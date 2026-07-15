import 'package:flutter/material.dart';
import '../i18n/farm_strings.dart';
import '../models/farm_models.dart';
import '../state/app_state.dart';
import '../theme/vanix_theme.dart';

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

  static const List<double> _weekly = [10, 12, 11, 13, 12, 12.5, 11.5];

  String get _lang => widget.appState.languageCode;
  bool get _isDark => widget.appState.isDark;

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

  // ── Hero ──────────────────────────────────────────────────────────────
  Widget _buildHero() {
    final textColor = _isDark ? Colors.white : VanixColors.textPrimary;
    final surface = _isDark ? VanixColors.darkSecond : VanixColors.bgCard;
    final st = _statusStyle();

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(VanixRadius.lg)),
        boxShadow: _isDark ? VanixShadow.cardDark : VanixShadow.card,
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(VanixSpacing.lg, 20, VanixSpacing.lg, VanixSpacing.lg),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _circleBtn(Icons.chevron_left, () => Navigator.of(context).pop()),
                const SizedBox(width: VanixSpacing.sm),
                _cowPhoto(),
                const SizedBox(width: VanixSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(widget.cow.nm(_lang),
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textColor), overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: VanixSpacing.sm),
                          _beltChip(),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(widget.cow.br(_lang), style: TextStyle(fontSize: 14, color: _isDark ? VanixColors.textOnDarkDim : VanixColors.textPrimary)),
                      Text(widget.cow.ag(_lang), style: const TextStyle(fontSize: 13, color: VanixColors.textHint)),
                    ],
                  ),
                ),
                _kebab(),
              ],
            ),
            const SizedBox(height: VanixSpacing.lg),
            Row(
              children: [
                Expanded(child: _statusTile(st)),
                const SizedBox(width: VanixSpacing.sm),
                Expanded(child: _tempTile()),
              ],
            ),
            const SizedBox(height: VanixSpacing.lg),
            _buildTabBar(),
          ],
        ),
      ),
    );
  }

  Widget _cowPhoto() {
    final placeholder = Container(
      width: 64, height: 64,
      color: _isDark ? VanixColors.darkSubSurface : VanixColors.bgWarm,
      alignment: Alignment.center,
      child: const Text('🐄', style: TextStyle(fontSize: 26)),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(VanixRadius.md),
      child: widget.cow.photo == null
          ? placeholder
          : Image.asset(widget.cow.photo!, width: 64, height: 64, fit: BoxFit.cover, errorBuilder: (_, __, ___) => placeholder),
    );
  }

  Widget _beltChip() {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _isDark ? VanixColors.darkSubSurface : VanixColors.bgWarm,
        border: Border.all(color: _isDark ? VanixColors.darkBorder : VanixColors.border),
        borderRadius: BorderRadius.circular(VanixRadius.sm),
      ),
      child: Text(widget.cow.bl(_lang), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _isDark ? Colors.white : VanixColors.textPrimary)),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 44, height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _isDark ? VanixColors.darkBorder : VanixColors.border),
        ),
        child: Icon(icon, size: 22, color: _isDark ? Colors.white : VanixColors.textPrimary),
      ),
    );
  }

  Widget _kebab() {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: _isDark ? Colors.white : VanixColors.textPrimary),
      onSelected: (v) => _snack('${_actionVerb(v)}…'),
      itemBuilder: (context) => [
        PopupMenuItem(value: 'edit', child: Text(FS.t(_lang, 'editWord'))),
        PopupMenuItem(value: 'delete', child: Text(FS.t(_lang, 'deleteWord'))),
        PopupMenuItem(value: 'group', child: Text(FS.t(_lang, 'addToGroup'))),
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

  Widget _statusTile(({String key, Color bg, Color ink}) st) {
    final tileBg = _isDark ? VanixColors.darkSubSurface : VanixColors.bgWarm;
    return Container(
      padding: const EdgeInsets.all(VanixSpacing.md),
      decoration: BoxDecoration(
        color: tileBg,
        border: Border.all(color: _isDark ? VanixColors.darkBorder : VanixColors.border),
        borderRadius: BorderRadius.circular(VanixRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: VanixColors.textHint)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: st.bg, borderRadius: BorderRadius.circular(VanixRadius.pill)),
            child: Text(FS.t(_lang, st.key), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: st.ink)),
          ),
        ],
      ),
    );
  }

  Widget _tempTile() {
    final tileBg = _isDark ? VanixColors.darkSubSurface : VanixColors.bgWarm;
    final textColor = _isDark ? Colors.white : VanixColors.textPrimary;
    return Container(
      padding: const EdgeInsets.all(VanixSpacing.md),
      decoration: BoxDecoration(
        color: tileBg,
        border: Border.all(color: _isDark ? VanixColors.darkBorder : VanixColors.border),
        borderRadius: BorderRadius.circular(VanixRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(FS.t(_lang, 'currentTemp').toUpperCase(),
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: VanixColors.textHint)),
          const SizedBox(height: 6),
          Text(widget.cow.temp, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor)),
        ],
      ),
    );
  }

  // ── Tab bar ───────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    final trackBg = _isDark ? VanixColors.darkSubSurface : VanixColors.bgWarm;
    final labels = ['tabTimeline', 'tabOverview', 'tabVetLogs'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: trackBg, borderRadius: BorderRadius.circular(VanixRadius.pill)),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _tab = i),
                borderRadius: BorderRadius.circular(VanixRadius.pill),
                child: Container(
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _tab == i ? VanixColors.greenInk : Colors.transparent,
                    borderRadius: BorderRadius.circular(VanixRadius.pill),
                  ),
                  child: Text(
                    FS.t(_lang, labels[i]),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _tab == i ? Colors.white : (_isDark ? VanixColors.textOnDarkDim : VanixColors.textPrimary),
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
        return _buildVetLogs();
      case 0:
      default:
        return _buildTimeline();
    }
  }

  // ── Timeline tab ──────────────────────────────────────────────────────
  Widget _buildTimeline() {
    final sheetBg = _isDark ? VanixColors.darkSecond : VanixColors.bgCard;
    final textColor = _isDark ? Colors.white : VanixColors.textPrimary;
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
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // dotted rail
                  Column(
                    children: [
                      Container(width: 12, height: 12, decoration: BoxDecoration(color: _timeline[i].dot, shape: BoxShape.circle)),
                      if (i != _timeline.length - 1)
                        Expanded(child: _DottedLine(color: _isDark ? VanixColors.darkBorder : VanixColors.border)),
                    ],
                  ),
                  const SizedBox(width: VanixSpacing.md),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: VanixSpacing.md),
                      child: InkWell(
                        onTap: () => _openTlDetail(_timeline[i]),
                        borderRadius: BorderRadius.circular(VanixRadius.md),
                        child: Container(
                          padding: const EdgeInsets.all(VanixSpacing.md),
                          decoration: BoxDecoration(
                            color: _isDark ? VanixColors.darkSubSurface : VanixColors.bgCard,
                            borderRadius: BorderRadius.circular(VanixRadius.md),
                            border: Border.all(color: _isDark ? VanixColors.darkBorder : VanixColors.border, width: 0.5),
                            boxShadow: _isDark ? VanixShadow.cardDark : VanixShadow.card,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(FS.t(_lang, _timeline[i].key),
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
                                    const SizedBox(height: 2),
                                    Text(_timeline[i].date, style: const TextStyle(fontSize: 12, color: VanixColors.textHint)),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right, size: 18, color: VanixColors.textHint),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _openTlDetail(TimelineEvent ev) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final bg = _isDark ? VanixColors.darkSecond : Colors.white;
        final textColor = _isDark ? Colors.white : VanixColors.textPrimary;
        return Container(
          decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(VanixRadius.pill))),
          padding: const EdgeInsets.fromLTRB(VanixSpacing.xl, VanixSpacing.xl, VanixSpacing.xl, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(width: 12, height: 12, decoration: BoxDecoration(color: ev.dot, shape: BoxShape.circle)),
                  const SizedBox(width: VanixSpacing.sm),
                  Expanded(
                    child: Text(FS.t(_lang, ev.key), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: textColor)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(ev.date, style: const TextStyle(fontSize: 12, color: VanixColors.textHint)),
              const SizedBox(height: VanixSpacing.md),
              Text(FS.t(_lang, '${ev.key}D'),
                  style: TextStyle(fontSize: 15, height: 1.6, color: _isDark ? VanixColors.textOnDarkDim : VanixColors.textPrimary)),
            ],
          ),
        );
      },
    );
  }

  // ── Overview tab ──────────────────────────────────────────────────────
  Widget _buildOverview() {
    final textColor = _isDark ? Colors.white : VanixColors.textPrimary;
    final cardBg = _isDark ? VanixColors.darkSecond : VanixColors.bgCard;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(VanixSpacing.lg),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(VanixRadius.lg),
            border: Border.all(color: _isDark ? VanixColors.darkBorder : VanixColors.border, width: 0.5),
            boxShadow: _isDark ? VanixShadow.cardDark : VanixShadow.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(FS.t(_lang, 'wkMilkTitle'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
              const SizedBox(height: VanixSpacing.md),
              SizedBox(
                height: 140,
                width: double.infinity,
                child: CustomPaint(painter: _WeeklyPainter(values: _weekly, isDark: _isDark)),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final d in const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'])
                    Text(d, style: const TextStyle(fontSize: 10, color: VanixColors.textHint)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: VanixSpacing.md),
        Row(
          children: [
            Expanded(child: _overviewTile('avgYield', '11.7 L')),
            const SizedBox(width: VanixSpacing.sm),
            Expanded(child: _overviewTile('lactationDay', '45')),
          ],
        ),
        const SizedBox(height: VanixSpacing.sm),
        Row(
          children: [
            Expanded(child: _overviewTile('avgTempLabel', '32.1°C')),
            const SizedBox(width: VanixSpacing.sm),
            Expanded(child: _overviewTile('heatCycles', '3')),
          ],
        ),
      ],
    );
  }

  Widget _overviewTile(String labelKey, String value) {
    final textColor = _isDark ? Colors.white : VanixColors.textPrimary;
    return Container(
      padding: const EdgeInsets.all(VanixSpacing.md),
      decoration: BoxDecoration(
        color: _isDark ? VanixColors.darkSecond : VanixColors.bgCard,
        border: Border.all(color: _isDark ? VanixColors.darkBorder : VanixColors.border),
        borderRadius: BorderRadius.circular(VanixRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(FS.t(_lang, labelKey), style: const TextStyle(fontSize: 11, color: VanixColors.textHint)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor)),
        ],
      ),
    );
  }

  // ── Vet Logs tab ──────────────────────────────────────────────────────
  Widget _buildVetLogs() {
    final textColor = _isDark ? Colors.white : VanixColors.textPrimary;
    return Column(
      children: [
        for (final log in _vetLogs)
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
      builder: (context) => _ActionsSheet(
        isDark: _isDark,
        lang: _lang,
        onAction: (label) {
          Navigator.pop(context);
          _snack('$label…');
        },
      ),
    );
  }

  void _snack(String msg) {
    if (!mounted) return;
    // TODO: route to the matching Events alert-card flow (Heat / Insemination /
    // Pregnancy / vet request) — cross-screen navigation deferred.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${FS.t(_lang, 'cowActions')}: $msg'), duration: const Duration(seconds: 1)),
    );
  }
}

