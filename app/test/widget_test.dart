import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:study_gym/main.dart';

void main() {
  testWidgets('App launches to the Welcome screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: StudyGymApp()));
    expect(find.text('Your daily study workout'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
  });
}
