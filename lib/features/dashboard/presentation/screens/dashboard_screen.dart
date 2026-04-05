import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../bootstrap/providers.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/time/app_clock_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../journal/presentation/providers/journal_provider.dart';
import '../../../mood/presentation/providers/mood_provider.dart';
import '../../../mood/presentation/widgets/mood_chart_widget.dart';
import '../../../mood/presentation/widgets/mood_checkin_sheet.dart';
import '../../../consent/presentation/providers/consent_provider.dart';
import '../../../progress/presentation/providers/progress_provider.dart';
import '../../../trainer/presentation/providers/trainer_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _onboardingCheckDone = false;

  void _maybeRedirectOnboarding() {
    if (_onboardingCheckDone) return;

    // Step 1: consent must come first
    final consent = ref.read(hasConsentedProvider);
    if (consent.isLoading) return;
    // On error (e.g. table missing), treat as not consented so screen still shows.
    if (consent.hasError || consent.value != true) {
      _onboardingCheckDone = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.go(Routes.consent);
      });
      return;
    }

    // Step 2: intake assessment if no active enrollment
    final enrollment = ref.read(activeEnrollmentProvider);
    if (enrollment.isLoading) return;
    _onboardingCheckDone = true;
    if (enrollment.value == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final packageId = ref.read(selectedPackageIdProvider);
        context.go(Routes.intakeAssessment, extra: packageId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Case 1: providers already resolved before this widget built
    _maybeRedirectOnboarding();

    // Case 2: providers resolve after first build
    ref.listen<AsyncValue<bool>>(hasConsentedProvider, (_, next) {
      if (!next.isLoading) _maybeRedirectOnboarding();
    });
    ref.listen<AsyncValue<EnrollmentsTableData?>>(activeEnrollmentProvider,
        (_, next) {
      if (!next.isLoading) _maybeRedirectOnboarding();
    });

    final progress = ref.watch(activeProgressProvider).valueOrNull;
    final enrollment = ref.watch(activeEnrollmentProvider).valueOrNull;
    final weekSessions = ref.watch(thisWeekSessionsProvider).valueOrNull ?? [];
    final completionReady = ref.watch(completionReadyProvider);
    final now = ref.watch(appClockProvider).now();

    final config = ref.watch(appConfigProvider);
    final currentEmail = Supabase.instance.client.auth.currentUser?.email ?? '';
    // Dev tools: only for @corejourney.dev accounts in development builds.
    final showDevTools = config.isDevelopment &&
        currentEmail.endsWith('@corejourney.dev');

    return Scaffold(
      appBar: AppBar(
        title: const Text('CoreJourney'),
        actions: [
          if (showDevTools)
            TextButton(
              onPressed: () => context.push(Routes.devTools),
              child: const Text(
                'DEV',
                style: TextStyle(
                  color: Colors.deepOrange,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push(Routes.profile),
          ),
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
              // Appointment proposal banner — shown when trainer sent slot options
              const _ProposalBanner(),

              // Completion banner — shown when target date reached
              if (completionReady && enrollment != null) ...[
                _CompletionBanner(
                  enrollment: enrollment,
                  onTap: () => context.push(
                    Routes.completionQuestionnaire,
                    extra: enrollment.id,
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // KPI Grid
              _KpiGrid(
                  l10n: l10n,
                  progress: progress,
                  enrollment: enrollment,
                  weekSessions: weekSessions,
                  now: now),
              const SizedBox(height: 20),

              // Weekly calendar strip
              _WeeklyCalendarStrip(weekSessions: weekSessions, now: now),
              const SizedBox(height: 20),

              // Mode selector
              _ModeSelector(l10n: l10n),
              const SizedBox(height: 20),

              // Start Training CTA
              ElevatedButton.icon(
                onPressed: () => context.push(
                  Routes.trainingSession,
                  extra: ref.read(selectedPackageIdProvider),
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 28),
                label: Text(
                  l10n.startTraining,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),

              // Mood chart
              _MoodChartCard(l10n: l10n),
              const SizedBox(height: 20),

              // Journal card
              _JournalCard(enrollment: enrollment),
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
  final ProgressEntriesTableData? progress;
  final EnrollmentsTableData? enrollment;
  final List<TrainingSessionsTableData> weekSessions;
  final DateTime now;

  const _KpiGrid({
    required this.l10n,
    required this.progress,
    required this.enrollment,
    required this.weekSessions,
    required this.now,
  });

  @override
  Widget build(BuildContext context) {
    final currentDay = progress?.currentDay ?? 1;
    final totalDays = (enrollment?.assignedDurationWeeks ?? 8) * 7;
    final streak = progress?.dailyStreak ?? 0;
    final weekCount = progress?.trainingsThisWeek ?? 0;
    final weekGoal = progress?.weeklyGoal ?? 5;

    // Days remaining to golden day (target completion)
    int daysToGolden = 0;
    if (enrollment != null) {
      final today = DateTime(now.year, now.month, now.day);
      daysToGolden = enrollment!.targetCompletionDate.difference(today).inDays;
      if (daysToGolden < 0) daysToGolden = 0;
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _KpiCard(
          label: l10n.currentDay(currentDay, totalDays),
          value: l10n.dayNumber(currentDay),
          icon: Icons.calendar_today_outlined,
        ),
        _KpiCard(
          label: l10n.dailyStreak,
          value: '$streak 🔥',
          icon: Icons.local_fire_department_outlined,
        ),
        _KpiCard(
          label: l10n.thisWeek,
          value: '$weekCount / $weekGoal',
          icon: Icons.check_circle_outline,
        ),
        _KpiCard(
          label: l10n.goldenDay,
          value: '$daysToGolden Tage',
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(height: 6),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyCalendarStrip extends StatelessWidget {
  final List<TrainingSessionsTableData> weekSessions;
  final DateTime now;

  const _WeeklyCalendarStrip({required this.weekSessions, required this.now});

  @override
  Widget build(BuildContext context) {
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));

    // Build set of completed day offsets this week
    final completedDays = <int>{};
    for (final s in weekSessions) {
      final d =
          DateTime(s.sessionDate.year, s.sessionDate.month, s.sessionDate.day);
      final offset = d.difference(weekStart).inDays;
      if (offset >= 0 && offset < 7) completedDays.add(offset);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final day = weekStart.add(Duration(days: i));
        final isToday = day == today;
        final isPast = day.isBefore(today);

        return _DayDot(
          dayLetter: _dayLetter(day.weekday),
          dayNumber: day.day,
          isToday: isToday,
          isCompleted: completedDays.contains(i),
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
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: MoodChartWidget(),
      ),
    );
  }
}

class _CompletionBanner extends StatelessWidget {
  final EnrollmentsTableData enrollment;
  final VoidCallback onTap;
  const _CompletionBanner({required this.enrollment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.85),
              AppColors.primary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Text('⭐', style: TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).completionBannerTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context).completionBannerSubtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}

class _JournalCard extends ConsumerWidget {
  final EnrollmentsTableData? enrollment;
  const _JournalCard({required this.enrollment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latestEntry = ref.watch(journalProvider).entries.firstOrNull;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push(Routes.journal),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('📓', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context).journal,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.add, size: 20),
                    color: AppColors.primary,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => showMoodCheckinSheet(
                      context,
                      enrollmentId: enrollment?.id,
                      onSaved: () {
                        ref.read(journalProvider.notifier).load();
                        ref.invalidate(moodDailyAggregatesProvider);
                        ref.invalidate(moodNotesProvider);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => context.push(Routes.journal),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  child: const Text('Tagebuch →'),
                ),
              ),
              if (latestEntry != null) ...[
                const SizedBox(height: 4),
                Text(
                  latestEntry.note ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                ),
              ] else ...[
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context).journalEmptyHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

const _packageNames = {
  'moro': 'Moro Reflex',
  'spinal_galant': 'Spinaler Galant + Amphibien',
  'tlr': 'Tonischer Labirint Reflex (TLR)',
  'babkin': 'Babkin + Plantar + Greifen',
  'such_saug': 'Such-Saug Reflex',
  'atnr': 'ATNR',
  'stnr': 'STNR',
  'babinski': 'Babinski Reflex',
  'landau': 'Landau Reflex',
};

const _packageSequence = [
  'moro',
  'spinal_galant',
  'tlr',
  'babkin',
  'such_saug',
  'atnr',
  'stnr',
  'babinski',
  'landau',
];

class _ProgramCard extends ConsumerWidget {
  final AppLocalizations l10n;
  const _ProgramCard({required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(selectedPackageIdProvider);
    final enrollment = ref.watch(activeEnrollmentProvider).valueOrNull;
    final progress = ref.watch(activeProgressProvider).valueOrNull;

    final packageName = _packageNames[selectedId] ?? selectedId;
    final seqNumber = (_packageSequence.indexOf(selectedId) + 1).toString();
    final currentDay = progress?.currentDay ?? 1;
    final totalDays = (enrollment?.assignedDurationWeeks ?? 8) * 7;

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
          child: Center(
            child: Text(seqNumber,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
        title: Text(packageName,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          enrollment != null
              ? '${l10n.packageCurrent} · ${l10n.currentDay(currentDay, totalDays)}'
              : l10n.packageLocked,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(Routes.packages),
      ),
    );
  }
}

// ── Appointment Proposal Banner ───────────────────────────────────────────────

class _ProposalBanner extends ConsumerWidget {
  const _ProposalBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleAsync = ref.watch(userRoleProvider);
    if (roleAsync.valueOrNull == 'trainer') return const SizedBox.shrink();

    final proposalsAsync = ref.watch(traineeProposalsProvider);
    final count = proposalsAsync.valueOrNull?.length ?? 0;
    if (count == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () => context.push(Routes.appointmentProposals),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.calendar_today_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$count Terminvorschlag${count > 1 ? "schläge" : ""} erhalten',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    const Text(
                      'Dein Trainer wartet auf deine Auswahl',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
