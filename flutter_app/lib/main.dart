import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'state/app_state.dart';
import 'theme/vanix_theme.dart';

void main() {
  runApp(VanixApp());
}

class VanixApp extends StatelessWidget {
  final AppState appState = AppState();
  VanixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        return MaterialApp(
          title: 'MyBovine',
          debugShowCheckedModeBanner: false,
          theme: vanixLightTheme(languageCode: appState.languageCode),
          darkTheme: vanixDarkTheme(languageCode: appState.languageCode),
          themeMode: appState.isDark ? ThemeMode.dark : ThemeMode.light,
          home: LoginScreen(appState: appState),
        );
      },
    );
  }
}
