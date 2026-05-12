enum ReflexQuestionnaireType {
  childParentReport,
  adultSelfReport,
  demoChildShort,
}

enum ReflexQuestionModule {
  pregnancyBirth,
  posturePerception,
  motorSkills,
  behaviorEmotion,
  speech,
  drawingWriting,
  school,
  other,
}

enum ReflexAnswerType {
  yesNoUnknown,
  multiSelectWithText,
  monthsNumber,
  freeText,
}

enum ReflexQuestionRole {
  score,
  context,
  safety,
}

enum ReflexWarningRule {
  none,
  professionalClearanceRequired,
}

enum ReflexScoreBand {
  strong,
  elevated,
  indication,
  inconspicuous,
  insufficientData,
}

enum PrimitiveReflex {
  delay,
  flr,
  moro,
  spinalGalant,
  tlr,
  atnr,
  stnr,
  landau,
  babinski,
  babkin,
  plantar,
  palmar,
  righting,
  rootingSucking,
}

class ReflexQuestionnaireDefinition {
  const ReflexQuestionnaireDefinition({
    required this.id,
    required this.version,
    required this.type,
    required this.title,
    required this.questions,
    required this.scoring,
  });

  final String id;
  final String version;
  final ReflexQuestionnaireType type;
  final String title;
  final List<ReflexQuestion> questions;
  final ReflexScoringDefinition scoring;
}

class ReflexQuestion {
  const ReflexQuestion({
    required this.id,
    required this.number,
    required this.module,
    required this.text,
    required this.answerType,
    this.role = ReflexQuestionRole.score,
    this.reflexes = const [],
    this.warningRule = ReflexWarningRule.none,
    this.helpText,
    this.followUpOf,
    this.options = const [],
    this.excludeFromAdminScience = false,
    this.trainerFlagLabel,
  });

  final String id;
  final int number;
  final ReflexQuestionModule module;
  final String text;
  final ReflexAnswerType answerType;
  final ReflexQuestionRole role;
  final List<PrimitiveReflex> reflexes;
  final ReflexWarningRule warningRule;
  final String? helpText;
  final String? followUpOf;
  final List<ReflexQuestionOption> options;
  final bool excludeFromAdminScience;
  /// Short label shown to trainers when this question is answered "yes".
  /// Set on both clearance-required questions and other clinically relevant ones.
  final String? trainerFlagLabel;

  bool get contributesToScore =>
      role == ReflexQuestionRole.score && reflexes.isNotEmpty;
}

class ReflexQuestionOption {
  const ReflexQuestionOption({
    required this.id,
    required this.label,
    this.adminMetricId,
  });

  final String id;
  final String label;
  final String? adminMetricId;
}

class ReflexScoringDefinition {
  const ReflexScoringDefinition({
    required this.strongPercent,
    required this.elevatedPercent,
    required this.indicationPercent,
  });

  final int strongPercent;
  final int elevatedPercent;
  final int indicationPercent;

  ReflexScoreBand bandFor({
    required double percent,
    required int answeredCount,
  }) {
    if (answeredCount == 0) return ReflexScoreBand.insufficientData;
    if (percent >= strongPercent) return ReflexScoreBand.strong;
    if (percent >= elevatedPercent) return ReflexScoreBand.elevated;
    if (percent >= indicationPercent) return ReflexScoreBand.indication;
    return ReflexScoreBand.inconspicuous;
  }
}

class ReflexAnswerValue {
  const ReflexAnswerValue({
    this.yesNoUnknown,
    this.isUnknown = false,
    this.selectedOptionIds = const [],
    this.text,
    this.months,
  });

  final bool? yesNoUnknown;
  final bool isUnknown;
  final List<String> selectedOptionIds;
  final String? text;
  final int? months;

  bool get isAnswered =>
      yesNoUnknown != null ||
      isUnknown ||
      selectedOptionIds.isNotEmpty ||
      (text != null && text!.trim().isNotEmpty) ||
      months != null;

  bool get isAffirmative => yesNoUnknown == true;
}

class ReflexWarningConfirmation {
  const ReflexWarningConfirmation({
    required this.questionId,
    required this.confirmedAt,
    required this.messageVersion,
  });

  final String questionId;
  final DateTime confirmedAt;
  final String messageVersion;
}
