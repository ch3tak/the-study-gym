import 'package:flutter_test/flutter_test.dart';
import 'package:study_gym/data/content_repository.dart';
import 'package:study_gym/data/models.dart';

Map<String, dynamic> _chapterRow(String id) => {
      'id': id,
      'subject_id': 'cbse_9_maths',
      'name': 'Chapter $id',
      'board_weight': 5,
      'sort_order': 1,
      'subjects': {'class_id': 'cbse_9', 'code': 'maths', 'status': 'live'},
    };

Map<String, dynamic> _conceptRow(String id, String chapterId) =>
    {'id': id, 'chapter_id': chapterId, 'name': 'Concept $id', 'sort_order': 1};

Map<String, dynamic> _questionRow(String id, Map<String, dynamic> body, {int? level}) => {
      'id': id,
      'concept_ids': ['c1'],
      'difficulty': 1,
      'type': 'mcq',
      'marks': 1,
      'body': body,
      'level': level,
      'stage': level == null ? null : 'FOUNDATION',
    };

Map<String, dynamic> _mcq([Map<String, dynamic> extra = const {}]) => {
      'stem': 's',
      'options': ['a', 'b'],
      'correctIndex': 0,
      ...extra,
    };

void main() {
  final repo = ContentRepository.forTesting();

  test('units load and each chapter carries its unit', () {
    final snap = repo.buildSnapshot(
      chapterRows: [_chapterRow('geo')],
      conceptRows: [_conceptRow('c1', 'geo')],
      questionRows: const [],
      unitRows: [
        {'id': 'cbse_9_maths.geometry', 'name': 'Geometry', 'marks': 25, 'sort_order': 4},
      ],
      chapterUnitRows: [
        {'id': 'geo', 'unit_id': 'cbse_9_maths.geometry'},
      ],
    );
    expect(snap.units.single.name, 'Geometry');
    expect(snap.units.single.marks, 25);
    expect(snap.units.single.sortOrder, 4);
    expect(snap.chapters.single.unitId, 'cbse_9_maths.geometry');
  });

  test('without the units migration, chapters load with no unit', () {
    final snap = repo.buildSnapshot(
      chapterRows: [_chapterRow('geo')],
      conceptRows: [_conceptRow('c1', 'geo')],
      questionRows: const [],
    );
    expect(snap.units, isEmpty);
    expect(snap.chapters.single.unitId, isNull);
  });

  test("a question body's node and whyAfterPrevious are parsed", () {
    final snap = repo.buildSnapshot(
      chapterRows: [_chapterRow('geo')],
      conceptRows: [_conceptRow('c1', 'geo')],
      questionRows: [
        _questionRow('q1', _mcq({'node': 'spot_the_mistake'})),
        _questionRow('q2', _mcq({'whyAfterPrevious': 'Because.'}), level: 1),
        _questionRow('q3', _mcq({'node': 'nonsense'})),
      ],
    );
    final byId = {for (final q in snap.questions) q.id: q};
    expect(byId['q1']!.node, TopicNode.spotTheMistake);
    expect(byId['q2']!.whyAfterPrevious, 'Because.');
    expect(byId['q2']!.node, isNull);
    expect(byId['q3']!.node, isNull);
  });
}
