import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/training/handsfree_setup_settings.dart';
import '../../../../core/mood/mood_view_settings.dart';
import '../../../../core/training/training_feedback_settings.dart';
import '../../../../core/training/training_launch_settings.dart';
import '../../../../core/training/tutorial_flow_settings.dart';
import '../../../../core/analytics/analytics_provider.dart';
import '../../../mood/data/repositories/mood_repository.dart';
import '../../../mood/domain/models/mood_checkin.dart';
import '../../../mood/presentation/providers/mood_provider.dart';
import '../../../progress/presentation/providers/progress_provider.dart';
import '../../../progress/domain/services/progress_service.dart';
import '../../../training/presentation/screens/training_flow_screen.dart';
import '../../../training/presentation/providers/training_flow_provider.dart';
import '../../../training/presentation/widgets/training_disclaimer_dialog.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../progress/domain/models/golden_day_status.dart';
import '../../../../core/navigation/route_observer.dart';

const Color _moodSeriesColor = Color(0xFF5A9B84);
const Color _energySeriesColor = Color(0xFF6E8FCB);
const Color _stressSeriesColor = Color(0xFFC47A93);
const Color _noteSeriesColor = Color(0xFFE0B867);

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with RouteAware, WidgetsBindingObserver {
  late Future<_DashboardData?> _dashboardFuture;
  TrainingMode _selectedTrainingMode = TrainingMode.routine;
  MoodViewScope _moodScope = MoodViewScope.package;
  MoodViewRangePreset _moodRangePreset = MoodViewRangePreset.days30;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _dashboardFuture = _loadDashboardData();
    // Initialize progress on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProgressIfNeeded();
      _maybeScheduleReminders();
      _loadTrainingModePreference();
      _loadMoodViewPreference();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      coreJourneyRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    coreJourneyRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // When coming back to the dashboard (e.g. from profile/admin tools),
    // refresh cached future so visual progress reflects new training sessions.
    if (!mounted) return;
    setState(() {
      _dashboardFuture = _loadDashboardData();
    });
    _loadMoodViewPreference();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;
    setState(() {
      _dashboardFuture = _loadDashboardData();
    });
    _maybeScheduleReminders();
    _loadMoodViewPreference();
  }

  Future<_DashboardData?> _loadDashboardData() async {
    final progressService = ref.read(progressServiceProvider);
    final moodRepository = ref.read(moodRepositoryProvider);
    final progress = await progressService.getCurrentProgress();
    if (progress == null) return null;

    final goldenDayStatus = await progressService.computeGoldenDayStatus();
    final snapshot = await progressService.buildDashboardSnapshot();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start =
        DateTime(progress.date.year, progress.date.month, progress.date.day);
    final to = today.add(const Duration(days: 1));
    final packageMoodAll = await moodRepository.getDailyAggregatesInRange(
      fromInclusive: start,
      toExclusive: to,
      packageId: 'core',
    );
    final overallMoodAll = await moodRepository.getDailyAggregatesInRange(
      fromInclusive: start,
      toExclusive: to,
    );
    final packageNotesAll = await moodRepository.getNotesInRange(
      fromInclusive: start,
      toExclusive: to,
      packageId: 'core',
    );
    final overallNotesAll = await moodRepository.getNotesInRange(
      fromInclusive: start,
      toExclusive: to,
    );

    return _DashboardData(
      goldenDayStatus: goldenDayStatus,
      snapshot: snapshot,
      packageMoodAll: packageMoodAll,
      overallMoodAll: overallMoodAll,
      packageNotesAll: packageNotesAll,
      overallNotesAll: overallNotesAll,
    );
  }

  Future<void> _initializeProgressIfNeeded() async {
    final progressService = ref.read(progressServiceProvider);
    final progress = await progressService.getCurrentProgress();

    if (progress == null) {
      // Initialize progress for new user
      await progressService.initializeProgress();
      if (!mounted) return;
      setState(() {
        _dashboardFuture = _loadDashboardData();
      });
    }
  }

  Future<void> _maybeScheduleReminders() async {
    if (!mounted) return;
    await ref.read(progressServiceProvider).syncReminderSchedule();
  }

  Future<void> _loadTrainingModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDirectStart =
        TrainingLaunchSettings.directStartEnabledOrNull(prefs);
    if (!mounted) return;
    setState(() {
      _selectedTrainingMode = savedDirectStart == false
          ? TrainingMode.tutorial
          : TrainingMode.routine;
    });
  }

  Future<void> _loadMoodViewPreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _moodScope = MoodViewSettings.scope(prefs);
      _moodRangePreset = MoodViewSettings.range(prefs);
    });
  }

  Future<void> _setTrainingMode(TrainingMode mode) async {
    setState(() {
      _selectedTrainingMode = mode;
    });
    final prefs = await SharedPreferences.getInstance();
    await TrainingLaunchSettings.setDirectStartEnabled(
      prefs,
      mode == TrainingMode.routine,
    );
  }

  Future<void> _handleStartTraining(BuildContext context) async {
    final progressService = ref.read(progressServiceProvider);
    final currentProgress = await progressService.getCurrentProgress();

    if (currentProgress == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fehler beim Laden des Fortschritts'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final shouldShowDisclaimer =
        progressService.shouldShowDisclaimer(currentProgress);

    if (shouldShowDisclaimer) {
      if (!context.mounted) return;
      final accepted = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => TrainingDisclaimerDialog(
          onAccept: () => Navigator.of(context).pop(true),
          onDecline: () => Navigator.of(context).pop(false),
        ),
      );

      if (accepted != true || !context.mounted) {
        return;
      }

      await progressService.recordDisclaimerAcceptance(currentProgress);
    }

    if (!context.mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final setupReady = await _ensureHandsfreeSetup(context, prefs);
    if (!setupReady || !context.mounted) return;
    final compactTutorial = TutorialFlowSettings.compactEnabled(prefs);
    await ref.read(analyticsServiceProvider).logEvent(
      name: 'training_start_tap',
      parameters: {
        'mode': _selectedTrainingMode.name,
        'compact_tutorial': compactTutorial,
        'handsfree_setup_completed': HandsfreeSetupSettings.isCompleted(prefs),
      },
    );

    ref.read(trainingFlowProvider.notifier).startTraining(
          mode: _selectedTrainingMode,
          compactTutorial: compactTutorial,
        );

    final completed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const TrainingFlowScreen(),
      ),
    );

    if (!context.mounted) return;

    if (completed == true) {
      final updatedProgress = await progressService.getCurrentProgress();
      if (updatedProgress != null) {
        await progressService.incrementDisclaimerCounter(updatedProgress);
      }

      if (!context.mounted) return;
      setState(() {
        _dashboardFuture = _loadDashboardData();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Training erfolgreich abgeschlossen!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _handleQuickCompleteToday(BuildContext context) async {
    final progressService = ref.read(progressServiceProvider);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte erneut anmelden.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final alreadyCompleted = await progressService.hasCompletedTrainingToday();
    if (alreadyCompleted) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Heute ist bereits abgehakt.')),
      );
      return;
    }

    await progressService.recordTrainingSession(user.uid);
    final updatedProgress = await progressService.getCurrentProgress();
    if (updatedProgress != null) {
      await progressService.incrementDisclaimerCounter(updatedProgress);
    }

    if (!mounted || !context.mounted) return;
    setState(() {
      _dashboardFuture = _loadDashboardData();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Heute als erledigt markiert.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<bool> _ensureHandsfreeSetup(
    BuildContext context,
    SharedPreferences prefs,
  ) async {
    if (HandsfreeSetupSettings.isCompleted(prefs)) return true;

    final result = await _showHandsfreeSetupSheet(context);
    if (result == null) return false;

    await TrainingLaunchSettings.setDirectStartEnabled(
      prefs,
      result.mode == TrainingMode.routine,
    );
    await TrainingFeedbackSettings.setFeedbackMode(prefs, result.feedbackMode);
    await HandsfreeSetupSettings.setDefaultTempoSeconds(
      prefs,
      result.defaultTempoSeconds,
    );
    await HandsfreeSetupSettings.setCompleted(prefs, true);

    if (!mounted) return false;
    setState(() {
      _selectedTrainingMode = result.mode;
    });
    return true;
  }

  Future<_HandsfreeSetupResult?> _showHandsfreeSetupSheet(
    BuildContext context,
  ) {
    var mode = _selectedTrainingMode;
    var feedbackMode = TrainingFeedbackMode.voiceAndCues;
    var tempoSeconds = 2.5;

    return showModalBottomSheet<_HandsfreeSetupResult>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Einmaliges Hands-free Setup',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Diese Einstellungen kannst du später jederzeit ändern.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    SegmentedButton<TrainingMode>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: TrainingMode.routine,
                          icon: Icon(Icons.bolt_outlined),
                          label: Text('Direkt starten'),
                        ),
                        ButtonSegment(
                          value: TrainingMode.tutorial,
                          icon: Icon(Icons.school_outlined),
                          label: Text('Tutorial'),
                        ),
                      ],
                      selected: {mode},
                      onSelectionChanged: (selection) {
                        setModalState(() => mode = selection.first);
                      },
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<TrainingFeedbackMode>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: TrainingFeedbackMode.voiceAndCues,
                          label: Text('Stimme'),
                        ),
                        ButtonSegment(
                          value: TrainingFeedbackMode.hapticOnly,
                          label: Text('Haptik'),
                        ),
                        ButtonSegment(
                          value: TrainingFeedbackMode.silent,
                          label: Text('Stumm'),
                        ),
                      ],
                      selected: {feedbackMode},
                      onSelectionChanged: (selection) {
                        setModalState(() => feedbackMode = selection.first);
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Starttempo: ${tempoSeconds.toStringAsFixed(tempoSeconds.truncateToDouble() == tempoSeconds ? 0 : 1)}s',
                    ),
                    Slider(
                      min: 1.0,
                      max: 5.0,
                      divisions: 8,
                      value: tempoSeconds,
                      onChanged: (v) {
                        setModalState(() => tempoSeconds = v);
                      },
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(context).pop(
                            _HandsfreeSetupResult(
                              mode: mode,
                              feedbackMode: feedbackMode,
                              defaultTempoSeconds: tempoSeconds,
                            ),
                          );
                        },
                        child: const Text('Setup speichern und starten'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      body: FutureBuilder(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text('Lade Fortschritt...'),
            );
          }

          final data = snapshot.data as _DashboardData;
          final goldenDayStatus = data.goldenDayStatus;
          final progressSnapshot = data.snapshot;

          final hasReachedGoldenDay =
              goldenDayStatus?.hasReachedGoldenDay ?? false;
          final scopedMood = _moodScope == MoodViewScope.package
              ? data.packageMoodAll
              : data.overallMoodAll;
          final mood = _dataForPreset(scopedMood, _moodRangePreset);
          final scopedNotes = _moodScope == MoodViewScope.package
              ? data.packageNotesAll
              : data.overallNotesAll;
          final notes = _notesForPreset(scopedNotes, _moodRangePreset);

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: _MinimalProgressCard(
                        snapshot: progressSnapshot,
                        reachedGoldenDay: hasReachedGoldenDay,
                        goldenDayStatus: goldenDayStatus,
                        moodScope: _moodScope,
                        moodRangePreset: _moodRangePreset,
                        moodData: mood,
                        notes: notes,
                        onAddNote: _handleAddManualNote,
                        onViewNotes: () => _showNotesSheet(scopedNotes),
                        onProfileTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const ProfileScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<TrainingMode>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: TrainingMode.routine,
                        icon: Icon(Icons.bolt_outlined),
                        label: Text('Direkt starten'),
                      ),
                      ButtonSegment(
                        value: TrainingMode.tutorial,
                        icon: Icon(Icons.school_outlined),
                        label: Text('Tutorial'),
                      ),
                    ],
                    selected: {_selectedTrainingMode},
                    onSelectionChanged: (selection) {
                      _setTrainingMode(selection.first);
                    },
                  ),
                  const SizedBox(height: 10),
                  _PrimaryActionButton(
                    label: hasReachedGoldenDay
                        ? 'Training erneut starten'
                        : 'Training starten',
                    onPressed: () => _handleStartTraining(context),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.tonalIcon(
                      onPressed: progressSnapshot.todayCompleted
                          ? null
                          : () => _handleQuickCompleteToday(context),
                      icon: Icon(
                        progressSnapshot.todayCompleted
                            ? Icons.check_circle
                            : Icons.check_circle_outline,
                      ),
                      label: Text(
                        progressSnapshot.todayCompleted
                            ? 'Heute bereits erledigt'
                            : 'Übung für heute abhaken',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<MoodDailyAggregate> _dataForPreset(
    List<MoodDailyAggregate> values,
    MoodViewRangePreset preset,
  ) {
    final sorted = [...values]..sort((a, b) => a.day.compareTo(b.day));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime start;

    switch (preset) {
      case MoodViewRangePreset.days30:
        start = today.subtract(const Duration(days: 29));
        break;
      case MoodViewRangePreset.days90:
        start = today.subtract(const Duration(days: 89));
        break;
      case MoodViewRangePreset.year1:
        start = today.subtract(const Duration(days: 364));
        break;
      case MoodViewRangePreset.all:
        if (sorted.isEmpty) return sorted;
        final first = sorted.first.day;
        start = DateTime(first.year, first.month, first.day);
        break;
    }
    final filtered = sorted.where((v) => !v.day.isBefore(start)).toList();
    return _expandToDaily(
      filtered,
      fromInclusive: start,
      toInclusive: today,
    );
  }

  List<MoodDailyAggregate> _expandToDaily(
    List<MoodDailyAggregate> values, {
    required DateTime fromInclusive,
    required DateTime toInclusive,
  }) {
    if (toInclusive.isBefore(fromInclusive)) return const [];
    final byDay = <int, MoodDailyAggregate>{
      for (final item in values) item.day.millisecondsSinceEpoch: item,
    };
    final result = <MoodDailyAggregate>[];
    var cursor = DateTime(
      fromInclusive.year,
      fromInclusive.month,
      fromInclusive.day,
    );
    final end = DateTime(
      toInclusive.year,
      toInclusive.month,
      toInclusive.day,
    );
    while (!cursor.isAfter(end)) {
      final key = cursor.millisecondsSinceEpoch;
      final existing = byDay[key];
      result.add(
        existing ??
            MoodDailyAggregate(
              day: cursor,
              avgMood: null,
              minMood: null,
              maxMood: null,
              avgEnergy: null,
              minEnergy: null,
              maxEnergy: null,
              avgStress: null,
              minStress: null,
              maxStress: null,
              entriesCount: 0,
              noteCount: 0,
            ),
      );
      cursor = cursor.add(const Duration(days: 1));
    }
    return result;
  }

  List<MoodCheckin> _notesForPreset(
    List<MoodCheckin> values,
    MoodViewRangePreset preset,
  ) {
    if (values.isEmpty) return values;
    final sorted = [...values]
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    DateTime? threshold;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (preset) {
      case MoodViewRangePreset.days30:
        threshold = today.subtract(const Duration(days: 29));
        break;
      case MoodViewRangePreset.days90:
        threshold = today.subtract(const Duration(days: 89));
        break;
      case MoodViewRangePreset.year1:
        threshold = today.subtract(const Duration(days: 364));
        break;
      case MoodViewRangePreset.all:
        threshold = null;
        break;
    }
    if (threshold == null) return sorted;
    return sorted
        .where((n) => !n.recordedAt.isBefore(threshold!))
        .toList(growable: false);
  }

  Future<void> _handleAddManualNote() async {
    var mood = 3;
    var energy = 3;
    var stress = 3;
    final noteController = TextEditingController();
    final result = await showModalBottomSheet<_ManualNoteInput>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Widget scaleHint({
              required String lowLabel,
              required String highLabel,
            }) {
              return Row(
                children: [
                  Text(
                    '1 = $lowLabel',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const Spacer(),
                  Text(
                    '5 = $highLabel',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              );
            }

            return SafeArea(
              child: GestureDetector(
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                child: AnimatedPadding(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOut,
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notiz hinzufügen',
                            style: Theme.of(sheetContext).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Werte (Pflicht)',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Stimmung',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          const SizedBox(height: 4),
                          SegmentedButton<int>(
                            showSelectedIcon: false,
                            segments: const [
                              ButtonSegment(value: 1, label: Text('1')),
                              ButtonSegment(value: 2, label: Text('2')),
                              ButtonSegment(value: 3, label: Text('3')),
                              ButtonSegment(value: 4, label: Text('4')),
                              ButtonSegment(value: 5, label: Text('5')),
                            ],
                            selected: {mood},
                            onSelectionChanged: (selection) {
                              setModalState(() => mood = selection.first);
                            },
                          ),
                          scaleHint(lowLabel: 'schlecht', highLabel: 'gut'),
                          const SizedBox(height: 6),
                          Text(
                            'Energie',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          const SizedBox(height: 4),
                          SegmentedButton<int>(
                            showSelectedIcon: false,
                            segments: const [
                              ButtonSegment(value: 1, label: Text('1')),
                              ButtonSegment(value: 2, label: Text('2')),
                              ButtonSegment(value: 3, label: Text('3')),
                              ButtonSegment(value: 4, label: Text('4')),
                              ButtonSegment(value: 5, label: Text('5')),
                            ],
                            selected: {energy},
                            onSelectionChanged: (selection) {
                              setModalState(() => energy = selection.first);
                            },
                          ),
                          scaleHint(lowLabel: 'schwach', highLabel: 'hoch'),
                          const SizedBox(height: 6),
                          Text(
                            'Stress',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          const SizedBox(height: 4),
                          SegmentedButton<int>(
                            showSelectedIcon: false,
                            segments: const [
                              ButtonSegment(value: 1, label: Text('1')),
                              ButtonSegment(value: 2, label: Text('2')),
                              ButtonSegment(value: 3, label: Text('3')),
                              ButtonSegment(value: 4, label: Text('4')),
                              ButtonSegment(value: 5, label: Text('5')),
                            ],
                            selected: {stress},
                            onSelectionChanged: (selection) {
                              setModalState(() => stress = selection.first);
                            },
                          ),
                          scaleHint(lowLabel: 'viel', highLabel: 'wenig'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: noteController,
                            minLines: 2,
                            maxLines: 10,
                            textInputAction: TextInputAction.newline,
                            onTapOutside: (_) =>
                                FocusManager.instance.primaryFocus?.unfocus(),
                            decoration: const InputDecoration(
                              hintText: 'Wie fühlst du dich heute?',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              TextButton(
                                onPressed: () {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  Navigator.of(sheetContext).pop();
                                },
                                child: const Text('Abbrechen'),
                              ),
                              const Spacer(),
                              FilledButton(
                                onPressed: () {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  Navigator.of(sheetContext).pop(
                                    _ManualNoteInput(
                                      mood: mood,
                                      energy: energy,
                                      stress: stress,
                                      note: noteController.text,
                                    ),
                                  );
                                },
                                child: const Text('Speichern'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(noteController.dispose);

    if (result == null) return;
    final note = result.note.trim();
    if (note.isEmpty) return;

    await ref.read(moodRepositoryProvider).createCheckin(
          packageId: 'core',
          source: MoodCheckinSource.manualNote,
          mood: result.mood,
          energy: result.energy,
          stress: result.stress,
          note: note,
        );
    if (!mounted) return;
    setState(() {
      _dashboardFuture = _loadDashboardData();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notiz gespeichert')),
    );
  }

  Future<void> _showNotesSheet(List<MoodCheckin> notes) async {
    final sorted = [...notes]
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              height: MediaQuery.of(sheetContext).size.height * 0.72,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Deine Notizen',
                    style: Theme.of(sheetContext).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sorted.isEmpty
                        ? 'Noch keine Notizen vorhanden'
                        : '${sorted.length} Notizen',
                    style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                          color: Theme.of(sheetContext)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.64),
                        ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: sorted.isEmpty
                        ? Center(
                            child: Text(
                              'Füge über "Notiz +" eine Notiz hinzu.',
                              style: Theme.of(sheetContext)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(sheetContext)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.6),
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.separated(
                            itemCount: sorted.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final note = sorted[index];
                              return _NoteListTile(note: note);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HandsfreeSetupResult {
  final TrainingMode mode;
  final TrainingFeedbackMode feedbackMode;
  final double defaultTempoSeconds;

  const _HandsfreeSetupResult({
    required this.mode,
    required this.feedbackMode,
    required this.defaultTempoSeconds,
  });
}

class _ManualNoteInput {
  final int mood;
  final int energy;
  final int stress;
  final String note;

  const _ManualNoteInput({
    required this.mood,
    required this.energy,
    required this.stress,
    required this.note,
  });
}

class _NoteListTile extends StatelessWidget {
  final MoodCheckin note;

  const _NoteListTile({required this.note});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = note.recordedAt;
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final stamp = '$day.$month.$year • $hour:$minute';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  stamp,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.62),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (note.mood != null)
                _NoteMetricChip(
                  label: 'Stimmung',
                  value: note.mood!,
                  color: _moodSeriesColor,
                ),
              if (note.energy != null)
                _NoteMetricChip(
                  label: 'Energie',
                  value: note.energy!,
                  color: _energySeriesColor,
                ),
              if (note.stress != null)
                _NoteMetricChip(
                  label: 'Stress',
                  value: note.stress!,
                  color: _stressSeriesColor,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            note.note ?? '',
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteMetricChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _NoteMetricChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label $value/5',
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DashboardData {
  final GoldenDayStatus? goldenDayStatus;
  final DashboardProgressSnapshot snapshot;
  final List<MoodDailyAggregate> packageMoodAll;
  final List<MoodDailyAggregate> overallMoodAll;
  final List<MoodCheckin> packageNotesAll;
  final List<MoodCheckin> overallNotesAll;

  const _DashboardData({
    required this.goldenDayStatus,
    required this.snapshot,
    required this.packageMoodAll,
    required this.overallMoodAll,
    required this.packageNotesAll,
    required this.overallNotesAll,
  });
}

class _MinimalProgressCard extends StatelessWidget {
  final DashboardProgressSnapshot snapshot;
  final bool reachedGoldenDay;
  final GoldenDayStatus? goldenDayStatus;
  final MoodViewScope moodScope;
  final MoodViewRangePreset moodRangePreset;
  final List<MoodDailyAggregate> moodData;
  final List<MoodCheckin> notes;
  final VoidCallback onAddNote;
  final VoidCallback onViewNotes;
  final VoidCallback onProfileTap;

  const _MinimalProgressCard({
    required this.snapshot,
    required this.reachedGoldenDay,
    required this.goldenDayStatus,
    required this.moodScope,
    required this.moodRangePreset,
    required this.moodData,
    required this.notes,
    required this.onAddNote,
    required this.onViewNotes,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const weekDisplayMax = 7;
    final weekDone = snapshot.completedThisWeek.clamp(0, weekDisplayMax);
    final progress = (weekDone / weekDisplayMax).clamp(0.0, 1.0);
    final qualifiedWeeks = (goldenDayStatus?.qualifiedWeeks ?? 0).clamp(0, 4);
    final todayLabel =
        snapshot.todayCompleted ? 'Heute erledigt' : 'Heute offen';

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.of(context).size.height;
        final chartHeight = (availableHeight * 0.27).clamp(124.0, 188.0);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.colorScheme.onSurface.withOpacity(0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: theme.colorScheme.primary.withOpacity(0.10),
                    ),
                    child: Text(
                      todayLabel,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: onProfileTap,
                    tooltip: 'Profil',
                    icon: CircleAvatar(
                      radius: 16,
                      backgroundColor:
                          theme.colorScheme.primary.withOpacity(0.10),
                      foregroundColor: theme.colorScheme.primary,
                      child: const Icon(Icons.person, size: 17),
                    ),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(36, 36),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '$weekDone / $weekDisplayMax',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Trainings diese Woche',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.68),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                reachedGoldenDay
                    ? 'Rhythmus halten.'
                    : 'Zielbereich: 5 bis 7 pro Woche.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor:
                      theme.colorScheme.onSurface.withOpacity(0.10),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _MinimalStat(
                    label: 'Streak',
                    value: '${snapshot.dailyStreakDays} Tage',
                  ),
                  const SizedBox(width: 16),
                  _MinimalStat(
                    label: 'Woche',
                    value: '$qualifiedWeeks / 4',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                notes.isEmpty
                    ? 'Befindensverlauf • ${_scopeLabel(moodScope)} • ${_rangeLabel(moodRangePreset)}'
                    : 'Befindensverlauf • ${_scopeLabel(moodScope)} • ${_rangeLabel(moodRangePreset)} • ${notes.length} Notizen',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: onAddNote,
                    icon: const Icon(Icons.edit_note, size: 16),
                    label: const Text('Notiz +'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      minimumSize: const Size(0, 34),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    onPressed: onViewNotes,
                    tooltip: 'Notizen ansehen',
                    icon: const Icon(Icons.notes),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(34, 34),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: chartHeight,
                child: moodData.isEmpty
                    ? Center(
                        child: Text(
                          'Noch keine Check-ins',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.56),
                          ),
                        ),
                      )
                    : _MoodTrendChart(data: moodData),
              ),
            ],
          ),
        );
      },
    );
  }

  String _scopeLabel(MoodViewScope scope) {
    return switch (scope) {
      MoodViewScope.package => 'Paket',
      MoodViewScope.overall => 'Gesamt',
    };
  }

  String _rangeLabel(MoodViewRangePreset range) {
    return switch (range) {
      MoodViewRangePreset.days30 => '30T',
      MoodViewRangePreset.days90 => '90T',
      MoodViewRangePreset.year1 => '1J',
      MoodViewRangePreset.all => 'Alle',
    };
  }
}

class _MoodTrendChart extends StatelessWidget {
  final List<MoodDailyAggregate> data;

  const _MoodTrendChart({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final latest = data.isEmpty ? null : data.last;

    String asText(double? value) =>
        value == null ? '-' : value.toStringAsFixed(1);

    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _MoodTrendPainter(
                      data: data,
                      moodColor: _moodSeriesColor,
                      energyColor: _energySeriesColor,
                      stressColor: _stressSeriesColor,
                      axisColor: theme.colorScheme.onSurface.withOpacity(0.24),
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 2,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: _noteSeriesColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Notizen',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface.withOpacity(0.66),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _MoodLegendItem(
                label: 'Mood',
                value: asText(latest?.avgMood),
                color: _moodSeriesColor,
              ),
              const SizedBox(width: 8),
              _MoodLegendItem(
                label: 'Energy',
                value: asText(latest?.avgEnergy),
                color: _energySeriesColor,
              ),
              const SizedBox(width: 8),
              _MoodLegendItem(
                label: 'Stress',
                value: asText(latest?.avgStress),
                color: _stressSeriesColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoodLegendItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MoodLegendItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '$label $value',
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodTrendPainter extends CustomPainter {
  final List<MoodDailyAggregate> data;
  final Color moodColor;
  final Color energyColor;
  final Color stressColor;
  final Color axisColor;

  _MoodTrendPainter({
    required this.data,
    required this.moodColor,
    required this.energyColor,
    required this.stressColor,
    required this.axisColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    const leftPad = 6.0;
    const rightPad = 6.0;
    const topPad = 8.0;
    const bottomPad = 16.0;
    final chartWidth = size.width - leftPad - rightPad;
    final chartHeight = size.height - topPad - bottomPad;
    if (chartWidth <= 0 || chartHeight <= 0) return;

    final axisPaint = Paint()
      ..color = axisColor
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = topPad + chartHeight * (i / 4);
      canvas.drawLine(
        Offset(leftPad, y),
        Offset(size.width - rightPad, y),
        axisPaint,
      );
    }

    final noteMarkerFill = Paint()
      ..color = _noteSeriesColor
      ..style = PaintingStyle.fill;
    final noteMarkerStroke = Paint()
      ..color = Colors.white.withOpacity(0.92)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final count = data.length;
    for (var i = 0; i < count; i++) {
      final noteCount = data[i].noteCount;
      if (noteCount <= 0) continue;
      final x = leftPad +
          (count == 1 ? chartWidth / 2 : chartWidth * (i / (count - 1)));
      final y = topPad + chartHeight + 7;
      final radius = noteCount >= 2 ? 3.8 : 3.0;
      canvas.drawCircle(Offset(x, y), radius, noteMarkerFill);
      canvas.drawCircle(Offset(x, y), radius, noteMarkerStroke);
    }

    void drawMarker({
      required Offset center,
      required Color color,
      required int shape,
      required double radius,
    }) {
      final fill = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      final stroke = Paint()
        ..color = Colors.white.withOpacity(0.95)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4;

      switch (shape) {
        case 0:
          canvas.drawCircle(center, radius, fill);
          canvas.drawCircle(center, radius, stroke);
          break;
        case 1:
          final rect = Rect.fromCenter(
            center: center,
            width: radius * 2.2,
            height: radius * 2.2,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(2.5)),
            fill,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(2.5)),
            stroke,
          );
          break;
        default:
          final path = Path()
            ..moveTo(center.dx, center.dy - radius * 1.25)
            ..lineTo(center.dx + radius * 1.05, center.dy)
            ..lineTo(center.dx, center.dy + radius * 1.25)
            ..lineTo(center.dx - radius * 1.05, center.dy)
            ..close();
          canvas.drawPath(path, fill);
          canvas.drawPath(path, stroke);
      }
    }

    void drawSeries({
      required double? Function(MoodDailyAggregate) selector,
      required double? Function(MoodDailyAggregate) minSelector,
      required double? Function(MoodDailyAggregate) maxSelector,
      required Color color,
      required int markerShape,
    }) {
      final points = <Offset>[];
      final lowerPoints = <Offset>[];
      final upperPoints = <Offset>[];
      final entryCounts = <int>[];
      for (var i = 0; i < count; i++) {
        final item = data[i];
        final value = selector(item);
        if (value == null) continue;
        final x = leftPad +
            (count == 1 ? chartWidth / 2 : chartWidth * (i / (count - 1)));
        final normalized = ((value - 1.0) / 4.0).clamp(0.0, 1.0);
        final y = topPad + chartHeight * (1 - normalized);
        points.add(Offset(x, y));
        entryCounts.add(item.entriesCount);

        final minValue = minSelector(item);
        final maxValue = maxSelector(item);
        if (minValue != null && maxValue != null && minValue != maxValue) {
          final minNorm = ((minValue - 1.0) / 4.0).clamp(0.0, 1.0);
          final maxNorm = ((maxValue - 1.0) / 4.0).clamp(0.0, 1.0);
          final lowerY = topPad + chartHeight * (1 - minNorm);
          final upperY = topPad + chartHeight * (1 - maxNorm);
          lowerPoints.add(Offset(x, lowerY));
          upperPoints.add(Offset(x, upperY));
        }
      }
      if (points.isEmpty) return;

      if (lowerPoints.length >= 2 && upperPoints.length >= 2) {
        final upperPath = Path()
          ..moveTo(upperPoints.first.dx, upperPoints.first.dy);
        for (var i = 1; i < upperPoints.length; i++) {
          final p0 = upperPoints[i - 1];
          final p1 = upperPoints[i];
          final cx = (p0.dx + p1.dx) / 2;
          upperPath.cubicTo(cx, p0.dy, cx, p1.dy, p1.dx, p1.dy);
        }

        final lowerPath = Path()
          ..moveTo(lowerPoints.first.dx, lowerPoints.first.dy);
        for (var i = 1; i < lowerPoints.length; i++) {
          final p0 = lowerPoints[i - 1];
          final p1 = lowerPoints[i];
          final cx = (p0.dx + p1.dx) / 2;
          lowerPath.cubicTo(cx, p0.dy, cx, p1.dy, p1.dx, p1.dy);
        }

        final rangePath = Path.from(upperPath);
        final reversedLower = lowerPoints.reversed.toList(growable: false);
        rangePath.lineTo(reversedLower.first.dx, reversedLower.first.dy);
        for (var i = 1; i < reversedLower.length; i++) {
          final p0 = reversedLower[i - 1];
          final p1 = reversedLower[i];
          final cx = (p0.dx + p1.dx) / 2;
          rangePath.cubicTo(cx, p0.dy, cx, p1.dy, p1.dx, p1.dy);
        }
        rangePath.close();

        final rangePaint = Paint()
          ..color = color.withOpacity(0.08)
          ..style = PaintingStyle.fill;
        canvas.drawPath(rangePath, rangePaint);
      }

      final linePath = Path()..moveTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length; i++) {
        final p0 = points[i - 1];
        final p1 = points[i];
        final cx = (p0.dx + p1.dx) / 2;
        linePath.cubicTo(cx, p0.dy, cx, p1.dy, p1.dx, p1.dy);
      }

      final fillPath = Path.from(linePath)
        ..lineTo(points.last.dx, topPad + chartHeight)
        ..lineTo(points.first.dx, topPad + chartHeight)
        ..close();

      final fillPaint = Paint()
        ..color = color.withOpacity(0.14)
        ..style = PaintingStyle.fill;
      canvas.drawPath(fillPath, fillPaint);

      // White underlay separates crossings; colored overlay uses additive
      // blending so overlapping series stay visible instead of fully covering.
      final lineUnderlayPaint = Paint()
        ..color = Colors.white.withOpacity(0.28)
        ..strokeWidth = 4.6
        ..style = PaintingStyle.stroke;
      canvas.drawPath(linePath, lineUnderlayPaint);

      final linePaint = Paint()
        ..color = color
        ..strokeWidth = 2.8
        ..style = PaintingStyle.stroke;
      canvas.drawPath(linePath, linePaint);

      for (var i = 0; i < points.length; i++) {
        final point = points[i];
        final pointRadius = entryCounts[i] > 1 ? 3.9 : 3.2;
        drawMarker(
          center: point,
          color: color,
          shape: markerShape,
          radius: pointRadius,
        );
      }
    }

    drawSeries(
      selector: (d) => d.avgMood,
      minSelector: (d) => d.minMood,
      maxSelector: (d) => d.maxMood,
      color: moodColor,
      markerShape: 0,
    );
    drawSeries(
      selector: (d) => d.avgEnergy,
      minSelector: (d) => d.minEnergy,
      maxSelector: (d) => d.maxEnergy,
      color: energyColor,
      markerShape: 1,
    );
    drawSeries(
      selector: (d) => d.avgStress,
      minSelector: (d) => d.minStress,
      maxSelector: (d) => d.maxStress,
      color: stressColor,
      markerShape: 2,
    );
  }

  @override
  bool shouldRepaint(covariant _MoodTrendPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.moodColor != moodColor ||
        oldDelegate.energyColor != energyColor ||
        oldDelegate.stressColor != stressColor ||
        oldDelegate.axisColor != axisColor;
  }
}

class _MinimalStat extends StatelessWidget {
  final String label;
  final String value;

  const _MinimalStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.58),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _HeroProgressCard extends StatelessWidget {
  final DashboardProgressSnapshot snapshot;
  final ThemeData theme;
  final GoldenDayStatus? goldenDayStatus;

  const _HeroProgressCard({
    required this.snapshot,
    required this.theme,
    required this.goldenDayStatus,
  });

  @override
  Widget build(BuildContext context) {
    final trainingsThisWeek = snapshot.completedThisWeek.clamp(0, 7);
    final isQualified = snapshot.isWeeklyQualified;
    final qualifiedWeeks = (goldenDayStatus?.qualifiedWeeks ?? 0).clamp(0, 4);
    final reached = goldenDayStatus?.hasReachedGoldenDay == true;
    final currentBlockIndex = goldenDayStatus?.currentBlockIndex ?? 0;
    final trainingsByBlock =
        goldenDayStatus?.trainingsByBlock ?? const [0, 0, 0, 0];
    final weeksRemaining = (4 - qualifiedWeeks).clamp(0, 4);
    final streakDays = snapshot.dailyStreakDays;
    final currentDay = snapshot.currentDay;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            reached ? 'Golden Day erreicht' : 'Du bist auf Kurs zum Golden Day',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            reached
                ? 'Halte deine Routine und stabilisiere deinen Fortschritt.'
                : '$weeksRemaining Woche${weeksRemaining == 1 ? '' : 'n'} bis zum Ziel.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.70),
            ),
          ),
          const SizedBox(height: 14),
          _KpiGrid(
            tiles: [
              _KpiTileData(
                icon: Icons.today_outlined,
                title: 'Heute',
                value: snapshot.todayCompleted ? 'Erledigt' : 'Offen',
                subtitle:
                    snapshot.todayCompleted ? 'Stark gemacht' : 'Jetzt starten',
                accent: snapshot.todayCompleted
                    ? const Color(0xFF2E7D32)
                    : theme.colorScheme.primary,
              ),
              _KpiTileData(
                icon: Icons.local_fire_department_outlined,
                title: 'Streak',
                value: '$streakDays Tage',
                subtitle: streakDays > 0 ? 'Bleib dran' : 'Neu aufbauen',
                accent: const Color(0xFFF57C00),
              ),
              _KpiTileData(
                icon: Icons.fitness_center_outlined,
                title: 'Diese Woche',
                value: '$trainingsThisWeek / 7',
                subtitle: isQualified ? 'Woche zählt' : 'Mind. 3 für Quali',
                accent: isQualified
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFF1976D2),
              ),
              _KpiTileData(
                icon: Icons.flag_outlined,
                title: 'Programm',
                value: 'Tag $currentDay / 28',
                subtitle: reached ? 'Ziel geschafft' : 'Fortschritt läuft',
                accent: theme.colorScheme.secondary,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _WeeklyMomentumBar(
            filled: trainingsThisWeek,
            qualified: isQualified,
          ),
          const SizedBox(height: 14),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.10),
                    theme.colorScheme.surface.withOpacity(0.10),
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.18),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: _JourneyMap(
                  progressColor: theme.colorScheme.primary,
                  mutedColor: theme.colorScheme.onSurface.withOpacity(
                    theme.brightness == Brightness.light ? 0.10 : 0.18,
                  ),
                  labelColor: theme.colorScheme.onSurface.withOpacity(0.65),
                  filledWeeks: qualifiedWeeks,
                  totalWeeks: 4,
                  weekDotsFilled: trainingsThisWeek,
                  currentBlockIndex: currentBlockIndex,
                  trainingsByBlock: trainingsByBlock,
                  weekQualified: isQualified,
                  reached: reached,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiTileData {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color accent;

  const _KpiTileData({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accent,
  });
}

class _KpiGrid extends StatelessWidget {
  final List<_KpiTileData> tiles;

  const _KpiGrid({required this.tiles});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tiles.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.72,
      ),
      itemBuilder: (context, index) {
        final tile = tiles[index];
        final theme = Theme.of(context);
        return Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withOpacity(0.75),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: tile.accent.withOpacity(0.28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(tile.icon, size: 14, color: tile.accent),
                  const SizedBox(width: 6),
                  Text(
                    tile.title,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.66),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                tile.value,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                tile.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.56),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WeeklyMomentumBar extends StatelessWidget {
  final int filled;
  final bool qualified;

  const _WeeklyMomentumBar({
    required this.filled,
    required this.qualified,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clamped = filled.clamp(0, 7);
    final accent =
        qualified ? const Color(0xFF2E7D32) : theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withOpacity(0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Wochen-Momentum',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                '$clamped / 7',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(7, (index) {
              final done = index < clamped;
              final isTarget = index < 3;
              final color = done
                  ? (isTarget ? accent : accent.withOpacity(0.65))
                  : theme.colorScheme.onSurface.withOpacity(0.12);

              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: index == 6 ? 0 : 6),
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            qualified
                ? 'Qualifiziert: Diese Woche zählt für deinen Golden Day.'
                : 'Ziel für Qualifikation: mindestens 3 Trainings pro Woche.',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.65),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _TodayIndicator extends StatelessWidget {
  final bool done;

  const _TodayIndicator({required this.done});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: primary.withOpacity(0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: primary,
          ),
          const SizedBox(width: 8),
          Text(
            done ? 'Für heute geschafft, bis morgen.' : "Los geht's.",
            style: TextStyle(
              color: primary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyMap extends StatelessWidget {
  final Color progressColor;
  final Color mutedColor;
  final Color labelColor;
  final int filledWeeks;
  final int totalWeeks;
  final int weekDotsFilled;
  final int currentBlockIndex;
  final List<int> trainingsByBlock;
  final bool weekQualified;
  final bool reached;

  const _JourneyMap({
    required this.progressColor,
    required this.mutedColor,
    required this.labelColor,
    required this.filledWeeks,
    required this.totalWeeks,
    required this.weekDotsFilled,
    required this.currentBlockIndex,
    required this.trainingsByBlock,
    required this.weekQualified,
    required this.reached,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _JourneyMapPainter(
          progressColor: progressColor,
          mutedColor: mutedColor,
          labelColor: labelColor,
          filledWeeks: filledWeeks,
          totalWeeks: totalWeeks,
          weekDotsFilled: weekDotsFilled,
          currentBlockIndex: currentBlockIndex,
          trainingsByBlock: trainingsByBlock,
          weekQualified: weekQualified,
          reached: reached,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _JourneyMapPainter extends CustomPainter {
  final Color progressColor;
  final Color mutedColor;
  final Color labelColor;
  final int filledWeeks;
  final int totalWeeks;
  final int weekDotsFilled;
  final int currentBlockIndex;
  final List<int> trainingsByBlock;
  final bool weekQualified;
  final bool reached;

  _JourneyMapPainter({
    required this.progressColor,
    required this.mutedColor,
    required this.labelColor,
    required this.filledWeeks,
    required this.totalWeeks,
    required this.weekDotsFilled,
    required this.currentBlockIndex,
    required this.trainingsByBlock,
    required this.weekQualified,
    required this.reached,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width * 0.5;
    final topY = size.height * 0.12;
    final bottomY = size.height * 0.88;
    const lineWidth = 10.0;

    final trackPaint = Paint()
      ..color = mutedColor
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = lineWidth;

    final progressPaint = Paint()
      ..color = progressColor.withOpacity(0.96)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = lineWidth;

    canvas.drawLine(
        Offset(centerX, topY), Offset(centerX, bottomY), trackPaint);

    final clampedFilled = filledWeeks.clamp(0, totalWeeks);
    final t = totalWeeks == 0 ? 0.0 : (clampedFilled / totalWeeks.toDouble());
    final progressY = topY + (bottomY - topY) * t;
    if (t > 0) {
      canvas.drawLine(
        Offset(centerX, topY),
        Offset(centerX, progressY),
        progressPaint,
      );
    }

    const nodeRadius = 16.0;
    final nodeGap = (bottomY - topY) / (totalWeeks - 1).clamp(1, 999);
    final activeIndex = reached
        ? (totalWeeks - 1).clamp(0, totalWeeks)
        : (clampedFilled == 0 ? 0 : (clampedFilled - 1)).clamp(0, totalWeeks);
    // The weekly ring should follow the *journey* progress, not raw elapsed
    // calendar blocks. When the user misses a week (<3), the journey doesn't
    // advance, so keep the ring on the same node.
    //
    // `filledWeeks` includes the current week if it already qualifies, so for
    // the ring we use the "current journey week" = qualified weeks *before*
    // the current block.
    final currentIndex = reached
        ? (totalWeeks - 1).clamp(0, totalWeeks - 1)
        : (filledWeeks - (weekQualified ? 1 : 0)).clamp(0, totalWeeks - 1);

    for (var i = 0; i < totalWeeks; i++) {
      final y = topY + nodeGap * i;
      final isFilled = i < clampedFilled;
      final isGoal = i == totalWeeks - 1;
      final isActive = i == activeIndex;
      final isCurrent = i == currentIndex;

      final fill = Paint()
        ..color = isGoal && reached
            ? progressColor
            : isFilled
                ? progressColor
                : mutedColor.withOpacity(0.16);

      final border = Paint()
        ..color = mutedColor.withOpacity(isFilled ? 0.0 : 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      final r = isGoal ? nodeRadius + 6 : nodeRadius;

      if (isActive) {
        final glow = Paint()
          ..color = progressColor.withOpacity(0.30)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
        canvas.drawCircle(Offset(centerX, y), r + 8, glow);
      }

      canvas.drawCircle(Offset(centerX, y), r, fill);
      if (!isFilled && !(isGoal && reached)) {
        canvas.drawCircle(Offset(centerX, y), r, border);
      }

      if (isGoal) {
        final iconColor = (progressColor.computeLuminance() > 0.6)
            ? Colors.black.withOpacity(0.85)
            : Colors.white;
        final iconPaint = Paint()..color = reached ? iconColor : progressColor;
        final w = r * 0.9;
        final h = r * 0.9;
        final path = Path()
          ..moveTo(centerX, y - h * 0.55)
          ..lineTo(centerX + w * 0.20, y - h * 0.10)
          ..lineTo(centerX + w * 0.55, y - h * 0.05)
          ..lineTo(centerX + w * 0.28, y + h * 0.15)
          ..lineTo(centerX + w * 0.36, y + h * 0.52)
          ..lineTo(centerX, y + h * 0.32)
          ..lineTo(centerX - w * 0.36, y + h * 0.52)
          ..lineTo(centerX - w * 0.28, y + h * 0.15)
          ..lineTo(centerX - w * 0.55, y - h * 0.05)
          ..lineTo(centerX - w * 0.20, y - h * 0.10)
          ..close();
        canvas.drawPath(path, iconPaint);
      }

      // Small per-week badges for past weeks (and current gets the full ring below).
      final weekCount = (i < trainingsByBlock.length) ? trainingsByBlock[i] : 0;
      if (!isCurrent && weekCount >= 6) {
        _paintWeekBonusBadge(
          canvas,
          center: Offset(centerX, y),
          nodeRadius: r,
          count: weekCount,
        );
      }
    }

    // Weekly progress: segmented ring around the "active" week node (ties the
    // 5 units directly to the journey path).
    final currentY = topY + nodeGap * currentIndex;
    final isCurrentGoal = currentIndex == totalWeeks - 1;
    final currentNodeRadius = isCurrentGoal ? nodeRadius + 6 : nodeRadius;
    _paintWeeklyRing(
      canvas,
      size: size,
      center: Offset(centerX, currentY),
      nodeRadius: currentNodeRadius,
      // The ring visualizes the *current rolling week* progress.
      filled: weekDotsFilled.clamp(0, 7),
      qualified: weekQualified,
    );
  }

  void _paintWeekBonusBadge(
    Canvas canvas, {
    required Offset center,
    required double nodeRadius,
    required int count,
  }) {
    // Diamond for 6/7, Crown for 7/7 (small, non-intrusive).
    final bonusColor =
        Color.lerp(progressColor, const Color(0xFFFFD54F), 0.78) ??
            const Color(0xFFFFD54F);

    final dx = nodeRadius + 18;
    final dy = nodeRadius + 8;
    final p = center + Offset(dx, -dy);

    if (count >= 7) {
      const w = 16.0;
      const h = 10.0;
      final crown = Path()
        ..moveTo(p.dx - w / 2, p.dy + h)
        ..lineTo(p.dx - w / 2 + 3, p.dy + h * 0.35)
        ..lineTo(p.dx - w / 4, p.dy + h * 0.65)
        ..lineTo(p.dx, p.dy)
        ..lineTo(p.dx + w / 4, p.dy + h * 0.65)
        ..lineTo(p.dx + w / 2 - 3, p.dy + h * 0.35)
        ..lineTo(p.dx + w / 2, p.dy + h)
        ..close();
      final glow = Paint()
        ..color = bonusColor.withOpacity(0.20)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawPath(crown, glow);
      canvas.drawPath(crown, Paint()..color = bonusColor.withOpacity(0.92));
      return;
    }

    // Diamond for 6/7.
    const r = 8.0;
    final diamond = Path()
      ..moveTo(p.dx, p.dy - r)
      ..lineTo(p.dx + r, p.dy)
      ..lineTo(p.dx, p.dy + r)
      ..lineTo(p.dx - r, p.dy)
      ..close();
    final glow = Paint()
      ..color = bonusColor.withOpacity(0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawPath(diamond, glow);
    canvas.drawPath(diamond, Paint()..color = bonusColor.withOpacity(0.90));
  }

  void _paintWeeklyRing(
    Canvas canvas, {
    required Size size,
    required Offset center,
    required double nodeRadius,
    required int filled,
    required bool qualified,
  }) {
    const totalSegments = 5;
    const gapAngle = 0.16; // radians
    const segmentAngle =
        (2 * math.pi - totalSegments * gapAngle) / totalSegments;
    const startAngle = -math.pi / 2;

    final ringRadius = nodeRadius + 18;
    final rect = Rect.fromCircle(center: center, radius: ringRadius);

    final normalizedFilled = filled.clamp(0, 7);
    final filledMain = math.min(totalSegments, normalizedFilled);
    final bonusFilled = math.max(0, normalizedFilled - totalSegments); // 0..2

    final bonusColor =
        Color.lerp(progressColor, const Color(0xFFFFD54F), 0.78) ??
            const Color(0xFFFFD54F);

    // Subtle base halo (connects ring + node visually).
    final halo = Paint()
      ..color = progressColor.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawArc(rect, 0, 2 * math.pi, false, halo);

    if (normalizedFilled >= 5) {
      final powerHalo = Paint()
        ..color = progressColor.withOpacity(0.14)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 26
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26);
      canvas.drawArc(rect, 0, 2 * math.pi, false, powerHalo);
    }

    for (var i = 0; i < totalSegments; i++) {
      final isFilled = i < filledMain;
      final isRequired = i < 3;
      final strokeWidth = isRequired ? 7.0 : 5.0;

      final color = isFilled
          ? (isRequired
              ? progressColor.withOpacity(0.98)
              : progressColor.withOpacity(0.72))
          : mutedColor.withOpacity(isRequired ? 0.30 : 0.20);

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth;

      final a = startAngle + i * (segmentAngle + gapAngle);
      canvas.drawArc(rect, a, segmentAngle, false, paint);
    }

    // Bonus pips (6th/7th day): two small diamonds above the ring.
    // Filled progressively when the user exceeds 5.
    if (normalizedFilled > 5) {
      const pipR = 9.0;
      final pipDistance = ringRadius + 14;
      final angles = <double>[
        -math.pi / 3.2, // ~-56°
        -math.pi + math.pi / 3.2, // mirrored (~-124°) -> appears top-left
      ];

      for (var i = 0; i < 2; i++) {
        final a = angles[i];
        final p = center +
            Offset(math.cos(a) * pipDistance, math.sin(a) * pipDistance);
        final isOn = i < bonusFilled;
        final fill = Paint()
          ..color = isOn
              ? bonusColor.withOpacity(0.95)
              : mutedColor.withOpacity(0.18);
        final stroke = Paint()
          ..color =
              isOn ? bonusColor.withOpacity(0.55) : mutedColor.withOpacity(0.26)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

        final diamond = Path()
          ..moveTo(p.dx, p.dy - pipR)
          ..lineTo(p.dx + pipR, p.dy)
          ..lineTo(p.dx, p.dy + pipR)
          ..lineTo(p.dx - pipR, p.dy)
          ..close();

        if (isOn) {
          final glow = Paint()
            ..color = bonusColor.withOpacity(0.22)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
          canvas.drawPath(diamond, glow);
        }

        canvas.drawPath(diamond, fill);
        canvas.drawPath(diamond, stroke);
      }
    }

    // "Perfect week" (7/7): a tiny crown above the node.
    if (normalizedFilled >= 7) {
      final crownY = center.dy - ringRadius - 16;
      final crownX = center.dx;
      const w = 22.0;
      const h = 14.0;
      final crown = Path()
        ..moveTo(crownX - w / 2, crownY + h)
        ..lineTo(crownX - w / 2 + 4, crownY + h * 0.35)
        ..lineTo(crownX - w / 4, crownY + h * 0.65)
        ..lineTo(crownX, crownY)
        ..lineTo(crownX + w / 4, crownY + h * 0.65)
        ..lineTo(crownX + w / 2 - 4, crownY + h * 0.35)
        ..lineTo(crownX + w / 2, crownY + h)
        ..close();

      final glow = Paint()
        ..color = bonusColor.withOpacity(0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
      canvas.drawPath(crown, glow);
      canvas.drawPath(crown, Paint()..color = bonusColor.withOpacity(0.95));
    }

    // Minimal label (no numbers); add a check when the week counts (>=3).
    final labelPainter = TextPainter(
      text: TextSpan(
        text: normalizedFilled >= 7
            ? 'Bonus freigeschaltet'
            : normalizedFilled >= 5
                ? 'Stark diese Woche'
                : qualified
                    ? 'Diese Woche ✓'
                    : 'Diese Woche',
        style: TextStyle(
          color: labelColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);

    final belowY = center.dy + ringRadius + 12;
    final aboveY = center.dy - ringRadius - 12 - labelPainter.height;
    final y = (belowY + labelPainter.height <= size.height)
        ? belowY
        : aboveY.clamp(0.0, size.height - labelPainter.height).toDouble();

    labelPainter.paint(
      canvas,
      Offset(center.dx - labelPainter.width / 2, y),
    );
  }

  @override
  bool shouldRepaint(covariant _JourneyMapPainter oldDelegate) {
    return oldDelegate.filledWeeks != filledWeeks ||
        oldDelegate.totalWeeks != totalWeeks ||
        oldDelegate.weekDotsFilled != weekDotsFilled ||
        oldDelegate.currentBlockIndex != currentBlockIndex ||
        oldDelegate.trainingsByBlock != trainingsByBlock ||
        oldDelegate.weekQualified != weekQualified ||
        oldDelegate.reached != reached ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.mutedColor != mutedColor;
  }
}

class _PrimaryActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _PrimaryActionButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      height: 74,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.play_circle_fill, size: 30),
        label: Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          shadowColor: theme.colorScheme.primary.withOpacity(0.4),
        ),
      ),
    );
  }
}
