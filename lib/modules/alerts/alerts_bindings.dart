import 'package:get/get.dart';
import 'package:zuru/modules/alerts/presentation/controllers/alerts_controller.dart';

/// Wiring for the scout **Alerts** tab.
///
/// [AlertsController] is registered as `permanent` so it starts watching for
/// incoming requests at app launch and keeps accruing alerts (and driving the
/// unread badge) while the scout is on other tabs.
///
/// ── MVP vs. a real notifications system ──────────────────────────────────────
/// Today alerts are derived on-device from the realtime `missions` streams the
/// scout already subscribes to. That is deliberately minimal: zero new backend,
/// works immediately, and covers "a live request was created".
///
/// The limits (and what a server-backed system would add):
///   • Ephemeral by nature — only events flowing through an open stream are
///     captured. A dedicated `notifications` table would be the source of truth.
///   • No push when the app is backgrounded/closed — needs FCM fan-out
///     (firebase_messaging is already wired; only the send side is missing).
///   • Read-state is local-only — won't sync across a scout's devices.
///
/// Recommended evolution when this graduates past MVP:
///   1. `notifications` table (recipient_profile_id, type, payload, read_at…).
///   2. Postgres trigger / Edge Function to insert a row on the events that
///      matter (mission requested, accepted elsewhere, payout, rating…).
///   3. Same trigger calls FCM for background push.
///   4. This controller swaps its `WatchScoutRequestsUseCase` source for a
///      realtime subscription on `notifications` — the entity, feed UI, and
///      badge stay exactly as they are.
class AlertsBindings extends Bindings {
  @override
  void dependencies() {
    Get.put<AlertsController>(AlertsController(), permanent: true);
  }
}
