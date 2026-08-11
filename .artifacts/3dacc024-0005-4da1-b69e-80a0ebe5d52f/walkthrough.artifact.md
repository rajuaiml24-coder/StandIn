# PolicyEngine Logic Upgrade Walkthrough

I have completed a significant upgrade to the `PolicyEngine` to support explicit academic periods, holiday calendar awareness, and improved prospective calculations.

## Key Accomplishments

### 1. Explicit Academic & Custom Periods
- **No More Assumptions**: Removed default date ranges for Semester and Academic Year periods. They now strictly use the `startDate` and `endDate` defined in the `AttendancePolicy`.
- **Incomplete Handling**: If these required dates are missing, the engine flags the summary as `isPolicyIncomplete` and returns neutral results for prospective math.

### 2. Holiday Calendar Awareness
- **Estimation Flag**: Added an `isEstimation` flag to `AttendanceSummary`.
- **Conditional Projections**: When the organization's holiday calendar is not fully configured (passed as `isHolidayCalendarConfigured`), the `safeToMiss` and `unitsToRecover` projections are marked as estimates.
- **Historical Durability**: The user's actual attendance percentage remains available and accurate based on historical records, even if future projections are estimated.

### 3. Prospective Projection Logic
- **`safeToMiss`**: Calculates the total units a user can miss *from the remaining working days* in the current period while staying at or above target.
- **`unitsToRecover`**: Calculates the exact number of units needed to bring the current percentage up to target relative to today.

### 4. Human-Friendly Messaging
- **Recovery Messages**: Generated dynamic, unit-aware text such as:
    - "Attend the next 6 classes"
    - "Attend the next 3 working days"
    - "Attend the next 14 hours"
- **Precision**: Handled rounding gracefully (e.g., "32 hours" instead of "32.0 hours").

## Verification Results

### Automated Checks
| Command | Result |
| :--- | :--- |
| `flutter analyze` | **Passed** (No issues found) |
| `flutter test` | **Passed** (42 tests covering all new logic and boundaries) |
| `flutter build web` | **Success** (Built successfully) |

## Files Modified/Created

| File | Change Type | Description |
| :--- | :--- | :--- |
| [attendance.dart](file:///C:/StandIn/lib/src/domain/attendance.dart) | MODIFY | Added `startDate`/`endDate` to Policy and `isEstimation`/`recoveryMessage` to Summary. |
| [policy_engine.dart](file:///C:/StandIn/lib/src/domain/policy_engine.dart) | MODIFY | Comprehensive logic upgrade for periods and projections. |
| [standin_database.dart](file:///C:/StandIn/lib/src/data/local/standin_database.dart) | MODIFY | Updated Drift schema for persistent period dates. |
| [policy_engine_test.dart](file:///C:/StandIn/test/policy_engine_test.dart) | MODIFY | Expanded to 42 tests covering all edge cases. |

## Final PolicyEngine Assumptions
1. **Capacity**: The engine calculates total period capacity by assuming all days within the `startDate` to `endDate` range are working days, minus `weeklyOffs`, unless an explicit holiday record exists.
2. **"Today"**: If today has no attendance record, it is treated as a future working unit for prospective calculations.
3. **Unit Consistency**: All records in a period must use the same unit (e.g., all hours or all days) for mathematical consistency.
