import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../../l10n/app_localizations.dart';

final _hadTrainerProvider = StateProvider<bool?>((ref) => null);

class IntakeAssessmentScreen extends ConsumerWidget {
  const IntakeAssessmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final hadTrainer = ref.watch(_hadTrainerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.intakeAssessmentTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Text(
                l10n.questionIsometricWithTrainer,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 32),
              _AnswerButton(
                label: l10n.yes,
                selected: hadTrainer == true,
                onTap: () => ref.read(_hadTrainerProvider.notifier).state = true,
              ),
              const SizedBox(height: 12),
              _AnswerButton(
                label: l10n.no,
                selected: hadTrainer == false,
                onTap: () => ref.read(_hadTrainerProvider.notifier).state = false,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: hadTrainer == null
                    ? null
                    : () => context.push(
                          Routes.durationRecommendation,
                          extra: {'hadIsometricWithTrainer': hadTrainer},
                        ),
                child: Text(l10n.next),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnswerButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _AnswerButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: selected
            ? Theme.of(context).colorScheme.primaryContainer
            : null,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 16)),
    );
  }
}
