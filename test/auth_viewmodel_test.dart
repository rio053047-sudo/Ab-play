import 'package:flutter_test/flutter_test.dart';
import 'package:ab_play/models/user_profile.dart';
import 'package:ab_play/services/auth_service.dart';
import 'package:ab_play/viewmodels/auth_viewmodel.dart';

class MockAuthService implements AuthService {
  bool shouldFail = false;
  bool shouldCancel = false;
  String? sentEmail;
  UserProfile? restoredUser;

  @override
  Future<void> initialize() async {}

  @override
  Future<UserProfile?> get currentUser async => restoredUser;

  @override
  Stream<UserProfile?> get authStateChanges => const Stream.empty();

  @override
  Stream<String> get pendingEmailLinks => const Stream.empty();

  @override
  Future<UserProfile?> signInWithGoogle() async {
    if (shouldFail) throw AuthException('Google Auth Error', code: 'ERR');
    if (shouldCancel) return null;
    return UserProfile(
      id: 'g_123',
      displayName: 'Test Google User',
      email: 'test@google.com',
      provider: AuthProviderType.google,
    );
  }

  @override
  Future<UserProfile?> signInWithFacebook() async {
    if (shouldFail) throw AuthException('Facebook Auth Error', code: 'ERR');
    if (shouldCancel) return null;
    return UserProfile(
      id: 'fb_456',
      displayName: 'Test Facebook User',
      provider: AuthProviderType.facebook,
    );
  }

  @override
  Future<UserProfile?> signInWithApple() async {
    return UserProfile(
      id: 'apple_789',
      displayName: 'Test Apple User',
      provider: AuthProviderType.apple,
    );
  }

  @override
  Future<UserProfile?> signInWithTwitter() async {
    throw AuthException('Twitter config required');
  }

  @override
  Future<void> sendEmailSignInLink(String email) async {
    if (shouldFail) throw AuthException('Email link error', code: 'ERR');
    sentEmail = email;
  }

  @override
  Future<UserProfile?> completeEmailLink({
    required String email,
    required String emailLink,
  }) async => UserProfile(
        id: 'email_link_123',
        displayName: 'Email Link User',
        email: email,
        provider: AuthProviderType.emailLink,
      );

  @override
  Future<UserProfile?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async => UserProfile(
        id: 'email_password_123',
        displayName: 'Password User',
        email: email,
        provider: AuthProviderType.emailPassword,
      );

  @override
  Future<UserProfile?> createEmailPasswordAccount({
    required String email,
    required String password,
  }) async => signInWithEmailPassword(email: email, password: password);

  @override
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(AuthException error) onError,
    required void Function(UserProfile profile) onAutoVerified,
  }) async {
    if (shouldFail) {
      onError(AuthException('Invalid Phone Number', code: 'INVALID_PHONE'));
    } else {
      onCodeSent('mock_verification_id_123', 123456);
    }
  }

  @override
  Future<UserProfile?> signInWithPhoneOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    if (shouldFail) throw AuthException('Invalid OTP Code', code: 'INVALID_OTP');
    return UserProfile(
      id: 'phone_999',
      displayName: 'Phone User',
      phoneNumber: '+919876543210',
      provider: AuthProviderType.phone,
    );
  }

  @override
  Future<void> signOut() async {}
}

void main() {
  group('AuthViewModel Tests', () {
    late MockAuthService mockAuthService;
    late AuthViewModel viewModel;

    setUp(() {
      mockAuthService = MockAuthService();
      viewModel = AuthViewModel(authService: mockAuthService);
    });

    test('Initial state is unauthenticated', () {
      expect(viewModel.status, AuthStatus.unauthenticated);
      expect(viewModel.user, null);
      expect(viewModel.errorMessage, null);
    });

    test('Firebase session is restored during initialization', () async {
      mockAuthService.restoredUser = UserProfile(
        id: 'firebase_uid_123',
        displayName: 'Returning player',
        email: 'player@gmail.com',
        provider: AuthProviderType.emailPassword,
      );

      await viewModel.initialize();

      expect(viewModel.isLoggedIn, isTrue);
      expect(viewModel.user?.id, 'firebase_uid_123');
      expect(viewModel.status, AuthStatus.authenticated);
    });

    test('Successful Google Login updates user and status', () async {
      final success = await viewModel.loginWithGoogle();

      expect(success, true);
      expect(viewModel.status, AuthStatus.authenticated);
      expect(viewModel.user?.displayName, 'Test Google User');
      expect(viewModel.user?.provider, AuthProviderType.google);
    });

    test('Email link request records the destination email', () async {
      final sent = await viewModel.sendEmailSignInLink('player@gmail.com');

      expect(sent, isTrue);
      expect(mockAuthService.sentEmail, 'player@gmail.com');
      expect(viewModel.emailLinkSent, isTrue);
      expect(viewModel.status, AuthStatus.unauthenticated);
    });

    test('Email/password login updates the authenticated profile', () async {
      final signedIn = await viewModel.loginWithEmailPassword(
        'player@gmail.com',
        'correct-horse',
      );

      expect(signedIn, isTrue);
      expect(viewModel.user?.email, 'player@gmail.com');
      expect(viewModel.user?.provider, AuthProviderType.emailPassword);
    });

    test('Canceled Facebook Login resets state to unauthenticated', () async {
      mockAuthService.shouldCancel = true;

      final success = await viewModel.loginWithFacebook();

      expect(success, false);
      expect(viewModel.status, AuthStatus.unauthenticated);
      expect(viewModel.user, null);
    });

    test('Failed Auth sets error state and message', () async {
      mockAuthService.shouldFail = true;

      final success = await viewModel.loginWithGoogle();

      expect(success, false);
      expect(viewModel.status, AuthStatus.error);
      expect(viewModel.errorMessage, 'Google Auth Error');
    });

    test('Phone OTP sending and verification success flow', () async {
      final otpSent = await viewModel.sendPhoneOtp('+919876543210');
      expect(otpSent, true);
      expect(viewModel.isOtpSent, true);
      expect(viewModel.phoneVerificationId, 'mock_verification_id_123');

      final verified = await viewModel.verifyOtpCode('123456');
      expect(verified, true);
      expect(viewModel.status, AuthStatus.authenticated);
      expect(viewModel.user?.phoneNumber, '+919876543210');
    });

    test('Phone OTP verification failure flow', () async {
      await viewModel.sendPhoneOtp('+919876543210');
      mockAuthService.shouldFail = true;

      final verified = await viewModel.verifyOtpCode('000000');
      expect(verified, false);
      expect(viewModel.status, AuthStatus.error);
      expect(viewModel.errorMessage, 'Invalid OTP Code');
    });

    test('Logout resets state', () async {
      await viewModel.loginWithGoogle();
      expect(viewModel.status, AuthStatus.authenticated);

      await viewModel.logout();
      expect(viewModel.status, AuthStatus.unauthenticated);
      expect(viewModel.user, null);
    });
  });
}
