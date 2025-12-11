import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/app_config.dart';
import '../../../../core/feature_flags/feature_flags.dart';
import '../../../../core/feature_flags/feature_flag_provider.dart';
import '../../../../core/logging/logger_provider.dart';
import '../../../../core/analytics/analytics_provider.dart';

/// Developer settings screen (only accessible in dev/staging)
/// 
/// Provides:
/// - Feature flag overrides
/// - View current configuration
/// - App diagnostics
/// - Clear caches and data
class DeveloperSettingsScreen extends ConsumerWidget {
  const DeveloperSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = AppConfig.current;
    final featureFlags = ref.watch(featureFlagServiceProvider);
    final allFlags = ref.watch(allFeatureFlagsProvider);
    final logger = ref.watch(loggerServiceProvider);

    // Only show in dev/staging
    if (config.environment.isProduction) {
      return Scaffold(
        appBar: AppBar(title: const Text('Developer Settings')),
        body: const Center(
          child: Text('Not available in production'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await featureFlags.refresh();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Feature flags refreshed')),
              );
            },
            tooltip: 'Refresh feature flags',
          ),
        ],
      ),
      body: ListView(
        children: [
          // Environment Info
          _buildSection(
            title: 'Environment',
            children: [
              _buildInfoTile('Environment', config.environment.name.toUpperCase()),
              _buildInfoTile('App Name', config.appName),
              _buildInfoTile('Bundle ID', config.bundleId),
              _buildInfoTile('Log Level', config.logLevel.toUpperCase()),
            ],
          ),

          // Services Status
          _buildSection(
            title: 'Services',
            children: [
              _buildInfoTile(
                'Analytics',
                config.enableAnalytics ? 'Enabled' : 'Disabled',
                trailing: Icon(
                  config.enableAnalytics ? Icons.check_circle : Icons.cancel,
                  color: config.enableAnalytics ? Colors.green : Colors.red,
                ),
              ),
              _buildInfoTile(
                'Crash Reporting',
                config.enableCrashReporting ? 'Enabled' : 'Disabled',
                trailing: Icon(
                  config.enableCrashReporting ? Icons.check_circle : Icons.cancel,
                  color: config.enableCrashReporting ? Colors.green : Colors.red,
                ),
              ),
              _buildInfoTile(
                'Performance Monitoring',
                config.enablePerformanceMonitoring ? 'Enabled' : 'Disabled',
                trailing: Icon(
                  config.enablePerformanceMonitoring ? Icons.check_circle : Icons.cancel,
                  color: config.enablePerformanceMonitoring ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),

          // Feature Flags
          _buildSection(
            title: 'Feature Flags',
            children: [
              ...FeatureFlag.values.map((flag) {
                final flagData = allFlags[flag.key];
                final isEnabled = flagData?['enabled'] as bool? ?? false;
                final hasOverride = flagData?['hasOverride'] as bool? ?? false;

                return ListTile(
                  title: Text(flag.key),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        flag.description,
                        style: const TextStyle(fontSize: 12),
                      ),
                      if (hasOverride)
                        const Text(
                          'Overridden locally',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasOverride)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () async {
                            await featureFlags.clearOverride(flag);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Override cleared for ${flag.key}')),
                            );
                          },
                          tooltip: 'Clear override',
                        ),
                      Switch(
                        value: isEnabled,
                        onChanged: (value) async {
                          await featureFlags.setOverride(flag, value);
                          logger.info('Feature flag overridden', data: {
                            'flag': flag.key,
                            'value': value,
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${flag.key} = $value'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              }),
              if (allFlags.values.any((v) => v['hasOverride'] == true))
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await featureFlags.clearAllOverrides();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('All overrides cleared')),
                      );
                    },
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Clear All Overrides'),
                  ),
                ),
            ],
          ),

          // Actions
          _buildSection(
            title: 'Actions',
            children: [
              ListTile(
                leading: const Icon(Icons.bug_report),
                title: const Text('Test Crash Reporting'),
                subtitle: const Text('Trigger a test crash (staging only)'),
                onTap: config.environment.isStaging
                    ? () {
                        logger.warning('Test crash triggered');
                        throw Exception('Test crash from developer settings');
                      }
                    : null,
              ),
              ListTile(
                leading: const Icon(Icons.analytics),
                title: const Text('Test Analytics Event'),
                subtitle: const Text('Send a test analytics event'),
                onTap: () {
                  final analytics = ref.read(analyticsServiceProvider);
                  analytics.logEvent(
                    name: 'developer_test_event',
                    parameters: {'timestamp': DateTime.now().toIso8601String()},
                  );
                  logger.info('Test analytics event sent');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Test event sent')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Clear App Data'),
                subtitle: const Text('Clear all local data (requires restart)'),
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Clear App Data?'),
                      content: const Text(
                        'This will clear all local data including feature flag overrides. App restart required.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && context.mounted) {
                    await featureFlags.clearAllOverrides();
                    logger.warning('App data cleared from developer settings');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Data cleared. Please restart the app.'),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        ...children,
        const Divider(),
      ],
    );
  }

  Widget _buildInfoTile(String label, String value, {Widget? trailing}) {
    return ListTile(
      title: Text(label),
      subtitle: Text(value),
      trailing: trailing,
    );
  }
}
