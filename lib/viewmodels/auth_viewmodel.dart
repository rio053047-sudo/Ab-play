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

  String? get phoneVerificationId => _phoneVerificationId;
  int? get resendToken => _resendToken;
  bool get isOtpSent => _isOtpSent;
  String? get phoneNumber => _phoneNumber;

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
}
