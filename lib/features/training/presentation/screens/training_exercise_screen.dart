import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/exercise.dart';
import '../providers/training_flow_provider.dart';
import '../widgets/animated_progress_bar.dart';
import '../widgets/premium_glassmorphic_card.dart';

class TrainingExerciseScreen extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final flowNotifier = ref.read(trainingFlowProvider.notifier);
    
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
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
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
                
                // Exercise Image - Medium size
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: theme.colorScheme.onPrimaryContainer.withOpacity(0.15),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 1,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        exercise.imagePath,
                        width: 220,
                        height: 220,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 220,
                            height: 220,
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.image_not_supported,
                              size: 42,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Execution Guide - HERO! Main focus
                Expanded(
                  child: PremiumGlassmorphicCard(
                    blur: 25,
                    opacity: 0.15,
                    borderRadius: 20,
                    padding: const EdgeInsets.all(28.0),
                    child: Center(
                      child: SingleChildScrollView(
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
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Complete Button - Prominent
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: onComplete,
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      isLastExercise ? 'Übung abschließen' : 'Übung abgeschlossen',
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
