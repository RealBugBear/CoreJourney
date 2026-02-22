import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/training/training_feedback_settings.dart';
import '../../domain/models/exercise.dart';
import '../providers/training_flow_provider.dart';
import '../widgets/animated_progress_bar.dart';
import '../widgets/premium_glassmorphic_card.dart';
import '../widgets/rhythm_visualizer.dart';
import '../widgets/parallel_lines_visualizer.dart';
import '../widgets/arc_swap_visualizer.dart';

class TrainingExerciseScreen extends ConsumerStatefulWidget {
  final Exercise exercise;
  final VoidCallback onComplete;
  final bool isLastExercise;

  const TrainingExerciseScreen({
    super.key,
    required this.exercise,
    required this.onComplete,
    this.isLastExercise = false,
  });

  @override
  ConsumerState<TrainingExerciseScreen> createState() =>
      _TrainingExerciseScreenState();
}

class _TrainingExerciseScreenState
    extends ConsumerState<TrainingExerciseScreen> {
  late double _intervalSeconds;
  bool _enableRhythmAudio = false;

  @override
  void initState() {
    super.initState();
    final ex = widget.exercise.exerciseNumber;
    _intervalSeconds = ex <= 5 ? 3 : 7;
    _loadFeedbackMode();
  }

  Future<void> _loadFeedbackMode() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = TrainingFeedbackSettings.feedbackMode(prefs);
    if (!mounted) return;
    setState(() {
      _enableRhythmAudio = mode == TrainingFeedbackMode.voiceAndCues;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final flowNotifier = ref.read(trainingFlowProvider.notifier);
    final exercise = widget.exercise;
    final isLastExercise = widget.isLastExercise;

    final exNum = exercise.exerciseNumber;
    final isEarly = exNum <= 5;
    final min = isEarly ? 3.0 : 6.0;
    final max = isEarly ? 7.0 : 12.0;
    final divisions = (max - min).round();
    final reps = isEarly ? 3 : 6;

    final visual = switch (exNum) {
      3 => ParallelLinesVisualizer(
          moveDuration: Duration(seconds: _intervalSeconds.toInt()),
          holdDuration: const Duration(seconds: 1),
          repetitions: 3,
          simultaneous: false,
        ),
      4 => ParallelLinesVisualizer(
          moveDuration: Duration(seconds: _intervalSeconds.toInt()),
          holdDuration: const Duration(seconds: 1),
          repetitions: 3,
          simultaneous: true,
        ),
      5 => ArcSwapVisualizer(
          interval: Duration(seconds: _intervalSeconds.toInt()),
          holdDuration: const Duration(seconds: 2),
          repetitions: 3,
        ),
      _ => RhythmVisualizer(
          config: RhythmConfig(
            pattern: (exNum == 1) ? RhythmPattern.v : RhythmPattern.i,
            interval: Duration(seconds: _intervalSeconds.toInt()),
            repetitions: reps,
            // I-pattern tuning:
            // - Exercise 2: hold at top is fixed 1s
            // - Exercises 6/7: hold at top is fixed 1s, move down is fixed 3s
            holdTop: (exNum == 2 || exNum == 6 || exNum == 7)
                ? const Duration(seconds: 1)
                : null,
            moveDown:
                (exNum == 6 || exNum == 7) ? const Duration(seconds: 3) : null,
          ),
          enableAudio: _enableRhythmAudio,
          autoplay: false,
          height: 180,
        ),
    };

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => flowNotifier.previousScreen(),
          tooltip: 'Zurück',
        ),
        // Slim progress bar between back and close buttons
        title: AnimatedProgressBar(
          currentStep: (exercise.exerciseNumber - 1) * 3 + 3,
          totalSteps: 21,
          compact: true,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _showCancelDialog(context),
            tooltip: 'Training abbrechen',
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primaryContainer.withOpacity(0.3),
              theme.colorScheme.secondaryContainer.withOpacity(0.2),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Timer Display - Compact and elegant
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 24,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${exercise.durationSeconds}s',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '${exercise.repetitions}× wiederholen',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  PremiumGlassmorphicCard(
                    blur: 18,
                    opacity: 0.10,
                    borderRadius: 20,
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        visual,
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              'Tempo',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.7),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              isEarly ? '3–7s' : '6–12s',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.5),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          min: min,
                          max: max,
                          divisions: divisions,
                          value: _intervalSeconds.clamp(min, max),
                          onChanged: (v) {
                            setState(() {
                              _intervalSeconds = v.roundToDouble();
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Execution Guide - HERO! Main focus
                  PremiumGlassmorphicCard(
                    blur: 25,
                    opacity: 0.15,
                    borderRadius: 20,
                    padding: const EdgeInsets.all(28.0),
                    child: Center(
                      child: Text(
                        exercise.executionGuide,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          height: 1.8,
                          fontWeight: FontWeight.w400,
                          fontSize: 22,
                          letterSpacing: 0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Complete Button - Prominent
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: widget.onComplete,
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        isLastExercise
                            ? 'Übung abschließen'
                            : 'Übung abgeschlossen',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Training abbrechen?'),
        content: const Text(
          'Möchtest du das Training wirklich abbrechen? Dein Fortschritt geht verloren.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Nein, weiter trainieren'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close training
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Ja, abbrechen'),
          ),
        ],
      ),
    );
  }
}
