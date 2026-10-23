import 'dart:async';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../models/user_profile.dart';
import 'auth_service.dart';

class RealAuthService implements AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  @override
  Future<UserProfile?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.authenticate();
      return UserProfile(
        id: googleUser.id,
        displayName: googleUser.displayName ?? 'Google User',
        email: googleUser.email,
        photoUrl: googleUser.photoUrl,
        provider: AuthProviderType.google,
      );
    } catch (e) {
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
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await FacebookAuth.instance.logOut();
    } catch (_) {}
  }
}
