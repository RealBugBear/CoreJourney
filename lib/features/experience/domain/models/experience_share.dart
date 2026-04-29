class ExperienceShare {
  final String id;
  final String packageId;
  final String? moodCheckinId;
  final String userId;
  final String displayName;
  final bool isAnonymous;
  final String? content;
  final int? mood;
  final int? energy;
  final int? stress;
  final DateTime createdAt;

  const ExperienceShare({
    required this.id,
    required this.packageId,
    this.moodCheckinId,
    required this.userId,
    required this.displayName,
    required this.isAnonymous,
    this.content,
    this.mood,
    this.energy,
    this.stress,
    required this.createdAt,
  });

  String get authorLabel => isAnonymous ? 'Anonym' : displayName;

  factory ExperienceShare.fromJson(Map<String, dynamic> json) => ExperienceShare(
        id: json['id'] as String,
        packageId: json['package_id'] as String,
        moodCheckinId: json['mood_checkin_id'] as String?,
        userId: json['user_id'] as String,
        displayName: json['display_name'] as String,
        isAnonymous: (json['is_anonymous'] as bool?) ?? false,
        content: json['content'] as String?,
        mood: json['mood'] as int?,
        energy: json['energy'] as int?,
        stress: json['stress'] as int?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

/// Input model for creating a new share (no id/createdAt — Supabase generates those).
class ExperienceShareInsert {
  final String packageId;
  final String? moodCheckinId;
  final String userId;
  final String displayName;
  final bool isAnonymous;
  final String? content;
  final int? mood;
  final int? energy;
  final int? stress;

  const ExperienceShareInsert({
    required this.packageId,
    this.moodCheckinId,
    required this.userId,
    required this.displayName,
    required this.isAnonymous,
    this.content,
    this.mood,
    this.energy,
    this.stress,
  });

  Map<String, dynamic> toJson() => {
        'package_id': packageId,
        if (moodCheckinId != null) 'mood_checkin_id': moodCheckinId,
        'user_id': userId,
        'display_name': displayName,
        'is_anonymous': isAnonymous,
        if (content != null) 'content': content,
        if (mood != null) 'mood': mood,
        if (energy != null) 'energy': energy,
        if (stress != null) 'stress': stress,
      };
}
