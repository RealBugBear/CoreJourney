import 'package:shared_preferences/shared_preferences.dart';

class TutorialFlowSettings {
  static const String tutorialCompactEnabledKey = 'tutorial_compact_enabled';

  static bool compactEnabled(SharedPreferences prefs) {
    return prefs.getBool(tutorialCompactEnabledKey) ?? false;
  }

  static Future<void> setCompactEnabled(
    SharedPreferences prefs,
    bool enabled,
  ) {
    return prefs.setBool(tutorialCompactEnabledKey, enabled);
  }
}
