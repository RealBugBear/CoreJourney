import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:corejourney/core/theme/app_theme.dart';
import 'package:corejourney/core/theme/app_colors.dart';

void main() {
  // Note: These tests verify theme structure (colors, shapes, dimensions)
  // GoogleFonts is disabled to avoid network calls in unit tests

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Disable GoogleFonts to prevent network calls during testing
    AppTheme.disableGoogleFontsForTesting = true;
  });

  tearDownAll(() {
    // Re-enable GoogleFonts after testing
    AppTheme.disableGoogleFontsForTesting = false;
  });

  group('AppTheme — structure verification', () {
    group('light theme', () {
      late ThemeData theme;

      setUp(() {
        theme = AppTheme.light;
      });

      test('scaffold background color', () {
        expect(theme.scaffoldBackgroundColor, AppColors.backgroundLight);
        expect(
          theme.scaffoldBackgroundColor,
          const Color(0xFFF4FAF6),
        );
      });

      test('color scheme uses primary seed color', () {
        expect(theme.colorScheme.brightness, Brightness.light);
        expect(
          theme.colorScheme.primary,
          isA<Color>(),
        );
      });

      test('elevated button styling', () {
        final buttonStyle = theme.elevatedButtonTheme.style!;
        expect(
          buttonStyle.backgroundColor?.resolve({}),
          AppColors.primary,
        );
        expect(
          buttonStyle.foregroundColor?.resolve({}),
          AppColors.white,
        );
        expect(
          buttonStyle.minimumSize?.resolve({}),
          const Size.fromHeight(52),
        );
      });

      test('elevated button border radius is 14px', () {
        final buttonShape = theme.elevatedButtonTheme.style!.shape!
            .resolve({}) as RoundedRectangleBorder;
        expect(
          buttonShape.borderRadius,
          BorderRadius.circular(14),
        );
      });

      test('card styling', () {
        final cardShape = theme.cardTheme.shape as RoundedRectangleBorder;
        expect(cardShape.borderRadius, BorderRadius.circular(16));
        expect(theme.cardTheme.color, AppColors.surfaceLight1);
        expect(theme.cardTheme.elevation, 0);
      });

      test('app bar appearance', () {
        expect(
          theme.appBarTheme.backgroundColor,
          AppColors.backgroundLight,
        );
        expect(
          theme.appBarTheme.foregroundColor,
          AppColors.textPrimary,
        );
        expect(theme.appBarTheme.elevation, 0);
      });

      test('text theme colors', () {
        expect(
          theme.textTheme.bodyLarge?.color,
          AppColors.textPrimary,
        );
        expect(
          theme.textTheme.displayLarge?.color,
          AppColors.textPrimary,
        );
      });

      test('divider theme', () {
        expect(
          theme.dividerTheme?.color,
          AppColors.divider,
        );
      });
    });

    group('dark theme', () {
      late ThemeData theme;

      setUp(() {
        theme = AppTheme.dark;
      });

      test('scaffold background color', () {
        expect(theme.scaffoldBackgroundColor, AppColors.backgroundDark);
      });

      test('color scheme uses primary seed color with dark brightness', () {
        expect(theme.colorScheme.brightness, Brightness.dark);
        expect(
          theme.colorScheme.primary,
          isA<Color>(),
        );
      });

      test('elevated button styling', () {
        final buttonStyle = theme.elevatedButtonTheme.style!;
        expect(
          buttonStyle.backgroundColor?.resolve({}),
          AppColors.primary,
        );
        expect(
          buttonStyle.foregroundColor?.resolve({}),
          AppColors.white,
        );
      });

      test('elevated button border radius is 14px', () {
        final buttonShape = theme.elevatedButtonTheme.style!.shape!
            .resolve({}) as RoundedRectangleBorder;
        expect(
          buttonShape.borderRadius,
          BorderRadius.circular(14),
        );
      });

      test('card styling', () {
        final cardShape = theme.cardTheme.shape as RoundedRectangleBorder;
        expect(cardShape.borderRadius, BorderRadius.circular(16));
        expect(theme.cardTheme.color, AppColors.surfaceDark);
        expect(theme.cardTheme.elevation, 0);
      });

      test('app bar appearance', () {
        expect(
          theme.appBarTheme.backgroundColor,
          AppColors.backgroundDark,
        );
        expect(
          theme.appBarTheme.foregroundColor,
          AppColors.textPrimaryDark,
        );
      });

      test('text theme colors', () {
        expect(
          theme.textTheme.bodyLarge?.color,
          AppColors.textPrimaryDark,
        );
        expect(
          theme.textTheme.displayLarge?.color,
          AppColors.textPrimaryDark,
        );
      });
    });
  });
}
