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

    final memberships = await _client
        .from('chat_channel_members')
        .select('role, last_read_at, channel_id, chat_channels(*)')
        .eq('user_id', userId);

    final channels = <ChatChannel>[];

    for (final m in memberships as List) {
      final roleStr = m['role'] as String? ?? 'member';
      final role = roleStr == 'moderator' ? MemberRole.moderator : MemberRole.member;

      final lastReadAtStr = m['last_read_at'] as String?;
      final lastReadAt = lastReadAtStr != null
          ? DateTime.parse(lastReadAtStr)
          : DateTime.fromMillisecondsSinceEpoch(0);

      final channelJson = m['chat_channels'] as Map<String, dynamic>;
      final channelId = channelJson['id'] as String;

      // Fetch last message
      final lastMsgRow = await _client
          .from('chat_messages')
          .select('content, created_at')
          .eq('channel_id', channelId)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      final lastMessageContent = lastMsgRow?['content'] as String?;
      final lastMessageAt = lastMsgRow != null
          ? DateTime.parse(lastMsgRow['created_at'] as String)
          : null;

      // Fetch unread count
      final unreadCount = await _client
          .from('chat_messages')
          .count(CountOption.exact)
          .eq('channel_id', channelId)
          .gt('created_at', lastReadAt.toIso8601String())
          .neq('sender_id', userId);

      channels.add(ChatChannel.fromJson(
        channelJson,
        currentUserRole: role,
        lastMessageContent: lastMessageContent,
        lastMessageAt: lastMessageAt,
        unreadCount: unreadCount,
      ));
    }

    // Sort: direct channels first, then community; within each group sort by
    // lastMessageAt descending (nulls last)
    channels.sort((a, b) {
      if (a.type != b.type) {
        return a.type == ChannelType.direct ? -1 : 1;
      }
      final aTime = a.lastMessageAt;
      final bTime = b.lastMessageAt;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });

    return channels;
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
  Future<void> joinCommunityChannel(String packageId) async {
    final userId = _userId;
    if (userId == null) return;

    final channelRow = await _client
        .from('chat_channels')
        .select('id')
        .eq('type', 'community')
        .eq('package_id', packageId)
        .maybeSingle();

    if (channelRow == null) return;
    final channelId = channelRow['id'] as String;

    final profileRow = await _client
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .single();

    final profileRole = profileRow['role'] as String? ?? 'member';
    final memberRole = profileRole == 'trainer' ? 'moderator' : 'member';

    await _client.from('chat_channel_members').upsert(
      {
        'channel_id': channelId,
        'user_id': userId,
        'role': memberRole,
        'joined_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'channel_id,user_id',
    );
  }

  @override
  Future<void> markChannelRead(String channelId) async {
    final userId = _userId;
    if (userId == null) return;

    await _client.from('chat_channel_members').update(
      {'last_read_at': DateTime.now().toIso8601String()},
    ).eq('channel_id', channelId).eq('user_id', userId);
  }

  // ── Messages ──────────────────────────────────────────────────────────────

  @override
  Stream<List<ChatMessage>> watchMessages(String channelId, {int pageSize = 30}) {
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
      () => _client
          .channel('typing:$channelId', opts: const RealtimeChannelConfig(ack: false))
        ..subscribe(),
    );
    await ch.track({'user_id': userId, 'ts': DateTime.now().millisecondsSinceEpoch});
  }

  @override
  Stream<Set<String>> watchTypingUsers(String channelId) {
    final userId = _userId;
    final controller = StreamController<Set<String>>.broadcast();
    const cutoffMs = Duration(seconds: 10);

    late final RealtimeChannel ch;
    ch = _client
        .channel('presence:typing:$channelId', opts: const RealtimeChannelConfig(ack: false))
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
