import 'package:flutter/material.dart';
import '../i18n/strings.dart';
import '../theme/vanix_theme.dart';

/// Searchable language picker — mirrors #s1-lang-sheet in vanix_screens.html.
/// Built to scale as more languages ship (Urdu, Phase 4).
Future<void> showLanguageSheet(BuildContext context, {required String current, required ValueChanged<String> onSelect}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => _LanguageSheet(current: current, onSelect: onSelect),
  );
}

class _LanguageSheet extends StatefulWidget {
  final String current;
  final ValueChanged<String> onSelect;
  const _LanguageSheet({required this.current, required this.onSelect});

  @override
  State<_LanguageSheet> createState() => _LanguageSheetState();
}

class _LanguageSheetState extends State<_LanguageSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xEB141414) : Colors.white;
    final textColor = isDark ? Colors.white : VanixColors.textPrimary;
    final hintColor = isDark ? const Color(0x8CFFFFFF) : VanixColors.textHint;

    final matches = VanixLanguage.supported.where((l) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return l.native.toLowerCase().contains(q) || l.english.toLowerCase().contains(q);
    }).toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4, margin: const EdgeInsets.only(top: 12), decoration: BoxDecoration(color: VanixColors.border, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.only(top: 18),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text('Choose language', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(border: Border.all(color: isDark ? const Color(0x40FFFFFF) : VanixColors.border), borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  Icon(Icons.search, size: 16, color: hintColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      style: TextStyle(fontSize: 14, color: textColor),
                      decoration: InputDecoration(hintText: 'Search language', hintStyle: TextStyle(color: hintColor), border: InputBorder.none, isDense: true),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                ],
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(top: 10),
                children: [
                  for (final lang in matches)
                    InkWell(
                      onTap: () {
                        widget.onSelect(lang.code);
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 52),
                        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isDark ? const Color(0x1AFFFFFF) : const Color(0x0F000000)))),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(lang.native, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
                                  Text(lang.english, style: TextStyle(fontSize: 12, color: hintColor)),
                                ],
                              ),
                            ),
                            if (lang.code == widget.current) const Icon(Icons.check, size: 18, color: VanixColors.greenInk),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
