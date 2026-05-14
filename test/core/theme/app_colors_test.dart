import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:corejourney/core/theme/app_colors.dart';

void main() {
  group('AppColors — green palette', () {
    test('primary is Free Place green', () {
      expect(AppColors.primary, const Color(0xFF009E6B));
    });

    test('primaryDark is darker green for pressed state', () {
      expect(AppColors.primaryDark, const Color(0xFF007A52));
    });

    test('primaryLight is lighter green for decorative use', () {
      expect(AppColors.primaryLight, const Color(0xFF6FD4A8));
    });

    test('primaryOnDark is brightened green for dark surfaces', () {
      expect(AppColors.primaryOnDark, const Color(0xFF00C882));
    });

    test('backgroundLight has subtle green tint', () {
      expect(AppColors.backgroundLight, const Color(0xFFF4FAF6));
    });

    test('textPrimary is dark green-tinted black', () {
      expect(AppColors.textPrimary, const Color(0xFF0D1F15));
    });

    test('textSecondary is muted green-grey (WCAG AA compliant)', () {
      expect(AppColors.textSecondary, const Color(0xFF3D6B4F));
    });

    test('divider is light green-tinted border', () {
      expect(AppColors.divider, const Color(0xFFD8EEE2));
    });
  });
}
