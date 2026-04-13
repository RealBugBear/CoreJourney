import 'package:flutter_test/flutter_test.dart';
import 'package:corejourney/features/video/domain/models/video_call.dart';

void main() {
  const activeJson = <String, dynamic>{
    'id': 'call-1',
    'channel_id': 'channel-1',
    'agora_channel_name': 'cj_abc12345_1712345678000',
    'started_by': 'user-trainer',
    'started_at': '2026-04-14T10:00:00.000Z',
    'ended_at': null,
  };

  final endedJson = <String, dynamic>{
    ...activeJson,
    'ended_at': '2026-04-14T10:30:00.000Z',
  };

  group('VideoCall — fromJson', () {
    test('parses all fields correctly', () {
      final call = VideoCall.fromJson(activeJson);
      expect(call.id, 'call-1');
      expect(call.channelId, 'channel-1');
      expect(call.agoraChannelName, 'cj_abc12345_1712345678000');
      expect(call.startedBy, 'user-trainer');
      expect(call.endedAt, isNull);
    });

    test('parses ended_at when set', () {
      final call = VideoCall.fromJson(endedJson);
      expect(call.endedAt, isNotNull);
    });
  });

  group('VideoCall — isActive', () {
    test('true when endedAt is null', () {
      final call = VideoCall.fromJson(activeJson);
      expect(call.isActive, isTrue);
    });

    test('false when endedAt is set', () {
      final call = VideoCall.fromJson(endedJson);
      expect(call.isActive, isFalse);
    });
  });

  group('VideoCall — Equatable', () {
    test('equal when same fields', () {
      final a = VideoCall.fromJson(activeJson);
      final b = VideoCall.fromJson(activeJson);
      expect(a, equals(b));
    });

    test('unequal when endedAt differs', () {
      final a = VideoCall.fromJson(activeJson);
      final b = VideoCall.fromJson(endedJson);
      expect(a, isNot(equals(b)));
    });
  });
}
