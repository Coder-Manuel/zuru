# Zuru World — Internal Security Remediation Backlog

**Internal only. Not part of the ODPC submission.**
Extracted from the ODPC security document on 21 August 2026 so the findings are
not lost when the submission draft was narrowed to implemented features only.
See `ODPC_SECURITY_MEASURES.md` for the declaration itself.

Priority order: item 9 (mission ownership), item 8 (`users` exposure),
item 10 (self-writable status/reputation), item 11 (location visibility).

---

## 6. Known gaps and remediation plan

These are stated candidly because ODPC registration is an ongoing obligation and
an inaccurate declaration is worse than a disclosed gap.

| # | Gap | Risk | Proposed remediation | Owner / date |
|---|---|---|---|---|
| 1 | No in-app **account deletion** flow. Apple App Store policy also requires this for any app offering account creation. | Non-compliance with the right to erasure; App Store rejection risk. | Add an in-app "Delete my account" action backed by a server-side function that erases or irreversibly anonymises the user's rows, avatar/clip objects, and cached tokens, retaining only what financial-records law requires. | **[CONFIRM]** |
| 2 | No **data export** (access / portability) flow. | Cannot service a subject access request within the statutory timeframe. | Provide an export on request via a documented manual process initially, automated later. | **[CONFIRM]** |
| 3 | **Retention schedule** is not formally defined for missions, payment records, live-stream artefacts, location history, and analytics events. | Indefinite retention conflicts with the storage-limitation principle. | Define and document a schedule per data category, then implement automated purging. | **[CONFIRM]** |
| 4 | **Live-stream recording** status is unclear. Recorded audio/video of third parties in public places is materially higher-risk than transient streaming. | If recordings are retained, a Data Protection Impact Assessment is likely required. | Confirm whether streams are recorded; if so, define retention, access control and a DPIA. | **[CONFIRM]** |
| 5 | Profile avatars and clips are served from a **public storage URL**. | Anyone holding the URL can view the media without authentication. | Confirm this is intended for publicly-listed Scout profiles; if not, move to signed, expiring URLs. | **[CONFIRM]** |
| 6 | **Cross-border transfer** basis is not documented. | s.48–49 of the Act require a lawful basis for transferring personal data outside Kenya. | Record hosting regions for each sub-processor and the transfer safeguard relied upon (adequacy, contractual clauses, or explicit consent). | **[CONFIRM]** |
| 7 | No formal **Data Protection Impact Assessment**. | The platform combines precise real-time location tracking with live video of public spaces — a combination that ordinarily warrants a DPIA under s.31. | Complete a DPIA before or shortly after registration. | **[CONFIRM]** |
| 8 | **`users` is readable in full by every authenticated user** (`users_select_public`, qualifier `true`). This exposes the email address, phone number, account status and push token of every registered user to anyone who creates an account. | **High.** Direct breach of the confidentiality and minimisation principles, and a bulk-harvesting route for contact data. Sensitive on a platform where users meet in person. | Replace with a policy scoping reads to `auth.uid() = id`. Expose counterparty details only through a view or `SECURITY DEFINER` function returning the minimum fields required, and only to users sharing an active mission. | **[CONFIRM]** |
| 9 | **Mission policies check role, not ownership.** `missions_select_own_client` and `missions_update_own_client` appear to test only that the caller is a client in `profiles`, without joining the mission to that client. The app's `updateMissionStatus` sends no ownership filter and relies wholly on the policy. | **Critical, if confirmed.** Any client could read every mission on the platform — including other clients' pickup addresses and coordinates — and alter the status of missions they do not own. | Re-write both qualifiers to compare `missions.client_id` against the caller's own profile id. Verify by attempting a cross-account read with a second test account. | **[CONFIRM — paste the exact `qual`/`with_check` expressions; this is the single highest-priority item.]** |
| 10 | **Reputation and account-status columns are self-writable.** `profiles` and `users` allow a user to update their own row, and RLS is row-level, not column-level. Unless column grants or triggers restrict it, a Scout can set their own `rating`, `total_reviews`, `fulfillment_rate`, and either role can set `status`. The app already writes `status: 'active'` from the client during Scout onboarding. | **High.** Enables reputation fraud against consumers, and lets a suspended or banned account restore its own access — a platform-safety failure, not merely a data one. | Revoke `UPDATE` on the reputation and status columns from the `authenticated` role (`GRANT UPDATE (col, …)` on the permitted columns only), or add a trigger rejecting changes to protected columns. Move activation server-side. | **[CONFIRM]** |
| 11 | **All profiles are readable by every authenticated user**, including `locality_geo`. Combined with the 25-second `update_scout_location` refresh, a Scout's near-real-time position may be readable platform-wide rather than only by the client of an active mission. | **High.** Continuous location is among the most sensitive categories the platform holds, and this is a physical-safety exposure, not only a privacy one. | Confirm whether `update_scout_location` writes to `profiles` or to a separate table. Restrict coordinate columns to `SECURITY DEFINER` proximity functions; return bearing/distance rather than raw coordinates. | **[CONFIRM]** |
| 12 | **`sessions` is readable by every authenticated user** (qualifier `true`). | Depends on contents. If session rows carry stream identifiers, room names or tokens, this could permit an uninvolved user to locate or join another user's live mission stream. | Establish what `sessions` contains and scope reads to mission participants. | **[CONFIRM — what columns does `sessions` hold?]** |
| 13 | **Narrower policies are nullified by broader ones.** On `ratings` and `profile_clips`, a correctly-scoped participant policy sits alongside a blanket `true` read policy. PostgreSQL combines permissive policies with **OR**, so the blanket policy wins and the narrow one contributes nothing. | Moderate — chiefly the false assurance that an access restriction is in force when it is not. | Remove the blanket policies, or mark the narrow ones `AS RESTRICTIVE` if both are genuinely intended. | **[CONFIRM]** |
| 14 | **No self-service deletion exists at the database layer.** `users` DELETE is `supabase_admin`-only and `profiles` has no DELETE policy — so the erasure gap at item 1 is structural, not merely a missing screen. | Reinforces the right-to-erasure gap. | Implement erasure as a `SECURITY DEFINER` function invoked by the account-deletion flow, rather than by granting DELETE to users. | **[CONFIRM]** |

