import '../models/user_profile.dart';

abstract class AuthService {
  Future<UserProfile?> signInWithGoogle();
  Future<UserProfile?> signInWithFacebook();
  Future<UserProfile?> signInWithApple();
  Future<UserProfile?> signInWithTwitter();
  Future<void> signOut();
}

class AuthException implements Exception {
  final String message;
  final String? code;

  AuthException(this.message, {this.code});

  @override
  String toString() => message;
}
