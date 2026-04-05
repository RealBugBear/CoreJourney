import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static bool get _useGoogleFonts => !Platform.isIOS;

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = _useGoogleFonts
        ? GoogleFonts.interTextTheme(base.textTheme)
        : base.textTheme;
    final titleTextStyle = _useGoogleFonts
        ? GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          )
        : const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          );
    final buttonTextStyle = _useGoogleFonts
        ? GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)
        : const TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.backgroundLight,
      textTheme: textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.backgroundLight,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        titleTextStyle: titleTextStyle,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: buttonTextStyle,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceLight1,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.divider),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.divider),
    );
  }

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = _useGoogleFonts
        ? GoogleFonts.interTextTheme(base.textTheme)
        : base.textTheme;
    final titleTextStyle = _useGoogleFonts
        ? GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimaryDark,
          )
        : const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimaryDark,
          );
    final buttonTextStyle = _useGoogleFonts
        ? GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)
        : const TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: AppColors.backgroundDark,
      textTheme: textTheme.apply(
        bodyColor: AppColors.textPrimaryDark,
        displayColor: AppColors.textPrimaryDark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.textPrimaryDark,
        elevation: 0,
        titleTextStyle: titleTextStyle,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: buttonTextStyle,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.surfaceDarkElevated),
        ),
      ),
    );
  }
}
