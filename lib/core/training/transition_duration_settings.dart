import 'package:shared_preferences/shared_preferences.dart';

class TransitionDurationSettings {
  static const _key = 'training_transition_duration_seconds';
  static const _default = 10;
  static const _min = 5;
  static const _max = 30;

  static int durationSeconds(SharedPreferences prefs) {
    return (prefs.getInt(_key) ?? _default).clamp(_min, _max);
  }

  static Future<void> setDurationSeconds(SharedPreferences prefs, int seconds) {
    return prefs.setInt(_key, seconds.clamp(_min, _max));
  }
}
