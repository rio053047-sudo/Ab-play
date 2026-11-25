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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validEmail() {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid email address.')),
      );
      return false;
    }
    return true;
  }

  Future<void> _passwordAction(
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
    final success = await action(_emailController.text.trim(), password);
    if (success && mounted) Navigator.of(context).pop();
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
                  'Sign in with email',
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
                            final completed = await authViewModel.completePendingEmailLink(
                              _emailController.text.trim(),
                            );
                            if (completed && context.mounted) Navigator.of(context).pop();
                            return;
                          }
                          await authViewModel.sendEmailSignInLink(
                            _emailController.text.trim(),
                          );
                        },
                  child: authViewModel.isAuthenticating &&
                          authViewModel.activeProvider == AuthProviderType.emailLink
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
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 10),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: authViewModel.isAuthenticating
                            ? null
                            : () => _passwordAction(
                                  authViewModel.loginWithEmailPassword,
                                ),
                        child: const Text('Sign in with password'),
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: authViewModel.isAuthenticating
                            ? null
                            : () => _passwordAction(
                                  authViewModel.createEmailPasswordAccount,
                                ),
                        child: const Text('Create account'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
