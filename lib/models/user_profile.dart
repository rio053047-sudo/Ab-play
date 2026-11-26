enum AuthProviderType {
  google,
  facebook,
  apple,
  twitter,
  phone,
  emailLink,
  emailPassword,
}

enum AuthStatus {
  initializing,
  unauthenticated,
  authenticating,
  authenticated,
  error,
}

class UserProfile {
  final String id;
  final String displayName;
  final String? email;
  final String? phoneNumber;
  final String? photoUrl;
  final AuthProviderType provider;
  final bool emailVerified;

  UserProfile({
    required this.id,
    required this.displayName,
    this.email,
    this.phoneNumber,
    this.photoUrl,
    required this.provider,
    this.emailVerified = true,
  });
}
