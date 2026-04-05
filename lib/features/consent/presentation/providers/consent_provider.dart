import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/settings/settings_provider.dart';

const kConsentVersion = 2;

String consentPrefKey(String userId) =>
    'consent.v$kConsentVersion.$userId.agreed';

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
