import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../assessment/domain/models/reflex_profile_assessment.dart';
import '../../../assessment/domain/reflex_questionnaire.dart';
import '../../../assessment/domain/reflex_questionnaire_definitions.dart';
import '../../domain/models/appointment.dart';
import '../../domain/models/trainer_client.dart';
import '../../../chat/presentation/navigation/chat_navigation.dart';
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
    final appointments = (ref.watch(appointmentsProvider).valueOrNull ?? [])
        .where((appointment) => appointment.traineeId == widget.clientId)
        .toList();
    final observationsAsync =
        ref.watch(trainerClientObservationsProvider(widget.clientId));
    final sharedProfilesAsync =
        ref.watch(trainerClientSharedProfilesProvider(widget.clientId));

    return Scaffold(
      appBar: AppBar(
        title: Text(client?.displayName ?? 'Client'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(
                trainerClientSharedProfilesProvider(widget.clientId)),
          ),
        ],
      ),
      body: client == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ── KPI strip ──────────────────────────────────────────────
                _KpiStrip(client: client, l10n: l10n),
                const SizedBox(height: 12),
                _ClientActionRow(client: client),
                const SizedBox(height: 24),

                Text(
                  'Freigegebene Reflexprofile',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                sharedProfilesAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text(
                    'Profile konnten nicht geladen werden: $e',
                    style: const TextStyle(color: AppColors.error),
                  ),
                  data: (sharedProfiles) => sharedProfiles.isEmpty
                      ? Text(
                          'Keine Profile freigegeben.',
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final profile in sharedProfiles) ...[
                              _SharedProfileHeader(profile: profile),
                              const SizedBox(height: 8),
                              profile.latestAssessment == null
                                  ? Padding(
                                      padding: const EdgeInsets.only(
                                          left: 4, bottom: 16),
                                      child: Text(
                                        'Noch kein abgeschlossenes Reflexprofil.',
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant),
                                      ),
                                    )
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _SharedReflexProfileCard(
                                            assessment:
                                                profile.latestAssessment!),
                                        const SizedBox(height: 12),
                                        _ReflexProfileNotesCard(
                                          assessment: profile.latestAssessment!,
                                          ownerUserId: client.clientId,
                                        ),
                                        const SizedBox(height: 16),
                                      ],
                                    ),
                            ],
                          ],
                        ),
                ),
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
                      style: const TextStyle(color: AppColors.error)),
                  data: (sessions) => sessions.isEmpty
                      ? Text(
                          l10n.trainerNoSessions,
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant),
                        )
                      : _SessionList(sessions: sessions),
                ),
                const SizedBox(height: 24),

                _SectionTitle(
                  title: 'Termine',
                  actionLabel: 'Termin vorschlagen',
                  onAction: () => context.push(
                    Routes.appointmentScheduler
                        .replaceFirst(':clientId', client.clientId),
                    extra: client,
                  ),
                ),
                const SizedBox(height: 8),
                _ClientAppointmentsList(appointments: appointments),
                const SizedBox(height: 24),

                Text(
                  'Beobachtungen',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                observationsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text(
                    e.toString(),
                    style: const TextStyle(color: AppColors.error),
                  ),
                  data: (observations) => observations.isEmpty
                      ? Text(
                          'Noch keine geteilten Beobachtungen.',
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant),
                        )
                      : _ObservationList(observations: observations),
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

class _ReflexProfileNotesCard extends ConsumerStatefulWidget {
  const _ReflexProfileNotesCard({
    required this.assessment,
    required this.ownerUserId,
  });

  final ReflexProfileAssessment assessment;
  final String ownerUserId;

  @override
  ConsumerState<_ReflexProfileNotesCard> createState() =>
      _ReflexProfileNotesCardState();
}

