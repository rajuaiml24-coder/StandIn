# Organization Setup Onboarding Walkthrough

I have completed the implementation of the full Organization Setup flow within the onboarding process. This implementation ensures a smooth transition from a generic "Follower" to a potentially "Verified Member" in the future, while maintaining strict data privacy and validation standards.

## Key Accomplishments

### 1. Flexible Organization Onboarding
- **Search & Follow**: Users can search for existing colleges or companies and follow their verified policies instantly.
- **Manual Creation**: If an organization is not found, users can create a minimal profile.
    - **Draft Policy**: As requested, manually created organizations are initialized with a "Draft" status. Users provide their own initial target percentage and full-day hours, which are clearly marked as non-official.
- **Identification Mapping**: Integrated a dedicated step to capture **Roll Numbers** (Students) or **Employee IDs** (Employees). This data is stored locally to facilitate future verified membership linking.

### 2. Enhanced UI & Responsiveness
- **`OrganizationCreatePage`**: A clean, minimal form for manual entry with built-in validation.
- **`OrganizationIdPage`**: Adapts its labels and hints based on the user's role (Student vs. Employee).
- **`PolicyPreviewPage`**: Updated to show a "DRAFT" badge for community-created organizations and a "Verified" icon for official ones.
- **Responsiveness**: All new screens follow the `SingleChildScrollView` + `IntrinsicHeight` pattern to prevent overflows on all device sizes.

### 3. Robust Domain & Validation
- **Centralized Logic**: Added `IdValidator` and `OrganizationNameValidator` to the testable domain layer.
- **Domain Evolution**: Updated `UserProfile` and `Organization` models to support the new metadata (types, identification numbers, verification states).

## Verification Results

### Automated Checks
| Command | Result |
| :--- | :--- |
| `flutter analyze` | **Passed** (No issues found) |
| `flutter test` | **Passed** (28 tests including new validator cases) |
| `flutter build web` | **Success** (Built successfully) |

## Files Modified/Created

| File | Change Type | Description |
| :--- | :--- | :--- |
| [attendance.dart](file:///C:/StandIn/lib/src/domain/attendance.dart) | MODIFY | Updated User and Organization domain models. |
| [validators.dart](file:///C:/StandIn/lib/src/domain/validators.dart) | MODIFY | Added ID and Org Name validators. |
| [onboarding_controller.dart](file:///C:/StandIn/lib/src/features/onboarding/onboarding_controller.dart) | MODIFY | Expanded state machine for the full flow. |
| [organization_create_page.dart](file:///C:/StandIn/lib/src/features/onboarding/organization_create_page.dart) | **NEW** | UI for manual organization creation. |
| [organization_id_page.dart](file:///C:/StandIn/lib/src/features/onboarding/organization_id_page.dart) | **NEW** | UI for capturing identification numbers. |
| [organization_search_page.dart](file:///C:/StandIn/lib/src/features/onboarding/organization_search_page.dart) | MODIFY | Enhanced search with branch and "Create New" option. |
| [policy_preview_page.dart](file:///C:/StandIn/lib/src/features/onboarding/policy_preview_page.dart) | MODIFY | Added support for Draft vs Verified states. |
| [app.dart](file:///C:/StandIn/lib/src/app.dart) | MODIFY | Integrated new pages into the onboarding flow. |
| [validators_test.dart](file:///C:/StandIn/test/validators_test.dart) | MODIFY | Added unit tests for new validators. |

> [!IMPORTANT]
> **Draft Policies**: Community-created organizations explicitly show: *"This policy is personal and not official until verified."* to maintain trust and transparency.
