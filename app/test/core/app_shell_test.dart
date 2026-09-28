import 'package:flutter_test/flutter_test.dart';
import 'package:study_gym/core/router/app_shell.dart';
import 'package:study_gym/data/daily_state.dart';

import '../fixtures/slice1_content.dart';
import '../helpers/pump.dart';

void main() {
  setUp(() {
    loadSlice1Content();
    DailyNotifier.clock = () => DateTime(2026, 9, 30, 10);
  });
  tearDown(() => DailyNotifier.clock = DateTime.now);

  for (final t in themes.entries) {
    testWidgets('four tabs, each showing its screen (${t.key})', (tester) async {
      await pumpScreen(tester, const AppShell(), theme: t.value);

      for (final label in ['Home', 'Learn', 'History', 'Me']) {
        expect(find.text(label), findsWidgets, reason: 'tab $label');
      }
      for (final gone in ['Today', 'Theory', 'Mission']) {
        expect(find.text(gone), findsNothing, reason: '$gone is no longer a tab');
      }
      expect(find.text('Start workout'), findsOneWidget);

      await tester.tap(find.text('Learn').last);
      await tester.pumpAndSettle();
      expect(find.text('Mock papers'), findsOneWidget, reason: 'Tests live at the end of Learn');

      await tester.tap(find.text('History').last);
      await tester.pumpAndSettle();
      expect(find.textContaining('Coming soon'), findsOneWidget);

      await tester.tap(find.text('Me').last);
      await tester.pumpAndSettle();
      expect(find.text('Appearance'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
