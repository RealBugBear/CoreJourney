import '../models/chat_channel.dart';
import '../models/chat_message.dart';

abstract class ChatRepository {
  // ── Channels ──────────────────────────────────────────────────────────────

  Future<List<ChatChannel>> getChannels();

  Future<ChatChannel> getOrCreateDirectChannel(String otherUserId);

  Future<void> joinCommunityChannel(String packageId);

  Future<void> markChannelRead(String channelId);

  // ── Messages ──────────────────────────────────────────────────────────────

  /// Real-time stream of the most recent [pageSize] messages.
  Stream<List<ChatMessage>> watchMessages(String channelId, {int pageSize = 30});

  /// Load messages older than [before] for infinite scroll.
  Future<List<ChatMessage>> fetchOlderMessages(
    String channelId, {
    required DateTime before,
    int limit = 30,
  });

  Future<void> sendMessage(String channelId, String content);

  /// Sends a call-request message. Only Practitioners call this.
  Future<void> sendCallRequest(String channelId);

  Future<void> deleteMessage(String messageId);

  // ── Typing indicator ──────────────────────────────────────────────────────

  Future<void> broadcastTyping(String channelId);

  Stream<Set<String>> watchTypingUsers(String channelId);
}
