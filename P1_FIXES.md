# StandIn P1 Fixes

Verified locally on 2026-10-17. Scope: the eight approved P1 issues only.
No production deployment, live account deletion, or P2 feature work was performed.

## Root Causes and Fixes

| Issue | Root cause | Fix |
| --- | --- | --- |
| Mark today | Today's time was compared against midnight and treated as a future date. | Normalize selected dates before validation. Save failures are displayed and duplicate submissions are disabled. |
| Profile writes | Creation omitted `isAdmin: false`; repeat writes replaced protected role and creation fields. | Transactional creation includes the non-admin flag; updates preserve protected fields. Username claims are transactional and idempotent for their owner. |
| Join and follower count | Ordinary users could create memberships but could not perform the accompanying organization count update. | Rules allow only exact count changes tied to the same user's atomic join/leave. Shared rule-editing permissions remain restricted. |
| Account deletion | Cancellation was treated as success, deletion permissions were missing, membership failures were swallowed, batches could exceed 500, and sync could recreate data. | Cancel explicitly; stop and await sync; propagate failures; remove remote and locally known memberships; use 450-document batches; clear personal local data; delete through the injected auth service. Preserve shared organizations. |
| Offline sync | No startup/retry trigger, only 25 writes per pass, unknown operations discarded, competing syncs, stale pulls, and client-time checkpoints. | Trigger on startup, retry automatically, drain the backlog, retain unsupported operations, serialize sync, compare queue payloads before acknowledgement/rescheduling, protect pending edits, and use inclusive server-timestamp checkpoints. |
| Organization/scope isolation | Global policy/calendar IDs collided locally and attendance used inherited policy identity rather than the user's follow context. | Namespace cache and queue keys by organization, retain matching legacy cache reads, prefer refreshed scoped rows, and use/filter the active follow's organization and scope. |
| Holiday inheritance | Personal schedules saved an empty holiday list and masked official holidays. | Copy holidays at onboarding and merge official/personal holidays during resolution, including legacy empty lists. |
| Incomplete policies | Missing targets or period dates could report safe eligibility; fallback units could mix calculation bases. | Validate targets, units, and period bounds; do not claim eligibility or safe-to-miss allowances with incomplete rules; use basis-appropriate personal defaults and display missing-rule states. |

Authenticated incomplete onboarding now starts after login, and rule/calendar loading errors offer retry instead of indefinite loading.

## Verification

- Flutter 3.35.7 / Dart 3.9.2.
- Full Flutter suite: **112 passed**, including 25 new regression tests.
- Firestore emulator: **7 passed**, using only project `demo-standin`.
- Web JavaScript release build: passed.
- Android debug APK build: passed.
- Analyzer: no new errors or warnings. The existing `avoid_print` informational lint remains at `C:/StandIn/test/org_selection_redesign_test.dart:138`; the analyzer exits nonzero for it.
- Whitespace/diff check: passed.
- Web build still reports existing optional WebAssembly incompatibilities and a Cupertino font warning; a Wasm build was not verified.
- Firebase account flows were tested with mocks/FakeFirestore and permission rules with the emulator. Live Google login and production behavior were not exercised.

## Changed Application Files

- `C:/StandIn/firestore.rules`
- `C:/StandIn/lib/src/app.dart`
- `C:/StandIn/lib/src/data/auth/auth_service.dart`
- `C:/StandIn/lib/src/data/local/standin_database.dart`
- `C:/StandIn/lib/src/data/local_first_attendance_repository.dart`
- `C:/StandIn/lib/src/data/organization_repository.dart`
- `C:/StandIn/lib/src/data/remote/firestore_attendance_remote.dart`
- `C:/StandIn/lib/src/data/remote/firestore_org_remote.dart`
- `C:/StandIn/lib/src/data/remote/firestore_user_remote.dart`
- `C:/StandIn/lib/src/data/sync/sync_engine.dart`
- `C:/StandIn/lib/src/data/user_repository.dart`
- `C:/StandIn/lib/src/domain/attendance.dart`
- `C:/StandIn/lib/src/domain/policy_engine.dart`
- `C:/StandIn/lib/src/features/attendance/attendance_controller.dart`
- `C:/StandIn/lib/src/features/onboarding/onboarding_controller.dart`

## Added Tests and Documentation

- `C:/StandIn/test/p1_attendance_test.dart`
- `C:/StandIn/test/p1_account_test.dart`
- `C:/StandIn/test/p1_cache_test.dart`
- `C:/StandIn/test/p1_sync_test.dart`
- `C:/StandIn/firebase.emulators.json`
- `C:/StandIn/test/firestore_rules/rules.test.cjs`
- `C:/StandIn/test/firestore_rules/package.json`
- `C:/StandIn/test/firestore_rules/package-lock.json`
- `C:/StandIn/test/firestore_rules/.gitignore`
- `C:/StandIn/test/firestore_rules/README.md`
- `C:/StandIn/P1_FIXES.md`

## Production Follow-Up

Deploy the updated app and `firestore.rules` together after approval. Until the
rules are deployed, production profile creation, membership count changes, and
account deletion will still be subject to the old permissions.

The Firestore document schema and local database schema version remain unchanged.
Legacy cache rows are retained. No application dependencies were upgraded.
Existing orphan memberships not represented in a user's remote follows or local
database cannot be discovered by this client-only deletion flow; auditing such
historical server data would require a separately approved administrative task.

Build outputs: `C:/StandIn/build/web` and
`C:/StandIn/build/app/outputs/flutter-apk/app-debug.apk`.
