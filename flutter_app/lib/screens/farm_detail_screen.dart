import 'package:flutter/material.dart';
import '../i18n/farm_strings.dart';
import '../i18n/strings.dart';
import '../models/farm_models.dart';
import '../state/app_state.dart';
import '../theme/vanix_theme.dart';
import '../widgets/vanix_bottom_nav.dart';
import '../widgets/vanix_nav_items.dart';
import 'milk_log_screen.dart';
import 'events_screen.dart';
import 'account_screen.dart';
import 'cow_profile_screen.dart';
import 'groups_screen.dart';
import 'add_cattle_screen.dart';

/// Farm Detail (cow list) — screen 05. Mirrors #page-farm-detail +
/// renderCattleList + the cattle-fs filter sheet + the alerts-tile toggle
/// in prototype.html. Hero (back / name / manager / farm temp + level, two
/// stat tiles), search + two-pane filter, cow cards with corner severity tag
/// and kebab menu, pinned bottom nav (Farms tab).
class FarmDetailScreen extends StatefulWidget {
  final AppState appState;
  final FarmModel farm;
  const FarmDetailScreen({super.key, required this.appState, required this.farm});

  @override
  State<FarmDetailScreen> createState() => _FarmDetailScreenState();
}

/// Corner-tag mapping (severity by cow status). Mirrors COW_TAG in prototype.
class _CowTag {
  final Color bg;
  final String key;
  const _CowTag(this.bg, this.key);
}

const Map<String, _CowTag> _kCowTag = {
  'Fever': _CowTag(VanixColors.danger, 'sevCritical'),
  'Heat': _CowTag(VanixColors.warning, 'sevMedium'),
  'Pregnant': _CowTag(VanixColors.textHint, 'sevLow'),
  'Milking': _CowTag(VanixColors.greenInk, 'healthyWord'),
};

class _FarmDetailScreenState extends State<FarmDetailScreen> {
  final int _navIndex = 1;
  final TextEditingController _search = TextEditingController();

  String _statusFilter = 'all';
  String _breedFilter = 'all';
  String _ageFilter = 'all';
  bool _alertsOnly = false;

