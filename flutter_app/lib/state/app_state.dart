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
  int _openEventsCount = 12;

  bool get isDark => _isDark;
  String get languageCode => _languageCode;
  int get openEventsCount => _openEventsCount;

  void toggleDark() {
    _isDark = !_isDark;
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
