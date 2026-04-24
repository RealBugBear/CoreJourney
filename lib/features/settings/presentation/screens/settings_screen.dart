import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../bootstrap/providers.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/settings/settings_provider.dart';
import '../../../../core/sync/sync_status.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/trainer/presentation/providers/trainer_provider.dart';
import '../../../../features/training/domain/models/training_session.dart'
    show TrainingSessionMode;
import '../../../../l10n/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          _SectionHeader(title: 'Trainingsmodus'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wie viel Begleitung moechtest du im Training?',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tutorial ist fuer den Einstieg. Routine ist kompakter.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 16),
                    _SegmentedRow<TrainingSessionMode>(
                      options: const [
                        TrainingSessionMode.tutorial,
                        TrainingSessionMode.routine,
                      ],
                      selected: settings.trainingMode,
                      label: (mode) => switch (mode) {
                        TrainingSessionMode.tutorial => l10n.tutorialMode,
                        TrainingSessionMode.routine => l10n.routineMode,
                      },
                      onChanged: notifier.setTrainingMode,
                    ),
                  ],
                ),
              ),
            ),
          ),

          _SectionHeader(title: l10n.settingsLanguage),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _SegmentedRow<String>(
              options: const ['de', 'en'],
              selected: settings.languageCode,
              label: (code) => code == 'de' ? 'Deutsch' : 'English',
              onChanged: notifier.setLanguage,
            ),
          ),

          _SectionHeader(title: l10n.settingsTheme),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _SegmentedRow<ThemeMode>(
              options: const [
                ThemeMode.system,
                ThemeMode.light,
                ThemeMode.dark,
              ],
              selected: settings.themeMode,
              label: (mode) => switch (mode) {
                ThemeMode.system => l10n.themeSystem,
                ThemeMode.light => l10n.themeLight,
                ThemeMode.dark => l10n.themeDark,
              },
              onChanged: notifier.setThemeMode,
            ),
          ),

          _SectionHeader(title: l10n.settingsFeedback),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _SegmentedRow<TrainingFeedbackMode>(
              options: const [
                TrainingFeedbackMode.silent,
                TrainingFeedbackMode.haptic,
                TrainingFeedbackMode.voiceCues,
              ],
              selected: settings.feedbackMode,
              label: (mode) => switch (mode) {
                TrainingFeedbackMode.silent => l10n.silentMode,
                TrainingFeedbackMode.haptic => l10n.hapticMode,
                TrainingFeedbackMode.voiceCues => l10n.voiceCuesMode,
              },
              onChanged: notifier.setFeedbackMode,
            ),
          ),

          _SectionHeader(title: l10n.settingsReminders),
          SwitchListTile(
            title: Text(l10n.reminderEnabled),
            value: settings.remindersEnabled,
            activeColor: AppColors.primary,
            onChanged: notifier.setRemindersEnabled,
          ),
          if (settings.remindersEnabled) ...[
            _TimePickerTile(
              label: '${l10n.reminderWindow} · ${l10n.reminderFrom}',
              time: settings.reminderStart,
              onChanged: notifier.setReminderStart,
            ),
            _TimePickerTile(
              label: '${l10n.reminderWindow} · ${l10n.reminderTo}',
              time: settings.reminderEnd,
              onChanged: notifier.setReminderEnd,
            ),
          ],

          _SectionHeader(title: l10n.settingsWeeklyGoal),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  l10n.weeklyGoalSessions(settings.weeklyGoal),
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: settings.weeklyGoal <= 3
                          ? null
                          : () =>
                              notifier.setWeeklyGoal(settings.weeklyGoal - 1),
                    ),
                    Text(
                      '${settings.weeklyGoal}',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: settings.weeklyGoal >= 7
                          ? null
                          : () =>
                              notifier.setWeeklyGoal(settings.weeklyGoal + 1),
                    ),
                  ],
                ),
              ],
            ),
          ),

          _SectionHeader(title: l10n.settingsDataSync),
          const _SyncStatusTile(),

          const _RoleAreasSection(),
          const _TrainerConnectionSection(),
          const _AccountSection(),
          const _SpecialCasesSection(),
        ],
      ),
    );
  }
}