  String get _lang => widget.appState.languageCode;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _onNavTap(int i) {
    switch (i) {
      case 0:
        Navigator.of(context).popUntil((r) => r.isFirst);
        break;
      case 1:
        Navigator.of(context).pop();
        break;
      case 2:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => MilkLogScreen(appState: widget.appState))).then((_) => setState(() {}));
        break;
      case 3:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => EventsScreen(appState: widget.appState))).then((_) => setState(() {}));
        break;
      case 4:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => AccountScreen(appState: widget.appState))).then((_) => setState(() {}));
        break;
    }
  }

  List<CowModel> get _visibleCows {
    final q = _search.text.trim().toLowerCase();
    return widget.farm.cows.where((c) {
      if (_alertsOnly && !c.isAlert) return false;
      if (_statusFilter != 'all' && c.status != _statusFilter) return false;
      if (_breedFilter != 'all' && c.breed != _breedFilter) return false;
      if (_ageFilter != 'all' && c.ageBucket != _ageFilter) return false;
      if (q.isNotEmpty && !('${c.name} ${c.nameHi}').toLowerCase().contains(q)) return false;
      return true;
    }).toList();
  }

  Future<void> _openFilterSheet() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CattleFilterSheet(
        lang: _lang,
        isDark: widget.appState.isDark,
        status: _statusFilter,
        breed: _breedFilter,
        age: _ageFilter,
        onApply: (s, b, a) => setState(() {
          _statusFilter = s;
          _breedFilter = b;
          _ageFilter = a;
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        final isDark = widget.appState.isDark;
        final t = VanixStrings.of(_lang);
        final theme = isDark ? vanixDarkTheme(languageCode: _lang) : vanixLightTheme(languageCode: _lang);
        return Theme(
          data: theme,
          child: Scaffold(
            body: Stack(
              children: [
                Positioned.fill(
                  child: SafeArea(
                    bottom: false,
                    child: ListView(
                    padding: const EdgeInsetsDirectional.only(bottom: 120),
                    children: [
                      _hero(isDark),
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 0),
                        child: _searchRow(isDark),
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 0),
                        child: _cattleList(isDark),
                      ),
                    ],
                  ),
                  ),
                ),
                PositionedDirectional(
                  end: 18,
                  bottom: 104,
                  child: FloatingActionButton(
                    heroTag: 'addCattleFab',
                    backgroundColor: VanixColors.greenInk,
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => AddCattleScreen(appState: widget.appState, farm: widget.farm),
                      ));
                    },
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: VanixBottomNav(
                    isDark: isDark,
                    selectedIndex: _navIndex,
                    onTap: _onNavTap,
                    items: buildVanixNavItems(t, widget.appState),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Manage farm manager: 3-option chooser (select / invite / assign self) ──
  void _openManagerChooser(FarmModel farm) {
    final lang = _lang;
    final isDark = widget.appState.isDark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bg = isDark ? const Color(0xFF1C1C1C) : Colors.white;
        final textColor = isDark ? Colors.white : VanixColors.textPrimary;
        Widget optionBtn(String label, VoidCallback onTap) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onTap,
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    minimumSize: const Size(0, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    side: BorderSide(color: isDark ? VanixColors.darkBorder : VanixColors.border),
                    foregroundColor: textColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                ),
              ),
            );
        return Container(
          decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: VanixColors.greenInk, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: Text(FS.t(lang, 'manageFarmMgr'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor))),
                IconButton(onPressed: () => Navigator.pop(ctx), icon: Icon(Icons.close, size: 18, color: textColor)),
              ]),
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(farm.nm(lang), style: TextStyle(fontSize: 12, color: isDark ? const Color(0xB3FFFFFF) : VanixColors.textHint)),
              ),
              optionBtn(FS.t(lang, 'selectNewMgr'), () { Navigator.pop(ctx); _openManagerForm(farm, invite: false); }),
              optionBtn(FS.t(lang, 'sendMgrInvite'), () { Navigator.pop(ctx); _openManagerForm(farm, invite: true); }),
              optionBtn(FS.t(lang, 'assignMe'), () {
                setState(() {
                  farm.manager = 'James Redmark';
                  farm.managerHi = 'जेम्स रेडमार्क';
                  farm.managerInvitePending = false;
                  farm.managerInviteEmail = '';
                });
                Navigator.pop(ctx);
              }),
            ],
          ),
        );
      },
    );
  }

  void _openManagerForm(FarmModel farm, {required bool invite}) {
    final lang = _lang;
    final isDark = widget.appState.isDark;
    final nameC = TextEditingController();
    final emailC = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bg = isDark ? const Color(0xFF1C1C1C) : Colors.white;
        final textColor = isDark ? Colors.white : VanixColors.textPrimary;
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: VanixColors.greenInk, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: Text(FS.t(lang, invite ? 'sendMgrInvite' : 'selectNewMgr'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor))),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: Icon(Icons.close, size: 18, color: textColor)),
                ]),
                Text(farm.nm(lang), style: TextStyle(fontSize: 12, color: isDark ? const Color(0xB3FFFFFF) : VanixColors.textHint)),
                const SizedBox(height: 14),
                if (invite) ...[
                  TextField(controller: emailC, keyboardType: TextInputType.emailAddress, style: TextStyle(fontSize: 13, color: textColor), decoration: InputDecoration(hintText: FS.t(lang, 'emailPh'))),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(FS.t(lang, 'mgrInviteHint'), style: TextStyle(fontSize: 11, height: 1.5, color: isDark ? const Color(0xB3FFFFFF) : VanixColors.textHint)),
                  ),
                ] else
                  TextField(controller: nameC, style: TextStyle(fontSize: 13, color: textColor), decoration: InputDecoration(hintText: FS.t(lang, 'mgrNamePh'))),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        if (invite) {
                          final em = emailC.text.trim();
                          if (em.isNotEmpty) { farm.managerInvitePending = true; farm.managerInviteEmail = em; }
                        } else {
                          final nm = nameC.text.trim();
                          if (nm.isNotEmpty) { farm.manager = nm; farm.managerHi = nm; farm.managerInvitePending = false; farm.managerInviteEmail = ''; }
                        }
                      });
                      Navigator.pop(ctx);
                    },
                    child: Text(FS.t(lang, 'confirmAssign')),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Hero ──────────────────────────────────────────────────────────────
  Widget _hero(bool isDark) {
    final farm = widget.farm;
    final textColor = isDark ? Colors.white : VanixColors.textPrimary;
    final subColor = isDark ? const Color(0xB3FFFFFF) : VanixColors.textHint;
    final levelKey = farmTempLevelKey(farm.temp);
    final levelColor = _tempLevelColor(levelKey);

    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: isDark ? VanixColors.darkPrimary : VanixColors.bgWarm,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 28, offset: const Offset(0, 12))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  alignment: AlignmentDirectional.centerStart,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.chevron_left, size: 26, color: textColor),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(farm.nm(_lang), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, height: 1.2, color: textColor)),
                      const SizedBox(height: 2),
                      Row(children: [
                        Flexible(
                          child: Text(
                            farm.managerInvitePending
                                ? '${FS.t(_lang, 'invitePending')} — ${farm.managerInviteEmail}'
                                : '${farm.mgr(_lang)} · ${FS.t(_lang, 'managerWord')}',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13, color: farm.managerInvitePending ? VanixColors.warning : subColor, fontWeight: farm.managerInvitePending ? FontWeight.w600 : FontWeight.w400),
                          ),
                        ),
                        // Manager edit is owner-only
                        if (!widget.appState.isFarmer) ...[
                          const SizedBox(width: 5),
                          InkWell(
                            onTap: () => _openManagerChooser(farm),
                            borderRadius: BorderRadius.circular(11),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(Icons.edit_outlined, size: 13, color: subColor),
                            ),
                          ),
                        ],
                      ]),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsetsDirectional.only(top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(farm.temp, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: textColor)),
                    const SizedBox(height: 2),
                    Text(
                      FS.t(_lang, levelKey).toUpperCase(),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: levelColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _statTile(value: '${farm.cattle}', label: FS.t(_lang, 'statTotalCattle'), isDark: isDark)),
                const SizedBox(width: 8),
                Expanded(child: _alertsTile(isDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _tempLevelColor(String key) {
    switch (key) {
      case 'tempVeryHigh':
        return VanixColors.danger;
      case 'tempHigh':
        return VanixColors.warningInk; // #8A5A00
      case 'tempNormal':
        return VanixColors.greenInk;
      default:
        return VanixColors.textHint;
    }
  }

  Widget _statTile({required String value, required String label, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? VanixColors.darkSecond : VanixColors.bgCard,
        border: Border.all(color: isDark ? VanixColors.darkBorder : VanixColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: isDark ? Colors.white : VanixColors.textPrimary)),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.4, color: isDark ? const Color(0xB3FFFFFF) : VanixColors.textHint),
          ),
        ],
      ),
    );
  }

  Widget _alertsTile(bool isDark) {
    final farm = widget.farm;
    return InkWell(
      onTap: () => setState(() => _alertsOnly = !_alertsOnly),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? VanixColors.dangerBg.withValues(alpha: 0.14) : VanixColors.dangerBg,
          border: Border.all(color: VanixColors.danger, width: _alertsOnly ? 2 : 1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text('${farm.alerts}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: isDark ? Colors.white : VanixColors.textPrimary)),
            const SizedBox(height: 4),
            Text(
              FS.t(_lang, 'statUnactionedAlerts').toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.4, color: isDark ? const Color(0xB3FFFFFF) : VanixColors.textHint),
            ),
            const SizedBox(height: 3),
            Text('${farm.critical} ${FS.t(_lang, 'criticalWord')}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: VanixColors.danger)),
          ],
        ),
      ),
    );
  }

  // ── Search + filter row ─────────────────────────────────────────────────
  Widget _searchRow(bool isDark) {
    final textColor = isDark ? Colors.white : VanixColors.textPrimary;
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 46,
            padding: const EdgeInsetsDirectional.only(start: 14, end: 8),
            decoration: BoxDecoration(
              color: isDark ? VanixColors.darkSecond : VanixColors.bgCard,
              border: Border.all(color: isDark ? VanixColors.darkBorder : VanixColors.border),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, size: 16, color: VanixColors.textHint),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(fontSize: 14, color: textColor),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      hintText: FS.t(_lang, 'searchCattle'),
                      hintStyle: const TextStyle(fontSize: 13, color: VanixColors.textHint),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: _openFilterSheet,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isDark ? VanixColors.darkSecond : VanixColors.bgCard,
              border: Border.all(color: isDark ? VanixColors.darkBorder : VanixColors.border),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.filter_alt_outlined, size: 18, color: textColor),
          ),
        ),
      ],
    );
  }

  // ── Cattle list ─────────────────────────────────────────────────────────
  Widget _cattleList(bool isDark) {
    if (widget.farm.cows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Column(
          children: [
            Text(FS.t(_lang, 'noCattleYet'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, height: 1.6, color: VanixColors.textHint)),
            Text(FS.t(_lang, 'tapAddCattle'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, height: 1.6, color: VanixColors.textHint)),
          ],
        ),
      );
    }
    final cows = _visibleCows;
    if (cows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Text(FS.t(_lang, 'noCattleMatch'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: VanixColors.textHint)),
      );
    }
    return Column(children: [for (final c in cows) _cowCard(c, isDark)]);
  }

  Widget _cowCard(CowModel cow, bool isDark) {
    final textColor = isDark ? Colors.white : VanixColors.textPrimary;
    final subColor = isDark ? const Color(0xB3FFFFFF) : VanixColors.textHint;
    final tag = _kCowTag[cow.status];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? VanixColors.darkSecond : VanixColors.bgCard,
        border: Border.all(color: isDark ? VanixColors.darkBorder : VanixColors.border),
        borderRadius: BorderRadius.circular(18),
        boxShadow: isDark ? VanixShadow.cardDark : VanixShadow.card,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => CowProfileScreen(appState: widget.appState, farm: widget.farm, cow: cow)),
          ),
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _cowPhoto(cow, isDark),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(end: 56),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 6,
                              children: [
                                Text(cow.nm(_lang), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textColor)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(color: VanixColors.activeBg, borderRadius: BorderRadius.circular(8)),
                                  child: Text(cow.bl(_lang), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: VanixColors.greenInk)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(cow.br(_lang), style: TextStyle(fontSize: 12, color: subColor)),
                            const SizedBox(height: 2),
                            Text(cow.ag(_lang), style: TextStyle(fontSize: 12, color: subColor)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (tag != null)
                PositionedDirectional(
                  top: 0,
                  end: 0,
                  child: Container(
                    padding: const EdgeInsetsDirectional.fromSTEB(16, 5, 14, 6),
                    decoration: BoxDecoration(
                      color: tag.bg,
                      borderRadius: const BorderRadiusDirectional.only(topEnd: Radius.circular(17), bottomStart: Radius.circular(12)),
                    ),
                    child: Text(
                      FS.t(_lang, tag.key).toUpperCase(),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: Colors.white),
                    ),
                  ),
                ),
              PositionedDirectional(
                bottom: 6,
                end: 8,
                child: _kebab(cow, isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cowPhoto(CowModel cow, bool isDark) {
    if (cow.photo != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.asset(
          cow.photo!,
          width: 64,
          height: 64,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _photoPlaceholder(isDark),
        ),
      );
    }
    return _photoPlaceholder(isDark);
  }

  Widget _photoPlaceholder(bool isDark) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? VanixColors.darkBorder : VanixColors.border, width: 1.5),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.close, size: 16, color: VanixColors.textHint),
    );
  }

  Widget _kebab(CowModel cow, bool isDark) {
    final textColor = isDark ? Colors.white : VanixColors.textPrimary;
    return SizedBox(
      width: 32,
      height: 32,
      child: PopupMenuButton<String>(
        tooltip: '',
        padding: EdgeInsets.zero,
        color: isDark ? VanixColors.darkSecond : VanixColors.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: isDark ? VanixColors.darkBorder : VanixColors.border),
        ),
        icon: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? VanixColors.darkSecond : VanixColors.bgCard,
            border: Border.all(color: isDark ? VanixColors.darkBorder : VanixColors.border),
          ),
          child: Icon(Icons.more_vert, size: 16, color: textColor),
        ),
        onSelected: (v) {
          if (v == 'group') showAddToGroupSheet(context, widget.appState, widget.farm.id, cow.no);
        },
        itemBuilder: (_) => [
          PopupMenuItem(value: 'edit', height: 40, child: Text(FS.t(_lang, 'editWord'), style: TextStyle(fontSize: 13, color: textColor))),
          PopupMenuItem(value: 'group', height: 40, child: Text(FS.t(_lang, 'addToGroup'), style: TextStyle(fontSize: 13, color: textColor))),
          PopupMenuItem(value: 'delete', height: 40, child: Text(FS.t(_lang, 'deleteWord'), style: const TextStyle(fontSize: 13, color: VanixColors.danger))),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Two-pane cattle filter sheet — mirrors #cattle-fs in prototype.html
// (Status / Breed / Age rail, single-select chips, greenInk Apply).
// ─────────────────────────────────────────────────────────────────────────
class _CattleFilterSheet extends StatefulWidget {
  final String lang;
  final bool isDark;
  final String status, breed, age;
  final void Function(String status, String breed, String age) onApply;
  const _CattleFilterSheet({
    required this.lang,
    required this.isDark,
    required this.status,
    required this.breed,
    required this.age,
    required this.onApply,
  });

  @override
  State<_CattleFilterSheet> createState() => _CattleFilterSheetState();
}

class _CattleFilterSheetState extends State<_CattleFilterSheet> {
  int _cat = 0; // 0 status, 1 breed, 2 age
  late String _status = widget.status;
  late String _breed = widget.breed;
  late String _age = widget.age;

  String t(String k) => FS.t(widget.lang, k);

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bg = isDark ? VanixColors.darkSecond : Colors.white;
    final railBg = isDark ? VanixColors.darkPrimary : VanixColors.bgWarm;
    final textColor = isDark ? Colors.white : VanixColors.textPrimary;

    return Container(
      decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      padding: const EdgeInsetsDirectional.fromSTEB(24, 8, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 36, height: 4, margin: const EdgeInsets.only(top: 6), decoration: BoxDecoration(color: VanixColors.greenInk, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                Expanded(child: Text(t('filterWord'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textColor))),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, size: 16, color: isDark ? const Color(0xA6FFFFFF) : VanixColors.textHint),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 260,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 126,
                  color: railBg,
                  child: Column(
                    children: [
                      _railTab(t('statusWord'), 0, isDark),
                      _railTab(t('breedWord'), 1, isDark),
                      _railTab(t('ageWord'), 2, isDark),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    color: isDark ? VanixColors.darkSubSurface : VanixColors.bgWarm,
                    padding: const EdgeInsets.all(12),
                    child: _pane(isDark),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: VanixColors.greenInk, foregroundColor: Colors.white),
              onPressed: () {
                widget.onApply(_status, _breed, _age);
                Navigator.of(context).pop();
              },
              child: Text(t('applyFilters')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _railTab(String label, int idx, bool isDark) {
    final active = _cat == idx;
    final activeColor = isDark ? VanixColors.textOnDarkDim : Colors.white;
    final textColor = isDark ? Colors.white : VanixColors.textPrimary;
    return InkWell(
      onTap: () => setState(() => _cat = idx),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 44),
        alignment: AlignmentDirectional.centerStart,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: active ? activeColor : Colors.transparent,
          border: active ? const BorderDirectional(start: BorderSide(color: VanixColors.greenInk, width: 3)) : null,
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: active ? FontWeight.w600 : FontWeight.w400, color: active && isDark ? VanixColors.darkPrimary : textColor)),
      ),
    );
  }

  Widget _pane(bool isDark) {
    switch (_cat) {
      case 0:
        return _chipList([
          _Opt('all', t('allWord')),
          _Opt('Milking', t('statusMilking')),
          _Opt('Pregnant', t('statusPregnant')),
          _Opt('Heat', t('cattleHeat')),
          _Opt('Fever', t('cattleFever')),
        ], _status, (v) => setState(() => _status = v), isDark);
      case 1:
        return _chipList([
          _Opt('all', t('allWord')),
          _Opt('Jersey', t('breedJersey')),
          const _Opt('HF Cross', 'HF Cross'),
          _Opt('Gir', t('breedGir')),
          _Opt('Sahiwal', t('breedSahiwal')),
          _Opt('Ongole', t('breedOngole')),
          _Opt('Desi', t('breedDesi')),
        ], _breed, (v) => setState(() => _breed = v), isDark);
      default:
        return _chipList([
          _Opt('all', t('allWord')),
          _Opt('u2', t('ageUnder2')),
          _Opt('2to4', t('age2to4')),
          _Opt('o4', t('ageOver4')),
        ], _age, (v) => setState(() => _age = v), isDark);
    }
  }

  Widget _chipList(List<_Opt> opts, String current, ValueChanged<String> onTap, bool isDark) {
    final activeBg = isDark ? VanixColors.textOnDarkDim : VanixColors.greenInk;
    final activeText = isDark ? VanixColors.darkPrimary : Colors.white;
    final inactiveText = isDark ? Colors.white : VanixColors.textPrimary;
    return ListView(
      children: [
        for (final o in opts)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => onTap(o.value),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: current == o.value ? activeBg : Colors.transparent,
                  border: current == o.value ? null : Border.all(color: isDark ? VanixColors.darkBorder : VanixColors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(child: Text(o.label, style: TextStyle(fontSize: 13, color: current == o.value ? activeText : inactiveText))),
                    if (current == o.value)
                      Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                        alignment: Alignment.center,
                        child: const Icon(Icons.check, size: 12, color: VanixColors.greenInk),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Opt {
  final String value, label;
  const _Opt(this.value, this.label);
}
