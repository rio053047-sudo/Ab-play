enum AuthProviderType {
  google,
  facebook,
  apple,
  twitter,
  phone,
}

enum AuthStatus {
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

  UserProfile({
    required this.id,
    required this.displayName,
    this.email,
    this.phoneNumber,
    this.photoUrl,
    required this.provider,
  });
}
