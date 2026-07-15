import 'package:flutter/material.dart';

/// Shared farm / cattle / vet demo data — mirrors the FARMS array, VETS list,
/// cow timeline, and vet logs in prototype.html. Kept in one place so the
/// Farms list, Farm Detail, Cow Profile, and Account screens stay consistent.

enum FarmStatus { attention, healthy, setup }

class InfoCell {
  final String labelKey; // resolve via FarmStrings
  final String value;
  final String? valueHi;
  const InfoCell(this.labelKey, this.value, {this.valueHi});
  String v(String lang) => (lang == 'en') ? value : (valueHi ?? value);
}

class CowModel {
  final String name, nameHi;
  final int no;
  final String age, ageHi, belt, beltHi, breed, breedHi;
  final String status; // Milking | Pregnant | Heat | Fever
  final String temp;
  final String trend; // up | down
  final String? photo; // asset path
  final List<InfoCell> info;
  const CowModel({
    required this.name, required this.nameHi, required this.no,
    required this.age, required this.ageHi, required this.belt, required this.beltHi,
    required this.breed, required this.breedHi, required this.status, required this.temp,
    this.trend = 'up', this.photo, this.info = const [],
  });
  String nm(String l) => l == 'en' ? name : nameHi;
  String ag(String l) => l == 'en' ? age : ageHi;
  String bl(String l) => l == 'en' ? belt : beltHi;
  String br(String l) => l == 'en' ? breed : breedHi;
  double get ageYears {
    final m = RegExp(r'[\d.]+').firstMatch(age);
    return m == null ? 0 : double.parse(m.group(0)!);
  }
  String get ageBucket => ageYears < 2 ? 'u2' : ageYears <= 4 ? '2to4' : 'o4';
  bool get isAlert => status == 'Fever' || status == 'Heat';
}

class FarmModel {
  final String id, name, nameHi, location, locationHi, locKey;
  String manager, managerHi;
  final int cattle, milkToday, alerts, critical, heat, fever, insem;
  final String temp;
  final FarmStatus status;
  final List<CowModel> cows;
  FarmModel({
    required this.id, required this.name, required this.nameHi,
    required this.location, required this.locationHi, required this.locKey,
    required this.manager, required this.managerHi, required this.cattle,
    required this.milkToday, required this.alerts, required this.critical,
    required this.heat, required this.fever, required this.insem,
    required this.temp, required this.status, this.cows = const [],
  });
  String nm(String l) => l == 'en' ? name : nameHi;
  String mgr(String l) => l == 'en' ? manager : managerHi;
  String loc(String l) => l == 'en' ? location : locationHi;
  bool get assigned => manager.isNotEmpty && manager != 'Unassigned';
}

/// Farm temperature level caption thresholds (°C).
String farmTempLevelKey(String temp) {
  final m = RegExp(r'[\d.]+').firstMatch(temp);
  if (m == null) return 'tempNormal';
  final v = double.parse(m.group(0)!);
  if (v >= 36) return 'tempVeryHigh';
  if (v >= 33) return 'tempHigh';
  if (v >= 22) return 'tempNormal';
  return 'tempLow';
}

const _mi = 'assets/images/milking_started_photo.jpg';
const _me = 'assets/images/milking_ended_photo.jpg';
const _ge = 'assets/images/gestation_photo.jpg';
const _he = 'assets/images/heat_photo.jpg';
const _fe = 'assets/images/fever_photo.jpg';

