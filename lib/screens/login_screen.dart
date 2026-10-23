import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../models/user_profile.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/social_button.dart';
import 'help_and_legal.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);

    // Show error snackbar if error occurs
    if (authViewModel.status == AuthStatus.error && authViewModel.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showErrorSnackBar(context, authViewModel.errorMessage!);
        authViewModel.clearError();
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Top Navigation / Help Action
                        Align(
                          alignment: Alignment.topRight,
                          child: InkWell(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (_) => const HelpDialog(),
                              );
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SvgPicture.asset(
                                    'assets/icons/help.svg',
                                    width: 18,
                                    height: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Help',
                                    style: AppTypography.topAction,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const Spacer(flex: 2),

                        // Center Branding & Mascot
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 130,
                              height: 130,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                              ),
                              child: SvgPicture.asset(
                                'assets/images/abplay_mascot.svg',
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Ab-Play',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primaryText,
                                letterSpacing: -0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Party Game & Voice Chat',
                              style: AppTypography.subtitleMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),

                        const Spacer(flex: 3),

                        // Primary Login Actions
                        SocialButton(
                          label: 'Sign in with Google',
                          iconAsset: 'assets/icons/google.svg',
                          isLoading: authViewModel.isAuthenticating &&
                              authViewModel.activeProvider == AuthProviderType.google,
                          onPressed: () async {
                            final success = await authViewModel.loginWithGoogle();
                            if (success && context.mounted) {
                              _showSuccessDialog(context, authViewModel.user!);
                            }
                          },
                        ),

                        const SizedBox(height: 14),

                        SocialButton(
                          label: 'Sign in with Facebook',
                          iconAsset: 'assets/icons/facebook.svg',
                          isLoading: authViewModel.isAuthenticating &&
                              authViewModel.activeProvider == AuthProviderType.facebook,
                          onPressed: () async {
                            final success = await authViewModel.loginWithFacebook();
                            if (success && context.mounted) {
                              _showSuccessDialog(context, authViewModel.user!);
                            }
                          },
                        ),

                        const SizedBox(height: 24),

                        // Secondary Social Icons Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularIconButton(
                              iconAsset: 'assets/icons/apple.svg',
                              tooltip: 'Sign in with Apple',
                              isLoading: authViewModel.isAuthenticating &&
                                  authViewModel.activeProvider == AuthProviderType.apple,
                              onPressed: () async {
                                final success = await authViewModel.loginWithApple();
                                if (success && context.mounted) {
                                  _showSuccessDialog(context, authViewModel.user!);
                                }
                              },
                            ),
                            const SizedBox(width: 24),
                            CircularIconButton(
                              iconAsset: 'assets/icons/x_twitter.svg',
                              tooltip: 'Sign in with X',
                              isLoading: authViewModel.isAuthenticating &&
                                  authViewModel.activeProvider == AuthProviderType.twitter,
                              onPressed: () async {
                                final success = await authViewModel.loginWithTwitter();
                                if (success && context.mounted) {
                                  _showSuccessDialog(context, authViewModel.user!);
                                }
                              },
                            ),
                          ],
                        ),

                        const Spacer(flex: 2),

                        // Bottom Legal Terms and Privacy Policy Links
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: AppTypography.legalText,
                              children: [
                                const TextSpan(text: 'By signing in, you agree to our '),
                                TextSpan(
                                  text: 'Terms of Service',
                                  style: AppTypography.legalLinkText,
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      LegalDocumentScreen.openUrlOrShowModal(
                                        context,
                                        'Terms of Service',
                                        'https://abplay.app/terms',
                                      );
                                    },
                                ),
                                const TextSpan(text: ' and '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: AppTypography.legalLinkText,
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      LegalDocumentScreen.openUrlOrShowModal(
                                        context,
                                        'Privacy Policy',
                                        'https://abplay.app/privacy',
                                      );
                                    },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, UserProfile user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Welcome to Ab-Play!'),
        content: Text('Logged in as ${user.displayName} (${user.email ?? user.id})'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
