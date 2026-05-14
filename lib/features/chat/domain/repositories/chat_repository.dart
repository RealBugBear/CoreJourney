import '../models/chat_channel.dart';
import '../models/chat_message.dart';

abstract class ChatRepository {
  // ── Channels ──────────────────────────────────────────────────────────────

  Future<List<ChatChannel>> getChannels();

  Future<ChatChannel> getOrCreateDirectChannel(String otherUserId);

  Future<void> markChannelRead(String channelId);

  // ── Messages ──────────────────────────────────────────────────────────────

  /// Real-time stream of the most recent [pageSize] messages.
  /// Implementations should include a polling fallback because Supabase
  /// Realtime can be disabled per table in some environments.
  Stream<List<ChatMessage>> watchMessages(String channelId,
      {int pageSize = 30});

  /// Streams recent video-call request messages visible to the current user.
  /// Used for app-wide trainer prompts when a client asks for a call.
  Stream<List<ChatMessage>> watchCallRequests();

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
