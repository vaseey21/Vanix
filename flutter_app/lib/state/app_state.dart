import 'package:flutter/material.dart';

/// App-wide state: dark mode + language are both manual toggles that
/// persist across every screen (see CLAUDE.md — dark mode is app-wide,
/// language selection must not reset when navigating between tabs).
class AppState extends ChangeNotifier {
  bool _isDark = false;
  String _languageCode = 'hi'; // default locale per CLAUDE.md

  bool get isDark => _isDark;
  String get languageCode => _languageCode;

  void toggleDark() {
    _isDark = !_isDark;
    notifyListeners();
  }

  void setLanguage(String code) {
    if (code == _languageCode) return;
    _languageCode = code;
    notifyListeners();
  }
}
