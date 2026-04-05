import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/appointment.dart';
import '../../domain/models/trainer_client.dart';

// ── User role ─────────────────────────────────────────────────────────────────

final userRoleProvider = FutureProvider<String>((ref) async {
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
    final code = await Supabase.instance.client.rpc('create_invite_code') as String;
    await refresh();
    return code;
  }

  Future<void> saveNotes(String relationshipId, String notes) async {
    await Supabase.instance.client
        .from('trainer_client_relationships')
        .update({'trainer_notes': notes})
        .eq('id', relationshipId);
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

/// Activates the trainer role for the current user.
/// [enteredCode] must match [trainerCode] from AppConfig (or be empty in dev).
/// Returns null on success, or an error message string on failure.
Future<String?> activateTrainerRole(String enteredCode, String trainerCode, bool isDev) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return 'Nicht eingeloggt.';

  // In dev mode without a configured code, allow direct activation for testing.
  final codeRequired = trainerCode.isNotEmpty;
  if (codeRequired && enteredCode.trim().toUpperCase() != trainerCode.toUpperCase()) {
    return 'Ungültiger Code.';
  }
  if (!isDev && !codeRequired) {
    return 'Trainer-Code nicht konfiguriert. Bitte TRAINER_CODE in .env setzen.';
  }

  await Supabase.instance.client
      .from('profiles')
      .update({'role': 'trainer'})
      .eq('id', userId);
  return null;
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
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return null;
  final res = await Supabase.instance.client
      .from('trainer_client_relationships')
      .select('profiles!trainer_id(display_name)')
      .eq('client_id', userId)
      .eq('status', 'active')
      .maybeSingle();
  if (res == null) return null;
  final profile = res['profiles'] as Map<String, dynamic>?;
  return (profile?['display_name'] as String?) ?? 'Trainer';
});
