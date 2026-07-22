import 'package:flutter/material.dart';
import '../i18n/farm_strings.dart';
import '../models/farm_models.dart';
import '../state/app_state.dart';
import '../theme/vanix_theme.dart';
import 'groups_screen.dart';

/// Cow Profile — mirrors #page-cow in prototype.html: hero (photo, name +
/// belt, breed, age, kebab, Status + Current Temp tiles), a 3-tab segmented
/// control (Timeline / Overview / Vet Logs), and a floating + actions sheet.
/// Pushed detail page — no bottom nav.
class CowProfileScreen extends StatefulWidget {
  final AppState appState;
  final FarmModel farm;
  final CowModel cow;
  const CowProfileScreen({super.key, required this.appState, required this.farm, required this.cow});

  @override
  State<CowProfileScreen> createState() => _CowProfileScreenState();
}

class _CowProfileScreenState extends State<CowProfileScreen> {
  int _tab = 0;
  final Set<int> _tlExpanded = {};

  // Activity tab — selected day for the inline per-date activity log.
  DateTime? _actlogSelected;

  // Overview temperature card range — Today (hourly, default) / This week
  // (7-point mock) / Custom (From/To -> 7-point mock, range-labelled).
  // Mirrors #cow-temp-range-btn in prototype.html.
  String _tempRange = 'today';
  DateTime? _tempFrom;
  DateTime? _tempTo;

  int _hashStr(String s) {
    var h = 0;
    for (final u in s.codeUnits) {
      h = (h * 31 + u) & 0xFFFFFFFF;
    }
    return h;
  }

  /// Deterministic 7-point mock temperature trend seeded by [seed] — same
  /// pattern as cowBatteryPct()/actlogHash() in prototype.html (hash-based,
  /// no DateTime.now() randomness).
  List<double> _weeklyTemps(String seed) {
    final h = _hashStr(seed);
    return List.generate(7, (i) => 29.5 + ((h >> (i * 3)) % 7) * 0.7);
  }

  // Timeline events — (key, date, dot color).
  static final List<TimelineEvent> _timeline = [
    const TimelineEvent('tlMilking', '2 Jul 2026', VanixColors.greenDeep),
    const TimelineEvent('tlCalved', '1 Jul 2026', VanixColors.greenDeep),
    const TimelineEvent('tlVet9m', '28 Jun 2026', VanixColors.warning),
    const TimelineEvent('tlPreg', '10 Oct 2025', VanixColors.greenDeep),
    const TimelineEvent('tlInsem', '18 Sep 2025', VanixColors.greenInk),
    const TimelineEvent('tlHeat', '17 Sep 2025', VanixColors.warning),
    const TimelineEvent('tlHeatMiss', '27 Aug 2025', VanixColors.danger),
    const TimelineEvent('tlVetNote', '20 Jul 2025', VanixColors.textHint),
    const TimelineEvent('tlCollar', '14 Jun 2025', VanixColors.textHint),
    const TimelineEvent('tlAdded', '12 Jun 2025', VanixColors.textHint),
  ];

  static const List<VetLog> _vetLogs = [
    VetLog('vl1t', 'vl1n', 'Dr. Sharma', '30 Jun 2026', attachment: 'Prescription.pdf'),
    VetLog('vl2t', 'vl2n', 'Dr. Rao', '15 May 2026', attachment: 'Scan_report.pdf'),
    VetLog('vl3t', 'vl3n', 'Dr. Iyer', '8 Jan 2026'),
  ];

  // Farmer-added vet logs (raw text, not localization keys) — rendered above
  // the seed logs. FS.t returns the string unchanged when it isn't a known key.
  final List<VetLog> _extraVetLogs = [];

  String get _lang => widget.appState.languageCode;
  bool get _isDark => widget.appState.isDark;

  /// Deterministic mock battery % from a hash of belt+name — mirrors
  /// cowBatteryPct() in prototype.html. No data-model change needed.
  int get _batteryPct {
    final s = '${widget.cow.belt}${widget.cow.name}';
    var h = 0;
    for (final unit in s.codeUnits) {
      h = (h * 31 + unit) & 0xFFFFFFFF;
    }
    return 20 + (h % 76);
  }

