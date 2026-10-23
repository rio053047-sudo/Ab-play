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

  AuthStatus get status => _status;
  UserProfile? get user => _user;
  String? get errorMessage => _errorMessage;
  AuthProviderType? get activeProvider => _activeProvider;

  bool get isAuthenticating => _status == AuthStatus.authenticating;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
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
