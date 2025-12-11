import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/app_config.dart';
import 'feature_flags.dart';

/// Service for managing feature flags
/// 
/// Provides access to feature flags with the following priority:
/// 1. Local overrides (dev/staging only)
/// 2. Firebase Remote Config values
/// 3. Default values from FeatureFlag enum
class FeatureFlagService {
  final FirebaseRemoteConfig _remoteConfig;
  final SharedPreferences _prefs;
  final AppConfig _config;

  static const _overridePrefix = 'ff_override_';

  FeatureFlagService({
    required FirebaseRemoteConfig remoteConfig,
    required SharedPreferences prefs,
    required AppConfig config,
  })  : _remoteConfig = remoteConfig,
        _prefs = prefs,
        _config = config;

  /// Initialize the feature flag service
  Future<void> initialize() async {
    try {
      // Configure fetch settings based on environment
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: _config.environment.isProduction
              ? const Duration(hours: 1) // Production: fetch every hour
              : const Duration(minutes: 5), // Dev/Staging: fetch every 5 min
        ),
      );

      // Set default values
      final defaults = <String, dynamic>{};
      for (final flag in FeatureFlag.values) {
        defaults[flag.key] = flag.defaultValue;
      }
      await _remoteConfig.setDefaults(defaults);

      // Fetch and activate
      await _remoteConfig.fetchAndActivate();
      
      debugPrint('[FeatureFlags] Initialized with ${FeatureFlag.values.length} flags');
    } catch (e) {
      debugPrint('[FeatureFlags] Failed to initialize: $e');
      // Continue with default values
    }
  }

  /// Get a boolean feature flag value
  bool isEnabled(FeatureFlag flag) {
    // Check for local override first (dev/staging only)
    if (!_config.environment.isProduction) {
      final overrideKey = '$_overridePrefix${flag.key}';
      if (_prefs.containsKey(overrideKey)) {
        return _prefs.getBool(overrideKey) ?? flag.defaultValue;
      }
    }

    // Get from remote config or default
    try {
      return _remoteConfig.getBool(flag.key);
    } catch (e) {
      debugPrint('[FeatureFlags] Error getting ${flag.key}: $e');
      return flag.defaultValue;
    }
  }

  /// Get a string configuration value
  String getString(ConfigFlag flag, String defaultValue) {
    try {
      final value = _remoteConfig.getString(flag.key);
      return value.isEmpty ? defaultValue : value;
    } catch (e) {
      debugPrint('[FeatureFlags] Error getting ${flag.key}: $e');
      return defaultValue;
    }
  }

  /// Get an integer configuration value
  int getInt(ConfigFlag flag, int defaultValue) {
    try {
      return _remoteConfig.getInt(flag.key);
    } catch (e) {
      debugPrint('[FeatureFlags] Error getting ${flag.key}: $e');
      return defaultValue;
    }
  }

  /// Get a double configuration value
  double getDouble(ConfigFlag flag, double defaultValue) {
    try {
      return _remoteConfig.getDouble(flag.key);
    } catch (e) {
      debugPrint('[FeatureFlags] Error getting ${flag.key}: $e');
      return defaultValue;
    }
  }

  /// Set a local override for a feature flag (dev/staging only)
  Future<void> setOverride(FeatureFlag flag, bool value) async {
    if (_config.environment.isProduction) {
      debugPrint('[FeatureFlags] Overrides not allowed in production');
      return;
    }

    final overrideKey = '$_overridePrefix${flag.key}';
    await _prefs.setBool(overrideKey, value);
    debugPrint('[FeatureFlags] Override set: ${flag.key} = $value');
  }

  /// Clear a local override
  Future<void> clearOverride(FeatureFlag flag) async {
    final overrideKey = '$_overridePrefix${flag.key}';
    await _prefs.remove(overrideKey);
    debugPrint('[FeatureFlags] Override cleared: ${flag.key}');
  }

  /// Clear all local overrides
  Future<void> clearAllOverrides() async {
    final keys = _prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_overridePrefix)) {
        await _prefs.remove(key);
      }
    }
    debugPrint('[FeatureFlags] All overrides cleared');
  }

  /// Check if a flag has a local override
  bool hasOverride(FeatureFlag flag) {
    if (_config.environment.isProduction) return false;
    return _prefs.containsKey('$_overridePrefix${flag.key}');
  }

  /// Get all flag values (useful for debugging)
  Map<String, dynamic> getAllValues() {
    final values = <String, dynamic>{};
    for (final flag in FeatureFlag.values) {
      values[flag.key] = {
        'enabled': isEnabled(flag),
        'hasOverride': hasOverride(flag),
        'default': flag.defaultValue,
      };
    }
    return values;
  }

  /// Force fetch new values from Remote Config
  Future<void> refresh() async {
    try {
      await _remoteConfig.fetchAndActivate();
      debugPrint('[FeatureFlags] Refreshed from Remote Config');
    } catch (e) {
      debugPrint('[FeatureFlags] Failed to refresh: $e');
    }
  }
}
