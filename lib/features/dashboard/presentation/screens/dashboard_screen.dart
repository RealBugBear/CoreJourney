import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CoreJourney'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(Routes.settings),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // KPI Grid
              _KpiGrid(l10n: l10n),
              const SizedBox(height: 20),

              // Weekly calendar strip
              _WeeklyCalendarStrip(),
              const SizedBox(height: 20),

              // Mode selector
              _ModeSelector(l10n: l10n),
              const SizedBox(height: 20),

              // Start Training CTA
              ElevatedButton.icon(
                onPressed: () => context.push(Routes.trainingSession),
                icon: const Icon(Icons.play_arrow_rounded, size: 28),
                label: Text(
                  l10n.startTraining,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),

              // Mood chart placeholder
              _MoodChartCard(l10n: l10n),
              const SizedBox(height: 20),

              // Program card
              _ProgramCard(l10n: l10n),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  final AppLocalizations l10n;
  const _KpiGrid({required this.l10n});

  @override
  Widget build(BuildContext context) {
    // TODO: wire to activeProgressProvider
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _KpiCard(
          label: l10n.currentDay(1, 56),
          value: 'Tag 1',
          icon: Icons.calendar_today_outlined,
        ),
        _KpiCard(
          label: l10n.dailyStreak,
          value: '0 🔥',
          icon: Icons.local_fire_department_outlined,
        ),
        _KpiCard(
          label: l10n.weeklyProgress(0, 5),
          value: '0 / 5',
          icon: Icons.check_circle_outline,
        ),
        _KpiCard(
          label: l10n.goldenDay,
          value: l10n.daysRemaining(55),
          icon: Icons.star_outline,
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyCalendarStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final day = weekStart.add(Duration(days: i));
        final isToday = day.day == now.day && day.month == now.month;
        final isPast = day.isBefore(DateTime(now.year, now.month, now.day));

        return _DayDot(
          dayLetter: _dayLetter(day.weekday),
          dayNumber: day.day,
          isToday: isToday,
          isCompleted: false, // TODO: wire to sessions
          isPast: isPast,
        );
      }),
    );
  }

  String _dayLetter(int weekday) {
    const letters = ['M', 'D', 'M', 'D', 'F', 'S', 'S'];
    return letters[weekday - 1];
  }
}

class _DayDot extends StatelessWidget {
  final String dayLetter;
  final int dayNumber;
  final bool isToday;
  final bool isCompleted;
  final bool isPast;

  const _DayDot({
    required this.dayLetter,
    required this.dayNumber,
    required this.isToday,
    required this.isCompleted,
    required this.isPast,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCompleted
        ? AppColors.success
        : isToday
            ? AppColors.primary
            : isPast
                ? AppColors.textDisabled
                : AppColors.divider;

    return Column(
      children: [
        Text(
          dayLetter,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isToday || isCompleted ? color : null,
            border: Border.all(color: color, width: 1.5),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text(
                    '$dayNumber',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                      color: isToday ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

enum TrainingMode { tutorial, routine }

final _trainingModeProvider = StateProvider<TrainingMode>(
  (ref) => TrainingMode.tutorial,
);

class _ModeSelector extends ConsumerWidget {
  final AppLocalizations l10n;
  const _ModeSelector({required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(_trainingModeProvider);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _ModeTab(
            label: l10n.tutorialMode,
            selected: mode == TrainingMode.tutorial,
            onTap: () => ref.read(_trainingModeProvider.notifier).state =
                TrainingMode.tutorial,
          ),
          _ModeTab(
            label: l10n.routineMode,
            selected: mode == TrainingMode.routine,
            onTap: () => ref.read(_trainingModeProvider.notifier).state =
                TrainingMode.routine,
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
            color: selected ? Theme.of(context).colorScheme.surface : null,
            borderRadius: BorderRadius.circular(8),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    )
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _MoodChartCard extends StatelessWidget {
  final AppLocalizations l10n;
  const _MoodChartCard({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.moodCheckIn,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 40),
            Center(
              child: Text(
                l10n.moodChartEmpty,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ProgramCard extends StatelessWidget {
  final AppLocalizations l10n;
  const _ProgramCard({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text('1', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
        title: const Text('Moro Reflex',
            style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${l10n.packageCurrent} · ${l10n.currentDay(1, 56)}',
          style:
              TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(Routes.packages),
      ),
    );
  }
}
