import 'dart:developer' as dev;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../core/database/app_database.dart';
import '../core/logging/app_logger.dart';
import '../core/notifications/notification_service.dart';
import '../core/sync/sync_service.dart';

class Bootstrap {
  final AppConfig config;
  final AppDatabase database;
  final SyncService syncService;
  final SharedPreferences prefs;

  Bootstrap._({
    required this.config,
    required this.database,
    required this.syncService,
    required this.prefs,
  });

  // Debug file logger — writes to app Documents so devicectl can read it back.
  static File? _debugFile;
  static void _dbg(String msg) {
    dev.log('[bootstrap] $msg', name: 'cj');
    try {
      _debugFile?.writeAsStringSync('$msg\n', mode: FileMode.append, flush: true);
    } catch (_) {}
  }

  static Future<Bootstrap> initialize({
    required String envFile,
    required AppEnvironment environment,
  }) async {
    dev.log('[bootstrap] ensureInitialized', name: 'cj');
    WidgetsFlutterBinding.ensureInitialized();

    // Set up debug file for offline crash diagnosis
    try {
      final dir = await getApplicationDocumentsDirectory();
      _debugFile = File('${dir.path}/bootstrap_debug.txt');
      await _debugFile!.writeAsString(
        '=== BOOTSTRAP START ${DateTime.now()} ===\n',
      );
    } catch (_) {}
    _dbg('ensureInitialized OK');

    // Load environment variables
    _dbg('loading $envFile');
    await dotenv.load(fileName: envFile);
    _dbg('dotenv loaded');

    final config = AppConfig(
      environment: environment,
      supabaseUrl: dotenv.env['SUPABASE_URL']!,
      supabaseAnonKey: dotenv.env['SUPABASE_ANON_KEY']!,
      revenueCatApiKey: dotenv.env['REVENUECAT_API_KEY'] ?? '',
      adminEmail: dotenv.env['ADMIN_EMAIL'] ?? '',
      trainerCode: dotenv.env['TRAINER_CODE'] ?? '',
    );
    _dbg('AppConfig created, url=${config.supabaseUrl}');

    // Initialize Supabase
    _dbg('Supabase.initialize start');
    final disableDeeplinkSessionDetection = Platform.isIOS &&
        environment == AppEnvironment.development;
    await Supabase.initialize(
      url: config.supabaseUrl,
      anonKey: config.supabaseAnonKey,
      authOptions: FlutterAuthClientOptions(
        detectSessionInUri: !disableDeeplinkSessionDetection,
      ),
    );
    _dbg('Supabase.initialize done');

    // Initialize local database
    _dbg('AppDatabase()');
    final useInMemoryDatabase = Platform.isIOS &&
        environment == AppEnvironment.development;
    final database = useInMemoryDatabase
        ? AppDatabase.inMemory()
        : AppDatabase();
    if (useInMemoryDatabase) {
      _dbg('AppDatabase.inMemory() activated for iOS DEV');
      appLogger.w(
        'AppDatabase: using in-memory fallback on iOS DEV '
        '(path_provider/drift workaround)',
      );
    } else {
      _dbg('AppDatabase() done');
    }

    // Initialize sync service
    _dbg('SyncService()');
    final syncService = SyncService(database);
    _dbg('SyncService() done');

    // Initialize SharedPreferences.
    // iOS 26 beta: the LegacyUserDefaultsApi Pigeon channel fails at runtime.
    // Pre-emptively replace the platform store with an in-memory stub on iOS
    // so getInstance() never hits the broken channel.
    // Settings will not persist across launches on affected builds, which is
    // acceptable for DEV. Remove this block once the channel issue is resolved.
    _dbg('SharedPreferences.getInstance');
    if (Platform.isIOS) {
      // ignore: invalid_use_of_visible_for_testing_member
      SharedPreferences.setMockInitialValues({});
      _dbg('SharedPreferences: iOS in-memory stub activated');
      appLogger.w('SharedPreferences: using in-memory stub on iOS (channel workaround)');
    }
    final prefs = await SharedPreferences.getInstance();
    _dbg('SharedPreferences done');

    // Initialize local notifications — wrapped so a native plugin crash on
    // iOS 26 beta does not kill the entire bootstrap.
    _dbg('NotificationService.initialize start');
    final enableIosProfileNotifications =
        dotenv.env['ENABLE_IOS_PROFILE_NOTIFICATIONS'] == 'true';
    final skipNotificationInit =
        Platform.isIOS && kProfileMode && !enableIosProfileNotifications;
    if (skipNotificationInit) {
      NotificationService.instance.disable(
        'safe mode on iOS profile build '
        '(set ENABLE_IOS_PROFILE_NOTIFICATIONS=true to override)',
      );
      _dbg('NotificationService.initialize skipped for iOS/profile safe mode');
    } else {
      try {
        await NotificationService.instance.initialize();
        _dbg('NotificationService.initialize done');
      } catch (e) {
        _dbg('NotificationService.initialize FAILED: $e');
        appLogger.w('NotificationService init skipped: $e');
      }
    }

    appLogger.i('Bootstrap complete [${config.envLabel}]');
    _dbg('BOOTSTRAP COMPLETE');

    return Bootstrap._(
      config: config,
      database: database,
      syncService: syncService,
      prefs: prefs,
    );
  }
}
