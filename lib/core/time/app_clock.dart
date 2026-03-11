import 'package:shared_preferences/shared_preferences.dart';

class AppClock {
  static const String overrideKey = 'debug_time_override_ms';

  final SharedPreferences? _prefs;

  AppClock([this._prefs]);

  DateTime now() {
    final ms = _prefs?.getInt(overrideKey);
    if (ms != null) {
      return DateTime.fromMillisecondsSinceEpoch(ms);
    }
    return DateTime.now();
  }

  DateTime? get overrideNow {
    final ms = _prefs?.getInt(overrideKey);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> setOverride(DateTime? value) async {
    final prefs = _prefs;
    if (prefs == null) return;
    if (value == null) {
      await prefs.remove(overrideKey);
      return;
    }
    await prefs.setInt(overrideKey, value.millisecondsSinceEpoch);
  }
}

