import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:corejourney/config/app_config.dart';
import 'package:corejourney/core/feature_flags/feature_flag_service.dart';
import 'package:corejourney/core/feature_flags/feature_flags.dart';

class MockFirebaseRemoteConfig extends Mock implements FirebaseRemoteConfig {}
class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  group('FeatureFlagService', () {
    late FeatureFlagService service;
    late MockFirebaseRemoteConfig mockRemoteConfig;
    late MockSharedPreferences mockPrefs;
    late AppConfig config;

    setUp(() {
      mockRemoteConfig = MockFirebaseRemoteConfig();
      mockPrefs = MockSharedPreferences();
      config = AppConfig.development;
      
      service = FeatureFlagService(
        remoteConfig: mockRemoteConfig,
        prefs: mockPrefs,
        config: config,
      );
    });

    group('isEnabled', () {
      test('returns remote config value when no override', () {
        // Arrange
        when(() => mockPrefs.containsKey(any())).thenReturn(false);
        when(() => mockRemoteConfig.getBool('new_training_flow'))
            .thenReturn(true);

        // Act
        final result = service.isEnabled(FeatureFlag.newTrainingFlow);

        // Assert
        expect(result, true);
        verify(() => mockRemoteConfig.getBool('new_training_flow')).called(1);
      });

      test('returns override value when set in dev mode', () {
        // Arrange
        const overrideKey = 'ff_override_new_training_flow';
        when(() => mockPrefs.containsKey(overrideKey)).thenReturn(true);
        when(() => mockPrefs.getBool(overrideKey)).thenReturn(true);

        // Act
        final result = service.isEnabled(FeatureFlag.newTrainingFlow);

        // Assert
        expect(result, true);
        verify(() => mockPrefs.getBool(overrideKey)).called(1);
        verifyNever(() => mockRemoteConfig.getBool(any()));
      });

      test('returns default value when remote config fails', () {
        // Arrange
        when(() => mockPrefs.containsKey(any())).thenReturn(false);
        when(() => mockRemoteConfig.getBool('new_training_flow'))
            .thenThrow(Exception('Remote config error'));

        // Act
        final result = service.isEnabled(FeatureFlag.newTrainingFlow);

        // Assert
        expect(result, FeatureFlag.newTrainingFlow.defaultValue);
      });

      test('ignores override in production mode', () {
        // Arrange
        final prodService = FeatureFlagService(
          remoteConfig: mockRemoteConfig,
          prefs: mockPrefs,
          config: AppConfig.production,
        );
        when(() => mockRemoteConfig.getBool('new_training_flow'))
            .thenReturn(false);

        // Act
        final result = prodService.isEnabled(FeatureFlag.newTrainingFlow);

        // Assert
        expect(result, false);
        verify(() => mockRemoteConfig.getBool('new_training_flow')).called(1);
        verifyNever(() => mockPrefs.containsKey(any()));
      });
    });

    group('setOverride', () {
      test('sets override in dev mode', () async {
        // Arrange
        when(() => mockPrefs.setBool(any(), any()))
            .thenAnswer((_) async => true);

        // Act
        await service.setOverride(FeatureFlag.newTrainingFlow, true);

        // Assert
        verify(() => mockPrefs.setBool('ff_override_new_training_flow', true))
            .called(1);
      });

      test('does not set override in production mode', () async {
        // Arrange
        final prodService = FeatureFlagService(
          remoteConfig: mockRemoteConfig,
          prefs: mockPrefs,
          config: AppConfig.production,
        );

        // Act
        await prodService.setOverride(FeatureFlag.newTrainingFlow, true);

        // Assert
        verifyNever(() => mockPrefs.setBool(any(), any()));
      });
    });

    group('clearOverride', () {
      test('removes override key', () async {
        // Arrange
        when(() => mockPrefs.remove(any())).thenAnswer((_) async => true);

        // Act
        await service.clearOverride(FeatureFlag.newTrainingFlow);

        // Assert
        verify(() => mockPrefs.remove('ff_override_new_training_flow'))
            .called(1);
      });
    });

    group('clearAllOverrides', () {
      test('removes all override keys', () async {
        // Arrange
        when(() => mockPrefs.getKeys()).thenReturn({
          'ff_override_new_training_flow',
          'ff_override_social_sharing',
          'other_key',
        });
        when(() => mockPrefs.remove(any())).thenAnswer((_) async => true);

        // Act
        await service.clearAllOverrides();

        // Assert
        verify(() => mockPrefs.remove('ff_override_new_training_flow'))
            .called(1);
        verify(() => mockPrefs.remove('ff_override_social_sharing'))
            .called(1);
        verifyNever(() => mockPrefs.remove('other_key'));
      });
    });

    group('hasOverride', () {
      test('returns true when override exists in dev mode', () {
        // Arrange
        when(() => mockPrefs.containsKey('ff_override_new_training_flow'))
            .thenReturn(true);

        // Act
        final result = service.hasOverride(FeatureFlag.newTrainingFlow);

        // Assert
        expect(result, true);
      });

      test('returns false in production mode', () {
        // Arrange
        final prodService = FeatureFlagService(
          remoteConfig: mockRemoteConfig,
          prefs: mockPrefs,
          config: AppConfig.production,
        );

        // Act
        final result = prodService.hasOverride(FeatureFlag.newTrainingFlow);

        // Assert
        expect(result, false);
      });
    });

    group('getAllValues', () {
      test('returns all flag values with metadata', () {
        // Arrange
        when(() => mockPrefs.containsKey(any())).thenReturn(false);
        when(() => mockRemoteConfig.getBool(any())).thenReturn(true);

        // Act
        final result = service.getAllValues();

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result.length, FeatureFlag.values.length);
        
        final newTrainingFlowData = result['new_training_flow'];
        expect(newTrainingFlowData['enabled'], true);
        expect(newTrainingFlowData['hasOverride'], false);
        expect(newTrainingFlowData['default'], false);
      });
    });
  });
}
