import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

enum LudoColor {
  red,
  green,
  yellow,
  blue;

  String get displayName {
    switch (this) {
      case LudoColor.red:
        return 'Red';
      case LudoColor.green:
        return 'Green';
      case LudoColor.yellow:
        return 'Yellow';
      case LudoColor.blue:
        return 'Blue';
    }
  }

  Color get color {
    switch (this) {
      case LudoColor.red:
        return AppColors.error;
      case LudoColor.green:
        return AppColors.success;
      case LudoColor.yellow:
        return const Color(0xFFFFB703);
      case LudoColor.blue:
        return AppColors.primary;
    }
  }

  Color get lightColor {
    switch (this) {
      case LudoColor.red:
        return const Color(0xFFFFEBEE);
      case LudoColor.green:
        return const Color(0xFFE8F5E9);
      case LudoColor.yellow:
        return const Color(0xFFFFF8E1);
      case LudoColor.blue:
        return const Color(0xFFE3F2FD);
    }
  }

  int get startTrackIndex {
    switch (this) {
      case LudoColor.red:
        return 0; // (1, 8)
      case LudoColor.green:
        return 39; // (6, 1) Top-Left
      case LudoColor.yellow:
        return 26; // (13, 6) Top-Right
      case LudoColor.blue:
        return 13; // (8, 13) Bottom-Right
    }
  }
}
