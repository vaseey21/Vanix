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
  String _languageCode = 'hi'; // default locale per CLAUDE.md
  int _openEventsCount = 14;
  // Persona: 'owner' (full access) or 'farmer' (action-first, restricted).
  // farmCount 'single' vs 'multi' controls the Farmer's Farms behaviour.
  String _persona = 'owner';
  String _farmCount = 'multi';
  // "text" = plain description-first Events cards (no icons/photos — the
  // pre-illustration-pass design); "image" = the whiteboard-sketched
  // photo-illustration cards (Fever, Heat so far). Toggled next to dark
  // mode on the login screen, applies app-wide.
  bool _displayImageMode = false;

  bool get isDark => _isDark;
  String get languageCode => _languageCode;
  int get openEventsCount => _openEventsCount;
  bool get displayImageMode => _displayImageMode;

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
