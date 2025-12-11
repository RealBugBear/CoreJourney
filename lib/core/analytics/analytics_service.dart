import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

import '../../config/app_config.dart';

/// Analytics service with Firebase Analytics integration
/// 
/// Respects AppConfig.enableAnalytics setting.
/// No-op in development environment.
class AnalyticsService {
  final FirebaseAnalytics _analytics;
  final AppConfig _config;

  AnalyticsService({
    required FirebaseAnalytics analytics,
    required AppConfig config,
  })  : _analytics = analytics,
        _config = config;

  /// Initialize analytics
  Future<void> initialize() async {
    if (!_config.enableAnalytics) {
      debugPrint('[Analytics] Disabled in ${_config.environment.name}');
      return;
    }

    await _analytics.setAnalyticsCollectionEnabled(true);
    debugPrint('[Analytics] Initialized');
  }

  /// Check if analytics should be sent
  bool get _shouldTrack => _config.enableAnalytics;

  /// Log a custom event
  Future<void> logEvent({
    required String name,
    Map<String, Object?>? parameters,
  }) async {
    if (!_shouldTrack) return;

    try {
      // Filter out null values from parameters as Firebase Analytics doesn't accept them
      final filteredParams = parameters?.map((key, value) => 
        MapEntry(key, value ?? '')
      ).cast<String, Object>();
      
      await _analytics.logEvent(
        name: name,
        parameters: filteredParams,
      );
      debugPrint('[Analytics] Event: $name ${parameters ?? ''}');
    } catch (e) {
      debugPrint('[Analytics] Failed to log event $name: $e');
    }
  }

  /// Log screen view
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    if (!_shouldTrack) return;

    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      );
      debugPrint('[Analytics] Screen: $screenName');
    } catch (e) {
      debugPrint('[Analytics] Failed to log screen view: $e');
    }
  }

  /// Set user ID
  Future<void> setUserId(String? userId) async {
    if (!_shouldTrack) return;

    try {
      await _analytics.setUserId(id: userId);
      debugPrint('[Analytics] User ID set: $userId');
    } catch (e) {
      debugPrint('[Analytics] Failed to set user ID: $e');
    }
  }

  /// Set user property
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    if (!_shouldTrack) return;

    try {
      await _analytics.setUserProperty(name: name, value: value);
      debugPrint('[Analytics] User property: $name = $value');
    } catch (e) {
      debugPrint('[Analytics] Failed to set user property: $e');
    }
  }

  // Convenience methods for common events

  /// Log app open
  Future<void> logAppOpen() async {
    await logEvent(name: 'app_open');
  }

  /// Log login
  Future<void> logLogin({String? method}) async {
    await logEvent(
      name: 'login',
      parameters: method != null ? {'method': method} : null,
    );
  }

  /// Log sign up
  Future<void> logSignUp({String? method}) async {
    await logEvent(
      name: 'sign_up',
      parameters: method != null ? {'method': method} : null,
    );
  }

  /// Log training start
  Future<void> logTrainingStart({
    required String trainingId,
    String? trainingName,
  }) async {
    await logEvent(
      name: 'training_start',
      parameters: {
        'training_id': trainingId,
        if (trainingName != null) 'training_name': trainingName,
      },
    );
  }

  /// Log training complete
  Future<void> logTrainingComplete({
    required String trainingId,
    String? trainingName,
    int? duration,
  }) async {
    await logEvent(
      name: 'training_complete',
      parameters: {
        'training_id': trainingId,
        if (trainingName != null) 'training_name': trainingName,
        if (duration != null) 'duration': duration,
      },
    );
  }

  /// Log feature usage
  Future<void> logFeatureUsage({
    required String featureName,
    Map<String, Object?>? parameters,
  }) async {
    await logEvent(
      name: 'feature_usage',
      parameters: {
        'feature': featureName,
        ...?parameters,
      },
    );
  }

  /// Log error
  Future<void> logError({
    required String error,
    String? context,
    bool fatal = false,
  }) async {
    await logEvent(
      name: 'error',
      parameters: {
        'error': error,
        if (context != null) 'context': context,
        'fatal': fatal,
      },
    );
  }
}
