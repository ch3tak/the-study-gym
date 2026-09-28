import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_gym/data/models.dart';
import 'package:study_gym/data/node_progress_repository.dart';
import 'package:study_gym/data/node_progress_state.dart';

class FakeNodeRepo implements NodeProgressRepository {
  FakeNodeRepo([this.initial = const {}]);
  final Map<String, Set<TopicNode>> initial;
  final writes = <String>[];

  @override
  Future<Map<String, Set<TopicNode>>> fetchAll() async => initial;

  @override
  Future<void> passNode(String conceptId, TopicNode node) async => writes.add('$conceptId/${node.dbValue}');
}

void main() {
  tearDown(() => NodeProgressNotifier.repositoryOverride = null);

  test('passing a node is remembered and saved once', () async {
    final repo = FakeNodeRepo();
    NodeProgressNotifier.repositoryOverride = repo;
    final c = ProviderContainer();
    addTearDown(c.dispose);
    c.read(nodeProgressProvider);
    await Future<void>.delayed(Duration.zero);

    c.read(nodeProgressProvider.notifier).passNode('c.iden', TopicNode.guided);
    c.read(nodeProgressProvider.notifier).passNode('c.iden', TopicNode.guided);

    expect(c.read(nodeProgressProvider).isPassed('c.iden', TopicNode.guided), isTrue);
    expect(c.read(nodeProgressProvider).isPassed('c.iden', TopicNode.challenge), isFalse);
    expect(repo.writes, ['c.iden/guided']);
  });

  test('hydrates saved passes', () async {
    NodeProgressNotifier.repositoryOverride = FakeNodeRepo({
      'c.iden': {TopicNode.challenge},
    });
    final c = ProviderContainer();
    addTearDown(c.dispose);
    c.read(nodeProgressProvider);
    await Future<void>.delayed(Duration.zero);
    expect(c.read(nodeProgressProvider).isPassed('c.iden', TopicNode.challenge), isTrue);
  });
}
