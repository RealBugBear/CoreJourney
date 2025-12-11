import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bootstrap/bootstrap.dart';
import 'config/app_config.dart';
import 'core/app/corejourney_app.dart';

void main() async {
  // Set production configuration
  AppConfig.setConfig(AppConfig.production);

  // Bootstrap app with production environment
  final result = await bootstrapApp(env: 'prod');

  runApp(
    ProviderScope(
      overrides: result.toOverrides(),
      child: const CoreJourneyApp(),
    ),
  );
}
