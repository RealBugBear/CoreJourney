import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../trainer/presentation/providers/trainer_provider.dart';

class TrainerOnboardingPromptScreen extends ConsumerStatefulWidget {
  const TrainerOnboardingPromptScreen({super.key});

  @override
  ConsumerState<TrainerOnboardingPromptScreen> createState() =>
      _TrainerOnboardingPromptScreenState();
}

class _TrainerOnboardingPromptScreenState
    extends ConsumerState<TrainerOnboardingPromptScreen> {
  bool _connecting = false;
  String? _inviteError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final hasTrainer =
          ref.read(clientTrainerProvider).valueOrNull != null;
      if (hasTrainer) _continueToDuration();
    });
  }

  Map<String, dynamic> get _extra {
    return GoRouterState.of(context).extra as Map<String, dynamic>? ??
        const <String, dynamic>{};
  }

  String get _packageId => _extra['packageId'] as String? ?? 'moro';

  bool get _hadTrainer => _extra['hadIsometricWithTrainer'] as bool? ?? false;

  Map<String, dynamic> get _durationExtra => {
        'packageId': _packageId,
        'hadIsometricWithTrainer': _hadTrainer,
        if (_extra['reflexProfileStatus'] != null)
          'reflexProfileStatus': _extra['reflexProfileStatus'],
      };

  void _continueToDuration() {
    context.go(Routes.durationRecommendation, extra: _durationExtra);
  }

  void _openDiscovery() {
    context.push(
      Routes.trainerDiscovery,
      extra: {
        'onboardingExtra': _durationExtra,
      },
    );
  }

  Future<void> _showInviteDialog() async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    _inviteError = null;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n.trainerOnboardingInviteTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.trainerOnboardingInviteBody),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.visiblePassword,
                textCapitalization: TextCapitalization.characters,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 8,
                ),
                decoration: InputDecoration(
                  labelText: l10n.enterInviteCode,
                  border: const OutlineInputBorder(),
                  errorText: _inviteError,
                  counterText: '',
                  hintText: 'A1B2C3',
                ),
                onChanged: (_) => setDialogState(() => _inviteError = null),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: _connecting ? null : () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: _connecting
                  ? null
                  : () async {
                      final code = controller.text
                          .replaceAll(RegExp(r'\s'), '')
                          .trim()
                          .toUpperCase();
                      if (code.length != 6) {
                        setDialogState(() {
                          _inviteError = l10n.trainerOnboardingInviteInvalid;
                        });
                        return;
                      }

                      setDialogState(() => _connecting = true);
                      try {
                        await acceptInvite(code);
                        ref.invalidate(clientTrainerProvider);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) _continueToDuration();
                      } catch (_) {
                        setDialogState(() {
                          _connecting = false;
                          _inviteError = l10n.trainerOnboardingInviteFailed;
                        });
                      }
                    },
              child: _connecting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.connectToTrainer),
            ),
          ],
        ),
      ),
    );

    controller.dispose();
    if (mounted) setState(() => _connecting = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final title = _hadTrainer
        ? l10n.trainerOnboardingConnectTitle
        : l10n.trainerOnboardingFindTitle;
    final body = _hadTrainer
        ? l10n.trainerOnboardingConnectBody
        : l10n.trainerOnboardingFindBody;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.trainerOnboardingTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                border: Border.all(color: AppColors.divider),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.groups_2_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          body,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: cs.onSurfaceVariant,
                                    height: 1.45,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _openDiscovery,
              icon: const Icon(Icons.travel_explore_outlined),
              label: Text(l10n.trainerOnboardingSearchCta),
            ),
            if (_hadTrainer) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _showInviteDialog,
                icon: const Icon(Icons.key_outlined),
                label: Text(l10n.trainerOnboardingInviteCta),
              ),
            ],
            const SizedBox(height: 12),
            TextButton(
              onPressed: _continueToDuration,
              child: Text(l10n.trainerOnboardingSkipCta),
            ),
          ],
        ),
      ),
    );
  }
}
