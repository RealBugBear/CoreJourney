enum AppEnvironment { development, production }

class AppConfig {
  final AppEnvironment environment;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String revenueCatApiKey;

  /// Email that may see dev tools in development builds.
  /// Set via ADMIN_EMAIL in .env.dev. If empty, dev tools are hidden for all.
  final String adminEmail;

  /// Secret code that activates the trainer role.
  /// Set via TRAINER_CODE in .env.dev / .env.prod.
  final String trainerCode;

  const AppConfig({
    required this.environment,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.revenueCatApiKey,
    this.adminEmail = '',
    this.trainerCode = '',
  });

  bool get isDevelopment => environment == AppEnvironment.development;
  bool get isProduction => environment == AppEnvironment.production;

  String get envLabel => isDevelopment ? 'DEV' : 'PROD';
}
