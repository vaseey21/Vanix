import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/vanix_theme.dart';

class VanixNavItem {
  /// A Material icon, OR provide [iconBuilder] for a custom-painted glyph.
  final IconData? icon;

  /// Builds a custom icon widget tinted [color] (used for the cow-head Farms
  /// tab). Takes precedence over [icon] when non-null.
  final Widget Function(Color color)? iconBuilder;
  final String label;
  final int badgeCount; // 0 = no badge
  final bool showDot;
  const VanixNavItem({this.icon, this.iconBuilder, required this.label, this.badgeCount = 0, this.showDot = false})
      : assert(icon != null || iconBuilder != null);
}

/// Cow-head line icon painted to match the stroke SVG in prototype.html's nav.
/// Recolours with [color] so it tracks active (greenInk) / inactive states.
class CowHeadIcon extends StatelessWidget {
  final Color color;
  final double size;
  const CowHeadIcon({super.key, required this.color, this.size = 20});

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: _CowHeadPainter(color));
}

class _CowHeadPainter extends CustomPainter {
  final Color color;
  _CowHeadPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24.0; // SVG viewBox is 24×24
    canvas.save();
    canvas.scale(s);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Top of head: elliptical arc M6 5.5 a6.3 3.6 0 0 1 12 0
    final top = Path()..moveTo(6, 5.5);
    top.arcToPoint(const Offset(18, 5.5), radius: const Radius.elliptical(6.3, 3.6), clockwise: true);
    canvas.drawPath(top, stroke);

    // Face outline down to the muzzle and back up.
    final face = Path()
      ..moveTo(6, 5.5)
      ..cubicTo(5.4, 8.5, 6.8, 10.8, 8.2, 12.8)
      ..cubicTo(9.2, 14.2, 9.5, 15.5, 9.5, 17.0)
      ..arcToPoint(const Offset(14.5, 17.0), radius: const Radius.circular(2.6), clockwise: false)
      ..cubicTo(14.5, 15.5, 14.8, 14.2, 15.8, 12.8)
      ..cubicTo(17.2, 10.8, 18.6, 8.5, 18.0, 5.5);
    canvas.drawPath(face, stroke);

    // Horns.
    final leftHorn = Path()
      ..moveTo(6, 5.5)
      ..cubicTo(4.5, 5.8, 3, 5, 3, 5)
      ..cubicTo(3, 5, 3.8, 7.3, 6, 7.3);
    canvas.drawPath(leftHorn, stroke);
    final rightHorn = Path()
      ..moveTo(18, 5.5)
      ..cubicTo(19.5, 5.8, 21, 5, 21, 5)
      ..cubicTo(21, 5, 20.2, 7.3, 18, 7.3);
    canvas.drawPath(rightHorn, stroke);

    // Mouth line.
    canvas.drawLine(const Offset(9.9, 16.3), const Offset(14.1, 16.3), stroke);

    // Nostrils (dots).
    final dot = Paint()..color = color..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(10.6, 18.4), 0.95, dot);
    canvas.drawCircle(const Offset(13.4, 18.4), 0.95, dot);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_CowHeadPainter old) => old.color != color;
}

/// The frosted floating nav bar with the sliding "droplet" capsule.
/// Mirrors .vnav / .vcap / .vtab in vanix_screens.html:
///   - capsule slide: 0.6s cubic-bezier(0.32, 1.04, 0.36, 1)
///   - squish keyframes: 1 → (1.08, 0.94) → (0.99, 1.01) → 1
///   - icons/labels never move — only the capsule glides beneath them.
class VanixBottomNav extends StatefulWidget {
  final List<VanixNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final bool isDark;

  const VanixBottomNav({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onTap,
    required this.isDark,
  });

  @override
  State<VanixBottomNav> createState() => _VanixBottomNavState();
}

