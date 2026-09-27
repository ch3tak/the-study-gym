import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:study_gym/main.dart';

import 'test_content.dart';

void main() {
  setUp(() {
    StudyGymApp.contentLoader = fakeContentLoader;
  });

  testWidgets('App launches to the Welcome screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: StudyGymApp()));
    await tester.pumpAndSettle();
    expect(find.text('Your daily study workout'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
  });
}
