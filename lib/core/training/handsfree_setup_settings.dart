import 'package:shared_preferences/shared_preferences.dart';

class HandsfreeSetupSettings {
  static const String setupCompletedKey = 'handsfree_setup_completed';
  static const String defaultTempoSecondsKey =
      'handsfree_default_tempo_seconds';

  static bool isCompleted(SharedPreferences prefs) {
    return prefs.getBool(setupCompletedKey) ?? false;
  }

  static Future<void> setCompleted(
    SharedPreferences prefs,
    bool value,
  ) {
    return prefs.setBool(setupCompletedKey, value);
  }

  static double? defaultTempoSecondsOrNull(SharedPreferences prefs) {
    return prefs.getDouble(defaultTempoSecondsKey);
  }

  static Future<void> setDefaultTempoSeconds(
    SharedPreferences prefs,
    double value,
  ) {
    return prefs.setDouble(defaultTempoSecondsKey, value);
  }
}
