import 'package:corejourney/features/experience/domain/models/experience_share.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExperienceShare', () {
    final json = {
      'id': 'share-1',
      'package_id': 'pkg-a',
      'mood_checkin_id': null,
      'user_id': 'user-1',
      'display_name': 'Maria',
      'is_anonymous': false,
      'content': 'Tolles Training!',
      'mood': 4,
      'energy': null,
      'stress': null,
      'created_at': '2026-04-21T10:00:00.000Z',
    };

    test('fromJson parses correctly', () {
      final s = ExperienceShare.fromJson(json);
      expect(s.id, 'share-1');
      expect(s.displayName, 'Maria');
      expect(s.isAnonymous, false);
      expect(s.authorLabel, 'Maria');
      expect(s.mood, 4);
      expect(s.content, 'Tolles Training!');
    });

    test('authorLabel returns Anonym when is_anonymous=true', () {
      final s = ExperienceShare.fromJson({...json, 'is_anonymous': true});
      expect(s.authorLabel, 'Anonym');
    });
  });
}
