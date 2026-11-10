# StandIn: Organization and Calendar Simplification

Status: implemented and verified, 2026-10-22. Tested Firebase rules are deployed;
the signed version 11 bundle is ready for closed testing. Google Play upload and
real-device acceptance testing have not been performed.

## Implementation Status

- Home, Calendar and Profile navigation is implemented. Discovery is opened from
  Profile; new follows are organization-only. Legacy branch data remains readable.
- Future personal holidays, a shared holiday symbol, half-unit Partial defaults,
  saved partial amounts, and actual/projected summaries are implemented.
- Creator-only holiday publication and per-date Apply/Keep mine review are
  implemented, with private accepted snapshots and durable synchronization.
- Optional registration/mobile editing and non-destructive schema 3 migration
  are implemented. New followers start at the selected publication checkpoint.
- Full Flutter suite: 152 passed. Firebase permission suite: 20 passed.
- Phone and desktop screen tests and preview inspection passed. Analyzer has no
  errors or warnings; one pre-existing informational print lint remains in a test.
- Firebase read-back matches ruleset 9f2dc7a5-6152-4365-86aa-2e72674d0e71.
- The release bundle manifest confirms application ID in.withwells.standin,
  version code 11 and version name 0.1.0. Three Android architectures are present,
  and the existing StandIn/Withwells signing certificate is verified.
- The real-device creator/follower acceptance check and Google Play upload are
  still required. The bundle does not mean an upload has been performed.

## Release Limitations

- Shared publication and organization discovery need a connection. Personal
  attendance, holiday changes and plans remain locally available and queued.
- The creator also reviews shared publication for their personal calendar.
- Old app versions still follow shared calendars automatically. Consent applies
  to version 11; update both creator and follower test devices before testing.
- Saved historical contexts remain available in Profile. Selecting a context
  does not erase history, and archived public contexts can be followed again.
- Publication proposes holiday dates only, not shared weekly patterns or rules.
- No production organization documents, ownership or follower counts are rewritten.

## Closed Testing

Bundle: C:/StandIn/build/app/outputs/bundle/release/standin-version-11.aab

SHA256: 1D6E4678C0C23F00E0D48D58A93589E865D9F488406D25A306F2548861DD14C9

Upload the bundle to a new release in the existing closed-testing track; no new
Android Studio project or Play app is needed. Install version 11 on both accounts.
Test following the same existing college, a count increase once per user, private
holiday and partial-plan edits, and a creator publication with one accepted date
and one declined date. Check that the declined date and attendance history stay
unchanged, then check reopening and synchronization on a second device. Verify
optional registration/mobile can be left blank or cleared. Perform these checks
before expanding rollout.

## Product Flow

- Bottom navigation: Home, Calendar, Profile. Remove the Following tab.
- Profile displays the current organization, follower count and sync status.
- Search and organization creation appear only when choosing or changing the
  organization, not as a repeated list on the main screens.
- Users follow an organization directly. New branch, department, location and
  subgroup creation/selection are removed from the user-facing flow.
- Keep one active organization calendar. Changing the active organization must
  not erase another organization's saved attendance or personal calendar.
- Retain private custom calculation for users who do not want an organization.
- Following does not grant access to other users' attendance or profile details.

## Profile and Onboarding

- Name remains required.
- Registration number is available but optional, stored as text so leading zeros
  and letters are preserved. It can be added or changed later in Profile.
- Mobile number is optional in onboarding and Profile; an empty value is valid.
- Registration and mobile values are private, not public organization metadata,
  follower identities, search keys, or authentication credentials.
- The organization area shows what the user follows. A deliberate Change action
  opens selection; ordinary calendar use never opens the discovery list.

## Calendar Interaction

- One calendar includes attendance, holidays and future plans. Remove the need
  to switch between separate Actual and With plans calendar modes.
- Show Actual and With plans percentages together at the top, with the latter
  clearly labeled Projected. Use a responsive layout that fits phone screens.
- A future date offers planned present, planned absent, planned half-day where
  supported, holiday, and clear plan. It never records actual future attendance.
