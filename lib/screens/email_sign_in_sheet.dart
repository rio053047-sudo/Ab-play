import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_profile.dart';
import '../viewmodels/auth_viewmodel.dart';

class EmailSignInSheet extends StatefulWidget {
  const EmailSignInSheet({super.key});

  @override
  State<EmailSignInSheet> createState() => _EmailSignInSheetState();
}

class _EmailSignInSheetState extends State<EmailSignInSheet> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _registering = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validEmail() {
    final email = _emailController.text.trim();
    if (email.isEmpty ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid email address.')),
      );
      return false;
    }
    return true;
  }

  Future<void> _passwordAction(
    AuthViewModel authViewModel,
    Future<bool> Function(String email, String password) action,
  ) async {
    if (!_validEmail()) return;
    final password = _passwordController.text;
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your password.')),
      );
      return;
    }
    if (_registering && password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Password must be at least 6 characters.')),
      );
      return;
    }
    if (_registering && password != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')),
      );
      return;
    }
    final success = await action(_emailController.text.trim(), password);
    if (success && mounted && !authViewModel.requiresEmailVerification) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _sendPasswordReset(AuthViewModel authViewModel) async {
    if (!_validEmail()) return;
    await authViewModel.sendEmailPasswordReset(_emailController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, _) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            20,
            24,
            MediaQuery.viewInsetsOf(context).bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _registering ? 'Create your account' : 'Sign in with email',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Email address',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: authViewModel.isAuthenticating
                      ? null
                      : () async {
                          if (!_validEmail()) return;
                          if (authViewModel.hasPendingEmailLink) {
                            final completed =
                                await authViewModel.completePendingEmailLink(
                              _emailController.text.trim(),
                            );
                            if (completed && context.mounted) {
                              Navigator.of(context).pop();
                            }
                            return;
                          }
                          await authViewModel.sendEmailSignInLink(
                            _emailController.text.trim(),
                          );
                        },
                  child: authViewModel.isAuthenticating &&
                          authViewModel.activeProvider ==
                              AuthProviderType.emailLink
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(authViewModel.hasPendingEmailLink
                          ? 'Complete sign-in with this email'
                          : 'Email me a secure sign-in link'),
                ),
                if (authViewModel.emailLinkSent) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Check your inbox for the Ab-Play sign-in link.',
                    textAlign: TextAlign.center,
                  ),
                ],
                if (authViewModel.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    authViewModel.errorMessage!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 10),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: _registering ? 'Create password' : 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_registering) ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Confirm password',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: authViewModel.isAuthenticating
                      ? null
                      : () => _passwordAction(
                            authViewModel,
                            _registering
                                ? authViewModel.createEmailPasswordAccount
                                : authViewModel.loginWithEmailPassword,
                          ),
                  child: authViewModel.isAuthenticating &&
                          authViewModel.activeProvider ==
                              AuthProviderType.emailPassword
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_registering
                          ? 'Create account'
                          : 'Sign in with password'),
                ),
                if (!_registering)
                  TextButton(
                    onPressed: authViewModel.isAuthenticating
                        ? null
                        : () => _sendPasswordReset(authViewModel),
                    child: const Text('Forgot password?'),
                  ),
                TextButton(
                  onPressed: authViewModel.isAuthenticating
                      ? null
                      : () => setState(() => _registering = !_registering),
                  child: Text(_registering
                      ? 'Already have an account? Sign in'
                      : 'New to Ab-Play? Create an account'),
                ),
                if (authViewModel.requiresEmailVerification) ...[
                  const SizedBox(height: 8),
                  Text(
                    authViewModel.accountNotice ??
                        'Verify your email address before continuing to Ab-Play.',
                    textAlign: TextAlign.center,
                  ),
                  TextButton(
                    onPressed: authViewModel.isAuthenticating
                        ? null
                        : authViewModel.resendEmailVerification,
                    child: const Text('Resend verification email'),
                  ),
                  OutlinedButton(
                    onPressed: authViewModel.isAuthenticating
                        ? null
                        : () async {
                            final verified =
                                await authViewModel.refreshEmailVerification();
                            if (verified && context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                    child: const Text('I have verified my email'),
                  ),
                ] else if (authViewModel.accountNotice != null) ...[
                  Text(authViewModel.accountNotice!,
                      textAlign: TextAlign.center),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
