# StandIn Followers and Planning

## Version 11: Current Release

Implemented and verified on 2026-10-22. The user confirmed that the highest
uploaded Play version is 10; this release uses 0.1.0+11.

- Navigation is Home, Calendar and Profile. There is no Following tab.
- Profile shows the current organization, follower count and sync status.
  Change organization opens discovery; new follows are organization-wide.
- New branch/subgroup selection is removed from the main experience. Existing
  branch contexts, attendance, plans and custom settings are preserved and can
  be accessed through Saved calendars in Profile.
- Calendar supports personal holidays on past, current and future dates, using
  the same holiday symbol as shared holidays. Make working day is a private
  override; it never removes a shared holiday for other people.
- Partial starts at the configured half-unit value, such as 4 of 8 hours, and
  reopening a saved partial entry preserves its amount.
- Home and Calendar show As of now and With plans/Projected together. Home
  lists upcoming plans and partial amounts. Plans never become actual attendance
  automatically, and holiday-excluded or stale plans are not credited.
- Only the organization creator can publish shared holiday changes. Each
  follower, including the creator, reviews changed dates with Apply/Keep mine.
  Publication is immutable, sequential and atomic; no follower-wide rewrite occurs.
- Accepted calendar snapshots, personal date overrides and review decisions are
  private and locally cached, with a durable sync queue. Concurrent unrelated
  edits merge; conflicts require explicit resolution in Profile.
- New followers start at the publication they selected, while existing accepted
  calendars are retained. Publication changes holidays only, not weekly rules.
- Registration number and mobile are optional and privately editable. Local
  schema 3 preserves existing data while adding registration and calendar state.

Verification: 152 Flutter tests and 20 Firebase permission tests passed. Phone
and desktop flows and previews were inspected, including saved partial amounts
and per-date consent. Analyzer has no errors or warnings; a pre-existing
informational print lint remains in one test. Whitespace checks passed.

The tested Firestore rules were deployed to standin-5755d and read back exactly:
ruleset 9f2dc7a5-6152-4365-86aa-2e72674d0e71. Existing search indexes are READY.
No production organization data, ownership or follower counts were rewritten.

The signed release bundle is ready:
C:/StandIn/build/app/outputs/bundle/release/standin-version-11.aab

Version code 11, version name 0.1.0 and application ID in.withwells.standin were
verified from the bundle's actual manifest. All three Android architectures are
present. JarFile signature verification passed using the existing certificate:
AD:02:D1:B7:18:C2:13:49:56:52:A6:E7:C2:2D:23:C5:20:B8:4A:F4:F1:DF:9C:5D:41:F9:2A:1A:C9:C9:0E:DB

Bundle SHA256:
1D6E4678C0C23F00E0D48D58A93589E865D9F488406D25A306F2548861DD14C9

The JDK verifier reports the expected self-signed certificate/no timestamp and
ZIP-stream entry-order warnings; the archive signature itself verifies. Android's
release lint found no issues. The bundle is not signed with a debug certificate.

Google Play upload and real-device Google sign-in/follow/creator-follower
interaction are not performed by these automated checks. Upload to the existing
closed-testing track, then update both creator and follower devices to version 11
before testing consent; old versions still read shared updates directly. Verify
joining/counts, private holiday edits, saved partial amounts, accepting one shared
date while declining another, and reopening/sync before a wider rollout.

## Version 10 Notes: Historical

Everything below records the previous release. Its navigation and subgroup
behavior are superseded by version 11 above; its bundle is not the new release.

## Shipped Behavior

- Users can discover colleges or companies, then preview and follow organization-wide rules or a specific branch, department, location, or semester.
- Organization discovery and group lists show follower counts and favor more-followed entries.
- A signed-in user can create a group in an existing organization. That user owns the group's shared rules; creating a group does not grant control of the organization or somebody else's groups.
- The Following tab supports multiple follows, switching the active group, personal rules, resetting to shared rules, and unfollowing. Attendance and plans remain stored separately for each organization/group.
- Personal settings include target, units, evaluation period, dates, weekly days off, Saturday patterns, and holidays. These settings do not change shared rules or follower counts.
- New college/company creation remains available after onboarding.
- Future calendar dates accept Going, Half day, Partial, or Not going plans. Non-working days and dates outside a configured date-bound period cannot be planned.
- Actual attendance still rejects future dates. The With plans view and home outlook show a separate projection, based only on confirmed attendance and saved, current-rule future plans.
- Plans are never automatically turned into attendance. An elapsed plan opens a confirmation sheet; saving actual attendance removes the plan atomically from the local active list and queues its remote tombstone.
- A rule or calendar change excludes stale future plans from the projection until the user reviews and saves them again.
- Profile now provides editable name/contact details, Manage following, and Calculation settings without duplicate shared-policy panels. It remains accessible with no active follow.
- Users may customize a followed group's rules or switch to a standalone private calculation. Public follows and attendance histories are retained when switching.
- Standalone calculation settings use users/{uid}/follows/personal-calculation with the private context personal:{uid}; no public organization or membership is created. Attendance and plans remain private in their existing per-user collections.
- Following shows pending/failed uploads and provides Retry sync. Search waits 300 ms while typing and uses the existing indexed, bounded queries. Selecting an organization no longer performs an administrator-only membership recount.

