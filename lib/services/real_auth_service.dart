import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../models/user_profile.dart';
import 'auth_service.dart';

class RealAuthService implements AuthService {
  static const _pendingEmailKey = 'abplay_pending_email_sign_in';
  static const _androidPackageName = 'com.abplay.app';

  final String? serverClientId;
  bool _googleInitialized = false;
  bool _firebaseInitialized = false;
  final AppLinks _appLinks = AppLinks();
  final StreamController<String> _pendingEmailLinks =
      StreamController<String>.broadcast();
  StreamSubscription<Uri>? _appLinkSubscription;

  RealAuthService({this.serverClientId});

  @override
  Stream<String> get pendingEmailLinks => _pendingEmailLinks.stream;

  @override
  Future<void> initialize() async {
    await _ensureFirebaseInitialized();
    if (_appLinkSubscription != null) return;

    _appLinkSubscription = _appLinks.uriLinkStream.listen(
      (uri) => unawaited(_handleIncomingEmailLink(uri)),
      onError: (_) {},
    );
    final initialLink = await _appLinks.getInitialLink();
    if (initialLink != null) {
      await _handleIncomingEmailLink(initialLink);
    }
  }

  @override
  Future<UserProfile?> get currentUser async {
    await _ensureFirebaseInitialized();
    return _profile(FirebaseAuth.instance.currentUser);
  }

  @override
  Stream<UserProfile?> get authStateChanges {
    return FirebaseAuth.instance.authStateChanges().map(_profile);
  }

  Future<void> _handleIncomingEmailLink(Uri uri) async {
    final link = uri.toString();
    try {
      await _ensureFirebaseInitialized();
      final auth = FirebaseAuth.instance;
      if (!auth.isSignInWithEmailLink(link)) return;

      final preferences = await SharedPreferences.getInstance();
      final email = preferences.getString(_pendingEmailKey);
      if (email == null || email.isEmpty) {
        _pendingEmailLinks.add(link);
        return;
      }

      await _completeEmailLink(email: email, emailLink: link);
    } on FirebaseAuthException {
      _pendingEmailLinks.add(link);
    } catch (_) {
      _pendingEmailLinks.add(link);
    }
  }

  UserProfile? _profile(User? user) {
    if (user == null) return null;
    final providerIds =
        user.providerData.map((info) => info.providerId).toSet();
    final provider = user.phoneNumber != null
        ? AuthProviderType.phone
        : providerIds.contains('google.com')
            ? AuthProviderType.google
            : AuthProviderType.emailPassword;
    return UserProfile(
      id: user.uid,
      displayName:
          user.displayName ?? user.email ?? user.phoneNumber ?? 'Ab-Play User',
      email: user.email,
      phoneNumber: user.phoneNumber,
      photoUrl: user.photoURL,
      provider: provider,
      emailVerified: user.emailVerified,
    );
  }

  UserProfile? _profileFor(User? user, AuthProviderType provider) {
    final profile = _profile(user);
    if (profile == null) return null;
    return UserProfile(
      id: profile.id,
      displayName: profile.displayName,
      email: profile.email,
      phoneNumber: profile.phoneNumber,
      photoUrl: profile.photoUrl,
      provider: provider,
      emailVerified: profile.emailVerified,
    );
  }

  AuthException _firebaseException(FirebaseAuthException error) {
    final message = switch (error.code) {
      'invalid-email' => 'Enter a valid email address.',
      'user-disabled' => 'This account has been disabled. Contact support.',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' =>
        'The email or password is incorrect.',
      'email-already-in-use' => 'An account already exists for this email.',
      'weak-password' => 'Choose a stronger password (at least 6 characters).',
      'operation-not-allowed' =>
        'Email/password sign-in is disabled in Firebase Console.',
      'quota-exceeded' =>
        'Email sending limit reached. Please try again later.',
      'requires-recent-login' =>
        'Sign in again before changing this account setting.',
      'expired-action-code' ||
      'invalid-action-code' =>
        'This sign-in link is invalid or has expired. Request a new link.',
      'network-request-failed' =>
        'Check your internet connection and try again.',
      'too-many-requests' => 'Too many attempts. Wait a little and try again.',
      _ => error.message ?? 'Authentication failed. Please try again.',
    };
    return AuthException(message, code: error.code);
  }

