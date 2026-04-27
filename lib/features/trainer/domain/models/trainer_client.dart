class TrainerClient {
  final String relationshipId;
  final String clientId;
  final String displayName;
  final String? packageId;
  final int currentDay;
  final int dailyStreak;
  final DateTime? lastActivityDate;
  final String? trainerNotes;
  final DateTime? linkedAt;

  const TrainerClient({
    required this.relationshipId,
    required this.clientId,
    required this.displayName,
    this.packageId,
    required this.currentDay,
    required this.dailyStreak,
    this.lastActivityDate,
    this.trainerNotes,
    this.linkedAt,
  });

  bool get isAtRisk {
    if (lastActivityDate == null) return false;
    final daysSince = DateTime.now().difference(lastActivityDate!).inDays;
    return daysSince >= 2;
  }

  int get totalTrainingDays => 28;

  int get remainingTrainingDays {
    final remaining = totalTrainingDays - currentDay;
    return remaining < 0 ? 0 : remaining;
  }

  bool get needsNextPackageAppointment => remainingTrainingDays <= 5;

  factory TrainerClient.fromJson(Map<String, dynamic> json) {
    return TrainerClient(
      relationshipId: json['relationship_id'] as String,
      clientId: json['client_id'] as String,
      displayName: json['display_name'] as String? ?? 'Client',
      packageId: json['package_id'] as String?,
      currentDay: (json['current_day'] as num?)?.toInt() ?? 1,
      dailyStreak: (json['daily_streak'] as num?)?.toInt() ?? 0,
      lastActivityDate: json['last_activity_date'] != null
          ? DateTime.tryParse(json['last_activity_date'] as String)
          : null,
      trainerNotes: json['trainer_notes'] as String?,
      linkedAt: json['linked_at'] != null
          ? DateTime.tryParse(json['linked_at'] as String)
          : null,
    );
  }
}

class ClientSession {
  final DateTime sessionDate;
  final bool isCompleted;
  final int dayNumber;

  const ClientSession({
    required this.sessionDate,
    required this.isCompleted,
    required this.dayNumber,
  });

  factory ClientSession.fromJson(Map<String, dynamic> json) {
    return ClientSession(
      sessionDate: DateTime.parse(json['session_date'] as String),
      isCompleted: json['is_completed'] as bool? ?? false,
      dayNumber: (json['day_number'] as num?)?.toInt() ?? 0,
    );
  }
}
