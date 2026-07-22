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

/// Farm Detail (cow list) — screen 05 (r2). Mirrors #page-farm-detail in
/// prototype.html: hero (back / name / manager / farm temp + level) with a
/// Cattle / Herd Activity tab row flush to its bottom border. Cattle pane —
/// search + two-pane filter (Status/Breed/Age), cow cards with corner
/// severity tag and kebab menu. Herd Activity pane — a funnel filter
/// (Activity/Cows two-pane sheet), a 2x2 activity summary grid
/// (Rumination/Standing/Resting/Feeding), and a read-only rumination-style
/// graph with a Normal/Anomaly pill. Pinned bottom nav (Farms tab).
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

/// Herd rumination hourly points (0–23h), mirrors FD_RUMINATION.
const List<double> _kRuminationSunrise = [
  38, 41, 43, 42, 39, 36, 34, 38, 42, 45, 46, 44, 43, 42, 18, 14, 20, 40, 43, 44, 42, 40, 39, 38
];
const List<double> _kRuminationNormal = [
  38, 40, 42, 41, 39, 36, 34, 37, 41, 44, 46, 45, 43, 42, 41, 40, 42, 44, 45, 43, 41, 40, 39, 38
];

/// Herd-activity summary hours, mirrors FD_HERD_HOURS in prototype.html.
const Map<String, String> _kFdHerdHours = {
  'rumination': '7.2h', 'standing': '3.6h', 'resting': '8.9h', 'feeding': '4.1h',
};

class _FarmDetailScreenState extends State<FarmDetailScreen> {
  final int _navIndex = 1;
  final TextEditingController _search = TextEditingController();

  String _statusFilter = 'all';
  String _breedFilter = 'all';
  String _ageFilter = 'all';

