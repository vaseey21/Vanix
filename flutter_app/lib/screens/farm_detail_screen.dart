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
import 'report_preview_screen.dart';

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

/// Per-activity color + nominal "active window" (hour range) + mock hourly
/// points (0–23h) — mirrors FD_ACT_META in vanix_screens_preview.html.
/// Rumination's points come from _kRuminationSunrise/_kRuminationNormal
/// (per-farm) instead of a fixed pts list here.
class _FdActMeta {
  final Color color;
  final List<int> range;
  final List<double>? pts;
  const _FdActMeta({required this.color, required this.range, this.pts});
}

final Map<String, _FdActMeta> _kFdActMeta = {
  'rumination': const _FdActMeta(color: VanixColors.greenDeep, range: [6, 20]),
  'standing': const _FdActMeta(
    color: Color(0xFF2563EB),
    range: [8, 18],
    pts: [10, 9, 8, 8, 9, 10, 12, 18, 28, 34, 36, 35, 33, 32, 34, 36, 35, 30, 20, 14, 11, 10, 9, 10],
  ),
  'resting': const _FdActMeta(
    color: Color(0xFF7C3AED),
    range: [20, 24],
    pts: [12, 10, 9, 10, 12, 16, 20, 24, 30, 28, 25, 22, 20, 18, 16, 15, 14, 16, 20, 28, 36, 44, 46, 45],
  ),
  'feeding': const _FdActMeta(
    color: VanixColors.warning,
    range: [6, 9],
    pts: [5, 5, 6, 8, 10, 14, 30, 42, 38, 20, 12, 10, 9, 9, 10, 12, 20, 34, 30, 16, 10, 8, 6, 5],
  ),
};

class _FarmDetailScreenState extends State<FarmDetailScreen> {
  final int _navIndex = 1;
  final TextEditingController _search = TextEditingController();

  String _statusFilter = 'all';
  String _breedFilter = 'all';
  String _ageFilter = 'all';

