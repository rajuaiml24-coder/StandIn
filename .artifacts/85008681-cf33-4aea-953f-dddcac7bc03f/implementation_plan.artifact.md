# Implementation Plan: Organization Discovery & Context Recovery

This plan implements real community discovery for organizations and ensures that a user's following context is fully restored on new devices.

## User Review Required

> [!IMPORTANT]
> **Strict Role Filtering**: I will enforce role-based discovery at the data layer. Students will only see "college" organizations, and employees will only see "company" organizations.
> **Full Context Sync**: On login, StandIn will now automatically pull not just your attendance records, but also the names and details of the College, Branch, and Semester you follow. This ensures your profile and dashboard are complete even on a fresh install.

## Proposed Changes

### 1. Real Organization Discovery
#### [MODIFY] [firestore_org_remote.dart](file:///C:/StandIn/lib/src/data/remote/firestore_org_remote.dart)
- **[NEW]** `searchOrganizations(String query, OrganizationType type)`: Performs a Firestore query filtered by type and name prefix.
- **[NEW]** `getOrganization(String orgId)`: Fetches a single organization document.
- **[NEW]** `getScope(String orgId, String scopeId)`: Fetches a single scope document.

#### [MODIFY] [organization_repository.dart](file:///C:/StandIn/lib/src/data/organization_repository.dart)
- **[NEW]** `searchOrganizations(String query, OrganizationType type)`: Orchestrates remote search and local caching of results.

#### [MODIFY] [organization_search_page.dart](file:///C:/StandIn/lib/src/features/onboarding/organization_search_page.dart)
- Remove `_mockOrgs`.
- Update `_onSearch` to call the repository through the `OnboardingController`.

### 2. Session & Context Recovery
#### [MODIFY] [firestore_user_remote.dart](file:///C:/StandIn/lib/src/data/remote/firestore_user_remote.dart)
- **[NEW]** `getFollows(String uid)`: Fetches all followed organizations for the user.

#### [MODIFY] [organization_repository.dart](file:///C:/StandIn/lib/src/data/organization_repository.dart)
- **[NEW]** `syncFollowContext(String uid, String followId)`: A "recovery" method that fetches the `Follow` document, then recursively fetches and caches the `Organization`, `Scope` hierarchy, active `Policy`, and `Calendar`.

#### [MODIFY] [sync_engine.dart](file:///C:/StandIn/lib/src/data/sync/sync_engine.dart)
- In `_pullRemoteChanges()`, add a phase to call `syncFollowContext` for the active follow ID. This ensures the "Unknown Organization" problem is solved on new device login.

### 3. Profile Context Enhancement
#### [MODIFY] [app.dart](file:///C:/StandIn/lib/src/app.dart)
- Refactor `ProfilePage` to robustly resolve labels for the entire hierarchy (College -> Branch -> Semester).
- Ensure "Academic Period" dates are shown clearly.
- Maintain strict visual separation between "Official Rules" and "My Attendance Settings".

---

## Verification Plan

### Manual Scenarios
1. **Student Search**: Login as Student. Search "Wells". Verify ONLY colleges appear. Verify "Global Tech Corp" (if it exists) is hidden.
2. **Employee Search**: Login as Employee. Search "Wells". Verify ONLY companies appear.
3. **New Device Recovery**:
    - Device 1: Follow "ABC College -> CSE -> Sem 3". Mark attendance.
    - Device 2: Login with same account.
    - **Verify**: The app immediately pulls the names "ABC College", "CSE", and "Sem 3" along with the rules and calendar. Dashboard should NOT show "Unknown".
4. **Profile Check**: Open Profile. Verify it shows the 3-level hierarchy and distinguishes between the 75% official target and any personal 80% override.

### Automated Tests
- **`discovery_filter_test.dart`**: (NEW) Verify that repository-level search respects the `OrganizationType`.
- **`context_sync_test.dart`**: (NEW) Verify that `syncFollowContext` correctly populates the local Drift database.
