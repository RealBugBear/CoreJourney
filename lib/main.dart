import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bootstrap/bootstrap.dart';
import 'core/app/corejourney_app.dart';

Future<void> main() async {
  final bootstrap = await bootstrapApp(env: 'dev');
  
  runApp(
    ProviderScope(
      overrides: bootstrap.toOverrides(),
      child: const CoreJourneyApp(),
    ),
  );
}
