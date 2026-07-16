// Verifies the Farm Detail hero's manager-edit flow: tapping the pencil opens
// a 3-option chooser (select new manager / send invite / assign to me), and
// sending an invite puts the farm into a pending state.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vanix/state/app_state.dart';
import 'package:vanix/models/farm_models.dart';
import 'package:vanix/screens/farm_detail_screen.dart';

void main() {
  testWidgets('Manager edit: send invite shows pending state', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final appState = AppState()..setLanguage('en');
    final farm = kFarms.first;
    farm.managerInvitePending = false;
    farm.managerInviteEmail = '';

    await tester.pumpWidget(MaterialApp(home: FarmDetailScreen(appState: appState, farm: farm)));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Send Invite to another farm manager'), findsOneWidget);

    await tester.tap(find.text('Send Invite to another farm manager'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'newmanager@test.com');
    await tester.tap(find.text('Confirm & assign'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Invite pending'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
