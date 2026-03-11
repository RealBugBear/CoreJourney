import 'package:shared_preferences/shared_preferences.dart';

enum MoodViewScope {
  package,
  overall,
}

enum MoodViewRangePreset {
  days30,
  days90,
  year1,
  all,
}

class MoodViewSettings {
  static const String _scopeKey = 'mood_view_scope';
  static const String _rangeKey = 'mood_view_range';

  static MoodViewScope scope(SharedPreferences prefs) {
    final raw = prefs.getString(_scopeKey);
    return switch (raw) {
      'overall' => MoodViewScope.overall,
      _ => MoodViewScope.package,
    };
  }

  static MoodViewRangePreset range(SharedPreferences prefs) {
    final raw = prefs.getString(_rangeKey);
    return switch (raw) {
      'days90' => MoodViewRangePreset.days90,
      'year1' => MoodViewRangePreset.year1,
      'all' => MoodViewRangePreset.all,
      _ => MoodViewRangePreset.days30,
    };
  }

  static Future<void> setScope(
    SharedPreferences prefs,
    MoodViewScope value,
  ) {
    return prefs.setString(_scopeKey, value.name);
  }

  static Future<void> setRange(
    SharedPreferences prefs,
    MoodViewRangePreset value,
  ) {
    return prefs.setString(_rangeKey, value.name);
  }
}
