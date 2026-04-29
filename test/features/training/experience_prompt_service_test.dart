import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:corejourney/features/training/domain/services/experience_prompt_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ExperiencePromptService', () {
    test('shouldShow returns true when never shown', () async {
      expect(await ExperiencePromptService.shouldShow(), true);
    });

    test('shouldShow returns false immediately after markShown', () async {
      await ExperiencePromptService.markShown();
      expect(await ExperiencePromptService.shouldShow(), false);
    });

    test('shouldShow returns true if stored date is yesterday', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      SharedPreferences.setMockInitialValues({
        'last_experience_prompt_date': yesterday.toIso8601String(),
      });
      expect(await ExperiencePromptService.shouldShow(), true);
    });

    test('shouldShow returns false if stored date is today', () async {
      final today = DateTime.now();
      SharedPreferences.setMockInitialValues({
        'last_experience_prompt_date': today.toIso8601String(),
      });
      expect(await ExperiencePromptService.shouldShow(), false);
    });
  });
}