- Past/current dates retain attendance editing and allow personal holiday edits.
- Users can also add a personal holiday on any future date, even when the
  organization has not published a holiday for it. These dates remain private.
- Use one holiday symbol for organization holidays, personal holidays and dates
  explicitly marked Holiday, including future dates. Show the holiday name and
  source in the date details when needed, not as different holiday icons.
- Holiday dates remain selectable so users can inspect, add, rename or remove
  personal overrides. Do not disable future date selection because a date is
  currently non-working.
- Holiday editing supports a name and a clear/remove action. Removing an
  inherited holiday is a private working-day override, not a shared deletion.
- Every user's ordinary calendar edits are personal. They never publish changes
  to the organization or alter its follower count.
- A holiday is excluded from the working-day denominator. A stored plan on that
  date is retained but excluded while the day is a holiday, rather than silently
  deleting the plan or counting it as attendance.
- Actual percentages never include plans. Projected percentages use eligible
  future plans and the user's accepted calendar and personal overrides.
- Unplanned future working days retain the existing projection assumptions;
  they must not silently become planned absences. Keep this formula covered by
  the existing planning tests.

## Partial Hours

- In both attendance and future-plan bottom sheets, selecting Partial starts
  with the configured half-day units, not the full-day units. For an 8-hour day
  with a 4-hour half day, the initial value is 4 hours, not 8 hours.
- Use half of the configured full-day units only as a fallback when no valid
  half-day amount exists. Never hard-code an 8-hour schedule.
- The slider remains editable and labels the value clearly, such as "Partial:
  4 hours of 8 hours". Use the correct unit for days/sessions-based calculations.
- Reopening an existing partial entry preserves its saved amount. Switching to
  Full resets to full-day units; Half resets to half-day units; Absent resets to
  zero. Do not carry the previous status's full-day value into Partial.
- Partial entries must have a value greater than zero and below the full-day
  amount. At the boundaries offer the appropriate Absent/Full status instead
  of saving a misleading Partial record.
- Calendar date details and Home's upcoming-plan summary show the partial amount,
  not a full-day amount or just an unlabeled Partial status.

## Home Summary

- Clearly label the actual attendance result "As of now" and show the period it
  covers. Future plans must not contribute to that result or to today's actual
  attendance status.
- Beside it, show "With plans" with a Projected label for the same evaluation
  period. Keep both values visible together near the top, stacking on narrower
  screens rather than requiring a toggle or hiding the projection below advice.
- When future plans exist, show the next few upcoming dates and their planned
  statuses/amounts, with a calendar action to see or edit the rest. Filter out
  elapsed or deleted plans; do not present plans for another period as if they
  contribute to the displayed percentage.
- Future holidays use the same holiday symbol and affect only eligible dates in
  the relevant calculation. Plans excluded because their date is a holiday, or
  needing review after a calendar change, are identified rather than presented
  as contributing attendance.
- Recompute both summaries after saving a plan or holiday, including offline
  edits. Keep actual safety/target messages separate from projected outcomes.
- When no future plans exist, use a clear empty state such as "No upcoming plans"
  rather than suggesting that the user has planned attendance.

## Organization Creator Editing

- No general Edit organization action for ordinary followers.
- Only the creator sees Edit shared calendar. Enforce this in Firebase, not just
  by hiding a button. Preserve the existing administrative support permissions.
- Creator edits to their own personal calendar remain private unless they
  explicitly choose the shared-calendar editing action.
- Shared publication creates an immutable calendar revision with author ID,
  publication time, base revision and exact changed dates/values. It must not
  overwrite a previously published revision.
- Publish a revision and advance the organization's latest revision reference
  atomically. Reject stale-base publication so competing edits cannot overwrite
  one another silently.
- The author's own calendar may apply the revision as part of publication;
  other followers must choose whether to apply it.

## Follower Consent to Calendar Updates

- First follow initializes the user's calendar from the current published
  organization calendar. Subsequent publications are proposals, not automatic
  replacements.
- Show an in-app notice: "Your organization updated its calendar." Open a review
  showing each changed date, old value and proposed value.
- Offer Apply and Keep mine for each date, plus Apply all and Keep all. Dismissing
  the review leaves decisions pending and does not change the calendar.
