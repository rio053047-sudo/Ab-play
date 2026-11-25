import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/user_profile.dart';
import '../services/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService;

  AuthViewModel({required AuthService authService}) : _authService = authService;

  AuthStatus _status = AuthStatus.unauthenticated;
  UserProfile? _user;
  String? _errorMessage;
  AuthProviderType? _activeProvider;
  String? _pendingEmailLink;
  bool _emailLinkSent = false;
  StreamSubscription<UserProfile?>? _authSubscription;
  StreamSubscription<String>? _emailLinkSubscription;
  bool _didInitialize = false;

  // Phone & OTP state variables
  String? _phoneVerificationId;
  int? _resendToken;
  bool _isOtpSent = false;
  String? _phoneNumber;

  AuthStatus get status => _status;
  UserProfile? get user => _user;
  String? get errorMessage => _errorMessage;
  AuthProviderType? get activeProvider => _activeProvider;

  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoggedIn => _status == AuthStatus.authenticated;
  bool get isAuthenticating => _status == AuthStatus.authenticating;
  bool get isInitializing => _status == AuthStatus.initializing;
  bool get emailLinkSent => _emailLinkSent;
  bool get hasPendingEmailLink => _pendingEmailLink != null;

  String? get phoneVerificationId => _phoneVerificationId;
  int? get resendToken => _resendToken;
  bool get isOtpSent => _isOtpSent;
  String? get phoneNumber => _phoneNumber;

  Future<void> initialize() async {
    if (_didInitialize) return;
    _didInitialize = true;
    _status = AuthStatus.initializing;
    notifyListeners();
    _emailLinkSubscription = _authService.pendingEmailLinks.listen((link) {
      _pendingEmailLink = link;
      _emailLinkSent = false;
      notifyListeners();
    });

    try {
      await _authService.initialize();
      _authSubscription = _authService.authStateChanges.listen(
        _applyAuthState,
        onError: (Object error) {
          _errorMessage = 'Could not restore your sign-in session. Please sign in again.';
          _status = AuthStatus.unauthenticated;
          notifyListeners();
        },
      );
      _applyAuthState(await _authService.currentUser);
    } catch (_) {
      // Firebase configuration errors are shown when the user starts an auth action.
      _user = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  void _applyAuthState(UserProfile? profile) {
    _user = profile;
    _status = profile == null ? AuthStatus.unauthenticated : AuthStatus.authenticated;
    if (profile == null) _activeProvider = null;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void resetPhoneAuth() {
    _phoneVerificationId = null;
    _resendToken = null;
    _isOtpSent = false;
    _phoneNumber = null;
    notifyListeners();
  }

  Future<bool> sendPhoneOtp(String rawPhone) async {
    _status = AuthStatus.authenticating;
    _activeProvider = AuthProviderType.phone;
    _errorMessage = null;
    _phoneNumber = rawPhone;
    notifyListeners();

    final Completer<bool> completer = Completer<bool>();

    await _authService.verifyPhoneNumber(
      phoneNumber: rawPhone,
      onCodeSent: (verificationId, resendToken) {
        _phoneVerificationId = verificationId;
        _resendToken = resendToken;
        _isOtpSent = true;
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        if (!completer.isCompleted) completer.complete(true);
      },
      onError: (error) {
        _errorMessage = error.message;
        _status = AuthStatus.error;
        _isOtpSent = false;
        notifyListeners();
        if (!completer.isCompleted) completer.complete(false);
      },
      onAutoVerified: (profile) {
        _user = profile;
        _status = AuthStatus.authenticated;
        notifyListeners();
        if (!completer.isCompleted) completer.complete(true);
      },
    );

    return completer.future;
  }

  Future<bool> verifyOtpCode(String smsCode) async {
    if (_phoneVerificationId == null) {
      _errorMessage = 'Phone verification ID is missing. Please resend OTP.';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }

    return _handleAuth(
      () => _authService.signInWithPhoneOTP(
        verificationId: _phoneVerificationId!,
        smsCode: smsCode,
      ),
      AuthProviderType.phone,
    );
  }

  Future<bool> loginWithGoogle() async {
    return _handleAuth(() => _authService.signInWithGoogle(), AuthProviderType.google);
  }

  Future<bool> sendEmailSignInLink(String email) async {
    _status = AuthStatus.authenticating;
    _activeProvider = AuthProviderType.emailLink;
    _emailLinkSent = false;
    _errorMessage = null;
    notifyListeners();
    try {
      await _authService.sendEmailSignInLink(email);
      _status = AuthStatus.unauthenticated;
      _activeProvider = null;
      _emailLinkSent = true;
      notifyListeners();
      return true;
    } on AuthException catch (error) {
      _setAuthError(error.message);
    } catch (error) {
      _setAuthError('Could not send the sign-in link. Please try again. $error');
    }
    return false;
  }

  Future<bool> completePendingEmailLink(String email) async {
    final link = _pendingEmailLink;
    if (link == null) {
      _setAuthError('Open the Ab-Play sign-in link from your email, then try again.');
      return false;
    }
    final success = await _handleAuth(
      () => _authService.completeEmailLink(email: email, emailLink: link),
      AuthProviderType.emailLink,
    );
    if (success) _pendingEmailLink = null;
    return success;
  }

  Future<bool> loginWithEmailPassword(String email, String password) {
    return _handleAuth(
      () => _authService.signInWithEmailPassword(email: email, password: password),
      AuthProviderType.emailPassword,
    );
  }

  Future<bool> createEmailPasswordAccount(String email, String password) {
    return _handleAuth(
      () => _authService.createEmailPasswordAccount(email: email, password: password),
      AuthProviderType.emailPassword,
    );
  }

  Future<bool> loginWithFacebook() async {
    return _handleAuth(() => _authService.signInWithFacebook(), AuthProviderType.facebook);
  }

  Future<bool> loginWithApple() async {
    return _handleAuth(() => _authService.signInWithApple(), AuthProviderType.apple);
  }

  Future<bool> loginWithTwitter() async {
    return _handleAuth(() => _authService.signInWithTwitter(), AuthProviderType.twitter);
  }

  Future<void> logout() async {
    await _authService.signOut();
    _user = null;
    _status = AuthStatus.unauthenticated;
    _activeProvider = null;
    _errorMessage = null;
    resetPhoneAuth();
    notifyListeners();
  }

  void _setAuthError(String message) {
    _errorMessage = message;
    _status = AuthStatus.error;
    _activeProvider = null;
    notifyListeners();
  }

  Future<bool> _handleAuth(
    Future<UserProfile?> Function() authCall,
    AuthProviderType provider,
  ) async {
    _status = AuthStatus.authenticating;
    _activeProvider = provider;
    _errorMessage = null;
    notifyListeners();

    try {
      final profile = await authCall();
      if (profile != null) {
        _user = profile;
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      } else {
        // User canceled sign in
        _status = AuthStatus.unauthenticated;
        _activeProvider = null;
        notifyListeners();
        return false;
      }
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.error;
      _activeProvider = null;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected authentication error occurred: $e';
      _status = AuthStatus.error;
      _activeProvider = null;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    unawaited(_authSubscription?.cancel());
    unawaited(_emailLinkSubscription?.cancel());
    super.dispose();
  }
}
