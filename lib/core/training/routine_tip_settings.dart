import 'package:shared_preferences/shared_preferences.dart';

class RoutineTipSettings {
  static const _keyShown = 'routine_tip_shown';
  static const _keyCount = 'completed_session_count';

  static bool tipShown(SharedPreferences prefs) =>
      prefs.getBool(_keyShown) ?? false;

  static int sessionCount(SharedPreferences prefs) =>
      prefs.getInt(_keyCount) ?? 0;

  static Future<void> incrementSessionCount(SharedPreferences prefs) =>
      prefs.setInt(_keyCount, sessionCount(prefs) + 1);

  static Future<void> markTipShown(SharedPreferences prefs) =>
      prefs.setBool(_keyShown, true);

  static bool shouldShowTip(SharedPreferences prefs) =>
      !tipShown(prefs) && sessionCount(prefs) >= 2;
}
