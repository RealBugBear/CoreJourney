import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../mood/presentation/widgets/mood_checkin_sheet.dart';

class JournalEntryTile extends ConsumerStatefulWidget {
  final MoodCheckinsTableData entry;
  final VoidCallback onDeleted;
  final VoidCallback onChanged;

  const JournalEntryTile({
    super.key,
    required this.entry,
    required this.onDeleted,
    required this.onChanged,
  });

  @override
  ConsumerState<JournalEntryTile> createState() => _JournalEntryTileState();
}

class _JournalEntryTileState extends ConsumerState<JournalEntryTile> {
  bool _expanded = false;

  Future<bool> _confirmDelete() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eintrag löschen?'),
        content: const Text('Dieser Eintrag wird dauerhaft entfernt.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final dayText = DateFormat('dd', 'de').format(entry.recordedAt);
    final monthText = DateFormat('MMM', 'de').format(entry.recordedAt);
    final timeText = DateFormat('HH:mm', 'de').format(entry.recordedAt);
    final note = entry.note?.trim() ?? '';
    final hasLongText = note.length > 180;
    final shownText =
        hasLongText && !_expanded ? '${note.substring(0, 180)}…' : note;

    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(),
      onDismissed: (_) => widget.onDeleted(),
      background: Container(
        decoration: BoxDecoration(
          color: Colors.red.shade600,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => showMoodCheckinSheet(
            context,
            initialEntry: entry,
            onSaved: widget.onChanged,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 44,
                  child: Column(
                    children: [
                      Text(
                        dayText,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  height: 1,
                                ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        monthText,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 2,
                      height: note.isEmpty ? 82 : 108,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: AppColors.divider,
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(0, 1, 0, 8),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.divider),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              timeText,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.edit_outlined,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const Spacer(),
                            if (note.isNotEmpty)
                              const Text(
                                'Notiz',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _metricChip(
                                '😊', 'Mood', entry.mood, AppColors.moodRose),
                            _metricChip('⚡', 'Energy', entry.energy,
                                AppColors.moodTeal),
                            _metricChip('😤', 'Stress', entry.stress,
                                AppColors.moodGold),
                          ].whereType<Widget>().toList(),
                        ),
                        if (note.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            shownText,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  height: 1.4,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                          if (hasLongText) ...[
                            const SizedBox(height: 4),
                            TextButton(
                              onPressed: () =>
                                  setState(() => _expanded = !_expanded),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 28),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                _expanded
                                    ? 'Weniger anzeigen'
                                    : 'Mehr anzeigen',
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget? _metricChip(String emoji, String label, int? value, Color color) {
    if (value == null) return null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$emoji $value',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
