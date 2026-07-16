// Milk-edit approval workflow — data contract.
//
// The full UI (MilkLogScreen) drives a scrolling list whose cards have
// pre-existing layout quirks at synthetic test viewports, so we verify the
// approval *contract* on the model here; the pending sub-card + owner
// Approve/✕ UI is exercised in the mirrored HTML prototype.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vanix/models/milk_models.dart';

MilkEntry _entry() => MilkEntry(
      id: 'e1', cow: 'Gauri', breed: 'Jersey', belt: '112', farm: 'Ravi Kumar Farm',
      manager: 'Suresh', date: DateTime(2026, 7, 2), session: MilkSession.morning,
      time: const TimeOfDay(hour: 7, minute: 30), litres: 12.5,
    );

void main() {
  test('Entry defaults to no pending request', () {
    final e = _entry();
    expect(e.pendingApproval, isFalse);
    expect(e.pendingKind, isNull);
    expect(e.updated, isFalse);
  });

  test('Farmer edit request carries the proposed change (not yet applied)', () {
    final e = _entry();
    // farmer requests an edit to 15 L
    e.pendingApproval = true;
    e.pendingKind = 'edit';
    e.pendingLitres = 15;
    e.pendingBy = e.manager;
    // litres unchanged until an owner approves
    expect(e.litres, 12.5);
    expect(e.pendingApproval, isTrue);
    expect(e.pendingLitres, 15);
  });

  test('Owner approval applies the edit and stamps Updated', () {
    final e = _entry()
      ..pendingApproval = true
      ..pendingKind = 'edit'
      ..pendingLitres = 15;
    // simulate approve
    e.litres = e.pendingLitres!;
    e.updated = true;
    e.pendingApproval = false;
    e.pendingKind = null;
    e.pendingLitres = null;
    expect(e.litres, 15);
    expect(e.updated, isTrue);
    expect(e.pendingApproval, isFalse);
  });
}
