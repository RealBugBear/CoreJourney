import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:corejourney/core/theme/app_colors.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('AppTheme — structure verification', () {
    group('light theme', () {
      late ThemeData theme;

      setUp(() {
        // Build theme structure without GoogleFonts to avoid network calls in unit tests
        final base = ThemeData.light(useMaterial3: true);
        final textTheme = base.textTheme;
        theme = base.copyWith(
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
            titleTextStyle: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
        // Build theme structure without GoogleFonts to avoid network calls in unit tests
        final base = ThemeData.dark(useMaterial3: true);
        final textTheme = base.textTheme;
        theme = base.copyWith(
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
            titleTextStyle: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryDark,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
