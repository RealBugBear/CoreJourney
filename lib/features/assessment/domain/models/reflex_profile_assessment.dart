class ReflexProfileAssessment {
  const ReflexProfileAssessment({
    required this.id,
    this.packageId,
    this.subjectProfileId,
    required this.questionnaireType,
    required this.questionnaireVersion,
    required this.scoringVersion,
    required this.status,
    required this.answers,
    required this.scores,
    required this.warningConfirmations,
    required this.safetyStatus,
    this.skippedAt,
    this.completedAt,
    required this.createdAt,
    this.ageYearsAtAssessment,
    this.ageMonthsAtAssessment,
    this.ageGroupAtAssessment,
  });

  final String id;
  final String? packageId;
  final String? subjectProfileId;
  final String questionnaireType;
  final String questionnaireVersion;
  final String scoringVersion;
  final String status;
  final Map<String, dynamic> answers;
  final Map<String, dynamic> scores;
  final List<dynamic> warningConfirmations;
  final String safetyStatus;
  final DateTime? skippedAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final int? ageYearsAtAssessment;
  final int? ageMonthsAtAssessment;
  final String? ageGroupAtAssessment;

  bool get isSkipped => status == 'skipped';
  bool get isCompleted => status == 'completed';
  bool get hasScores => scores.isNotEmpty;

  factory ReflexProfileAssessment.fromJson(Map<String, dynamic> json) {
    return ReflexProfileAssessment(
      id: json['id'] as String,
      packageId: json['package_id'] as String?,
      subjectProfileId: json['subject_profile_id'] as String?,
      questionnaireType:
          json['questionnaire_type'] as String? ?? 'child_parent_report',
      questionnaireVersion:
          json['questionnaire_version'] as String? ?? 'pending_expert_v1',
      scoringVersion:
          json['scoring_version'] as String? ?? 'score_equal_weight_v1',
      status: json['status'] as String? ?? 'skipped',
      answers: (json['answers'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{},
      scores: (json['scores'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{},
      warningConfirmations:
          (json['warning_confirmations'] as List?) ?? const <dynamic>[],
      safetyStatus: json['safety_status'] as String? ?? 'clear',
      skippedAt: json['skipped_at'] == null
          ? null
          : DateTime.parse(json['skipped_at'] as String).toLocal(),
      completedAt: json['completed_at'] == null
          ? null
          : DateTime.parse(json['completed_at'] as String).toLocal(),
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      ageYearsAtAssessment: json['age_years_at_assessment'] as int?,
      ageMonthsAtAssessment: json['age_months_at_assessment'] as int?,
      ageGroupAtAssessment: json['age_group_at_assessment'] as String?,
    );
  }
}
