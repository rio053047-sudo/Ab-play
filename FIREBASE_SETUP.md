# Firebase Authentication setup

The app uses Firebase Authentication for Google, email-link, email/password, and existing phone sign-in. Firebase client configuration is intentionally not committed. Do not add service-account JSON files or private keys to this repository.

## Firebase Console

1. Open **Project settings** and register the Android app with package name `com.abplay.app`.
2. Add the SHA-1 and SHA-256 certificate fingerprints for every signing certificate used to install the app (debug, local release, and Play App Signing as applicable).
3. Download that Android app's `google-services.json` and place it at `android/app/google-services.json`. The file is ignored by Git.
4. In **Authentication → Sign-in method**, enable **Email/Password**, **Email link (passwordless sign-in)**, **Google**, and **Phone** if phone SMS sign-in is used. Email link requires Email/Password to remain enabled.
5. In **Authentication → Templates**, review the **Email address verification** and **Password reset** messages and sender details. Firebase's default templates work; if you customize action URLs, use an authorized domain.
6. In **Authentication → Settings → Authorized domains**, authorize `abplay.app` for the email-link continue URL.
7. In the Android app settings, verify the package name and signing fingerprints are saved. Configure the project's mobile email-link domain as its Firebase Hosting default domain (`<PROJECT_ID>.firebaseapp.com`) in the Firebase Authentication project configuration. If the project still points at Firebase Dynamic Links, update `mobileLinksConfig.domain` with the Firebase Admin SDK using an authorized server environment. Firebase Hosting email links use `/__/auth/links`; this app does not use Firebase Dynamic Links.
8. For Google sign-in, set the Web OAuth client ID from this Firebase project's Google provider configuration as the `GOOGLE_SERVER_CLIENT_ID` Dart define when launching/building the app. It is an OAuth client identifier, not a service-account credential.

## Local Android configuration

The Gradle build reads the Firebase project ID from `google-services.json` and uses it for the App Links host. If you need to supply the host explicitly, set the project ID in the ignored `android/local.properties` file. Keep the existing `flutter.sdk` line and add:

```properties
firebase.projectId=your-firebase-project-id
```

The Android manifest uses that ID to claim `https://<PROJECT_ID>.firebaseapp.com/__/auth/links`. If you use a custom Firebase Hosting domain for mobile links, also pass its hostname at build time:

```text
--dart-define=FIREBASE_EMAIL_LINK_DOMAIN=auth.example.com
```

The custom domain must be configured in Firebase Hosting and selected as the project's mobile email-link domain. `abplay.app` is used only as the authorized continue URL; it does not need to be the mobile link domain.

## Android Studio

1. Open the `Ab-Play` project root, copy `google-services.json` into `android/app`, and add `firebase.projectId` to `android/local.properties`.
2. Sync Gradle and run the app on a device or emulator with Google Play services.
3. Confirm the debug signing SHA-1 and SHA-256 are registered in Firebase before testing Google sign-in or verified App Links. Register release and Play signing fingerprints before distributing those builds.
4. Create an Email/Password account, verify the message reaches the mailbox, and confirm Ab-Play enters Home only after tapping **I have verified my email**.
5. Test **Forgot password?** using an account you control and confirm the Firebase reset email arrives.
6. Test email link sign-in on the same device first. If the link is opened on another device, enter the same email in Ab-Play and tap **Complete sign-in with this email**.

For Google sign-in, set this in **Run → Edit Configurations → Additional run args** (replace the value with the Web client ID from Firebase):

```text
--dart-define=GOOGLE_SERVER_CLIENT_ID=your-web-client-id.apps.googleusercontent.com
```

Firebase must be configured in Console and the app's Firebase configuration file must be supplied locally before real network authentication can be tested. Email/password users and their Firebase UIDs are retained by Firebase; Google sign-in now uses the Firebase UID as the app profile ID.
