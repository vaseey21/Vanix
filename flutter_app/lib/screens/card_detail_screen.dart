import 'package:flutter/material.dart';
import '../theme/vanix_theme.dart';
import '../widgets/graph_widgets.dart';

/// Full detail page reached by tapping "View Details" on any Events action
/// card. Holds everything trimmed off the list card — the full sensor
/// description, farm/belt meta, a last-10-days temperature graph (today's
/// spike highlighted) and a movement graph — then repeats the card's own
/// CTAs at the bottom so the farmer can act without going back to the list.
/// One shared page/template for all 14 card types (mirrors #ev-detail-page
/// in vanix_screens.html).
class CardDetailScreen extends StatelessWidget {
  final String title, sub;
  final String? meta;
  final String? manager;
  final String priorityLabel;
  final Color priorityBg, priorityFg;
  final bool priorityOutline;
  final Color? priorityBorderColor;
  final bool isDark;
  final List<double> temps;
  final List<int> moves;
  final bool moveIsFlat;
  final Widget cta;
  // Illustration-first layout (Fever/Abortion/Fresh-Cow/Heat so far): a big
  // cow+condition emoji tile + cow name/breed caption, with the CTA moved up
  // right below it — matches the user's whiteboard sketch (title →
  // illustration → name/breed → question → Yes/No). Cards without an
  // illustration keep the original description-first order.
  final String? illustrationEmoji;
  final String? cowName;
  final String? cowBreed;
  final Color? illustrationTint;
  final Color? illustrationBorder;

  const CardDetailScreen({
    super.key,
    required this.title,
    required this.sub,
    this.meta,
    this.manager,
    required this.priorityLabel,
    required this.priorityBg,
    required this.priorityFg,
    this.priorityOutline = false,
    this.priorityBorderColor,
    required this.isDark,
    required this.temps,
    required this.moves,
    this.moveIsFlat = false,
    required this.cta,
    this.illustrationEmoji,
    this.cowName,
    this.cowBreed,
    this.illustrationTint,
    this.illustrationBorder,
  });

  @override
  Widget build(BuildContext context) {
    final scaffoldBg = isDark ? VanixColors.darkPrimary : VanixColors.bgWarm;
    final textColor = isDark ? Colors.white : VanixColors.textPrimary;
    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 4),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: textColor),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text('Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textColor))),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: priorityBg,
                            borderRadius: BorderRadius.circular(10),
                            border: priorityOutline ? Border.all(color: priorityBorderColor!) : null,
                          ),
                          child: Text(priorityLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: priorityFg)),
                        ),
                      ],
                    ),
                    if (illustrationEmoji != null) ...[
                      const SizedBox(height: 18),
                      Center(
                        child: Container(
                          width: 128,
                          height: 116,
                          decoration: BoxDecoration(
                            color: illustrationTint,
                            border: Border.all(color: illustrationBorder ?? VanixColors.border),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          alignment: Alignment.center,
                          child: Text(illustrationEmoji!, style: const TextStyle(fontSize: 52)),
                        ),
                      ),
                      if (cowName != null) Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Center(
                          child: Text(
                            cowBreed != null ? '$cowName · $cowBreed' : cowName!,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white.withOpacity(0.85) : VanixColors.textPrimary),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      cta,
                      const SizedBox(height: 20),
                    ],
                    if (manager != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text('Manager: $manager', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: VanixColors.textHint))),
                    if (meta != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(meta!, style: const TextStyle(fontSize: 12, color: VanixColors.textHint))),
                    Padding(padding: const EdgeInsets.only(top: 10), child: Text(sub, style: TextStyle(fontSize: 14, height: 1.6, color: isDark ? Colors.white.withOpacity(0.85) : VanixColors.textPrimary))),
                    const SizedBox(height: 16),
                    GraphPanel(
                      isDark: isDark,
                      label: 'TEMPERATURE — LAST 10 DAYS',
                      child: SizedBox(
                        height: 40,
                        width: double.infinity,
                        child: CustomPaint(painter: SparklinePainter(temps, highlightLast: true)),
                      ),
                      footer: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${temps.reduce((a, b) => a < b ? a : b).toStringAsFixed(1)}°C baseline', style: TextStyle(fontSize: 10, color: isDark ? Colors.white.withOpacity(0.6) : VanixColors.textHint)),
                          Text('${temps.last.toStringAsFixed(1)}°C today', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: VanixColors.danger)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    GraphPanel(
                      isDark: isDark,
                      label: 'MOVEMENT — LAST 10 DAYS',
                      child: MovementBars(values: moves, highlightLast: !moveIsFlat),
                    ),
                    if (illustrationEmoji == null) ...[
                      const SizedBox(height: 18),
                      cta,
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
