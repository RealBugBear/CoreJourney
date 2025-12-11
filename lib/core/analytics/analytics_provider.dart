import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

import '../../config/app_config.dart';
import 'analytics_service.dart';

/// Provider for FirebaseAnalytics instance
final firebaseAnalyticsProvider = Provider<FirebaseAnalytics>((ref) {
  return FirebaseAnalytics.instance;
});

/// Provider for AnalyticsService
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService(
    analytics: ref.watch(firebaseAnalyticsProvider),
    config: AppConfig.current,
  );
});

/// Provider for FirebaseAnalyticsObserver (for route tracking)
final analyticsObserverProvider = Provider<FirebaseAnalyticsObserver>((ref) {
  return FirebaseAnalyticsObserver(
    analytics: ref.watch(firebaseAnalyticsProvider),
  );
});
