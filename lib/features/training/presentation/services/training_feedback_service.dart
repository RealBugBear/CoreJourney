import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/training/training_feedback_settings.dart';

class TrainingFeedbackService {
  final AudioPlayer _stepCuePlayer = AudioPlayer();
  final AudioPlayer _finishCuePlayer = AudioPlayer();
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final mixedAudioContext = AudioContextConfig(
        focus: AudioContextConfigFocus.mixWithOthers,
      ).build();
      await AudioPlayer.global.setAudioContext(mixedAudioContext);

      await _stepCuePlayer.setReleaseMode(ReleaseMode.stop);
      await _finishCuePlayer.setReleaseMode(ReleaseMode.stop);
      await _stepCuePlayer.setPlayerMode(PlayerMode.lowLatency);
      await _finishCuePlayer.setPlayerMode(PlayerMode.lowLatency);
      await _stepCuePlayer.setAudioContext(mixedAudioContext);
      await _finishCuePlayer.setAudioContext(mixedAudioContext);
    } catch (_) {
      // Keep the training flow running silently if sound init fails.
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final preset = TrainingFeedbackSettings.voicePreset(prefs);
      final selectedVoice =
          TrainingFeedbackSettings.voiceSelectionOrNull(prefs);
      await _tts.setSharedInstance(true);
      await _tts.autoStopSharedSession(true);
      await _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [IosTextToSpeechAudioCategoryOptions.mixWithOthers],
      );
      final profile = _voiceProfileFor(preset);
      await _tts.setSpeechRate(profile.speechRate);
      await _tts.setPitch(profile.pitch);
      await _tts.setVolume(profile.volume);
      final configuredLocale = selectedVoice?.locale ?? 'de-DE';
      await _tts.setLanguage(configuredLocale);
      if (selectedVoice != null) {
        final resolvedLocale = selectedVoice.locale ??
            await _resolveLocaleForVoiceName(selectedVoice.name);
        if (resolvedLocale != null && resolvedLocale.isNotEmpty) {
          await _tts.setLanguage(resolvedLocale);
        }
        final voiceConfig = <String, String>{'name': selectedVoice.name};
        if (resolvedLocale != null && resolvedLocale.isNotEmpty) {
          voiceConfig['locale'] = resolvedLocale;
        }
        await _tts.setVoice(voiceConfig);
      }
      await _tts.awaitSpeakCompletion(false);
    } catch (_) {
      // Voice cues are optional; ignore initialization issues.
    }
  }

  Future<void> onTrainingStarted({required bool routineMode}) async {
    final mode = await _mode();
    if (mode == TrainingFeedbackMode.silent) return;

    HapticFeedback.mediumImpact();
    if (mode == TrainingFeedbackMode.hapticOnly) return;

    await _speak(
      routineMode
          ? 'Routine Modus gestartet. Übung eins von sieben.'
          : 'Tutorial Modus gestartet.',
    );
  }

  Future<void> onExerciseEntered({
    required int exerciseNumber,
    required int totalExercises,
    required bool routineMode,
  }) async {
    final mode = await _mode();
    if (mode == TrainingFeedbackMode.silent) return;

    HapticFeedback.selectionClick();
    if (mode == TrainingFeedbackMode.hapticOnly) return;

    await _playStepCue();

    if (routineMode) {
      await _speak('Übung $exerciseNumber von $totalExercises.');
    }
  }

  Future<void> onExerciseCompleted({required bool isLast}) async {
    final mode = await _mode();
    if (mode == TrainingFeedbackMode.silent) return;

    if (isLast) {
      HapticFeedback.heavyImpact();
      if (mode != TrainingFeedbackMode.hapticOnly) {
        await _playFinishCue();
      }
      return;
    }

    HapticFeedback.lightImpact();
  }

  Future<void> onTrainingCompleted() async {
    final mode = await _mode();
    if (mode == TrainingFeedbackMode.silent) return;

    HapticFeedback.heavyImpact();
    if (mode == TrainingFeedbackMode.hapticOnly) {
      return;
    }

    await _playFinishCue();
    await _speak('Training abgeschlossen. Stark gemacht.');
  }

  Future<void> previewFeedbackMode(TrainingFeedbackMode mode) async {
    switch (mode) {
      case TrainingFeedbackMode.silent:
        HapticFeedback.lightImpact();
        return;
      case TrainingFeedbackMode.hapticOnly:
        HapticFeedback.mediumImpact();
        return;
      case TrainingFeedbackMode.voiceAndCues:
        HapticFeedback.selectionClick();
        await _playStepCue();
        await _speak('So klingt dein aktuelles Trainingsfeedback.');
        return;
    }
  }

  Future<TrainingFeedbackMode> _mode() async {
    final prefs = await SharedPreferences.getInstance();
    return TrainingFeedbackSettings.feedbackMode(prefs);
  }

  Future<void> dispose() async {
    try {
      await _tts.stop();
    } catch (_) {}
    await _stepCuePlayer.dispose();
    await _finishCuePlayer.dispose();
  }

  Future<void> refreshConfiguration() async {
    try {
      await _tts.stop();
    } catch (_) {}
    _initialized = false;
  }

  Future<void> _playStepCue() async {
    try {
      await init();
      await _stepCuePlayer.stop();
      await _stepCuePlayer.play(
        AssetSource('sounds/rhythm_arrive.wav'),
        mode: PlayerMode.lowLatency,
      );
    } catch (_) {}
  }

  Future<void> _playFinishCue() async {
    try {
      await init();
      await _finishCuePlayer.stop();
      await _finishCuePlayer.play(
        AssetSource('sounds/rhythm_hold_end.wav'),
        mode: PlayerMode.lowLatency,
      );
    } catch (_) {}
  }

  Future<void> _speak(String text) async {
    try {
      await init();
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {}
  }

  Future<String?> _resolveLocaleForVoiceName(String voiceName) async {
    try {
      final voices = await _tts.getVoices;
      for (final voice in voices) {
        if (voice is! Map) continue;
        final data = Map<String, dynamic>.from(voice);
        final name = (data['name'] ?? '').toString();
        if (name.toLowerCase() != voiceName.toLowerCase()) continue;
        final locale = (data['locale'] ?? '').toString();
        if (locale.isNotEmpty) return locale;
      }
    } catch (_) {}
    return null;
  }

  _VoiceProfile _voiceProfileFor(TrainingVoicePreset preset) {
    return switch (preset) {
      TrainingVoicePreset.calm => const _VoiceProfile(
          speechRate: 0.35,
          pitch: 0.88,
          volume: 0.82,
        ),
      TrainingVoicePreset.neutral => const _VoiceProfile(
          speechRate: 0.40,
          pitch: 0.92,
          volume: 0.86,
        ),
      TrainingVoicePreset.dynamic => const _VoiceProfile(
          speechRate: 0.46,
          pitch: 0.98,
          volume: 0.90,
        ),
    };
  }
}

class _VoiceProfile {
  final double speechRate;
  final double pitch;
  final double volume;

  const _VoiceProfile({
    required this.speechRate,
    required this.pitch,
    required this.volume,
  });
}
