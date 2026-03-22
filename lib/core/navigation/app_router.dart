import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/assessment/presentation/screens/intake_assessment_screen.dart';
import '../../features/assessment/presentation/screens/duration_recommendation_screen.dart';
import '../../features/assessment/presentation/screens/completion_questionnaire_screen.dart';
import '../../features/training/presentation/screens/training_session_screen.dart';
import '../../features/mood/presentation/screens/mood_history_screen.dart';
import '../../features/packages/presentation/screens/packages_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/trainer/presentation/screens/trainer_clients_screen.dart';
import '../../features/trainer/presentation/screens/trainer_client_detail_screen.dart';

// Route name constants
class Routes {
  static const login = '/login';
  static const dashboard = '/dashboard';
  static const intakeAssessment = '/intake-assessment';
  static const durationRecommendation = '/intake-assessment/duration';
  static const completionQuestionnaire = '/completion-questionnaire';
  static const trainingSession = '/training/session';
  static const moodHistory = '/mood/history';
  static const packages = '/packages';
  static const settings = '/settings';
  static const profile = '/profile';
  static const trainerClients = '/trainer/clients';
  static const trainerClientDetail = '/trainer/clients/:clientId';
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.dashboard,
    redirect: (context, state) {
      final user = Supabase.instance.client.auth.currentUser;
      final isOnLogin = state.matchedLocation == Routes.login;

      if (user == null && !isOnLogin) return Routes.login;
      if (user != null && isOnLogin) return Routes.dashboard;
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.dashboard,
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: Routes.intakeAssessment,
        name: 'intake-assessment',
        builder: (context, state) => const IntakeAssessmentScreen(),
      ),
      GoRoute(
        path: Routes.durationRecommendation,
        name: 'duration-recommendation',
        builder: (context, state) => const DurationRecommendationScreen(),
      ),
      GoRoute(
        path: Routes.completionQuestionnaire,
        name: 'completion-questionnaire',
        builder: (context, state) => const CompletionQuestionnaireScreen(),
      ),
      GoRoute(
        path: Routes.trainingSession,
        name: 'training-session',
        builder: (context, state) => const TrainingSessionScreen(),
      ),
      GoRoute(
        path: Routes.moodHistory,
        name: 'mood-history',
        builder: (context, state) => const MoodHistoryScreen(),
      ),
      GoRoute(
        path: Routes.packages,
        name: 'packages',
        builder: (context, state) => const PackagesScreen(),
      ),
      GoRoute(
        path: Routes.settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: Routes.profile,
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: Routes.trainerClients,
        name: 'trainer-clients',
        builder: (context, state) => const TrainerClientsScreen(),
      ),
      GoRoute(
        path: Routes.trainerClientDetail,
        name: 'trainer-client-detail',
        builder: (context, state) {
          final clientId = state.pathParameters['clientId']!;
          return TrainerClientDetailScreen(clientId: clientId);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
});
