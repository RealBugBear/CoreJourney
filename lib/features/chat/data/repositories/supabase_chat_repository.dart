import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/chat_channel.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';

class SupabaseChatRepository implements ChatRepository {
  SupabaseChatRepository();

  SupabaseClient get _client => Supabase.instance.client;
  String? get _userId => _client.auth.currentUser?.id;

  final _presenceChannels = <String, RealtimeChannel>{};

  // ── Channels ──────────────────────────────────────────────────────────────

  @override
  Future<List<ChatChannel>> getChannels() async {
    final userId = _userId;
    if (userId == null) return [];

    final rows = await _client.rpc(
      'get_channel_list',
      params: {'p_user_id': userId},
    ) as List;

    return rows.map((row) {
      final m = row as Map<String, dynamic>;
      final roleStr = m['member_role'] as String? ?? 'member';
      final role =
          roleStr == 'moderator' ? MemberRole.moderator : MemberRole.member;
      final lastMsgContent = m['last_message_content'] as String?;
      final lastMsgAtStr = m['last_message_at'] as String?;
      final lastMessageAt =
          lastMsgAtStr != null ? DateTime.parse(lastMsgAtStr) : null;
      final unreadCount = (m['unread_count'] as num?)?.toInt() ?? 0;

      return ChatChannel.fromJson(
        m,
        currentUserRole: role,
        lastMessageContent: lastMsgContent,
        lastMessageAt: lastMessageAt,
        unreadCount: unreadCount,
      );
    }).toList();
  }

  @override
  Future<ChatChannel> getOrCreateDirectChannel(String otherUserId) async {
    final userId = _userId;
    if (userId == null) throw StateError('User not authenticated');

    final channelId = await _client.rpc(
      'get_or_create_direct_channel',
      params: {'user_a': userId, 'user_b': otherUserId},
    ) as String;

    final channelJson = await _client
        .from('chat_channels')
        .select()
        .eq('id', channelId)
        .single();

    return ChatChannel.fromJson(
      channelJson,
      currentUserRole: MemberRole.member,
      unreadCount: 0,
    );
  }

  @override
  Future<void> markChannelRead(String channelId) async {
    final userId = _userId;
    if (userId == null) return;

    await _client
        .from('chat_channel_members')
        .update(
          {'last_read_at': DateTime.now().toIso8601String()},
        )
        .eq('channel_id', channelId)
        .eq('user_id', userId);
  }

  // ── Messages ──────────────────────────────────────────────────────────────

  @override
  Stream<List<ChatMessage>> watchMessages(String channelId,
      {int pageSize = 30}) {
    return _client
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('channel_id', channelId)
        .order('created_at', ascending: true)
        .limit(pageSize)
        .map((rows) => rows.map(ChatMessage.fromJson).toList());
  }

  @override
  Future<List<ChatMessage>> fetchOlderMessages(
    String channelId, {
    required DateTime before,
    int limit = 30,
  }) async {
    final rows = await _client
        .from('chat_messages')
        .select()
        .eq('channel_id', channelId)
        .lt('created_at', before.toIso8601String())
        .order('created_at', ascending: false)
        .limit(limit);
    return (rows as List)
        .map((r) => ChatMessage.fromJson(r as Map<String, dynamic>))
        .toList()
        .reversed
        .toList();
  }

  @override
  Future<void> sendMessage(String channelId, String content) async {
    final userId = _userId;
    if (userId == null) return;

    await _client.from('chat_messages').insert({
      'channel_id': channelId,
      'sender_id': userId,
      'content': content,
      'is_bot_response': false,
      'is_call_request': false,
    });

    unawaited(_triggerTriageBot(channelId: channelId, content: content));
  }

  @override
  Future<void> sendCallRequest(String channelId) async {
    final userId = _userId;
    if (userId == null) return;

    await _client.from('chat_messages').insert({
      'channel_id': channelId,
      'sender_id': userId,
      'content': '📹 Video-Call angefragt / Video call requested',
      'is_bot_response': false,
      'is_call_request': true,
    });
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    await _client.from('chat_messages').update(
      {'deleted_at': DateTime.now().toIso8601String()},
    ).eq('id', messageId);
  }

  // ── Typing indicator ──────────────────────────────────────────────────────

  @override
  Future<void> broadcastTyping(String channelId) async {
    final userId = _userId;
    if (userId == null) return;

    final ch = _presenceChannels.putIfAbsent(
      channelId,
      () => _client.channel('typing:$channelId',
          opts: const RealtimeChannelConfig(ack: false))
        ..subscribe(),
    );
    await ch.track(
        {'user_id': userId, 'ts': DateTime.now().millisecondsSinceEpoch});
  }

  @override
  Stream<Set<String>> watchTypingUsers(String channelId) {
    final userId = _userId;
    final controller = StreamController<Set<String>>.broadcast();
    const cutoffMs = Duration(seconds: 10);

    late final RealtimeChannel ch;
    ch = _client
        .channel('presence:typing:$channelId',
            opts: const RealtimeChannelConfig(ack: false))
        .onPresenceSync((payload) {
      final state = ch.presenceState();
      final now = DateTime.now().millisecondsSinceEpoch;
      final active = state
          .expand((s) => s.presences)
          .where((p) {
            final ts = p.payload['ts'] as int?;
            return ts != null && (now - ts) < cutoffMs.inMilliseconds;
          })
          .map((p) => p.payload['user_id'] as String?)
          .whereType<String>()
          .where((id) => id != userId)
          .toSet();
      controller.add(active);
    })
      ..subscribe();

    controller.onCancel = () => ch.unsubscribe();
    return controller.stream;
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<void> _triggerTriageBot({
    required String channelId,
    required String content,
  }) async {
    try {
      final locale =
          _client.auth.currentUser?.userMetadata?['locale'] as String? ?? 'de';
      await _client.functions.invoke(
        'chat-triage-bot',
        body: {'channel_id': channelId, 'content': content, 'locale': locale},
      );
    } catch (e) {
      debugPrint('Triage bot invocation failed: $e');
    }
  }
}
