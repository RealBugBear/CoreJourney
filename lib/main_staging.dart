import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bootstrap/bootstrap.dart';
import 'config/app_config.dart';
import 'core/app/corejourney_app.dart';

void main() async {
  // Set staging configuration
  AppConfig.setConfig(AppConfig.staging);

  // Bootstrap app with staging environment
  final result = await bootstrapApp(env: 'staging');

  runApp(
    ProviderScope(
      overrides: result.toOverrides(),
      child: const CoreJourneyApp(),
    ),
  );
}
