import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../core/database/app_database.dart';
import '../core/logging/app_logger.dart';
import '../core/sync/sync_service.dart';
import '../firebase_options.dart';

class Bootstrap {
  final AppConfig config;
  final AppDatabase database;
  final SyncService syncService;

  Bootstrap._({
    required this.config,
    required this.database,
    required this.syncService,
  });

  static Future<Bootstrap> initialize({
    required String envFile,
    required AppEnvironment environment,
  }) async {
    WidgetsFlutterBinding.ensureInitialized();

    // Load environment variables
    await dotenv.load(fileName: envFile);

    final config = AppConfig(
      environment: environment,
      supabaseUrl: dotenv.env['SUPABASE_URL']!,
      supabaseAnonKey: dotenv.env['SUPABASE_ANON_KEY']!,
      revenueCatApiKey: dotenv.env['REVENUECAT_API_KEY'] ?? '',
    );

    // Initialize Supabase
    await Supabase.initialize(
      url: config.supabaseUrl,
      anonKey: config.supabaseAnonKey,
    );

    // Initialize Firebase (Analytics + Crashlytics)
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      appLogger.w('Firebase initialization failed: $e');
    }

    // Initialize local database
    final database = AppDatabase();

    // Initialize sync service
    final syncService = SyncService(database);

    appLogger.i('Bootstrap complete [${config.envLabel}]');

    return Bootstrap._(
      config: config,
      database: database,
      syncService: syncService,
    );
  }
}
