# Blueprint — IntaSend collection (M-Pesa + card) on the mobile side

## Goal

The backend has moved inbound mission payments from Safaricom Daraja to IntaSend.
IntaSend collects by **M-Pesa STK push** and by **card**, so the app must let a
client pick a method and must handle a card payment that completes in an
external browser.

This document is the spec. Everything it says about the backend is already
deployed — do not change the Supabase functions from this repo.

## Scope

**In scope:** the client paying for a mission (`intasend-collect`), plus the
payment-status watching that follows it.

**Out of scope:** scout payouts. Payouts run through `intasend-payout`, which
only accepts an internal service token and is never called from the app. A scout
sees payouts as rows in the existing statements list.

---

## 1. Backend contract

### `intasend-collect` — starts a payment

`POST {SUPABASE_URL}/functions/v1/intasend-collect`, called with
`client.functions.invoke('intasend-collect', body: …)`. It requires the caller's
Supabase user JWT (the Supabase client adds it) and only the mission's own
client may pay.

The **amount comes from the mission row on the server**. Never send an amount;
it will be ignored.

M-Pesa request:

```json
{ "mission_id": "uuid", "method": "mpesa", "phone_number": "0712345678" }
```

M-Pesa response, HTTP 200:

```json
{
  "message": "Check your phone to complete the M-Pesa payment",
  "payment_id": "uuid",
  "invoice_id": "ABC123"
}
```

Card request (`email` and `redirect_url` are both optional):

```json
{ "mission_id": "uuid", "method": "card", "email": "a@b.com", "redirect_url": "https://…" }
```

Card response, HTTP 200:

```json
{
  "payment_id": "uuid",
  "checkout_id": "uuid",
  "checkout_url": "https://sandbox.intasend.com/checkout/…/express/"
}
```

Errors are `{ "error": "…" }` with a status code:

| Status | Meaning | What the UI should do |
| --- | --- | --- |
| 400 | Bad body, bad phone number, or the mission has no price | Show the message, stay on the form |
| 403 | Caller is not this mission's client | Show a generic failure and close |
| 404 | Mission not found | Show a generic failure and close |
| 409 | `Mission already paid` | Treat the mission as paid: close the sheet as success |
| 502 | IntaSend rejected the request | Offer a retry |

`phone_number` is normalised server-side, so `0712…`, `+254712…` and `254712…`
are all fine. The server rejects anything that is not a valid Safaricom number.

### How a payment finishes

Both methods finish **out of band**: IntaSend calls the `intasend-webhook`
function, which verifies the result against IntaSend's own status API and then
writes the `payments` row. The app learns the outcome **only** by watching that
row over realtime — the same mechanism `watchPayment` already uses. There is no
status endpoint to poll and no meaningful status in the initiate response.

`payments.status` values the app will see:

| Status | Meaning |
| --- | --- |
| `pending` | Row created, not yet sent to IntaSend |
| `processing` | STK push sent / checkout open, waiting on the customer |
| `success` | Paid and verified. Terminal |
| `failed` | Failed, or the amount/currency did not match. Terminal |
| `cancelled` | Customer cancelled. Terminal |
| `refunded` | Refunded later. Terminal |

`failure_reason` carries the human-readable reason on a failure, and `provider`
is `intasend`.

No provider-specific columns were added — the existing ones are reused, so a
future provider changes nothing here:

| Column | Holds |
| --- | --- |
| `checkout_request_id` | The in-flight request id: the IntaSend invoice id for M-Pesa, the checkout id for card |
| `merchant_request_id` | The settlement invoice id (filled in by the webhook for card) |
| `provider_ref` | The final receipt, set only on success: the M-Pesa code, else the invoice id |
| `metadata` | `{ "method": "mpesa" \| "card", "provider_event": … }` |

So the method a payment used is `metadata->>'method'`, **not** a column. If the
UI labels a row, read it from the metadata map.

---

## 2. What to change in this repo

The `payments` module already does almost all of this for Daraja. Extend it;
don't start a parallel module.

### 2.1 `data/models/payments.inputs.dart`

Replace `StkPushInput` with a `CollectPaymentInput` that carries the method.
Keep the class in this file.

