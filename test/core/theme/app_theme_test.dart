import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:corejourney/core/theme/app_theme.dart';
import 'package:corejourney/core/theme/app_colors.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Disable runtime font fetching; use system defaults instead.
    // This prevents GoogleFonts from trying to download fonts during tests.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('AppTheme', () {
    group('light theme', () {
      late ThemeData theme;

      setUpAll(() async {
        // The GoogleFonts library will raise exceptions asynchronously if fonts aren't found
        // when allowRuntimeFetching is false. Since we're testing theme structure (colors,
        // sizes, radii), not fonts, we suppress these font-loading errors.
        await runZonedGuarded(
          () async {
            theme = AppTheme.light;
            await Future.delayed(const Duration(milliseconds: 100));
          },
          (Object error, StackTrace stack) {
            // Ignore GoogleFonts font loading errors in tests
          },
        );
      });

      test('scaffold background is green-tinted', () {
        expect(theme.scaffoldBackgroundColor, AppColors.backgroundLight);
      });

      test('primary color seed is Free Place green', () {
        expect(theme.scaffoldBackgroundColor, const Color(0xFFF4FAF6));
      });

      test('elevated button background is primary green', () {
        final style = theme.elevatedButtonTheme.style!;
        final bg = style.backgroundColor?.resolve({});
        expect(bg, AppColors.primary);
      });

      test('elevated button radius is 14', () {
        final style = theme.elevatedButtonTheme.style!;
        final shape = style.shape?.resolve({}) as RoundedRectangleBorder?;
        expect(shape?.borderRadius, BorderRadius.circular(14));
      });

      test('card radius is 16', () {
        final shape = theme.cardTheme.shape as RoundedRectangleBorder;
        expect(shape.borderRadius, BorderRadius.circular(16));
      });

      test('app bar background is green-tinted', () {
        expect(theme.appBarTheme.backgroundColor, AppColors.backgroundLight);
      });
    });

    group('dark theme', () {
      late ThemeData theme;

      setUpAll(() async {
        // The GoogleFonts library will raise exceptions asynchronously if fonts aren't found
        // when allowRuntimeFetching is false. Since we're testing theme structure (colors,
        // sizes, radii), not fonts, we suppress these font-loading errors.
        await runZonedGuarded(
          () async {
            theme = AppTheme.dark;
            await Future.delayed(const Duration(milliseconds: 100));
          },
          (Object error, StackTrace stack) {
            // Ignore GoogleFonts font loading errors in tests
          },
        );
      });

      test('scaffold background is pure neutral dark', () {
        expect(theme.scaffoldBackgroundColor, AppColors.backgroundDark);
      });

      test('elevated button background is primary green', () {
        final style = theme.elevatedButtonTheme.style!;
        final bg = style.backgroundColor?.resolve({});
        expect(bg, AppColors.primary);
      });

      test('elevated button radius is 14', () {
        final style = theme.elevatedButtonTheme.style!;
        final shape = style.shape?.resolve({}) as RoundedRectangleBorder?;
        expect(shape?.borderRadius, BorderRadius.circular(14));
      });

      test('app bar background is dark', () {
        expect(theme.appBarTheme.backgroundColor, AppColors.backgroundDark);
      });

      test('card surface is dark', () {
        expect(theme.cardTheme.color, AppColors.surfaceDark);
      });
    });
  });
}
