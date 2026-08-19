# Implementation Plan - Simplified Organization Following Flow

This plan pivots the organization discovery flow to a direct "Search -> Select -> Follow" model for the initial Play Store release. This ensures a reliable experience by inheriting official policies while maintaining independent personal calendars, without the complexity of mandatory hierarchical scopes.

## User Review Required

> [!IMPORTANT]
> **Flow Change**: Followers will now skip "Branch" and "Semester" selection. They will follow the organization directly at the root level and go straight to the Dashboard.
>
> **Data Model**: Branch and Semester logic remains in the codebase and is used by organization creators. It will be reintroduced as optional context for followers in a later release.

> [!CAUTION]
> **Security**: Firestore rules will strictly enforce that only the organization's creator (identified by `createdBy`) can define or add to the official configuration (scopes, policies, calendars). Followers will have read-only access to this shared data.

## Proposed Changes

### [Onboarding] Simplified Follow Path

#### [MODIFY] [onboarding_controller.dart](file:///C:/StandIn/lib/src/features/onboarding/onboarding_controller.dart)
- **Step Redirection**: Update `selectOrganization` to route directly to `organizationId` (for ID entry) or `policyDetection` instead of `scopeBranch`.
- **Detection Logic**: Update `completeOrganizationId` to use `scopeId = 'global'` when no branch/semester is selected.
- **Auto-Follow**: If an official policy is detected at the organization level, show the summary and allow the user to follow immediately.
- **State Preservation**: Ensure `_isCreatingNewOrganization` still triggers the full setup flow for creators.

### [Data] Inheritance & Personalization

#### [MODIFY] [organization_repository.dart](file:///C:/StandIn/lib/src/data/organization_repository.dart)
- **Hierarchical Fallback**: Ensure `getOfficialPolicyForScope` and `getOfficialCalendarForScope` correctly return organization-level defaults (`org-default`, `cal-global`) when called with `scopeId = 'global'`.
- **Template Copying**: In `followOrganization`, explicitly copy the official organization calendar values into the new `Follow` record's `personalWeeklyOffs` and `personalOffSaturdays` fields.

### [Security] Protected Configuration

#### [MODIFY] [firestore.rules](file:///C:/StandIn/firestore.rules)
- **Creator Check**: Implement a function `isOrgCreator(orgId)` that checks if `get(/organizations/$(orgId)).data.createdBy == request.auth.uid`.
- **Restricted Scopes/Policies/Calendars**:
    - `allow create: if signedIn() && isOrgCreator(orgId);`
    - `allow read: if signedIn();`
    - `allow update, delete: if isAdmin();`

### [UI] Streamlined Experience

#### [MODIFY] [organization_search_page.dart](file:///C:/StandIn/lib/src/features/onboarding/organization_search_page.dart)
- Remove automatic navigation to branch selection.

#### [MODIFY] [policy_preview_page.dart](file:///C:/StandIn/lib/src/features/onboarding/policy_preview_page.dart)
- Update text to reflect that the user is following the organization's official policy.

## Verification Plan

### Automated Tests
I will create a comprehensive test suite `test/simplified_follow_test.dart` covering:
1.  **Test 1**: Student searches and follows existing college -> reaches Dashboard.
2.  **Test 2**: Employee searches and follows existing company -> reaches Dashboard.
3.  **Test 3**: Verify NO `putOrganization` enqueued for followers.
4.  **Test 4**: Verify NO `putScope` enqueued for followers.
5.  **Test 5**: Verify NO `putPolicy` enqueued for followers.
6.  **Test 6**: Verify NO `putCalendar` enqueued for followers.
7.  **Test 7**: Verify `Follow` record contains inherited policy basis and target.
8.  **Test 8**: Verify user can update personal `Follow` week-offs without triggering remote organization writes.
9.  **Test 9**: Verify creator still performs all writes successfully.

### Manual Verification
1.  **Follow Flow**: Search "Swarnaandhra" -> Select -> Enter Roll Number -> View Policy -> "Follow" -> See Dashboard.
2.  **Creation Flow**: Search "New Org" -> "Create it" -> Fill Name -> Select Branch/Sem -> Set Policy -> Set Calendar -> "Complete".
3.  **Isolation Check**: Mark a personal holiday for Student B and verify Student A's dashboard calculation is unchanged.
