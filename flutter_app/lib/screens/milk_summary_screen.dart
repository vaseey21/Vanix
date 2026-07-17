import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme/vanix_theme.dart';

/// Complete-summary / analytics page — mirrors #s7-stats in
/// vanix_screens.html: breed filter, 8-week trend chart, hi/lo tiles,
/// top-5 cows, yield-by-breed bars. Single measure = single hue
/// (greenInk light / greenDeep dark), per the design rule — no legend.
class MilkSummaryScreen extends StatelessWidget {
  final AppState appState;
  const MilkSummaryScreen({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Milk Log'), actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.download_outlined))]),
      body: MilkSummaryContent(appState: appState, padding: const EdgeInsets.fromLTRB(16, 16, 16, 32), showTotalHeader: true),
    );
  }
}

/// Reusable analytics body — breed filter, 8-week trend chart, hi/lo tiles,
/// top-5 cows, yield-by-breed bars. Used both as a standalone route
/// (MilkSummaryScreen) and expanded in place inside the Milk Log page.
class MilkSummaryContent extends StatefulWidget {
  final AppState appState;
  final EdgeInsets padding;
  final bool showTotalHeader;
  const MilkSummaryContent({super.key, required this.appState, this.padding = EdgeInsets.zero, this.showTotalHeader = false});

  @override
  State<MilkSummaryContent> createState() => _MilkSummaryContentState();
}

class _MilkSummaryContentState extends State<MilkSummaryContent> {
  static const _weeks = ['9 Jun', '16 Jun', '23 Jun', '30 Jun', '7 Jul', '14 Jul', '21 Jul', '28 Jul'];
  static const _allTrend = [520.0, 588.0, 540.0, 560.0, 575.0, 610.0, 590.0, 605.0];

  static const _breedTrend = {
    'Jersey': [220.0, 250.0, 230.0, 240.0, 245.0, 260.0, 250.0, 255.0],
    'Ongole': [160.0, 180.0, 165.0, 172.0, 178.0, 190.0, 182.0, 188.0],
    'Gir/Sahiwal': [140.0, 158.0, 145.0, 148.0, 152.0, 160.0, 158.0, 162.0],
    'Desi': [34.0, 38.0, 36.0, 37.0, 39.0, 41.0, 38.0, 40.0],
  };

  String _breed = 'All breeds';
  int? _tooltipIndex;

  List<double> get _trend => _breed == 'All breeds' ? _allTrend : _breedTrend[_breed]!;

  static const _topCows = [
    ('Gauri', 12.5),
    ('Dhauli', 6.8),
    ('Lakshmi', 5.6),
    ('Mohini', 5.0),
    ('Bhoori', 2.5),
  ];

  static const _byBreed = [
    ('Jersey', 255.0),
    ('Ongole', 188.0),
    ('Gir/Sahiwal', 162.0),
    ('Desi', 40.0),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = widget.appState.isDark;
    final textColor = isDark ? Colors.white : VanixColors.textPrimary;
    final hintColor = isDark ? const Color(0xFF8C8780) : VanixColors.textHint;
    final trend = _trend;
    final maxVal = trend.reduce((a, b) => a > b ? a : b);
    final minVal = trend.reduce((a, b) => a < b ? a : b);
    final maxWeek = _weeks[trend.indexOf(maxVal)];
    final minWeek = _weeks[trend.indexOf(minVal)];

    return Scaffold(
      appBar: AppBar(title: const Text('Milk Log'), actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.download_outlined))]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text('TOTAL MILK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 1, color: hintColor)),
          const SizedBox(height: 6),
          const Row(
            children: [
              Text('38.6 L', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700)),
              SizedBox(width: 10),
              Text('▲ 8% vs yesterday', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: VanixColors.greenInk)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _BreedChip(label: 'All breeds', active: _breed == 'All breeds', onTap: () => setState(() { _breed = 'All breeds'; _tooltipIndex = null; })),
                const SizedBox(width: 8),
                _BreedChip(label: 'Jersey', active: _breed == 'Jersey', onTap: () => setState(() { _breed = 'Jersey'; _tooltipIndex = null; })),
                const SizedBox(width: 8),
                _BreedChip(label: 'Ongole', active: _breed == 'Ongole', onTap: () => setState(() { _breed = 'Ongole'; _tooltipIndex = null; })),
                const SizedBox(width: 8),
                _BreedChip(label: 'Gir/Sahiwal', active: _breed == 'Gir/Sahiwal', onTap: () => setState(() { _breed = 'Gir/Sahiwal'; _tooltipIndex = null; })),
                const SizedBox(width: 8),
                _BreedChip(label: 'Desi', active: _breed == 'Desi', onTap: () => setState(() { _breed = 'Desi'; _tooltipIndex = null; })),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('8-week trend', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
          const SizedBox(height: 10),
          GestureDetector(
            onTapDown: (details) {
              final box = context.findRenderObject() as RenderBox?;
              if (box == null) return;
              final width = MediaQuery.of(context).size.width - 32;
              final step = width / (trend.length - 1);
              final idx = (details.localPosition.dx / step).round().clamp(0, trend.length - 1);
              setState(() => _tooltipIndex = idx);
            },
            child: SizedBox(
              height: 140,
              width: double.infinity,
              child: CustomPaint(
                painter: _TrendPainter(values: trend, isDark: isDark, tooltipIndex: _tooltipIndex),
              ),
            ),
          ),
          if (_tooltipIndex != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('${_weeks[_tooltipIndex!]} · ${trend[_tooltipIndex!].round()} L', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor)),
            ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _StatTile(label: 'Highest week', value: '${maxVal.round()} L', sub: 'Week of $maxWeek', isDark: isDark)),
              const SizedBox(width: 8),
              Expanded(child: _StatTile(label: 'Lowest week', value: '${minVal.round()} L', sub: 'Week of $minWeek', isDark: isDark)),
            ],
          ),
          const SizedBox(height: 24),
          Text('Top 5 cows', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
          const SizedBox(height: 12),
          for (final c in _topCows) _BarRow(label: c.$1, value: c.$2, max: 12.5, unit: 'L', isDark: isDark),
          if (_breed == 'All breeds') ...[
            const SizedBox(height: 24),
            Text('Yield by breed', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
            const SizedBox(height: 12),
            for (final b in _byBreed) _BarRow(label: b.$1, value: b.$2, max: 255, unit: 'L', isDark: isDark),
          ],
        ],
      ),
    );
  }
}

