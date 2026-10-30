import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../models/user_profile.dart';
import 'auth_service.dart';

class RealAuthService implements AuthService {
  final String? serverClientId;
  bool _googleInitialized = false;
  bool _firebaseInitialized = false;

  RealAuthService({this.serverClientId});

  Future<void> _ensureFirebaseInitialized() async {
    if (_firebaseInitialized) return;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      _firebaseInitialized = true;
    } catch (e) {
      throw AuthException(
        'Firebase is not initialized. Please configure google-services.json (Android) / GoogleService-Info.plist (iOS) and enable Phone Authentication in Firebase Console.\nDetails: $e',
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
      await _ensureGoogleInitialized();
      final googleUser = await GoogleSignIn.instance.authenticate();
      return UserProfile(
        id: googleUser.id,
        displayName: googleUser.displayName ?? 'Google User',
        email: googleUser.email,
        photoUrl: googleUser.photoUrl,
        provider: AuthProviderType.google,
      );
    } catch (e) {
      final String message = e.toString();
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

      final String name = [
        credential.givenName,
        credential.familyName
      ].where((element) => element != null && element.isNotEmpty).join(' ');

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
            final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
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
            onError(AuthException('Auto-verification failed: $e', code: 'AUTO_VERIFY_FAILED'));
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

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
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
    try {
      await GoogleSignIn.instance.signOut();
      await FacebookAuth.instance.logOut();
      if (_firebaseInitialized) {
        await FirebaseAuth.instance.signOut();
      }
    } catch (_) {}
  }
}
