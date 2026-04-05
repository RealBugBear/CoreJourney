import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../bootstrap/providers.dart';
import '../../../../core/settings/settings_provider.dart';
import '../../../../core/sync/sync_status.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/trainer/presentation/providers/trainer_provider.dart';
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
        children: [
          // ── Training Feedback ──────────────────────────────────────────────
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
              label: (m) => switch (m) {
                TrainingFeedbackMode.silent => l10n.silentMode,
                TrainingFeedbackMode.haptic => l10n.hapticMode,
                TrainingFeedbackMode.voiceCues => l10n.voiceCuesMode,
              },
              onChanged: notifier.setFeedbackMode,
            ),
          ),

          // ── Weekly Goal ────────────────────────────────────────────────────
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
                          : () => notifier.setWeeklyGoal(settings.weeklyGoal - 1),
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
                          : () => notifier.setWeeklyGoal(settings.weeklyGoal + 1),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── Reminders ─────────────────────────────────────────────────────
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

          // ── Language ──────────────────────────────────────────────────────
          _SectionHeader(title: l10n.settingsLanguage),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _SegmentedRow<String>(
              options: const ['de', 'en'],
              selected: settings.languageCode,
              label: (code) => code == 'de' ? '🇩🇪 Deutsch' : '🇬🇧 English',
              onChanged: notifier.setLanguage,
            ),
          ),

          // ── Appearance ────────────────────────────────────────────────────
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
              label: (m) => switch (m) {
                ThemeMode.system => l10n.themeSystem,
                ThemeMode.light => l10n.themeLight,
                ThemeMode.dark => l10n.themeDark,
              },
              onChanged: notifier.setThemeMode,
            ),
          ),

          // ── Data & Sync ───────────────────────────────────────────────────
          _SectionHeader(title: l10n.settingsDataSync),
          const _SyncStatusTile(),

          // ── Connect to Trainer ────────────────────────────────────────────
          _SectionHeader(title: l10n.settingsConnectTrainer),
          const _ConnectTrainerTile(),

          // ── Account ───────────────────────────────────────────────────────
          _SectionHeader(title: l10n.settingsAccount),

          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(l10n.signOut),
            textColor: AppColors.error,
            iconColor: AppColors.error,
            onTap: () async {
              await ref.read(authNotifierProvider.notifier).signOut();
            },
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

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
  final List<T> options;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onChanged;

  const _SegmentedRow({
    required this.options,
    required this.selected,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<T>(
      segments: options
          .map((o) => ButtonSegment<T>(value: o, label: Text(label(o))))
          .toList(),
      selected: {selected},
      onSelectionChanged: (s) => onChanged(s.first),
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

class _ConnectTrainerTile extends ConsumerStatefulWidget {
  const _ConnectTrainerTile();

  @override
  ConsumerState<_ConnectTrainerTile> createState() => _ConnectTrainerTileState();
}

class _ConnectTrainerTileState extends ConsumerState<_ConnectTrainerTile> {
  final _codeController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _codeController,
              decoration: InputDecoration(
                hintText: l10n.enterInviteCode,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
            ),
          ),
          const SizedBox(width: 8),
          _loading
              ? const SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : ElevatedButton(
                  onPressed: () => _connect(context, l10n),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: Text(l10n.connectToTrainer),
                ),
        ],
      ),
    );
  }

  Future<void> _connect(BuildContext context, AppLocalizations l10n) async {
    final code = _codeController.text.trim();
    if (code.length < 6) return;
    setState(() => _loading = true);
    try {
      await acceptInvite(code);
      _codeController.clear();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.connectToTrainerSuccess)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.connectToTrainerError)),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _TimePickerTile extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final ValueChanged<TimeOfDay> onChanged;

  const _TimePickerTile({
    required this.label,
    required this.time,
    required this.onChanged,
  });

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
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
