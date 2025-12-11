import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bootstrap/bootstrap.dart';
import 'config/app_config.dart';
import 'core/app/corejourney_app.dart';

void main() async {
  // Set development configuration
  AppConfig.setConfig(AppConfig.development);

  // Bootstrap app with dev environment
  final result = await bootstrapApp(env: 'dev');

  runApp(
    ProviderScope(
      overrides: result.toOverrides(),
      child: const CoreJourneyApp(),
    ),
  );
}
