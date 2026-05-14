import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/settings/settings_provider.dart';

const kConsentVersion = 2;
const kAnalysisPlaceholderVersion = 1;

String consentPrefKey(String userId) =>
    'consent.v$kConsentVersion.$userId.agreed';

String analysisPlaceholderPrefKey(String userId) =>
    'analysis_placeholder.v$kAnalysisPlaceholderVersion.$userId.seen';

/// Returns true once the current user has seen the analysis questionnaire
/// placeholder that precedes the required consent gate.
final hasSeenAnalysisPlaceholderProvider = FutureProvider<bool>((ref) async {
  final prefs = ref.watch(sharedPreferencesProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return false;
  return prefs.getBool(analysisPlaceholderPrefKey(userId)) == true;
});

/// Returns true when the current user has already consented.
/// Checks local SharedPreferences first; falls back to Supabase.
final hasConsentedProvider = FutureProvider<bool>((ref) async {
  final prefs = ref.watch(sharedPreferencesProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return false;

  if (prefs.getBool(consentPrefKey(userId)) == true) return true;

  try {
    final result = await Supabase.instance.client
        .from('user_consents')
        .select('id')
        .eq('user_id', userId)
        .eq('consent_version', kConsentVersion)
        .maybeSingle();

    if (result != null) {
      await prefs.setBool(consentPrefKey(userId), true);
      return true;
    }
  } catch (_) {}
  return false;
});
