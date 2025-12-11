import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:corejourney/config/app_config.dart';

/// Mock classes for common dependencies

class MockRef extends Mock implements Ref {}

class MockWidgetRef extends Mock implements WidgetRef {}

/// Test Data Builders

class TestData {
  /// Create test AppConfig for development
  static const developmentConfig = AppConfig.development;

  /// Create test AppConfig for staging
  static const stagingConfig = AppConfig.staging;

  /// Create test AppConfig for production
  static const productionConfig = AppConfig.production;
}

/// Common Test Helpers

/// Create a ProviderScope for testing
ProviderScope createProviderScope({
  required Widget child,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: child,
  );
}

/// Pump a widget with MaterialApp wrapper
Future<void> pumpMaterialApp(
  WidgetTester tester,
  Widget widget, {
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(
    createProviderScope(
      overrides: overrides,
      child: MaterialApp(
        home: widget,
      ),
    ),
  );
}

/// Common Assertions

/// Verify a widget exists and is visible
void expectVisible(Finder finder) {
  expect(finder, findsOneWidget);
  final widget = finder.evaluate().first.widget;
  expect(widget, isA<Widget>());
}

/// Verify a widget does not exist
void expectNotFound(Finder finder) {
  expect(finder, findsNothing);
}

/// Setup and Teardown Helpers

/// Reset all mocks
void resetMocks(List<Mock> mocks) {
  for (final mock in mocks) {
    reset(mock);
  }
}

/// Common Matchers

/// Matcher for checking if a value is within a range
Matcher isInRange(num min, num max) {
  return predicate<num>(
    (value) => value >= min && value <= max,
    'is in range [$min, $max]',
  );
}

/// Matcher for checking if a DateTime is close to another
Matcher isCloseTo(DateTime expected, {Duration tolerance = const Duration(seconds: 1)}) {
  return predicate<DateTime>(
    (actual) {
      final difference = actual.difference(expected).abs();
      return difference <= tolerance;
    },
    'is close to $expected within $tolerance',
  );
}

/// Test Groups

/// Standard test group wrapper with setup/teardown
void testGroup(
  String description,
  void Function() body, {
  void Function()? setUpFn,
  void Function()? tearDownFn,
}) {
  group(description, () {
    if (setUpFn != null) {
      setUp(setUpFn);
    }
    if (tearDownFn != null) {
      tearDown(tearDownFn);
    }
    body();
  });
}
