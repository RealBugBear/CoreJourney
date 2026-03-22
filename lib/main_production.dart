import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'bootstrap/bootstrap.dart';
import 'bootstrap/providers.dart';
import 'config/app_config.dart';

void main() async {
  final bootstrap = await Bootstrap.initialize(
    envFile: '.env.prod',
    environment: AppEnvironment.production,
  );

  // Route all uncaught errors to Crashlytics in production
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  bootstrap.syncService.start();

  runApp(
    ProviderScope(
      overrides: bootstrapOverrides(bootstrap),
      child: const CoreJourneyApp(),
    ),
  );
}