  String _fdTab = 'cattle'; // cattle | herd
  String _fdActivity = 'rumination'; // rumination | standing | resting | feeding
  String _fdHerdCow = 'all';

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
                        child: _fdTab == 'cattle' ? _cattlePane(isDark) : _herdPane(isDark),
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
                    Text(widget.appState.fmtTemp(farm.temp), style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: textColor)),
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
          const SizedBox(height: 8),
          _fdTabRow(isDark),
        ],
      ),
    );
  }

  // ── Cattle / Herd Activity tabs — mirrors .fd-tab in prototype.html ────
  Widget _fdTabRow(bool isDark) {
    return Row(
      children: [
        Expanded(child: _fdTabBtn(FS.t(_lang, 'fdTabCattle'), 'cattle', isDark)),
        Expanded(child: _fdTabBtn(FS.t(_lang, 'fdTabHerd'), 'herd', isDark)),
      ],
    );
  }

  Widget _fdTabBtn(String label, String value, bool isDark) {
    final active = _fdTab == value;
    final textColor = isDark ? Colors.white : VanixColors.textPrimary;
    return InkWell(
      onTap: () => setState(() => _fdTab = value),
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: BorderDirectional(bottom: BorderSide(color: active ? VanixColors.greenInk : Colors.transparent, width: 3)),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              color: active ? VanixColors.greenInk : (isDark ? const Color(0xB3FFFFFF) : VanixColors.textHint),
            )),
      ),
    );
  }

  // ── Cattle pane: search + filter + cow list ─────────────────────────────
  Widget _cattlePane(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _searchRow(isDark),
        Padding(
          padding: const EdgeInsetsDirectional.only(top: 12),
          child: _cattleList(isDark),
        ),
      ],
    );
  }

  // ── Herd Activity pane: filter + activity tiles + rumination graph ─────
  Widget _herdPane(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(alignment: AlignmentDirectional.centerEnd, child: _herdFilterBtn(isDark)),
        Padding(
          padding: const EdgeInsetsDirectional.only(top: 10),
          child: _herdSummaryGrid(isDark),
        ),
        if (widget.farm.cows.isNotEmpty)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 0),
            child: _ruminationCard(isDark),
          ),
      ],
    );
  }

  Widget _herdFilterBtn(bool isDark) {
    final textColor = isDark ? Colors.white : VanixColors.textPrimary;
    return InkWell(
      onTap: _openHerdFilterSheet,
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
    );
  }

  Widget _herdSummaryGrid(bool isDark) {
    final tiles = [
      ('rumination', FS.t(_lang, 'actRumination'), VanixColors.greenInk),
      ('standing', FS.t(_lang, 'actStanding'), const Color(0xFF2563EB)),
      ('resting', FS.t(_lang, 'actResting'), const Color(0xFF7C3AED)),
      ('feeding', FS.t(_lang, 'actFeeding'), VanixColors.warning),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.2,
      children: [
        for (final tile in tiles) _fdActivityTile(label: tile.$2, color: tile.$3, value: _kFdHerdHours[tile.$1] ?? '', isDark: isDark),
      ],
    );
  }

  Widget _fdActivityTile({required String label, required Color color, required String value, required bool isDark}) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 10, vertical: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark ? VanixColors.darkSecond : VanixColors.bgCard,
        border: Border.all(color: isDark ? VanixColors.darkBorder : VanixColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: isDark ? Colors.white : VanixColors.textPrimary, height: 1)),
          const SizedBox(height: 5),
          Text(label.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.3, color: color)),
        ],
      ),
    );
  }

  void _openHerdFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _HerdFilterSheet(
        lang: _lang,
        isDark: widget.appState.isDark,
        cows: widget.farm.cows,
        activity: _fdActivity,
        cow: _fdHerdCow,
        onApply: (a, c) => setState(() {
          _fdActivity = a;
          _fdHerdCow = c;
        }),
      ),
    );
  }


  // ── Herd rumination card ────────────────────────────────────────────────
  Widget _ruminationCard(bool isDark) {
    final isSunrise = widget.farm.id == 'sunrise';
    final pts = isSunrise ? _kRuminationSunrise : _kRuminationNormal;
    final textColor = isDark ? Colors.white : VanixColors.textPrimary;
    return Container(
      padding: const EdgeInsetsDirectional.all(14),
      decoration: BoxDecoration(
        color: isDark ? VanixColors.darkSecond : VanixColors.bgCard,
        border: Border.all(color: isDark ? VanixColors.darkBorder : VanixColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('${FS.t(_lang, 'fdHerdTitlePre')} ${_activityLabel()} — ${FS.t(_lang, 'fdHerdTitlePost')}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor))),
              _ruminationPill(isSunrise),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 96,
            width: double.infinity,
            child: CustomPaint(
              painter: _RuminationPainter(points: pts, anomaly: isSunrise),
              size: Size.infinite,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final l in const ['00:00', '06:00', '12:00', '18:00', '24:00'])
                Text(l, style: const TextStyle(fontSize: 9, color: VanixColors.textHint)),
            ],
          ),
          if (isSunrise)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: 10),
              child: Text(FS.t(_lang, 'fdAnomalyNote'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.5, color: VanixColors.warningInk)),
            ),
        ],
      ),
    );
  }

  Widget _ruminationPill(bool anomaly) {
    final bg = anomaly ? VanixColors.warningBg : VanixColors.activeBg;
    final dot = anomaly ? VanixColors.warning : VanixColors.greenDeep;
    final ink = anomaly ? VanixColors.warningInk : VanixColors.greenInk;
    final label = anomaly ? FS.t(_lang, 'fdAnomaly') : FS.t(_lang, 'fdNormalPattern');
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ink)),
        ],
      ),
    );
  }

  String _activityLabel() {
    switch (_fdActivity) {
      case 'standing':
        return FS.t(_lang, 'actStanding');
      case 'resting':
        return FS.t(_lang, 'actResting');
      case 'feeding':
        return FS.t(_lang, 'actFeeding');
      default:
        return FS.t(_lang, 'actRumination');
    }
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

// ─────────────────────────────────────────────────────────────────────────
// Herd-activity filter sheet — mirrors #fd-herd-filter-sheet in
// prototype.html (Activity / Cows two-pane rail, single-select chips).
// ─────────────────────────────────────────────────────────────────────────
class _HerdFilterSheet extends StatefulWidget {
  final String lang;
  final bool isDark;
  final List<CowModel> cows;
  final String activity, cow;
  final void Function(String activity, String cow) onApply;
  const _HerdFilterSheet({
    required this.lang,
    required this.isDark,
    required this.cows,
    required this.activity,
    required this.cow,
    required this.onApply,
  });

  @override
  State<_HerdFilterSheet> createState() => _HerdFilterSheetState();
}

class _HerdFilterSheetState extends State<_HerdFilterSheet> {
  int _cat = 0; // 0 activity, 1 cows
  late String _activity = widget.activity;
  late String _cow = widget.cow;

  String t(String k) => FS.t(widget.lang, k);

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bg = isDark ? VanixColors.darkSecond : Colors.white;
    final railBg = isDark ? VanixColors.darkPrimary : VanixColors.bgWarm;
    final textColor = isDark ? Colors.white : VanixColors.textPrimary;

    return Container(
      decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsetsDirectional.only(top: 12),
            decoration: BoxDecoration(color: VanixColors.greenInk, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(t('filterWord'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor)),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, size: 18, color: isDark ? const Color(0xA6FFFFFF) : VanixColors.textHint),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 260,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 132,
                  color: railBg,
                  child: Column(
                    children: [
                      _herdRailTab(t('activityWord'), 0, isDark),
                      _herdRailTab(t('herdCowsBtn'), 1, isDark),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    color: isDark ? VanixColors.darkSubSurface : VanixColors.bgWarm,
                    padding: const EdgeInsetsDirectional.all(12),
                    child: _cat == 0 ? _activityPane(isDark) : _cowsPane(isDark),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(_activity, _cow);
                Navigator.of(context).pop();
              },
              child: Text(t('applyFilters')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _herdRailTab(String label, int idx, bool isDark) {
    final active = _cat == idx;
    final activeColor = isDark ? VanixColors.textOnDarkDim : Colors.white;
    final textColor = isDark ? Colors.white : VanixColors.textPrimary;
    return InkWell(
      onTap: () => setState(() => _cat = idx),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 14, vertical: 14),
        alignment: AlignmentDirectional.centerStart,
        decoration: BoxDecoration(
          color: active ? activeColor : Colors.transparent,
          border: active ? const BorderDirectional(start: BorderSide(color: VanixColors.greenInk, width: 3)) : null,
        ),
        child: Text(label,
            style: TextStyle(fontSize: 13, fontWeight: active ? FontWeight.w600 : FontWeight.w400, color: active && isDark ? VanixColors.darkPrimary : textColor)),
      ),
    );
  }

  Widget _herdOptRow(String label, bool active, bool isDark, VoidCallback onTap) {
    final rowBg = isDark ? VanixColors.darkSecond : VanixColors.bgCard;
    final borderCol = isDark ? VanixColors.darkBorder : VanixColors.border;
    final textColor = active ? Colors.white : (isDark ? Colors.white : VanixColors.textPrimary);
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: active ? VanixColors.greenInk : rowBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: active ? VanixColors.greenInk : borderCol),
          ),
          child: Row(
            children: [
              Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: textColor))),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active ? Colors.white : Colors.transparent,
                  border: Border.all(color: active ? Colors.white : borderCol, width: 1.5),
                ),
                child: active ? const Icon(Icons.check, size: 13, color: VanixColors.greenInk) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _activityPane(bool isDark) {
    return ListView(
      children: [
        _herdOptRow(t('actRumination'), _activity == 'rumination', isDark, () => setState(() => _activity = 'rumination')),
        _herdOptRow(t('actStanding'), _activity == 'standing', isDark, () => setState(() => _activity = 'standing')),
        _herdOptRow(t('actResting'), _activity == 'resting', isDark, () => setState(() => _activity = 'resting')),
        _herdOptRow(t('actFeeding'), _activity == 'feeding', isDark, () => setState(() => _activity = 'feeding')),
      ],
    );
  }

  Widget _cowsPane(bool isDark) {
    return ListView(
      children: [
        _herdOptRow(t('allWord'), _cow == 'all', isDark, () => setState(() => _cow = 'all')),
        for (final c in widget.cows)
          _herdOptRow(c.nm(widget.lang), _cow == '${c.no}', isDark, () => setState(() => _cow = '${c.no}')),
      ],
    );
  }
}

/// Paints the herd rumination sparkline (24 hourly points, 0–60 scale) with
/// an optional 14:00–16:00 anomaly-dip segment in warning color.
class _RuminationPainter extends CustomPainter {
  final List<double> points;
  final bool anomaly;
  const _RuminationPainter({required this.points, required this.anomaly});

  Offset _pt(Size size, int i) {
    final x = i / (points.length - 1) * size.width;
    final y = size.height - 4 - (points[i] / 60 * (size.height - 8));
    return Offset(x, y);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final basePaint = Paint()
      ..color = VanixColors.greenDeep
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final p = _pt(size, i);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(path, basePaint);

    if (anomaly) {
      // Highlight the 14:00–16:00 dip (indices 14..16) in warning color.
      final dipPaint = Paint()
        ..color = VanixColors.warning
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final dipPath = Path();
      const from = 13, to = 17;
      for (var i = from; i <= to && i < points.length; i++) {
        final p = _pt(size, i);
        if (i == from) {
          dipPath.moveTo(p.dx, p.dy);
        } else {
          dipPath.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(dipPath, dipPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RuminationPainter oldDelegate) => oldDelegate.points != points || oldDelegate.anomaly != anomaly;
}
