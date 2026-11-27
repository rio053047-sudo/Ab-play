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

## Voice Room backend and live RTC

Voice Rooms use Firestore for room/member/seat/event/wallet records, Realtime Database for disconnect presence, Cloud Storage for room covers, Firebase callable Cloud Functions for permission-checked writes, and Agora RTC for live audio. Client writes to room records, seat assignments, wallets, gift transactions, and events are denied by the checked-in rules.

1. In Firebase Console, enable **Cloud Firestore**, **Realtime Database**, and **Cloud Storage** for the same project. Set the Realtime Database URL in `google-services.json` (`firebase_database_url`). Keep the Android package name `com.abplay.app`.
2. Enable **Cloud Functions** billing (Blaze plan is required for deployment and the Realtime Database trigger). Use Node.js 22 for Functions.
3. In Agora Console, create an RTC project, copy its App ID and App Certificate, and enable token authentication. Enable **Co-host Authentication** so audience tokens cannot publish microphone audio. The App Certificate must remain server-side.
4. From the repository root, select the Firebase project (`firebase use <project-id>`). Set the server secrets interactively; do not put their values in source files or commit them:

   ```text
   firebase functions:secrets:set AGORA_APP_ID
   firebase functions:secrets:set AGORA_APP_CERTIFICATE
   firebase functions:secrets:set ROOM_PASSWORD_PEPPER
   ```

   Use a cryptographically random value of at least 32 bytes for `ROOM_PASSWORD_PEPPER`. Keep a backup in the organization's secret manager; changing it prevents users from using existing private-room passwords until they are reset.
5. In **App Check**, register the Android app. For local debug builds, use the debug provider and register the debug token printed by Firebase App Check in the Console. For release, register Play Integrity and configure the Play signing certificate. The callable backend enforces App Check.
6. Deploy the backend and security rules from the root:

   ```text
   firebase deploy --only functions,firestore:rules,firestore:indexes,database,storage
   ```

7. Confirm the Cloud Functions Realtime Database trigger region matches the Realtime Database instance region. The configured callable region is `asia-south1`.
8. Wallets start at **0 coins**. This repository has no payment/top-up provider; do not grant balances from Flutter. Before production gifts can be used, implement and review a trusted payment or administrative wallet-credit flow on the server.

The Agora Flutter client now requires the App ID, channel-specific token, and unique RTC UID returned by the authenticated backend; it contains no fallback App ID or certificate. A successful local build does not prove Firebase deployment, Agora token validity, or two-device audio. Run the two-device verification below only after Firebase and Agora setup is complete.

### Two Android phone verification checklist

Use two physical Android phones, two separate Firebase accounts, the same deployed Firebase project, and the same production-configured Agora App ID. Install the same current build on both phones. Record the build SHA, user/room IDs, timestamp, and actual device results; never mark a step passed from emulator or unit-test results alone.

1. Phone A signs in with Account A; Phone B signs in with Account B.
2. Phone A creates a public room and shares its displayed room ID.
3. Phone B finds the room in discovery and joins; both member lists show both Firebase UIDs.
4. Have A speak while B confirms audible speech, then repeat B to A.
5. Toggle each microphone off/on and confirm the other phone hears the change.
6. Have the host assign and remove a participant's speaker seat; confirm both clients update.
7. Send a gift only after the sender wallet is funded via the approved server flow; verify event animation, recipient coin-back policy, gift wall/history, and contribution rank.
8. Leave/rejoin; verify participant counts and seats recover from server state.
9. Create a private room; verify no password is rejected and the correct password is accepted.
10. Disable Wi-Fi or mobile data briefly on one phone, restore it, and confirm RTC and presence reconnect without a duplicate member or gift transaction.

No physical-device run or live Firebase/Agora deployment was performed as part of the code change; these results remain pending until executed and recorded.