  Future<void> _ensureFirebaseInitialized() async {
    if (_firebaseInitialized) return;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      _firebaseInitialized = true;
    } catch (e) {
      throw AuthException(
        'Firebase is not configured for this app. Add the Android google-services.json file, register the package and signing fingerprints in Firebase Console, and enable the required sign-in providers.\nDetails: $e',
        code: 'FIREBASE_NOT_CONFIGURED',
      );
    }
  }

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    final clientId = serverClientId ??
        (const String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID').isNotEmpty
            ? const String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID')
            : null);

    if (clientId != null && clientId.isNotEmpty) {
      await GoogleSignIn.instance.initialize(serverClientId: clientId);
    } else {
      await GoogleSignIn.instance.initialize();
    }
    _googleInitialized = true;
  }

  @override
  Future<UserProfile?> signInWithGoogle() async {
    try {
      await _ensureFirebaseInitialized();
      await _ensureGoogleInitialized();
      final googleUser = await GoogleSignIn.instance.authenticate();
      final idToken = googleUser.authentication.idToken;
      if (idToken == null) {
        throw AuthException(
          'Google Sign-In did not return an ID token. Check the Android OAuth client and SHA fingerprints.',
          code: 'GOOGLE_ID_TOKEN_MISSING',
        );
      }
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final result =
          await FirebaseAuth.instance.signInWithCredential(credential);
      return _profileFor(
        result.user,
        AuthProviderType.google,
      );
    } catch (e) {
      if (e is AuthException) rethrow;
      final String message = e.toString();
      if (message.toLowerCase().contains('cancel')) return null;
      if (message.contains('serverClientId must be provided on Android')) {
        throw AuthException(
          'Google Sign-In requires a serverClientId on Android.\n\n'
          'To configure:\n'
          '1. Enable Google Sign-In in Firebase Console / Google Cloud Console.\n'
          '2. Copy the Web Client ID.\n'
          '3. Pass it via build flag:\n'
          '   flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID="YOUR_WEB_CLIENT_ID.apps.googleusercontent.com"',
          code: 'GOOGLE_SERVER_CLIENT_ID_MISSING',
        );
      }
      throw AuthException(
        'Google Sign-In configuration is missing or invalid. Please configure Google OAuth Client ID and SHA-1 certificate in Firebase / Google Developer Console.\nDetails: $e',
        code: 'GOOGLE_CONFIG_REQUIRED',
      );
    }
  }

  @override
  Future<void> sendEmailSignInLink(String email) async {
    await _ensureFirebaseInitialized();
    final normalizedEmail = email.trim();
    final configuredLinkDomain =
        const String.fromEnvironment('FIREBASE_EMAIL_LINK_DOMAIN').trim();
    final settings = ActionCodeSettings(
      url: 'https://abplay.app/finishSignUp',
      handleCodeInApp: true,
      androidPackageName: _androidPackageName,
      androidInstallApp: true,
      androidMinimumVersion: '1',
      linkDomain: configuredLinkDomain.isEmpty ? null : configuredLinkDomain,
    );
    try {
      await FirebaseAuth.instance.sendSignInLinkToEmail(
        email: normalizedEmail,
        actionCodeSettings: settings,
      );
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_pendingEmailKey, normalizedEmail);
    } on FirebaseAuthException catch (error) {
      throw _firebaseException(error);
    }
  }

  @override
  Future<UserProfile?> completeEmailLink({
    required String email,
    required String emailLink,
  }) async {
    try {
      return await _completeEmailLink(email: email, emailLink: emailLink);
    } on FirebaseAuthException catch (error) {
      throw _firebaseException(error);
    }
  }

  Future<UserProfile?> _completeEmailLink({
    required String email,
    required String emailLink,
  }) async {
    await _ensureFirebaseInitialized();
    final auth = FirebaseAuth.instance;
    if (!auth.isSignInWithEmailLink(emailLink)) {
      throw AuthException(
        'This does not look like a valid Ab-Play sign-in link. Request a new one.',
        code: 'INVALID_EMAIL_LINK',
      );
    }

    final result = await auth.signInWithEmailLink(
      email: email.trim(),
      emailLink: emailLink,
    );
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_pendingEmailKey);
    return _profileFor(result.user, AuthProviderType.emailLink);
  }

  @override
  Future<UserProfile?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    await _ensureFirebaseInitialized();
    try {
      final result = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return _profileFor(result.user, AuthProviderType.emailPassword);
    } on FirebaseAuthException catch (error) {
      throw _firebaseException(error);
    }
  }

  @override
  Future<UserProfile?> createEmailPasswordAccount({
    required String email,
    required String password,
  }) async {
    await _ensureFirebaseInitialized();
    try {
      final result = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await result.user?.sendEmailVerification();
      return _profileFor(result.user, AuthProviderType.emailPassword);
    } on FirebaseAuthException catch (error) {
      throw _firebaseException(error);
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    await _ensureFirebaseInitialized();
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw AuthException('Sign in again to verify your email.');
      }
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (error) {
      throw _firebaseException(error);
    }
  }

  @override
  Future<UserProfile?> reloadEmailPasswordUser() async {
    await _ensureFirebaseInitialized();
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      await user.reload();
      return _profileFor(
          FirebaseAuth.instance.currentUser, AuthProviderType.emailPassword);
    } on FirebaseAuthException catch (error) {
      throw _firebaseException(error);
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _ensureFirebaseInitialized();
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (error) {
      throw _firebaseException(error);
    }
  }

  @override
  Future<UserProfile?> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status == LoginStatus.cancelled) {
        return null;
      }

      if (result.status == LoginStatus.success) {
        final userData = await FacebookAuth.instance.getUserData();
        return UserProfile(
          id: userData['id'] ?? '',
          displayName: userData['name'] ?? 'Facebook User',
          email: userData['email'],
          photoUrl: userData['picture']?['data']?['url'],
          provider: AuthProviderType.facebook,
        );
      } else {
        throw AuthException(
          'Facebook Login failed: ${result.message}',
          code: 'FACEBOOK_AUTH_FAILED',
        );
      }
    } catch (e) {
      throw AuthException(
        'Facebook Login configuration is missing or invalid. Please configure Facebook App ID and key hash in Facebook Developers Console.\nDetails: $e',
        code: 'FACEBOOK_CONFIG_REQUIRED',
      );
    }
  }

  @override
  Future<UserProfile?> signInWithApple() async {
    try {
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        throw AuthException(
          'Sign in with Apple is not supported on this device/platform.',
          code: 'APPLE_NOT_SUPPORTED',
        );
      }

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final String name = [credential.givenName, credential.familyName]
          .where((element) => element != null && element.isNotEmpty)
          .join(' ');

      return UserProfile(
        id: credential.userIdentifier ?? '',
        displayName: name.isNotEmpty ? name : 'Apple User',
        email: credential.email,
        provider: AuthProviderType.apple,
      );
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(
        'Sign in with Apple requires Apple Developer account configuration, bundle ID setup, and service ID provisioning.\nDetails: $e',
        code: 'APPLE_CONFIG_REQUIRED',
      );
    }
  }

  @override
  Future<UserProfile?> signInWithTwitter() async {
    throw AuthException(
      'X (Twitter) sign-in requires Twitter OAuth 2.0 Client Credentials and Callback URL configuration in Twitter Developer Portal.',
      code: 'TWITTER_CONFIG_REQUIRED',
    );
  }

  @override
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(AuthException error) onError,
    required void Function(UserProfile profile) onAutoVerified,
  }) async {
    try {
      await _ensureFirebaseInitialized();

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            final userCredential =
                await FirebaseAuth.instance.signInWithCredential(credential);
            final user = userCredential.user;
            if (user != null) {
              onAutoVerified(
                UserProfile(
                  id: user.uid,
                  displayName: user.displayName ?? 'Phone User',
                  phoneNumber: user.phoneNumber ?? phoneNumber,
                  provider: AuthProviderType.phone,
                ),
              );
            }
          } catch (e) {
            onError(AuthException('Auto-verification failed: $e',
                code: 'AUTO_VERIFY_FAILED'));
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(
            AuthException(
              'Phone verification failed: ${e.message ?? e.code}. Ensure Phone Authentication and SHA-1/SHA-256 fingerprints are configured in Firebase Console.',
              code: e.code,
            ),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId, resendToken);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      if (e is AuthException) {
        onError(e);
      } else {
        onError(
          AuthException(
            'Failed to initiate phone verification: $e. Make sure Firebase is properly configured.',
            code: 'PHONE_VERIFY_INIT_FAILED',
          ),
        );
      }
    }
  }

  @override
  Future<UserProfile?> signInWithPhoneOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      await _ensureFirebaseInitialized();

      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        return UserProfile(
          id: user.uid,
          displayName: user.displayName ?? 'Phone User',
          phoneNumber: user.phoneNumber,
          provider: AuthProviderType.phone,
        );
      }
      return null;
    } catch (e) {
      throw AuthException(
        'Invalid OTP code or expired verification. Details: $e',
        code: 'INVALID_OTP',
      );
    }
  }

  @override
  Future<void> signOut() async {
    await _ensureFirebaseInitialized();
    await FirebaseAuth.instance.signOut();
    if (_googleInitialized) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {
        // Firebase has already ended the app session.
      }
    }
    try {
      await FacebookAuth.instance.logOut();
    } catch (_) {
      // Firebase sign-out has already completed; no Facebook session may exist.
    }
  }
}
