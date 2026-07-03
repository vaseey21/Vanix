import 'package:flutter/material.dart';
import '../i18n/strings.dart';
import '../state/app_state.dart';
import '../theme/vanix_theme.dart';
import '../widgets/vanix_bottom_nav.dart';
import 'milk_log_screen.dart';

/// STUB — Events (fever/heat/pregnancy action cards, reminders, history,
/// All/Needs-action/Reminders tabs) is fully designed in vanix_screens.html
/// but not yet ported. Wired here only for nav parity — port next.
class EventsScreen extends StatefulWidget {
  final AppState appState;
  const EventsScreen({super.key, required this.appState});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final int _navIndex = 3;

  void _onNavTap(int i) {
    if (i == 0) {
      Navigator.of(context).pop();
      return;
    }
    if (i == 2) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => MilkLogScreen(appState: widget.appState)));
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
                  child: Center(child: Text('Events — port pending\n(see vanix_screens.html)', textAlign: TextAlign.center, style: TextStyle(color: VanixColors.textHint))),
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
