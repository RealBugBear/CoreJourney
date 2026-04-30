import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/trainer_profile.dart';
import '../providers/trainer_discovery_provider.dart';

class TrainerPublicProfileScreen extends ConsumerStatefulWidget {
  const TrainerPublicProfileScreen({
    super.key,
    required this.trainer,
    this.onboardingExtra,
  });

  final TrainerProfile trainer;
  final Map<String, dynamic>? onboardingExtra;

  @override
  ConsumerState<TrainerPublicProfileScreen> createState() =>
      _TrainerPublicProfileScreenState();
}

class _TrainerPublicProfileScreenState
    extends ConsumerState<TrainerPublicProfileScreen> {
  bool _isRequesting = false;
  bool _requestSent = false;
  String? _errorMessage;

  Future<void> _sendRequest() async {
    setState(() {
      _isRequesting = true;
      _errorMessage = null;
    });
    try {
      await sendDiscoveryRequest(ref, widget.trainer.id);
      if (mounted) setState(() => _requestSent = true);
    } on Exception catch (e) {
      final msg = e.toString();
      if (!mounted) return;
      if (msg.contains('Anfrage bereits gesendet') || msg.contains('already')) {
        final l10n = AppLocalizations.of(context);
        setState(() => _errorMessage = l10n.trainerDiscoveryRequestAlreadySent);
      } else if (msg.toLowerCase().contains('bereits verbunden') ||
          msg.contains('connected')) {
        final l10n = AppLocalizations.of(context);
        setState(
            () => _errorMessage = l10n.trainerDiscoveryRequestAlreadyConnected);
      } else {
        setState(() => _errorMessage = msg);
      }
    } finally {
      if (mounted) setState(() => _isRequesting = false);
    }
  }

  void _continueOnboarding() {
    final extra = widget.onboardingExtra;
    if (extra == null) return;
    context.go(Routes.durationRecommendation, extra: extra);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = widget.trainer;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.trainerPublicProfileTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: t.photoUrl != null
                ? CircleAvatar(
                    backgroundImage: NetworkImage(t.photoUrl!),
                    radius: 48,
                  )
                : const CircleAvatar(
                    radius: 48,
                    child: Icon(Icons.person, size: 48),
                  ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t.displayName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (t.verified) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.verified,
                      color: AppColors.primary, size: 22),
                ],
              ],
            ),
          ),
          if (t.verified)
            Center(
              child: Text(
                l10n.trainerPublicProfileVerified,
                style: const TextStyle(color: AppColors.primary),
              ),
            ),
          if (t.distanceKm != null) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                l10n.trainerDiscoveryDistanceLabel(t.distanceKm!),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
          if (t.bio != null) ...[
            const SizedBox(height: 24),
            Text(t.bio!),
          ],
          const SizedBox(height: 32),
          if (_requestSent)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Text(
                    l10n.trainerDiscoveryRequestSent,
                    style: const TextStyle(color: AppColors.success),
                  ),
                ),
                if (widget.onboardingExtra != null) ...[
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _continueOnboarding,
                    child: Text(l10n.trainerOnboardingContinueAfterRequest),
                  ),
                ],
              ],
            )
          else ...[
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
              ),
            FilledButton(
              onPressed: _isRequesting ? null : _sendRequest,
              child: _isRequesting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.trainerDiscoverySendRequest),
            ),
          ],
        ],
      ),
    );
  }
}
