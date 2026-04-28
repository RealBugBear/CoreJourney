import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/trainer_profile.dart';
import '../providers/trainer_discovery_provider.dart';

class TrainerProfilePendingScreen extends ConsumerStatefulWidget {
  const TrainerProfilePendingScreen({super.key});

  @override
  ConsumerState<TrainerProfilePendingScreen> createState() =>
      _TrainerProfilePendingScreenState();
}

class _TrainerProfilePendingScreenState
    extends ConsumerState<TrainerProfilePendingScreen> {
  bool _isChecking = false;

  Future<void> _checkStatus() async {
    setState(() => _isChecking = true);
    try {
      ref.invalidate(ownTrainerProfileProvider);
      final profile = await ref.read(ownTrainerProfileProvider.future);
      if (!mounted) return;
      if (profile != null && profile.status == TrainerProfileStatus.active) {
        context.go(Routes.trainerDashboard);
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.hourglass_top_rounded,
                  size: 72, color: AppColors.primary),
              const SizedBox(height: 24),
              Text(
                l10n.trainerSetupPendingTitle,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.trainerSetupPendingBody,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _isChecking ? null : _checkStatus,
                icon: _isChecking
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label: Text(l10n.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
