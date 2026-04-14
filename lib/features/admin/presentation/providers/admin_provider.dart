import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Trainer code model ────────────────────────────────────────────────────────

class TrainerCode {
  const TrainerCode({
    required this.id,
    required this.code,
    required this.createdAt,
    this.usedAt,
    this.expiresAt,
  });

  final String id;
  final String code;
  final DateTime createdAt;
  final DateTime? usedAt;
  final DateTime? expiresAt;

  bool get isUsed => usedAt != null;
  bool get isExpired =>
      !isUsed &&
      expiresAt != null &&
      expiresAt!.isBefore(DateTime.now());
  bool get isActive => !isUsed && !isExpired;

  factory TrainerCode.fromJson(Map<String, dynamic> json) => TrainerCode(
        id: json['id'] as String,
        code: json['code'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        usedAt: json['used_at'] == null
            ? null
            : DateTime.parse(json['used_at'] as String),
        expiresAt: json['expires_at'] == null
            ? null
            : DateTime.parse(json['expires_at'] as String),
      );
}

// ── Admin provider (trainer codes) ───────────────────────────────────────────

class AdminNotifier extends AsyncNotifier<List<TrainerCode>> {
  @override
  Future<List<TrainerCode>> build() => _fetch();

  Future<List<TrainerCode>> _fetch() async {
    final res = await Supabase.instance.client
        .from('trainer_codes')
        .select()
        .order('created_at', ascending: false);
    return (res as List)
        .cast<Map<String, dynamic>>()
        .map(TrainerCode.fromJson)
        .toList();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<TrainerCode> generate() async {
    final res = await Supabase.instance.client
        .from('trainer_codes')
        .insert({'created_by': Supabase.instance.client.auth.currentUser!.id})
        .select()
        .single();
    final code = TrainerCode.fromJson(res);
    state = state.whenData((codes) => [code, ...codes]);
    return code;
  }
}

final adminProvider =
    AsyncNotifierProvider<AdminNotifier, List<TrainerCode>>(
  AdminNotifier.new,
);

// ── Admin user list (for premium management) ──────────────────────────────────

class AdminUser {
  const AdminUser({
    required this.id,
    required this.displayName,
    required this.role,
    required this.subscriptionTier,
  });

  final String id;
  final String displayName;
  final String role;
  final String subscriptionTier;

  bool get isPremium => subscriptionTier == 'premium';

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
        id: json['id'] as String,
        displayName: json['display_name'] as String? ?? json['id'] as String,
        role: json['role'] as String? ?? 'practitioner',
        subscriptionTier: json['subscription_tier'] as String? ?? 'free',
      );
}

class AdminUsersNotifier extends AsyncNotifier<List<AdminUser>> {
  @override
  Future<List<AdminUser>> build() => _fetch();

  Future<List<AdminUser>> _fetch() async {
    final res = await Supabase.instance.client
        .from('profiles')
        .select('id, display_name, role, subscription_tier')
        .order('display_name')
        .limit(500);
    return (res as List)
        .cast<Map<String, dynamic>>()
        .map(AdminUser.fromJson)
        .toList();
  }

  Future<void> setTier(String userId, String tier) async {
    final session = Supabase.instance.client.auth.currentSession;
    final response = await Supabase.instance.client.functions.invoke(
      'set-subscription-tier',
      body: {'user_id': userId, 'tier': tier},
      headers: {
        if (session != null) 'Authorization': 'Bearer ${session.accessToken}',
      },
    );
    final data = response.data as Map<String, dynamic>;
    if (data['error'] != null) throw Exception(data['error'] as String);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }
}

final adminUsersProvider =
    AsyncNotifierProvider<AdminUsersNotifier, List<AdminUser>>(
  AdminUsersNotifier.new,
);
