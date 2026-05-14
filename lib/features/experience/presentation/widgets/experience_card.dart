import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models/experience_share.dart';

class ExperienceCard extends StatelessWidget {
  final ExperienceShare share;
  final bool isModerator;
  final VoidCallback? onDelete;

  const ExperienceCard({
    super.key,
    required this.share,
    required this.isModerator,
    this.onDelete,
  });

  bool get _isOwn =>
      share.userId == Supabase.instance.client.auth.currentUser?.id;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final timeLabel = _formatRelative(share.createdAt);

    return GestureDetector(
      onLongPress: (isModerator || _isOwn) ? onDelete : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: Text(
                    share.authorLabel.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    share.authorLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  timeLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
                if (isModerator || _isOwn)
                  GestureDetector(
                    onTap: onDelete,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(Icons.more_vert,
                          size: 18, color: cs.onSurfaceVariant),
                    ),
                  ),
              ],
            ),
            // Mood row (only if any value present)
            if (share.mood != null || share.energy != null || share.stress != null) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                children: [
                  if (share.mood != null)
                    _MoodChip(emoji: '😊', value: share.mood!),
                  if (share.energy != null)
                    _MoodChip(emoji: '⚡', value: share.energy!),
                  if (share.stress != null)
                    _MoodChip(emoji: '😤', value: share.stress!),
                ],
              ),
            ],
            // Content text
            if (share.content != null && share.content!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                '"${share.content}"',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(height: 1.45),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatRelative(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'vor ${diff.inMinutes} Min.';
    if (diff.inHours < 24) return 'vor ${diff.inHours} Std.';
    if (diff.inDays == 1) return 'gestern';
    return DateFormat('d. MMM', 'de').format(dt);
  }
}

class _MoodChip extends StatelessWidget {
  final String emoji;
  final int value;
  const _MoodChip({required this.emoji, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('$emoji $value',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }
}
