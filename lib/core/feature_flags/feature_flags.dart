/// Feature flags available in the application
/// 
/// Each flag has a default value that can be overridden by:
/// 1. Firebase Remote Config (all environments)
/// 2. Local overrides in developer settings (dev/staging only)
enum FeatureFlag {
  // Example flags - replace with your actual features
  
  /// Enable new training flow redesign
  newTrainingFlow('new_training_flow', false),
  
  /// Enable social sharing features
  socialSharing('social_sharing', false),
  
  /// Enable advanced analytics
  advancedAnalytics('advanced_analytics', true),
  
  /// Enable offline mode
  offlineMode('offline_mode', true),
  
  /// Enable dark mode
  darkMode('dark_mode', true),
  
  /// Enable experimental features (dev only)
  experimentalFeatures('experimental_features', false),
  
  /// Enable performance monitoring
  performanceMonitoring('performance_monitoring', true);

  const FeatureFlag(this.key, this.defaultValue);

  /// Remote config key
  final String key;
  
  /// Default value if not configured remotely
  final bool defaultValue;

  /// Description for developer settings
  String get description {
    switch (this) {
      case FeatureFlag.newTrainingFlow:
        return 'Enable redesigned training flow UI';
      case FeatureFlag.socialSharing:
        return 'Allow users to share progress on social media';
      case FeatureFlag.advancedAnalytics:
        return 'Track detailed user analytics';
      case FeatureFlag.offlineMode:
        return 'Enable full offline functionality';
      case FeatureFlag.darkMode:
        return 'Enable dark theme support';
      case FeatureFlag.experimentalFeatures:
        return 'Show experimental features (dev only)';
      case FeatureFlag.performanceMonitoring:
        return 'Monitor app performance metrics';
    }
  }
}

/// String-based feature flags for configuration values
enum ConfigFlag {
  /// API base URL
  apiBaseUrl('api_base_url'),
  
  /// Maximum cache size in MB
  maxCacheSize('max_cache_size'),
  
  /// Sync interval in minutes
  syncInterval('sync_interval');

  const ConfigFlag(this.key);

  final String key;

  String get description {
    switch (this) {
      case ConfigFlag.apiBaseUrl:
        return 'Base URL for API requests';
      case ConfigFlag.maxCacheSize:
        return 'Maximum cache size in megabytes';
      case ConfigFlag.syncInterval:
        return 'Sync interval in minutes';
    }
  }
}
