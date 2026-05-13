import '../../domain/models/reflex_profile_assessment.dart';
import '../../domain/reflex_questionnaire.dart';
import '../../domain/reflex_questionnaire_definitions.dart';

class RelevantAnswerItem {
  const RelevantAnswerItem({
    required this.question,
    required this.selectedOptionLabels,
    this.freeText,
    this.months,
  });

  final ReflexQuestion question;
  final List<String> selectedOptionLabels;
  final String? freeText;
  final int? months;
}

List<(ReflexQuestionModule, List<RelevantAnswerItem>)> buildRelevanteAngaben(
  ReflexProfileAssessment assessment,
) {
  final questionById = {
    for (final q in childParentQuestionnaireV1.questions) q.id: q,
  };

  final Map<ReflexQuestionModule, List<RelevantAnswerItem>> byModule = {};

  for (final entry in assessment.answers.entries) {
    final raw = entry.value;
    if (raw is! Map) continue;

    final question = questionById[entry.key];
    if (question == null) continue;

    final selectedIds =
        (raw['selected_options'] as List?)?.cast<String>() ?? const <String>[];
    final text = raw['text'] as String?;
    final months = raw['months'] as int?;
    final trimmedText = text?.trim();
    final hasFreeText = trimmedText != null && trimmedText.isNotEmpty;

    if (selectedIds.isEmpty && !hasFreeText && months == null) continue;

    final optionLabels = selectedIds.map((id) {
      return question.options
          .firstWhere(
            (o) => o.id == id,
            orElse: () => ReflexQuestionOption(id: id, label: id),
          )
          .label;
    }).toList();

    byModule.putIfAbsent(question.module, () => []).add(
          RelevantAnswerItem(
            question: question,
            selectedOptionLabels: optionLabels,
            freeText: hasFreeText ? trimmedText : null,
            months: months,
          ),
        );
  }

  return [
    for (final module in ReflexQuestionModule.values)
      if (byModule.containsKey(module)) (module, byModule[module]!),
  ];
}

String reflexModuleLabel(ReflexQuestionModule module) => switch (module) {
      ReflexQuestionModule.pregnancyBirth => 'Schwangerschaft & Geburt',
      ReflexQuestionModule.posturePerception => 'Haltung & Wahrnehmung',
      ReflexQuestionModule.motorSkills => 'Motorik',
      ReflexQuestionModule.behaviorEmotion => 'Verhalten & Emotionen',
      ReflexQuestionModule.speech => 'Sprache',
      ReflexQuestionModule.drawingWriting => 'Zeichnen & Schreiben',
      ReflexQuestionModule.school => 'Schule & Konzentration',
      ReflexQuestionModule.other => 'Weitere Beobachtungen',
    };
