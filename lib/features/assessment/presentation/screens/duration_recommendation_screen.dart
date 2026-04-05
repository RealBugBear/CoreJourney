import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../bootstrap/providers.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/widgets/error_retry_widget.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../progress/presentation/providers/progress_provider.dart';

int _computeRecommendedWeeks({required bool hadIsometricWithTrainer}) {
  return hadIsometricWithTrainer ? 6 : 8;
}

class DurationRecommendationScreen extends ConsumerStatefulWidget {
  const DurationRecommendationScreen({super.key});

  @override
  ConsumerState<DurationRecommendationScreen> createState() =>
      _DurationRecommendationScreenState();
}

class _DurationRecommendationScreenState
    extends ConsumerState<DurationRecommendationScreen> {
  late int _selectedWeeks;
  late String _packageId;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final extra =
        GoRouterState.of(context).extra as Map<String, dynamic>?;
    _packageId = extra?['packageId'] as String? ?? 'moro';
    final hadTrainer =
        extra?['hadIsometricWithTrainer'] as bool? ?? false;
    _selectedWeeks =
        _computeRecommendedWeeks(hadIsometricWithTrainer: hadTrainer);
  }

  Future<void> _confirm() async {
    setState(() => _saving = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      await createEnrollment(
        db: ref.read(databaseProvider),
        syncService: ref.read(syncServiceProvider),
        userId: userId,
        packageId: _packageId,
        durationWeeks: _selectedWeeks,
      );

      // Update the selected package so the dashboard shows this enrollment
      ref.read(selectedPackageIdProvider.notifier).select(_packageId);

      if (mounted) context.go(Routes.dashboard);
    } catch (_) {
      if (mounted) showErrorSnackBar(context, AppLocalizations.of(context).errorGeneric);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.adjustDuration)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Text(
                l10n.durationRecommendation(_selectedWeeks),
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.daysCount(_selectedWeeks * 7),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Slider(
                value: _selectedWeeks.toDouble(),
                min: 4,
                max: 8,
                divisions: 4,
                label: l10n.weeksCount(_selectedWeeks),
                onChanged: (v) =>
                    setState(() => _selectedWeeks = v.round()),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.weeksCount(4), style: Theme.of(context).textTheme.bodySmall),
                  Text(l10n.weeksCount(8), style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _saving ? null : _confirm,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(l10n.confirm),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
