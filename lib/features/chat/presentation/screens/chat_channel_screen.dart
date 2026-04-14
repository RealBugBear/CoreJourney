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
import '../../../video/domain/models/video_call.dart';
import '../../../video/presentation/providers/video_providers.dart';
import '../../../video/presentation/screens/video_call_screen.dart';
import '../../../trainer/presentation/providers/trainer_provider.dart';
import '../../../../core/navigation/app_router.dart';
import 'package:go_router/go_router.dart';

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

  Future<void> _startCall() async {
    final call = await ref.read(startCallProvider.notifier).start(widget.channelId);
    if (call == null) return;
    final token = await ref
        .read(videoRepositoryProvider)
        .getAgoraToken(call.channelId, call.agoraChannelName);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => VideoCallScreen(call: call, token: token),
      ),
    );
  }

  void _showIncomingCall(VideoCall call) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Eingehender Video-Call'),
        content: const Text(
          'Dein Trainer möchte mit dir sprechen.\nMöchtest du beitreten?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Ignorieren'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final token = await ref
                  .read(videoRepositoryProvider)
                  .getAgoraToken(call.channelId, call.agoraChannelName);
              if (!mounted) return;
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  fullscreenDialog: true,
                  builder: (_) => VideoCallScreen(call: call, token: token),
                ),
              );
            },
            child: const Text('Beitreten'),
          ),
        ],
      ),
    );
  }

  Future<void> _proposeAppointment(BuildContext context, WidgetRef ref) async {
    final partnerIdAsync = ref.read(chatPartnerIdProvider(widget.channelId));
    final clientId = await partnerIdAsync.when(
      data: (id) async => id,
      loading: () async => null,
      error: (_, __) async => null,
    );
    if (clientId == null || !mounted) return;
    context.push(
      Routes.appointmentScheduler.replaceFirst(':clientId', clientId),
    );
  }

  void _showPremiumSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_outlined, size: 48),
            const SizedBox(height: 16),
            Text(
              'Video-Calls sind ein Premium-Feature',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Mit einem Premium-Abo kannst du deinen Trainer direkt per Video-Call erreichen.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Verstanden'),
            ),
          ],
        ),
      ),
    );
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

    // Listen for active calls started by someone else (incoming call for practitioner).
    ref.listen(activeCallProvider(widget.channelId), (prev, next) {
      final call = next.valueOrNull;
      if (call == null) return;
      final currentUserId =
          Supabase.instance.client.auth.currentUser?.id ?? '';
      // Don't show incoming call dialog to the person who started it.
      if (call.startedBy == currentUserId) return;
      // Only show if this is a new call (prev had no active call for this id).
      if (prev?.valueOrNull?.id == call.id) return;
      _showIncomingCall(call);
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(channel?.channelDisplayName() ?? 'Chat'),
        actions: [
          // Trainer: start call + propose appointment
          if (isModerator && channel?.type == ChannelType.direct) ...[
            IconButton(
              icon: const Icon(Icons.event_outlined),
              tooltip: 'Termin vorschlagen',
              onPressed: () => _proposeAppointment(context, ref),
            ),
            IconButton(
              icon: const Icon(Icons.videocam_outlined),
              tooltip: 'Call starten',
              onPressed: _startCall,
            ),
          ],
          // Practitioner (client): request video call (premium gate)
          if (isPractitioner)
            Consumer(builder: (context, ref, _) {
              final tier = ref.watch(subscriptionTierProvider).valueOrNull ?? 'free';
              final isPremium = tier == 'premium';
              return IconButton(
                icon: Icon(
                  isPremium ? Icons.videocam_outlined : Icons.videocam_off_outlined,
                ),
                tooltip: isPremium ? 'Video-Call anfragen' : 'Premium-Feature',
                onPressed: isPremium ? _sendCallRequest : () => _showPremiumSheet(context),
              );
            }),
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
