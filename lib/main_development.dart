import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'bootstrap/bootstrap.dart';
import 'bootstrap/providers.dart';
import 'config/app_config.dart';

void main() async {
  final bootstrap = await Bootstrap.initialize(
    envFile: '.env.dev',
    environment: AppEnvironment.development,
  );

  bootstrap.syncService.start();

  runApp(
    ProviderScope(
      overrides: bootstrapOverrides(bootstrap),
      child: const CoreJourneyApp(),
    ),
  );
}