- Apply changes only the dates accepted for that exact revision. Other dates,
  calculation settings, attendance records and plans stay unchanged.
- Keep mine retains the user's effective value for that date and records the
  rejection, so the same change is not repeatedly offered.
- If applying would replace a personal edit or change the classification of a
  date with recorded attendance, clearly show the conflict in the review. Never
  delete the recorded attendance or silently overwrite a personal override.
- A later editor change to a previously declined date is a new proposal. Review
  must show the user's current value, not assume they accepted the last version.
- Process pending revisions in order; reviewing one revision must not mark newer
  revisions reviewed. Decisions refer to immutable revision IDs and dates.
- Persist acceptance/rejection privately and sync it between devices. Retries
  must be idempotent. Recheck the proposal and user's override at apply time so
  a stale review cannot overwrite a newer personal edit.
- Weekly patterns or calculation-rule updates are not disguised as date edits.
  Keep those unchanged in this release unless a separate, explicit review flow
  is implemented for them.

## Storage and Retrieval

- Reuse organizations and indexed organization search/popularity queries.
- New organization follows use the existing global context internally; no new
  public branch/scope documents are required for the user-facing flow.
- Store immutable shared revisions under each organization's calendar revisions.
  Store follower baseline, date overrides and update decisions privately beneath
  that user's account, using organization and revision IDs for isolation.
- Cache the accepted baseline and overrides locally. Calendar rendering and
  personal edits remain available offline through the durable sync queue.
- Fetch only revisions newer than the user's review checkpoint in bounded,
  ordered pages. Avoid downloading an entire follower list or copying every
  user's calendar when an editor publishes an update.
- Keep unique organization follower counts and idempotent joining/leaving.
  Personal calendar edits and update decisions do not change counts.
- An organization without published rules remains followable. Users can create
  their own personal settings; do not invent an official calendar.

## Compatibility and Migration

- Do not delete existing branch follows, calendars, attendance or plans.
- Existing branch users keep their current effective calendar and saved context
  until migration has preserved their data. Hide branch creation/selection, not
  the storage required to read historical records.
- Capture a follower's current effective calendar as the initial accepted
  baseline before enabling the consent resolver. Never switch an existing user
  to a newer organization calendar during migration without review.
- Existing branch attendance remains associated with its original context. Do
  not relabel it as global organization attendance or combine conflicting dates
  without an explicit migration decision.
- Old app versions still read shared calendars automatically. Keep legacy
  policy/calendar behavior compatible and do not claim consent protection for
  those versions. Test old/new client coexistence before live publication.
- Registration number requires a nullable local field, remote mapping and a
  non-destructive schema migration. Clearing optional fields must persist.

## Implementation Order and Release Gates

1. Implement accepted-calendar snapshots, private overrides, immutable shared
   revisions and decision sync, with security and migration tests.
2. Add creator-only publishing and the follower review/apply/keep flow. Validate
   offline recovery, duplicate retries, concurrent devices and ordered updates.
3. Simplify navigation/Profile and organization-only selection; remove new
   subgroup creation without deleting historical storage.
4. Unify calendar date actions, including personal future holidays and one holiday
   symbol. Correct Partial defaults and display As of now/Projected percentages
   together in Calendar and Home. Show upcoming plans on Home. Add registration
   number and keep both contact/registration fields optional.
5. Verify phone layouts and run the full app and Firebase permission suites.
   Test creator and follower accounts on real devices before wider rollout.
6. Build the next signed closed-testing bundle with a version code greater than
   the highest uploaded Play version. Version 11 is the next candidate if 10 is
   still the highest uploaded version; confirm before building.

Required tests include no Following tab, no new subgroup flow, creator-only
publication, unique follower counts, optional registration/mobile, private data
isolation, per-date accept/reject, preserving overrides/history/plans, holiday
denominators, adding future personal holidays without an inherited holiday,
one holiday symbol across sources, half-day Partial defaults in both sheets,
preserving edited partial amounts, correct non-hour units, Home actual/projected
period alignment, upcoming plan filtering, no actual future attendance,
migration without data loss, and bounded revision retrieval.