  // Status → (labelKey, bg, ink) tint mapping — shared with Farm Detail.
  ({String key, Color bg, Color ink}) _statusStyle() {
    switch (widget.cow.status) {
      case 'Fever':
        return (key: 'statusFeverAlert', bg: VanixColors.dangerBg, ink: VanixColors.dangerInk);
      case 'Heat':
        return (key: 'statusHeatCycle', bg: VanixColors.dangerBg, ink: VanixColors.dangerInk);
      case 'Pregnant':
        return (key: 'statusPregnant', bg: VanixColors.warningBg, ink: VanixColors.warningInk);
      case 'Milking':
      default:
        return (key: 'statusMilking', bg: VanixColors.activeBg, ink: VanixColors.greenInk);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = _isDark ? vanixDarkTheme(languageCode: _lang) : vanixLightTheme(languageCode: _lang);
    return Theme(
      data: theme,
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          backgroundColor: VanixColors.greenInk,
          onPressed: _openActionsSheet,
          child: const Icon(Icons.add, color: Colors.white),
        ),
        body: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildHero(),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(VanixSpacing.lg, VanixSpacing.lg, VanixSpacing.lg, 40),
              child: _buildTabBody(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Hero — full-bleed photo w/ gradient overlay (mirrors #page-cow's
  // .m-hero in vanix_screens_preview.html: back + kebab float over the photo,
  // name/breed/age/temp + gender/battery/status chips sit on the scrim at the
  // bottom — no separate Status/Current-Temp tiles below it any more). ──
  Widget _buildHero() {
    final st = _statusStyle();
    final placeholder = Container(color: _isDark ? VanixColors.darkSubSurface : VanixColors.bgWarm, alignment: Alignment.center, child: const Text('🐄', style: TextStyle(fontSize: 40)));

    return Container(
      decoration: BoxDecoration(boxShadow: _isDark ? VanixShadow.cardDark : VanixShadow.card),
      child: Column(
        children: [
          SizedBox(
            height: 224,
            child: Stack(
              fit: StackFit.expand,
              children: [
                widget.cow.photo == null ? placeholder : Image.asset(widget.cow.photo!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => placeholder),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x6B000000), Color(0x0D000000), Color(0x1F000000), Color(0xD1000000)],
                      stops: [0.0, 0.32, 0.52, 1.0],
                    ),
                  ),
                ),
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.symmetric(horizontal: 10),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _heroCircleBtn(Icons.chevron_left, () => Navigator.of(context).pop()),
                          _kebab(),
                        ],
                      ),
                    ),
                  ),
                ),
                PositionedDirectional(
                  start: 16, end: 16, bottom: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.cow.nm(_lang), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white)),
                      const SizedBox(height: 5),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(widget.cow.br(_lang), style: const TextStyle(fontSize: 13, color: Color(0xEBFFFFFF))),
                          const Text('  ·  ', style: TextStyle(color: Color(0x80FFFFFF))),
                          Text(widget.cow.ag(_lang), style: const TextStyle(fontSize: 13, color: Color(0xEBFFFFFF))),
                          const Text('  ·  ', style: TextStyle(color: Color(0x80FFFFFF))),
                          Text(widget.appState.fmtTemp(widget.cow.temp), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Wrap(spacing: 6, runSpacing: 6, children: [_onPhotoChip(FS.t(_lang, 'genderFemale')), _batteryChip(), _statusPillChip(st)]),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildTabBar(),
        ],
      ),
    );
  }

  Widget _heroCircleBtn(IconData icon, VoidCallback onTap) => SizedBox(
        width: 38, height: 38,
        child: Material(
          color: const Color(0x59000000),
          shape: const CircleBorder(),
          child: InkWell(customBorder: const CircleBorder(), onTap: onTap, child: Icon(icon, size: 20, color: Colors.white)),
        ),
      );

  Widget _onPhotoChip(String text) => Container(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: const Color(0x2EFFFFFF), border: Border.all(color: const Color(0x52FFFFFF)), borderRadius: BorderRadius.circular(VanixRadius.sm)),
        child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
      );

  Widget _statusPillChip(({String key, Color bg, Color ink}) st) => Container(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(color: st.bg, borderRadius: BorderRadius.circular(VanixRadius.pill)),
        child: Text(FS.t(_lang, st.key), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: st.ink)),
      );

  Widget _batteryChip() {
    final pct = _batteryPct;
    final low = pct <= 30;
    final color = low ? const Color(0xFFFFD5CE) : Colors.white;
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0x2EFFFFFF),
        border: Border.all(color: low ? const Color(0xFFFFD5CE) : const Color(0x52FFFFFF)),
        borderRadius: BorderRadius.circular(VanixRadius.sm),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(low ? Icons.battery_alert : Icons.battery_full, size: 12, color: color),
        const SizedBox(width: 3),
        Text('$pct%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }

  void _openReportSheet({required bool critical}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ReportPeriodSheet(
        isDark: _isDark,
        lang: _lang,
        onDownloaded: () => _snack('${FS.t(_lang, critical ? 'fdCriticalDownloaded' : 'reportDownloaded')} — ${widget.cow.nm(_lang)}'),
      ),
    );
  }

  // Report-type chooser (full / critical) -> report period sheet. Mirrors
  // #cow-reptype-sheet -> #cow-report-sheet in vanix_screens_preview.html.
  void _openReportTypeSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) {
        final bg = _isDark ? VanixColors.darkSecond : Colors.white;
        final text1 = _isDark ? Colors.white : VanixColors.textPrimary;
        Widget row(String label, VoidCallback onTap, {bool danger = false}) => InkWell(
              onTap: onTap,
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                alignment: AlignmentDirectional.centerStart,
                child: Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: danger ? VanixColors.danger : text1)),
              ),
            );
        return Container(
          decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(VanixRadius.pill))),
          padding: const EdgeInsets.fromLTRB(VanixSpacing.xl, VanixSpacing.md, VanixSpacing.xl, 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: _isDark ? VanixColors.darkBorder : VanixColors.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: VanixSpacing.md),
            Text(FS.t(_lang, 'reportTypeTitle'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: text1)),
            const SizedBox(height: 4),
            row(FS.t(_lang, 'fullReport'), () { Navigator.of(sheetCtx).pop(); _openReportSheet(critical: false); }),
            row(FS.t(_lang, 'criticalReport'), () { Navigator.of(sheetCtx).pop(); _openReportSheet(critical: true); }, danger: true),
          ]),
        );
      },
    );
  }

  // Share Report with vet -> vet picker -> toast. Mirrors cow-kebab-share ->
  // window.openVetSheet() in vanix_screens_preview.html.
  void _openShareWithVetSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) {
        final bg = _isDark ? VanixColors.darkSecond : Colors.white;
        final text1 = _isDark ? Colors.white : VanixColors.textPrimary;
        final border = _isDark ? VanixColors.darkBorder : VanixColors.border;
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
                    decoration: BoxDecoration(color: _isDark ? VanixColors.darkSubSurface : VanixColors.bgCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: border)),
                    child: Text(v, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: text1)),
                  ),
                ),
              ),
          ]),
        );
      },
    );
  }

  // Kebab order: Edit / Add to group / Download Report / Share Report with
  // vet / Delete — mirrors #cow-kebab-menu in vanix_screens_preview.html.
  Widget _kebab() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white),
      onSelected: (v) {
        switch (v) {
          case 'group':
            showAddToGroupSheet(context, widget.appState, widget.farm.id, widget.cow.no);
            break;
          case 'download':
            _openReportTypeSheet();
            break;
          case 'share':
            _openShareWithVetSheet();
            break;
          default:
            _snack('${_actionVerb(v)}…');
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: 'edit', child: Text(FS.t(_lang, 'editWord'))),
        PopupMenuItem(value: 'group', child: Text(FS.t(_lang, 'addToGroup'))),
        PopupMenuItem(value: 'download', child: Text(FS.t(_lang, 'downloadReport'))),
        PopupMenuItem(value: 'share', child: Text(FS.t(_lang, 'shareReportVet'))),
        PopupMenuItem(
          value: 'delete',
          child: Text(FS.t(_lang, 'deleteWord'), style: const TextStyle(color: VanixColors.danger)),
        ),
      ],
    );
  }

  String _actionVerb(String v) {
    switch (v) {
      case 'edit':
        return FS.t(_lang, 'editWord');
      case 'delete':
        return FS.t(_lang, 'deleteWord');
      default:
        return FS.t(_lang, 'addToGroup');
    }
  }

  // ── Tab bar — underline tabs flush at the hero's bottom edge ────────────
  Widget _buildTabBar() {
    final labels = ['tabTimeline', 'tabOverview', 'tabActivity', 'tabMilkData', 'tabVetLogs'];
    return Container(
      color: _isDark ? VanixColors.darkPrimary : VanixColors.bgWarm,
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _tab = i),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 44),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: _tab == i ? VanixColors.greenInk : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                  child: Text(
                    FS.t(_lang, labels[i]),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: _tab == i ? FontWeight.w600 : FontWeight.w500,
                      color: _tab == i ? VanixColors.greenInk : VanixColors.textHint,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabBody() {
    switch (_tab) {
      case 1:
        return _buildOverview();
      case 2:
        return _buildActivity();
      case 3:
        return _buildMilkData();
      case 4:
        return _buildVetLogs();
      case 0:
      default:
        return _buildTimeline();
    }
  }

  // ── Timeline tab ──────────────────────────────────────────────────────
  Widget _buildTimeline() {
    final sheetBg = _isDark ? VanixColors.darkSecond : VanixColors.bgCard;
    return Container(
      padding: const EdgeInsets.all(VanixSpacing.lg),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: BorderRadius.circular(VanixRadius.lg),
        border: Border.all(color: _isDark ? VanixColors.darkBorder : VanixColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          for (var i = 0; i < _timeline.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == _timeline.length - 1 ? 0 : VanixSpacing.md),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // dotted rail — the dot sits at the vertical center of the
                    // card regardless of its height (2-line vs. expanded).
                    SizedBox(
                      width: 12,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (i != 0)
                            Align(
                              alignment: Alignment.topCenter,
                              child: FractionallySizedBox(
                                heightFactor: 0.5,
                                child: _DottedLine(color: _isDark ? VanixColors.darkBorder : VanixColors.border),
                              ),
                            ),
                          if (i != _timeline.length - 1)
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                heightFactor: 0.5,
                                child: _DottedLine(color: _isDark ? VanixColors.darkBorder : VanixColors.border),
                              ),
                            ),
                          Container(width: 12, height: 12, decoration: BoxDecoration(color: _timeline[i].dot, shape: BoxShape.circle)),
                        ],
                      ),
                    ),
                    const SizedBox(width: VanixSpacing.md),
                    Expanded(child: _timelineCard(i)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _timelineCard(int i) {
    final textColor = _isDark ? Colors.white : VanixColors.textPrimary;
    final ev = _timeline[i];
    final open = _tlExpanded.contains(i);
    return InkWell(
      onTap: () => setState(() { open ? _tlExpanded.remove(i) : _tlExpanded.add(i); }),
      borderRadius: BorderRadius.circular(VanixRadius.md),
      child: Container(
        padding: const EdgeInsets.all(VanixSpacing.md),
        decoration: BoxDecoration(
          color: _isDark ? VanixColors.darkSubSurface : VanixColors.bgCard,
          borderRadius: BorderRadius.circular(VanixRadius.md),
          border: Border.all(color: _isDark ? VanixColors.darkBorder : VanixColors.border, width: 0.5),
          boxShadow: _isDark ? VanixShadow.cardDark : VanixShadow.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(FS.t(_lang, ev.key), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
                      const SizedBox(height: 2),
                      Text(ev.date, style: const TextStyle(fontSize: 12, color: VanixColors.textHint)),
                    ],
                  ),
                ),
                Icon(open ? Icons.expand_less : Icons.chevron_right, size: 18, color: VanixColors.textHint),
              ],
            ),
            if (open) ...[
              const SizedBox(height: VanixSpacing.md),
              Text(FS.t(_lang, '${ev.key}D'),
                  style: TextStyle(fontSize: 12, height: 1.6, color: _isDark ? VanixColors.textOnDarkDim : VanixColors.textHint)),
              const SizedBox(height: VanixSpacing.md),
              OutlinedButton(
                onPressed: () => setState(() => _tlExpanded.remove(i)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  side: BorderSide(color: _isDark ? VanixColors.darkBorder : VanixColors.border),
                  foregroundColor: textColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(FS.t(_lang, 'hideWord'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Overview tab (v2 — colourful) ─────────────────────────────────────
  Widget _buildOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(child: _ovStatCard('19 Mar', 'ovLastHeat', VanixColors.warning)),
          const SizedBox(width: VanixSpacing.sm),
          Expanded(child: _ovStatCard('14 Apr', 'ovNextHeat', VanixColors.greenInk)),
        ]),
        const SizedBox(height: VanixSpacing.sm),
        Row(children: [
          Expanded(child: _ovStatCard('18 Jun', 'ovLastSpike', VanixColors.danger)),
          const SizedBox(width: VanixSpacing.sm),
          Expanded(child: _ovStatCard('1', 'ovNumCalving', VanixColors.accentBlue)),
        ]),
        const SizedBox(height: VanixSpacing.xl),
        _sectionLabel('tempWord'),
        _tempCard(),
        const SizedBox(height: VanixSpacing.xl),
        _sectionLabel('remindersWord'),
        _remindersCard(),
      ],
    );
  }

  // ── Activity tab — Activity Status tiles + inline per-date activity log
  // (day-chip strip + 30-min action rows), mirrors renderCowActivity() /
  // renderCowActlog() in vanix_screens_preview.html (folded out of Overview
  // into its own tab). ──
  String _actlogDateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  List<DateTime> get _actlogChips {
    const today = 20; // fixed "today" reference (2026-07-20) per CLAUDE.md currentDate
    return List.generate(14, (i) => DateTime(2026, 7, today - 13 + i));
  }

  List<(String action, Color color, Color bg, IconData icon, String duration, String start)> _actlogRowsFor(DateTime d) {
    final seed = _hashStr(_actlogDateKey(d));
    const actions = <(String, Color, Color, IconData)>[
      ('Resting', Color(0xFF7C3AED), Color(0x1F7C3AED), Icons.bed_outlined),
      ('Feeding', VanixColors.warning, Color(0x24E8A020), Icons.restaurant),
      ('Ruminating', VanixColors.greenInk, VanixColors.activeBg, Icons.pets),
      ('Standing', Color(0xFF2563EB), Color(0x1F2563EB), Icons.directions_walk),
    ];
    final rows = <(String, Color, Color, IconData, String, String)>[];
    var slot = 0, i = 0;
    while (slot < 24 * 60) {
      final pick = actions[(seed + i) % actions.length];
      final h = slot ~/ 60, m = slot % 60;
      rows.add((pick.$1, pick.$2, pick.$3, pick.$4, '30 min', '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}'));
      slot += 30;
      i++;
    }
    return rows;
  }

  Widget _buildActivity() {
    _actlogSelected ??= _actlogChips.last;
    final rows = _actlogRowsFor(_actlogSelected!);
    final textColor = _isDark ? Colors.white : VanixColors.textPrimary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('actStatus'),
        _activityCard(),
        const SizedBox(height: VanixSpacing.xl),
        _sectionLabel('activityLogWord'),
        SizedBox(
          height: 60,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final d in _actlogChips)
                Padding(padding: const EdgeInsetsDirectional.only(end: 8), child: _actlogChip(d)),
            ],
          ),
        ),
        const SizedBox(height: VanixSpacing.sm),
        for (final r in rows)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _isDark ? VanixColors.darkBorder : VanixColors.border))),
            child: Row(children: [
              Container(width: 32, height: 32, decoration: BoxDecoration(color: r.$3, borderRadius: BorderRadius.circular(10)), child: Icon(r.$4, size: 16, color: r.$2)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.$1, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
                    const SizedBox(height: 2),
                    Text('${r.$5} · ${r.$6}', style: const TextStyle(fontSize: 12, color: VanixColors.textHint)),
                  ],
                ),
              ),
            ]),
          ),
      ],
    );
  }

  static const List<String> _wkShort = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  Widget _actlogChip(DateTime d) {
    final on = _actlogSelected != null && _actlogDateKey(d) == _actlogDateKey(_actlogSelected!);
    final textColor = _isDark ? Colors.white : VanixColors.textPrimary;
    return InkWell(
      onTap: () => setState(() => _actlogSelected = d),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? VanixColors.activeBg : (_isDark ? VanixColors.darkSubSurface : VanixColors.bgCard),
          border: Border.all(color: on ? VanixColors.greenInk : (_isDark ? VanixColors.darkBorder : VanixColors.border)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_wkShort[d.weekday % 7], style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: on ? VanixColors.greenInk : VanixColors.textHint)),
            const SizedBox(height: 2),
            Text('${d.day}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: on ? VanixColors.greenInk : textColor)),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String key) => Padding(
        padding: const EdgeInsets.only(bottom: VanixSpacing.sm),
        child: Text(FS.t(_lang, key).toUpperCase(),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: VanixColors.textHint)),
      );

  Widget _card({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(VanixSpacing.lg),
      decoration: BoxDecoration(
        color: _isDark ? VanixColors.darkSecond : VanixColors.bgCard,
        borderRadius: BorderRadius.circular(VanixRadius.lg),
        border: Border.all(color: _isDark ? VanixColors.darkBorder : VanixColors.border, width: 0.5),
        boxShadow: _isDark ? VanixShadow.cardDark : VanixShadow.card,
      ),
      child: child,
    );
  }

  // Mirrors ovStatCardNoIcon() in vanix_screens_preview.html — just the
  // coloured left-edge stripe + big number + label, no icon of any kind.
  Widget _ovStatCard(String big, String labelKey, Color accent) {
    final textColor = _isDark ? Colors.white : VanixColors.textPrimary;
    return ClipRRect(
      borderRadius: BorderRadius.circular(VanixRadius.lg),
      child: Stack(children: [
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(big, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textColor)),
              const SizedBox(height: 4),
              Text(FS.t(_lang, labelKey).toUpperCase(),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: VanixColors.textHint)),
            ],
          ),
        ),
        PositionedDirectional(start: 0, top: 0, bottom: 0, child: Container(width: 4, color: accent)),
      ]),
    );
  }

  String _tempRangeSeed() {
    if (_tempRange == 'custom' && _tempFrom != null && _tempTo != null) {
      return '${widget.cow.name}-${_tempFrom!.toIso8601String()}-${_tempTo!.toIso8601String()}';
    }
    return '${widget.cow.name}-week';
  }

  String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  String _tempRangeLabel() {
    switch (_tempRange) {
      case 'custom':
        if (_tempFrom != null && _tempTo != null) return '${_fmtDate(_tempFrom!)} – ${_fmtDate(_tempTo!)}';
        return FS.t(_lang, 'fdRangeCustom');
      case 'week':
        return FS.t(_lang, 'fdRangeWeek');
      default:
        return FS.t(_lang, 'todayWord');
    }
  }

  Future<void> _pickCustomTempRange() async {
    final from = await showDatePicker(context: context, initialDate: DateTime(2026, 7, 13), firstDate: DateTime(2024), lastDate: DateTime(2027));
    if (from == null || !mounted) return;
    final to = await showDatePicker(context: context, initialDate: DateTime(2026, 7, 20), firstDate: from, lastDate: DateTime(2027));
    if (to == null) return;
    setState(() {
      _tempRange = 'custom';
      _tempFrom = from;
      _tempTo = to;
    });
  }

  Widget _tempRangeDropdown(Color textColor) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 30),
      onSelected: (v) {
        if (v == 'custom') {
          _pickCustomTempRange();
        } else {
          setState(() => _tempRange = v);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: 'today', child: Text(FS.t(_lang, 'todayWord'))),
        PopupMenuItem(value: 'week', child: Text(FS.t(_lang, 'fdRangeWeek'))),
        PopupMenuItem(value: 'custom', child: Text(FS.t(_lang, 'fdRangeCustom'))),
      ],
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: _isDark ? VanixColors.darkBorder : VanixColors.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(_tempRangeLabel(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor)),
          const SizedBox(width: 4),
          Icon(Icons.keyboard_arrow_down, size: 14, color: textColor),
        ]),
      ),
    );
  }

  Widget _tempCard() {
    final textColor = _isDark ? Colors.white : VanixColors.textPrimary;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: VanixColors.activeBg, borderRadius: BorderRadius.circular(14)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 7, height: 7, decoration: const BoxDecoration(color: VanixColors.greenDeep, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(FS.t(_lang, 'tempNormal'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: VanixColors.greenInk)),
                ]),
              ),
              Row(children: [
                Text(widget.appState.fmtTemp('33°C'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor)),
                const SizedBox(width: 8),
                _tempRangeDropdown(textColor),
              ]),
            ],
          ),
          const SizedBox(height: VanixSpacing.md),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Column(children: [
              Text('40°C', style: TextStyle(fontSize: 9, color: VanixColors.textHint)),
              SizedBox(height: 36),
              Text('30°C', style: TextStyle(fontSize: 9, color: VanixColors.textHint)),
              SizedBox(height: 36),
              Text('20°C', style: TextStyle(fontSize: 9, color: VanixColors.textHint)),
            ]),
            const SizedBox(width: VanixSpacing.sm),
            Expanded(
              child: Column(children: [
                SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _TempPainter(
                      isDark: _isDark,
                      values: _tempRange == 'today' ? null : _weeklyTemps(_tempRangeSeed()),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                _tempRange == 'today'
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (final x in const ['00:00', '06:00', '12:00', '18:00', '24:00'])
                            Text(x, style: const TextStyle(fontSize: 9, color: VanixColors.textHint)),
                        ],
                      )
                    : Text(_tempRangeLabel(), style: const TextStyle(fontSize: 9, color: VanixColors.textHint)),
              ]),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _activityCard() {
    final acts = [
      (Icons.pets, '210', 'actRumination', VanixColors.greenInk, VanixColors.activeBg),
      (Icons.restaurant, '268', 'actFeeding', VanixColors.warning, VanixColors.warning.withValues(alpha: 0.14)),
      (Icons.directions_walk, '96', 'actStanding', VanixColors.accentBlue, VanixColors.accentBlue.withValues(alpha: 0.12)),
      (Icons.bedtime_outlined, '512', 'actResting', VanixColors.accentViolet, VanixColors.accentViolet.withValues(alpha: 0.12)),
    ];
    final textColor = _isDark ? Colors.white : VanixColors.textPrimary;
    return _card(
      padding: const EdgeInsets.symmetric(vertical: VanixSpacing.md, horizontal: 6),
      child: Row(
        children: [
          for (var i = 0; i < acts.length; i++)
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  border: i == 0 ? null : Border(left: BorderSide(color: _isDark ? VanixColors.darkDivider : VanixColors.divider)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(color: acts[i].$5, borderRadius: BorderRadius.circular(9)),
                      child: Icon(acts[i].$1, size: 15, color: acts[i].$4),
                    ),
                    const SizedBox(height: 8),
                    Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                      Text(acts[i].$2, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: textColor)),
                      const SizedBox(width: 3),
                      const Text('min', style: TextStyle(fontSize: 10, color: VanixColors.textHint)),
                    ]),
                    const SizedBox(height: 3),
                    Text(FS.t(_lang, acts[i].$3).toUpperCase(),
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.3, color: VanixColors.textHint)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }


  Widget _remindersCard() {
    return Container(
      padding: const EdgeInsets.all(VanixSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(VanixRadius.lg),
        border: Border.all(color: _isDark ? VanixColors.darkBorder : VanixColors.border, width: 1.5, style: BorderStyle.solid),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.notifications_none, size: 17, color: VanixColors.textHint),
          const SizedBox(width: 8),
          Text(FS.t(_lang, 'noActiveReminders'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: VanixColors.textHint)),
        ],
      ),
    );
  }

  // ── Milk Data tab (colourful, read-only) ──────────────────────────────
  Widget _buildMilkData() {
    const history = [
      (date: '12 Jun 2026', m: '7:30', e: '6:00', total: '12.5', missing: false),
      (date: '13 Jun 2026', m: '7:00', e: '5:30', total: '14.5', missing: false),
      (date: '14 Jun 2026', m: '6:45', e: '', total: '6.5', missing: true),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('wkYield8'),
        _card(
          padding: const EdgeInsets.fromLTRB(VanixSpacing.md, VanixSpacing.lg, VanixSpacing.md, VanixSpacing.lg),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Column(children: [
              Text('60L', style: TextStyle(fontSize: 9, color: VanixColors.textHint)),
              SizedBox(height: 36),
              Text('48L', style: TextStyle(fontSize: 9, color: VanixColors.textHint)),
              SizedBox(height: 36),
              Text('36L', style: TextStyle(fontSize: 9, color: VanixColors.textHint)),
            ]),
            const SizedBox(width: VanixSpacing.sm),
            Expanded(
              child: Column(children: [
                SizedBox(
                  height: 96,
                  width: double.infinity,
                  child: CustomPaint(painter: _WeeklyPainter(values: const [40, 47, 44, 50, 46, 58, 47, 45], isDark: _isDark, peakIndex: 5)),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (var i = 1; i <= 8; i++)
                      Text('W$i', style: const TextStyle(fontSize: 9, color: VanixColors.textHint)),
                  ],
                ),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: VanixSpacing.md),
        Row(children: [
          Expanded(child: _weekTile('58', 'highestWeek', '16 Jun', VanixColors.greenDeep, VanixColors.greenInk)),
          const SizedBox(width: VanixSpacing.sm),
          Expanded(child: _weekTile('47', 'lowestWeek', '30 Jun', VanixColors.warning, VanixColors.warningInk)),
        ]),
        const SizedBox(height: VanixSpacing.xl),
        _sectionLabel('milkLogHistory'),
        for (final r in history) _milkHistoryRow(r.date, r.m, r.e, r.total, r.missing),
        const SizedBox(height: 4),
        Text(FS.t(_lang, 'milkDataReadonly'),
            style: const TextStyle(fontSize: 11, height: 1.5, fontStyle: FontStyle.italic, color: VanixColors.textHint)),
      ],
    );
  }

  Widget _weekTile(String big, String labelKey, String sub, Color accent, Color numColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(VanixRadius.lg),
      child: Stack(children: [
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                Text(big, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: numColor)),
                const SizedBox(width: 4),
                const Text('L', style: TextStyle(fontSize: 12, color: VanixColors.textHint)),
              ]),
              const SizedBox(height: 4),
              Text(FS.t(_lang, labelKey).toUpperCase(),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.3, color: VanixColors.textHint)),
              const SizedBox(height: 1),
              Text(sub, style: const TextStyle(fontSize: 11, color: VanixColors.textHint)),
            ],
          ),
        ),
        PositionedDirectional(start: 0, top: 0, bottom: 0, child: Container(width: 4, color: accent)),
      ]),
    );
  }

  Widget _sessionPill(bool morning) {
    final bg = morning ? VanixColors.warning.withValues(alpha: 0.16) : VanixColors.accentBlue.withValues(alpha: 0.12);
    final fg = morning ? VanixColors.warningInk : VanixColors.accentBlue;
    return Container(
      constraints: const BoxConstraints(minWidth: 74),
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(VanixRadius.md)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(morning ? Icons.wb_sunny_outlined : Icons.nightlight_outlined, size: 12, color: fg),
        const SizedBox(width: 5),
        Text(FS.t(_lang, morning ? 'sessMorning' : 'sessEvening'),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
      ]),
    );
  }

  Widget _milkSessRow(bool morning, String time, bool missing) {
    return Padding(
      padding: EdgeInsets.only(top: morning ? 0 : 6),
      child: Row(children: [
        _sessionPill(morning),
        const SizedBox(width: 8),
        if (missing)
          Row(children: [
            Text(FS.t(_lang, 'missingWord'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: VanixColors.danger)),
            const SizedBox(width: 4),
            const Icon(Icons.close, size: 12, color: VanixColors.danger),
          ])
        else ...[
          Text(time, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _isDark ? Colors.white : VanixColors.textPrimary)),
          const SizedBox(width: 4),
          const Icon(Icons.check, size: 13, color: VanixColors.greenDeep),
        ],
      ]),
    );
  }

  Widget _milkHistoryRow(String date, String m, String e, String total, bool missing) {
    return Container(
      margin: const EdgeInsets.only(bottom: VanixSpacing.md),
      padding: const EdgeInsets.all(VanixSpacing.lg),
      decoration: BoxDecoration(
        color: _isDark ? VanixColors.darkSecond : VanixColors.bgCard,
        borderRadius: BorderRadius.circular(VanixRadius.lg),
        border: missing
            ? Border.all(color: _isDark ? VanixColors.darkBorder : VanixColors.border, width: 1.5)
            : Border.all(color: _isDark ? VanixColors.darkBorder : VanixColors.border, width: 0.5),
        boxShadow: missing ? null : (_isDark ? VanixShadow.cardDark : VanixShadow.card),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _milkSessRow(true, m, false),
                _milkSessRow(false, e, missing),
              ],
            ),
          ),
          const SizedBox(width: VanixSpacing.md),
          Text(date, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: VanixColors.textHint)),
          const SizedBox(width: VanixSpacing.md),
          Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Text(total, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: missing ? VanixColors.danger : VanixColors.greenInk)),
            const SizedBox(width: 3),
            const Text('Lts', style: TextStyle(fontSize: 11, color: VanixColors.textHint)),
          ]),
        ],
      ),
    );
  }

  // ── Vet Logs tab ──────────────────────────────────────────────────────
  Widget _buildVetLogs() {
    final textColor = _isDark ? Colors.white : VanixColors.textPrimary;
    return Column(
      children: [
        for (final log in [..._extraVetLogs, ..._vetLogs])
          Container(
            margin: const EdgeInsets.only(bottom: VanixSpacing.md),
            padding: const EdgeInsets.all(VanixSpacing.lg),
            decoration: BoxDecoration(
              color: _isDark ? VanixColors.darkSecond : VanixColors.bgCard,
              borderRadius: BorderRadius.circular(VanixRadius.lg),
              border: Border.all(color: _isDark ? VanixColors.darkBorder : VanixColors.border, width: 0.5),
              boxShadow: _isDark ? VanixShadow.cardDark : VanixShadow.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(FS.t(_lang, log.titleKey), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
                    ),
                    const SizedBox(width: VanixSpacing.sm),
                    Text(log.date, style: const TextStyle(fontSize: 12, color: VanixColors.textHint)),
                  ],
                ),
                const SizedBox(height: 3),
                Text(log.vet, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: VanixColors.greenInk)),
                const SizedBox(height: 6),
                Text(FS.t(_lang, log.noteKey),
                    style: TextStyle(fontSize: 14, height: 1.5, color: _isDark ? VanixColors.textOnDarkDim : VanixColors.textPrimary)),
                if (log.attachment != null) ...[
                  const SizedBox(height: VanixSpacing.md),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Container(
                      padding: const EdgeInsetsDirectional.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _isDark ? VanixColors.darkSubSurface : VanixColors.bgWarm,
                        border: Border.all(color: _isDark ? VanixColors.darkBorder : VanixColors.border),
                        borderRadius: BorderRadius.circular(VanixRadius.sm),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.description_outlined, size: 14, color: _isDark ? Colors.white : VanixColors.textPrimary),
                          const SizedBox(width: 6),
                          Text(log.attachment!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _isDark ? Colors.white : VanixColors.textPrimary)),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  // ── Floating + actions sheet ──────────────────────────────────────────
  void _openActionsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ActionsSheet(
        isDark: _isDark,
        lang: _lang,
        cowName: widget.cow.nm(_lang),
        vets: const ['Dr. Sharma', 'Dr. Rao', 'Dr. Iyer'],
        onAddVetLog: (log) {
          setState(() {
            _extraVetLogs.insert(0, log);
            _tab = 3; // Vet Logs tab
          });
        },
      ),
    );
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${FS.t(_lang, 'cowActions')}: $msg'), duration: const Duration(seconds: 1)),
    );
  }
}

