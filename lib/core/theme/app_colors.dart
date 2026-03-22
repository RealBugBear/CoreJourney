import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary
  static const Color primary = Color(0xFF6B4CE6);
  static const Color primaryDark = Color(0xFF5338C7);
  static const Color primaryLight = Color(0xFF9B85F2);

  // Semantic
  static const Color success = Color(0xFF34C759);
  static const Color successDark = Color(0xFF248A3D);
  static const Color warning = Color(0xFFFF9500);
  static const Color error = Color(0xFFFF3B30);
  static const Color info = Color(0xFF007AFF);

  // Neutrals
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textDisabled = Color(0xFF999999);
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color divider = Color(0xFFE0E0E0);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // Dark theme
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color surfaceDarkElevated = Color(0xFF2A2A2A);
  static const Color textPrimaryDark = Color(0xFFEFEFEF);
  static const Color textSecondaryDark = Color(0xFFB3B3B3);
  static const Color textDisabledDark = Color(0xFF737373);

  // Surface variants
  static const Color surfaceLight1 = Color(0xFFFFFFFF);
  static const Color surfaceLight2 = Color(0xFFFAFAFA);
  static const Color surfaceLight3 = Color(0xFFF0F0F0);

  // Mood chart series
  static const Color moodTeal = Color(0xFF5A9B84);
  static const Color moodBlue = Color(0xFF6E8FCB);
  static const Color moodRose = Color(0xFFC47A93);
  static const Color moodGold = Color(0xFFE0B867);

  static Color getContrastText(Color backgroundColor) {
    return backgroundColor.computeLuminance() > 0.5 ? textPrimary : textPrimaryDark;
  }
}
