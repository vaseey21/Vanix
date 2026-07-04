import 'package:flutter/material.dart';

enum MilkSession { morning, evening }

extension MilkSessionLabel on MilkSession {
  String get label => this == MilkSession.morning ? 'Morning' : 'Evening';
}

/// A single milk-log entry — mirrors the `.m-card.m-entry` dataset attrs
/// in vanix_screens.html (data-cow, data-breed, data-belt, data-sess, …).
class MilkEntry {
  final String id;
  String cow;
  String breed;
  String belt;
  String farm;
  String manager;
  DateTime date;
  MilkSession session;
  TimeOfDay time;
  double litres;
  bool onTime;
  String? lateNote; // e.g. "4h 25m after milking"
  bool pendingApproval;
  String? pendingLabel; // e.g. "+5 L (second entry)"
  bool updated;
  TimeOfDay? updatedAt;

  MilkEntry({
    required this.id,
    required this.cow,
    required this.breed,
    required this.belt,
    required this.farm,
    required this.manager,
    required this.date,
    required this.session,
    required this.time,
    required this.litres,
    this.onTime = true,
    this.lateNote,
    this.pendingApproval = false,
    this.pendingLabel,
    this.updated = false,
    this.updatedAt,
  }) : assert(litres >= 0);
}

class Cow {
  final String name, breed, belt;
  const Cow(this.name, this.breed, this.belt);
  String get display => '$name — $breed — Belt $belt';
}

/// Seed data matching the values already locked in vanix_screens.html
/// (Gauri = today's max, Kajri = today's min, 18 cows milked, 38.6 L total).
class MilkSeed {
  // Breed set matches the Cattle Health Logic v3.1 breed matrix
  // (Ongole, Jersey, Gir/Sahiwal, Desi) — not the earlier invented "HF Cross".
  static const cows = [
    Cow('Gauri', 'Jersey', '41'),
    Cow('Kajri', 'Jersey', '63'),
    Cow('Mohini', 'Desi', '91'),
    Cow('Dhauli', 'Gir/Sahiwal', '18'),
    Cow('Ganga', 'Ongole', '27'),
    Cow('Lakshmi', 'Ongole', '52'),
    Cow('Bhoori', 'Gir/Sahiwal', '09'),
  ];

  static const farms = ['Green Valley Farm', 'Sunrise Dairy'];

  static List<MilkEntry> entries(DateTime today) {
    final yesterday = today.subtract(const Duration(days: 1));
    int seq = 0;
    MilkEntry e({
      required String cow,
      required String breed,
      required String belt,
      required DateTime date,
      required MilkSession session,
      required TimeOfDay time,
      required double litres,
      bool onTime = true,
      String? lateNote,
    }) {
      seq++;
      return MilkEntry(
        id: 'e$seq',
        cow: cow,
        breed: breed,
        belt: belt,
        farm: MilkSeed.farms[0],
        manager: 'Anita',
        date: date,
        session: session,
        time: time,
        litres: litres,
        onTime: onTime,
        lateNote: lateNote,
      );
    }

    return [
      e(cow: 'Gauri', breed: 'HF Cross', belt: '41', date: today, session: MilkSession.morning, time: const TimeOfDay(hour: 7, minute: 5), litres: 12.5),
      e(cow: 'Mohini', breed: 'Gir', belt: '91', date: today, session: MilkSession.morning, time: const TimeOfDay(hour: 7, minute: 15), litres: 5.0),
      e(cow: 'Dhauli', breed: 'Sahiwal', belt: '18', date: today, session: MilkSession.morning, time: const TimeOfDay(hour: 7, minute: 20), litres: 6.8),
      e(cow: 'Ganga', breed: 'Gir', belt: '27', date: today, session: MilkSession.morning, time: const TimeOfDay(hour: 7, minute: 30), litres: 4.2),
      e(cow: 'Lakshmi', breed: 'HF Cross', belt: '52', date: today, session: MilkSession.morning, time: const TimeOfDay(hour: 8, minute: 45), litres: 5.6, onTime: false, lateNote: '1h 45m after milking'),
      e(cow: 'Kajri', breed: 'HF Cross', belt: '63', date: today, session: MilkSession.evening, time: const TimeOfDay(hour: 18, minute: 20), litres: 2.0),
      e(cow: 'Bhoori', breed: 'Sahiwal', belt: '09', date: today, session: MilkSession.evening, time: const TimeOfDay(hour: 18, minute: 5), litres: 2.5),
      e(cow: 'Kajri', breed: 'HF Cross', belt: '63', date: yesterday, session: MilkSession.evening, time: const TimeOfDay(hour: 22, minute: 45), litres: 2.0, onTime: false, lateNote: '4h 25m after milking'),
      e(cow: 'Mohini', breed: 'Gir', belt: '91', date: yesterday, session: MilkSession.morning, time: const TimeOfDay(hour: 7, minute: 15), litres: 5.0),
    ];
  }
}
