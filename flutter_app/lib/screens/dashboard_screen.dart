import 'package:flutter/material.dart';
import '../i18n/strings.dart';
import '../state/app_state.dart';
import '../theme/vanix_theme.dart';
import '../widgets/vanix_bottom_nav.dart';
import '../widgets/vanix_nav_items.dart';
import 'milk_log_screen.dart';
import 'events_screen.dart';
import 'farms_screen.dart';
import 'account_screen.dart';

/// Home dashboard — screen 03 in the build plan (still pending content).
/// The nav shell + tab routing here is final; the dashboard body itself
/// is a placeholder until that screen is designed in vanix_screens.html.
class DashboardScreen extends StatefulWidget {
  final AppState appState;
  const DashboardScreen({super.key, required this.appState});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _navIndex = 0;

  void _onNavTap(int i) {
    if (i == 1) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => FarmsScreen(appState: widget.appState))).then((_) => setState(() {}));
      return;
    }
    if (i == 2) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => MilkLogScreen(appState: widget.appState))).then((_) => setState(() {}));
      return;
    }
    if (i == 3) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => EventsScreen(appState: widget.appState))).then((_) => setState(() {}));
      return;
    }
    if (i == 4) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => AccountScreen(appState: widget.appState))).then((_) => setState(() {}));
      return;
    }
    setState(() => _navIndex = i);
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
                  child: SafeArea(
                    bottom: false,
                    child: Center(child: Text('Dashboard — Screen 03', style: TextStyle(letterSpacing: 1, color: VanixColors.textHint, fontWeight: FontWeight.w500))),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: VanixBottomNav(
                    isDark: isDark,
                    selectedIndex: _navIndex,
                    onTap: _onNavTap,
                    items: buildVanixNavItems(t, widget.appState),
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
