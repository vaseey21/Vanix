import 'package:flutter/material.dart';
import '../i18n/farm_strings.dart';
import '../models/farm_models.dart';
import '../models/group_models.dart';
import '../state/app_state.dart';
import '../theme/vanix_theme.dart';

/// Add-to-group sheet, reachable from a cow's kebab (Farm Detail / Cow
/// Profile). Mirrors #cow-grp-sheet in prototype.html — a checkbox list of
/// every group with this cow's membership toggled.
Future<void> showAddToGroupSheet(BuildContext context, AppState appState, String farmId, int no) {
  final lang = appState.languageCode;
  final isDark = appState.isDark;
  final text1 = isDark ? Colors.white : VanixColors.textPrimary;
  final border = isDark ? VanixColors.darkBorder : VanixColors.border;
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
        decoration: BoxDecoration(color: isDark ? const Color(0xFF1C1C1C) : Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: Text(FS.t(lang, 'addToGroupTitle'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: text1))),
            IconButton(onPressed: () => Navigator.pop(ctx), icon: Icon(Icons.close, size: 18, color: text1)),
          ]),
          if (kGroups.isEmpty)
            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(FS.t(lang, 'noGroupsYet'), style: const TextStyle(fontSize: 13, color: VanixColors.textHint)))
          else
            Flexible(
              child: SingleChildScrollView(
                child: Column(children: kGroups.map((g) {
                  return CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: VanixColors.greenInk,
                    value: g.has(farmId, no),
                    onChanged: (v) { g.toggle(farmId, no, v ?? false); setSheet(() {}); },
                    title: Text(g.name, style: TextStyle(fontSize: 14, color: text1)),
                  );
                }).toList()),
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(minimumSize: const Size(0, 48), backgroundColor: VanixColors.greenInk, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
              child: Text(FS.t(lang, 'saveWord'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    ),
  );
}

/// Cattle Groups (Account → Cattle Groups) — owner-only. Mirrors #page-groups
/// in prototype.html: create groups, open a group to add/remove cattle.
class GroupsScreen extends StatefulWidget {
  final AppState appState;
  const GroupsScreen({super.key, required this.appState});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  String get _lang => widget.appState.languageCode;
  bool get _isDark => widget.appState.isDark;
  String _t(String k) => FS.t(_lang, k);

  Color get _cardBg => _isDark ? VanixColors.darkSecond : VanixColors.bgCard;
  Color get _text1 => _isDark ? Colors.white : VanixColors.textPrimary;
  Color get _border => _isDark ? VanixColors.darkBorder : VanixColors.border;
  Color get _sheetBg => _isDark ? const Color(0xFF1C1C1C) : Colors.white;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        final theme = _isDark ? vanixDarkTheme(languageCode: _lang) : vanixLightTheme(languageCode: _lang);
        return Theme(
          data: theme,
          child: Scaffold(
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 40),
                children: [
                  _hero(),
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 0),
                    child: Column(
                      children: [
                        _newGroupButton(),
                        const SizedBox(height: 12),
                        if (kGroups.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: Text(_t('noGroupsYet'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: VanixColors.textHint)),
                          )
                        else
                          for (final g in kGroups) _groupRow(g),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _hero() {
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: _isDark ? VanixColors.darkPrimary : VanixColors.bgWarm,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 28, offset: const Offset(0, 12))],
      ),
      child: Row(children: [
        SizedBox(
          width: 40, height: 40,
          child: IconButton(
            padding: EdgeInsets.zero,
            alignment: AlignmentDirectional.centerStart,
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.chevron_left, size: 26, color: _text1),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_t('rowCattleGroups'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _text1)),
              const SizedBox(height: 2),
              Text(_t('groupsSub'), style: const TextStyle(fontSize: 11, color: VanixColors.textHint)),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _newGroupButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _openNewGroup,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 46),
          side: BorderSide(color: _border, width: 1.5),
          foregroundColor: VanixColors.greenInk,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(_t('newGroupBtn'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _groupRow(CattleGroup g) {
    return InkWell(
      onTap: () => _openGroupDetail(g),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
        child: Row(children: [
          Expanded(child: Text(g.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _text1))),
          Text('${g.members.length} ${_t('cowsWord')}', style: const TextStyle(fontSize: 12, color: VanixColors.textHint)),
        ]),
      ),
    );
  }

  // ── New-group name sheet ──
  void _openNewGroup() {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _sheetShell(ctx, _t('newGroupBtn'), [
          TextField(controller: ctrl, autofocus: true, style: TextStyle(fontSize: 13, color: _text1), decoration: InputDecoration(hintText: _t('groupNamePh'))),
          const SizedBox(height: 12),
          _primaryBtn(_t('createGroup'), () {
            final nm = ctrl.text.trim();
            if (nm.isNotEmpty) {
              final g = CattleGroup(id: 'g${DateTime.now().millisecondsSinceEpoch}', name: nm);
              kGroups.add(g);
              Navigator.pop(ctx);
              setState(() {});
              _openGroupDetail(g);
            }
          }),
        ]),
      ),
    );
  }

  // ── Group detail: members + add cattle ──
  void _openGroupDetail(CattleGroup g) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => _sheetShell(ctx, g.name, [
          if (g.members.isEmpty)
            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(_t('noCowsInGroup'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: VanixColors.textHint)))
          else
            ...g.members.map((m) {
              final farm = kFarms.firstWhere((f) => f.id == m.farmId);
              final cow = farm.cows.firstWhere((c) => c.no == m.no);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(cow.nm(_lang), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _text1)),
                      Text(farm.nm(_lang), style: const TextStyle(fontSize: 11, color: VanixColors.textHint)),
                    ]),
                  ),
                  IconButton(
                    onPressed: () { setState(() => g.members.removeWhere((x) => x.farmId == m.farmId && x.no == m.no)); setSheet(() {}); },
                    icon: const Icon(Icons.close, size: 18, color: VanixColors.textHint),
                  ),
                ]),
              );
            }),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _openPicker(g, () => setSheet(() {})),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 46),
                side: const BorderSide(color: VanixColors.greenInk),
                backgroundColor: VanixColors.activeBg,
                foregroundColor: VanixColors.greenInk,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
              ),
              child: Text(_t('addCattleBtn'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Add-cattle picker (checkbox list of every cow) ──
  void _openPicker(CattleGroup g, VoidCallback onClosed) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => _sheetShell(ctx, _t('addCattleBtn'), [
          ...allCowsFlat().map((fc) {
            final checked = g.has(fc.farm.id, fc.cow.no);
            return CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: VanixColors.greenInk,
              value: checked,
              onChanged: (v) { g.toggle(fc.farm.id, fc.cow.no, v ?? false); setSheet(() {}); },
              title: Text('${fc.cow.nm(_lang)} — ${fc.farm.nm(_lang)}', style: TextStyle(fontSize: 14, color: _text1)),
            );
          }),
          const SizedBox(height: 12),
          _primaryBtn(_t('saveWord'), () { Navigator.pop(ctx); setState(() {}); onClosed(); }),
        ], scroll: true),
      ),
    );
  }

  // ── Sheet chrome ──
  Widget _sheetShell(BuildContext ctx, String title, List<Widget> children, {bool scroll = false}) {
    final body = Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2)))),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _text1))),
        IconButton(onPressed: () => Navigator.pop(ctx), icon: Icon(Icons.close, size: 18, color: _text1)),
      ]),
      if (scroll) Flexible(child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children))) else ...children,
    ]);
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.8),
      decoration: BoxDecoration(color: _sheetBg, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
      child: body,
    );
  }

  Widget _primaryBtn(String label, VoidCallback onTap) => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(0, 48),
            backgroundColor: VanixColors.greenInk,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
          child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      );
}
