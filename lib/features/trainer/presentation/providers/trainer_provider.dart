import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../domain/models/appointment.dart';
import '../../domain/models/trainer_client.dart';

// ── User role ─────────────────────────────────────────────────────────────────

final userRoleProvider = FutureProvider<String>((ref) async {
  // Re-run automatically on every auth state change (sign-in / sign-out).
  // Without this, a manual invalidate() during sign-out could race with the
  // Supabase sign-out call and cache 'practitioner' for the next session.
  ref.watch(authStateProvider);

  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return 'practitioner';
  final res = await Supabase.instance.client
      .from('profiles')
      .select('role')
      .eq('id', userId)
      .single();
  return res['role'] as String? ?? 'practitioner';
});

// ── Trainer clients ───────────────────────────────────────────────────────────

class TrainerClientsNotifier extends AsyncNotifier<List<TrainerClient>> {
  @override
  Future<List<TrainerClient>> build() => _fetch();

  Future<List<TrainerClient>> _fetch() async {
    final res = await Supabase.instance.client.rpc('get_trainer_clients');
    final list = (res as List).cast<Map<String, dynamic>>();
    return list.map(TrainerClient.fromJson).toList();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<String> generateInviteCode() async {
    final code =
        await Supabase.instance.client.rpc('create_invite_code') as String;
    await refresh();
    return code;
  }

  Future<void> saveNotes(String relationshipId, String notes) async {
    await Supabase.instance.client
        .from('trainer_client_relationships')
        .update({'trainer_notes': notes}).eq('id', relationshipId);
    await refresh();
  }
}

final trainerClientsProvider =
    AsyncNotifierProvider<TrainerClientsNotifier, List<TrainerClient>>(
  TrainerClientsNotifier.new,
);

// ── Client sessions (for detail screen) ──────────────────────────────────────

final clientSessionsProvider =
    FutureProvider.family<List<ClientSession>, String>((ref, clientId) async {
  final res = await Supabase.instance.client
      .rpc('get_client_sessions', params: {'p_client_id': clientId});
  final list = (res as List).cast<Map<String, dynamic>>();
  return list.map(ClientSession.fromJson).toList();
});

// ── Appointments (trainer view — confirmed/planned) ───────────────────────────

final appointmentsProvider = FutureProvider<List<Appointment>>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return [];

  final res = await Supabase.instance.client
      .from('appointments')
      .select('*, profiles!trainee_id(display_name)')
      .eq('trainer_id', userId)
      .neq('status', 'proposed')
      .order('scheduled_for', ascending: true);

  final list = (res as List).cast<Map<String, dynamic>>();
  return list.map((row) {
    final profile = row['profiles'] as Map<String, dynamic>?;
    final name = (profile?['display_name'] as String?) ?? 'Trainee';
    return Appointment.fromJson({...row, 'trainee_name': name});
  }).toList();
});

// ── Pending proposals (trainee view) ─────────────────────────────────────────

final traineeProposalsProvider = FutureProvider<List<Appointment>>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return [];

  final res = await Supabase.instance.client
      .from('appointments')
      .select('*, profiles!trainer_id(display_name)')
      .eq('trainee_id', userId)
      .eq('status', 'proposed')
      .order('created_at', ascending: false);

  final list = (res as List).cast<Map<String, dynamic>>();
  return list.map((row) {
    final profile = row['profiles'] as Map<String, dynamic>?;
    final trainerName = (profile?['display_name'] as String?) ?? 'Trainer';
    return Appointment.fromJson({...row, 'trainee_name': trainerName});
  }).toList();
});

// ── Confirm a proposed slot (trainee action) ──────────────────────────────────

Future<void> confirmProposedSlot(String appointmentId, DateTime chosen) async {
  final sb = Supabase.instance.client;

  // Fetch trainer/trainee IDs so we can cancel stale appointments
  final apptData = await sb
      .from('appointments')
      .select('trainer_id, trainee_id')
      .eq('id', appointmentId)
      .single();
  final trainerId = apptData['trainer_id'] as String;
  final traineeId = apptData['trainee_id'] as String;

  // Confirm the chosen slot
  await sb.from('appointments').update({
    'status': 'confirmed',
    'scheduled_for': chosen.toIso8601String(),
  }).eq('id', appointmentId);

  // Cancel any other planned/proposed appointments between the same pair
  await sb
      .from('appointments')
      .update({'status': 'cancelled'})
      .eq('trainer_id', trainerId)
      .eq('trainee_id', traineeId)
      .neq('id', appointmentId)
      .inFilter('status', ['planned', 'proposed']);
}

