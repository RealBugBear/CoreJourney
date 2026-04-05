import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/time/app_clock_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_retry_widget.dart';
import '../../../mood/presentation/providers/mood_provider.dart';
import '../../../mood/presentation/widgets/mood_checkin_sheet.dart';
import '../../../progress/presentation/providers/progress_provider.dart';
import '../providers/journal_provider.dart';
import '../widgets/journal_entry_tile.dart';

class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(journalProvider);
    final enrollmentId = ref.watch(activeEnrollmentProvider).valueOrNull?.id;
    final now = ref.watch(appClockProvider).now();
    final entriesThisWeek = state.entries
        .where(
          (entry) => entry.recordedAt.isAfter(
            now.subtract(const Duration(days: 7)),
          ),
        )
        .length;

    return Scaffold(
      appBar: AppBar(title: const Text('Tagebuch')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showMoodCheckinSheet(
          context,
          enrollmentId: enrollmentId,
          onSaved: () {
            ref.read(journalProvider.notifier).load();
            ref.invalidate(moodDailyAggregatesProvider);
            ref.invalidate(moodNotesProvider);
          },
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit_note),
        label: const Text('Eintrag'),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? ErrorRetryWidget(
                  message: 'Einträge konnten nicht geladen werden.',
                  onRetry: () => ref.read(journalProvider.notifier).load(),
                )
              : RefreshIndicator(
                  onRefresh: () => ref.read(journalProvider.notifier).load(),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                    children: [
                      _JournalTopBar(
                        entryCount: state.entries.length,
                        entriesThisWeek: entriesThisWeek,
                        monthLabel: DateFormat('MMM yyyy', 'de').format(now),
                      ),
                      const SizedBox(height: 6),
                      if (state.entries.isEmpty)
                        const _EmptyJournalState()
                      else
                        ...state.entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: JournalEntryTile(
                              entry: entry,
                              onDeleted: () => ref
                                  .read(journalProvider.notifier)
                                  .deleteEntry(entry.id),
                              onChanged: () =>
                                  ref.read(journalProvider.notifier).load(),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}

class _JournalTopBar extends StatelessWidget {
  final int entryCount;
  final int entriesThisWeek;
  final String monthLabel;

  const _JournalTopBar({
    required this.entryCount,
    required this.entriesThisWeek,
    required this.monthLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Einträge',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              Text(
                '$entryCount gesamt · $entriesThisWeek Woche',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          monthLabel,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
        ),
      ],
    );
  }
}

class _EmptyJournalState extends StatelessWidget {
  const _EmptyJournalState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            'Noch keine Einträge',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Deine Notizen erscheinen hier als kompakte Timeline. Der Verlauf bleibt im Dashboard.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
          ),
        ],
      ),
    );
  }
}