class _BreedChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _BreedChip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? VanixColors.darkPrimary : (isDark ? const Color(0xFF1C1C1C) : VanixColors.bgCard),
          border: Border.all(color: active ? VanixColors.darkPrimary : VanixColors.border),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: active ? FontWeight.w600 : FontWeight.w500, color: active ? Colors.white : (isDark ? Colors.white : VanixColors.textPrimary))),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label, value, sub;
  final bool isDark;
  const _StatTile({required this.label, required this.value, required this.sub, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF1C1C1C) : VanixColors.bgCard, border: Border.all(color: isDark ? const Color(0xFF3A3A3A) : VanixColors.border), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF8C8780) : VanixColors.textHint)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: isDark ? Colors.white : VanixColors.textPrimary)),
          Text(sub, style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF8C8780) : VanixColors.textHint)),
        ],
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  final String label;
  final double value, max;
  final String unit;
  final bool isDark;
  const _BarRow({required this.label, required this.value, required this.max, required this.unit, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final ratio = (value / max).clamp(0.0, 1.0);
    final barColor = isDark ? VanixColors.greenDeep : VanixColors.greenInk;
    final textColor = isDark ? Colors.white : VanixColors.textPrimary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(width: 70, child: Text(label, style: TextStyle(fontSize: 12, color: textColor), overflow: TextOverflow.ellipsis)),
          Expanded(
            child: LayoutBuilder(builder: (context, c) {
              return Stack(
                children: [
                  Container(height: 18, decoration: BoxDecoration(color: isDark ? const Color(0xFF262626) : const Color(0xFFF0EBE2), borderRadius: BorderRadius.circular(4))),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 18,
                    width: c.maxWidth * ratio,
                    decoration: BoxDecoration(color: barColor, borderRadius: BorderRadius.circular(4)),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 44, child: Text('${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)} $unit', style: TextStyle(fontSize: 11, color: textColor), textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  final List<double> values;
  final bool isDark;
  final int? tooltipIndex;
  _TrendPainter({required this.values, required this.isDark, required this.tooltipIndex});

  @override
  void paint(Canvas canvas, Size size) {
    final lineColor = isDark ? VanixColors.greenDeep : VanixColors.greenInk;
    final gridColor = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08);
    final max = values.reduce((a, b) => a > b ? a : b);
    final min = values.reduce((a, b) => a < b ? a : b);
    final range = (max - min) == 0 ? 1 : (max - min);
    final chartHeight = size.height - 20;

    // grid
    final gridPaint = Paint()..color = gridColor..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = chartHeight / 3 * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    Offset pointAt(int i) {
      final x = size.width / (values.length - 1) * i;
      final y = chartHeight - ((values[i] - min) / range) * chartHeight;
      return Offset(x, y);
    }

    final path = Path();
    final fillPath = Path();
    for (var i = 0; i < values.length; i++) {
      final p = pointAt(i);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
        fillPath.moveTo(p.dx, chartHeight);
        fillPath.lineTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
        fillPath.lineTo(p.dx, p.dy);
      }
    }
    fillPath.lineTo(pointAt(values.length - 1).dx, chartHeight);
    fillPath.close();

    canvas.drawPath(fillPath, Paint()..color = lineColor.withValues(alpha: 0.10)..style = PaintingStyle.fill);
    canvas.drawPath(path, Paint()..color = lineColor..strokeWidth = 2..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);

    final maxIdx = values.indexOf(max);
    final minIdx = values.indexOf(min);
    for (var i = 0; i < values.length; i++) {
      final p = pointAt(i);
      final isKey = i == 0 || i == values.length - 1 || i == maxIdx || i == minIdx || i == tooltipIndex;
      canvas.drawCircle(p, isKey ? 4 : 2.5, Paint()..color = lineColor);
      if (isKey) canvas.drawCircle(p, isKey ? 4 : 2.5, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.5);
    }

    if (tooltipIndex != null) {
      final p = pointAt(tooltipIndex!);
      canvas.drawLine(Offset(p.dx, 0), Offset(p.dx, chartHeight), Paint()..color = lineColor.withValues(alpha: 0.3)..strokeWidth = 1);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) => oldDelegate.values != values || oldDelegate.tooltipIndex != tooltipIndex || oldDelegate.isDark != isDark;
}
