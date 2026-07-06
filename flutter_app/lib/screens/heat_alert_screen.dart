import 'package:flutter/material.dart';
import '../theme/vanix_theme.dart';

/// Full-screen "push notification" heat alert — the entry point of the
/// "View full cycle" walkthrough, styled after a MyGate-style gate-visitor
/// approval screen. Mirrors #ev-alert-fullscreen in vanix_screens.html.
///
/// Returns 'yes' / 'no' if the farmer resolves it directly here, or null if
/// dismissed via the close button / "View in app instead" link — the caller
/// then opens the walkthrough bottom sheet in "restricted" detail mode.
class HeatAlertScreen extends StatelessWidget {
  const HeatAlertScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [VanixColors.darkPrimary, VanixColors.darkSecond]),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.of(context).pop(null),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('Green Valley Farm · Belt 41', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.85))),
                  ],
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 104,
                        height: 104,
                        decoration: BoxDecoration(color: VanixColors.warningBg, shape: BoxShape.circle, border: Border.all(color: VanixColors.warning, width: 2)),
                        alignment: Alignment.center,
                        child: const Text('🐄', style: TextStyle(fontSize: 44)),
                      ),
                      const SizedBox(height: 18),
                      const Text('Heat cycle detected — Gauri', textAlign: TextAlign.center, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: Colors.white)),
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text('🌡 Temperature swinging up and down since 04:30', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.75), height: 1.6)),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('🏃 Movement well above her baseline', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.75), height: 1.6)),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48), side: BorderSide(color: Colors.white.withOpacity(0.4)), foregroundColor: Colors.white),
                    onPressed: () => Navigator.of(context).pop('no'),
                    child: const Text('No'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48), backgroundColor: VanixColors.warningInk),
                    onPressed: () => Navigator.of(context).pop('yes'),
                    child: const Text('Yes, in heat'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    child: const Text('View in app instead ›', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: VanixColors.greenDeep)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