## Count Definitions

An organization counts a user once, even when that user follows several of its groups.
A group counts distinct users following that specific group, not the sum of its child groups.
Switching the active group or editing personal rules does not increase a count.
The creator is counted when they actually follow. Repeated follows and sync retries are idempotent.
Unfollowing the last group in an organization removes that user's organization membership.

Counters and their membership/follower records change together in Firestore transactions.
New follows create organization membership, exact-group ledger and both counters in the same
transaction. A rejected group follow cannot leave an organization count increment behind.
Older queued membership operations and last-follow membership removal remain compatible
with the existing durable queue. Removing the final follow synchronizes its group removal
before organization membership removal.
The rules reject duplicate increments, identity changes, ownership transfers, forged verification,
and membership changes without the accompanying count change.
Public discovery shows counts, not follower identities or attendance histories.

## Data and Compatibility

The local database upgrades from schema 1 to 2 by adding group metadata columns and
the attendance_plan_rows table. Existing attendance, scopes, and pending operations are retained.
Plans use the existing durable sync queue, inclusive server-timestamp checkpoints,
pending-local-edit protection, and revision-aware acknowledgements.
Plan deletion uses tombstones so another device receives the deletion.
Account deletion removes remote plans and group follower records as well as attendance.
Legacy personal holiday arrays keep their merge behavior; new explicit personal calendars
can replace inherited holidays. Editing legacy attendance preserves its original version identifiers.

There were no dependency version upgrades. sqlite3 is now an explicit test dependency at
its already-installed version. flutter_native_splash moved to runtime dependencies because
the generated Android release registrant references its native plugin.

## Release Requirements

The Android version code is 10, replacing the version 9 the user reports already uploaded to Google Play.
The app uses the existing release-signing configuration.

The tested Firestore rules were published to standin-5755d on 2026-10-18 using the authorized
StandIn account. A read-back confirmed that the active source exactly matches firestore.rules.
Active ruleset: 1448bd75-be0c-48ab-a597-d150ab64c486.
All existing search/popularity indexes were verified READY; no document data was rewritten.
The older installed Firebase CLI treats a combined firestore:rules,firestore:indexes selector
as excluding both deployment steps. Use --only firestore for both, or publish rules separately
with --only firestore:rules. Always verify the active rules after deployment.
Retest following the same existing college on a real phone before rolling out broadly.
The version 10 Google Play upload has not been performed.

Group creation/shared rule publication and discovery require an internet connection.
Attendance, personal-rule changes, follows, and plans use the local durable queue.
New plans are stored privately under users/{uid}/plans.

Existing organization memberships retain their counts. Historical group follows created by
older app versions are not administratively backfilled; their scope ledger is created on the
next follow upload. Legacy orphan memberships still require a separate administrative audit.

A bounded read-only production audit found nine organizations, ready search metadata/indexes,
and no policy/calendar/scope documents in the checked collections. Shared rules were not
invented or ownership reassigned. Creators can now publish their queued shared rules under
the corrected permissions. Organizations can still be followed without shared rules, and
users can configure their own calculation. Similarly named organizations were not merged.
The previous rules and metadata summary are recorded locally in build/firebase-audit/.

## Verification

Verified locally on 2026-10-18:

- Full Flutter suite: 136 passed.
- Firebase permission suite: 16 passed against the local demo emulator, including joining
  existing organizations and branches without ownership metadata or initialized counters.
- Phone and desktop screen tests: passed; readable preview images inspected.
- Android release app bundle: rebuilt successfully with version code 10 and version name 0.1.0.
- Bundle signature: verified with the existing StandIn/Withwells certificate, not a debug certificate.
- Analyzer: no errors or warnings; the pre-existing avoid_print informational lint remains in test/org_selection_redesign_test.dart:138.
- Diff/whitespace check: passed.
- Production rules deployment and source verification succeeded; existing indexes are READY.
- Live app Google sign-in, phone follow behavior, and Google Play upload were not exercised.

Upload bundle: C:/StandIn/build/app/outputs/bundle/release/standin-version-10.aab

Build output: C:/StandIn/build/app/outputs/bundle/release/app-release.aab

SHA256: 18D572FBF42A47FDCAF629E2682E2D18EC765C0AEC07E4696EAA445873E8B5E5

The version 9 release arm64 binary was checked for Manage following, Custom calculation and
Retry sync. Version 10 retains the same app code and changes only the release number; its
release manifest and existing StandIn/Withwells signing certificate were verified again.

Focused tests cover count idempotency, branch isolation, popularity sorting, personal overrides,
new-device recovery, actual/planned separation, stale rules, holidays, future-month projections,
plan edits during upload, tombstones, account cleanup, historical version preservation,
and schema migration. Screen tests cover phone and desktop layouts and future-plan saving.
The permission suite covers both allowed operations and denied cross-account or forged writes.
