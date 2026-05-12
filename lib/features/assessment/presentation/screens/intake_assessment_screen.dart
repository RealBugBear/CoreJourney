import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

final _hadTrainerProvider = StateProvider<bool?>((ref) => null);

class IntakeAssessmentScreen extends ConsumerWidget {
  const IntakeAssessmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final hadTrainer = ref.watch(_hadTrainerProvider);
    final extra = GoRouterState.of(context).extra;
    final packageId = extra is Map<String, dynamic>
        ? extra['packageId'] as String? ?? 'moro'
        : extra as String? ?? 'moro';
    final reflexProfileStatus = extra is Map<String, dynamic>
        ? extra['reflexProfileStatus'] as String?
        : null;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.intakeAssessmentTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: _BrandMark(size: 84),
              ),
              const SizedBox(height: 20),

              // ── Welcome ───────────────────────────────────────────────────
              _InfoCard(
                icon: Icons.self_improvement_outlined,
                iconColor: AppColors.primary,
                title: l10n.intakeWelcomeTitle,
                body: l10n.intakeWelcomeBody,
              ),
              const SizedBox(height: 16),

              // ── Trainer recommendation ────────────────────────────────────
              _InfoCard(
                icon: Icons.person_outline,
                iconColor: AppColors.success,
                title: l10n.intakeTrainerTitle,
                body: l10n.intakeTrainerBody,
              ),
              const SizedBox(height: 32),

              // ── Question ──────────────────────────────────────────────────
              Text(
                l10n.intakeQuestionLabel.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.questionIsometricWithTrainer,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),

              _AnswerButton(
                label: l10n.yes,
                selected: hadTrainer == true,
                onTap: () =>
                    ref.read(_hadTrainerProvider.notifier).state = true,
              ),
              const SizedBox(height: 12),
              _AnswerButton(
                label: l10n.no,
                selected: hadTrainer == false,
                onTap: () =>
                    ref.read(_hadTrainerProvider.notifier).state = false,
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: hadTrainer == null
                    ? null
                    : () {
                        ref.read(_hadTrainerProvider.notifier).state = null;
                        context.push(
                          Routes.trainerOnboardingPrompt,
                          extra: {
                            'packageId': packageId,
                            'hadIsometricWithTrainer': hadTrainer,
                            if (reflexProfileStatus != null)
                              'reflexProfileStatus': reflexProfileStatus,
                          },
                        );
                      },
                child: Text(l10n.next),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  final double size;

  const _BrandMark({required this.size});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/brand/free.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;

  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                ),
              ],
            ),
          ),
        ],
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
        backgroundColor:
            selected ? AppColors.primary.withValues(alpha: 0.08) : null,
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.divider,
          width: selected ? 2 : 1,
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          color: selected ? AppColors.primary : null,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}
