import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../bootstrap/providers.dart';
import '../../../../core/services/notification_service.dart';
import '../../../progress/presentation/providers/progress_provider.dart';
import '../../../progress/domain/services/progress_service.dart';
import '../../../../core/time/clock_provider.dart';

class AdminToolsScreen extends ConsumerStatefulWidget {
  const AdminToolsScreen({super.key});

  @override
  ConsumerState<AdminToolsScreen> createState() => _AdminToolsScreenState();
}

class _AdminToolsScreenState extends ConsumerState<AdminToolsScreen> {
  late DateTime _visibleMonth;
  DateTime? _selectedDay;
  Future<Set<int>>? _monthDaysFuture;
  bool _diagLoading = false;
  bool _probeRunning = false;
  DashboardProgressSnapshot? _diagSnapshot;
  bool _diagCompletedToday = false;
  bool _diagReminderScheduled = false;
  int _diagPendingNotifications = 0;
  List<int> _diagPendingNotificationIds = const <int>[];
  int _diagPendingJobs = 0;
  DateTime? _diagOldestJobAt;
  String? _probeSummary;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
    _selectedDay = DateTime(now.year, now.month, now.day);
    _loadDiagnostics();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshMonth();
  }

  void _refreshMonth() {
    final progress = ref.read(progressServiceProvider);
    final from = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final to = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 1);
    _monthDaysFuture = progress.debugCompletedDayEpochsInRange(from, to);
  }

  Future<void> _loadDiagnostics() async {
    if (!mounted) return;
    setState(() => _diagLoading = true);

    try {
      final progress = ref.read(progressServiceProvider);
      final sync = ref.read(syncServiceProvider);
      final notifications = NotificationService();

      final snapshot = await progress.buildDashboardSnapshot();
      final completedToday = await progress.hasCompletedTrainingToday();
      final reminderDiag = await notifications.getReminderDiagnostics();
      final queueStats = await sync.getQueueStats();

      if (!mounted) return;
      setState(() {
        _diagSnapshot = snapshot;
        _diagCompletedToday = completedToday;
        _diagReminderScheduled = reminderDiag.hasDailyReminder;
        _diagPendingNotifications = reminderDiag.totalPending;
        _diagPendingNotificationIds = reminderDiag.pendingIds;
        _diagPendingJobs = queueStats.pendingJobs;
        _diagOldestJobAt = queueStats.oldestJobAt;
        _diagLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _diagLoading = false);
    }
  }

  Future<void> _runReconnectProbe() async {
    if (_probeRunning) return;
    if (!mounted) return;
    setState(() {
      _probeRunning = true;
      _probeSummary = null;
    });

    try {
      final progress = ref.read(progressServiceProvider);

      final result = await progress.runReconnectProbe();

      if (!mounted) return;
      setState(() {
        _probeSummary = 'Queue ${result.beforePendingJobs} -> '
            '${result.afterPendingJobs} | Reminder '
            '${result.beforeReminderScheduled ? 'ja' : 'nein'} -> '
            '${result.afterReminderScheduled ? 'ja' : 'nein'}';
      });
      await _loadDiagnostics();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _probeSummary = 'Probe-Fehler: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _probeRunning = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;
    final email = (user?.email ?? '').toLowerCase();
    if (email != 'admin@test.de') {
      return Scaffold(
        appBar: AppBar(title: const Text('Test Tools')),
        body: const Center(
          child: Text('Kein Zugriff.'),
        ),
      );
    }

    final clock = ref.watch(appClockProvider);
    final progress = ref.watch(progressServiceProvider);

    final effectiveNow = clock.now();
    final override = clock.overrideNow;
    final overrideActive = override != null;

    final monthDaysFuture = _monthDaysFuture ??
        progress.debugCompletedDayEpochsInRange(
          DateTime(_visibleMonth.year, _visibleMonth.month, 1),
          DateTime(_visibleMonth.year, _visibleMonth.month + 1, 1),
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Tools'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Test-Zeit',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    override != null
                        ? 'Override aktiv: ${_fmtDateTime(override)}'
                        : 'Systemzeit: ${_fmtDateTime(effectiveNow)}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          final base = (clock.overrideNow ?? clock.now())
                              .subtract(const Duration(days: 1));
                          await clock.setOverride(base);
                          await _loadDiagnostics();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Tag -1')),
                            );
                          }
                        },
                        icon: const Icon(Icons.chevron_left),
                        label: const Text('-1 Tag'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final base = (clock.overrideNow ?? clock.now())
                              .add(const Duration(days: 1));
                          await clock.setOverride(base);
                          await _loadDiagnostics();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Tag +1')),
                            );
                          }
                        },
                        icon: const Icon(Icons.chevron_right),
                        label: const Text('+1 Tag'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: override ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked == null) return;
                          final current = clock.overrideNow ?? DateTime.now();
                          final withTime = DateTime(
                            picked.year,
                            picked.month,
                            picked.day,
                            current.hour,
                            current.minute,
                            current.second,
                            current.millisecond,
                          );
                          await clock.setOverride(withTime);
                          await _loadDiagnostics();
                        },
                        icon: const Icon(Icons.calendar_month),
                        label: const Text('Datum wählen'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final base = clock.overrideNow ?? DateTime.now();
                          await clock.setOverride(
                            DateTime(base.year, base.month, base.day, 23, 58),
                          );
                          await _loadDiagnostics();
                        },
                        icon: const Icon(Icons.nights_stay_outlined),
                        label: const Text('23:58'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final base = clock.overrideNow ?? DateTime.now();
                          final nextDay = DateTime(
                              base.year, base.month, base.day + 1, 0, 5);
                          await clock.setOverride(nextDay);
                          await _loadDiagnostics();
                        },
                        icon: const Icon(Icons.wb_twilight_outlined),
                        label: const Text('00:05 (+1)'),
                      ),
                      if (overrideActive)
                        TextButton(
                          onPressed: () async {
                            await clock.setOverride(null);
                            await _loadDiagnostics();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Override entfernt')),
                              );
                            }
                          },
                          child: const Text('Zurück zur Systemzeit'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Phase-0 Diagnose',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _diagLoading ? null : _loadDiagnostics,
                        tooltip: 'Neu laden',
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: (_diagLoading || _probeRunning)
                            ? null
                            : _runReconnectProbe,
                        icon: const Icon(Icons.sync),
                        label: Text(
                          _probeRunning ? 'Probe läuft...' : 'Reconnect-Probe',
                        ),
                      ),
                    ],
                  ),
                  if (_probeSummary != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _probeSummary!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.75),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  if (_diagLoading)
                    const LinearProgressIndicator()
                  else ...[
                    Text(
                      'Heute erledigt: ${_diagCompletedToday ? 'ja' : 'nein'}',
                    ),
                    Text(
                      'Dashboard Heute: ${_diagSnapshot?.todayCompleted == true ? 'Erledigt' : 'Offen'}',
                    ),
                    Text(
                      'Dashboard Woche: ${_diagSnapshot?.completedThisWeek ?? 0} / 7',
                    ),
                    Text(
                      'Dashboard Streak: ${_diagSnapshot?.dailyStreakDays ?? 0} Tage',
                    ),
                    Text(
                      'Reminder geplant: ${_diagReminderScheduled ? 'ja' : 'nein'}',
                    ),
                    Text('Pending Notifications: $_diagPendingNotifications'),
                    Text(
                      'Notification IDs: ${_diagPendingNotificationIds.isEmpty ? '-' : _diagPendingNotificationIds.join(', ')}',
                    ),
                    Text('Pending Sync Jobs: $_diagPendingJobs'),
                    Text(
                      'Ältester Sync Job: ${_diagOldestJobAt == null ? '-' : _fmtDateTime(_diagOldestJobAt!)}',
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Training-Kalender',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Tippe auf einen Tag, um Training zu setzen/entfernen. '
                    'Gesetzte Tage sind markiert.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _visibleMonth = DateTime(
                                _visibleMonth.year, _visibleMonth.month - 1);
                            _refreshMonth();
                          });
                        },
                        icon: const Icon(Icons.chevron_left),
                        tooltip: 'Vorheriger Monat',
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            _fmtMonth(_visibleMonth),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _visibleMonth = DateTime(
                                _visibleMonth.year, _visibleMonth.month + 1);
                            _refreshMonth();
                          });
                        },
                        icon: const Icon(Icons.chevron_right),
                        tooltip: 'Nächster Monat',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<Set<int>>(
                    future: monthDaysFuture,
                    builder: (context, snapshot) {
                      final completedDays = snapshot.data ?? const <int>{};
                      return _CalendarGrid(
                        month: _visibleMonth,
                        selectedDay: _selectedDay,
                        completedDays: completedDays,
                        onSelectDay: (day) async {
                          setState(() => _selectedDay = day);
                          final key = DateTime(day.year, day.month, day.day)
                              .millisecondsSinceEpoch;
                          final isCompleted = completedDays.contains(key);
                          if (isCompleted) {
                            await progress
                                .debugDeleteTrainingSessionForDay(day);
                            await _loadDiagnostics();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Entfernt: ${_fmtDate(day)}'),
                                ),
                              );
                            }
                          } else {
                            await progress.debugSetTrainingSessionForDay(day);
                            await _loadDiagnostics();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Gesetzt: ${_fmtDate(day)}'),
                                ),
                              );
                            }
                          }

                          // If the user toggles a future day relative to the current
                          // app time, automatically move test-time forward so the
                          // dashboard can "see" the new completion.
                          final now = clock.now();
                          final today = DateTime(now.year, now.month, now.day);
                          final selected =
                              DateTime(day.year, day.month, day.day);
                          if (selected.isAfter(today)) {
                            await clock.setOverride(
                              DateTime(
                                selected.year,
                                selected.month,
                                selected.day,
                                now.hour,
                                now.minute,
                                now.second,
                                now.millisecond,
                              ),
                            );
                          }

                          if (!mounted) return;
                          setState(() {
                            _refreshMonth();
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: user == null
                          ? null
                          : () async {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Alles löschen?'),
                                  content: const Text(
                                    'Alle Trainings-Sessions werden entfernt. '
                                    'Das ist nur für Testzwecke.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text('Abbrechen'),
                                    ),
                                    FilledButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: const Text('Löschen'),
                                    ),
                                  ],
                                ),
                              );
                              if (ok != true) return;
                              await progress.debugClearAllTrainingSessions();
                              await _loadDiagnostics();
                              if (!mounted) return;
                              setState(_refreshMonth);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Alle Trainings-Sessions gelöscht.'),
                                  ),
                                );
                              }
                            },
                      icon: const Icon(Icons.delete_sweep),
                      label: const Text('Alle Trainings-Sessions löschen'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Hinweis: Den Nutzer `admin@test.de` mit Passwort `1234` musst du in Firebase Authentication als Email/Password User anlegen. '
            'Die Test-Tools werden nur für diesen Account angezeigt.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.65),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtDate(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  static String _fmtDateTime(DateTime dt) =>
      '${_fmtDate(dt)} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  static String _fmtMonth(DateTime dt) {
    const months = <String>[
      'Januar',
      'Februar',
      'März',
      'April',
      'Mai',
      'Juni',
      'Juli',
      'August',
      'September',
      'Oktober',
      'November',
      'Dezember',
    ];
    final name = months[(dt.month - 1).clamp(0, 11)];
    return '$name ${dt.year}';
  }
}

