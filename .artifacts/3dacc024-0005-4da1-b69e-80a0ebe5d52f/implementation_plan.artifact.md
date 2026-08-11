# Implementation Plan: Fix Drift Web Initialization

This plan addresses the `ArgumentError` when initializing the Drift database on Web/PWA: "When compiling to the web, the `web` parameter needs to be set."

## User Review Required

> [!IMPORTANT]
> **Drift Web Assets**: Drift on Web requires `sqlite3.wasm` and `drift_worker.js` to be present in the `web/` directory for optimal performance and persistent storage. I will configure the app to look for these files.
> **PWA Support**: Proper web initialization is critical for local-first behavior on PWA, ensuring data is persisted across browser refreshes and offline sessions.

## Proposed Changes

### 1. Fix StandInDatabase Initialization
#### [MODIFY] [standin_database.dart](file:///C:/StandIn/lib/src/data/local/standin_database.dart)
- Update the `StandInDatabase` constructor to provide `DriftWebOptions` to the `driftDatabase` function.
- Configure `sqlite3Wasm` and `driftWorker` paths.

### 2. Verify Data Model Consistency
- Ensure that the web implementation uses the same schema and naming conventions as the Android implementation.

## Verification Plan

### Automated Tests
- Run `flutter analyze` to ensure no syntax issues.
- Run `flutter test` to ensure existing logic tests pass.
- Run `flutter build web` to verify the build process.

### Manual Verification
- Run the Web/PWA preview.
- Confirm that the "ArgumentError" is resolved and the app loads the Landing screen.
- Verify that "Continue with Google" is visible.
