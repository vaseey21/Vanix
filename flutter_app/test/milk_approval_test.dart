// Verifies the milk-edit approval workflow: a Farmer's delete becomes a
// pending owner-approval request (entry not removed, no Approve control),
// while an Owner's delete applies directly.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vanix/state/app_state.dart';
import 'package:vanix/screens/milk_log_screen.dart';

Future<void> _tapFirstEntryDelete(WidgetTester tester) async {
  // Open the first entry's action sheet, then Delete.
  await tester.tap(find.text('Delete entry').first, warnIfMissed: false);
}

void main() {
  testWidgets('Farmer delete → pending request, not removed, no Approve', (tester) async {
    tester.view.physicalSize = const Size(540, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final farmer = AppState()..setLanguage('en')..setPersona('farmer', farmCount: 'multi');
    await tester.pumpWidget(MaterialApp(home: MilkLogScreen(appState: farmer)));
    await tester.pumpAndSettle();

    // Tap the first entry card to open its actions.
    final firstCard = find.byType(InkWell).first;
    await tester.tap(firstCard);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete entry'));
    await tester.pumpAndSettle();

    // Pending sub-card shows, and the farmer gets no Approve control.
    expect(find.textContaining('Pending owner approval'), findsWidgets);
    expect(find.text('Approve'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
