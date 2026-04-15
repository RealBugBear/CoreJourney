import 'package:equatable/equatable.dart';

enum ChannelType { direct, community }

enum MemberRole { member, moderator }

class ChatChannel extends Equatable {
  const ChatChannel({
    required this.id,
    required this.type,
    this.packageId,
    required this.createdAt,
    required this.currentUserRole,
    this.lastMessageContent,
    this.lastMessageAt,
    required this.unreadCount,
  });

  final String id;
  final ChannelType type;
  final String? packageId; // non-null for community channels
  final DateTime createdAt;
  final MemberRole currentUserRole;
  final String? lastMessageContent;
  final DateTime? lastMessageAt;
  final int unreadCount;

  bool get isModerator => currentUserRole == MemberRole.moderator;

  String channelDisplayName({String? packageName}) {
    return switch (type) {
      ChannelType.direct => 'Trainer',
      ChannelType.community => packageName ?? packageId ?? 'Community',
    };
  }

  factory ChatChannel.fromJson(
    Map<String, dynamic> json, {
    required MemberRole currentUserRole,
    String? lastMessageContent,
    DateTime? lastMessageAt,
    int unreadCount = 0,
  }) {
    return ChatChannel(
      id: json['id'] as String,
      type:
          json['type'] == 'direct' ? ChannelType.direct : ChannelType.community,
      packageId: json['package_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      currentUserRole: currentUserRole,
      lastMessageContent: lastMessageContent,
      lastMessageAt: lastMessageAt,
      unreadCount: unreadCount,
    );
  }

  @override
  List<Object?> get props =>
      [id, type, packageId, createdAt, currentUserRole, unreadCount];
}
