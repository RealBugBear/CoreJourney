import 'package:shared_preferences/shared_preferences.dart';

class VorrundeStatusSettings {
  static const _key = 'vorrunde_status';

  static String status(SharedPreferences prefs) =>
      prefs.getString(_key) ?? 'unseen';

  static bool isUnseen(SharedPreferences prefs) => status(prefs) == 'unseen';

  static Future<void> setStatus(SharedPreferences prefs, String value) =>
      prefs.setString(_key, value);
}