// ── Become trainer ───────────────────────────────────────────────────────────

/// Sends [enteredCode] to the activate-trainer Edge Function for server-side
/// validation. The code is never compared on the client — the secret lives
/// only in Supabase project secrets.
/// Returns null on success, or a localised error message on failure.
Future<String?> activateTrainerRole(String enteredCode) async {
  if (Supabase.instance.client.auth.currentUser == null)
    return 'Nicht eingeloggt.';

  try {
    final session = Supabase.instance.client.auth.currentSession;
    final response = await Supabase.instance.client.functions.invoke(
      'activate-trainer',
      body: {'code': enteredCode.trim()},
      headers: {
        if (session != null) 'Authorization': 'Bearer ${session.accessToken}',
      },
    );
    final data = response.data as Map<String, dynamic>?;
    if (data?['error'] != null) return data!['error'] as String;
    return null;
  } catch (e) {
    return 'Fehler beim Aktivieren. Bitte versuche es erneut.';
  }
}

// ── Accept invite (client side) ───────────────────────────────────────────────

Future<void> acceptInvite(String code) async {
  await Supabase.instance.client
      .rpc('accept_invite', params: {'p_code': code.trim().toUpperCase()});
}

// ── Switch trainer (client side) ─────────────────────────────────────────────

Future<void> switchTrainer(String newInviteCode) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return;
  await Supabase.instance.client
      .from('trainer_client_relationships')
      .update({'status': 'inactive'})
      .eq('client_id', userId)
      .eq('status', 'active');
  await acceptInvite(newInviteCode);
}

// ── Client's linked trainer ───────────────────────────────────────────────────

final clientTrainerProvider = FutureProvider<String?>((ref) async {
  ref.watch(authStateProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return null;

  // Step 1: get trainer_id from relationship (avoid ambiguous multi-FK join)
  final rel = await Supabase.instance.client
      .from('trainer_client_relationships')
      .select('trainer_id')
      .eq('client_id', userId)
      .eq('status', 'active')
      .maybeSingle();
  if (rel == null) return null;

  // Step 2: fetch trainer's display name separately
  final trainerId = rel['trainer_id'] as String;
  final profile = await Supabase.instance.client
      .from('profiles')
      .select('display_name')
      .eq('id', trainerId)
      .maybeSingle();
  return (profile?['display_name'] as String?) ?? 'Trainer';
});

// ── Subscription tier ─────────────────────────────────────────────────────────

/// Returns 'free' or 'premium' for the currently signed-in user.
/// Re-runs on auth state change (same pattern as userRoleProvider).
final subscriptionTierProvider = FutureProvider<String>((ref) async {
  ref.watch(authStateProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return 'free';
  final res = await Supabase.instance.client
      .from('profiles')
      .select('subscription_tier')
      .eq('id', userId)
      .single();
  return res['subscription_tier'] as String? ?? 'free';
});

// ── Trainer linked (bool) ─────────────────────────────────────────────────────

/// True wenn der aktuelle User einen aktiv verknüpften Trainer hat.
/// Leitet sich von clientTrainerProvider ab — kein extra DB-Call.
final trainerLinkedProvider = Provider<bool>((ref) {
  return ref.watch(clientTrainerProvider).valueOrNull != null;
});

// ── Chat partner ──────────────────────────────────────────────────────────────

/// For a direct channel, returns the OTHER participant's user_id.
/// Returns null for community channels or if not found.
final chatPartnerIdProvider =
    FutureProvider.autoDispose.family<String?, String>((ref, channelId) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return null;

  final rows = await Supabase.instance.client
      .from('chat_channel_members')
      .select('user_id')
      .eq('channel_id', channelId)
      .neq('user_id', userId);

  final list = rows as List;
  if (list.isEmpty) return null;
  return list.first['user_id'] as String?;
});

/// For a direct channel, returns the OTHER participant's display name.
/// Falls back to 'Chat' if not found.
final chatPartnerNameProvider =
    FutureProvider.autoDispose.family<String, String>((ref, channelId) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return 'Chat';

  // Step 1: get partner's user_id
  final rows = await Supabase.instance.client
      .from('chat_channel_members')
      .select('user_id')
      .eq('channel_id', channelId)
      .neq('user_id', userId);

  final list = rows as List;
  if (list.isEmpty) return 'Chat';
  final partnerId = list.first['user_id'] as String;

  // Step 2: fetch their display name
  final profile = await Supabase.instance.client
      .from('profiles')
      .select('display_name')
      .eq('id', partnerId)
      .maybeSingle();
  return profile?['display_name'] as String? ?? 'Chat';
});
