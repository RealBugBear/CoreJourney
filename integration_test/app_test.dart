import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:corejourney/bootstrap/bootstrap.dart';
import 'package:corejourney/config/app_config.dart';
import 'package:corejourney/core/app/corejourney_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Integration Tests', () {
    testWidgets('App launches successfully in development', (tester) async {
      // Set development configuration
      AppConfig.setConfig(AppConfig.development);

      // Bootstrap app
      final result = await bootstrapApp(env: 'dev');

      // Build app
      await tester.pumpWidget(
        ProviderScope(
          overrides: result.toOverrides(),
          child: const CoreJourneyApp(),
        ),
      );

      // Wait for app to settle
      await tester.pumpAndSettle();

      // Verify app loaded (this will depend on your app's structure)
      // For now, just verify no errors occurred
      expect(tester.takeException(), isNull);
    });

    testWidgets('App launches successfully in staging', (tester) async {
      // Set staging configuration
      AppConfig.setConfig(AppConfig.staging);

      // Bootstrap app
      final result = await bootstrapApp(env: 'staging');

      // Build app
      await tester.pumpWidget(
        ProviderScope(
          overrides: result.toOverrides(),
          child: const CoreJourneyApp(),
        ),
      );

      // Wait for app to settle
      await tester.pumpAndSettle();

      // Verify app loaded
      expect(tester.takeException(), isNull);
    });

    testWidgets('Bootstrap initializes all services', (tester) async {
      // Set development configuration
      AppConfig.setConfig(AppConfig.development);

      // Bootstrap app
      final result = await bootstrapApp(env: 'dev');

      // Verify all services are initialized
      expect(result.database, isNotNull);
      expect(result.sync, isNotNull);
      expect(result.sharedPreferences, isNotNull);
      expect(result.featureFlags, isNotNull);
      expect(result.analytics, isNotNull);
      expect(result.logger, isNotNull);

      // Verify overrides are created
      final overrides = result.toOverrides();
      expect(overrides, isNotEmpty);
      expect(overrides.length, 6); // database, sync, prefs, flags, analytics, logger
    });

    testWidgets('Feature flags initialize correctly', (tester) async {
      // Set development configuration
      AppConfig.setConfig(AppConfig.development);

      // Bootstrap app
      final result = await bootstrapApp(env: 'dev');

      // Check feature flag service is initialized
      expect(result.featureFlags, isNotNull);

      // Test that flags can be read (will use defaults)
      expect(
        () => result.featureFlags.getAllValues(),
        returnsNormally,
      );
    });
  });
}
