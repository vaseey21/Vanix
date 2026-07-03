import 'package:flutter/material.dart';
import '../i18n/strings.dart';
import '../state/app_state.dart';
import '../theme/vanix_theme.dart';
import '../widgets/vanix_bottom_nav.dart';
import 'events_screen.dart';

/// STUB — Milk Log is fully designed in vanix_screens.html (hero, date-grouped
/// cards, filter bottom sheet, analytics page, add/edit entry, owner approval
/// flow) but not yet ported to Flutter widgets. This screen only wires up
/// navigation parity with the HTML prototype so the nav shell is testable
/// end-to-end; port the real content next in the same pattern as LoginScreen.
class MilkLogScreen extends StatefulWidget {
  final AppState appState;
  const MilkLogScreen({super.key, required this.appState});

  @override
  State<MilkLogScreen> createState() => _MilkLogScreenState();
}

class _MilkLogScreenState extends State<MilkLogScreen> {
  final int _navIndex = 2;

  void _onNavTap(int i) {
    if (i == 0) {
      Navigator.of(context).pop();
      return;
    }
    if (i == 3) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => EventsScreen(appState: widget.appState)));
      return;
    }
    if (i == 4) widget.appState.toggleDark();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        final isDark = widget.appState.isDark;
        final t = VanixStrings.of(widget.appState.languageCode);
        final theme = isDark ? vanixDarkTheme(languageCode: widget.appState.languageCode) : vanixLightTheme(languageCode: widget.appState.languageCode);
        return Theme(
          data: theme,
          child: Scaffold(
            body: Stack(
              children: [
                const Positioned.fill(
                  child: Center(child: Text('Milk Log — port pending\n(see vanix_screens.html)', textAlign: TextAlign.center, style: TextStyle(color: VanixColors.textHint))),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: VanixBottomNav(
                    isDark: isDark,
                    selectedIndex: _navIndex,
                    onTap: _onNavTap,
                    items: [
                      VanixNavItem(icon: Icons.home_outlined, label: t.navHome, showDot: true),
                      VanixNavItem(icon: Icons.pets_outlined, label: t.navFarms),
                      VanixNavItem(icon: Icons.water_drop_outlined, label: t.navMilk),
                      VanixNavItem(icon: Icons.event_note_outlined, label: t.navEvents, badgeCount: 3),
                      VanixNavItem(icon: Icons.person_outline, label: t.navAccount),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
