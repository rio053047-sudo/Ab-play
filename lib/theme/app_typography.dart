import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppTypography {
  static const String fontFamily = 'Roboto';

  static const TextStyle titleStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryText,
  );

  static const TextStyle titleMedium = titleStyle;

  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryText,
  );

  static const TextStyle captionStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.secondaryText,
  );

  static const TextStyle labelMedium = captionStyle;

  static const TextStyle titleBold = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.primaryText,
    letterSpacing: -0.5,
  );

  static const TextStyle subtitleMedium = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.secondaryText,
    letterSpacing: 0.1,
  );

  static const TextStyle buttonLabel = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryText,
  );

  static const TextStyle topAction = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryText,
  );

  static const TextStyle legalText = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.secondaryText,
    height: 1.4,
  );

  static const TextStyle legalLinkText = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.linkText,
    decoration: TextDecoration.underline,
  );
}
