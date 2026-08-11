# Implementation Plan: Finalize Organization Setup Onboarding

This plan outlines the completion of the Organization Setup flow within the onboarding process, supporting both Students and Employees with minimal friction.

## User Review Required

> [!IMPORTANT]
> **Verification Strategy**: Roll Numbers and Employee IDs will be captured during onboarding but will be treated as "Follower" data initially. The system architecture will support a future transition to "Verified Member" without data loss or account duplication.
> **Minimal Creation**: If an organization is not listed, the user can create a minimal profile (Name and Type) to proceed immediately.

## Proposed Changes

### [Domain & Logic]

#### [MODIFY] [validators.dart](file:///C:/StandIn/lib/src/domain/validators.dart)
- Add `IdValidator` for Roll Numbers and Employee IDs (3-20 alphanumeric characters).
- Add `OrganizationNameValidator` (3-100 characters).

#### [MODIFY] [attendance.dart](file:///C:/StandIn/lib/src/domain/attendance.dart)
- Update `UserProfile` to include `identificationNumber` (Roll No/Emp ID) and `isOrganizationVerified`.
- Update `Organization` to include `type` (College/Company).

#### [MODIFY] [onboarding_controller.dart](file:///C:/StandIn/lib/src/features/onboarding/onboarding_controller.dart)
- Expand `OnboardingStep` to include:
    - `organizationId`: For Roll Number or Employee ID.
    - `organizationCreate`: For manual creation if search fails.
- Add properties to track:
    - `identificationNumber`: The user's ID within the org.
    - `isCreatingNewOrganization`: Flag to distinguish from following existing.
- Implement logic to handle branch selection (as part of search or separate step).

---

### [UI/UX]

#### [MODIFY] [organization_search_page.dart](file:///C:/StandIn/lib/src/features/onboarding/organization_search_page.dart)
- Enhance search results to clearly show branch/campus.
- Add "Create New Organization" button that leads to `organizationCreate`.

#### [NEW] [organization_create_page.dart](file:///C:/StandIn/lib/src/features/onboarding/organization_create_page.dart)
- Minimal form: Name and Branch/Campus.
- Assign a default "MVP Policy" (e.g., 75% target, 7h full day).

#### [NEW] [organization_id_page.dart](file:///C:/StandIn/lib/src/features/onboarding/organization_id_page.dart)
- Captures Roll Number (for Students) or Employee ID (for Employees).
- Clearly labeled based on the selected role.
- Support "Skip for now" if appropriate (optional based on final review).

#### [MODIFY] [policy_preview_page.dart](file:///C:/StandIn/lib/src/features/onboarding/policy_preview_page.dart)
- Finalize layout to show all policy details before the user clicks "Follow Policy".

---

### [Testing & Verification]

- Add unit tests for `IdValidator` and `OrganizationNameValidator`.
- Update `OnboardingController` tests to cover the expanded flow.
- Run `flutter analyze`, `flutter test`, and `flutter build web`.

## Roadmap
1. Update Domain & Validators.
2. Update Controller logic and state.
3. Implement `OrganizationCreatePage` and `OrganizationIdPage`.
4. Enhance `OrganizationSearchPage` and `PolicyPreviewPage`.
5. Final verification.
