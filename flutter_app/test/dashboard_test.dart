import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vanix/screens/dashboard_screen.dart';
import 'package:vanix/state/app_state.dart';

// Searches both Text and RichText/TextSpan trees for a substring.
bool _hasText(WidgetTester tester, String needle) {
  for (final e in find.byType(RichText).evaluate()) {
    final rt = e.widget as RichText;
    if (rt.text.toPlainText().contains(needle)) return true;
  }
  for (final e in find.byType(Text).evaluate()) {
    final tw = e.widget as Text;
    if ((tw.data ?? '').contains(needle)) return true;
  }
  return false;
}

void main() {
  testWidgets('DashboardScreen renders (light) with no exceptions/overflow', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: DashboardScreen(appState: AppState()..setLanguage('en'))));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('James'), findsOneWidget);
    expect(find.text('77'), findsOneWidget);
    expect(_hasText(tester, 'Kajri'), isTrue);
    expect(find.text('Sunrise Dairy'), findsWidgets);
    // triage buttons render; tapping "Yes, fever" collapses to logged state
    expect(_hasText(tester, 'Yes, fever'), isTrue);
    await tester.tap(find.text('Yes, fever'), warnIfMissed: false);
    await tester.pump();
    expect(_hasText(tester, 'Logged'), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('DashboardScreen renders (dark) with no exceptions', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final app = AppState()..setLanguage('en')..toggleDark();
    await tester.pumpWidget(MaterialApp(home: DashboardScreen(appState: app)));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('James'), findsOneWidget);
  });
}
