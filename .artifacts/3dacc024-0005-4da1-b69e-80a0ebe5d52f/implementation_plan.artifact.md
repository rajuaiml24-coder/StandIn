# Implementation Plan: Fix Drift Web Initialization (Modern Wasm)

This plan addresses the "sql.js" and "WebAssembly MIME type" errors on Web/PWA by correctly implementing the modern Drift Wasm storage engine.

## User Review Required

> [!IMPORTANT]
> **One-Time Manual Step**: After I update the code, you will need to run a command to download the SQLite Wasm assets into your `web/` folder. I will provide the specific command.
> **Persistence**: This setup uses IndexedDB via Wasm, which is the most reliable way to ensure your attendance data persists across browser sessions and works offline in the PWA.

## Proposed Changes

### 1. Modernize Web Connection
#### [MODIFY] [web.dart](file:///C:/StandIn/lib/src/data/local/connection/web.dart)
- Replace legacy `WebDatabase` with the modern `WasmDatabase` implementation.
- Use `WasmDatabase.open()` which automatically manages the connection to the SQLite worker.

### 2. Update StandInDatabase Constructor
#### [MODIFY] [standin_database.dart](file:///C:/StandIn/lib/src/data/local/standin_database.dart)
- Clean up the constructor to use the refined connection factory.

### 3. Provide Asset Setup Script
#### [NEW] [setup_web.sh / setup_web.ps1]
- I will provide a script (or command) to download `sqlite3.wasm` and `drift_worker.js` from the official Drift repository.

## Verification Plan

### Automated
- Run `flutter analyze` to ensure syntax correctness.
- Run `flutter test` to ensure existing logic tests pass.

### Manual
- **Step 1**: Run the download command (to be provided).
- **Step 2**: Run the Web preview.
- **Step 3**: Confirm the app reaches the "Continue with Google" screen without Drift errors.
- **Step 4**: Verify data persistence by marking a test record and refreshing the page.
