import 'package:flutter/material.dart';

/// App-wide state: dark mode + language are both manual toggles that
/// persist across every screen (see CLAUDE.md — dark mode is app-wide,
/// language selection must not reset when navigating between tabs).
///
/// openEventsCount mirrors the JS `evOpen` counter in vanix_screens.html —
/// every nav's Events badge + Home red dot read this same value, so
/// resolving an action card anywhere decrements it everywhere at once.
class AppState extends ChangeNotifier {
  bool _isDark = false;
  String _languageCode = 'en'; // default locale (per design call: English)
  int _openEventsCount = 15; // 14 existing + Vaccination due (new)
  // Persona: 'owner' (full access), 'manager' (owner-dashboard shell,
  // scoped-down Needs Attention + no farm-management surfaces), or
  // 'farmer' (action-first, restricted). farmCount 'single' vs 'multi'
  // controls both Manager's and Farmer's Farms/Home behaviour.
  String _persona = 'owner';
  String _farmCount = 'multi';
  // "text" = plain description-first Events cards (no icons/photos — the
  // pre-illustration-pass design); "image" = the whiteboard-sketched
  // photo-illustration cards (Fever, Heat so far). Toggled next to dark
  // mode on the login screen, applies app-wide.
  bool _displayImageMode = true;

  // Temperature display unit — 'C' (default) or 'F'. Values are always
  // STORED in Celsius everywhere in the model; fmtTemp() only converts for
  // display, mirroring fmtTemp()/vanixTempUnit in prototype.html. Graph axis
  // labels and historical/vet-log temp strings stay in Celsius by design.
  String _tempUnit = 'C';

  bool get isDark => _isDark;
  String get languageCode => _languageCode;
  int get openEventsCount => _openEventsCount;
  bool get displayImageMode => _displayImageMode;
  String get persona => _persona;
  String get farmCount => _farmCount;
  bool get isFarmer => _persona == 'farmer';
  bool get isManager => _persona == 'manager';
  bool get isOwner => _persona == 'owner';
  bool get isSingleFarm => (_persona == 'farmer' || _persona == 'manager') && _farmCount == 'single';
  String get tempUnit => _tempUnit;

  void setTempUnit(String u) {
    if (u != 'C' && u != 'F') return;
    if (u == _tempUnit) return;
    _tempUnit = u;
    notifyListeners();
  }

  /// Formats a Celsius value (accepts a raw number, or a string like
  /// '33°C' / '39.2°C') into the currently selected display unit. Mirrors
  /// fmtTemp() in prototype.html — always stored in Celsius, only the
  /// display string changes.
  String fmtTemp(String celsiusText) {
    final m = RegExp(r'[\d.]+').firstMatch(celsiusText);
    if (m == null) return celsiusText;
    final v = double.tryParse(m.group(0)!);
    if (v == null) return celsiusText;
    if (_tempUnit == 'F') {
      final f = v * 9 / 5 + 32;
      return '${f.toStringAsFixed(1)}°F';
    }
    var s = v.toStringAsFixed(1);
    if (s.endsWith('.0')) s = s.substring(0, s.length - 2);
    return '$s°C';
  }

  /// Cycle Owner → Manager(multi) → Manager(single) → Farmer(multi) →
  /// Farmer(single) → Owner (demo control).
  void cyclePersona() {
    if (_persona == 'owner') {
      _persona = 'manager';
      _farmCount = 'multi';
    } else if (_persona == 'manager' && _farmCount == 'multi') {
      _farmCount = 'single';
    } else if (_persona == 'manager') {
      _persona = 'farmer';
      _farmCount = 'multi';
    } else if (_farmCount == 'multi') {
      _farmCount = 'single';
    } else {
      _persona = 'owner';
    }
    notifyListeners();
  }

  void setPersona(String p, {String farmCount = 'multi'}) {
    _persona = p;
    _farmCount = farmCount;
    notifyListeners();
  }

  void toggleDark() {
    _isDark = !_isDark;
    notifyListeners();
  }

  void toggleDisplayMode() {
    _displayImageMode = !_displayImageMode;
    notifyListeners();
  }

  void setLanguage(String code) {
    if (code == _languageCode) return;
    _languageCode = code;
    notifyListeners();
  }

  void resolveEvent() {
    if (_openEventsCount == 0) return;
    _openEventsCount--;
    notifyListeners();
  }
}
