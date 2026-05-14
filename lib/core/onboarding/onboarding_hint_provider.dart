import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../settings/settings_provider.dart';

enum AppOnboardingHint {
  dashboard,
  progress,
  accompaniment,
  profile,
}

class OnboardingHintContent {
  const OnboardingHintContent({
    required this.title,
    required this.body,
    required this.items,
  });

  final String title;
  final String body;
  final List<OnboardingHintItem> items;
}

class OnboardingHintItem {
  const OnboardingHintItem({
    required this.iconName,
    required this.text,
  });

  final String iconName;
  final String text;
}

extension AppOnboardingHintContent on AppOnboardingHint {
  String get storageKey => switch (this) {
        AppOnboardingHint.dashboard => 'dashboard',
        AppOnboardingHint.progress => 'progress',
        AppOnboardingHint.accompaniment => 'accompaniment',
        AppOnboardingHint.profile => 'profile',
      };

  OnboardingHintContent get content => switch (this) {
        AppOnboardingHint.dashboard => const OnboardingHintContent(
            title: 'Heute',
            body:
                'Hier steuerst du deinen täglichen Rhythmus und dokumentierst, was du wahrnimmst.',
            items: [
              OnboardingHintItem(
                iconName: 'play',
                text: 'Starte deine geführte Einheit oder den Routine-Modus.',
              ),
              OnboardingHintItem(
                iconName: 'check',
                text: 'Trage eine Einheit ein, wenn du heute geübt hast.',
              ),
              OnboardingHintItem(
                iconName: 'note',
                text: 'Halte Erfahrungen direkt nach der Einheit fest.',
              ),
            ],
          ),
        AppOnboardingHint.progress => const OnboardingHintContent(
            title: 'Verlauf',
            body:
                'Der Verlauf hilft dir, Muster zu sehen, ohne einzelne Tage zu überbewerten.',
            items: [
              OnboardingHintItem(
                iconName: 'chart',
                text:
                    'Sieh Trainingstage, Beobachtungen und Einträge zusammen.',
              ),
              OnboardingHintItem(
                iconName: 'note',
                text: 'Ergänze Beobachtungen, wenn dir etwas auffällt.',
              ),
              OnboardingHintItem(
                iconName: 'book',
                text: 'Öffne einzelne Journal-Einträge für mehr Kontext.',
              ),
            ],
          ),
        AppOnboardingHint.accompaniment => const OnboardingHintContent(
            title: 'Begleitung',
            body:
                'Hier liegt alles, was mit Trainer, Kommunikation und Terminen zu tun hat.',
            items: [
              OnboardingHintItem(
                iconName: 'trainer',
                text: 'Finde Trainer oder verwalte deine aktive Begleitung.',
              ),
              OnboardingHintItem(
                iconName: 'chat',
                text:
                    'Öffne Nachrichten und bleib mit deinem Trainer im Kontakt.',
              ),
              OnboardingHintItem(
                iconName: 'calendar',
                text: 'Sieh Terminvorschläge und geplante Termine an.',
              ),
            ],
          ),
        AppOnboardingHint.profile => const OnboardingHintContent(
            title: 'Profil',
            body:
                'Im Profil findest du Konto, Einstellungen und administrative Zugänge.',
            items: [
              OnboardingHintItem(
                iconName: 'settings',
                text: 'Passe Sprache, Darstellung und Erinnerungen an.',
              ),
              OnboardingHintItem(
                iconName: 'account',
                text: 'Verwalte Account, Passwort und Profilinformationen.',
              ),
              OnboardingHintItem(
                iconName: 'work',
                text:
                    'Öffne Trainer- oder Admin-Bereiche, wenn sie für dich freigeschaltet sind.',
              ),
            ],
          ),
      };
}

final onboardingHintControllerProvider =
    StateNotifierProvider<OnboardingHintController, int>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final userId = ref.watch(authStateProvider).valueOrNull?.session?.user.id ??
      Supabase.instance.client.auth.currentUser?.id;
  return OnboardingHintController(prefs, userId);
});

class OnboardingHintController extends StateNotifier<int> {
  OnboardingHintController(this._prefs, this._userId) : super(0);

  final SharedPreferences _prefs;
  final String? _userId;
  final Set<AppOnboardingHint> _dismissedThisSession = {};

  bool shouldShow(AppOnboardingHint hint) {
    if (_userId == null) return false;
    if (_dismissedThisSession.contains(hint)) return false;
    return _prefs.getBool(_prefKey(hint)) != true;
  }

  void dismissForSession(AppOnboardingHint hint) {
    _dismissedThisSession.add(hint);
    state++;
  }

  Future<void> hidePermanently(AppOnboardingHint hint) async {
    _dismissedThisSession.add(hint);
    await _prefs.setBool(_prefKey(hint), true);
    state++;
  }

  Future<void> resetAll() async {
    _dismissedThisSession.clear();
    for (final hint in AppOnboardingHint.values) {
      await _prefs.remove(_prefKey(hint));
    }
    state++;
  }

  String _prefKey(AppOnboardingHint hint) =>
      'onboarding_hint.v1.${_userId ?? 'anonymous'}.${hint.storageKey}.hidden';
}
