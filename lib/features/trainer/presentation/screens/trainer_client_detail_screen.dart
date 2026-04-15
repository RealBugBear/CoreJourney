import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/trainer_client.dart';
import '../providers/trainer_provider.dart';

class TrainerClientDetailScreen extends ConsumerStatefulWidget {
  final String clientId;
  const TrainerClientDetailScreen({super.key, required this.clientId});

  @override
  ConsumerState<TrainerClientDetailScreen> createState() =>
      _TrainerClientDetailScreenState();
}

class _TrainerClientDetailScreenState
    extends ConsumerState<TrainerClientDetailScreen> {
  late TextEditingController _notesController;
  TrainerClient? _client;
  bool _notesDirty = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _initClient(TrainerClient client) {
    if (_client?.clientId == client.clientId) return;
    _client = client;
    _notesController.text = client.trainerNotes ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Find this client from the already-loaded list
    final clientsAsync = ref.watch(trainerClientsProvider);
    final client = clientsAsync.valueOrNull?.firstWhere(
      (c) => c.clientId == widget.clientId,
      orElse: () => TrainerClient(
        relationshipId: '',
        clientId: widget.clientId,
        displayName: 'Client',
        currentDay: 1,
        dailyStreak: 0,
      ),
    );

    if (client != null) _initClient(client);

    final sessionsAsync = ref.watch(clientSessionsProvider(widget.clientId));

    return Scaffold(
      appBar: AppBar(
        title: Text(client?.displayName ?? 'Client'),
      ),
      body: client == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ── KPI strip ──────────────────────────────────────────────
                _KpiStrip(client: client, l10n: l10n),
                const SizedBox(height: 24),

                // ── Recent sessions ────────────────────────────────────────
                Text(
                  l10n.trainerRecentSessions,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                sessionsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text(e.toString(),
                      style: TextStyle(color: AppColors.error)),
                  data: (sessions) => sessions.isEmpty
                      ? Text(
                          l10n.trainerNoSessions,
                          style: TextStyle(color: AppColors.textSecondary),
                        )
                      : _SessionList(sessions: sessions),
                ),
                const SizedBox(height: 24),

                // ── Trainer notes ──────────────────────────────────────────
                Text(
                  l10n.trainerNotes,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesController,
                  maxLines: 6,
                  decoration: InputDecoration(
                    hintText: l10n.trainerNotesHint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (_) => setState(() => _notesDirty = true),
                ),
                const SizedBox(height: 12),
                if (_notesDirty)
                  ElevatedButton(
                    onPressed: () => _saveNotes(context, l10n, client),
                    child: Text(l10n.save),
                  ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Future<void> _saveNotes(
    BuildContext context,
    AppLocalizations l10n,
    TrainerClient client,
  ) async {
    try {
      await ref
          .read(trainerClientsProvider.notifier)
          .saveNotes(client.relationshipId, _notesController.text);
      setState(() => _notesDirty = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.trainerNotesSaved)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorSaveFailed)),
        );
      }
    }
  }
}

class _KpiStrip extends StatelessWidget {
  final TrainerClient client;
  final AppLocalizations l10n;
  const _KpiStrip({required this.client, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _KpiChip(
          icon: Icons.calendar_today_outlined,
          label: l10n.dayNumber(client.currentDay),
          color: AppColors.primary,
        ),
        const SizedBox(width: 8),
        _KpiChip(
          icon: Icons.local_fire_department_outlined,
          label: '${client.dailyStreak} 🔥',
          color: AppColors.warning,
        ),
        const SizedBox(width: 8),
        if (client.packageId != null)
          _KpiChip(
            icon: Icons.fitness_center_outlined,
            label: client.packageId!.toUpperCase(),
            color: AppColors.success,
          ),
      ],
    );
  }
}

class _KpiChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _KpiChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionList extends StatelessWidget {
  final List<ClientSession> sessions;
  const _SessionList({required this.sessions});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: sessions.take(14).map((s) {
        final dayStr =
            '${s.sessionDate.day}.${s.sessionDate.month}.${s.sessionDate.year}';
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            s.isCompleted
                ? Icons.check_circle_outline
                : Icons.radio_button_unchecked,
            color: s.isCompleted ? AppColors.success : AppColors.textDisabled,
            size: 20,
          ),
          title:
              Text('Day ${s.dayNumber}', style: const TextStyle(fontSize: 14)),
          trailing: Text(
            dayStr,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        );
      }).toList(),
    );
  }
}
