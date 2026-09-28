import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_gym/shared/widgets/course_chip.dart';

import '../helpers/pump.dart';

void main() {
  for (final t in themes.entries) {
    testWidgets('chip shows the active course and opens the switcher (${t.key})', (tester) async {
      await pumpScreen(tester, const Scaffold(body: Center(child: CourseChip())), theme: t.value);
      expect(find.text('Class 9 ▾'), findsOneWidget);

      await tester.tap(find.text('Class 9 ▾'));
      await tester.pumpAndSettle();
      expect(find.text('CBSE Class 9 Maths'), findsOneWidget);
      expect(find.text('CBSE Class 10 Maths'), findsOneWidget);
      expect(find.text('Coming soon'), findsOneWidget);
      expect(find.text('Add a course'), findsOneWidget);

      final class10 = tester.widget<ListTile>(find.widgetWithText(ListTile, 'CBSE Class 10 Maths'));
      expect(class10.enabled, isFalse, reason: 'Class 10 must not be selectable');
    });
  }
}
