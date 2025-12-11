import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/database_service.dart';
import '../core/sync/sync_service.dart';

// Providers that will be overridden in bootstrap
final databaseProvider = Provider<DatabaseService>((ref) {
  throw UnimplementedError('Must be overridden in bootstrap');
});

final syncServiceProvider = Provider<SyncService>((ref) {
  throw UnimplementedError('Must be overridden in bootstrap');
});
