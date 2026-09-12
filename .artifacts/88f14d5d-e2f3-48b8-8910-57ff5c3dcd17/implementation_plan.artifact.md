# Implementation Plan - Account Restoration & Follower Count Self-Healing

Resolve the critical issue where clearing app cache forces existing users into onboarding, and ensure follower counts are authoritative and self-healing.

## User Review Required

> [!IMPORTANT]
> - **Authoritative Identity**: The app will now explicitly wait for authoritative Firestore data (Profile, Follow, and Organization) before deciding which screen to show. This prevents empty local databases from triggering the "new user" flow.
> - **Self-Healing Counts**: The `PolicyPreviewPage` will now trigger a one-time authoritative reconciliation of the `followerCount` from actual membership documents. This heals corrupted counts (like the "9 to 0" issue) without slowing down general search.

## Proposed Changes

### Core App Shell (`app.dart`)

#### [MODIFY] [_processAuthState](file:///C:/StandIn/lib/src/app.dart)
- Introduce a `isRestoring` boolean state.
- While `isRestoring` is true, the `build` method will show the "Restoring session..." UI.
- Update the logic to:
    1. Await `syncProfile`.
    2. If a profile exists and has an `activeFollowId`, await `orgRepo.syncFollowContext(...)`.
    3. Set `isRestoring = false`.
- This ensures the local database is rebuilt with essential metadata *before* the first render.

### Data Layer (`OrganizationRepository` & `FirestoreOrgRemote`)

#### [MODIFY] [firestore_org_remote.dart](file:///C:/StandIn/lib/src/data/remote/firestore_org_remote.dart)
- Add `reconcileFollowerCount(String orgId)`:
    - Performs an aggregate `count()` query on the `members` subcollection.
    - Updates the `followerCount` field on the organization document with the result.
- Add `leaveOrganizationAtomic({required String orgId, required String uid})`:
    - A transaction that deletes the member document and **decrements** the `followerCount`.

#### [MODIFY] [organization_repository.dart](file:///C:/StandIn/lib/src/data/organization_repository.dart)
- Update `getOrganization` to accept an optional `reconcile` flag.
- When `reconcile` is true, call the remote self-healing logic.
- Update `removeMembership` to use the new atomic leave operation.

### Onboarding Flow (`OnboardingController`)

#### [MODIFY] [selectOrganization](file:///C:/StandIn/lib/src/features/onboarding/onboarding_controller.dart)
- Call `getOrganization(org.id, forceRemote: true, reconcile: true)`.
- This ensures that when a user selects an organization for preview, the count is healed to the actual number of membership documents.

## Verification Plan

### Automated Tests
- Run `flutter test` (81/81 target).
- **New Test**: `test/reconciliation_test.dart` to verify that `reconcileFollowerCount` correctly sets the field to the number of member documents.
- **New Test**: `test/restoration_logic_test.dart` to verify that `_processAuthState` correctly awaits hierarchical sync.

### Manual Verification (Logical)
1. **Cache Clear**:
    - Log in to an existing account.
    - Manually delete the local Drift database (or clear app data).
    - Open the app. Verify it shows "Restoring session..." and then goes directly to the **Dashboard**, NOT onboarding.
2. **Count Healing**:
    - Manually set an organization's `followerCount` to `0` in Firestore while keeping members.
    - Search and select that organization in the app.
    - Verify the Preview page initially shows 0, then updates to the real count after reconciliation.
3. **Atomic Leave**:
    - Delete an account. Verify Firestore `followerCount` decrements by 1.
