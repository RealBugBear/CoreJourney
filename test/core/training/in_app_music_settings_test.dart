import 'package:corejourney/core/training/in_app_music_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('InAppMusicSettings', () {
    test('selectedTrack returns null when not set', () async {
      final prefs = await SharedPreferences.getInstance();
      expect(InAppMusicSettings.selectedTrack(prefs), isNull);
    });

    test('persists selected track', () async {
      final prefs = await SharedPreferences.getInstance();
      await InAppMusicSettings.setSelectedTrack(prefs, 'ambient_flow');
      expect(InAppMusicSettings.selectedTrack(prefs), 'ambient_flow');
    });

    test('volume defaults to 0.7', () async {
      final prefs = await SharedPreferences.getInstance();
      expect(InAppMusicSettings.volume(prefs), 0.7);
    });

    test('clears track when set to null', () async {
      final prefs = await SharedPreferences.getInstance();
      await InAppMusicSettings.setSelectedTrack(prefs, 'ambient_flow');
      await InAppMusicSettings.setSelectedTrack(prefs, null);
      expect(InAppMusicSettings.selectedTrack(prefs), isNull);
    });

    test('persists volume', () async {
      final prefs = await SharedPreferences.getInstance();
      await InAppMusicSettings.setVolume(prefs, 0.5);
      expect(InAppMusicSettings.volume(prefs), 0.5);
    });

    test('clamps volume to 0.0..1.0', () async {
      final prefs = await SharedPreferences.getInstance();
      await InAppMusicSettings.setVolume(prefs, 1.8);
      expect(InAppMusicSettings.volume(prefs), 1.0);
      await InAppMusicSettings.setVolume(prefs, -0.3);
      expect(InAppMusicSettings.volume(prefs), 0.0);
    });
  });
}
