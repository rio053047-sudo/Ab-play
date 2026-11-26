import '../models/user_profile.dart';

abstract class AuthService {
  Future<void> initialize() async {}
  Future<UserProfile?> get currentUser async => null;
  Stream<UserProfile?> get authStateChanges =>
      const Stream<UserProfile?>.empty();
  Stream<String> get pendingEmailLinks => const Stream<String>.empty();

  Future<UserProfile?> signInWithGoogle();
  Future<UserProfile?> signInWithFacebook();
  Future<UserProfile?> signInWithApple();
  Future<UserProfile?> signInWithTwitter();
  Future<void> sendEmailSignInLink(String email) async {
    throw AuthException('Email link sign-in is not available.');
  }

  Future<UserProfile?> completeEmailLink({
    required String email,
    required String emailLink,
  }) async {
    throw AuthException('Email link sign-in is not available.');
  }

  Future<UserProfile?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    throw AuthException('Email/password sign-in is not available.');
  }

  Future<UserProfile?> createEmailPasswordAccount({
    required String email,
    required String password,
  }) async {
    throw AuthException('Email/password sign-up is not available.');
  }

  Future<void> sendEmailVerification() async {
    throw AuthException('Email verification is not available.');
  }

  Future<UserProfile?> reloadEmailPasswordUser() async {
    throw AuthException('Email verification is not available.');
  }

  Future<void> sendPasswordResetEmail(String email) async {
    throw AuthException('Password reset is not available.');
  }

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
