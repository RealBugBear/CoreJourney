import 'package:shared_preferences/shared_preferences.dart';

enum ReminderCadence {
  minimal,
  balanced,
}

class ReminderProfileSettings {
  static const String cadenceKey = 'reminder_cadence';

  static ReminderCadence cadence(SharedPreferences prefs) {
    final value = prefs.getString(cadenceKey);
    return switch (value) {
      'balanced' => ReminderCadence.balanced,
      _ => ReminderCadence.minimal,
    };
  }

  static Future<void> setCadence(
    SharedPreferences prefs,
    ReminderCadence cadence,
  ) {
    return prefs.setString(cadenceKey, cadence.name);
  }
}
