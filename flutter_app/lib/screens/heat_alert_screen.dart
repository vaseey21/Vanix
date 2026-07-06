import 'package:flutter/material.dart';
import '../theme/vanix_theme.dart';

/// One heat alert's data for the full-screen carousel.
class _HeatAlertData {
  final String name, farm, time, reason;
  final List<double> temps;
  final List<int> moves;
  const _HeatAlertData({required this.name, required this.farm, required this.time, required this.reason, required this.temps, required this.moves});
}

/// Multiple cows in heat at once — same card design, different data.
/// Mirrors FS_ALERTS in vanix_screens.html.
const List<_HeatAlertData> _kAlerts = [
  _HeatAlertData(
    name: 'Gauri', farm: 'Green Valley Farm · Belt 41', time: '04:30',
    reason: 'Temperature crossed her 10-day baseline 4 times in 6h while activity doubled — classic heat signature.',
    temps: [38.4, 38.5, 38.9, 38.6, 39.1, 38.7, 39.3, 38.8, 39.4, 39.2],
    moves: [3, 4, 3, 6, 7, 6, 8, 9, 8, 9],
  ),
  _HeatAlertData(
    name: 'Mohini', farm: 'Sunrise Dairy · Belt 91', time: '05:10',
    reason: 'Restlessness overnight with a rising temperature trend since 05:10 — matches her last confirmed heat.',
    temps: [38.3, 38.4, 38.6, 38.5, 38.8, 39.0, 38.9, 39.2, 39.1, 39.3],
    moves: [2, 3, 4, 4, 5, 7, 7, 8, 9, 9],
  ),
  _HeatAlertData(
    name: 'Dhauli', farm: 'Green Valley Farm · Belt 17', time: '05:45',
    reason: 'Mounting behaviour flagged by the collar plus a temperature swing outside her normal band.',
    temps: [38.5, 38.7, 38.6, 39.0, 38.8, 39.2, 39.0, 39.4, 39.1, 39.5],
    moves: [4, 4, 5, 6, 6, 8, 7, 9, 9, 8],
  ),
];

/// Full-screen "push notification" heat alert carousel — the entry point of
/// the "View full cycle" walkthrough, styled after a MyGate-style approval
/// screen. Mirrors #ev-alert-fullscreen in vanix_screens.html.
///
/// Swipe or use the arrows to move between cards; actioning one auto-advances
/// to the next unresolved card. Once every card is actioned, pops with the
/// FIRST card's (Gauri's) decision — 'yes' / 'no' — since she is the cow the
/// walkthrough narrates. Dismissing via ✕ or "View in app instead" pops null,
/// and the caller opens the walkthrough in "restricted" detail mode.
class HeatAlertScreen extends StatefulWidget {
  const HeatAlertScreen({super.key});

  @override
  State<HeatAlertScreen> createState() => _HeatAlertScreenState();
}

class _HeatAlertScreenState extends State<HeatAlertScreen> {
  final _pageCtrl = PageController();
  int _index = 0;
  final List<String?> _decisions = List.filled(_kAlerts.length, null);

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _goTo(int i) {
    if (i < 0 || i >= _kAlerts.length) return;
    _pageCtrl.animateToPage(i, duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
  }

  void _action(int i, String decision) {
    if (_decisions[i] != null) return;
    setState(() => _decisions[i] = decision);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final next = _decisions.indexWhere((d) => d == null);
      if (next >= 0) {
        _goTo(next);
      } else {
        Navigator.of(context).pop(_decisions[0]);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [VanixColors.darkPrimary, VanixColors.darkSecond]),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    Text('${_index + 1} of ${_kAlerts.length}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.75))),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: _pageCtrl,
                      itemCount: _kAlerts.length,
                      onPageChanged: (i) => setState(() => _index = i),
                      itemBuilder: (context, i) => _AlertCard(
                        data: _kAlerts[i],
                        decision: _decisions[i],
                        onYes: () => _action(i, 'yes'),
                        // "No" defers the decision to the in-app card — pop
                        // null so the caller opens the restricted sheet view.
                        onNo: () => Navigator.of(context).pop(null),
                      ),
                    ),
                    PositionedDirectional(
                      start: 8,
                      top: 0,
                      bottom: 0,
                      child: Center(child: _ArrowButton(icon: Icons.chevron_left, onTap: () => _goTo(_index - 1))),
                    ),
                    PositionedDirectional(
                      end: 8,
                      top: 0,
                      bottom: 0,
                      child: Center(child: _ArrowButton(icon: Icons.chevron_right, onTap: () => _goTo(_index + 1))),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 10),
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('View in app instead ›', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: VanixColors.greenDeep)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ArrowButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final _HeatAlertData data;
  final String? decision;
  final VoidCallback onYes, onNo;
  const _AlertCard({required this.data, required this.decision, required this.onYes, required this.onNo});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(48, 8, 48, 4),
      child: Column(
        children: [
          Text('${data.farm} · detected ${data.time}', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.75))),
          const SizedBox(height: 12),
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(color: VanixColors.warningBg, shape: BoxShape.circle, border: Border.all(color: VanixColors.warning, width: 2)),
            alignment: Alignment.center,
            child: const Text('🐄', style: TextStyle(fontSize: 36)),
          ),
          const SizedBox(height: 12),
          Text('Heat cycle detected — ${data.name}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 6),
          Text(data.reason, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.75), height: 1.6)),
          const SizedBox(height: 12),
          _GraphPanel(
            label: 'TEMPERATURE — LAST 10 READINGS',
            child: SizedBox(
              height: 34,
              width: double.infinity,
              child: CustomPaint(painter: _SparklinePainter(data.temps)),
            ),
            footer: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${data.temps.reduce((a, b) => a < b ? a : b).toStringAsFixed(1)}°C', style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.6))),
                Text('${data.temps.reduce((a, b) => a > b ? a : b).toStringAsFixed(1)}°C', style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.6))),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _GraphPanel(
            label: 'MOVEMENT — ACTIVITY INDEX',
            child: SizedBox(
              height: 34,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < data.moves.length; i++) ...[
                    if (i > 0) const SizedBox(width: 3),
                    Expanded(
                      child: FractionallySizedBox(
                        heightFactor: data.moves[i] / data.moves.reduce((a, b) => a > b ? a : b),
                        child: Container(decoration: BoxDecoration(color: VanixColors.greenDeep, borderRadius: BorderRadius.circular(2))),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (decision != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('Acknowledged ✓ — ${data.name} marked ${decision == 'yes' ? 'in heat' : 'not in heat'}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: VanixColors.greenDeep)),
            )
          else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                // Primary CTA: greenDeep fill with dark text (locked token rule).
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48), backgroundColor: VanixColors.greenDeep, foregroundColor: VanixColors.darkPrimary),
                onPressed: onYes,
                child: const Text('Yes, in heat'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48), side: BorderSide(color: Colors.white.withOpacity(0.4)), foregroundColor: Colors.white),
                onPressed: onNo,
                child: const Text('No'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GraphPanel extends StatelessWidget {
  final String label;
  final Widget child;
  final Widget? footer;
  const _GraphPanel({required this.label, required this.child, this.footer});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.6, color: Colors.white.withOpacity(0.6))),
          const SizedBox(height: 4),
          child,
          if (footer != null) footer!,
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  _SparklinePainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final range = (max - min) == 0 ? 1.0 : (max - min);
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = i / (values.length - 1) * size.width;
      final y = size.height - ((values[i] - min) / range) * (size.height - 4) - 2;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final paint = Paint()
      ..color = VanixColors.warning
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) => oldDelegate.values != values;
}
