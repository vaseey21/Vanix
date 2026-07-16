import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vanix/screens/dashboard_screen.dart';
import 'package:vanix/state/app_state.dart';

bool _hasText(WidgetTester tester, String needle) {
  for (final e in find.byType(RichText).evaluate()) {
    if ((e.widget as RichText).text.toPlainText().contains(needle)) return true;
  }
  for (final e in find.byType(Text).evaluate()) {
    if (((e.widget as Text).data ?? '').contains(needle)) return true;
  }
  return false;
}

void main() {
  testWidgets('Dashboard v2 renders (light) with no exceptions/overflow', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: DashboardScreen(appState: AppState()..setLanguage('en'))));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('James'), findsOneWidget);
    expect(find.text('Unactioned Alerts'), findsOneWidget);
    // bell + avatar removed
    expect(find.byIcon(Icons.notifications_none), findsNothing);
    // schedule tabs present
    expect(find.text('Today'), findsWidgets);
    expect(find.text('This Week'), findsWidgets);
    // info button (near top) opens the alerts sheet with the triage question
    await tester.tap(find.byIcon(Icons.info_outline));
    await tester.pumpAndSettle();
    expect(_hasText(tester, 'Kajri'), isTrue);
    expect(find.text('Yes, fever'), findsOneWidget);
    await tester.tap(find.text('Yes, fever'));
    await tester.pump();
    expect(_hasText(tester, 'Logged'), isTrue);
    expect(tester.takeException(), isNull);
    // close the sheet, then scroll the dashboard → Updates section builds
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.textContaining('Bhoori'),
      find.byType(Scrollable).first,
      const Offset(0, -300),
    );
    await tester.pump();
    expect(_hasText(tester, 'Bhoori'), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Dashboard v2 renders (dark) with no exceptions', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: DashboardScreen(appState: AppState()..setLanguage('en')..toggleDark())));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('James'), findsOneWidget);
  });
}