---

## 7. Open questions to resolve before submission

1. Is Zuru registering as a **Data Controller**, a **Data Processor**, or both?
2. Legal entity name, registration number, physical address, and the nominated
   data protection contact.
3. Which **Supabase region** hosts the production project?
4. Are **live streams recorded and retained**, or transient only?
5. Are **Scout location histories** persisted as a trail, or does each update
   overwrite the last known position?
6. Is a published **privacy policy** live, and is consent captured at sign-up?
7. Is **MFA enforced** on all administrative consoles?
8. How many people hold production data access, and under what agreement?
9. What is the intended **retention period** for each data category?
10. Are signed **DPAs** in place with Supabase, LiveKit, Mixpanel, Google and Safaricom?
11. **Priority:** what are the exact `qual` and `with_check` expressions on
    `missions_select_own_client` and `missions_update_own_client`?
12. Does `update_scout_location` write to `profiles.locality_geo`, or to a
    separate table with its own policy?
13. What columns does the `sessions` table hold, and does `app_config` contain
    anything not safe for every authenticated user to read?
14. Are there **column-level grants** on `profiles` and `users` that restrict
    which columns the `authenticated` role may update?
15. Which database functions are `SECURITY DEFINER`, and does each re-check the
    caller's entitlement internally? A `SECURITY DEFINER` function bypasses RLS
    entirely, so it must perform its own authorisation.

---

---

## 8. Annex A — deployed Row-Level Security policies

Policies as deployed at the date of this document. "All authenticated" means the
qualifier evaluates to `true` for any signed-in user.

| Table | Policy | Op | Scope | Assessment |
|---|---|---|---|---|
| `app_config` | `app_config authenticated read` | SELECT | All authenticated | Acceptable if the table holds no secrets — **[CONFIRM]** |
| `mission_scout_events` | `scout reads own events` | SELECT | Own scout profile | Correctly scoped |
| `missions` | `clients can insert own missions` | INSERT | Caller is a client and owns the profile | Correctly scoped |
| `missions` | `missions_select_own_client` | SELECT | Caller is a client — **ownership link unverified** | **See §6 item 9** |
| `missions` | `missions_update_own_client` | UPDATE | Caller is a client — **ownership link unverified** | **See §6 item 9** |
| `payments` | `payments_participant_read` | SELECT | Payer or payee only | Correctly scoped; no client-side writes permitted |
| `profile_clips` | `Enable read access for auth users` | SELECT | All authenticated | Acceptable for public Scout profiles |
| `profile_clips` | `*_insert_own` / `*_update_own` / `*_delete_own` | I/U/D | Own profile | Correctly scoped |
| `profiles` | `Enable read access for auth users` | SELECT | All authenticated | **See §6 item 11** (location columns) |
| `profiles` | `Enable update for users based on user_id` | UPDATE | Own row, **all columns** | **See §6 item 10** |
| `ratings` | `Enable insert for users based on user_id` | INSERT | Own profile | Correctly scoped |
| `ratings` | `Enable read access for all users` | SELECT | All authenticated | Supersedes the participant policy below |
| `ratings` | `Mission participants can read ratings` | SELECT | Mission participants | **Inert — see §6 item 13** |
| `sessions` | `Enable read access for all users` | SELECT | All authenticated | **See §6 item 12** |
| `users` | `users_select_public` | SELECT | **All authenticated, all columns** | **See §6 item 8 — highest-severity finding** |
| `users` | `users_update_own` | UPDATE | Own row, **all columns** | **See §6 item 10** |
| `users` | `users_insert_admin_only` / `users_delete_admin_only` | INSERT/DELETE | `supabase_admin` only | Correctly restricted; see §6 item 14 |

**Note on `role: public`.** Three policies are granted to the `public` role,
which includes the unauthenticated `anon` role. Their qualifiers dereference
`auth.uid()`, which is `NULL` for anonymous callers, so the subquery fails
closed and no anonymous access results. This is safe as written but fragile;
these should be re-granted to `authenticated` for clarity.

**Note on write coverage.** `missions` has no scout-facing UPDATE policy, which
is consistent with mission acceptance being routed through the `accept_mission`
database function. Any such `SECURITY DEFINER` function bypasses RLS and must
therefore perform its own entitlement check internally — see §7 question 15.

*This document describes measures implemented in the Zuru World mobile
application and its supporting backend as of the date above. It should be
reviewed whenever the architecture, sub-processor list, or data categories change.*