// ── Actions bottom sheet (two views: main list → status list) ───────────
class _ActionsSheet extends StatefulWidget {
  final bool isDark;
  final String lang;
  final void Function(String label) onAction;
  const _ActionsSheet({required this.isDark, required this.lang, required this.onAction});

  @override
  State<_ActionsSheet> createState() => _ActionsSheetState();
}

class _ActionsSheetState extends State<_ActionsSheet> {
  bool _statusView = false;

  static const _statusKeys = ['stInHeat', 'stInsem', 'stPreg', 'stDelivered', 'stCalvInt', 'stMilking', 'stDry'];

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? VanixColors.darkSecond : Colors.white;
    final textColor = widget.isDark ? Colors.white : VanixColors.textPrimary;
    final lang = widget.lang;
    return Container(
      decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(VanixRadius.pill))),
      padding: const EdgeInsets.fromLTRB(VanixSpacing.xl, VanixSpacing.lg, VanixSpacing.xl, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(width: 40, height: 4, decoration: BoxDecoration(color: VanixColors.greenDeep, borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: VanixSpacing.lg),
          Row(
            children: [
              if (_statusView)
                InkWell(
                  onTap: () => setState(() => _statusView = false),
                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.chevron_left, color: textColor),
                  ),
                ),
              Text(FS.t(lang, _statusView ? 'changeStatus' : 'cowActions'),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor)),
            ],
          ),
          const SizedBox(height: VanixSpacing.md),
          if (!_statusView) ...[
            _row(Icons.sync, FS.t(lang, 'changeStatus'), () => setState(() => _statusView = true), trailing: Icons.chevron_right),
            _row(Icons.medical_services_outlined, FS.t(lang, 'reqVetVisit'), () => widget.onAction(FS.t(lang, 'reqVetVisit'))),
            _row(Icons.favorite_border, FS.t(lang, 'addHeat'), () => widget.onAction(FS.t(lang, 'addHeat'))),
            _row(Icons.colorize_outlined, FS.t(lang, 'addInsem'), () => widget.onAction(FS.t(lang, 'addInsem'))),
            _row(Icons.pregnant_woman_outlined, FS.t(lang, 'addPreg'), () => widget.onAction(FS.t(lang, 'addPreg'))),
          ] else ...[
            for (final k in _statusKeys) _row(Icons.circle_outlined, FS.t(lang, k), () => widget.onAction(FS.t(lang, k))),
          ],
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, VoidCallback onTap, {IconData? trailing}) {
    final textColor = widget.isDark ? Colors.white : VanixColors.textPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(VanixRadius.md),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsetsDirectional.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 20, color: VanixColors.greenInk),
            const SizedBox(width: VanixSpacing.md),
            Expanded(child: Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textColor))),
            if (trailing != null) Icon(trailing, size: 18, color: VanixColors.textHint),
          ],
        ),
      ),
    );
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

