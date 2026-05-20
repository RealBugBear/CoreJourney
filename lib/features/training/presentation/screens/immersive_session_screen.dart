import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/training/transition_duration_settings.dart';
import '../../../../core/training/training_feedback_settings.dart';
import '../../domain/models/exercise.dart';
import '../../domain/services/audio_announcement_service.dart';
import '../widgets/exercise_transition_widget.dart';
import 'immersive_exercise_screen.dart';

enum _Phase { transition, exercise }

class ImmersiveSessionScreen extends StatefulWidget {
  final List<Exercise> exercises;
  final bool isRoutineMode;
  final List<String> companionSubjectProfileIds;
  final void Function(List<String> completedExerciseIds) onComplete;

  const ImmersiveSessionScreen({
    super.key,
    required this.exercises,
    required this.isRoutineMode,
    this.companionSubjectProfileIds = const [],
    required this.onComplete,
  });

  @override
  State<ImmersiveSessionScreen> createState() => _ImmersiveSessionScreenState();
}

class _ImmersiveSessionScreenState extends State<ImmersiveSessionScreen> {
  int _exerciseIndex = 0;
  _Phase _phase = _Phase.transition;
  final List<String> _completedIds = [];
  int _transitionDuration = 10;

  @override
  void initState() {
    super.initState();
    _loadTransitionDuration();
    if (widget.isRoutineMode && widget.exercises.isNotEmpty) {
      final first = widget.exercises.first;
      final isDuo = widget.companionSubjectProfileIds.isNotEmpty;
      unawaited(AudioAnnouncementService.instance.queue([
        'sounds/announcements/de/exercises/${first.id}_name.mp3',
        'sounds/announcements/de/exercises/${first.id}_position${isDuo ? '_duo' : ''}.mp3',
      ]));
    }
  }

  Future<void> _loadTransitionDuration() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _transitionDuration = TransitionDurationSettings.durationSeconds(prefs);
    });
  }

  @override
  void dispose() {
    AudioAnnouncementService.instance.stop();
    super.dispose();
  }

  void _onTransitionComplete() {
    setState(() => _phase = _Phase.exercise);
  }

  Future<void> _onExerciseComplete() async {
    final exercise = widget.exercises[_exerciseIndex];
    _completedIds.add(exercise.id);

    if (_exerciseIndex >= widget.exercises.length - 1) {
      widget.onComplete(List.unmodifiable(_completedIds));
      return;
    }

    // Play exercise-switch tone unless hapticOnly mode
    final prefs = await SharedPreferences.getInstance();
    final mode = TrainingFeedbackSettings.feedbackMode(prefs);
    if (mode != TrainingFeedbackMode.hapticOnly) {
      final player = AudioPlayer();
      try {
        final ctx = AudioContextConfig(
          focus: AudioContextConfigFocus.mixWithOthers,
        ).build();
        await player.setAudioContext(ctx);
        await player.setPlayerMode(PlayerMode.lowLatency);
        await player.play(AssetSource('sounds/rhythm_hold_end.wav'),
            mode: PlayerMode.lowLatency);
      } catch (_) {}
      await player.dispose();
    }

    if (!mounted) return;
    if (widget.isRoutineMode) {
      final nextExercise = widget.exercises[_exerciseIndex + 1];
      final isDuo = widget.companionSubjectProfileIds.isNotEmpty;
      unawaited(AudioAnnouncementService.instance.queue([
        'sounds/announcements/de/exercises/${nextExercise.id}_name.mp3',
        'sounds/announcements/de/exercises/${nextExercise.id}_position${isDuo ? '_duo' : ''}.mp3',
      ]));
    }
    setState(() {
      _exerciseIndex++;
      _phase = _Phase.transition;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.exercises.isEmpty) {
      return const SizedBox.shrink();
    }

    final exercise = widget.exercises[_exerciseIndex];
    final locale = Localizations.localeOf(context).languageCode;

    return switch (_phase) {
      _Phase.transition => ExerciseTransitionWidget(
          key: ValueKey('transition_$_exerciseIndex'),
          exercise: exercise,
          exerciseIndex: _exerciseIndex,
          totalExercises: widget.exercises.length,
          isRoutineMode: widget.isRoutineMode,
          transitionDurationSeconds: _transitionDuration,
          locale: locale,
          onStart: _onTransitionComplete,
        ),
      _Phase.exercise => ImmersiveExerciseScreen(
          key: ValueKey('exercise_$_exerciseIndex'),
          exercise: exercise,
          exerciseIndex: _exerciseIndex,
          totalExercises: widget.exercises.length,
          isRoutineMode: widget.isRoutineMode,
          onComplete: _onExerciseComplete,
        ),
    };
  }
}
