import 'package:flutter_test/flutter_test.dart';
import 'package:corejourney/features/trainer/domain/models/trainer_discovery_request.dart';

void main() {
  group('TrainerDiscoveryRequest.fromJson', () {
    test('parses all fields correctly', () {
      final json = {
        'relationship_id': 'rel-123',
        'client_id': 'client-456',
        'display_name': 'Anna Müller',
        'created_at': '2026-04-27T09:00:00.000Z',
      };
      final req = TrainerDiscoveryRequest.fromJson(json);
      expect(req.relationshipId, 'rel-123');
      expect(req.clientId, 'client-456');
      expect(req.displayName, 'Anna Müller');
      expect(req.createdAt, DateTime.utc(2026, 4, 27, 9, 0, 0));
    });
  });
}
