import 'package:equatable/equatable.dart';

class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.channelId,
    required this.senderId,
    required this.content,
    required this.isBotResponse,
    required this.isCallRequest,
    this.deletedAt,
    required this.createdAt,
  });

  final String id;
  final String channelId;
  final String senderId;
  final String content;
  final bool isBotResponse;
  final bool isCallRequest;
  final DateTime? deletedAt;    // non-null = soft-deleted
  final DateTime createdAt;

  bool get isDeleted => deletedAt != null;

  bool isOwnMessage(String currentUserId) => senderId == currentUserId;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      channelId: json['channel_id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String,
      isBotResponse: json['is_bot_response'] as bool? ?? false,
      isCallRequest: json['is_call_request'] as bool? ?? false,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  List<Object?> get props => [id, channelId, senderId, content,
      isBotResponse, isCallRequest, deletedAt, createdAt];
}
