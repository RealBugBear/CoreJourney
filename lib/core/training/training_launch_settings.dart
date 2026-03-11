import 'package:shared_preferences/shared_preferences.dart';

class TrainingLaunchSettings {
  static const String directStartEnabledKey = 'training_direct_start_enabled';

  static bool? directStartEnabledOrNull(SharedPreferences prefs) {
    return prefs.getBool(directStartEnabledKey);
  }

  static Future<void> setDirectStartEnabled(
    SharedPreferences prefs,
    bool enabled,
  ) {
    return prefs.setBool(directStartEnabledKey, enabled);
  }
}
