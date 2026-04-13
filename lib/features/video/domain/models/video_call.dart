import 'package:equatable/equatable.dart';

class VideoCall extends Equatable {
  const VideoCall({
    required this.id,
    required this.channelId,
    required this.agoraChannelName,
    required this.startedBy,
    required this.startedAt,
    this.endedAt,
  });

  final String id;
  final String channelId;
  final String agoraChannelName;
  final String startedBy;
  final DateTime startedAt;
  final DateTime? endedAt;

  bool get isActive => endedAt == null;

  factory VideoCall.fromJson(Map<String, dynamic> json) => VideoCall(
        id: json['id'] as String,
        channelId: json['channel_id'] as String,
        agoraChannelName: json['agora_channel_name'] as String,
        startedBy: json['started_by'] as String,
        startedAt: DateTime.parse(json['started_at'] as String),
        endedAt: json['ended_at'] == null
            ? null
            : DateTime.parse(json['ended_at'] as String),
      );

  @override
  List<Object?> get props =>
      [id, channelId, agoraChannelName, startedBy, startedAt, endedAt];
}
