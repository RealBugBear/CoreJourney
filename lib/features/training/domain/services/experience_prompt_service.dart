import 'package:shared_preferences/shared_preferences.dart';

class ExperiencePromptService {
  static const _key = 'last_experience_prompt_date';

  /// Returns true if the experience prompt has not been shown today.
  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return true;
    final last = DateTime.parse(raw);
    final now = DateTime.now();
    return !(last.year == now.year &&
        last.month == now.month &&
        last.day == now.day);
  }

  /// Records that the prompt was shown today.
  static Future<void> markShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, DateTime.now().toIso8601String());
  }
}
