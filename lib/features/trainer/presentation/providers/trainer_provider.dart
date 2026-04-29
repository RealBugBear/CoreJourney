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
  Future<List<TrainerClient>> build() {
    ref.watch(authStateProvider);
    return _fetch();
  }

  Future<List<TrainerClient>> _fetch() async {
    if (Supabase.instance.client.auth.currentUser == null) return [];

    await Supabase.instance.client.rpc('reconcile_trainer_clients');
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

final trainerClientsDebugProvider = FutureProvider<String>((ref) async {
  ref.watch(authStateProvider);

  final sb = Supabase.instance.client;
  final user = sb.auth.currentUser;
  if (user == null) return 'auth.uid: nicht eingeloggt';

  final lines = <String>[
    'auth.uid: ${user.id}',
    'email: ${user.email ?? '-'}',
  ];

  try {
    final profile = await sb
        .from('profiles')
        .select('role, display_name')
        .eq('id', user.id)
        .maybeSingle();
    lines.add('profiles.role: ${profile?['role'] ?? '-'}');
    lines.add('profiles.display_name: ${profile?['display_name'] ?? '-'}');
  } catch (e) {
    lines.add('profiles: Fehler $e');
  }

  try {
    final relationships = await sb
        .from('trainer_client_relationships')
        .select('id, client_id, status, linked_at')
        .eq('trainer_id', user.id);
    final list = (relationships as List).cast<Map<String, dynamic>>();
    lines.add('relationships gesamt: ${list.length}');
    lines.add(
      'relationships active: ${list.where((r) => r['status'] == 'active').length}',
    );
    if (list.isNotEmpty) {
      lines.add(
        'relationship statuses: ${list.map((r) => r['status']).join(', ')}',
      );
      lines.add('relationship client_ids:');
      for (final row in list.take(5)) {
        lines.add('- ${row['client_id']} (${row['status']})');
      }
    }
  } catch (e) {
    lines.add('relationships: Fehler $e');
  }

  try {
    final appointments = await sb
        .from('appointments')
        .select('id, trainee_id, status, scheduled_for')
        .eq('trainer_id', user.id);
    final list = (appointments as List).cast<Map<String, dynamic>>();
    lines.add('appointments als trainer: ${list.length}');
    if (list.isNotEmpty) {
      lines.add('appointment trainee_ids:');
      for (final row in list.take(5)) {
        lines.add('- ${row['trainee_id']} (${row['status']})');
      }
    }
  } catch (e) {
    lines.add('appointments: Fehler $e');
  }

  try {
    await sb.rpc('reconcile_trainer_clients');
    lines.add('reconcile_trainer_clients: ok');
  } catch (e) {
    lines.add('reconcile_trainer_clients: Fehler $e');
  }

  try {
    final clients = await sb.rpc('get_trainer_clients');
    final list = clients as List;
    lines.add('get_trainer_clients rows: ${list.length}');
    if (list.isNotEmpty) {
      for (final row in list.take(5)) {
        lines.add('- ${row['client_id']} ${row['display_name']}');
      }
    }
  } catch (e) {
    lines.add('get_trainer_clients: Fehler $e');
  }

  return lines.join('\n');
});

// ── Client sessions (for detail screen) ──────────────────────────────────────

final clientSessionsProvider =
    FutureProvider.family<List<ClientSession>, String>((ref, clientId) async {
  final res = await Supabase.instance.client
      .rpc('get_client_sessions', params: {'p_client_id': clientId});
  final list = (res as List).cast<Map<String, dynamic>>();
  return list.map(ClientSession.fromJson).toList();
});

// ── Appointments (trainer view — confirmed/planned) ───────────────────────────

final _appointmentsRefreshTickProvider = StreamProvider.autoDispose<int>((ref) {
  return Stream.periodic(const Duration(seconds: 10), (tick) => tick);
});

final appointmentsProvider = FutureProvider<List<Appointment>>((ref) async {
  ref.watch(authStateProvider);
  ref.watch(_appointmentsRefreshTickProvider);

  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return [];

  final res = await Supabase.instance.client
      .from('appointments')
      .select('*, profiles!trainee_id(display_name)')
      .eq('trainer_id', userId)
      .inFilter('status', ['planned', 'confirmed']).order('scheduled_for',
          ascending: true);

  final list = (res as List).cast<Map<String, dynamic>>();
  return list.map((row) {
    final profile = row['profiles'] as Map<String, dynamic>?;
    final name = (profile?['display_name'] as String?) ?? 'Trainee';
    return Appointment.fromJson({...row, 'trainee_name': name});
  }).toList();
});

// ── Pending proposals (trainee view) ─────────────────────────────────────────

final traineeProposalsProvider = FutureProvider<List<Appointment>>((ref) async {
  ref.watch(authStateProvider);

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
  await Supabase.instance.client.rpc(
    'confirm_proposed_appointment',
    params: {
      'p_appointment_id': appointmentId,
      'p_chosen_slot': chosen.toUtc().toIso8601String(),
    },
  );

  try {
    await Supabase.instance.client.functions.invoke(
      'notify-appointment-confirmed',
      body: {'appointment_id': appointmentId},
    );
  } catch (_) {
    // The appointment confirmation itself succeeded; notification delivery is
    // best-effort and must not block the trainee flow.
  }
}

// ── Become trainer ───────────────────────────────────────────────────────────

/// Sends [enteredCode] to the activate-trainer Edge Function for server-side
/// validation. The code is never compared on the client — the secret lives
/// only in Supabase project secrets.
/// Returns null on success, or a localised error message on failure.
Future<String?> activateTrainerRole(String enteredCode) async {
  if (Supabase.instance.client.auth.currentUser == null) {
    return 'Nicht eingeloggt.';
  }

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
  } on FunctionException catch (e) {
    final details = e.details;
    if (details is Map && details['error'] is String) {
      return details['error'] as String;
    }
    return e.reasonPhrase ?? e.toString();
  } catch (e) {
    return 'Fehler beim Aktivieren: $e';
  }
}

// ── Accept invite (client side) ───────────────────────────────────────────────

Future<void> acceptInvite(String code) async {
  await Supabase.instance.client
      .rpc('accept_invite', params: {'p_code': code.trim().toUpperCase()});
}

// ── Switch trainer (client side) ─────────────────────────────────────────────

/// Wechselt den Trainer atomar im Backend.
/// accept_invite() übernimmt alles: Deaktivierung alter Beziehungen,
/// Re-Linking bei bestehendem disconnected-Record, Erstellung neuer Beziehung.
/// Kein Client-Side State-Management nötig.
Future<void> switchTrainer(String newInviteCode) async {
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

/// Returns the user_id of the currently linked trainer (null if none).
final clientTrainerIdProvider = FutureProvider<String?>((ref) async {
  ref.watch(authStateProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return null;

  final rel = await Supabase.instance.client
      .from('trainer_client_relationships')
      .select('trainer_id')
      .eq('client_id', userId)
      .eq('status', 'active')
      .maybeSingle();
  return rel?['trainer_id'] as String?;
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
/// Falls back to their role so both sides always know who the chat is with.
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
      .select('display_name, role')
      .eq('id', partnerId)
      .maybeSingle();
  final displayName = profile?['display_name'] as String?;
  if (displayName != null && displayName.trim().isNotEmpty) {
    return displayName.trim();
  }

  final role = profile?['role'] as String?;
  return role == 'trainer' ? 'Dein Trainer' : 'Dein Nutzer';
});
