import 'package:flutter/material.dart';
import '../i18n/strings.dart';
import '../state/app_state.dart';
import 'vanix_bottom_nav.dart';

/// Builds the standard 5-tab item set with the Events badge/dot wired to
/// AppState.openEventsCount — every screen's nav bar stays in sync since
/// they all read the same counter (mirrors the JS evUpdateBadges()).
List<VanixNavItem> buildVanixNavItems(VanixStrings t, AppState appState) {
  final count = appState.openEventsCount;
  return [
    VanixNavItem(icon: Icons.home_outlined, label: t.navHome, showDot: count > 0),
    // Farms — custom cow-head line icon (no Material equivalent), matching the
    // stroke SVG in prototype.html's nav.
    VanixNavItem(iconBuilder: (color) => CowHeadIcon(color: color, size: 20), label: t.navFarms),
    VanixNavItem(icon: Icons.water_drop_outlined, label: t.navMilk),
    VanixNavItem(icon: Icons.calendar_today_outlined, label: t.navEvents, badgeCount: count),
    VanixNavItem(icon: Icons.account_circle_outlined, label: t.navAccount),
  ];
}