```dart
enum PaymentMethod { mpesa, card }

class CollectPaymentInput {
  final String missionId;
  final PaymentMethod method;
  final String? phoneNumber; // required for mpesa
  final String? email;       // optional, card only
  final String? redirectUrl; // optional, card only

  const CollectPaymentInput({ … });

  Map<String, dynamic> toBody() => {
    'mission_id': missionId,
    'method': method.name, // 'mpesa' | 'card'
    if (phoneNumber != null) 'phone_number': phoneNumber,
    if (email != null) 'email': email,
    if (redirectUrl != null) 'redirect_url': redirectUrl,
  };
}
```

### 2.2 `domain/entities/` — the initiate result

Replace `StkPushResult` with one entity covering both methods, because the card
branch has no message and the M-Pesa branch has no URL:

```dart
class CollectPaymentResult {
  final String paymentId;
  final String? message;      // mpesa
  final String? invoiceId;    // mpesa
  final String? checkoutUrl;  // card — open this
  final String? checkoutId;   // card
}
```

Model: rename `stk_push_result.model.dart` to `collect_payment_result.model.dart`
and map the fields above from the response map. Keep the existing guard that
treats an empty `payment_id` as a failure.

### 2.3 `data/sources/remote_payments_datasource.dart`

Rename `initiateStkPush` to `collectPayment` and change the function name:

```dart
return client.functions.invoke('intasend-collect', body: input.toBody());
```

Leave `watchPayment` and `getStatements` exactly as they are — the realtime
watch already does the right thing.

`FunctionResponse` does not expose the error body for non-2xx, so read the
status code and, where you can, the `error` field, to distinguish the 409
`Mission already paid` case from a generic failure. `functions.invoke` throws
`FunctionException` on a non-2xx; catch it in the repository and read
`e.status` and `e.details` (the decoded body, so `e.details['error']`).

### 2.4 `domain/entities/payment.entity.dart` — **status enum is incomplete**

`PaymentStatus` currently has only `processing`, `success`, `failed`, `unknown`.
The backend also writes `pending`, `cancelled` and `refunded`, and `cancelled`
currently falls into `unknown`, so a customer who cancels the STK prompt waits
for the 90-second timeout instead of being told.

Add all of them, and keep `isTerminal` honest:

```dart
enum PaymentStatus {
  pending, processing, success, failed, cancelled, refunded, unknown;

  static PaymentStatus fromApi(String? value) => switch (value?.toLowerCase()) {
    'pending' => pending,
    'processing' => processing,
    'success' => success,
    'failed' => failed,
    'cancelled' => cancelled,
    'refunded' => refunded,
    _ => unknown,
  };

  bool get isTerminal =>
      this == success || this == failed || this == cancelled || this == refunded;
}
```

Also map `failure_reason` into `resultDesc` in `payment.model.dart` — that is
where the backend puts the reason now:

```dart
resultDesc: m['failure_reason']?.toString() ??
    m['result_desc']?.toString() ??
    m['message']?.toString(),
```

If the UI needs to label a row with its method, read it out of the metadata
map rather than expecting a column:

```dart
paymentMethod: (m['metadata'] as Map?)?['method']?.toString(),
```

### 2.5 Repository, use case, bindings

- `PaymentsRepository.initiateStkPush` becomes
  `collectPayment(CollectPaymentInput)` returning
  `RepoResponse<CollectPaymentResult>`.
- Rename `InitiateStkPushUseCase` to `CollectPaymentUseCase`. Same shape.
- Update `payments_bindings.dart` for the renames. Keep `fenix: true`.
- Keep using `ErrorWrapper.async` with a friendly `onError` message, as the
  existing methods do.

### 2.6 `presentation/controllers/payment_controller.dart`

This is the real work. The controller gains a method choice and a card branch.

State machine:

```dart
enum PaymentUiState { form, sending, awaitingPin, awaitingCard, success, failed }
```

- `form` — amount, method toggle, and the phone field when the method is M-Pesa.
- `sending` — the `intasend-collect` call is in flight.
- `awaitingPin` — M-Pesa: STK sent, watching the row (unchanged behaviour).
- `awaitingCard` — card: checkout URL opened externally, watching the row.
- `success` / `failed` — as today.

Add `final Rx<PaymentMethod> method = PaymentMethod.mpesa.obs;` and a
`setMethod` that clears `error`.

`pay()`:

1. If method is `mpesa`, validate the phone as it does today. If `card`, skip
   the phone check.
