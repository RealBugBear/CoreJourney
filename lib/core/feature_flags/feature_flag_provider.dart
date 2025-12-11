import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/app_config.dart';
import 'feature_flag_service.dart';
import 'feature_flags.dart';

/// Provider for SharedPreferences instance
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in bootstrap');
});

/// Provider for FirebaseRemoteConfig instance
final firebaseRemoteConfigProvider = Provider<FirebaseRemoteConfig>((ref) {
  return FirebaseRemoteConfig.instance;
});

/// Provider for FeatureFlagService
final featureFlagServiceProvider = Provider<FeatureFlagService>((ref) {
  return FeatureFlagService(
    remoteConfig: ref.watch(firebaseRemoteConfigProvider),
    prefs: ref.watch(sharedPreferencesProvider),
    config: AppConfig.current,
  );
});

/// Provider for individual feature flag values
/// Usage: ref.watch(featureFlagProvider(FeatureFlag.newTrainingFlow))
final featureFlagProvider = Provider.family<bool, FeatureFlag>((ref, flag) {
  final service = ref.watch(featureFlagServiceProvider);
  return service.isEnabled(flag);
});

/// Provider for config flag string values
final configFlagStringProvider = Provider.family.autoDispose<String, ({ConfigFlag flag, String defaultValue})>((ref, params) {
  final service = ref.watch(featureFlagServiceProvider);
  return service.getString(params.flag, params.defaultValue);
});

/// Provider for config flag int values
final configFlagIntProvider = Provider.family.autoDispose<int, ({ConfigFlag flag, int defaultValue})>((ref, params) {
  final service = ref.watch(featureFlagServiceProvider);
  return service.getInt(params.flag, params.defaultValue);
});

/// Provider for all feature flag values (debugging)
final allFeatureFlagsProvider = Provider<Map<String, dynamic>>((ref) {
  final service = ref.watch(featureFlagServiceProvider);
  return service.getAllValues();
});
