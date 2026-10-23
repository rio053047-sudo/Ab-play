import 'package:flutter_test/flutter_test.dart';
import 'package:ab_play/models/user_profile.dart';
import 'package:ab_play/services/auth_service.dart';
import 'package:ab_play/viewmodels/auth_viewmodel.dart';

class MockAuthService implements AuthService {
  bool shouldFail = false;
  bool shouldCancel = false;

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

    test('Successful Google Login updates user and status', () async {
      final success = await viewModel.loginWithGoogle();

      expect(success, true);
      expect(viewModel.status, AuthStatus.authenticated);
      expect(viewModel.user?.displayName, 'Test Google User');
      expect(viewModel.user?.provider, AuthProviderType.google);
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

    test('Logout resets state', () async {
      await viewModel.loginWithGoogle();
      expect(viewModel.status, AuthStatus.authenticated);

      await viewModel.logout();
      expect(viewModel.status, AuthStatus.unauthenticated);
      expect(viewModel.user, null);
    });
  });
}
