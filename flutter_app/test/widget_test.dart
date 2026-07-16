// Basic smoke test — confirms the app boots and renders its root widget
// without throwing. Replace/extend with real widget tests as screens firm up.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vanix/main.dart';

void main() {
  testWidgets('VanixApp boots without throwing', (WidgetTester tester) async {
    await tester.pumpWidget(const VanixApp());
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
