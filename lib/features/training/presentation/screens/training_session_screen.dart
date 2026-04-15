import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../../core/navigation/app_router.dart';

import '../../../chat/domain/models/chat_channel.dart';
import '../../../chat/presentation/providers/chat_providers.dart';
import '../../../../bootstrap/providers.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/settings/settings_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../mood/presentation/providers/mood_provider.dart';
import '../../../mood/presentation/widgets/mood_checkin_sheet.dart';
import '../../../progress/presentation/providers/progress_provider.dart';
import '../providers/training_flow_provider.dart';
import '../widgets/disclaimer_dialog.dart';
import '../widgets/exercise_movement_widget.dart';
import '../widgets/exercise_position_widget.dart';
import '../widgets/exercise_preparation_widget.dart';
import '../widgets/exercise_rest_widget.dart';
import '../widgets/exercise_video_widget.dart';
import '../widgets/training_intro_widget.dart';
import '../widgets/training_outro_widget.dart';

class TrainingSessionScreen extends ConsumerStatefulWidget {
  final String packageId;

  const TrainingSessionScreen({super.key, this.packageId = 'moro'});

  @override
  ConsumerState<TrainingSessionScreen> createState() =>
      _TrainingSessionScreenState();
}

class _TrainingSessionScreenState extends ConsumerState<TrainingSessionScreen> {
  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  Future<void> _handleOutroContinue(TrainingFlowState state) async {
    // Save session + update progress in background.
    //
    // IMPORTANT: Do NOT use activeEnrollmentProvider here — it is keyed to
    // selectedPackageIdProvider, which may differ from widget.packageId if the
    // user has multiple packages. Query the DB directly for this package.
    final db = ref.read(databaseProvider);
    final syncService = ref.read(syncServiceProvider);
    final userId = ref.read(authStateProvider).valueOrNull?.session?.user.id ??
        Supabase.instance.client.auth.currentUser?.id;

    EnrollmentsTableData? enrollment;
    ProgressEntriesTableData? progress;

    if (userId != null) {
      final rows = await (db.select(db.enrollmentsTable)
            ..where((t) => t.userId.equals(userId))
            ..where((t) => t.packageId.equals(widget.packageId))
            ..where((t) => t.status.equals('active'))
            ..limit(1))
          .get();
      enrollment = rows.firstOrNull;
      if (enrollment != null) {
        progress = await (db.select(db.progressEntriesTable)
              ..where((t) => t.enrollmentId.equals(enrollment!.id))
              ..limit(1))
            .getSingleOrNull();
      }
    }

    if (enrollment != null && progress != null) {
      await saveCompletedSession(
        db: db,
        syncService: syncService,
        enrollment: enrollment,
        progress: progress,
        completedExerciseIds: state.completedExerciseIds,
      );
    }

    // Suppress today's training reminder since the session is done.
    final settings = ref.read(settingsProvider);
    if (settings.remindersEnabled) {
      final isDE = settings.languageCode == 'de';
      await NotificationService.instance.suppressTodayAndReschedule(
        startMinutes: settings.reminderStartMinutes,
        titleDe:
            isDE ? 'Zeit für dein Training 🧘' : 'Time for your training 🧘',
        bodyDe: isDE
            ? 'Mach dein tägliches Reflexintegrations-Training.'
            : 'Complete your daily reflex integration training.',
      );
    }

    if (!mounted) return;

    // One coupled mood + note check-in after training.
    if (enrollment != null) {
      await showMoodCheckinSheet(
        context,
        enrollmentId: enrollment.id,
        onSaved: () {
          ref.invalidate(moodDailyAggregatesProvider);
          ref.invalidate(moodNotesProvider);
        },
      );
    }

    if (!mounted) return;

    // Offer to share experience in the package community chat
    await _showShareWithCommunityPrompt(widget.packageId);

    if (!mounted) return;
    context.pop();
  }

  Future<void> _showShareWithCommunityPrompt(String packageId) async {
    // Use cached channels instead of extra DB round-trip
    final channels = ref.read(chatChannelsProvider).valueOrNull ?? [];
    final communityChannel = channels
        .where(
            (c) => c.type == ChannelType.community && c.packageId == packageId)
        .firstOrNull;

    if (communityChannel == null || !mounted) return;
    final channelId = communityChannel.id;

    final share = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Erfahrung teilen?'),
        content: const Text(
          'Teile dein heutiges Training mit der Community.\n'
          'Andere Teilnehmer desselben Pakets freuen sich über deinen Bericht.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Nein danke'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Teilen'),
          ),
        ],
      ),
    );

    if (share == true && mounted) {
      context.push(
        Routes.chatChannel.replaceFirst(':channelId', channelId),
      );
    }
  }

  Future<bool> _onWillPop() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.cancel),
        content: const Text(
            'Dein Training wird nicht gespeichert. Wirklich abbrechen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.back),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final pkg = widget.packageId;
    final flowState = ref.watch(trainingFlowProvider(pkg));

    // Show disclaimer as dialog overlay
    if (flowState.showDisclaimer) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => DisclaimerDialog(
            onAccept: () {
              Navigator.of(context).pop();
              ref.read(trainingFlowProvider(pkg).notifier).acceptDisclaimer();
            },
          ),
        );
      });
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) context.go(Routes.dashboard);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              _buildCurrentStep(flowState, pkg),
              // Close button — always visible top-right
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white60),
                  onPressed: () async {
                    final shouldLeave = await _onWillPop();
                    if (shouldLeave && mounted) context.go(Routes.dashboard);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep(TrainingFlowState state, String pkg) {
    switch (state.step) {
      case TrainingFlowStep.disclaimer:
        return const SizedBox.shrink();

      case TrainingFlowStep.intro:
        return TrainingIntroWidget(
          exercise: state.currentExercise,
          exerciseIndex: state.currentExerciseIndex,
          totalExercises: state.totalExercises,
          mode: state.mode,
          onStart: () =>
              ref.read(trainingFlowProvider(pkg).notifier).startSession(),
          onChangeMode: (m) =>
              ref.read(trainingFlowProvider(pkg).notifier).setMode(m),
        );

      case TrainingFlowStep.video:
        return ExerciseVideoWidget(
          exercise: state.currentExercise,
          onReady: () =>
              ref.read(trainingFlowProvider(pkg).notifier).videoReady(),
        );

      case TrainingFlowStep.position:
        return ExercisePositionWidget(
          exercise: state.currentExercise,
          onReady: () =>
              ref.read(trainingFlowProvider(pkg).notifier).positionReady(),
        );

      case TrainingFlowStep.preparation:
        return ExercisePreparationWidget(
          exercise: state.currentExercise,
          onReady: () =>
              ref.read(trainingFlowProvider(pkg).notifier).preparationReady(),
        );

      case TrainingFlowStep.movement:
        return ExerciseMovementWidget(
          exercise: state.currentExercise,
          exerciseIndex: state.currentExerciseIndex,
          totalExercises: state.totalExercises,
          onComplete: () =>
              ref.read(trainingFlowProvider(pkg).notifier).exerciseComplete(),
        );

      case TrainingFlowStep.rest:
        return ExerciseRestWidget(
          nextExercise: state.currentExercise,
          onContinue: () =>
              ref.read(trainingFlowProvider(pkg).notifier).restComplete(),
        );

      case TrainingFlowStep.outro:
        return TrainingOutroWidget(
          completedCount: state.completedExerciseIds.length,
          onContinue: () => _handleOutroContinue(state),
        );
    }
  }
}