// ── Weekly milk line graph ──────────────────────────────────────────────
class _WeeklyPainter extends CustomPainter {
  final List<double> values;
  final bool isDark;
  _WeeklyPainter({required this.values, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final lineColor = isDark ? VanixColors.greenDeep : VanixColors.greenInk;
    final gridColor = (isDark ? Colors.white : Colors.black).withOpacity(0.08);
    final max = values.reduce((a, b) => a > b ? a : b);
    final min = values.reduce((a, b) => a < b ? a : b);
    final range = (max - min) == 0 ? 1.0 : (max - min);
    final chartHeight = size.height;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = chartHeight / 3 * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    Offset pointAt(int i) {
      final x = values.length == 1 ? 0.0 : size.width / (values.length - 1) * i;
      final y = chartHeight - ((values[i] - min) / range) * (chartHeight - 8) - 4;
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

    canvas.drawPath(fillPath, Paint()..color = lineColor.withOpacity(0.10)..style = PaintingStyle.fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    for (var i = 0; i < values.length; i++) {
      final p = pointAt(i);
      canvas.drawCircle(p, 3, Paint()..color = lineColor);
      canvas.drawCircle(p, 3, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.5);
    }
  }

  @override
  bool shouldRepaint(covariant _WeeklyPainter oldDelegate) => oldDelegate.values != values || oldDelegate.isDark != isDark;
}
