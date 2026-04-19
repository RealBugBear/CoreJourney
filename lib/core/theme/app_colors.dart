import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary — Free Place green (#009E6B exact match)
  static const Color primary = Color(0xFF009E6B);
  static const Color primaryDark = Color(0xFF007A52);
  static const Color primaryLight = Color(0xFF6FD4A8);
  static const Color primaryOnDark = Color(0xFF00C882);

  // Semantic
  static const Color success = Color(0xFF34C759);
  static const Color successDark = Color(0xFF248A3D);
  static const Color warning = Color(0xFFFF9500);
  static const Color error = Color(0xFFFF3B30);
  static const Color info = Color(0xFF007AFF);

  // Neutrals — Light mode
  static const Color textPrimary = Color(0xFF0D1F15);
  static const Color textSecondary = Color(0xFF3D6B4F);
  static const Color textDisabled = Color(0xFF999999);
  static const Color backgroundLight = Color(0xFFF4FAF6);
  static const Color divider = Color(0xFFD8EEE2);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // Dark theme
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color surfaceDarkElevated = Color(0xFF2A2A2A);
  static const Color textPrimaryDark = Color(0xFFEFEFEF);
  static const Color textSecondaryDark = Color(0xFFB3B3B3);
  static const Color textDisabledDark = Color(0xFF737373);

  // Surface variants (light)
  static const Color surfaceLight1 = Color(0xFFFFFFFF);
  static const Color surfaceLight2 = Color(0xFFFAFAFA);
  static const Color surfaceLight3 = Color(0xFFF0F5F2);

  // Mood chart series — unchanged
  static const Color moodTeal = Color(0xFF5A9B84);
  static const Color moodBlue = Color(0xFF6E8FCB);
  static const Color moodRose = Color(0xFFC47A93);
  static const Color moodGold = Color(0xFFE0B867);

  static Color getContrastText(Color backgroundColor) {
    return backgroundColor.computeLuminance() > 0.5
        ? textPrimary
        : textPrimaryDark;
  }
}
