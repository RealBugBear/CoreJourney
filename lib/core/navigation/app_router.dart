import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/auth/presentation/screens/change_password_screen.dart';
import '../../features/consent/presentation/screens/consent_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/assessment/presentation/screens/intake_assessment_screen.dart';
import '../../features/assessment/presentation/screens/duration_recommendation_screen.dart';
import '../../features/assessment/presentation/screens/completion_questionnaire_screen.dart';
import '../../features/training/presentation/screens/training_session_screen.dart';
import '../../features/mood/presentation/screens/mood_history_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/trainer/presentation/screens/trainer_clients_screen.dart';
import '../../features/trainer/presentation/screens/trainer_client_detail_screen.dart';
import '../../features/trainer/presentation/screens/trainer_dashboard_screen.dart';
import '../../features/trainer/presentation/screens/appointment_scheduler_screen.dart';
import '../../features/trainer/presentation/screens/appointment_proposal_screen.dart';
import '../../features/trainer/domain/models/trainer_client.dart';
import '../../features/journal/presentation/screens/journal_screen.dart';
import '../../features/dev_tools/presentation/screens/dev_tools_screen.dart';
import '../../features/chat/domain/models/chat_channel.dart';
import '../../features/admin/presentation/screens/admin_panel_screen.dart';
import '../../features/chat/presentation/screens/chat_channel_screen.dart';
import '../../features/community/presentation/screens/community_screen.dart';
import '../../features/chat/presentation/screens/dm_screen.dart';
import 'app_shell.dart';

// Route name constants
class Routes {
  static const login = '/login';
  static const resetPassword = '/auth/reset-password';
  static const changePassword = '/profile/change-password';
  static const devTools = '/dev-tools';
  static const consent = '/consent';
  static const dashboard = '/dashboard';
  static const intakeAssessment = '/intake-assessment';
  static const durationRecommendation = '/intake-assessment/duration';
  static const completionQuestionnaire = '/completion-questionnaire';
  static const trainingSession = '/training/session';
  static const moodHistory = '/mood/history';
  static const journal = '/journal';
  static const packages = '/packages';
  static const settings = '/settings';
  static const profile = '/profile';
  static const trainerClients = '/trainer/clients';
  static const trainerClientDetail = '/trainer/clients/:clientId';
  static const trainerDashboard = '/trainer/dashboard';
  static const appointmentScheduler = '/trainer/appointment/:clientId';
  static const appointmentProposals = '/appointments/proposals';
  static const community = '/community';
  static const communityChannel = '/community/:channelId';
  static const dm = '/dm';
  static const dmChannel = '/dm/:channelId';
  static const chatInbox = '/chat';
  static const chatChannel = '/chat/:channelId';
  static const adminPanel = '/admin';
}

/// Bridges a Stream into a [Listenable] so GoRouter can react to auth changes.
class _StreamRefreshListenable extends ChangeNotifier {
  _StreamRefreshListenable(Stream<dynamic> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }
  late final dynamic _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final routerProvider = Provider<GoRouter>((ref) {
  final authRefresh = _StreamRefreshListenable(
    Supabase.instance.client.auth.onAuthStateChange,
  );
  ref.onDispose(authRefresh.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: Routes.login,
    refreshListenable: authRefresh,
    redirect: (context, state) {
      final user = Supabase.instance.client.auth.currentUser;
      final isPasswordRecovery = ref.read(passwordRecoveryActiveProvider);
      final loc = state.matchedLocation;

      // Password-Recovery Deep Link: Vorrang vor allem anderen
      if (isPasswordRecovery && loc != Routes.resetPassword) {
        return Routes.resetPassword;
      }
      // Nicht eingeloggt → Login (außer während Recovery)
      if (user == null && loc != Routes.login && loc != Routes.resetPassword) {
        return Routes.login;
      }
      // Eingeloggt und auf Login → Dashboard
      if (user != null && !isPasswordRecovery && loc == Routes.login) {
        return Routes.dashboard;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.resetPassword,
        name: 'reset-password',
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: Routes.changePassword,
        name: 'change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: Routes.consent,
        name: 'consent',
        builder: (context, state) => const ConsentScreen(),
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
        builder: (context, state) {
          final enrollmentId = state.extra as String? ?? '';
          return CompletionQuestionnaireScreen(enrollmentId: enrollmentId);
        },
      ),
      GoRoute(
        path: Routes.trainingSession,
        name: 'training-session',
        builder: (context, state) {
          final packageId = state.extra as String? ?? 'moro';
          return TrainingSessionScreen(packageId: packageId);
        },
      ),
      GoRoute(
        path: Routes.moodHistory,
        name: 'mood-history',
        builder: (context, state) => const MoodHistoryScreen(),
      ),
      GoRoute(
        path: Routes.journal,
        name: 'journal',
        builder: (context, state) => const JournalScreen(),
      ),
      GoRoute(
        path: Routes.settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
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
      GoRoute(
        path: Routes.trainerDashboard,
        name: 'trainer-dashboard',
        builder: (context, state) => const TrainerDashboardScreen(),
      ),
      GoRoute(
        path: Routes.appointmentScheduler,
        name: 'appointment-scheduler',
        builder: (context, state) {
          final clientId = state.pathParameters['clientId']!;
          final client = state.extra as TrainerClient?;
          // Fallback minimal client if navigated without extra
          return AppointmentSchedulerScreen(
            client: client ??
                TrainerClient(
                  relationshipId: '',
                  clientId: clientId,
                  displayName: 'Trainee',
                  currentDay: 1,
                  dailyStreak: 0,
                ),
          );
        },
      ),
      GoRoute(
        path: Routes.appointmentProposals,
        name: 'appointment-proposals',
        builder: (context, state) => const AppointmentProposalScreen(),
      ),
      GoRoute(
        path: Routes.devTools,
        name: 'dev-tools',
        builder: (context, state) => const DevToolsScreen(),
      ),
      GoRoute(
        path: Routes.adminPanel,
        name: 'admin-panel',
        builder: (context, state) => const AdminPanelScreen(),
      ),
      // ── Shell: persists bottom navigation bar ────────────────────────────
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: Routes.dashboard,
            name: 'dashboard',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const DashboardScreen(),
            ),
          ),
          GoRoute(
            path: Routes.community,
            name: 'community',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const CommunityScreen(),
            ),
            routes: [
              GoRoute(
                path: ':channelId',
                name: 'community-channel',
                builder: (context, state) {
                  final channelId = state.pathParameters['channelId']!;
                  final channel = state.extra as ChatChannel?;
                  return ChatChannelScreen(channelId: channelId, channel: channel);
                },
              ),
            ],
          ),
          GoRoute(
            path: Routes.dm,
            name: 'dm',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const DmScreen(),
            ),
            routes: [
              GoRoute(
                path: ':channelId',
                name: 'dm-channel',
                builder: (context, state) {
                  final channelId = state.pathParameters['channelId']!;
                  final channel = state.extra as ChatChannel?;
                  return ChatChannelScreen(channelId: channelId, channel: channel);
                },
              ),
            ],
          ),
          GoRoute(
            path: Routes.profile,
            name: 'profile',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const ProfileScreen(),
            ),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
});
