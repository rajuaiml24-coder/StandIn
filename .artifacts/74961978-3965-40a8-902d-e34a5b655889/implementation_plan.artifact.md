# Implementation Plan - Follow Flow Period Selection Refinement

This plan outlines the changes to refine the organization follow flow, ensuring followers can easily inherit organization rules or customize their tracking period with minimal setup steps.

## Proposed Changes

### 1. Data Resolution

#### [MODIFY] [organization_repository.dart](file:///C:/StandIn/lib/src/data/organization_repository.dart)
- Update `getResolvedPolicy` to apply `personalEvaluationPeriod` from the `Follow` record even if other personal overrides (Basis/Target) are absent. This ensures the follower's choice on the preview page is respected in the dashboard.

### 2. Follower Onboarding Logic

#### [MODIFY] [onboarding_controller.dart](file:///C:/StandIn/lib/src/features/onboarding/onboarding_controller.dart)
- **New State Update**: Add `setPeriod(EvaluationPeriod period)` to allow updating the tracking period on the preview page without triggering a navigation transition.
- **Conditional Follow**: Update `useOfficialPolicy` to detect if the selected period differs from the organization default.
    - If same: Follow immediately (Complete).
    - If different: Transition to "Final Setups" (starting at `setupTarget`).
- **Short-circuit Setup**: Update `setTarget` and `setDates` to finish the flow (call `followOrganization`) for followers, bypassing redundant organization-level setup steps like Schedule/Weekly-off.

### 3. User Interface Refinements

#### [MODIFY] [policy_preview_page.dart](file:///C:/StandIn/lib/src/features/onboarding/policy_preview_page.dart)
- Update the tracking period radio buttons to use the new `controller.setPeriod` method.
- Ensure the "Follow This Organization" button correctly triggers the conditional logic in the controller.

#### [MODIFY] [policy_setup_target_page.dart](file:///C:/StandIn/lib/src/features/onboarding/policy_setup_target_page.dart)
- Initialize the target slider with the organization's inherited target value if available, providing a smoother experience when customizing.

## Verification Plan

### Automated Tests
- Run `flutter test test/org_selection_redesign_test.dart` and add scenarios for:
    - Default period inheritance (Zero-click finish).
    - Custom period selection (Setup Target sequence).

### Manual Verification
1. **Inherited Follow**: Select an organization, keep the default period, click "Follow". Verify you land on the dashboard immediately with organization rules applied.
2. **Custom Period Follow**: Select an organization, change the period (e.g., Monthly to Semester), click "Follow". Verify you are asked for your target and dates, then land on the dashboard with organization rules but your chosen period.
3. **New Org Creator**: Create a new organization and verify the full setup flow remains intact and functional.
