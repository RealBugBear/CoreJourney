// lib/features/chat/presentation/screens/chat_channel_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/chat_channel.dart';
import '../../domain/models/chat_message.dart';
import '../providers/chat_providers.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input_bar.dart';
import '../widgets/typing_indicator.dart';

class ChatChannelScreen extends ConsumerStatefulWidget {
  const ChatChannelScreen({
    super.key,
    required this.channelId,
    this.channel,
  });

  final String channelId;

  /// Passed from the inbox for instant title display — may be null on deep link.
  final ChatChannel? channel;

  @override
  ConsumerState<ChatChannelScreen> createState() => _ChatChannelScreenState();
}

class _ChatChannelScreenState extends ConsumerState<ChatChannelScreen> {
  final _scrollController = ScrollController();
  bool _loadingOlder = false;
  List<ChatMessage> _olderMessages = [];

  @override
  void initState() {
    super.initState();
    // Mark channel as read when screen opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(markReadProvider.notifier).markRead(widget.channelId);
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels <=
            _scrollController.position.minScrollExtent + 80 &&
        !_loadingOlder) {
      _loadMoreOlder();
    }
  }

  Future<void> _loadMoreOlder() async {
    final messages = ref.read(chatMessagesProvider(widget.channelId)).valueOrNull;
    final allMessages = [..._olderMessages, ...(messages ?? [])];
    if (allMessages.isEmpty) return;

    final oldest = allMessages.reduce((a, b) =>
        a.createdAt.isBefore(b.createdAt) ? a : b);

    setState(() => _loadingOlder = true);
    try {
      final older = await ref
          .read(chatRepositoryProvider)
          .fetchOlderMessages(widget.channelId, before: oldest.createdAt);
      if (older.isNotEmpty) {
        setState(() => _olderMessages = [...older, ..._olderMessages]);
      }
    } finally {
      setState(() => _loadingOlder = false);
    }
  }

  void _sendMessage(String content) {
    ref.read(sendMessageProvider.notifier).send(widget.channelId, content);
    // Scroll to bottom after send.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendCallRequest() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Video-Call anfragen?'),
        content: const Text(
          'Du sendest deinem Trainer eine Anfrage für einen Video-Call. '
          'Der Trainer entscheidet, ob und wann er den Call startet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(sendMessageProvider.notifier)
                  .sendCallRequest(widget.channelId);
            },
            child: const Text('Anfrage senden'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final channel = widget.channel;
    final isModerator = channel?.isModerator ?? false;
    final isPractitioner = !isModerator && channel?.type == ChannelType.direct;

    final messagesAsync = ref.watch(chatMessagesProvider(widget.channelId));

    return Scaffold(
      appBar: AppBar(
        title: Text(channel?.channelDisplayName() ?? 'Chat'),
        actions: [
          // Trainer: start call directly. (Video feature — Task 2 of Plan 2)
          if (isModerator && channel?.type == ChannelType.direct)
            IconButton(
              icon: const Icon(Icons.videocam_outlined),
              tooltip: 'Call starten',
              onPressed: () {
                // Placeholder until Plan 2 (Video Chat) is implemented.
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Video-Chat kommt in Phase 2.')),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Fehler: $e')),
              data: (realtimeMessages) {
                final allMessages = [
                  ..._olderMessages,
                  ...realtimeMessages,
                ];

                if (allMessages.isEmpty) {
                  return Center(
                    child: Text(
                      'Noch keine Nachrichten.\nSchreib die erste!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5),
                          ),
                    ),
                  );
                }

                return Stack(
                  children: [
                    ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: allMessages.length + (_loadingOlder ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (_loadingOlder && index == 0) {
                          return const Padding(
                            padding: EdgeInsets.all(8),
                            child: Center(
                                child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))),
                          );
                        }
                        final msgIndex =
                            _loadingOlder ? index - 1 : index;
                        final msg = allMessages[msgIndex];
                        return MessageBubble(
                          message: msg,
                          isModerator: isModerator,
                          onDeleteRequested: (isModerator ||
                                  msg.isOwnMessage(
                                      _currentUserId()))
                              ? () => _confirmDelete(msg)
                              : null,
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
          TypingIndicator(channelId: widget.channelId),
          MessageInputBar(
            channel: channel ??
                ChatChannel(
                  id: widget.channelId,
                  type: ChannelType.direct,
                  createdAt: DateTime.now(),
                  currentUserRole: MemberRole.member,
                  unreadCount: 0,
                ),
            onSend: _sendMessage,
            onCallRequest: isPractitioner ? _sendCallRequest : null,
            onTyping: () => ref
                .read(chatRepositoryProvider)
                .broadcastTyping(widget.channelId),
          ),
        ],
      ),
    );
  }

  String _currentUserId() {
    return Supabase.instance.client.auth.currentUser?.id ?? '';
  }

  void _confirmDelete(ChatMessage message) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nachricht entfernen?'),
        content: const Text(
            'Die Nachricht wird für alle als entfernt angezeigt.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(deleteMessageProvider.notifier)
                  .delete(message.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Entfernen'),
          ),
        ],
      ),
    );
  }
}
