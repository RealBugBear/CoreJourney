import 'package:corejourney/features/assessment/domain/draft_persistence_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DraftPersistenceService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service = DraftPersistenceService();
  });

  group('DraftPersistenceService', () {
    test('saveLocal + loadLocal round-trip preserves all fields', () async {
      final draft = {
        'saved_at': '2026-05-14T10:00:00.000Z',
        'answers': {
          '__meta': {'module_index': 2, 'questionnaire_for': 'child'},
          'q001': {'yesNoUnknown': true},
        },
        'warning_confirmations': <dynamic>[],
      };

      await service.saveLocal('profile-1', draft);
      final loaded = await service.loadLocal('profile-1');

      expect(loaded, equals(draft));
    });

    test('loadLocal returns null when nothing saved', () async {
      final result = await service.loadLocal('unknown-profile');
      expect(result, isNull);
    });

    test('clearLocal removes the draft', () async {
      await service.saveLocal('profile-1', {'saved_at': '2026-01-01T00:00:00Z'});
      await service.clearLocal('profile-1');
      final result = await service.loadLocal('profile-1');
      expect(result, isNull);
    });

    test('different profile IDs are stored independently', () async {
      await service.saveLocal('profile-a', {'saved_at': '2026-01-01T00:00:00Z', 'x': 1});
      await service.saveLocal('profile-b', {'saved_at': '2026-01-01T00:00:00Z', 'x': 2});

      final a = await service.loadLocal('profile-a');
      final b = await service.loadLocal('profile-b');

      expect(a!['x'], 1);
      expect(b!['x'], 2);
    });

    test('clearLocal only removes the targeted profile draft', () async {
      await service.saveLocal('profile-a', {'saved_at': '2026-01-01T00:00:00Z'});
      await service.saveLocal('profile-b', {'saved_at': '2026-01-01T00:00:00Z'});

      await service.clearLocal('profile-a');

      expect(await service.loadLocal('profile-a'), isNull);
      expect(await service.loadLocal('profile-b'), isNotNull);
    });

    test('loadLocal returns null and clears corrupt JSON', () async {
      SharedPreferences.setMockInitialValues({
        'reflex_draft_corrupt-profile': 'this is not valid json{{{',
      });
      final service2 = DraftPersistenceService();

      final result = await service2.loadLocal('corrupt-profile');
      expect(result, isNull);

      // Draft should be cleared after corrupt read
      final afterClear = await service2.loadLocal('corrupt-profile');
      expect(afterClear, isNull);
    });

    test('saveLocal is idempotent — overwrites previous draft', () async {
      await service.saveLocal('profile-1', {'saved_at': '2026-01-01T00:00:00Z', 'v': 1});
      await service.saveLocal('profile-1', {'saved_at': '2026-01-01T00:00:00Z', 'v': 2});

      final loaded = await service.loadLocal('profile-1');
      expect(loaded!['v'], 2);
    });
  });
}