class _VanixBottomNavState extends State<VanixBottomNav> with SingleTickerProviderStateMixin {
  late AnimationController _squishCtrl;
  static const _slideCurve = Cubic(0.32, 1.04, 0.36, 1);
  static const _slideDuration = Duration(milliseconds: 600);

  @override
  void initState() {
    super.initState();
    _squishCtrl = AnimationController(vsync: this, duration: _slideDuration);
  }

  @override
  void didUpdateWidget(covariant VanixBottomNav old) {
    super.didUpdateWidget(old);
    if (old.selectedIndex != widget.selectedIndex) {
      _squishCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _squishCtrl.dispose();
    super.dispose();
  }

  double _squishScaleX(double t) {
    if (t < 0.4) return _lerp(1, 1.08, t / 0.4);
    if (t < 0.75) return _lerp(1.08, 0.99, (t - 0.4) / 0.35);
    return _lerp(0.99, 1, (t - 0.75) / 0.25);
  }

  double _squishScaleY(double t) {
    if (t < 0.4) return _lerp(1, 0.94, t / 0.4);
    if (t < 0.75) return _lerp(0.94, 1.01, (t - 0.4) / 0.35);
    return _lerp(1.01, 1, (t - 0.75) / 0.25);
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t.clamp(0, 1);

  @override
  Widget build(BuildContext context) {
    final barColor = widget.isDark ? const Color(0x8C1C1C1C) : const Color(0x6BFFFFFF);
    final borderColor = widget.isDark ? const Color(0x29FFFFFF) : const Color(0x8CFFFFFF);
    final capsuleColor = widget.isDark ? VanixColors.textOnDarkDim : VanixColors.bgCard;
    final inactiveColor = widget.isDark ? VanixColors.textOnDarkDim : VanixColors.darkPrimary;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(14, 0, 14, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(36),
              border: Border.all(color: borderColor),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.20), blurRadius: 36, offset: const Offset(0, 14))],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final n = widget.items.length;
                final tabWidth = constraints.maxWidth / n;
                return SizedBox(
                  height: 56,
                  child: Stack(
                    children: [
                      AnimatedPositioned(
                        duration: _slideDuration,
                        curve: _slideCurve,
                        left: tabWidth * widget.selectedIndex,
                        top: 0,
                        width: tabWidth,
                        height: 56,
                        child: AnimatedBuilder(
                          animation: _squishCtrl,
                          builder: (context, child) {
                            final t = _squishCtrl.value;
                            return Transform.scale(
                              scaleX: _squishScaleX(t),
                              scaleY: _squishScaleY(t),
                              child: child,
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: capsuleColor,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 14, offset: const Offset(0, 4))],
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          for (var i = 0; i < n; i++)
                            Expanded(
                              child: _NavTab(
                                item: widget.items[i],
                                active: i == widget.selectedIndex,
                                activeColor: VanixColors.greenInk,
                                inactiveColor: inactiveColor,
                                onTap: () => widget.onTap(i),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  final VanixNavItem item;
  final bool active;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _NavTab({required this.item, required this.active, required this.activeColor, required this.inactiveColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = active ? activeColor : inactiveColor;
    return InkWell(
      onTap: onTap,
      customBorder: const StadiumBorder(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(item.icon, size: 20, color: color),
                if (item.showDot)
                  const Positioned(top: -2, right: -4, child: _Dot()),
                if (item.badgeCount > 0)
                  Positioned(top: -5, right: -8, child: _Badge(count: item.badgeCount)),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              style: TextStyle(fontSize: 11, fontWeight: active ? FontWeight.w600 : FontWeight.w500, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();
  @override
  Widget build(BuildContext context) => Container(width: 8, height: 8, decoration: const BoxDecoration(color: VanixColors.danger, shape: BoxShape.circle));
}

class _Badge extends StatelessWidget {
  final int count;
  const _Badge({required this.count});
  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minWidth: 15),
        height: 15,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(color: VanixColors.danger, borderRadius: BorderRadius.circular(8)),
        alignment: Alignment.center,
        child: Text('$count', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
      );
}
