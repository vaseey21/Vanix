import 'package:flutter/material.dart';
import '../theme/vanix_theme.dart';

/// Small labelled panel wrapping a graph + optional footer — shared by the
/// full-screen heat alert carousel and the per-card "View Details" page so
/// both draw temperature/movement graphs identically. Mirrors the panel
/// markup around #fs-* graphs in vanix_screens.html.
class GraphPanel extends StatelessWidget {
  final bool isDark;
  final String label;
  final Widget child;
  final Widget? footer;
  const GraphPanel({super.key, required this.isDark, required this.label, required this.child, this.footer});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : VanixColors.bgCard,
        border: isDark ? null : Border.all(color: VanixColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.6, color: isDark ? Colors.white.withOpacity(0.6) : VanixColors.textHint)),
          const SizedBox(height: 4),
          child,
          if (footer != null) footer!,
        ],
      ),
    );
  }
}

/// Temperature sparkline. When [highlightLast] is set, the final point (i.e.
/// "today") is drawn as a filled danger-coloured dot so it reads as the spike
/// against the prior baseline days, per the Events card-detail redesign.
class SparklinePainter extends CustomPainter {
  final List<double> values;
  final bool highlightLast;
  SparklinePainter(this.values, {this.highlightLast = false});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final range = (max - min) == 0 ? 1.0 : (max - min);
    final path = Path();
    late Offset lastPoint;
    for (var i = 0; i < values.length; i++) {
      final x = i / (values.length - 1) * size.width;
      final y = size.height - ((values[i] - min) / range) * (size.height - 4) - 2;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      if (i == values.length - 1) lastPoint = Offset(x, y);
    }
    final paint = Paint()
      ..color = VanixColors.warning
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, paint);
    if (highlightLast) {
      canvas.drawCircle(lastPoint, 4, Paint()..color = VanixColors.danger);
      canvas.drawCircle(lastPoint, 4, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.2);
    }
  }

  @override
  bool shouldRepaint(covariant SparklinePainter oldDelegate) => oldDelegate.values != values || oldDelegate.highlightLast != highlightLast;
}

/// Movement/activity bar graph — last N readings as vertical bars. When
/// [highlightLast] is set, today's bar is drawn in danger instead of
/// greenDeep so it stands out against the baseline days.
class MovementBars extends StatelessWidget {
  final List<int> values;
  final bool highlightLast;
  const MovementBars({super.key, required this.values, this.highlightLast = false});

  @override
  Widget build(BuildContext context) {
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: 34,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++) ...[
            if (i > 0) const SizedBox(width: 3),
            Expanded(
              child: FractionallySizedBox(
                heightFactor: values[i] / maxVal,
                child: Container(
                  decoration: BoxDecoration(
                    color: highlightLast && i == values.length - 1 ? VanixColors.danger : VanixColors.greenDeep,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
