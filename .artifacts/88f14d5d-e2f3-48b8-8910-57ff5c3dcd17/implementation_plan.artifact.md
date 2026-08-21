# Implementation Plan - Authoritative Policy Resolution

Fix the "Attendance rules incomplete" issue by ensuring followers correctly inherit organization rules using authoritative policy references and resilient lookups.

## Proposed Changes

### Data Layer
#### [MODIFY] [organization_repository.dart](file:///C:/StandIn/lib/src/data/organization_repository.dart)
- Update `_getPolicyHierarchy` and `_getCalendarHierarchy` to prioritize the organization's `activePolicyId` and `activeCalendarId` when resolving the current state.
- Update `_getCachedOrRemotePolicy` and `_getCachedOrRemoteCalendar`:
    - If an `explicitId` is provided (from the organization's authoritative metadata), attempt to load that specific ID from the local Drift cache first.
    - If not in cache, fetch it from remote using that ID.
    - **Remove hardcoded "policy-global" and "cal-global" fallback IDs** when an authoritative ID is available.
- Update `getResolvedPolicy` and `getResolvedCalendar` to retrieve the organization's metadata from the local database before starting hierarchy resolution. This ensures the authoritative IDs are known.

### Local Database
#### [MODIFY] [standin_database.dart](file:///C:/StandIn/lib/src/data/local/standin_database.dart)
- Add `getPolicyById(String id)` and `getCalendarById(String id)` methods to allow direct retrieval of authoritative versions, bypassing the `effectiveFrom <= now` restriction for the currently active rule.

## Verification Plan

### Automated Tests
- Run `flutter analyze` to ensure no regressions.
- Run `flutter test` with a specific test case for "Rapid Follow" (creator creates, follower joins 1 second later).

### Manual Verification
1. **Scenario: Rapid Follow**
    - Create an organization with 85% Target and Semester dates.
    - Switch accounts and immediately follow that organization.
    - Verify Home screen displays 85% Target and correct period dates.
    - Confirm "Attendance rules incomplete" card is NOT shown.
2. **Scenario: Historical Consistency**
    - Verify that an organization with a 1-year-old policy still resolves correctly for the current user.
3. **Scenario: Personal Preference**
    - Change the tracking period as a follower (e.g., Semester -> Monthly).
    - Verify the personal preference is saved in the `Follow` record while the organization's 85% Target remains inherited.
