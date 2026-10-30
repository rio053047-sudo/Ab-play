import '../models/user_profile.dart';

abstract class AuthService {
  Future<UserProfile?> signInWithGoogle();
  Future<UserProfile?> signInWithFacebook();
  Future<UserProfile?> signInWithApple();
  Future<UserProfile?> signInWithTwitter();

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(AuthException error) onError,
    required void Function(UserProfile profile) onAutoVerified,
  });

  Future<UserProfile?> signInWithPhoneOTP({
    required String verificationId,
    required String smsCode,
  });

  Future<void> signOut();
}

class AuthException implements Exception {
  final String message;
  final String? code;

  AuthException(this.message, {this.code});

  @override
  String toString() => message;
}
