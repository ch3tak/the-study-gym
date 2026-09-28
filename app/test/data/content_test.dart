import 'package:flutter_test/flutter_test.dart';
import 'package:study_gym/data/content.dart';
import 'package:study_gym/data/models.dart';

import '../fixtures/slice1_content.dart';

void main() {
  setUp(loadSlice1Content);

  test('Trial levels come sorted and only for their chapter', () {
    final levels = Content.trialLevels(savChapter);
    expect(levels.map((q) => q.level), [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
    expect(Content.trialLevels(seqChapter), isEmpty);
    expect(Content.trialLevels('no_such_chapter'), isEmpty);
  });

  test('Trial levels never count as topic questions (interim rule)', () {
    expect(Content.hasTopicQuestions('c.cube'), isFalse, reason: 'c.cube only has Trial levels');
    expect(Content.hasTopicQuestions('c.ap'), isFalse, reason: 'untagged practice questions');
    expect(Content.hasTopicQuestions('c.iden'), isTrue);
    expect(Content.nodeQuestions('c.iden', TopicNode.guided).map((q) => q.id), ['q_iden_g1', 'q_iden_g2']);
    expect(Content.nodeQuestions('c.iden', TopicNode.practice), isEmpty);
  });

  test('practice questions exclude Trial levels', () {
    expect(Content.practiceQuestions('c.cube'), isEmpty);
    expect(Content.practiceQuestions('c.ap'), hasLength(6));
  });

  test('a chapter has content if it has lessons or questions', () {
    expect(Content.hasContent(seqChapter), isTrue);
    expect(Content.hasContent(savChapter), isTrue);
    expect(Content.hasContent(triChapter), isFalse);
  });

  test('units, chapters in a unit, and a concept\'s lesson', () {
    expect(Content.units.map((u) => u.name), ['Algebra', 'Geometry', 'Mensuration']);
    expect(Content.chaptersInUnit('u.algebra').map((c) => c.id), [seqChapter, idenChapter]);
    expect(Content.lessonForConcept('c.cyl')?.id, 't_cyl');
    expect(Content.lessonForConcept('c.ap'), isNull);
  });
}
