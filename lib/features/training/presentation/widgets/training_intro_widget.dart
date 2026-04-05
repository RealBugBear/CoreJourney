import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/exercise.dart';
import '../../domain/models/training_session.dart';

class TrainingIntroWidget extends StatelessWidget {
  final Exercise exercise;
  final int exerciseIndex;
  final int totalExercises;
  final TrainingSessionMode mode;
  final VoidCallback onStart;
  final ValueChanged<TrainingSessionMode> onChangeMode;

  const TrainingIntroWidget({
    super.key,
    required this.exercise,
    required this.exerciseIndex,
    required this.totalExercises,
    required this.mode,
    required this.onStart,
    required this.onChangeMode,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${exerciseIndex + 1} / $totalExercises',
                  style: const TextStyle(
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Exercise image
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                exercise.imagePath,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            exercise.title(locale),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${exercise.durationSeconds}s · ${exercise.repetitions}x',
            style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 15),
          ),
          const SizedBox(height: 24),

          // Mode selector
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                _ModeTab(
                  label: l10n.tutorialMode,
                  selected: mode == TrainingSessionMode.tutorial,
                  onTap: () => onChangeMode(TrainingSessionMode.tutorial),
                ),
                _ModeTab(
                  label: l10n.routineMode,
                  selected: mode == TrainingSessionMode.routine,
                  onTap: () => onChangeMode(TrainingSessionMode.routine),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: onStart,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              backgroundColor: AppColors.primary,
            ),
            child: Text(
              l10n.startTraining,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? Colors.white : AppColors.textSecondaryDark,
            ),
          ),
        ),
      ),
    );
  }
}
