import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ab_play/models/user_profile.dart';
import 'package:ab_play/screens/login_screen.dart';
import 'package:ab_play/services/auth_service.dart';
import 'package:ab_play/viewmodels/auth_viewmodel.dart';

class MockPhoneAuthService implements AuthService {
  @override
  Future<void> initialize() async {}

  @override
  Future<UserProfile?> get currentUser async => null;

  @override
  Stream<UserProfile?> get authStateChanges => const Stream.empty();

  @override
  Stream<String> get pendingEmailLinks => const Stream.empty();

  bool shouldFail = false;

  @override
  Future<UserProfile?> signInWithGoogle() async => null;
  @override
  Future<UserProfile?> signInWithFacebook() async => null;
  @override
  Future<UserProfile?> signInWithApple() async => null;
  @override
  Future<UserProfile?> signInWithTwitter() async => null;

  @override
  Future<void> sendEmailSignInLink(String email) async {}

  @override
  Future<UserProfile?> completeEmailLink({
    required String email,
    required String emailLink,
  }) async =>
      null;

  @override
  Future<UserProfile?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async =>
      null;

  @override
  Future<UserProfile?> createEmailPasswordAccount({
    required String email,
    required String password,
  }) async =>
      null;

  @override
  Future<void> sendEmailVerification() async {}

  @override
  Future<UserProfile?> reloadEmailPasswordUser() async => null;

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(AuthException error) onError,
    required void Function(UserProfile profile) onAutoVerified,
  }) async {
    if (shouldFail) {
      onError(AuthException('Invalid phone configuration', code: 'CONFIG_ERR'));
    } else {
      onCodeSent('verification_id_abc123', 60);
    }
  }

  @override
  Future<UserProfile?> signInWithPhoneOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    if (shouldFail || smsCode != '123456') {
      throw AuthException('Invalid OTP Code', code: 'INVALID_OTP');
    }
    return UserProfile(
      id: 'usr_phone_1',
      displayName: 'Phone User',
      phoneNumber: '+919876543210',
      provider: AuthProviderType.phone,
    );
  }

  @override
  Future<void> signOut() async {}
}

void main() {
  Widget createWidgetUnderTest(MockPhoneAuthService service) {
    return ChangeNotifierProvider(
      create: (_) => AuthViewModel(authService: service),
      child: const MaterialApp(
        home: LoginScreen(),
      ),
    );
  }

  testWidgets(
      'LoginScreen displays "Continue with Phone Number" button and navigates to PhoneLoginScreen',
      (WidgetTester tester) async {
    final mockService = MockPhoneAuthService();
    await tester.pumpWidget(createWidgetUnderTest(mockService));

    expect(find.text('Continue with Phone Number'), findsOneWidget);

    await tester.tap(find.text('Continue with Phone Number'));
    await tester.pumpAndSettle();

    expect(find.text('Enter Mobile Number'), findsOneWidget);
    expect(find.text('+91'), findsOneWidget);
  });

  testWidgets('Email sign-in sheet offers passwordless and password methods',
      (WidgetTester tester) async {
    final mockService = MockPhoneAuthService();
    await tester.pumpWidget(createWidgetUnderTest(mockService));

    await tester.tap(find.text('Sign in with email'));
    await tester.pumpAndSettle();

    expect(find.text('Email me a secure sign-in link'), findsOneWidget);
    expect(find.text('Sign in with password'), findsOneWidget);
    expect(find.text('New to Ab-Play? Create an account'), findsOneWidget);
    await tester.tap(find.text('New to Ab-Play? Create an account'));
    await tester.pumpAndSettle();
    expect(find.text('Create account'), findsOneWidget);
    expect(find.text('Confirm password'), findsOneWidget);
  });

  testWidgets('PhoneLoginScreen validates 10-digit phone number entry',
      (WidgetTester tester) async {
    final mockService = MockPhoneAuthService();
    await tester.pumpWidget(createWidgetUnderTest(mockService));

    await tester.tap(find.text('Continue with Phone Number'));
    await tester.pumpAndSettle();

    // Tap Get OTP without entering a phone number
    await tester.tap(find.text('Get OTP'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter a valid 10-digit mobile number'),
        findsOneWidget);

    // Enter valid 10-digit number and submit
    await tester.enterText(find.byType(TextField), '9876543210');
    await tester.tap(find.text('Get OTP'));
    await tester.pumpAndSettle();

    // Should navigate to OTP screen
    expect(find.text('Verify OTP Code'), findsOneWidget);
    expect(find.text('Code sent to +919876543210'), findsOneWidget);
  });

  testWidgets(
      'OtpVerificationScreen allows entering 6-digit OTP and authenticating',
      (WidgetTester tester) async {
    final mockService = MockPhoneAuthService();
    await tester.pumpWidget(createWidgetUnderTest(mockService));

    await tester.tap(find.text('Continue with Phone Number'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '9876543210');
    await tester.tap(find.text('Get OTP'));
    await tester.pumpAndSettle();

    // Enter correct 6-digit OTP code
    await tester.enterText(find.byType(TextField), '123456');
    await tester.tap(find.text('Verify & Sign In'));
    await tester.pumpAndSettle();

    // User is authenticated
    final vm = Provider.of<AuthViewModel>(
        tester.element(find.byType(LoginScreen)),
        listen: false);
    expect(vm.status, AuthStatus.authenticated);
    expect(vm.user?.phoneNumber, '+919876543210');
  });
}
