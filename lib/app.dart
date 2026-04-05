import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bootstrap/providers.dart';
import 'core/navigation/app_router.dart';
import 'core/settings/settings_provider.dart';
import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';

class CoreJourneyApp extends ConsumerWidget {
  const CoreJourneyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);

    // React to notification-relevant settings changes
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

// Called whenever settings change — syncs the scheduled notification.
Future<void> _syncNotifications(
  WidgetRef ref,
  AppSettings? prev,
  AppSettings next,
) async {
  final ns = ref.read(notificationServiceProvider);

  // Nothing to do if the relevant fields didn't change
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

  // First enable: request permission, then schedule
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
