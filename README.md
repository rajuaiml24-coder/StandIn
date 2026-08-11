# StandIn

Offline-first attendance planning for students and hybrid employees. The app is structured as UI -> controller -> repository -> local database / cloud sync.

## Setup

1. Install Flutter 3.24+ and add it to `PATH`.
2. Run `flutter pub get`.
3. Add platform Firebase configuration (`google-services.json` / `GoogleService-Info.plist`) before enabling Firebase services.
4. Generate Drift code after adding the production database implementation: `dart run build_runner build --delete-conflicting-outputs`.

The present app uses a local development repository so its complete interaction flow works before Firebase configuration. Replace the composition root with `StandInSyncRepository` after wiring Firebase and Drift.