class _CalendarGrid extends StatelessWidget {
  final DateTime month;
  final DateTime? selectedDay;
  final Set<int> completedDays;
  final ValueChanged<DateTime> onSelectDay;

  const _CalendarGrid({
    required this.month,
    required this.selectedDay,
    required this.completedDays,
    required this.onSelectDay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final firstDay = DateTime(month.year, month.month, 1);
    final firstWeekday = firstDay.weekday; // Mon=1..Sun=7
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    final leadingEmpty = firstWeekday - 1; // Mon-start calendar
    final totalCells = ((leadingEmpty + daysInMonth + 6) ~/ 7) * 7;

    final selectedKey = selectedDay == null
        ? null
        : DateTime(selectedDay!.year, selectedDay!.month, selectedDay!.day)
            .millisecondsSinceEpoch;

    const weekdayLabels = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

    return Column(
      children: [
        Row(
          children: [
            for (final label in weekdayLabels)
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.55),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
          ),
          itemCount: totalCells,
          itemBuilder: (context, index) {
            final dayNum = index - leadingEmpty + 1;
            if (dayNum < 1 || dayNum > daysInMonth) {
              return const SizedBox.shrink();
            }

            final day = DateTime(month.year, month.month, dayNum);
            final key = day.millisecondsSinceEpoch;
            final isCompleted = completedDays.contains(key);
            final isSelected = selectedKey == key;

            final bg = isSelected
                ? theme.colorScheme.primary.withOpacity(0.16)
                : isCompleted
                    ? theme.colorScheme.primary.withOpacity(0.10)
                    : theme.colorScheme.surface.withOpacity(0.55);
            final border = isSelected
                ? theme.colorScheme.primary.withOpacity(0.55)
                : isCompleted
                    ? theme.colorScheme.primary.withOpacity(0.35)
                    : theme.colorScheme.outlineVariant.withOpacity(0.35);

            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onSelectDay(day),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: border),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Text(
                        '$dayNum',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface.withOpacity(0.85),
                        ),
                      ),
                    ),
                    if (isCompleted)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Icon(
                          Icons.check_circle,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
