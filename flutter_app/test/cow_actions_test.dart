// Verifies the cow-profile floating "+" actions sheet flow engine (ported from
// the prototype.html caViews flow): the sheet opens, and the Heat flow surfaces
// the newly-added date + time fields before confirming.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vanix/state/app_state.dart';
import 'package:vanix/models/farm_models.dart';
import 'package:vanix/screens/cow_profile_screen.dart';

Widget _host(Widget child) => MaterialApp(home: child);

void main() {
  testWidgets('Cow actions sheet: Heat flow shows date + time fields', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final appState = AppState()..setLanguage('en');
    final farm = kFarms.first;
    final cow = farm.cows.first;

    await tester.pumpWidget(_host(
      CowProfileScreen(appState: appState, farm: farm, cow: cow),
    ));
    await tester.pumpAndSettle();

    // Open the actions sheet via the floating "+" FAB.
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Tap "Add Heat" in the main action list.
    await tester.tap(find.text('Add Heat').last);
    await tester.pumpAndSettle();

    // Heat confirm step → tap Yes to reach the date/time step.
    expect(find.text('Yes'), findsWidgets);
    await tester.tap(find.text('Yes').last);
    await tester.pumpAndSettle();

    // The new date + time fields must be present for Heat.
    expect(find.text('Event date'), findsWidgets);
    expect(find.text('Time'), findsWidgets);

    // No overflow / exceptions anywhere in the flow.
    expect(tester.takeException(), isNull);
  });
}