// ── Report period bottom sheet — Today/This week/This month/Custom (From/To)
// then "Download report" -> close + toast. Mirrors #cow-report-sheet in
// prototype.html. Mock/demo only — no real file is produced. ──
class _ReportPeriodSheet extends StatefulWidget {
  final bool isDark;
  final String lang;
  final VoidCallback onDownloaded;
  const _ReportPeriodSheet({required this.isDark, required this.lang, required this.onDownloaded});

  @override
  State<_ReportPeriodSheet> createState() => _ReportPeriodSheetState();
}

class _ReportPeriodSheetState extends State<_ReportPeriodSheet> {
  String _period = 'today';
  DateTime? _from;
  DateTime? _to;

  Color get _text1 => widget.isDark ? Colors.white : VanixColors.textPrimary;
  Color get _border => widget.isDark ? VanixColors.darkBorder : VanixColors.border;
  String _t(String k) => FS.t(widget.lang, k);

  Future<void> _pick(bool from) async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime(2026, 7, from ? 13 : 20),
      firstDate: DateTime(2024),
      lastDate: DateTime(2027),
    );
    if (d == null) return;
    setState(() { if (from) { _from = d; } else { _to = d; } });
  }

  Widget _radioRow(String value, String label) {
    final on = _period == value;
    return InkWell(
      onTap: () => setState(() => _period = value),
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        child: Row(children: [
          Icon(on ? Icons.radio_button_checked : Icons.radio_button_unchecked, size: 18, color: on ? VanixColors.greenInk : _border),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(fontSize: 14, color: _text1)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? VanixColors.darkSecond : Colors.white;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(VanixRadius.pill))),
        padding: const EdgeInsets.fromLTRB(VanixSpacing.xl, VanixSpacing.md, VanixSpacing.xl, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: VanixSpacing.md),
            Text(_t('downloadReportTitle'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _text1)),
            const SizedBox(height: VanixSpacing.sm),
            _radioRow('today', _t('reportPeriodToday')),
            _radioRow('week', _t('reportPeriodWeek')),
            _radioRow('month', _t('reportPeriodMonth')),
            _radioRow('custom', _t('reportPeriodCustom')),
            if (_period == 'custom') ...[
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pick(true),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 46), side: BorderSide(color: _border), foregroundColor: _text1),
                    child: Text(_from == null ? FS.t(widget.lang, 'fdFrom') : '${_from!.day}/${_from!.month}/${_from!.year}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pick(false),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 46), side: BorderSide(color: _border), foregroundColor: _text1),
                    child: Text(_to == null ? FS.t(widget.lang, 'fdTo') : '${_to!.day}/${_to!.month}/${_to!.year}'),
                  ),
                ),
              ]),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(minimumSize: const Size(0, 48), backgroundColor: VanixColors.greenInk, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onDownloaded();
                },
                child: Text(_t('downloadReportBtn'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ── Actions bottom sheet — full multi-step flow engine (mirrors caViews in
// prototype.html): status+reason, vet visit+schedule, vet log, heat (date+time),
// insemination (vet→type→log), pregnancy (date), delivery (yes/no→vet→log). ──
class _ActionsSheet extends StatefulWidget {
  final bool isDark;
  final String lang;
  final String cowName;
  final List<String> vets;
  final void Function(VetLog) onAddVetLog;
  const _ActionsSheet({required this.isDark, required this.lang, required this.cowName, required this.vets, required this.onAddVetLog});

  @override
  State<_ActionsSheet> createState() => _ActionsSheetState();
}

class _ActionsSheetState extends State<_ActionsSheet> {
  final List<String> _stack = ['main'];
  String _flow = '', _status = '', _vet = '', _insemType = '', _doneMsg = '', _vaccineType = '';
  bool _attach = false;
  String _date = '', _time = '';
  final _reason = TextEditingController();
  final _notes = TextEditingController();

  bool get isDark => widget.isDark;
  Color get _text1 => isDark ? Colors.white : VanixColors.textPrimary;
  Color get _border => isDark ? VanixColors.darkBorder : VanixColors.border;
  Color get _fieldBg => isDark ? VanixColors.darkSubSurface : VanixColors.bgCard;
  String _t(String k) => FS.t(widget.lang, k);
  String get _step => _stack.last;

  @override
  void dispose() {
    _reason.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _go(String v) => setState(() => _stack.add(v));
  void _back() { if (_stack.length > 1) setState(() => _stack.removeLast()); }
  void _done(String msg) => setState(() { _doneMsg = msg; _stack.add('done'); });

  Future<void> _pickDate() async {
    final d = await showDatePicker(context: context, initialDate: DateTime(2026, 7, 16), firstDate: DateTime(2024), lastDate: DateTime(2027));
    if (d != null) setState(() => _date = '${d.day}/${d.month}/${d.year}');
  }

  Future<void> _pickTime() async {
    final tm = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 9, minute: 0));
    if (tm != null) setState(() => _time = tm.format(context));
  }

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? VanixColors.darkSecond : Colors.white;
    final v = _view();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(VanixRadius.pill))),
        padding: const EdgeInsets.fromLTRB(VanixSpacing.xl, VanixSpacing.md, VanixSpacing.xl, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: VanixSpacing.md),
            Row(
              children: [
                if (_stack.length > 1 && _step != 'done')
                  InkWell(
                    onTap: _back,
                    customBorder: const CircleBorder(),
                    child: Padding(padding: const EdgeInsets.only(right: 6), child: Icon(Icons.chevron_left, color: _text1)),
                  ),
                Expanded(child: Text(v.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _text1))),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  customBorder: const CircleBorder(),
                  child: Icon(Icons.close, color: _text1),
                ),
              ],
            ),
            const SizedBox(height: VanixSpacing.md),
            Flexible(child: SingleChildScrollView(child: v.body)),
          ],
        ),
      ),
    );
  }

  ({String title, Widget body}) _view() {
    switch (_step) {
      case 'statusList':
        return (title: _t('changeStatus'), body: _list(
          const ['stInHeat', 'stInsem', 'stPreg', 'stDelivered', 'stCalvInt', 'stMilking', 'stDry'],
          (k) { _status = _t(k); _go('statusNote'); }));
      case 'statusNote':
        return (title: _t('changeStatus'), body: _noteStep(
          '${_t('statusNoteTitle')} — $_status', _t('statusNotePh'), _reason,
          () => _done('${_t('statusChanged')} — $_status')));
      case 'vetPick':
        return (title: _t('pickVet'), body: _list(widget.vets, (name) {
          _vet = name;
          if (_flow == 'visit') { _go('schedule'); }
          else if (_flow == 'vetlog') { _go('vetlogForm'); }
          else if (_flow == 'insem') { _go('insemType'); }
          else { _go('deliveryLog'); } // delYes / delNo
        }, raw: true));
      case 'schedule':
        return (title: _t('schedVisit'), body: _scheduleStep());
      case 'vetlogForm':
        return (title: _t('addVetLog'), body: _vetlogStep());
      case 'heatConfirm':
        return (title: _t('addHeat'), body: _confirmStep(_t('heatQ').replaceAll('{cow}', widget.cowName), () => _go('heatWhen')));
      case 'heatWhen':
        return (title: _t('addHeat'), body: _whenStep(withTime: true, onOk: () => _done(_t('heatConfirmed'))));
      case 'pregConfirm':
        return (title: _t('addPreg'), body: _confirmStep(_t('pregQ').replaceAll('{cow}', widget.cowName), () => _go('pregWhen')));
      case 'pregWhen':
        return (title: _t('addPreg'), body: _whenStep(withTime: false, onOk: () => _done(_t('gest9'))));
      case 'insemType':
        return (title: _t('insemTypeTitle'), body: _list(
          const ['Artificial', 'Conventional', 'IVF', 'Embryo Transfer'],
          (ty) { _insemType = ty; _go('insemLog'); }, raw: true, subtitle: _vet));
      case 'insemLog':
        return (title: _t('logDetails'), body: _insemLogStep());
      case 'deliveryConfirm':
        return (title: _t('addDelivery'), body: _deliveryConfirmStep());
      case 'lossReason':
        return (title: _t('addDelivery'), body: _noteStep(_t('lossReasonTitle'), _t('lossReasonPh'), _reason, () { _flow = 'delNo'; _go('vetPick'); }));
      case 'deliveryLog':
        return (title: _t('logDetails'), body: _deliveryLogStep());
      case 'vaccineType':
        return (title: _t('addVaccination'), body: _list(
          const ['vaccineFmd', 'vaccineHs', 'vaccineBq', 'vaccineBrucellosis'],
          (k) { _vaccineType = _t(k); _go('vaccineLog'); }));
      case 'vaccineLog':
        return (title: _t('addVaccination'), body: _vaccineLogStep());
      case 'done':
        return (title: _t('cowActions'), body: _doneStep());
      case 'main':
      default:
        return (title: _t('cowActions'), body: _mainList());
    }
  }

  // ── shared step widgets ──
  Widget _mainList() {
    final items = <(IconData, String, VoidCallback)>[
      (Icons.sync, _t('changeStatus'), () => _go('statusList')),
      (Icons.medical_services_outlined, _t('reqVetVisit'), () { _flow = 'visit'; _go('vetPick'); }),
      (Icons.description_outlined, _t('addVetLog'), () { _flow = 'vetlog'; _attach = false; _go('vetPick'); }),
      (Icons.favorite_border, _t('addHeat'), () => _go('heatConfirm')),
      (Icons.colorize_outlined, _t('addInsem'), () { _flow = 'insem'; _go('vetPick'); }),
      (Icons.pregnant_woman_outlined, _t('addPreg'), () => _go('pregConfirm')),
      (Icons.child_friendly_outlined, _t('addDelivery'), () => _go('deliveryConfirm')),
      (Icons.vaccines_outlined, _t('addVaccination'), () => _go('vaccineType')),
    ];
    return Column(
      children: [
        for (final it in items)
          InkWell(
            onTap: it.$3,
            borderRadius: BorderRadius.circular(VanixRadius.md),
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsetsDirectional.symmetric(vertical: 6),
              child: Row(children: [
                Icon(it.$1, size: 20, color: VanixColors.greenInk),
                const SizedBox(width: VanixSpacing.md),
                Expanded(child: Text(it.$2, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: _text1))),
                const Icon(Icons.chevron_right, size: 18, color: VanixColors.textHint),
              ]),
            ),
          ),
      ],
    );
  }

  Widget _list(List<String> keys, void Function(String) onTap, {bool raw = false, String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (subtitle != null) Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(subtitle, style: const TextStyle(fontSize: 13, color: VanixColors.textHint))),
        for (final k in keys)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => onTap(k),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                alignment: AlignmentDirectional.centerStart,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(color: _fieldBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: _border)),
                child: Text(raw ? k : _t(k), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _text1)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _label(String txt) => Padding(padding: const EdgeInsets.only(bottom: 6, top: 2), child: Text(txt, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: VanixColors.textHint)));

  Widget _fieldBox({required Widget child}) => Container(
        height: 46, margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(color: _fieldBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: _border)),
        alignment: AlignmentDirectional.centerStart,
        child: child,
      );

  Widget _pickerField(String value, String placeholder, IconData icon, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: _fieldBox(child: Row(children: [
          Expanded(child: Text(value.isEmpty ? placeholder : value, style: TextStyle(fontSize: 14, color: value.isEmpty ? VanixColors.textHint : _text1))),
          Icon(icon, size: 16, color: VanixColors.textHint),
        ])),
      );

  Widget _cta(String label, VoidCallback? onOk) => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(0, 48),
            backgroundColor: VanixColors.greenInk,
            foregroundColor: Colors.white,
            disabledBackgroundColor: VanixColors.greenInk.withValues(alpha: 0.45),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
          onPressed: onOk,
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        ),
      );

  Widget _textArea(TextEditingController c, String ph) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(color: _fieldBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: _border)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: TextField(
          controller: c,
          maxLines: 3,
          onChanged: (_) => setState(() {}),
          style: TextStyle(fontSize: 14, color: _text1),
          decoration: InputDecoration(border: InputBorder.none, hintText: ph, hintStyle: const TextStyle(color: VanixColors.textHint, fontSize: 14)),
        ),
      );

  Widget _confirmStep(String question, VoidCallback onYes) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(bottom: 14), child: Text(question, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _text1))),
      _cta(_t('caYes'), onYes),
      const SizedBox(height: 8),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 46), side: BorderSide(color: _border), foregroundColor: _text1, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(_t('caNo'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ),
      ),
    ]);
  }

  Widget _whenStep({required bool withTime, required VoidCallback onOk}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(widget.cowName, style: const TextStyle(fontSize: 13, color: VanixColors.textHint))),
      _label(_t('eventDate')),
      _pickerField(_date, _t('eventDate'), Icons.calendar_today_outlined, _pickDate),
      if (withTime) ...[
        _label(_t('eventTime')),
        _pickerField(_time, _t('eventTime'), Icons.schedule, _pickTime),
      ],
      const SizedBox(height: 4),
      _cta(_t('caConfirm'), onOk),
    ]);
  }

  Widget _scheduleStep() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(bottom: 12), child: Text('$_vet — ${widget.cowName}', style: const TextStyle(fontSize: 13, color: VanixColors.textHint))),
      _label(_t('eventDate')),
      _pickerField(_date, _t('eventDate'), Icons.calendar_today_outlined, _pickDate),
      _label(_t('eventTime')),
      _pickerField(_time, _t('eventTime'), Icons.schedule, _pickTime),
      const SizedBox(height: 4),
      _cta(_t('caConfirm'), () => _done('${_t('visitScheduled')} — $_vet')),
    ]);
  }

  Widget _noteStep(String prompt, String ph, TextEditingController c, VoidCallback onOk) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(prompt, style: const TextStyle(fontSize: 13, color: VanixColors.textHint))),
      _textArea(c, ph),
      const SizedBox(height: 4),
      _cta(_t('caConfirm'), c.text.trim().isEmpty ? null : onOk),
    ]);
  }

  Widget _vetlogStep() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(bottom: 12), child: Text('$_vet — ${widget.cowName}', style: const TextStyle(fontSize: 13, color: VanixColors.textHint))),
      _label(_t('notesPh')),
      _textArea(_notes, _t('notesPh')),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: _attach ? VanixColors.greenInk : _text1,
            side: BorderSide(color: _attach ? VanixColors.greenInk : _border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => setState(() => _attach = !_attach),
          icon: const Icon(Icons.attach_file, size: 15),
          label: Text(_attach ? '${_t('attached')} · Photo.jpg' : _t('attachFile'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ),
      const SizedBox(height: 10),
      _cta(_t('saveLog'), _notes.text.trim().isEmpty ? null : () {
        widget.onAddVetLog(VetLog(_t('vlCustomT'), _notes.text.trim(), _vet, '16/7/2026', attachment: _attach ? 'Photo.jpg' : null));
        _done(_t('vetLogSaved'));
      }),
    ]);
  }

  Widget _insemLogStep() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(bottom: 12), child: Text('$_vet · $_insemType — ${widget.cowName}', style: const TextStyle(fontSize: 13, color: VanixColors.textHint))),
      _label(_t('eventDate')),
      _pickerField(_date, _t('eventDate'), Icons.calendar_today_outlined, _pickDate),
      _label(_t('eventTime')),
      _pickerField(_time, _t('eventTime'), Icons.schedule, _pickTime),
      _label(_t('notesPh')),
      _textArea(_notes, _t('notesPh')),
      const SizedBox(height: 4),
      _cta(_t('saveLog'), () => _done(_t('obs21'))),
    ]);
  }

  Widget _deliveryConfirmStep() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(bottom: 14), child: Text(_t('deliveryQ'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _text1))),
      _cta(_t('caYes'), () { _flow = 'delYes'; _go('vetPick'); }),
      const SizedBox(height: 8),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 46), side: BorderSide(color: _border), foregroundColor: _text1, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
          onPressed: () { _flow = 'delNo'; _reason.clear(); _go('lossReason'); },
          child: Text(_t('caNo'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ),
      ),
    ]);
  }

  Widget _deliveryLogStep() {
    final ok = _flow == 'delYes';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(bottom: 12), child: Text('$_vet — ${widget.cowName}', style: const TextStyle(fontSize: 13, color: VanixColors.textHint))),
      _label(_t('eventDate')),
      _pickerField(_date, _t('eventDate'), Icons.calendar_today_outlined, _pickDate),
      _label(_t('notesPh')),
      _textArea(_notes, _t('notesPh')),
      const SizedBox(height: 4),
      _cta(_t('saveLog'), () => _done(ok ? _t('deliveryLogged') : _t('lossLogged'))),
    ]);
  }

  Widget _vaccineLogStep() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(bottom: 12), child: Text('$_vaccineType — ${widget.cowName}', style: const TextStyle(fontSize: 13, color: VanixColors.textHint))),
      _label(_t('eventDate')),
      _pickerField(_date, _t('eventDate'), Icons.calendar_today_outlined, _pickDate),
      _label(_t('notesOptional')),
      _textArea(_notes, _t('notesOptional')),
      const SizedBox(height: 4),
      _cta(_t('saveLog'), () => _done(_t('vaccinationLogged'))),
    ]);
  }

  Widget _doneStep() {
    return Column(children: [
      const SizedBox(height: 8),
      Container(
        width: 56, height: 56,
        decoration: const BoxDecoration(color: VanixColors.activeBg, shape: BoxShape.circle),
        child: const Icon(Icons.check, color: VanixColors.greenInk, size: 26),
      ),
      const SizedBox(height: 14),
      Text(_doneMsg, textAlign: TextAlign.center, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.5, color: _text1)),
      const SizedBox(height: 16),
      _cta(_t('caDone'), () => Navigator.of(context).pop()),
    ]);
  }
}