class _RoleAreasSection extends ConsumerWidget {
  const _RoleAreasSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(userRoleProvider).valueOrNull;
    final isDev = ref.watch(appConfigProvider).isDevelopment;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Rollenbereiche'),
        if (role == 'admin')
          ListTile(
            leading: const Icon(Icons.admin_panel_settings_outlined),
            title: const Text('Admin Panel'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.adminPanel),
          ),
        if (role == 'trainer')
          ListTile(
            leading: const Icon(Icons.group_outlined),
            title: const Text('Trainerbereich'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.trainerDashboard),
          ),
        if (role != 'trainer' && role != 'admin')
          ListTile(
            leading: const Icon(Icons.verified_user_outlined),
            title: const Text('Trainer werden'),
            subtitle: Text(
              isDev
                  ? 'DEV: Code wird serverseitig geprueft'
                  : 'Code eingeben um Trainer-Rolle zu aktivieren',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showActivationDialog(context, ref),
          ),
      ],
    );
  }

  Future<void> _showActivationDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final ctrl = TextEditingController();
    String? errorMsg;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Trainer werden'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Gib deinen Trainer-Aktivierungscode ein:'),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Trainer-Code',
                  border: const OutlineInputBorder(),
                  errorText: errorMsg,
                ),
                onChanged: (_) => setDialogState(() => errorMsg = null),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () async {
                final err = await activateTrainerRole(ctrl.text);
                if (err != null) {
                  setDialogState(() => errorMsg = err);
                  return;
                }
                if (ctx.mounted) Navigator.pop(ctx);
                ref.invalidate(userRoleProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Trainer-Rolle aktiviert!')),
                  );
                }
              },
              child: const Text('Aktivieren'),
            ),
          ],
        ),
      ),
    );

    ctrl.dispose();
  }
}

class _TrainerConnectionSection extends ConsumerWidget {
  const _TrainerConnectionSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(userRoleProvider).valueOrNull;
    if (role == 'trainer' || role == 'admin') return const SizedBox.shrink();

    final trainerName = ref.watch(clientTrainerProvider).valueOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Trainer'),
        ListTile(
          leading: Icon(
            trainerName != null ? Icons.link : Icons.link_off,
            color: trainerName != null ? AppColors.success : null,
          ),
          title: Text(
            trainerName != null ? 'Verbunden mit $trainerName' : 'Trainer verbinden',
          ),
          subtitle: Text(
            trainerName != null
                ? 'Du bist aktuell mit einem Trainer verknuepft.'
                : 'Einladungscode vom Trainer eingeben',
            style: const TextStyle(fontSize: 12),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => trainerName != null
              ? _showSwitchTrainerDialog(context, ref)
              : _showConnectTrainerDialog(context, ref),
        ),
      ],
    );
  }

  Future<void> _showConnectTrainerDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final ctrl = TextEditingController();
    String? errorMsg;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Trainer verbinden'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Gib den 6-stelligen Code ein, den du von deinem Trainer erhalten hast:',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 8,
                ),
                decoration: InputDecoration(
                  labelText: 'Einladungscode',
                  border: const OutlineInputBorder(),
                  errorText: errorMsg,
                  counterText: '',
                  hintText: '000000',
                ),
                onChanged: (_) => setDialogState(() => errorMsg = null),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () async {
                final code = ctrl.text.replaceAll(RegExp(r'\s'), '').trim();
                if (code.length != 6) {
                  setDialogState(
                    () => errorMsg = 'Bitte 6-stelligen Code eingeben.',
                  );
                  return;
                }
                try {
                  await acceptInvite(code);
                  ref.invalidate(clientTrainerProvider);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Trainer erfolgreich verbunden'),
                      ),
                    );
                  }
                } catch (_) {
                  setDialogState(
                    () => errorMsg = 'Fehler beim Verbinden mit dem Trainer.',
                  );
                }
              },
              child: const Text('Verbinden'),
            ),
          ],
        ),
      ),
    );

    ctrl.dispose();
  }

  Future<void> _showSwitchTrainerDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final ctrl = TextEditingController();
    String? errorMsg;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Trainer wechseln'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Gib den 6-stelligen Einladungscode deines neuen Trainers ein:',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
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
                  labelText: 'Einladungscode',
                  border: const OutlineInputBorder(),
                  errorText: errorMsg,
                  counterText: '',
                  hintText: 'A1B2C3',
                ),
                onChanged: (_) => setDialogState(() => errorMsg = null),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () async {
                final code = ctrl.text
                    .replaceAll(RegExp(r'\s'), '')
                    .trim()
                    .toUpperCase();
                if (code.length != 6) {
                  setDialogState(
                    () => errorMsg = 'Bitte 6-stelligen Code eingeben.',
                  );
                  return;
                }
                try {
                  await switchTrainer(code);
                  ref.invalidate(clientTrainerProvider);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Trainer erfolgreich gewechselt'),
                      ),
                    );
                  }
                } catch (e) {
                  final msg = e.toString().contains('Invalid or already used')
                      ? 'Code ungültig oder bereits verwendet.'
                      : 'Fehler: ${e.toString().replaceAll('Exception: ', '')}';
                  setDialogState(() => errorMsg = msg);
                }
              },
              child: const Text('Bestätigen'),
            ),
          ],
        ),
      ),
    );

    ctrl.dispose();
  }
}

