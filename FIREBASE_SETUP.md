# StandIn Firebase setup

StandIn must use a new Firebase project. Do not reuse a WithWells or other production project.

1. Create a new Firebase project, for example `standin-production`.
2. Register an Android app with package name `in.withwells.standin`.
3. Download `google-services.json` and place it at `android/app/google-services.json`.
4. Run `flutterfire configure` from this project, selecting only the new StandIn Firebase project. This generates `lib/firebase_options.dart` and configures Android Gradle integration.
5. Enable Email/Password in Firebase Authentication. Do not enable Phone authentication for this MVP.
6. Create Firestore in the intended region. Do not deploy the included rules yet.

Project credentials are intentionally not supplied by this repository.
