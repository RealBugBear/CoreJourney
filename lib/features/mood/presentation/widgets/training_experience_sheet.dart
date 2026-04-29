import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_retry_widget.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../experience/domain/models/experience_share.dart';
import '../../../experience/presentation/providers/experience_providers.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../providers/mood_provider.dart';
import '../../../training/domain/services/experience_prompt_service.dart';

/// Shows the post-training experience bottom sheet and marks the prompt as seen.
Future<void> showTrainingExperienceSheet(
  BuildContext context, {
  required String enrollmentId,
  required String packageId,
}) async {
  await ExperiencePromptService.markShown();
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => ProviderScope(
      child: TrainingExperienceSheet(
        enrollmentId: enrollmentId,
        packageId: packageId,
      ),
    ),
  );
}

class TrainingExperienceSheet extends ConsumerStatefulWidget {
  final String enrollmentId;
  final String packageId;

  const TrainingExperienceSheet({
    super.key,
    required this.enrollmentId,
    required this.packageId,
  });

  @override
  ConsumerState<TrainingExperienceSheet> createState() =>
      _TrainingExperienceSheetState();
}

class _TrainingExperienceSheetState
    extends ConsumerState<TrainingExperienceSheet> {
  int? _mood;
  int? _energy;
  int? _stress;
  final _noteController = TextEditingController();
  bool _shareWithCommunity = false;
  bool _anonymous = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Pre-populate anonymous default from profile.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isAnonDefault =
          ref.read(profileProvider).valueOrNull?.isAnonymousDefault ?? false;
      if (mounted) setState(() => _anonymous = isAnonDefault);
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final repo = ref.read(moodRepositoryProvider);

      // 1. Save mood checkin.
      await repo.createCheckin(
        enrollmentId: widget.enrollmentId,
        mood: _mood,
        energy: _energy,
        stress: _stress,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        source: 'training',
      );

      // 2. Optionally share to community feed.
      if (_shareWithCommunity) {
        final profile = ref.read(profileProvider).valueOrNull;
        final displayName = _anonymous ? 'Anonym' : profile?.effectiveDisplayName ?? 'Anonym';

        await ref.read(experienceRepositoryProvider).createShare(
              ExperienceShareInsert(
                packageId: widget.packageId,
                // Don't link checkinId: the checkin is stored in the local DB and
                // synced to Supabase asynchronously, so the FK would fail if the
                // row isn't replicated yet. Mood values are duplicated on the share.
                userId: Supabase.instance.client.auth.currentUser!.id,
                displayName: displayName,
                isAnonymous: _anonymous,
                content: _noteController.text.trim().isEmpty
                    ? null
                    : _noteController.text.trim(),
                mood: _mood,
                energy: _energy,
                stress: _stress,
              ),
            );
      }

      ref.invalidate(moodDailyAggregatesProvider);
      ref.invalidate(moodNotesProvider);

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, 'Fehler beim Speichern: $e');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 4,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Wie war dein Training heute?',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Hast du Erlebnisse oder Eindrücke rund um das Pränatale Reflexe Training? '
            'Wie geht es dir dabei?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 20),
          _MetricRow(
            label: '😊 Stimmung',
            color: AppColors.moodRose,
            value: _mood,
            onChanged: (v) => setState(() => _mood = v),
          ),
          const SizedBox(height: 10),
          _MetricRow(
            label: '⚡ Energie',
            color: AppColors.moodTeal,
            value: _energy,
            onChanged: (v) => setState(() => _energy = v),
          ),
          const SizedBox(height: 10),
          _MetricRow(
            label: '😤 Stress',
            color: AppColors.moodGold,
            value: _stress,
            onChanged: (v) => setState(() => _stress = v),
          ),
          const SizedBox(height: 4),
          Text(
            'Tippe auf einen Wert um ihn auszuwählen — oder lass ihn frei.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            minLines: 3,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: 'Deine Erfahrung... (optional)',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Mit Community teilen'),
            value: _shareWithCommunity,
            activeColor: AppColors.primary,
            onChanged: (v) => setState(() {
              _shareWithCommunity = v ?? false;
              if (!_shareWithCommunity) _anonymous = false;
            }),
          ),
          if (_shareWithCommunity)
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Anonym teilen'),
                value: _anonymous,
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() => _anonymous = v ?? false),
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(AppLocalizations.of(context).save),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final Color color;
  final int? value;
  final ValueChanged<int?> onChanged;

  const _MetricRow({
    required this.label,
    required this.color,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Expanded(
          child: SegmentedButton<int>(
            showSelectedIcon: false,
            emptySelectionAllowed: true,
            style: ButtonStyle(
              foregroundColor: WidgetStateProperty.resolveWith((states) =>
                  states.contains(WidgetState.selected)
                      ? color
                      : AppColors.textSecondary),
            ),
            segments: const [
              ButtonSegment(value: 1, label: Text('1')),
              ButtonSegment(value: 2, label: Text('2')),
              ButtonSegment(value: 3, label: Text('3')),
              ButtonSegment(value: 4, label: Text('4')),
              ButtonSegment(value: 5, label: Text('5')),
            ],
            selected: value != null ? {value!} : {},
            onSelectionChanged: (sel) =>
                onChanged(sel.isEmpty ? null : sel.first),
          ),
        ),
      ],
    );
  }
}