class _AccountSection extends ConsumerWidget {
  const _AccountSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Account'),
        ListTile(
          leading: const Icon(Icons.lock_outline),
          title: Text(l10n.profileChangePassword),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(Routes.changePassword),
        ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: Text(l10n.signOut),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            await ref.read(authNotifierProvider.notifier).signOut();
          },
        ),
      ],
    );
  }
}

class _SpecialCasesSection extends ConsumerWidget {
  const _SpecialCasesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Sonderfaelle'),
        ListTile(
          leading: const Icon(Icons.replay_outlined),
          title: const Text('Zurueck zu Moro'),
          subtitle: const Text(
            'Springe zurueck zu Moro. Dein aktuelles Paket bleibt bis zum Abschluss von Moro pausiert.',
            style: TextStyle(fontSize: 12),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _confirmReturnToMoro(context),
        ),
        ListTile(
          leading: const Icon(Icons.delete_outline, color: AppColors.error),
          title: const Text(
            'Account loeschen',
            style: TextStyle(color: AppColors.error),
          ),
          onTap: () => _confirmDeleteAccount(context, ref),
        ),
      ],
    );
  }

  Future<void> _confirmReturnToMoro(BuildContext context) async {
    final first = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Zurueck zu Moro'),
        content: const Text(
          'Du gehst zurueck zu Moro und kannst erst wieder in dein aktuelles Trainingspaket, wenn du Moro abgeschlossen hast.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Weiter'),
          ),
        ],
      ),
    );

    if (first != true || !context.mounted) return;

    final second = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bist du dir sicher?'),
        content: const Text(
          'Moro wird von vorne gestartet. Diese Funktion wird als naechstes technisch angebunden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Nein'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ja, ich bin sicher'),
          ),
        ],
      ),
    );

    if (second == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zurueck zu Moro ist noch nicht aktiv.')),
      );
    }
  }

  Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Account loeschen'),
        content: const Text(
          'Dieser Account wird dauerhaft entfernt. Dies kann nicht rueckgaengig gemacht werden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Loeschen'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await Supabase.instance.client.rpc('delete_user');
      await ref.read(authNotifierProvider.notifier).signOut();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account erfolgreich geloescht')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account konnte nicht geloescht werden')),
        );
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _SegmentedRow<T> extends StatelessWidget {
  const _SegmentedRow({
    required this.options,
    required this.selected,
    required this.label,
    required this.onChanged,
  });

  final List<T> options;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<T>(
      segments: options
          .map((option) => ButtonSegment<T>(
                value: option,
                label: Text(label(option)),
              ))
          .toList(),
      selected: {selected},
      onSelectionChanged: (selection) => onChanged(selection.first),
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: AppColors.primary,
        selectedForegroundColor: Colors.white,
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _SyncStatusTile extends ConsumerWidget {
  const _SyncStatusTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final status = ref.watch(syncStatusProvider).valueOrNull;
    final syncService = ref.read(syncServiceProvider);

    final (icon, color, label) = switch (status) {
      null => (Icons.sync, AppColors.textSecondary, l10n.loading),
      SyncStatus(isSyncing: true) => (
          Icons.sync,
          AppColors.primary,
          l10n.syncInProgress,
        ),
      SyncStatus(hasFailures: true) => (
          Icons.sync_problem,
          AppColors.error,
          l10n.syncStatusFailed(status.failedCount),
        ),
      SyncStatus(hasPending: true) => (
          Icons.sync_disabled,
          AppColors.warning,
          l10n.syncStatusPending(status.pendingCount),
        ),
      _ => (
          Icons.cloud_done_outlined,
          AppColors.success,
          l10n.syncStatusOk,
        ),
    };

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label),
      trailing: TextButton(
        onPressed: status?.isSyncing == true ? null : () => syncService.drain(),
        child: Text(l10n.syncNow),
      ),
    );
  }
}

class _TimePickerTile extends StatelessWidget {
  const _TimePickerTile({
    required this.label,
    required this.time,
    required this.onChanged,
  });

  final String label;
  final TimeOfDay time;
  final ValueChanged<TimeOfDay> onChanged;

  @override
  Widget build(BuildContext context) {
    final formatted =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return ListTile(
      title: Text(label),
      trailing: TextButton(
        onPressed: () async {
          final picked = await showTimePicker(
            context: context,
            initialTime: time,
            builder: (ctx, child) => MediaQuery(
              data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
              child: child!,
            ),
          );
          if (picked != null) onChanged(picked);
        },
        child: Text(
          formatted,
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
