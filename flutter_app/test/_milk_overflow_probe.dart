import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vanix/state/app_state.dart';
import 'package:vanix/screens/milk_log_screen.dart';
void main() {
  testWidgets('milk log renders at phone width without overflow', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: MilkLogScreen(appState: AppState()..setLanguage('en'))));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