class _ReflexProfileNotesCardState
    extends ConsumerState<_ReflexProfileNotesCard> {
  final _noteController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _addNote() async {
    final body = _noteController.text.trim();
    final subjectProfileId = widget.assessment.subjectProfileId;
    if (body.isEmpty || subjectProfileId == null) return;

    setState(() => _saving = true);
    try {
      await addReflexSubjectProfileNote(
        ref: ref,
        subjectProfileId: subjectProfileId,
        ownerUserId: widget.ownerUserId,
        relatedAssessmentId: widget.assessment.id,
        body: body,
      );
      _noteController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reflexprofil-Notiz gespeichert.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Notiz konnte nicht gespeichert werden: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjectProfileId = widget.assessment.subjectProfileId;
    if (subjectProfileId == null) return const SizedBox.shrink();
    final notesAsync = ref.watch(
      reflexSubjectProfileNotesProvider(subjectProfileId),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.note_alt_outlined, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Reflexprofil-Notizen',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Diese Notizen haften am Profil und sind bei bestehender Freigabe auch fuer spaetere Trainer als Uebergabe sichtbar.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              minLines: 2,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Notiz zur Begleitung oder Uebergabe',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _saving ? null : _addNote,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_comment_outlined),
                label: const Text('Notiz speichern'),
              ),
            ),
            const Divider(height: 28),
            notesAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text(
                'Notizen konnten nicht geladen werden: $e',
                style: const TextStyle(color: AppColors.error),
              ),
              data: (notes) {
                if (notes.isEmpty) {
                  return Text(
                    'Noch keine Reflexprofil-Notizen.',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  );
                }
                return Column(
                  children: [
                    for (final note in notes.take(8))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.sticky_note_2_outlined),
                        title: Text(note.body),
                        subtitle: Text(
                          DateFormat('dd.MM.yyyy · HH:mm', 'de_DE')
                              .format(note.createdAt),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ClientActionRow extends ConsumerWidget {
  const _ClientActionRow({required this.client});

  final TrainerClient client;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        FilledButton.icon(
          onPressed: () =>
              openDirectChatWithUser(context, ref, client.clientId),
          icon: const Icon(Icons.chat_bubble_outline),
          label: const Text('Nachricht'),
        ),
        OutlinedButton.icon(
          onPressed: () => context.push(
            Routes.appointmentScheduler.replaceFirst(
              ':clientId',
              client.clientId,
            ),
            extra: client,
          ),
          icon: const Icon(Icons.event_available_outlined),
          label: const Text('Termin'),
        ),
      ],
    );
  }
}

class _SharedReflexProfileCard extends StatelessWidget {
  const _SharedReflexProfileCard({required this.assessment});

  final ReflexProfileAssessment assessment;

  @override
  Widget build(BuildContext context) {
    final scores = _trainerScoreRows(assessment).toList();
    final safetyRows = _trainerSafetyRows(assessment);
    final warningCount = safetyRows.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  warningCount > 0
                      ? Icons.medical_information_outlined
                      : Icons.assignment_turned_in_outlined,
                  color:
                      warningCount > 0 ? AppColors.warning : AppColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Freigegebene Auswertung',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Abgeschlossen am ${DateFormat('dd.MM.yyyy', 'de_DE').format(assessment.completedAt ?? assessment.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (warningCount > 0) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  warningCount == 1
                      ? '1 bestaetigter Sicherheits-/Ruecksprache-Hinweis. '
                          'Bitte vor und waehrend der Begleitung besonders beachten.'
                      : '$warningCount bestaetigte Sicherheits-/Ruecksprache-Hinweise. '
                          'Bitte vor und waehrend der Begleitung besonders beachten.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                ),
              ),
              const SizedBox(height: 8),
              for (final row in safetyRows)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(
                        child: Text(
                          row,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    height: 1.3,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 12),
            for (final score in scores) _TrainerScoreBar(score: score),
            const SizedBox(height: 8),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Antworten anzeigen'),
              children: [
                for (final entry in assessment.answers.entries)
                  _TrainerAnswerRow(questionId: entry.key, value: entry.value),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TrainerScoreBar extends StatelessWidget {
  const _TrainerScoreBar({required this.score});

  final _TrainerScoreRow score;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(score.label)),
              Text(
                '${score.percent.round()}%',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (score.percent / 100).clamp(0, 1),
              minHeight: 7,
              color: _trainerBandColor(score.band,
                  secondaryColor: cs.onSurfaceVariant),
              backgroundColor: cs.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrainerAnswerRow extends StatelessWidget {
  const _TrainerAnswerRow({
    required this.questionId,
    required this.value,
  });

  final String questionId;
  final dynamic value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 54,
            child: Text(
              questionId,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              _trainerFormatAnswer(value),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrainerScoreRow {
  const _TrainerScoreRow({
    required this.label,
    required this.percent,
    required this.band,
  });

  final String label;
  final double percent;
  final ReflexScoreBand band;
}

List<_TrainerScoreRow> _trainerScoreRows(ReflexProfileAssessment assessment) {
  final rows = <_TrainerScoreRow>[];
  for (final entry in assessment.scores.entries) {
    final raw = entry.value;
    if (raw is! Map) continue;
    rows.add(
      _TrainerScoreRow(
        label: _trainerReflexLabel(entry.key),
        percent: (raw['percent'] as num?)?.toDouble() ?? 0,
        band: _trainerScoreBandFromName(raw['band'] as String? ?? ''),
      ),
    );
  }
  rows.sort((a, b) => b.percent.compareTo(a.percent));
  return rows;
}

List<String> _trainerSafetyRows(ReflexProfileAssessment assessment) {
  final labelById = {
    for (final question in childParentQuestionnaireV1.questions)
      question.id: question.trainerFlagLabel ?? question.text,
  };
  final warningIds = assessment.warningConfirmations
      .whereType<Map>()
      .map((entry) => entry['question_id'] as String?)
      .whereType<String>()
      .toSet();
  const relevantIds = {
    'q061',
    'q109',
    'q110',
    'q111',
    'q112',
  };

  final rows = <String>[];
  for (final id in relevantIds) {
    final answer = assessment.answers[id];
    final isYes = answer is Map && answer['answer'] == 'yes';
    if (!isYes && !warningIds.contains(id)) continue;
    rows.add(labelById[id] ?? id);
  }
  return rows;
}

ReflexScoreBand _trainerScoreBandFromName(String name) {
  return ReflexScoreBand.values.firstWhere(
    (band) => band.name == name,
    orElse: () => ReflexScoreBand.insufficientData,
  );
}

Color _trainerBandColor(ReflexScoreBand band,
        {required Color secondaryColor}) =>
    switch (band) {
      ReflexScoreBand.strong => AppColors.error,
      ReflexScoreBand.elevated => AppColors.warning,
      ReflexScoreBand.indication => AppColors.primary,
      ReflexScoreBand.inconspicuous => AppColors.success,
      ReflexScoreBand.insufficientData => secondaryColor,
    };

String _trainerFormatAnswer(dynamic value) {
  if (value is! Map) return value.toString();
  final parts = <String>[];
  final answer = value['answer'];
  if (answer == 'yes') parts.add('Ja');
  if (answer == 'no') parts.add('Nein');
  if (answer == 'unknown') parts.add('Weiss ich nicht');
  if (value['months'] != null) parts.add('${value['months']} Monate');
  final selected = value['selected_options'];
  if (selected is List && selected.isNotEmpty) {
    parts.add(selected.join(', '));
  }
  final text = value['text'];
  if (text is String && text.trim().isNotEmpty) parts.add(text.trim());
  return parts.isEmpty ? '-' : parts.join(' · ');
}

String _trainerReflexLabel(String key) => switch (key) {
      'delay' => 'Entwicklungsverzoegerung',
      'flr' => 'FLR',
      'moro' => 'Moro',
      'spinalGalant' => 'Spinaler Galant',
      'tlr' => 'TLR',
      'atnr' => 'ATNR',
      'stnr' => 'STNR',
      'landau' => 'Landau',
      'babinski' => 'Babinski',
      'babkin' => 'Babkin',
      'plantar' => 'Plantar',
      'palmar' => 'Palmar',
      'righting' => 'Aufricht',
      'rootingSucking' => 'Such-Saug',
      _ => key,
    };

class _SharedProfileHeader extends StatelessWidget {
  const _SharedProfileHeader({required this.profile});

  final TrainerSharedProfile profile;

  @override
  Widget build(BuildContext context) {
    final age = profile.ageYears != null
        ? ' · ${profile.ageYears} Jahr${profile.ageYears == 1 ? '' : 'e'}'
        : (profile.ageGroup != null ? ' · ${profile.ageGroup}' : '');
    return Row(
      children: [
        const Icon(Icons.person_outline, size: 18),
        const SizedBox(width: 8),
        Text(
          '${profile.displayName}$age',
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        TextButton(
          onPressed: onAction,
          child: Text(actionLabel),
        ),
      ],
    );
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
          icon: Icons.radio_button_checked,
          label: '${client.dailyStreak} Tage',
          color: AppColors.warning,
        ),
        const SizedBox(width: 8),
        if (client.packageId != null)
          _KpiChip(
            icon: Icons.inventory_2_outlined,
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

class _ClientAppointmentsList extends StatelessWidget {
  const _ClientAppointmentsList({required this.appointments});

  final List<Appointment> appointments;

  @override
  Widget build(BuildContext context) {
    if (appointments.isEmpty) {
      return Text(
        'Noch keine geplanten Termine.',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      );
    }

    return Column(
      children: appointments.take(5).map((appointment) {
        final scheduledFor = appointment.scheduledFor;
        final date = scheduledFor == null
            ? 'Termin vorgeschlagen'
            : DateFormat('dd.MM.yyyy · HH:mm', 'de_DE').format(scheduledFor);
        final profileLabel = appointment.profileLabel;
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.event_available_outlined),
          title: Text(appointment.title),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(date),
              if (profileLabel != null)
                Text(
                  'für $profileLabel',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          trailing: _StatusChip(status: appointment.status),
        );
      }).toList(),
    );
  }
}

class _ObservationList extends StatelessWidget {
  const _ObservationList({required this.observations});

  final List<TrainerClientObservation> observations;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: observations.take(8).map((observation) {
        final date = DateFormat('dd.MM.yyyy · HH:mm', 'de_DE')
            .format(observation.recordedAt);
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.edit_note_outlined),
          title: Text(
            observation.note,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(date),
        );
      }).toList(),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      'confirmed' => 'Bestätigt',
      'proposed' => 'Vorschlag',
      'cancelled' => 'Abgesagt',
      'done' => 'Erledigt',
      _ => 'Geplant',
    };
    final color = switch (status) {
      'confirmed' => AppColors.success,
      'cancelled' => AppColors.error,
      'done' => AppColors.textDisabled,
      _ => AppColors.primary,
    };

    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: color.withValues(alpha: 0.28)),
      backgroundColor: color.withValues(alpha: 0.10),
      labelStyle: TextStyle(color: color, fontSize: 12),
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
              Text('Tag ${s.dayNumber}', style: const TextStyle(fontSize: 14)),
          trailing: Text(
            dayStr,
            style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        );
      }).toList(),
    );
  }
}
