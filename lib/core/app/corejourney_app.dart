import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_config.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CoreJourneyApp extends ConsumerWidget {
  const CoreJourneyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = AppConfig.current;
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: config.appName, // Changes per environment
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode, // Reaktiv vom Provider
      debugShowCheckedModeBanner: config.showDebugBanner, // Hidden in staging/prod
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (snapshot.hasData) {
            return const DashboardScreen();
          }

          return const LoginScreen();
        },
      ),
    );
  }
}
