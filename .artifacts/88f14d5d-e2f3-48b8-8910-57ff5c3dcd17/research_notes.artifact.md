# Research Notes: ApiException 10 on Play Store Build

The error `com.google.android.gms.common.api.ApiException: 10` (CommonStatusCodes.DEVELOPER_ERROR) indicates a configuration mismatch between your app's signing certificate and the OAuth 2.0 client IDs registered in the Google Cloud or Firebase Console.

## Findings

- **Package Name**: `in.withwells.standin` (verified in `android/app/build.gradle.kts`).
- **Current SHA-1s**: Your `google-services.json` currently contains three registered certificate hashes:
  - `193442fbb9906056711ae71a43822b7eb51fce48`
  - `6bd56160a4a12e40ef3ac7ef9869a5f81ba3e062`
  - `a4982b40b4ed85e03ac19c4710d7fa7127da1b1b`

## Root Cause
When you upload an app to the Play Store, **Google Play App Signing** re-signs your app with a unique key maintained by Google. This key's SHA-1 fingerprint is different from your local debug and release/upload keys. If this third SHA-1 is missing from Firebase, Google Sign-In will fail with `ApiException: 10`.

## Step-by-Step Resolution

### 1. Retrieve the Google Play SHA-1
1. Log in to the [Google Play Console](https://play.google.com/console/).
2. Select the **StandIn** app.
3. In the left menu, go to **Setup** > **App Integrity**.
4. Click on the **App Signing** tab.
5. Locate the **App signing key certificate** section.
6. Copy the **SHA-1 certificate fingerprint**.

### 2. Add SHA-1 to Firebase
1. Go to the [Firebase Console](https://console.firebase.google.com/).
2. Open **Project Settings** (gear icon) > **General**.
3. Scroll down to **Your apps** and select the Android app (`in.withwells.standin`).
4. Click **Add fingerprint**.
5. Paste the SHA-1 you copied from the Play Console and click **Save**.

### 3. Verify OAuth Consent Screen
1. Go to the [Google Cloud Console Credentials page](https://console.cloud.google.com/apis/credentials).
2. Ensure that the **OAuth Consent Screen** is set to **Production** (not Testing) if you want anyone to be able to sign in.
3. If it is still in **Testing**, you must explicitly add all tester email addresses to the **Test users** list in the Google Cloud Console.

### 4. (Optional but Recommended) Refresh Config
1. Download the updated `google-services.json` from Firebase.
2. Replace the file at `android/app/google-services.json`.
3. Note: This is usually not required for the fix to take effect as the verification happens server-side, but it ensures your local config matches the server state.

> [!IMPORTANT]
> After adding the SHA-1 to Firebase, it can take **5-10 minutes** for Google's servers to propagate the change. You do NOT need to upload a new build to the Play Store for this change to take effect.