final List<FarmModel> kFarms = [
  FarmModel(
    id: 'sunrise', name: 'Sunrise Dairy Farm', nameHi: 'सनराइज़ डेयरी फार्म',
    location: 'Coimbatore, Tamil Nadu', locationHi: 'कोयंबटूर, तमिलनाडु', locKey: 'coimbatore',
    manager: 'Ramesh C', managerHi: 'रमेश सी', cattle: 32, milkToday: 56, alerts: 2, critical: 2,
    heat: 2, fever: 1, insem: 1, temp: '33°C', status: FarmStatus.attention,
    cows: [
      CowModel(name: 'Gowri', nameHi: 'गौरी', no: 1, age: '2.2 yrs', ageHi: '2.2 साल', belt: 'Belt 60', beltHi: 'बेल्ट 60', breed: 'Jersey', breedHi: 'जर्सी', status: 'Milking', temp: '32°C', trend: 'up', photo: _mi, info: [
        InfoCell('labelMilkToday', '12 L'), InfoCell('labelLastMilking', '6:45 AM'), InfoCell('labelLactation', 'Day 45', valueHi: 'दिन 45')]),
      CowModel(name: 'Giri', nameHi: 'गिरि', no: 2, age: '4 yrs', ageHi: '4 साल', belt: 'Belt 12', beltHi: 'बेल्ट 12', breed: 'HF Cross', breedHi: 'एचएफ क्रॉस', status: 'Pregnant', temp: '34°C', trend: 'up', photo: _ge, info: [
        InfoCell('labelDueDate', '12 Aug', valueHi: '12 अगस्त'), InfoCell('labelPregnancy', '5 Months', valueHi: '5 महीने'), InfoCell('labelLastCheck', '15 May', valueHi: '15 मई')]),
      CowModel(name: 'Ramya', nameHi: 'रम्या', no: 3, age: '3 yrs', ageHi: '3 साल', belt: 'Belt 45', beltHi: 'बेल्ट 45', breed: 'Gir', breedHi: 'गिर', status: 'Heat', temp: '36°C', trend: 'up', photo: _he, info: [
        InfoCell('labelHeatDetected', '6:10 AM'), InfoCell('labelInsemination', 'Due Today', valueHi: 'आज देय'), InfoCell('labelHeatStage', 'Standing Heat', valueHi: 'स्टैंडिंग हीट')]),
      CowModel(name: 'Lakshmi', nameHi: 'लक्ष्मी', no: 4, age: '5 yrs', ageHi: '5 साल', belt: 'Belt 08', beltHi: 'बेल्ट 08', breed: 'Sahiwal', breedHi: 'साहीवाल', status: 'Fever', temp: '39.2°C', trend: 'up', photo: _fe, info: [
        InfoCell('labelTempRecorded', '39.2°C'), InfoCell('labelRecordedAt', '9:15 AM'), InfoCell('labelSeverity', 'High', valueHi: 'उच्च')]),
      CowModel(name: 'Nandini', nameHi: 'नंदिनी', no: 5, age: '2.8 yrs', ageHi: '2.8 साल', belt: 'Belt 22', beltHi: 'बेल्ट 22', breed: 'Ongole', breedHi: 'ओंगोल', status: 'Milking', temp: '31°C', trend: 'down', photo: _me, info: [
        InfoCell('labelMilkToday', '8 L'), InfoCell('labelLastMilking', '6:10 AM'), InfoCell('labelLactation', 'Day 30', valueHi: 'दिन 30')]),
    ],
  ),
  FarmModel(
    id: 'greenvilla', name: 'Green Villa Dairy Farm', nameHi: 'ग्रीन विला डेयरी फार्म',
    location: 'Erode, Tamil Nadu', locationHi: 'एरोड, तमिलनाडु', locKey: 'erode',
    manager: 'Rakesh H', managerHi: 'राकेश एच', cattle: 20, milkToday: 42, alerts: 0, critical: 0,
    heat: 0, fever: 0, insem: 0, temp: '31°C', status: FarmStatus.healthy,
    cows: [
      CowModel(name: 'Meera', nameHi: 'मीरा', no: 1, age: '3.5 yrs', ageHi: '3.5 साल', belt: 'Belt 21', beltHi: 'बेल्ट 21', breed: 'Jersey', breedHi: 'जर्सी', status: 'Milking', temp: '31°C', trend: 'up', photo: _mi, info: [
        InfoCell('labelMilkToday', '11 L'), InfoCell('labelLastMilking', '7:00 AM'), InfoCell('labelLactation', 'Day 80', valueHi: 'दिन 80')]),
      CowModel(name: 'Kaveri', nameHi: 'कावेरी', no: 2, age: '2 yrs', ageHi: '2 साल', belt: 'Belt 8', beltHi: 'बेल्ट 8', breed: 'Desi', breedHi: 'देसी', status: 'Milking', temp: '32°C', trend: 'up', photo: _me, info: [
        InfoCell('labelMilkToday', '9 L'), InfoCell('labelLastMilking', '6:30 AM'), InfoCell('labelLactation', 'Day 112', valueHi: 'दिन 112')]),
    ],
  ),
  FarmModel(
    id: 'stones', name: 'Stones Dairy Farm', nameHi: 'स्टोन्स डेयरी फार्म',
    location: 'Salem, Tamil Nadu', locationHi: 'सेलम, तमिलनाडु', locKey: 'salem',
    manager: 'Vimal E', managerHi: 'विमल ई', cattle: 25, milkToday: 20, alerts: 0, critical: 0,
    heat: 0, fever: 0, insem: 0, temp: '30°C', status: FarmStatus.healthy,
    cows: [
      CowModel(name: 'Chinnu', nameHi: 'चिन्नू', no: 1, age: '5 yrs', ageHi: '5 साल', belt: 'Belt 3', beltHi: 'बेल्ट 3', breed: 'Gir', breedHi: 'गिर', status: 'Milking', temp: '30°C', trend: 'up', photo: _mi, info: [
        InfoCell('labelMilkToday', '10 L'), InfoCell('labelLastMilking', '6:15 AM'), InfoCell('labelLactation', 'Day 60', valueHi: 'दिन 60')]),
      CowModel(name: 'Devi', nameHi: 'देवी', no: 2, age: '1.8 yrs', ageHi: '1.8 साल', belt: 'Belt 27', beltHi: 'बेल्ट 27', breed: 'Sahiwal', breedHi: 'साहीवाल', status: 'Pregnant', temp: '31°C', trend: 'up', photo: _ge, info: [
        InfoCell('labelDueDate', '2 Oct', valueHi: '2 अक्टूबर'), InfoCell('labelPregnancy', '3 Months', valueHi: '3 महीने'), InfoCell('labelLastCheck', '20 Jun', valueHi: '20 जून')]),
    ],
  ),
  FarmModel(
    id: 'highland', name: 'Highland Farm', nameHi: 'हाइलैंड फार्म',
    location: '—', locationHi: '—', locKey: 'other',
    manager: 'Unassigned', managerHi: 'नियुक्त नहीं', cattle: 0, milkToday: 0, alerts: 0, critical: 0,
    heat: 0, fever: 0, insem: 0, temp: '—', status: FarmStatus.setup, cows: [],
  ),
];

class VetModel {
  String name;
  final String email, phone;
  String status; // confirmed | pending | declined
  final String? specKey;
  VetModel({required this.name, required this.email, required this.phone, required this.status, this.specKey});
}

final List<VetModel> kVets = [
  VetModel(name: 'Dr. Sharma', email: 'sharma.vet@gmail.com', phone: '+91 98450 11223', status: 'confirmed', specKey: 'vetSpec1'),
  VetModel(name: 'Dr. Rao', email: 'rao.cattle@gmail.com', phone: '+91 99000 44556', status: 'confirmed', specKey: 'vetSpec2'),
  VetModel(name: 'Dr. Iyer', email: 'iyer.vet@gmail.com', phone: '+91 90032 77889', status: 'pending', specKey: 'vetSpec3'),
];

class TimelineEvent {
  final String key; // resolve title + desc via <key> and <key>D
  final String date;
  final Color dot;
  const TimelineEvent(this.key, this.date, this.dot);
}

class VetLog {
  final String titleKey, noteKey, vet, date;
  final String? attachment;
  const VetLog(this.titleKey, this.noteKey, this.vet, this.date, {this.attachment});
}
