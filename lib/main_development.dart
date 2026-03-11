import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bootstrap/bootstrap.dart';
import 'config/app_config.dart';
import 'core/app/corejourney_app.dart';

void main() async {
  // Set development configuration
  AppConfig.setConfig(AppConfig.development);

  try {
    // Bootstrap app with dev environment
    final result = await bootstrapApp(
      env: 'dev',
    ).timeout(const Duration(seconds: 30));

    runApp(
      ProviderScope(
        overrides: result.toOverrides(),
        child: const CoreJourneyApp(),
      ),
    );
  } catch (error, stackTrace) {
    debugPrint('Dev bootstrap failed: $error');
    debugPrint('$stackTrace');

    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Startup failed in development mode:\n$error',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
