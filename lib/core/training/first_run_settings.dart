import 'package:shared_preferences/shared_preferences.dart';

class FirstRunSettings {
  static String _key(String packageId) => 'first_run_complete_$packageId';

  static bool isFirstRun(SharedPreferences prefs, String packageId) =>
      !(prefs.getBool(_key(packageId)) ?? false);

  static Future<void> markComplete(
          SharedPreferences prefs, String packageId) =>
      prefs.setBool(_key(packageId), true);
}
