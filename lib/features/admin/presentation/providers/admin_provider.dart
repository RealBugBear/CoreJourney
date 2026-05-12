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
      !isUsed && expiresAt != null && expiresAt!.isBefore(DateTime.now());
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
        .from('trainer_invite_codes')
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
    final session = Supabase.instance.client.auth.currentSession;
    final response = await Supabase.instance.client.functions.invoke(
      'create-trainer-code',
      headers: {
        if (session != null) 'Authorization': 'Bearer ${session.accessToken}',
      },
    );
    final data = response.data;
    if (data is Map && data['error'] != null) {
      throw Exception(data['error'] as String);
    }
    // Refresh the full list so the new code appears with all fields
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
    return state.value!.first;
  }
}

final adminProvider = AsyncNotifierProvider<AdminNotifier, List<TrainerCode>>(
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
  bool get isTrainer => role == 'trainer' || role == 'admin';
  bool get isAdmin => role == 'admin';

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
        id: json['id'] as String,
        displayName: json['display_name'] as String? ?? json['id'] as String,
        role: json['role'] as String? ?? 'practitioner',
        subscriptionTier: json['subscription_tier'] as String? ?? 'free',
      );
}

class AdminTrainerProfile {
  const AdminTrainerProfile({
    required this.id,
    required this.displayName,
    required this.status,
    required this.submittedAt,
    required this.hasLocation,
  });

  final String id;
  final String displayName;
  final String status;
  final DateTime submittedAt;
  final bool hasLocation;

  bool get isPublic => status == 'active';

  factory AdminTrainerProfile.fromJson(Map<String, dynamic> json) {
    return AdminTrainerProfile(
      id: json['id'] as String,
      displayName: json['display_name'] as String? ?? 'Trainer',
      status: json['status'] as String? ?? 'pending',
      submittedAt: DateTime.parse(json['submitted_at'] as String),
      hasLocation: json['location_updated_at'] != null,
    );
  }
}

class AdminExperienceShare {
  const AdminExperienceShare({
    required this.id,
    required this.packageId,
    required this.displayName,
    required this.isAnonymous,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String packageId;
  final String displayName;
  final bool isAnonymous;
  final String content;
  final DateTime createdAt;

  String get authorLabel => isAnonymous ? 'Anonym' : displayName;

  factory AdminExperienceShare.fromJson(Map<String, dynamic> json) {
    return AdminExperienceShare(
      id: json['id'] as String,
      packageId: json['package_id'] as String? ?? '-',
      displayName: json['display_name'] as String? ?? 'Anonym',
      isAnonymous: json['is_anonymous'] as bool? ?? true,
      content: (json['content'] as String?)?.trim() ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
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
    final data = response.data;
    if (data is Map && data['error'] != null) {
      throw Exception(data['error'] as String);
    }
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> setRole(String userId, String role) async {
    final session = Supabase.instance.client.auth.currentSession;
    final response = await Supabase.instance.client.functions.invoke(
      'set-user-role',
      body: {'user_id': userId, 'role': role},
      headers: {
        if (session != null) 'Authorization': 'Bearer ${session.accessToken}',
      },
    );
    final data = response.data;
    if (data is Map && data['error'] != null) {
      throw Exception(data['error'] as String);
    }
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }
}

final adminUsersProvider =
    AsyncNotifierProvider<AdminUsersNotifier, List<AdminUser>>(
  AdminUsersNotifier.new,
);

class AdminTrainerProfilesNotifier
    extends AsyncNotifier<List<AdminTrainerProfile>> {
  @override
  Future<List<AdminTrainerProfile>> build() => _fetch();

  Future<List<AdminTrainerProfile>> _fetch() async {
    final rows = await Supabase.instance.client
        .from('trainer_profiles')
        .select('id, display_name, status, submitted_at, location_updated_at')
        .order('display_name');
    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(AdminTrainerProfile.fromJson)
        .toList();
  }

  Future<void> setPublicStatus(String trainerId, bool visible) async {
    await Supabase.instance.client.rpc(
      'admin_set_trainer_public_status',
      params: {
        'p_trainer_id': trainerId,
        'p_status': visible ? 'active' : 'suspended',
      },
    );
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }
}

final adminTrainerProfilesProvider = AsyncNotifierProvider<
    AdminTrainerProfilesNotifier, List<AdminTrainerProfile>>(
  AdminTrainerProfilesNotifier.new,
);

class AdminExperienceSharesNotifier
    extends AsyncNotifier<List<AdminExperienceShare>> {
  @override
  Future<List<AdminExperienceShare>> build() => _fetch();

  Future<List<AdminExperienceShare>> _fetch() async {
    final rows = await Supabase.instance.client
        .from('experience_shares')
        .select(
            'id, package_id, display_name, is_anonymous, content, created_at')
        .order('created_at', ascending: false)
        .limit(100);
    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(AdminExperienceShare.fromJson)
        .where((share) => share.content.isNotEmpty)
        .toList();
  }

  Future<void> deleteShare(String shareId) async {
    await Supabase.instance.client.rpc(
      'moderator_delete_experience_share',
      params: {'share_id': shareId},
    );
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }
}

final adminExperienceSharesProvider = AsyncNotifierProvider<
    AdminExperienceSharesNotifier, List<AdminExperienceShare>>(
  AdminExperienceSharesNotifier.new,
);

class AdminReflexProfileRollup {
  const AdminReflexProfileRollup({
    required this.questionnaireType,
    required this.ageGroup,
    required this.assessmentCount,
    required this.scores,
    required this.answers,
  });

  final String questionnaireType;
  final String ageGroup;
  final int assessmentCount;
  final List<Map<String, dynamic>> scores;
  final List<Map<String, dynamic>> answers;

  factory AdminReflexProfileRollup.fromJson(Map<String, dynamic> json) {
    return AdminReflexProfileRollup(
      questionnaireType: json['questionnaire_type'] as String? ?? 'unknown',
      ageGroup: json['age_group'] as String? ?? 'unknown',
      assessmentCount: (json['assessment_count'] as num?)?.toInt() ?? 0,
      scores: _jsonMapList(json['scores']),
      answers: _jsonMapList(json['answer_counts']),
    );
  }
}

List<Map<String, dynamic>> _jsonMapList(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => item.cast<String, dynamic>())
      .toList();
}

final adminReflexProfileRollupProvider =
    FutureProvider<List<AdminReflexProfileRollup>>((ref) async {
  final rows =
      await Supabase.instance.client.rpc('get_reflex_profile_admin_rollup');
  if (rows is! List) return const [];
  return rows
      .whereType<Map>()
      .map((row) => AdminReflexProfileRollup.fromJson(
            row.cast<String, dynamic>(),
          ))
      .toList();
});
