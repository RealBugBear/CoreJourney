import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../core/database/app_database.dart';
import '../core/sync/sync_service.dart';
import 'bootstrap.dart';

// These are overridden in main with real values from Bootstrap
final appConfigProvider = Provider<AppConfig>((ref) {
  throw UnimplementedError('appConfigProvider must be overridden');
});

final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('databaseProvider must be overridden');
});

final syncServiceProvider = Provider<SyncService>((ref) {
  throw UnimplementedError('syncServiceProvider must be overridden');
});

List<Override> bootstrapOverrides(Bootstrap bootstrap) => [
      appConfigProvider.overrideWithValue(bootstrap.config),
      databaseProvider.overrideWithValue(bootstrap.database),
      syncServiceProvider.overrideWithValue(bootstrap.syncService),
    ];
