import 'package:corejourney/core/training/transition_duration_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('TransitionDurationSettings', () {
    test('returns default 10 when not set', () async {
      final prefs = await SharedPreferences.getInstance();
      expect(TransitionDurationSettings.durationSeconds(prefs), 10);
    });

    test('returns persisted value', () async {
      final prefs = await SharedPreferences.getInstance();
      await TransitionDurationSettings.setDurationSeconds(prefs, 15);
      expect(TransitionDurationSettings.durationSeconds(prefs), 15);
    });

    test('clamps to valid range 5..30', () async {
      final prefs = await SharedPreferences.getInstance();
      await TransitionDurationSettings.setDurationSeconds(prefs, 99);
      expect(TransitionDurationSettings.durationSeconds(prefs), 30);
      await TransitionDurationSettings.setDurationSeconds(prefs, 1);
      expect(TransitionDurationSettings.durationSeconds(prefs), 5);
    });
  });
}
