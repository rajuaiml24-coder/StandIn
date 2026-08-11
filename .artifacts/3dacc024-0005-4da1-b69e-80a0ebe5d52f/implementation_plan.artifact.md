# Implementation Plan: PolicyEngine Refinement (Custom Periods & Estimation)

This plan implements the final corrections to the `PolicyEngine` to support explicit semester dates, holiday calendar awareness, and improved recovery phrasing.

## User Review Required

> [!IMPORTANT]
> **Custom Period Dates**: Semester and Academic Year periods now **require** `startDate` and `endDate` in the policy. If they are null for these period types, the engine will flag the summary as `isPolicyIncomplete` and return 0 for prospective calculations.
> **Estimation Flag**: A new `isEstimation` flag in `AttendanceSummary` will indicate if calculations are based on an incomplete future holiday calendar.
> **Organization Context**: The `PolicyEngine.summarize` method will now require a `bool isHolidayCalendarConfigured` parameter.

## Proposed Changes

### [Domain & Logic]

#### [MODIFY] [attendance.dart](file:///C:/StandIn/lib/src/domain/attendance.dart)
- **`AttendancePolicy`**:
    - Add `startDate` (DateTime?).
    - Add `endDate` (DateTime?).
- **`AttendanceSummary`**:
    - Add `isEstimation` (bool).
    - Add `recoveryMessage` (String) to house the user-friendly recovery wording.

#### [MODIFY] [policy_engine.dart](file:///C:/StandIn/lib/src/domain/policy_engine.dart)
- **`summarize`**:
    - Add `isHolidayCalendarConfigured` parameter.
    - Update `_getPeriodRange` to use explicit `startDate`/`endDate` for `semester`, `academicYear`, and `halfYear`.
    - If explicit dates are missing for these types, return an incomplete summary.
    - Set `isEstimation = !isHolidayCalendarConfigured`.
- **Message Generation**:
    - Implement a helper to generate user-friendly recovery text: "Attend the next 6 classes", "Attend the next 3 working days", etc.

---

### [Data Layer Compatibility]

#### [MODIFY] [standin_database.dart](file:///C:/StandIn/lib/src/data/local/standin_database.dart)
- Update `OrganizationPolicyRows` table:
    - Add `startDate` (dateTime().nullable()).
    - Add `endDate` (dateTime().nullable()).
- Update `OrganizationRows` (if exists) or ensure repository can pass `isHolidayCalendarConfigured`.

#### [MODIFY] [organization_policy_repository.dart](file:///C:/StandIn/lib/src/data/organization_policy_repository.dart)
- Map new `startDate`/`endDate` fields.

---

### [Testing]

#### [MODIFY] [policy_engine_test.dart](file:///C:/StandIn/test/policy_engine_test.dart)
- Add tests for:
    - Custom semester dates (valid).
    - Missing semester dates (incomplete result).
    - `isEstimation` flag when holiday calendar is incomplete.
    - Verify recovery messages follow the "Attend the next X [units]" pattern.

## Verification Plan

### Automated Tests
- Run `flutter test test/policy_engine_test.dart`.
- Run `flutter analyze`.

### Final Build
- Run `flutter build web` to ensure PWA compatibility.
