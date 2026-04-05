import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Keys ─────────────────────────────────────────────────────────────────────

const _kFeedbackMode = 'settings.feedbackMode';
const _kWeeklyGoal = 'settings.weeklyGoal';
const _kLanguage = 'settings.languageCode';
const _kThemeMode = 'settings.themeMode';
const _kRemindersEnabled = 'settings.remindersEnabled';
const _kReminderStart = 'settings.reminderStartMinutes';
const _kReminderEnd = 'settings.reminderEndMinutes';
const _kChildAssist = 'settings.childAssistMode';

// ── Model ─────────────────────────────────────────────────────────────────────

enum TrainingFeedbackMode { silent, haptic, voiceCues }

class AppSettings {
  final TrainingFeedbackMode feedbackMode;
  final int weeklyGoal;
  final String languageCode;
  final ThemeMode themeMode;
  final bool remindersEnabled;
  final int reminderStartMinutes; // hour*60 + minute
  final int reminderEndMinutes;
  final bool childAssistMode;

  const AppSettings({
    this.feedbackMode = TrainingFeedbackMode.haptic,
    this.weeklyGoal = 5,
    this.languageCode = 'de',
    this.themeMode = ThemeMode.system,
    this.remindersEnabled = false,
    this.reminderStartMinutes = 8 * 60, // 08:00
    this.reminderEndMinutes = 20 * 60, // 20:00
    this.childAssistMode = false,
  });

  TimeOfDay get reminderStart =>
      TimeOfDay(hour: reminderStartMinutes ~/ 60, minute: reminderStartMinutes % 60);
  TimeOfDay get reminderEnd =>
      TimeOfDay(hour: reminderEndMinutes ~/ 60, minute: reminderEndMinutes % 60);

  AppSettings copyWith({
    TrainingFeedbackMode? feedbackMode,
    int? weeklyGoal,
    String? languageCode,
    ThemeMode? themeMode,
    bool? remindersEnabled,
    int? reminderStartMinutes,
    int? reminderEndMinutes,
    bool? childAssistMode,
  }) {
    return AppSettings(
      feedbackMode: feedbackMode ?? this.feedbackMode,
      weeklyGoal: weeklyGoal ?? this.weeklyGoal,
      languageCode: languageCode ?? this.languageCode,
      themeMode: themeMode ?? this.themeMode,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      reminderStartMinutes: reminderStartMinutes ?? this.reminderStartMinutes,
      reminderEndMinutes: reminderEndMinutes ?? this.reminderEndMinutes,
      childAssistMode: childAssistMode ?? this.childAssistMode,
    );
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in main');
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  final SharedPreferences _prefs;

  SettingsNotifier(this._prefs) : super(_load(_prefs));

  static AppSettings _load(SharedPreferences prefs) {
    final modeIndex = prefs.getInt(_kFeedbackMode) ?? 1;
    final themeModeIndex = prefs.getInt(_kThemeMode) ?? 0;

    // If no language has been saved yet (first launch), detect from device locale.
    // We support 'de' and 'en'; everything else defaults to 'en'.
    final savedLanguage = prefs.getString(_kLanguage);
    final languageCode = savedLanguage ??
        (WidgetsBinding.instance.platformDispatcher.locale.languageCode == 'de'
            ? 'de'
            : 'en');

    return AppSettings(
      feedbackMode: TrainingFeedbackMode.values[modeIndex.clamp(
          0, TrainingFeedbackMode.values.length - 1)],
      weeklyGoal: prefs.getInt(_kWeeklyGoal) ?? 5,
      languageCode: languageCode,
      themeMode: ThemeMode.values[themeModeIndex.clamp(0, 2)],
      remindersEnabled: prefs.getBool(_kRemindersEnabled) ?? false,
      reminderStartMinutes: prefs.getInt(_kReminderStart) ?? 8 * 60,
      reminderEndMinutes: prefs.getInt(_kReminderEnd) ?? 20 * 60,
      childAssistMode: prefs.getBool(_kChildAssist) ?? false,
    );
  }

  void setFeedbackMode(TrainingFeedbackMode mode) {
    state = state.copyWith(feedbackMode: mode);
    _prefs.setInt(_kFeedbackMode, mode.index);
  }

  void setWeeklyGoal(int goal) {
    state = state.copyWith(weeklyGoal: goal);
    _prefs.setInt(_kWeeklyGoal, goal);
  }

  void setLanguage(String code) {
    state = state.copyWith(languageCode: code);
    _prefs.setString(_kLanguage, code);
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _prefs.setInt(_kThemeMode, mode.index);
  }

  void setRemindersEnabled(bool enabled) {
    state = state.copyWith(remindersEnabled: enabled);
    _prefs.setBool(_kRemindersEnabled, enabled);
  }

  void setReminderStart(TimeOfDay time) {
    final minutes = time.hour * 60 + time.minute;
    state = state.copyWith(reminderStartMinutes: minutes);
    _prefs.setInt(_kReminderStart, minutes);
  }

  void setReminderEnd(TimeOfDay time) {
    final minutes = time.hour * 60 + time.minute;
    state = state.copyWith(reminderEndMinutes: minutes);
    _prefs.setInt(_kReminderEnd, minutes);
  }

  void setChildAssistMode(bool enabled) {
    state = state.copyWith(childAssistMode: enabled);
    _prefs.setBool(_kChildAssist, enabled);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsNotifier(prefs);
});

// ── Derived providers consumed by app.dart ────────────────────────────────────

final localeProvider = Provider<Locale>((ref) {
  final code = ref.watch(settingsProvider).languageCode;
  return Locale(code);
});

final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(settingsProvider).themeMode;
});