  String _fdTab = 'cattle'; // cattle | herd
  // Herd Activity chips — mirrors fdActiveSet in vanix_screens_preview.html.
  // Rumination toggles independently; standing/resting/feeding are mutually
  // exclusive among themselves (selecting one deselects any other of the three).
  List<String> _fdActiveSet = ['rumination'];
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
                      // Bottom slide-up sheet (leaves the farm-detail hero
                      // peeking through at the top) — mirrors #page-add-cattle
                      // / #ac-backdrop in vanix_screens_preview.html (top:64px,
                      // rounded top corners, dimming backdrop) rather than a
                      // full-screen page push.
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        barrierColor: Colors.black.withValues(alpha: 0.35),
                        builder: (_) => ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                          child: ConstrainedBox(
                            // Sized to content, not full-screen — mirrors the
                            // HTML fix (max-height cap instead of a fixed
                            // top:64px stretch that left dead whitespace
                            // below "Add cow history" on short forms).
                            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
                            child: AddCattleScreen(appState: widget.appState, farm: widget.farm),
                          ),
                        ),
                      );
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
                  child: Text(farm.nm(_lang), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, height: 1.2, color: textColor)),
                ),
              ),
              _farmKebab(isDark),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        farm.managerInvitePending
                            ? '${FS.t(_lang, 'invitePending')} — ${farm.managerInviteEmail}'
                            : farm.mgr(_lang),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: farm.managerInvitePending ? VanixColors.warning : subColor, fontWeight: farm.managerInvitePending ? FontWeight.w600 : FontWeight.w400),
                      ),
                    ),
                    // Manager edit is owner-only
                    if (!widget.appState.isFarmer && !farm.managerInvitePending) ...[
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () => _openManagerChooser(farm),
                        borderRadius: BorderRadius.circular(11),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(Icons.edit_outlined, size: 13, color: subColor),
                        ),
                      ),
                    ],
                    if (!farm.managerInvitePending) ...[
                      Text('  -  ', style: TextStyle(fontSize: 13, color: subColor)),
                      Text(widget.appState.fmtTemp(farm.temp), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor)),
                      const SizedBox(width: 5),
                      Text(
                        FS.t(_lang, levelKey).toUpperCase(),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: levelColor),
                      ),
                    ],
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

  Widget _farmKebab(bool isDark) {
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
        icon: Icon(Icons.more_vert, size: 20, color: textColor),
        onSelected: (v) {
          switch (v) {
            case 'download':
              _openReportPreview(critical: false);
              break;
            case 'download-critical':
              _openReportPreview(critical: true);
              break;
            case 'share':
              _openShareWithVetSheet();
              break;
            case 'manage':
              Navigator.of(context).pop();
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => FarmMgmtPage(appState: widget.appState)));
              break;
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem(value: 'download', height: 40, child: Text(FS.t(_lang, 'downloadReport'), style: TextStyle(fontSize: 13, color: textColor))),
          PopupMenuItem(value: 'download-critical', height: 40, child: Text(FS.t(_lang, 'downloadCriticalReport'), style: TextStyle(fontSize: 13, color: textColor))),
          PopupMenuItem(value: 'share', height: 40, child: Text(FS.t(_lang, 'shareReportVet'), style: TextStyle(fontSize: 13, color: textColor))),
          PopupMenuItem(value: 'manage', height: 40, child: Text(FS.t(_lang, 'manageFarmWord'), style: TextStyle(fontSize: 13, color: textColor))),
        ],
      ),
    );
  }

  // Download Report / Download Critical Report -> full-screen Report Preview.
  // Mirrors openReportPreview() in vanix_screens_preview.html.
  void _openReportPreview({required bool critical}) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ReportPreviewScreen(appState: widget.appState, farm: widget.farm, critical: critical),
    ));
  }

  // Share Report with vet -> vet picker sheet -> toast. Mirrors
  // farm-detail-kebab-share -> window.openVetSheet() in
  // vanix_screens_preview.html.
  void _openShareWithVetSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) {
        final isDark = widget.appState.isDark;
        final bg = isDark ? VanixColors.darkSecond : Colors.white;
        final text1 = isDark ? Colors.white : VanixColors.textPrimary;
        final border = isDark ? VanixColors.darkBorder : VanixColors.border;
        const vets = ['Dr. Sharma', 'Dr. Rao', 'Dr. Iyer'];
        return Container(
          decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(VanixRadius.pill))),
          padding: const EdgeInsets.fromLTRB(VanixSpacing.xl, VanixSpacing.md, VanixSpacing.xl, 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: VanixSpacing.md),
            Text(FS.t(_lang, 'pickVet'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: text1)),
            const SizedBox(height: VanixSpacing.md),
            for (final v in vets)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    _snack('${FS.t(_lang, 'reportSharedWith')} $v');
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 48),
                    alignment: AlignmentDirectional.centerStart,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(color: isDark ? VanixColors.darkSubSurface : VanixColors.bgCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: border)),
                    child: Text(v, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: text1)),
                  ),
                ),
              ),
          ]),
        );
      },
    );
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 1)),
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

  // ── Herd Activity pane: filter + rumination graph + activity chips ─────
  // Funnel sheet is Cows-only now (Activity category removed) — the 4
  // activity chips render directly under the graph card instead. Mirrors
  // renderFdRumination()/fdToggleActivity() in vanix_screens_preview.html.
  Widget _herdPane(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.farm.cows.isNotEmpty) _ruminationCard(isDark),
      ],
    );
  }

  // ignore: unused_element
  void _openHerdFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _HerdFilterSheet(
        lang: _lang,
        isDark: widget.appState.isDark,
        cows: widget.farm.cows,
        cow: _fdHerdCow,
        onApply: (c) => setState(() {
          _fdHerdCow = c;
        }),
      ),
    );
  }

  // Toggling Rumination just shows/hides its line; tapping a secondary
  // activity (Standing/Resting/Feeding) swaps it in, replacing any other
  // secondary already selected. Mirrors fdToggleActivity() exactly.
  void _fdToggleActivity(String key) {
    setState(() {
      if (key == 'rumination') {
        if (_fdActiveSet.contains('rumination')) {
          _fdActiveSet.remove('rumination');
        } else {
          _fdActiveSet.insert(0, 'rumination');
        }
      } else {
        final already = _fdActiveSet.contains(key);
        _fdActiveSet = _fdActiveSet.where((k) => k == 'rumination').toList();
        if (!already) _fdActiveSet.add(key);
      }
    });
  }

  // ── Herd rumination / activity card ─────────────────────────────────────
  Widget _ruminationCard(bool isDark) {
    final isSunrise = widget.farm.id == 'sunrise';
    final ruminationPts = isSunrise ? _kRuminationSunrise : _kRuminationNormal;
    final textColor = isDark ? Colors.white : VanixColors.textPrimary;
    final ruminationOn = _fdActiveSet.contains('rumination');
    final anomaly = ruminationOn && isSunrise;

    // When exactly 2 activities are picked, the graph zooms into ONLY their
    // overlapping active-hours window — no data outside it is drawn at all
    // (not just highlighted). With 0/1 picked, show the full day.
    int windowLo = 0, windowHi = 24;
    String overlapCaption = '';
    bool overlapFound = false;
    bool noGraph = false;
    if (_fdActiveSet.length == 2) {
      final rA = _kFdActMeta[_fdActiveSet[0]]!.range;
      final rB = _kFdActMeta[_fdActiveSet[1]]!.range;
      final oStart = rA[0] > rB[0] ? rA[0] : rB[0];
      final oEnd = rA[1] < rB[1] ? rA[1] : rB[1];
      if (oStart < oEnd) {
        overlapFound = true;
        windowLo = oStart;
        windowHi = oEnd;
        String pad(int n) => '${(n % 24).toString().padLeft(2, '0')}:00';
        overlapCaption = '${FS.t(_lang, 'overlapWord')}: ${pad(oStart)}–${pad(oEnd)} (${oEnd - oStart}h)';
      } else {
        noGraph = true;
        overlapCaption = FS.t(_lang, 'noOverlapWord');
      }
    }
    final anomalyDrawn = anomaly && windowLo == 0;

    // Build one polyline per active key, sliced to [windowLo, windowHi] —
    // sourcing rumination from the per-farm pts and everything else from
    // _kFdActMeta.
    final lines = <_FdActLine>[
      if (!noGraph)
        for (final key in _fdActiveSet)
          _FdActLine(
            points: (key == 'rumination' ? ruminationPts : _kFdActMeta[key]!.pts!).sublist(windowLo, windowHi + 1),
            color: _kFdActMeta[key]!.color,
            anomalySegment: key == 'rumination' && anomalyDrawn ? const (13, 17) : null,
          ),
    ];

    final titleLabel = _fdActiveSet.isEmpty
        ? FS.t(_lang, 'actRumination')
        : _fdActiveSet.map(_activityLabel).join(' & ');

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
              Expanded(child: Text('${FS.t(_lang, 'fdHerdTitlePre')} $titleLabel — ${FS.t(_lang, 'fdHerdTitlePost')}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor))),
              if (ruminationOn && !noGraph) _ruminationPill(anomalyDrawn),
            ],
          ),
          if (!noGraph) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              width: double.infinity,
              child: CustomPaint(
                painter: _MultiActivityPainter(lines: lines),
                size: Size.infinite,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final l in (windowLo == 0 && windowHi == 24)
                    ? const ['00:00', '06:00', '12:00', '18:00', '24:00']
                    : ['${windowLo.toString().padLeft(2, '0')}:00', '${windowHi.toString().padLeft(2, '0')}:00'])
                  Text(l, style: const TextStyle(fontSize: 9, color: VanixColors.textHint)),
              ],
            ),
          ],
          if (anomalyDrawn)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: 10),
              child: Text(FS.t(_lang, 'fdAnomalyNote'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.5, color: VanixColors.warningInk)),
            ),
          if (_fdActiveSet.length == 2)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: 10),
              child: Text(
                overlapCaption,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: overlapFound ? FontWeight.w600 : FontWeight.w400,
                  color: overlapFound ? textColor : VanixColors.textHint,
                ),
              ),
            ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final key in const ['rumination', 'standing', 'resting', 'feeding']) ...[
                  _fdActivityChip(key, isDark),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fdActivityChip(String key, bool isDark) {
    final on = _fdActiveSet.contains(key);
    final color = _kFdActMeta[key]!.color;
    return InkWell(
      onTap: () => _fdToggleActivity(key),
      borderRadius: BorderRadius.circular(17),
      child: Container(
        height: 34,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: on ? color : (isDark ? VanixColors.darkBorder : VanixColors.border)),
          color: on ? color : (isDark ? VanixColors.darkSecond : VanixColors.bgCard),
        ),
        child: Text(
          _activityLabel(key),
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: on ? Colors.white : (isDark ? Colors.white : VanixColors.textPrimary)),
        ),
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

  String _activityLabel(String key) {
    switch (key) {
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
// vanix_screens_preview.html. The Activity category was removed from this
// sheet (activity selection now lives as chips under the graph) — the sheet
// is Cows-only.
// ─────────────────────────────────────────────────────────────────────────
class _HerdFilterSheet extends StatefulWidget {
  final String lang;
  final bool isDark;
  final List<CowModel> cows;
  final String cow;
  final void Function(String cow) onApply;
  const _HerdFilterSheet({
    required this.lang,
    required this.isDark,
    required this.cows,
    required this.cow,
    required this.onApply,
  });

  @override
  State<_HerdFilterSheet> createState() => _HerdFilterSheetState();
}

class _HerdFilterSheetState extends State<_HerdFilterSheet> {
  late String _cow = widget.cow;

  String t(String k) => FS.t(widget.lang, k);

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bg = isDark ? VanixColors.darkSecond : Colors.white;
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
            child: Container(
              color: isDark ? VanixColors.darkSubSurface : VanixColors.bgWarm,
              padding: const EdgeInsetsDirectional.all(12),
              child: _cowsPane(isDark),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(_cow);
                Navigator.of(context).pop();
              },
              child: Text(t('applyFilters')),
            ),
          ),
        ],
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

/// One activity's polyline data for the herd-activity graph.
class _FdActLine {
  final List<double> points;
  final Color color;
  final (int, int)? anomalySegment; // hour indices (inclusive) to highlight
  const _FdActLine({required this.points, required this.color, this.anomalySegment});
}

/// Paints one polyline per active herd-activity (0–60 scale, 24 hourly
/// points), an optional overlap-window shaded rect, and per-line
/// anomaly-dip highlight segments. Mirrors renderFdRumination()'s SVG
/// building in vanix_screens_preview.html.
class _MultiActivityPainter extends CustomPainter {
  final List<_FdActLine> lines;
  const _MultiActivityPainter({required this.lines});

  Offset _pt(List<double> points, int i, Size size) {
    final x = i / (points.length - 1) * size.width;
    final y = size.height - 4 - (points[i] / 60 * (size.height - 8));
    return Offset(x, y);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final baselinePaint = Paint()
      ..color = VanixColors.divider
      ..strokeWidth = 0.5;
    canvas.drawLine(Offset(0, size.height - 4), Offset(size.width, size.height - 4), baselinePaint);

    for (final line in lines) {
      final basePaint = Paint()
        ..color = line.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final path = Path();
      for (var i = 0; i < line.points.length; i++) {
        final p = _pt(line.points, i, size);
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(path, basePaint);

      if (line.anomalySegment != null) {
        final (from, to) = line.anomalySegment!;
        final dipPaint = Paint()
          ..color = VanixColors.warning
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        final dipPath = Path();
        for (var i = from; i <= to && i < line.points.length; i++) {
          final p = _pt(line.points, i, size);
          if (i == from) {
            dipPath.moveTo(p.dx, p.dy);
          } else {
            dipPath.lineTo(p.dx, p.dy);
          }
        }
        canvas.drawPath(dipPath, dipPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MultiActivityPainter oldDelegate) =>
      oldDelegate.lines != lines;
}

