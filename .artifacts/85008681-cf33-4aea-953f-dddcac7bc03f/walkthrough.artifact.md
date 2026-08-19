# Walkthrough: Semester Calculation & Profile Context Fixes

I have fixed the semester calculation bug, resolved the unit display inconsistencies, and implemented a comprehensive "Following Context" in the user profile.

## Key Fixes

### 1. Semester Attendance Calculation
Previously, the app failed to calculate semester progress because it was resolving rules using a "global" scope instead of the specific Semester scope.
- **Context-Aware Resolution**: I refactored the app startup to load your active `Follow` record first. StandIn now uses the exact College, Branch, and Semester IDs saved in your follow record to resolve rules.
- **Academic Period Enforcement**: This fix ensures that your Semester's **Start and End dates** are correctly loaded into the `PolicyEngine`, enabling accurate tracking for long-term periods.

### 2. Intelligent Unit Formatting
Fixed the bug where "classes" were referred to as "periods" and pluralization was incorrect (e.g., "1 days").
- **Centralized Mapping**:
    - `periods` -> **"class" / "classes"**
    - `hours` -> **"hour" / "hours"**
    - `days` -> **"day" / "days"**
- **Natural Pluralization**: All recovery messages and dashboard cards now use grammatically correct labels based on the actual value (e.g., "Attend 1 more class" vs "Attend 2 more classes").

### 3. Profile Context & Data Isolation
The Profile page is now a live view of your tracking hierarchy, clearly distinguishing between community rules and your private settings.
- **Full Hierarchy View**: See exactly which institution, branch, and semester you are following.
- **Academic Period Summary**: Displays your semester's date range (e.g., Aug 2026 – Nov 2026) directly on the profile.
- **Privacy Separation**:
    - **"Official Attendance Rules"**: Shows the shared requirements for your cohort.
    - **"My Attendance Settings"**: Displays your private overrides (e.g., a personal 80% target), ensuring these choices never overwrite organization data or affect other students.

## Changes Made

### Domain & Logic
- **`attendance.dart`**: Added `CalculationBasis.label(double value)` for centralized formatting.
- **`policy_engine.dart`**: Updated `summarize` to use dynamic unit labels in recovery messages.

### App Architecture
- **`app.dart`**:
    - Refactored `StandInApp` to resolve the `Follow` record before loading the Dashboard.
    - Implemented a context-aware `ProfilePage` using local Drift data.
    - Fixed the status label logic in `_AttendanceHero` (now correctly shows "• AT RISK").

## Verification Results

### Automated Tests
- **`unit_formatting_test.dart`**: Verified that "class/classes", "hour/hours", and "day/days" resolve correctly for both singular and plural values.
- **`semester_resolution_test.dart`**: Confirmed that rules for a specific Semester are correctly resolved when followed, including start/end dates.

### Manual Scenarios Verified
| Scenario | Behavior |
| :--- | :--- |
| **Semester Tracking** | Mark attendance in a Semester-based period. Verified % updates on Dashboard. |
| **Unit Consistency** | Changed basis to Hours. Verified AdviceCard showed "X more hours". |
| **Profile Isolation** | Verified that personal target overrides on the Profile page are correctly labeled and private to the user. |

> [!TIP]
> Your tracking is now fully **context-aware**. If you follow a Semester, the app uses that specific academic window; if you follow a Branch, it falls back to departmental rules automatically.
