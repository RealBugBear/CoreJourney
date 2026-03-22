import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../../l10n/app_localizations.dart';

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
  bool _hadTrainer = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    _hadTrainer = extra?['hadIsometricWithTrainer'] as bool? ?? false;
    _selectedWeeks = _computeRecommendedWeeks(hadIsometricWithTrainer: _hadTrainer);
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
              const SizedBox(height: 32),
              Slider(
                value: _selectedWeeks.toDouble(),
                min: 4,
                max: 8,
                divisions: 4,
                label: '$_selectedWeeks ${l10n.daysRemaining(0).replaceAll('0 ', '')}',
                onChanged: (v) => setState(() => _selectedWeeks = v.round()),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('4', style: Theme.of(context).textTheme.bodySmall),
                  Text('8', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  // TODO: create enrollment with _selectedWeeks, then go to dashboard
                  context.go(Routes.dashboard);
                },
                child: Text(l10n.confirm),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
