// Verifies Cattle Groups: the page lists seeded groups, and the group model
// supports create + add/remove membership.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vanix/state/app_state.dart';
import 'package:vanix/models/group_models.dart';
import 'package:vanix/screens/groups_screen.dart';

void main() {
  testWidgets('Groups page renders seeded groups + New Group', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(home: GroupsScreen(appState: AppState()..setLanguage('en'))));
    await tester.pump();

    expect(find.text('Jersey'), findsOneWidget);
    expect(find.text('Sahiwal'), findsOneWidget);
    expect(find.text('+ New Group'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('Group membership toggle add/remove', () {
    final g = CattleGroup(id: 'gx', name: 'Test');
    expect(g.has('sunrise', 1), isFalse);
    g.toggle('sunrise', 1, true);
    expect(g.has('sunrise', 1), isTrue);
    expect(g.members.length, 1);
    g.toggle('sunrise', 1, false);
    expect(g.has('sunrise', 1), isFalse);
  });
}
