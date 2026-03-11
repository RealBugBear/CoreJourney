import 'package:corejourney/core/database/database_service.dart';
import 'package:corejourney/core/sync/models/sync_job.dart';
import 'package:corejourney/core/sync/sync_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDatabaseService extends Mock implements DatabaseService {}

void main() {
  late SyncService service;

  setUp(() {
    service = SyncService(_MockDatabaseService());
  });

  group('SyncService coalescing helpers', () {
    test('detects pending delete among existing jobs', () {
      final jobs = [
        SyncJob()
          ..collection = 'progress'
          ..docId = 'a'
          ..action = 'update'
          ..payload = '{"a":1}'
          ..createdAt = DateTime(2026, 1, 1),
        SyncJob()
          ..collection = 'progress'
          ..docId = 'a'
          ..action = 'delete'
          ..payload = '{}'
          ..createdAt = DateTime(2026, 1, 1),
      ];

      final hasDelete = service.hasPendingDeleteForTesting(jobs);

      expect(hasDelete, isTrue);
    });

    test('coalesced action stays create when pending create exists', () {
      final action = service.resolveCoalescedActionForTesting(
        hasPendingCreate: true,
        incomingAction: 'update',
      );

      expect(action, 'create');
    });

    test('incoming create promotes coalesced action to create', () {
      final action = service.resolveCoalescedActionForTesting(
        hasPendingCreate: false,
        incomingAction: 'create',
      );

      expect(action, 'create');
    });

    test('coalesced action is update when no create is involved', () {
      final action = service.resolveCoalescedActionForTesting(
        hasPendingCreate: false,
        incomingAction: 'update',
      );

      expect(action, 'update');
    });

    test('payload merge keeps latest values from incoming payload', () {
      final merged = service.mergePayloadsForTesting(
        const ['{"a":1,"b":2}', '{"b":3,"c":4}'],
        {'c': 9, 'd': 10},
      );

      expect(merged['a'], 1);
      expect(merged['b'], 3);
      expect(merged['c'], 9);
      expect(merged['d'], 10);
    });
  });
}
