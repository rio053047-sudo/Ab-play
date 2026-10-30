import 'package:flutter/material.dart';

class UserShortcut {
  final String id;
  final String title;
  final IconData icon;
  final Color iconColor;
  final Color badgeColor;
  final String? badgeText;

  const UserShortcut({
    required this.id,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.badgeColor,
    this.badgeText,
  });
}
