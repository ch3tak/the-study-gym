import 'package:flutter_test/flutter_test.dart';
import 'package:study_gym/data/models.dart';
import 'package:study_gym/features/workout/numeric_grading.dart';

Question _q(String answer, {double? tolerance}) => Question(
      id: 'q',
      conceptId: 'c',
      type: QuestionType.numeric,
      difficulty: 1,
      marks: 1,
      stem: 's',
      numericAnswer: answer,
      tolerance: tolerance,
      solutionSteps: const [],
    );

void main() {
  group('no tolerance: exact string match (unchanged behaviour)', () {
    test('exact match, whitespace ignored', () {
      expect(isNumericAnswerCorrect(_q('216'), ' 2 16 '), isTrue);
    });
    test('numerically equal but differently written is still rejected', () {
      expect(isNumericAnswerCorrect(_q('216'), '216.0'), isFalse);
    });
    test('empty input is rejected', () {
      expect(isNumericAnswerCorrect(_q('216'), ''), isFalse);
    });
  });

  group('with tolerance', () {
    final q = _q('487.67', tolerance: 0.1);
    test('inside tolerance is accepted, including both boundaries', () {
      expect(isNumericAnswerCorrect(q, '487.67'), isTrue);
      expect(isNumericAnswerCorrect(q, '487.6'), isTrue);
      expect(isNumericAnswerCorrect(q, '487.57'), isTrue);
      expect(isNumericAnswerCorrect(q, '487.77'), isTrue);
    });
    test('outside tolerance is rejected', () {
      expect(isNumericAnswerCorrect(q, '487.5'), isFalse);
      expect(isNumericAnswerCorrect(q, '487.8'), isFalse);
    });
    test('unparseable input is rejected', () {
      expect(isNumericAnswerCorrect(q, 'abc'), isFalse);
    });
    test('a fraction typed by the student is evaluated', () {
      final pyramid = _q('85.33', tolerance: 0.05);
      expect(isNumericAnswerCorrect(pyramid, '256/3'), isTrue);
      expect(isNumericAnswerCorrect(pyramid, '85.3'), isTrue);
      expect(isNumericAnswerCorrect(pyramid, '85.4'), isFalse);
    });
  });

  test('parseNumericInput', () {
    expect(parseNumericInput('-3.5'), -3.5);
    expect(parseNumericInput('1/4'), 0.25);
    expect(parseNumericInput('1/0'), isNull);
    expect(parseNumericInput('1/2/3'), isNull);
    expect(parseNumericInput('x'), isNull);
  });
}
