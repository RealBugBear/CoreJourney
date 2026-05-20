import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:corejourney/core/training/vorrunde_status_settings.dart';

void main() {
  group('VorrundeStatusSettings', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('default status is unseen', () async {
      final prefs = await SharedPreferences.getInstance();
      expect(VorrundeStatusSettings.status(prefs), 'unseen');
    });

    test('setStatus persists value', () async {
      final prefs = await SharedPreferences.getInstance();
      await VorrundeStatusSettings.setStatus(prefs, 'skipped');
      expect(VorrundeStatusSettings.status(prefs), 'skipped');
    });

    test('isUnseen returns true only for unseen', () async {
      final prefs = await SharedPreferences.getInstance();
      expect(VorrundeStatusSettings.isUnseen(prefs), isTrue);
      await VorrundeStatusSettings.setStatus(prefs, 'skipped');
      expect(VorrundeStatusSettings.isUnseen(prefs), isFalse);
    });
  });
}
