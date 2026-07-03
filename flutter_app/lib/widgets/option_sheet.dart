import 'package:flutter/material.dart';
import '../theme/vanix_theme.dart';

/// Generic single-select bottom sheet — mirrors #s7-period-sheet /
/// #s7-sheet row styling in vanix_screens.html. Used for the "Show data
/// for" period picker and any future single-select list.
Future<void> showOptionSheet({
  required BuildContext context,
  required String title,
  required List<String> options,
  required String current,
  required ValueChanged<String> onSelect,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final bg = isDark ? const Color(0xFF1C1C1C) : Colors.white;
      final textColor = isDark ? Colors.white : VanixColors.textPrimary;
      return Container(
        decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4, margin: const EdgeInsets.only(top: 12), decoration: BoxDecoration(color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 6),
              child: Align(alignment: AlignmentDirectional.centerStart, child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor))),
            ),
            for (final opt in options)
              InkWell(
                onTap: () {
                  onSelect(opt);
                  Navigator.of(context).pop();
                },
                child: Container(
                  constraints: const BoxConstraints(minHeight: 50),
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: opt == options.last ? Colors.transparent : (isDark ? const Color(0x1AFFFFFF) : const Color(0x0F000000))))),
                  child: Row(
                    children: [
                      Expanded(child: Text(opt, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textColor))),
                      if (opt == current) const Icon(Icons.check, size: 18, color: VanixColors.greenInk),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}
