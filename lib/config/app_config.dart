enum Environment {
  development,
  staging,
  production;

  bool get isDevelopment => this == Environment.development;
  bool get isStaging => this == Environment.staging;
  bool get isProduction => this == Environment.production;
}

class AppConfig {
  final Environment environment;
  final String appName;
  final String bundleId;
  final bool enableAnalytics;
  final bool enableCrashReporting;
  final bool showDebugBanner;
  final bool enablePerformanceMonitoring;
  final String logLevel;

  const AppConfig({
    required this.environment,
    required this.appName,
    required this.bundleId,
    required this.enableAnalytics,
    required this.enableCrashReporting,
    required this.showDebugBanner,
    required this.enablePerformanceMonitoring,
    required this.logLevel,
  });

  // Development configuration
  static const development = AppConfig(
    environment: Environment.development,
    appName: 'CoreJourney DEV',
    bundleId: 'com.alexandermessinger.corejourney.dev',
    enableAnalytics: false,
    enableCrashReporting: false,
    showDebugBanner: true,
    enablePerformanceMonitoring: false,
    logLevel: 'debug',
  );

  // Staging configuration
  static const staging = AppConfig(
    environment: Environment.staging,
    appName: 'CoreJourney STAGING',
    bundleId: 'com.alexandermessinger.corejourney.staging',
    enableAnalytics: true,
    enableCrashReporting: true,
    showDebugBanner: false,
    enablePerformanceMonitoring: true,
    logLevel: 'info',
  );

  // Production configuration
  static const production = AppConfig(
    environment: Environment.production,
    appName: 'CoreJourney',
    bundleId: 'com.alexandermessinger.corejourney',
    enableAnalytics: true,
    enableCrashReporting: true,
    showDebugBanner: false,
    enablePerformanceMonitoring: true,
    logLevel: 'error',
  );

  // Get current config
  static AppConfig get current {
    // Will be set by main_*.dart files
    return _currentConfig ?? development;
  }

  static AppConfig? _currentConfig;

  static void setConfig(AppConfig config) {
    _currentConfig = config;
  }
}
