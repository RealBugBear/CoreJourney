import 'package:flutter_test/flutter_test.dart';
import 'package:corejourney/features/assessment/domain/models/reflex_profile_assessment.dart';
import 'package:corejourney/features/assessment/domain/reflex_questionnaire.dart';
import 'package:corejourney/features/assessment/presentation/screens/reflex_profile_result_helpers.dart';

ReflexProfileAssessment _assessment(Map<String, dynamic> answers) =>
    ReflexProfileAssessment(
      id: 'test',
      questionnaireType: 'child_parent_report',
      questionnaireVersion: 'child_parent_v1_2026_05',
      scoringVersion: 'score_equal_weight_v1',
      status: 'completed',
      answers: answers,
      scores: const {},
      warningConfirmations: const [],
      safetyStatus: 'clear',
      createdAt: DateTime(2026, 5, 13),
    );

void main() {
  group('buildRelevanteAngaben', () {
    test('pure yes/no answer is excluded', () {
      final result = buildRelevanteAngaben(_assessment({
        'q001': {'answer': 'yes'},
      }));
      expect(result, isEmpty);
    });

    test('pure no answer is excluded', () {
      final result = buildRelevanteAngaben(_assessment({
        'q001': {'answer': 'no'},
      }));
      expect(result, isEmpty);
    });

    test('selected_options resolves option labels and includes item', () {
      // q006 = "Wurden Geburtshilfe-Instrumente eingesetzt?", pregnancyBirth
      // option ids: 'forceps' -> 'Geburtszange', 'vacuum' -> 'Saugglocke'
      final result = buildRelevanteAngaben(_assessment({
        'q006': {
          'answer': 'yes',
          'selected_options': ['vacuum', 'forceps'],
        },
      }));
      expect(result.length, 1);
      final (module, items) = result.first;
      expect(module, ReflexQuestionModule.pregnancyBirth);
      expect(items.length, 1);
      expect(items.first.selectedOptionLabels, ['Saugglocke', 'Geburtszange']);
      expect(items.first.freeText, isNull);
      expect(items.first.months, isNull);
    });

    test('free text is included and trimmed', () {
      // q009 = "Sonstiges zur Geburt", freeText, pregnancyBirth
      final result = buildRelevanteAngaben(_assessment({
        'q009': {'text': '  Nabelschnur zweimal gewickelt  '},
      }));
      expect(result.length, 1);
      expect(result.first.$2.first.freeText, 'Nabelschnur zweimal gewickelt');
      expect(result.first.$2.first.selectedOptionLabels, isEmpty);
    });

    test('blank free text is excluded', () {
      final result = buildRelevanteAngaben(_assessment({
        'q009': {'text': '   '},
      }));
      expect(result, isEmpty);
    });

    test('months value is included', () {
      // q037 = "Wann ist dein Kind das erste Mal gelaufen?", monthsNumber, motorSkills
      final result = buildRelevanteAngaben(_assessment({
        'q037': {'months': 18},
      }));
      expect(result.length, 1);
      final (module, items) = result.first;
      expect(module, ReflexQuestionModule.motorSkills);
      expect(items.first.months, 18);
    });

    test('unknown question ID is silently skipped', () {
      final result = buildRelevanteAngaben(_assessment({
        'q_nonexistent': {'selected_options': ['foo']},
      }));
      expect(result, isEmpty);
    });

    test('unknown option ID falls back to raw id as label', () {
      final result = buildRelevanteAngaben(_assessment({
        'q006': {'selected_options': ['unknown_option_xyz']},
      }));
      expect(result.first.$2.first.selectedOptionLabels, ['unknown_option_xyz']);
    });

    test('groups are ordered by module enum order regardless of answer insertion order', () {
      // q037 = motorSkills (enum index 2), q006 = pregnancyBirth (enum index 0)
      // Insert in reverse order to verify enum-order output
      final result = buildRelevanteAngaben(_assessment({
        'q037': {'months': 18},        // motorSkills
        'q006': {'selected_options': ['vacuum']},  // pregnancyBirth
      }));
      expect(result.length, 2);
      expect(result[0].$1, ReflexQuestionModule.pregnancyBirth);
      expect(result[1].$1, ReflexQuestionModule.motorSkills);
    });

    test('multiple answers in same module appear in the same group', () {
      // q006 and q009 are both pregnancyBirth
      final result = buildRelevanteAngaben(_assessment({
        'q006': {'selected_options': ['vacuum']},
        'q009': {'text': 'Sturzgeburt'},
      }));
      expect(result.length, 1);
      expect(result.first.$2.length, 2);
    });
  });

  group('reflexModuleLabel', () {
    test('returns correct German label for every module', () {
      expect(reflexModuleLabel(ReflexQuestionModule.pregnancyBirth),
          'Schwangerschaft & Geburt');
      expect(reflexModuleLabel(ReflexQuestionModule.posturePerception),
          'Haltung & Wahrnehmung');
      expect(reflexModuleLabel(ReflexQuestionModule.motorSkills), 'Motorik');
      expect(reflexModuleLabel(ReflexQuestionModule.behaviorEmotion),
          'Verhalten & Emotionen');
      expect(reflexModuleLabel(ReflexQuestionModule.speech), 'Sprache');
      expect(reflexModuleLabel(ReflexQuestionModule.drawingWriting),
          'Zeichnen & Schreiben');
      expect(reflexModuleLabel(ReflexQuestionModule.school),
          'Schule & Konzentration');
      expect(reflexModuleLabel(ReflexQuestionModule.other),
          'Weitere Beobachtungen');
    });
  });
}
