import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../core/database/database_service.dart';
import '../core/sync/sync_service.dart';
import '../core/feature_flags/feature_flag_service.dart';
import '../core/feature_flags/feature_flag_provider.dart';
import '../core/analytics/analytics_service.dart';
import '../core/analytics/analytics_provider.dart';
import '../core/logging/logger_service.dart';
import '../core/logging/logger_provider.dart';
import '../core/services/notification_service.dart';
import '../firebase_options.dart' as dev;
import '../firebase_options_prod.dart' as prod;
import 'providers.dart';

class BootstrapResult {
  final DatabaseService database;
  final SyncService sync;
  final SharedPreferences sharedPreferences;
  final FeatureFlagService featureFlags;
  final AnalyticsService analytics;
  final LoggerService logger;

  BootstrapResult({
    required this.database,
    required this.sync,
    required this.sharedPreferences,
    required this.featureFlags,
    required this.analytics,
    required this.logger,
  });

  List<Override> toOverrides() {
    return [
      databaseProvider.overrideWithValue(database),
      syncServiceProvider.overrideWithValue(sync),
      sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      featureFlagServiceProvider.overrideWithValue(featureFlags),
      analyticsServiceProvider.overrideWithValue(analytics),
      loggerServiceProvider.overrideWithValue(logger),
    ];
  }
}

Future<BootstrapResult> bootstrapApp({String env = 'dev'}) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment
  await dotenv.load(fileName: '.env.$env');

  // Get current config for initialization
  final config = AppConfig.current;

  // Initialize Firebase (handle duplicate initialization gracefully)
  try {
    await Firebase.initializeApp(
      options: env == 'prod'
        ? prod.DefaultFirebaseOptions.currentPlatform
        : dev.DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('[Bootstrap] Firebase initialized');
  } catch (e) {
    // Firebase may already be initialized by native iOS/Android code
    // This is okay, we can continue
    debugPrint('[Bootstrap] Firebase already initialized: $e');
  }

  // Initialize Logger (before other services so we can use it)
  final logger = LoggerService(config: config);
  logger.info('Bootstrapping app', data: {
    'environment': config.environment.name,
    'version': env,
  });

  // Initialize Crashlytics
  if (config.enableCrashReporting) {
    try {
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      logger.info('Crashlytics enabled');
    } catch (e) {
      logger.warning('Failed to initialize Crashlytics', error: e);
    }
  }

  // Initialize Performance Monitoring
  if (config.enablePerformanceMonitoring) {
    try {
      final performance = FirebasePerformance.instance;
      await performance.setPerformanceCollectionEnabled(true);
      logger.info('Performance monitoring enabled');
    } catch (e) {
      logger.warning('Failed to initialize Performance Monitoring', error: e);
    }
  }

  // Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  logger.debug('SharedPreferences initialized');

  // Initialize Analytics
  final analytics = AnalyticsService(
    analytics: FirebaseAnalytics.instance,
    config: config,
  );
  await analytics.initialize();
  
  // Initialize Database
  final database = DatabaseService();
  await database.init();
  logger.info('Database initialized');

  // Initialize Sync Service with Firebase
  final sync = SyncService(
    database,
    firestore: FirebaseFirestore.instance,
  );
  sync.init();
  logger.info('Sync service initialized');

  // Initialize Feature Flags
  final featureFlags = FeatureFlagService(
    remoteConfig: FirebaseRemoteConfig.instance,
    prefs: sharedPreferences,
    config: config,
  );
  await featureFlags.initialize();
  logger.info('Feature flags initialized');

  // Initialize Notification Service
  final notificationService = NotificationService();
  await notificationService.init();
  await notificationService.requestPermissions();
  logger.info('Notification service initialized');

  logger.info('Bootstrap complete');

  return BootstrapResult(
    database: database,
    sync: sync,
    sharedPreferences: sharedPreferences,
    featureFlags: featureFlags,
    analytics: analytics,
    logger: logger,
  );
}
