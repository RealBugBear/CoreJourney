import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../bootstrap/providers.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/settings/settings_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/time/app_clock_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../chat/presentation/widgets/direct_messages_action.dart';
import '../../../mood/presentation/providers/mood_provider.dart';
import '../../../mood/presentation/widgets/mood_chart_widget.dart';
import '../../../mood/presentation/widgets/mood_checkin_sheet.dart';
import '../../../mood/presentation/widgets/training_experience_sheet.dart';
import '../../../training/domain/services/experience_prompt_service.dart';
import '../../../consent/presentation/providers/consent_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../progress/presentation/providers/progress_provider.dart';
import '../../../trainer/presentation/providers/trainer_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _onboardingCheckDone = false;
  bool _usernameCheckDone = false;

  void _maybeRedirectOnboarding() {
    if (_onboardingCheckDone) return;

    // The first-run gates must happen as soon as the dashboard is reached.
    // They do not depend on local training data or rehydration.
    final consent = ref.read(hasConsentedProvider);
    if (consent.isLoading) return;
    // On error (e.g. table missing), treat as not consented so screen still shows.
    if (consent.hasError || consent.value != true) {
      final placeholder = ref.read(hasSeenAnalysisPlaceholderProvider);
      if (placeholder.isLoading) return;
      if (placeholder.hasError || placeholder.value != true) {
        _onboardingCheckDone = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context.go(Routes.analysisPlaceholder);
        });
        return;
      }

      _onboardingCheckDone = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.go(Routes.consent);
      });
      return;
    }

    // Gate: do not decide while server data is being loaded into local DB.
    // A returning user on a fresh device has an empty local DB until
    // rehydrate() completes. Without this guard, they would incorrectly
    // be sent to the intake assessment screen.
    //
    // Treat AsyncLoading (stream has never emitted) as "might be rehydrating" —
    // safer to wait than to proceed with a potentially empty local DB.
    // This covers the race where GoRouter builds the dashboard before the
    // app.dart authStateProvider listener has had a chance to call rehydrate().
    final rehydrationAsync = ref.read(rehydrationProvider);
    if (rehydrationAsync.isLoading || (rehydrationAsync.valueOrNull ?? false)) {
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
      return;
    }

    // Step 3: username setup — checked per-account via Supabase profiles table.
    // Profile row is created on first save/skip, so null means the user has
    // never gone through setup on this account.
    if (!_usernameCheckDone) {
      final profileAsync = ref.read(profileProvider);
      if (profileAsync.isLoading) return; // wait until profile is loaded
      _usernameCheckDone = true;
      if (profileAsync.valueOrNull == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.push(Routes.usernameSetup);
        });
      }
    }
  }

  bool _isCompletedToday(ProgressEntriesTableData? progress, DateTime now) {
    final lastActivity = progress?.lastActivityDate;
    if (lastActivity == null) return false;
    return lastActivity.year == now.year &&
        lastActivity.month == now.month &&
        lastActivity.day == now.day;
  }

  Future<void> _markTodayComplete({
    required EnrollmentsTableData? enrollment,
    required ProgressEntriesTableData? progress,
  }) async {
    if (enrollment == null || progress == null) return;

    final now = ref.read(appClockProvider).now();
    if (_isCompletedToday(progress, now)) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Training als abgeschlossen markieren'),
        content: const Text(
          'Der heutige Trainingstag wird als erledigt markiert. Du kannst danach direkt eine Stimmung und Notiz erfassen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Als abgeschlossen markieren'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final db = ref.read(databaseProvider);
      final syncService = ref.read(syncServiceProvider);

      await saveCompletedSession(
        db: db,
        syncService: syncService,
        enrollment: enrollment,
        progress: progress,
        completedExerciseIds: const [],
      );

      final settings = ref.read(settingsProvider);
      if (settings.remindersEnabled) {
        final isDE = settings.languageCode == 'de';
        await NotificationService.instance.suppressTodayAndReschedule(
          startMinutes: settings.reminderStartMinutes,
          titleDe:
              isDE ? 'Zeit fuer dein Training 🧘' : 'Time for your training 🧘',
          bodyDe: isDE
              ? 'Mach dein taegliches Reflexintegrations-Training.'
              : 'Complete your daily reflex integration training.',
        );
      }

      if (!mounted) return;

      // Show experience prompt (once per day).
      final shouldShow = await ExperiencePromptService.shouldShow();
      if (shouldShow && mounted) {
        final packageId = ref.read(selectedPackageIdProvider);
        await showTrainingExperienceSheet(
          context,
          enrollmentId: enrollment.id,
          packageId: packageId,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Der heutige Tag wurde abgeschlossen.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Der Tag konnte nicht abgeschlossen werden: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Case 1: providers already resolved before this widget built
    _maybeRedirectOnboarding();

    // Case 2: providers resolve after first build
    ref.listen<AsyncValue<bool>>(hasSeenAnalysisPlaceholderProvider, (_, next) {
      if (!next.isLoading) _maybeRedirectOnboarding();
    });
    ref.listen<AsyncValue<bool>>(hasConsentedProvider, (_, next) {
      if (!next.isLoading) _maybeRedirectOnboarding();
    });
    ref.listen<AsyncValue<EnrollmentsTableData?>>(activeEnrollmentProvider,
        (_, next) {
      if (!next.isLoading) _maybeRedirectOnboarding();
    });

    // Case 3: rehydration completes → re-run check with fresh DB data.
    // Resets _onboardingCheckDone so the check fires again after rehydrate()
    // has filled the local DB with server enrollments.
    //
    // Triggers on ANY transition to false — covers both:
    //   loading → false  (rehydration was skipped: no connectivity, userId mismatch)
    //   true   → false   (normal completion after pulling server data)
    // Using addPostFrameCallback gives Drift one async cycle to propagate the
    // freshly-written DB rows to activeEnrollmentProvider before we re-check.
    ref.listen<AsyncValue<bool>>(rehydrationProvider, (prev, next) {
      if (next.valueOrNull == false) {
        _onboardingCheckDone = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _maybeRedirectOnboarding();
        });
      }
    });

    final progress = ref.watch(activeProgressProvider).valueOrNull;
    final enrollment = ref.watch(activeEnrollmentProvider).valueOrNull;
    final now = ref.watch(appClockProvider).now();
    final completedToday = _isCompletedToday(progress, now);

    final config = ref.watch(appConfigProvider);
    final currentEmail = Supabase.instance.client.auth.currentUser?.email ?? '';
    // Dev tools: only for @corejourney.dev accounts in development builds.
    final showDevTools =
        config.isDevelopment && currentEmail.endsWith('@corejourney.dev');

    return Scaffold(
      appBar: AppBar(
        title: const _DashboardBrandTitle(),
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
          const DirectMessagesAction(),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Einstellungen',
            onPressed: () => context.push(Routes.settings),
          ),
        ],
      ),
      floatingActionButton: enrollment == null
          ? null
          : FloatingActionButton.small(
              tooltip: 'Schneller Eintrag',
              backgroundColor: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.96),
              foregroundColor: AppColors.primary,
              elevation: 2,
              onPressed: () => showMoodCheckinSheet(
                context,
                enrollmentId: enrollment.id,
                onSaved: () {
                  ref.invalidate(moodDailyAggregatesProvider);
                  ref.invalidate(moodNotesProvider);
                },
              ),
              child: const Icon(Icons.edit_note_outlined),
            ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SlimStatusBar(
                l10n: l10n,
                progress: progress,
                enrollment: enrollment,
                now: now,
              ),
              const SizedBox(height: 16),
              const _CompletionQuestionnaireBanner(),
              const SizedBox(height: 12),
              const _AppointmentProposalBanner(),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: const _MoodChartCard(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => context.push(
                  Routes.trainingSession,
                  extra: ref.read(selectedPackageIdProvider),
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 28),
                label: Text(
                  l10n.startTraining,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed:
                    enrollment == null || progress == null || completedToday
                        ? null
                        : () => _markTodayComplete(
                              enrollment: enrollment,
                              progress: progress,
                            ),
                icon: Icon(
                  completedToday
                      ? Icons.check_circle
                      : Icons.check_circle_outline,
                ),
                label: Text(
                  completedToday
                      ? 'Heute bereits abgeschlossen'
                      : 'Training als abgeschlossen markieren',
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompletionQuestionnaireBanner extends ConsumerWidget {
  const _CompletionQuestionnaireBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ready = ref.watch(completionReadyProvider);
    final enrollment = ref.watch(activeEnrollmentProvider).valueOrNull;
    if (!ready || enrollment == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    return Material(
      color: AppColors.primary.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push(
          Routes.completionQuestionnaire,
          extra: enrollment.id,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.emoji_events_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.completionBannerTitle,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.completionBannerSubtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.25,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppointmentProposalBanner extends ConsumerWidget {
  const _AppointmentProposalBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proposalsAsync = ref.watch(traineeProposalsProvider);
    final proposals = proposalsAsync.valueOrNull ?? const [];

    if (proposals.isEmpty) return const SizedBox.shrink();

    final count = proposals.length;
    final trainerName = proposals.first.traineeName;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push(Routes.appointmentProposals),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.event_available_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        count == 1
                            ? 'Neuer Terminvorschlag'
                            : '$count neue Terminvorschläge',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$trainerName hat dir Termine vorgeschlagen.',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardBrandTitle extends StatelessWidget {
  const _DashboardBrandTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'assets/images/brand/free.png',
            width: 28,
            height: 28,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 10),
        const Text('CoreJourney'),
      ],
    );
  }
}

class _SlimStatusBar extends StatelessWidget {
  final AppLocalizations l10n;
  final ProgressEntriesTableData? progress;
  final EnrollmentsTableData? enrollment;
  final DateTime now;

  const _SlimStatusBar({
    required this.l10n,
    required this.progress,
    required this.enrollment,
    required this.now,
  });

  @override
  Widget build(BuildContext context) {
    final currentDay = progress?.currentDay ?? 1;
    final totalDays =
        ((enrollment?.assignedDurationWeeks ?? 8) * 7).clamp(1, 3650);
    final streak = progress?.dailyStreak ?? 0;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _StatusPill(
          icon: Icons.calendar_today_outlined,
          title: l10n.dayNumber(currentDay),
          subtitle: l10n.currentDay(currentDay, totalDays),
        ),
        _StatusPill(
          icon: Icons.local_fire_department_outlined,
          title: '$streak',
          subtitle: l10n.dailyStreak,
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _StatusPill({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoodChartCard extends StatelessWidget {
  const _MoodChartCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableHeight =
                constraints.maxHeight.isFinite ? constraints.maxHeight : 320.0;
            final chartHeight = (availableHeight - 72).clamp(150.0, 300.0);

            return SizedBox.expand(
              child: MoodChartWidget(
                compactHeader: true,
                showNotesList: false,
                showLegend: false,
                chartHeight: chartHeight,
              ),
            );
          },
        ),
      ),
    );
  }
}