2. `state.value = PaymentUiState.sending`.
3. Call `CollectPaymentUseCase` with the input.
4. On failure, `_fail(message)`.
5. On success, **start watching `result.paymentId` before opening anything**,
   so a fast webhook cannot be missed.
6. M-Pesa: `state.value = PaymentUiState.awaitingPin`.
7. Card: open `result.checkoutUrl!` with
   `Get.find<UrlLauncherService>().launch(Uri.parse(url))`. If it returns
   false, `_fail('Could not open the payment page.')`. Otherwise
   `state.value = PaymentUiState.awaitingCard`.

Timeouts — the current single 90s timeout is wrong for card, where the customer
is typing card details in a browser:

- M-Pesa: keep 90 seconds.
- Card: 10 minutes, and only fail on timeout if the state is still
  `awaitingCard`.

Because the card flow leaves the app, the sheet must recover when the user comes
back. The realtime subscription survives backgrounding, but the socket can drop,
so add an `AppLifecycleListener` (or `WidgetsBindingObserver`) and, on resume
while in `awaitingCard`, re-subscribe to `watchPayment(paymentId)`. The
datasource already emits the current row once on subscribe, so a re-subscribe
picks up a payment that completed while the app was backgrounded.

Handle the new statuses in the watch callback:

- `success` → `_succeed()`
- `failed` → `_fail(payment.resultDesc ?? 'Payment failed. Please try again.')`
- `cancelled` → `_fail('Payment was cancelled.')`
- `refunded` → `_fail('This payment was refunded.')`
- `pending`, `processing`, `unknown` → keep waiting

In `awaitingCard`, also offer an explicit "I've completed payment" button that
just re-subscribes, and keep "Cancel" available.

`redirectUrl`: pass nothing for now. The app learns the result from the payments
row, not from the redirect, so a redirect is only cosmetic. If a
thank-you page is wanted later, pass an `https://` URL — not a custom scheme,
since IntaSend validates it as a URI and the browser has to be able to load it.

### 2.7 `presentation/widgets/payment_sheet.dart`

- Add a method toggle (two pill buttons: "M-Pesa", "Card") above the amount
  card, driven by `controller.method`, wrapped in `Obx`.
- Show the phone field only when the method is M-Pesa.
- The pay button label stays `Pay {amountLabel}`.
- Add an `awaitingCard` view: "Complete payment in your browser", subtitle
  "We'll confirm automatically once your card payment goes through", a spinner,
  the "I've completed payment" button, and "Cancel".
- Keep `ClientColors`, the `flutter_animate` usage and the existing view
  structure. Do not restyle the sheet.

`showPaymentSheet(missionId:, amountLabel:, phone:)` keeps its signature and
still returns `Future<bool>`, so its three callers
(`maps_tab_controller.dart:140`, `missions_tab_controller.dart:93`,
`post_mission_controller.dart:183`) need no changes. Preserve that.

---

## 3. Edge cases to get right

1. **Already paid.** A 409 `Mission already paid` is a success for the UI:
   close the sheet with `true` rather than showing an error, otherwise a client
   whose webhook landed late gets stuck.
2. **Watch before you leave.** Subscribe before launching the browser; a card
   payment can settle in seconds.
3. **Reused payment row.** Calling `intasend-collect` twice for one mission
   reuses the same in-flight row, so `payment_id` may be one you have already
   seen. Cancel the previous subscription before starting a new one.
4. **Don't trust the response for the outcome.** Neither response says a
   payment succeeded. Only the watched row does.
5. **Timeout is not failure.** On timeout say the payment could not be
   confirmed and that the mission will update if it goes through — don't claim
   it failed.
6. **Amount is server-side.** `amountLabel` is display only.

---

## 4. Acceptance checks

- Sandbox M-Pesa STK push on a completed mission moves the sheet
  form → sending → awaitingPin → success, and the mission publishes.
- Cancelling the STK prompt shows "Payment was cancelled" without waiting for
  the timeout.
- Card: the checkout page opens in the browser, test card `4242 4242 4242 4242`
  with any future expiry and any CVC succeeds, and the sheet reaches success
  after returning to the app — including when the app was backgrounded for a
  minute.
- Paying an already-paid mission closes the sheet as paid.
- `flutter analyze` is clean and no caller of `showPaymentSheet` changed.
