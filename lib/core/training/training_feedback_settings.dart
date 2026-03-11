import 'package:shared_preferences/shared_preferences.dart';

enum TrainingFeedbackMode {
  silent,
  hapticOnly,
  voiceAndCues,
}

enum TrainingVoicePreset {
  calm,
  neutral,
  dynamic,
}

class TrainingFeedbackSettings {
  static const String trainingFeedbackModeKey = 'training_feedback_mode';
  static const String trainingVoicePresetKey = 'training_voice_preset';
  static const String trainingVoiceNameKey = 'training_voice_name';
  static const String trainingVoiceLocaleKey = 'training_voice_locale';

  static TrainingFeedbackMode feedbackMode(SharedPreferences prefs) {
    final raw = prefs.getString(trainingFeedbackModeKey);
    return switch (raw) {
      'silent' => TrainingFeedbackMode.silent,
      'hapticOnly' => TrainingFeedbackMode.hapticOnly,
      'voiceAndCues' => TrainingFeedbackMode.voiceAndCues,
      _ => TrainingFeedbackMode.voiceAndCues,
    };
  }

  static Future<void> setFeedbackMode(
    SharedPreferences prefs,
    TrainingFeedbackMode mode,
  ) {
    return prefs.setString(trainingFeedbackModeKey, mode.name);
  }

  static TrainingVoicePreset voicePreset(SharedPreferences prefs) {
    final raw = prefs.getString(trainingVoicePresetKey);
    return switch (raw) {
      'calm' => TrainingVoicePreset.calm,
      'dynamic' => TrainingVoicePreset.dynamic,
      'neutral' => TrainingVoicePreset.neutral,
      _ => TrainingVoicePreset.calm,
    };
  }

  static Future<void> setVoicePreset(
    SharedPreferences prefs,
    TrainingVoicePreset preset,
  ) {
    return prefs.setString(trainingVoicePresetKey, preset.name);
  }

  static String? voiceNameOrNull(SharedPreferences prefs) {
    return prefs.getString(trainingVoiceNameKey);
  }

  static TrainingVoiceSelection? voiceSelectionOrNull(SharedPreferences prefs) {
    final name = prefs.getString(trainingVoiceNameKey);
    if (name == null || name.isEmpty) return null;
    final locale = prefs.getString(trainingVoiceLocaleKey);
    if (locale == null || locale.isEmpty) {
      return TrainingVoiceSelection(name: name);
    }
    return TrainingVoiceSelection(name: name, locale: locale);
  }

  static Future<void> setVoiceName(
    SharedPreferences prefs,
    String? voiceName,
  ) {
    if (voiceName == null || voiceName.isEmpty) {
      return Future.wait([
        prefs.remove(trainingVoiceNameKey),
        prefs.remove(trainingVoiceLocaleKey),
      ]);
    }
    return prefs.setString(trainingVoiceNameKey, voiceName);
  }

  static Future<void> setVoiceSelection(
    SharedPreferences prefs,
    TrainingVoiceSelection? selection,
  ) async {
    if (selection == null) {
      await Future.wait([
        prefs.remove(trainingVoiceNameKey),
        prefs.remove(trainingVoiceLocaleKey),
      ]);
      return;
    }
    await prefs.setString(trainingVoiceNameKey, selection.name);
    if (selection.locale == null || selection.locale!.isEmpty) {
      await prefs.remove(trainingVoiceLocaleKey);
      return;
    }
    await prefs.setString(trainingVoiceLocaleKey, selection.locale!);
  }
}

class TrainingVoiceSelection {
  final String name;
  final String? locale;

  const TrainingVoiceSelection({
    required this.name,
    this.locale,
  });
}