// ── Dotted vertical line for the timeline rail ──────────────────────────
class _DottedLine extends StatelessWidget {
  final Color color;
  const _DottedLine({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 12,
      child: Center(
        child: CustomPaint(size: const Size(2, double.infinity), painter: _DottedPainter(color)),
      ),
    );
  }
}

class _DottedPainter extends CustomPainter {
  final Color color;
  _DottedPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const dash = 3.0, gap = 4.0;
    double y = 0;
    final x = size.width / 2;
    while (y < size.height) {
      canvas.drawLine(Offset(x, y), Offset(x, (y + dash).clamp(0, size.height)), paint);
      y += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DottedPainter oldDelegate) => oldDelegate.color != color;
}

// ── Weekly milk line graph — green area fill + optional single peak dot ──
class _WeeklyPainter extends CustomPainter {
  final List<double> values;
  final bool isDark;
  final int? peakIndex; // when set, only this point gets a dot
  _WeeklyPainter({required this.values, required this.isDark, this.peakIndex});

  @override
  void paint(Canvas canvas, Size size) {
    const lineColor = VanixColors.greenInk;
    final max = values.reduce((a, b) => a > b ? a : b);
    final min = values.reduce((a, b) => a < b ? a : b);
    final range = (max - min) == 0 ? 1.0 : (max - min);
    final chartHeight = size.height;

    // single baseline
    canvas.drawLine(
      Offset(0, chartHeight / 2),
      Offset(size.width, chartHeight / 2),
      Paint()..color = (isDark ? VanixColors.darkDivider : VanixColors.divider)..strokeWidth = 1,
    );

    Offset pointAt(int i) {
      final x = values.length == 1 ? 0.0 : size.width / (values.length - 1) * i;
      final y = chartHeight - ((values[i] - min) / range) * (chartHeight - 10) - 5;
      return Offset(x, y);
    }

    final path = Path();
    final fillPath = Path()..moveTo(0, chartHeight);
    for (var i = 0; i < values.length; i++) {
      final p = pointAt(i);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(size.width, chartHeight);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [VanixColors.greenDeep.withValues(alpha: 0.28), VanixColors.greenDeep.withValues(alpha: 0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, chartHeight)),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..strokeWidth = 1.3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    if (peakIndex != null) {
      final p = pointAt(peakIndex!);
      canvas.drawCircle(p, 2.6, Paint()..color = VanixColors.greenDeep);
      canvas.drawCircle(p, 2.6, Paint()..color = (isDark ? VanixColors.darkSecond : Colors.white)..style = PaintingStyle.stroke..strokeWidth = 1);
    } else {
      for (var i = 0; i < values.length; i++) {
        final p = pointAt(i);
        canvas.drawCircle(p, 2.2, Paint()..color = lineColor);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WeeklyPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.isDark != isDark || oldDelegate.peakIndex != peakIndex;
}

// ── 24-hour temperature line — green→orange→red gradient + 39°C guide ────
class _TempPainter extends CustomPainter {
  final bool isDark;
  final List<double> values;
  _TempPainter({required this.isDark, List<double>? values}) : values = values ?? _defaultTemps;

  static const List<double> _defaultTemps = [30, 30, 29.5, 30, 30.5, 30, 32.5, 31.5, 31, 34, 32.5, 32, 35];
  static const double _lo = 20, _hi = 40;

  @override
  void paint(Canvas canvas, Size size) {
    final temps = values;
    double yFor(double v) => size.height - ((v - _lo) / (_hi - _lo)) * size.height;

    // fever threshold guide at 39°C
    final guideY = yFor(39);
    final guidePaint = Paint()
      ..color = VanixColors.danger.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 6) {
      canvas.drawLine(Offset(x, guideY), Offset(x + 3, guideY), guidePaint);
    }

    final path = Path();
    for (var i = 0; i < temps.length; i++) {
      final x = size.width / (temps.length - 1) * i;
      final y = yFor(temps[i]);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [VanixColors.greenDeep, VanixColors.warning, VanixColors.danger],
          stops: [0.0, 0.5, 0.8],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _TempPainter oldDelegate) => oldDelegate.isDark != isDark || oldDelegate.values != values;
}
