import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class HelpDialog extends StatelessWidget {
  const HelpDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.brandYellow.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.help_outline, color: AppColors.primaryText),
          ),
          const SizedBox(width: 12),
          const Text('Ab-Play Support', style: AppTypography.titleBold),
        ],
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Need assistance logging in or managing your account?',
            style: AppTypography.buttonLabel,
          ),
          SizedBox(height: 12),
          Text(
            'Contact our support team at support@abplay.app or visit our online help desk for FAQs, account recovery, and safety tips.',
            style: AppTypography.legalText,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close', style: TextStyle(color: AppColors.linkText, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

class LegalDocumentScreen extends StatelessWidget {
  final String title;
  final String content;

  const LegalDocumentScreen({
    super.key,
    required this.title,
    required this.content,
  });

  static Future<void> openUrlOrShowModal(BuildContext context, String title, String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (ctx) => DraggableScrollableSheet(
            initialChildSize: 0.8,
            maxChildSize: 0.95,
            minChildSize: 0.5,
            expand: false,
            builder: (context, scrollController) {
              return Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(title, style: AppTypography.titleBold),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        children: [
                          Text(
                            title == 'Terms of Service'
                                ? 'Welcome to Ab-Play! By downloading, accessing, or using Ab-Play, you agree to be bound by these Terms of Service. Ab-Play provides party gaming and voice chat features for users worldwide. Respectful behavior, fair play, and compliance with local laws are strictly enforced.'
                                : 'Your privacy is essential to us at Ab-Play. This Privacy Policy explains how we collect, store, protect, and process user data when using Ab-Play services. We do not sell your personal information to third parties.',
                            style: AppTypography.legalText,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: AppTypography.buttonLabel),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Text(content, style: AppTypography.legalText),
      ),
    );
  }
}
