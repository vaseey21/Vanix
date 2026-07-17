import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vanix/state/app_state.dart';
import 'package:vanix/screens/events_screen.dart';

void main() {
  for (final w in [360.0, 390.0, 430.0]) {
    testWidgets('Events renders without overflow at width $w', (tester) async {
      tester.view.physicalSize = Size(w, 932);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final app = AppState()..setLanguage('en');
      await tester.pumpWidget(MaterialApp(home: EventsScreen(appState: app)));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull, reason: 'overflow/exception at width $w');
    });
  }
}
