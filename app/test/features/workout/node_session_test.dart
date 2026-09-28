import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_gym/data/app_state.dart';
import 'package:study_gym/data/content.dart';
import 'package:study_gym/data/models.dart';
import 'package:study_gym/data/node_progress_state.dart';
import 'package:study_gym/features/workout/workout_screen.dart';

import '../../fixtures/slice1_content.dart';
import '../../helpers/pump.dart';

Future<ProviderContainer> _openGuided(WidgetTester tester) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  await pumpScreen(
    tester,
    Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => WorkoutScreen.node(concept: Content.conceptById('c.iden'), node: TopicNode.guided),
          )),
          child: const Text('open'),
        ),
      ),
    ),
    container: container,
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return container;
}

void main() {
  setUp(loadSlice1Content);

  testWidgets('a wrong answer comes back at the end; the node passes once all are right', (tester) async {
    final container = await _openGuided(tester);

    expect(find.textContaining('q_iden_g1', findRichText: true), findsOneWidget);
    await tester.tap(find.text('wrong').first);
    await tester.pump();
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();
    expect(find.text('Try again'), findsNothing, reason: 'node sessions requeue instead');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.textContaining('q_iden_g2', findRichText: true), findsOneWidget);
    await answerQuestions(tester, 1);
    expect(container.read(nodeProgressProvider).isPassed('c.iden', TopicNode.guided), isFalse);

    expect(find.textContaining('q_iden_g1', findRichText: true), findsOneWidget, reason: 'g1 returns');
    await answerQuestions(tester, 1);

    expect(find.byType(WorkoutScreen), findsNothing);
    expect(container.read(nodeProgressProvider).isPassed('c.iden', TopicNode.guided), isTrue);
  });

  testWidgets('leaving part-way does not pass the node', (tester) async {
    final container = await _openGuided(tester);
    await answerQuestions(tester, 1);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(container.read(nodeProgressProvider).isPassed('c.iden', TopicNode.guided), isFalse);
  });

  testWidgets('a returning question is recorded in mastery only once', (tester) async {
    final container = await _openGuided(tester);
    await answerQuestions(tester, 1, answer: 'wrong');
    await answerQuestions(tester, 2);
    expect(container.read(studentProvider).mastery['c.iden']!.attempts, 2);
  });
}
