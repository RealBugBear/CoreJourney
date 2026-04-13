import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/navigation/app_router.dart';
import '../../domain/models/chat_channel.dart';
import '../providers/chat_providers.dart';

class ChatInboxScreen extends ConsumerWidget {
  const ChatInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channelsAsync = ref.watch(chatChannelsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nachrichten'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(chatChannelsProvider),
          ),
        ],
      ),
      body: channelsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(onRetry: () => ref.invalidate(chatChannelsProvider)),
        data: (channels) {
          if (channels.isEmpty) return const _EmptyState();

          final direct = channels.where((c) => c.type == ChannelType.direct).toList();
          final community = channels.where((c) => c.type == ChannelType.community).toList();

          return ListView(
            children: [
              if (direct.isNotEmpty) ...[
                const _SectionHeader(title: 'Direkt'),
                ...direct.map((c) => _ChannelListTile(channel: c, onTap: () => _open(context, c))),
              ],
              if (community.isNotEmpty) ...[
                const _SectionHeader(title: 'Community'),
                ...community.map((c) => _ChannelListTile(channel: c, onTap: () => _open(context, c))),
              ],
            ],
          );
        },
      ),
    );
  }

  void _open(BuildContext context, ChatChannel channel) {
    context.push(
      Routes.chatChannel.replaceFirst(':channelId', channel.id),
      extra: channel,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Text(
      title,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
        letterSpacing: 0.8,
      ),
    ),
  );
}

class _ChannelListTile extends StatelessWidget {
  const _ChannelListTile({required this.channel, required this.onTap});
  final ChatChannel channel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasUnread = channel.unreadCount > 0;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: channel.type == ChannelType.direct
            ? theme.colorScheme.primary
            : theme.colorScheme.secondary,
        child: Icon(
          channel.type == ChannelType.direct
              ? Icons.person_outline
              : Icons.group_outlined,
          color: Colors.white,
          size: 20,
        ),
      ),
      title: Text(
        channel.channelDisplayName(),
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: channel.lastMessageContent != null
          ? Text(
              channel.lastMessageContent!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: hasUnread
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurface.withValues(alpha: 0.55),
                fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
              ),
            )
          : null,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (channel.lastMessageAt != null)
            Text(
              _formatTime(channel.lastMessageAt!),
              style: theme.textTheme.labelSmall?.copyWith(
                color: hasUnread
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
          if (hasUnread) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                channel.unreadCount > 99 ? '99+' : '${channel.unreadCount}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ],
      ),
      onTap: onTap,
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(dt.year, dt.month, dt.day);
    if (msgDay == today) return DateFormat.Hm().format(dt);
    if (today.difference(msgDay).inDays == 1) return 'Gestern';
    return DateFormat('dd.MM').format(dt);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.25)),
          const SizedBox(height: 16),
          Text('Noch keine Nachrichten',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Verlinke dich mit einem Trainer, um direkte Nachrichten zu nutzen.\n'
            'Community-Channels erscheinen wenn du einem Block beitrittst.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, size: 48),
        const SizedBox(height: 8),
        Text('Fehler beim Laden', style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 8),
        TextButton(onPressed: onRetry, child: const Text('Erneut versuchen')),
      ],
    ),
  );
}
