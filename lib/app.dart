import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'bootstrap/providers.dart';
import 'core/navigation/app_router.dart';
import 'core/settings/settings_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'l10n/app_localizations.dart';

/// Root widget. Handles app lifecycle events (sync drain on background) and
/// delegates actual UI construction to [_CoreJourneyAppView].
class CoreJourneyApp extends ConsumerStatefulWidget {
  const CoreJourneyApp({super.key});

  @override
  ConsumerState<CoreJourneyApp> createState() => _CoreJourneyAppState();
}

class _CoreJourneyAppState extends ConsumerState<CoreJourneyApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Flush the sync queue whenever the app moves to background or is suspended.
  /// This ensures data written during the session reaches Supabase even if the
  /// user force-quits before the 5-minute periodic timer fires.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      unawaited(ref.read(syncServiceProvider).drain());
    }
  }

  @override
  Widget build(BuildContext context) => const _CoreJourneyAppView();
}

// ── App view ──────────────────────────────────────────────────────────────────

class _CoreJourneyAppView extends ConsumerWidget {
  const _CoreJourneyAppView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Sync static exercise content from Supabase into the local cache.
    // Runs once per cold start; no-ops if the cache is already populated.
    ref.read(exercisesSyncServiceProvider).syncIfNeeded();

    // Trigger server → local rehydration whenever the user signs in or the
    // token is refreshed. Ensures returning users on a fresh device or after
    // reinstall see their real Supabase data instead of being re-enrolled.
    ref.listen<AsyncValue<AuthState>>(authStateProvider, (_, next) {
      final event = next.valueOrNull?.event;
      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.tokenRefreshed) {
        final userId = next.valueOrNull?.session?.user.id;
        if (userId != null) {
          ref.read(syncServiceProvider).rehydrate(userId);
        }
      }
      // On sign-out: settingsProvider re-creates with userId=null,
      // reads the global theme key (no value saved → defaults to system).
      // On next sign-in: re-creates with the real userId, restoring
      // the user's previously saved theme from their scoped key.
    });

    // React to notification-relevant settings changes.
    ref.listen<AppSettings>(settingsProvider, (prev, next) {
      _syncNotifications(ref, prev, next);
    });

    return MaterialApp.router(
      title: 'CoreJourney',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: locale,
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('de'),
        Locale('en'),
      ],
    );
  }
}

// ── Notification sync helper ──────────────────────────────────────────────────

Future<void> _syncNotifications(
  WidgetRef ref,
  AppSettings? prev,
  AppSettings next,
) async {
  final ns = ref.read(notificationServiceProvider);

  final prevEnabled = prev?.remindersEnabled ?? false;
  final prevStart = prev?.reminderStartMinutes;
  final prevEnd = prev?.reminderEndMinutes;

  final changed = prevEnabled != next.remindersEnabled ||
      prevStart != next.reminderStartMinutes ||
      prevEnd != next.reminderEndMinutes;

  if (!changed) return;

  if (!next.remindersEnabled) {
    await ns.cancelReminder();
    return;
  }

  if (!prevEnabled && next.remindersEnabled) {
    final granted = await ns.requestPermission();
    if (!granted) return;
  }

  final isDE = next.languageCode == 'de';
  await ns.scheduleReminder(
    startMinutes: next.reminderStartMinutes,
    titleDe: isDE ? 'Zeit für dein Training 🧘' : 'Time for your training 🧘',
    bodyDe: isDE
        ? 'Mach dein tägliches Reflexintegrations-Training.'
        : 'Complete your daily reflex integration training.',
  );
}
