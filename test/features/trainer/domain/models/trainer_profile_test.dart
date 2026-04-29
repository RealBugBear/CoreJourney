import 'package:flutter_test/flutter_test.dart';
import 'package:corejourney/features/trainer/domain/models/trainer_profile.dart';

void main() {
  group('TrainerProfile.fromJson', () {
    test('parses all fields correctly', () {
      final json = {
        'id': 'abc-123',
        'display_name': 'Max Muster',
        'bio': 'Certified trainer',
        'photo_url': 'https://example.com/photo.jpg',
        'distance_km': 8.0,
        'public_latitude': 52.5200,
        'public_longitude': 13.4050,
        'verified': true,
        'status': 'active',
        'submitted_at': '2026-04-01T10:00:00.000Z',
      };
      final profile = TrainerProfile.fromJson(json);
      expect(profile.id, 'abc-123');
      expect(profile.displayName, 'Max Muster');
      expect(profile.bio, 'Certified trainer');
      expect(profile.photoUrl, 'https://example.com/photo.jpg');
      expect(profile.distanceKm, 8.0);
      expect(profile.publicLatitude, 52.5200);
      expect(profile.publicLongitude, 13.4050);
      expect(profile.verified, true);
      expect(profile.status, TrainerProfileStatus.active);
      expect(profile.submittedAt, DateTime.utc(2026, 4, 1, 10, 0, 0));
    });

    test('nullable fields are null when absent', () {
      final json = {
        'id': 'abc-123',
        'display_name': 'Max Muster',
        'bio': null,
        'photo_url': null,
        'distance_km': null,
        'public_latitude': null,
        'public_longitude': null,
        'verified': false,
        'status': 'pending',
        'submitted_at': '2026-04-01T10:00:00.000Z',
      };
      final profile = TrainerProfile.fromJson(json);
      expect(profile.bio, isNull);
      expect(profile.photoUrl, isNull);
      expect(profile.distanceKm, isNull);
      expect(profile.publicLatitude, isNull);
      expect(profile.publicLongitude, isNull);
    });

    test('unknown status maps to pending', () {
      final json = {
        'id': 'abc-123',
        'display_name': 'Max',
        'bio': null,
        'photo_url': null,
        'distance_km': null,
        'public_latitude': null,
        'public_longitude': null,
        'verified': false,
        'status': 'unknown_future_value',
        'submitted_at': '2026-04-01T10:00:00.000Z',
      };
      final profile = TrainerProfile.fromJson(json);
      expect(profile.status, TrainerProfileStatus.pending);
    });

    test('integer distance_km is coerced to double', () {
      final json = {
        'id': 'abc-123',
        'display_name': 'Max',
        'bio': null,
        'photo_url': null,
        'distance_km': 5,
        'public_latitude': 52.0,
        'public_longitude': 13.0,
        'verified': true,
        'status': 'active',
        'submitted_at': '2026-04-01T10:00:00.000Z',
      };
      final profile = TrainerProfile.fromJson(json);
      expect(profile.distanceKm, 5.0);
    });

    test('legacy nearby rpc rows can omit submitted_at and status', () {
      final json = {
        'id': 'abc-123',
        'display_name': 'Max',
        'bio': null,
        'photo_url': null,
        'distance_km': 5,
        'public_latitude': 52.0,
        'public_longitude': 13.0,
        'verified': true,
      };

      final profile = TrainerProfile.fromJson(json);

      expect(profile.displayName, 'Max');
      expect(profile.status, TrainerProfileStatus.pending);
      expect(profile.submittedAt, DateTime.fromMillisecondsSinceEpoch(0));
    });
  });
}
