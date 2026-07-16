// Verifies the Farmer persona: the simplified action-first dashboard renders
// its Immediate / To-dos tabs, and owner-only Account sections are hidden.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vanix/state/app_state.dart';
import 'package:vanix/screens/farmer_dashboard_screen.dart';
import 'package:vanix/screens/account_screen.dart';

bool _hasText(WidgetTester tester, String needle) {
  for (final e in find.byType(Text).evaluate()) {
    if (((e.widget as Text).data ?? '').contains(needle)) return true;
  }
  return false;
}

void main() {
  testWidgets('Farmer dashboard: Immediate/To-dos tabs render, no overflow', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final appState = AppState()..setLanguage('en')..setPersona('farmer', farmCount: 'multi');
    await tester.pumpWidget(MaterialApp(home: FarmerDashboardScreen(appState: appState)));
    await tester.pump();

    expect(find.text('Immediate'), findsOneWidget);
    expect(find.text('To-dos'), findsOneWidget);
    expect(_hasText(tester, 'Heat detected'), isTrue);
    expect(find.text('Open'), findsWidgets);

    // Switch to To-dos
    await tester.tap(find.text('To-dos'));
    await tester.pump();
    expect(_hasText(tester, 'Insemination window'), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Farmer Account hides owner-only sections', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final farmer = AppState()..setLanguage('en')..setPersona('farmer', farmCount: 'multi');
    await tester.pumpWidget(MaterialApp(home: AccountScreen(appState: farmer)));
    await tester.pump();
    // Farm Management + Cattle Groups + Vet Contacts are owner-only
    expect(find.text('Farm Management'), findsNothing);
    expect(find.text('Cattle Groups'), findsNothing);

    // Owner sees them
    final owner = AppState()..setLanguage('en');
    await tester.pumpWidget(MaterialApp(home: AccountScreen(appState: owner)));
    await tester.pump();
    expect(find.text('Farm Management'), findsWidgets);
  });
}
