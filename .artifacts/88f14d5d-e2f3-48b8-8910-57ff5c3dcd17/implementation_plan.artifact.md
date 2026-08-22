# Implementation Plan - Final Test Suite Fixes

Restore the test suite to 81/81 by aligning test setups and mocks with the corrected "Inherit by Default" and "Authoritative Resolution" production behavior.

## User Review Required

> [!IMPORTANT]
> - **Inheritance Logic**: I am updating `Scenario A` and `Scenario E` in `policy_onboarding_test.dart` to correctly simulate organization metadata (including `activePolicyId`). This ensures that the production inheritance logic (which uses these IDs) works as intended in the test environment.
> - **Enum Cleanup**: I am removing all references to the obsolete `OnboardingStep.policyMissing` from the test files to match the cleaned-up production `OnboardingStep` enum.

## Proposed Changes

### Tests & Mocks
#### [MODIFY] [direct_follow_test.dart](file:///C:/StandIn/test/direct_follow_test.dart)
- Update mock stubs for `OrganizationRepository`:
    - Add `saveOrganizationMetadata`.
    - Add `incrementFollowerCount`.
    - Add `getResolvedPolicy`.
- Update `OnboardingStep` expectations to match the new flow (removing `policyMissing`).

#### [MODIFY] [simplified_follow_test.dart](file:///C:/StandIn/test/simplified_follow_test.dart)
- Similar mock updates as `direct_follow_test.dart`.
- Update `OnboardingStep` expectations.

#### [MODIFY] [policy_onboarding_test.dart](file:///C:/StandIn/test/policy_onboarding_test.dart)
- **Scenario A**:
    - Provide `activePolicyId` in the `Organization` object.
    - Seed Firestore with a basic organization document containing matching metadata.
    - Expect `PolicyState.official` (as the follower now correctly inherits rules without redundant overrides).
- **Scenario E**:
    - Ensure the organization metadata (including its later-added `activePolicyId`) is correctly resolved to trigger the conflict state.
    - Remove redundant ID entry steps.

## Verification Plan

### Automated Tests
- Run `flutter analyze` to ensure no errors.
- Run `flutter test` and confirm **81/81 passed**.

### Manual Verification
- No manual verification required at this stage as per instructions.
