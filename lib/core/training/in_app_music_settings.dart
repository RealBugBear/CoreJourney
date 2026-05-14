import 'package:shared_preferences/shared_preferences.dart';

class InAppMusicSettings {
  static const _trackKey = 'training_in_app_music_track';
  static const _volumeKey = 'training_in_app_music_volume';
  static const _defaultVolume = 0.7;

  static String? selectedTrack(SharedPreferences prefs) {
    return prefs.getString(_trackKey);
  }

  static Future<void> setSelectedTrack(SharedPreferences prefs, String? track) {
    if (track == null) return prefs.remove(_trackKey);
    return prefs.setString(_trackKey, track);
  }

  static double volume(SharedPreferences prefs) {
    return prefs.getDouble(_volumeKey) ?? _defaultVolume;
  }

  static Future<void> setVolume(SharedPreferences prefs, double volume) {
    return prefs.setDouble(_volumeKey, volume.clamp(0.0, 1.0));
  }
}
