import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../../core/analytics/analytics_provider.dart';
import '../../../../core/training/training_launch_settings.dart';
import '../../../mood/domain/models/mood_checkin.dart';
import '../../../mood/presentation/providers/mood_provider.dart';
import '../../domain/models/exercise.dart';
import '../providers/training_flow_provider.dart';
import '../services/training_feedback_service.dart';
import 'training_intro_screen.dart';
import 'training_position_screen.dart';
import 'training_movement_screen.dart';
import 'training_exercise_screen.dart';
import 'training_outro_screen.dart';

class TrainingFlowScreen extends ConsumerStatefulWidget {
  const TrainingFlowScreen({super.key});

  @override
  ConsumerState<TrainingFlowScreen> createState() => _TrainingFlowScreenState();
}

class _TrainingFlowScreenState extends ConsumerState<TrainingFlowScreen> {
  final TrainingFeedbackService _feedback = TrainingFeedbackService();
  final Stopwatch _funnelStopwatch = Stopwatch();
  bool _didAnnounceStart = false;
  bool _firstExerciseLogged = false;
  bool _completionHandled = false;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _feedback.init();
    _funnelStopwatch.start();
  }

  @override
  void dispose() {
    _feedback.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<TrainingFlowState>(trainingFlowProvider, (previous, next) {
      _handleFeedback(previous, next);
    });

    final flowState = ref.watch(trainingFlowProvider);
    final flowNotifier = ref.read(trainingFlowProvider.notifier);

    if (!_didAnnounceStart) {
      _didAnnounceStart = true;
      final routineMode = flowState.mode == TrainingMode.routine;
      _feedback.onTrainingStarted(routineMode: routineMode);
      if (flowState.screenType == TrainingScreenType.exercise &&
          flowState.currentExerciseIndex == 0) {
        _logFirstExerciseEntered(flowState);
      }
    }

    // If completed, capture mood first and then navigate back to dashboard.
    if (flowState.isCompleted && !_completionHandled) {
      _completionHandled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleTrainingCompletion();
      });
    }

    return _buildCurrentScreen(flowState, flowNotifier);
  }

  void _handleFeedback(TrainingFlowState? previous, TrainingFlowState next) {
    final routineMode = next.mode == TrainingMode.routine;
    if (previous == null) return;

    final enteredAnotherExercise =
        next.screenType == TrainingScreenType.exercise &&
            (previous.screenType != TrainingScreenType.exercise ||
                previous.currentExerciseIndex != next.currentExerciseIndex);
    if (enteredAnotherExercise) {
      _feedback.onExerciseEntered(
        exerciseNumber: next.currentExerciseIndex + 1,
        totalExercises: exercises.length,
        routineMode: routineMode,
      );
      if (next.currentExerciseIndex == 0) {
        _logFirstExerciseEntered(next);
      }
    }

    final leftExercise = previous.screenType == TrainingScreenType.exercise &&
        (next.screenType != TrainingScreenType.exercise ||
            previous.currentExerciseIndex != next.currentExerciseIndex);
    if (leftExercise) {
      _feedback.onExerciseCompleted(
        isLast: previous.isLastExercise,
      );
    }

    if (!previous.isCompleted && next.isCompleted) {
      _feedback.onTrainingCompleted();
    }
  }

  Widget _buildCurrentScreen(
    TrainingFlowState state,
    TrainingFlowNotifier notifier,
  ) {
    switch (state.screenType) {
      case TrainingScreenType.intro:
        return TrainingIntroScreen(
          onStart: () => _handleIntroStart(state, notifier),
        );

      case TrainingScreenType.position:
        final exercise = state.getCurrentExercise();
        if (exercise == null) {
          return const Scaffold(
            body: Center(child: Text('Fehler: Übung nicht gefunden')),
          );
        }
        return TrainingPositionScreen(
          exercise: exercise,
          onContinue: () => notifier.nextScreen(),
        );

      case TrainingScreenType.movement:
        final exercise = state.getCurrentExercise();
        if (exercise == null) {
          return const Scaffold(
            body: Center(child: Text('Fehler: Übung nicht gefunden')),
          );
        }
        return TrainingMovementScreen(
          exercise: exercise,
          onContinue: () => notifier.nextScreen(),
        );

      case TrainingScreenType.exercise:
        final exercise = state.getCurrentExercise();
        if (exercise == null) {
          return const Scaffold(
            body: Center(child: Text('Fehler: Übung nicht gefunden')),
          );
        }
        return TrainingExerciseScreen(
          exercise: exercise,
          isLastExercise: state.isLastExercise,
          routineMode: state.mode == TrainingMode.routine,
          deferAutoplayForAnnouncement: state.mode == TrainingMode.routine &&
              state.currentExerciseIndex == 0,
          onComplete: () => notifier.nextScreen(),
        );

      case TrainingScreenType.outro:
        return TrainingOutroScreen(
          onFinish: () => notifier.nextScreen(),
        );
    }
  }

  Future<void> _handleIntroStart(
    TrainingFlowState state,
    TrainingFlowNotifier notifier,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await TrainingLaunchSettings.setDirectStartEnabled(
      prefs,
      state.mode == TrainingMode.routine,
    );
    notifier.nextScreen();
  }

  void _logFirstExerciseEntered(TrainingFlowState state) {
    if (_firstExerciseLogged) return;
    _firstExerciseLogged = true;
    unawaited(
      ref.read(analyticsServiceProvider).logEvent(
        name: 'training_first_exercise_entered',
        parameters: {
          'mode': state.mode.name,
          'compact_tutorial': state.compactTutorial,
          'time_to_first_exercise_ms': _funnelStopwatch.elapsedMilliseconds,
        },
      ),
    );
  }

  Future<void> _handleTrainingCompletion() async {
    if (!mounted) return;

    await ref.read(analyticsServiceProvider).logEvent(
      name: 'mood_prompt_shown',
      parameters: const {
        'source': 'post_training_prompt',
      },
    );

    final result = await _showMoodCheckinSheet(context);
    if (!mounted) return;

    if (result == null || result.skipped) {
      await ref.read(analyticsServiceProvider).logEvent(
        name: 'mood_prompt_skipped',
        parameters: const {
          'source': 'post_training_prompt',
        },
      );
      Navigator.of(context).pop(true);
      return;
    }

    await ref.read(moodRepositoryProvider).createCheckin(
          packageId: 'core',
          source: MoodCheckinSource.postTrainingPrompt,
          mood: result.mood,
          energy: result.energy,
          stress: result.stress,
          note: result.note,
        );

    await ref.read(analyticsServiceProvider).logEvent(
      name: 'mood_prompt_submitted',
      parameters: {
        'source': 'post_training_prompt',
        'mood': result.mood,
        'energy': result.energy,
        'stress': result.stress,
        'has_note': result.note?.isNotEmpty == true,
      },
    );

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<_MoodPromptResult?> _showMoodCheckinSheet(BuildContext context) {
    var mood = 3;
    var energy = 3;
    var stress = 3;
    final noteController = TextEditingController();

    return showModalBottomSheet<_MoodPromptResult>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Widget scoreRow({
              required String label,
              required int current,
              required ValueChanged<int> onChanged,
            }) {
              return Row(
                children: [
                  SizedBox(
                    width: 84,
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  Expanded(
                    child: SegmentedButton<int>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(value: 1, label: Text('1')),
                        ButtonSegment(value: 2, label: Text('2')),
                        ButtonSegment(value: 3, label: Text('3')),
                        ButtonSegment(value: 4, label: Text('4')),
                        ButtonSegment(value: 5, label: Text('5')),
                      ],
                      selected: {current},
                      onSelectionChanged: (selection) {
                        onChanged(selection.first);
                      },
                    ),
                  ),
                ],
              );
            }

            Widget scaleHint({
              required String lowLabel,
              required String highLabel,
            }) {
              return Padding(
                padding: const EdgeInsets.only(left: 84, top: 4),
                child: Row(
                  children: [
                    Text(
                      '1 = $lowLabel',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const Spacer(),
                    Text(
                      '5 = $highLabel',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              );
            }

            return SafeArea(
              child: GestureDetector(
                onTap: () => FocusScope.of(sheetContext).unfocus(),
                child: AnimatedPadding(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOut,
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kurzer Check-in',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Wie fühlst du dich nach dem Training?',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 12),
                          scoreRow(
                            label: 'Stimmung',
                            current: mood,
                            onChanged: (value) =>
                                setModalState(() => mood = value),
                          ),
                          scaleHint(lowLabel: 'schlecht', highLabel: 'gut'),
                          const SizedBox(height: 8),
                          scoreRow(
                            label: 'Energie',
                            current: energy,
                            onChanged: (value) =>
                                setModalState(() => energy = value),
                          ),
                          scaleHint(lowLabel: 'schwach', highLabel: 'hoch'),
                          const SizedBox(height: 8),
                          scoreRow(
                            label: 'Stress',
                            current: stress,
                            onChanged: (value) =>
                                setModalState(() => stress = value),
                          ),
                          scaleHint(lowLabel: 'viel', highLabel: 'wenig'),
                          const SizedBox(height: 10),
                          TextField(
                            controller: noteController,
                            minLines: 1,
                            maxLines: 8,
                            textInputAction: TextInputAction.newline,
                            onTapOutside: (_) =>
                                FocusScope.of(sheetContext).unfocus(),
                            decoration: const InputDecoration(
                              labelText: 'Notiz (optional)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              TextButton(
                                onPressed: () {
                                  FocusScope.of(sheetContext).unfocus();
                                  Navigator.of(context).pop(
                                    const _MoodPromptResult(skipped: true),
                                  );
                                },
                                child: const Text('Überspringen'),
                              ),
                              const Spacer(),
                              FilledButton(
                                onPressed: () {
                                  FocusScope.of(sheetContext).unfocus();
                                  Navigator.of(context).pop(
                                    _MoodPromptResult(
                                      skipped: false,
                                      mood: mood,
                                      energy: energy,
                                      stress: stress,
                                      note: noteController.text.trim().isEmpty
                                          ? null
                                          : noteController.text.trim(),
                                    ),
                                  );
                                },
                                child: const Text('Speichern'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(noteController.dispose);
  }
}

class _MoodPromptResult {
  final bool skipped;
  final int mood;
  final int energy;
  final int stress;
  final String? note;

  const _MoodPromptResult({
    required this.skipped,
    this.mood = 3,
    this.energy = 3,
    this.stress = 3,
    this.note,
  });
}
