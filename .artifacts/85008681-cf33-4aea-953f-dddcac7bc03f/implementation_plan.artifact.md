# Implementation Plan: Fix WebAssembly Magic Word Error (Drift Web Migration)

The error `expected magic word 00 61 73 6d, found 3c 21 44 4f` indicates that the browser attempted to load a WebAssembly (`.wasm`) file but received an HTML document instead (likely a 404 fallback to `index.html`).

This is occurring because the project is in a partially migrated state:
1. `index.html` loads legacy `sql-wasm.js` which tries to fetch a `.wasm` file that doesn't exist in the expected location.
2. `web.dart` uses the legacy `WebDatabase` implementation.
3. Modern Drift WASM assets (`sqlite3.wasm`, `drift_worker.js`) are either missing or incomplete in the `web/` directory.

## User Review Required

> [!IMPORTANT]
> **Asset Download**: I will download the official SQLite WASM and Drift Worker files directly into your `web/` directory. This is required for the modern storage engine to function.
> **Dependency**: This fix relies on `drift_flutter` which is already in your `pubspec.yaml`.

## Proposed Changes

### 1. Unified Connection Logic
#### [MODIFY] [web.dart](file:///C:/StandIn/lib/src/data/local/connection/web.dart)
- Replace legacy `WebDatabase` with `driftDatabase` from `package:drift_flutter`.
- This aligns the Web implementation with the Native implementation in [native.dart](file:///C:/StandIn/lib/src/data/local/connection/native.dart), providing a more robust and persistent storage backend.

### 2. Cleanup Web Assets
#### [MODIFY] [index.html](file:///C:/StandIn/web/index.html)
- Remove the `<script>` tag for `sql-wasm.js`. Modern Drift WASM does not need this script in the HTML; it loads the WASM engine dynamically via a web worker.

### 3. Install Required WASM Assets
#### [NEW] `web/drift_worker.js`
- I will fetch and save the `drift_worker.js` file required for multi-threaded SQLite on the web.
#### [UPDATE] `web/sqlite3.wasm`
- I will ensure `sqlite3.wasm` is present and at the correct version.

---

## Verification Plan

### Automated Tests
- Run `flutter analyze` to verify the new connection logic.

### Manual Verification
- After applying changes, run the app in Chrome (`flutter run -d chrome`).
- Open Browser DevTools (F12) -> Application -> IndexedDB.
- Confirm a database named `standin` (or similar) is created and the "magic word" error is gone from the console.
