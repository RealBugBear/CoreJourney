import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_retry_widget.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/mood_provider.dart';

Future<void> showMoodCheckinSheet(
  BuildContext context, {
  String? enrollmentId,
  MoodCheckinsTableData? initialEntry,
  VoidCallback? onSaved,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => MoodCheckinSheet(
      enrollmentId: enrollmentId,
      initialEntry: initialEntry,
      onSaved: onSaved,
    ),
  );
}

class MoodCheckinSheet extends ConsumerStatefulWidget {
  final String? enrollmentId;
  final MoodCheckinsTableData? initialEntry;
  final VoidCallback? onSaved;

  const MoodCheckinSheet({
    super.key,
    this.enrollmentId,
    this.initialEntry,
    this.onSaved,
  });

  @override
  ConsumerState<MoodCheckinSheet> createState() => _MoodCheckinSheetState();
}

class _MoodCheckinSheetState extends ConsumerState<MoodCheckinSheet> {
  late int? _mood;
  late int? _energy;
  late int? _stress;
  late TextEditingController _noteController;
  bool _saving = false;

  bool get _isEdit => widget.initialEntry != null;

  @override
  void initState() {
    super.initState();
    _mood = widget.initialEntry?.mood;
    _energy = widget.initialEntry?.energy;
    _stress = widget.initialEntry?.stress;
    _noteController =
        TextEditingController(text: widget.initialEntry?.note ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;

    final enrollmentId =
        widget.enrollmentId ?? widget.initialEntry?.enrollmentId;
    if (enrollmentId == null) {
      showErrorSnackBar(context, 'Kein aktives Programm gefunden.');
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = ref.read(moodRepositoryProvider);
      if (_isEdit) {
        await repo.updateCheckin(
          id: widget.initialEntry!.id,
          mood: _mood,
          energy: _energy,
          stress: _stress,
          note: _noteController.text,
        );
      } else {
        await repo.createCheckin(
          enrollmentId: enrollmentId,
          mood: _mood,
          energy: _energy,
          stress: _stress,
          note: _noteController.text,
          source: 'manual',
        );
      }

      if (!mounted) return;
      widget.onSaved?.call();
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        showErrorSnackBar(
            context, AppLocalizations.of(context).errorSaveFailed);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isEdit ? 'Eintrag bearbeiten' : 'Stimmung eintragen',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          _MetricSelector(
            label: l10n.moodLabel,
            emoji: '😊',
            color: AppColors.moodRose,
            value: _mood,
            onChanged: (value) => setState(() => _mood = value),
          ),
          const SizedBox(height: 12),
          _MetricSelector(
            label: l10n.energyLabel,
            emoji: '⚡',
            color: AppColors.moodTeal,
            value: _energy,
            onChanged: (value) => setState(() => _energy = value),
          ),
          const SizedBox(height: 12),
          _MetricSelector(
            label: l10n.stressLabel,
            emoji: '😤',
            color: AppColors.moodGold,
            value: _stress,
            onChanged: (value) => setState(() => _stress = value),
          ),
          const SizedBox(height: 4),
          Text(
            'Tippe auf einen Wert um ihn auszuwählen — oder lass ihn frei.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            minLines: 3,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: l10n.journalPlaceholder,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.save),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricSelector extends StatelessWidget {
  final String label;
  final String emoji;
  final Color color;
  final int? value;
  final ValueChanged<int?> onChanged;

  const _MetricSelector({
    required this.label,
    required this.emoji,
    required this.color,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$emoji $label',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Expanded(
          child: SegmentedButton<int>(
            showSelectedIcon: false,
            emptySelectionAllowed: true,
            style: ButtonStyle(
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                return states.contains(WidgetState.selected)
                    ? color
                    : AppColors.textSecondary;
              }),
            ),
            segments: const [
              ButtonSegment(value: 1, label: Text('1')),
              ButtonSegment(value: 2, label: Text('2')),
              ButtonSegment(value: 3, label: Text('3')),
              ButtonSegment(value: 4, label: Text('4')),
              ButtonSegment(value: 5, label: Text('5')),
            ],
            selected: value != null ? {value!} : {},
            onSelectionChanged: (selection) {
              onChanged(selection.isEmpty ? null : selection.first);
            },
          ),
        ),
      ],
    );
  }
}
