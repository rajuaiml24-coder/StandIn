# Implementation Plan: End-to-End Firebase Integration Test

This plan outlines a comprehensive integration test to verify the full StandIn stack (Drift + Firestore + Sync) under real-world scenarios.

## User Review Required

> [!IMPORTANT]
> **Real Data**: This test will interact with the actual `standin-5755d` project. I will use unique, temporary test IDs (e.g., `test_user_xyz`) to avoid pollution.
> **Environment**: I will attempt to run these tests using `flutter test`. If network or credential issues arise, I will provide a script that can be run in a production-ready environment.

## Test Scenario Breakdown

### 1. Account & Identity
- **Steps**: Create a new account, generate a unique username, verify uniqueness check, and set up a PIN.
- **Verification**: Check `usernames` and `users` collections in Firestore.

### 2. Organization & Following
- **Steps**: Create a test organization, search for it, and "follow" it.
- **Verification**: Check `organizations` and `users/{uid}/follows` collections.

### 3. Policy & Calendar Resolution
- **Steps**: Define a policy for the organization and verify that the client resolves it correctly (Hierarchy: Personal -> Scope -> Org).
- **Verification**: Assert correct `AttendancePolicy` object in `AttendanceController`.

### 4. Attendance & Sync (Local-First)
- **Scenario A (Online)**: Mark attendance -> Verify Drift write -> Trigger Sync -> Verify Firestore update.
- **Scenario B (Offline)**: Mark attendance -> Verify Drift write -> Simulate restart -> Trigger Sync -> Verify Firestore.
- **Scenario C (Conflict)**: Verify that two users following the same org get independent attendance records.

### 5. Security Boundaries
- **Steps**: Attempt to modify `isAdmin` or another user's attendance record.
- **Verification**: Confirm that Firestore rules reject the operation with a `PERMISSION_DENIED` error.

## Proposed Changes

#### [NEW] [firebase_integration_e2e_test.dart](file:///C:/StandIn/test/firebase_integration_e2e_test.dart)
- A specialized test file that orchestrates the above steps using the production `AuthService`, `UserRepository`, `OrganizationRepository`, and `SyncEngine`.

## Verification Plan

### Execution
- Run `flutter test test/firebase_integration_e2e_test.dart`.
- Monitor console output for PASS/FAIL on each step.

### Post-Test Cleanup
- I will include a cleanup step in the test to delete temporary `test_*` documents if possible (subject to security rules).
