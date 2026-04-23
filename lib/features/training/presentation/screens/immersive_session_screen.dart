import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/training/transition_duration_settings.dart';
import '../../domain/models/exercise.dart';
import '../widgets/exercise_transition_widget.dart';
import 'immersive_exercise_screen.dart';

enum _Phase { transition, exercise }

class ImmersiveSessionScreen extends StatefulWidget {
  final List<Exercise> exercises;
  final bool isRoutineMode;
  final void Function(List<String> completedExerciseIds) onComplete;

  const ImmersiveSessionScreen({
    super.key,
    required this.exercises,
    required this.isRoutineMode,
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
  }

  Future<void> _loadTransitionDuration() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _transitionDuration = TransitionDurationSettings.durationSeconds(prefs);
    });
  }

  void _onTransitionComplete() {
    setState(() => _phase = _Phase.exercise);
  }

  void _onExerciseComplete() {
    final exercise = widget.exercises[_exerciseIndex];
    _completedIds.add(exercise.id);

    if (_exerciseIndex >= widget.exercises.length - 1) {
      widget.onComplete(List.unmodifiable(_completedIds));
      return;
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
