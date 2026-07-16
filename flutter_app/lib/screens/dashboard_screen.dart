import 'package:flutter/material.dart';
import '../i18n/farm_strings.dart';
import '../i18n/strings.dart';
import '../state/app_state.dart';
import '../theme/vanix_theme.dart';
import '../widgets/vanix_bottom_nav.dart';
import '../widgets/vanix_nav_items.dart';
import 'milk_log_screen.dart';
import 'events_screen.dart';
import 'farms_screen.dart';
import 'account_screen.dart';

/// Home dashboard — Screen 03. Mirrors #s1-dash in prototype.html: greeting
/// header (bell + avatar), All-Farms selector + live collars, 2x2 stat cards,
/// Action Alerts with per-farm breakdown + inline triage, edits/milk-missing
/// cards, insemination-window timer, farms-needing-action, today's schedule,
/// this-week, and good-news — over the shared bottom nav.
class DashboardScreen extends StatefulWidget {
  final AppState appState;
  const DashboardScreen({super.key, required this.appState});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _navIndex = 0;
  bool _triaged = false;
  String _schTab = 'today';

  String get _lang => widget.appState.languageCode;
  bool get _isDark => widget.appState.isDark;

  void _onNavTap(int i) {
    if (i == 1) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => FarmsScreen(appState: widget.appState))).then((_) => setState(() {}));
      return;
    }
    if (i == 2) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => MilkLogScreen(appState: widget.appState))).then((_) => setState(() {}));
      return;
    }
    if (i == 3) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => EventsScreen(appState: widget.appState))).then((_) => setState(() {}));
      return;
    }
    if (i == 4) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => AccountScreen(appState: widget.appState))).then((_) => setState(() {}));
      return;
    }
    setState(() => _navIndex = i);
  }

  Color get _cardBg => _isDark ? VanixColors.darkSecond : VanixColors.bgCard;
  Color get _text1 => _isDark ? Colors.white : VanixColors.textPrimary;
  Color get _border => _isDark ? VanixColors.darkBorder : VanixColors.border;
  Color get _divider => _isDark ? VanixColors.darkDivider : VanixColors.divider;
  List<BoxShadow> get _shadow => _isDark ? VanixShadow.cardDark : VanixShadow.card;

  String _t(String k) => FS.t(_lang, k);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        final t = VanixStrings.of(_lang);
        final theme = _isDark ? vanixDarkTheme(languageCode: _lang) : vanixLightTheme(languageCode: _lang);
        return Theme(
          data: theme,
          child: Scaffold(
            body: Stack(
              children: [
                Positioned.fill(
                  child: SafeArea(
                    bottom: false,
                    child: ListView(
                      padding: const EdgeInsetsDirectional.only(bottom: 128),
                      children: [
                        _header(),
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 0),
                          child: _statGrid(),
                        ),
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(16, 20, 16, 0),
                          child: _scheduleTabs(),
                        ),
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 0),
                          child: _twoCards(),
                        ),
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 0),
                          child: _insemTimer(),
                        ),
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(16, 20, 16, 0),
                          child: _farmsNeedingAction(),
                        ),
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(16, 20, 16, 0),
                          child: _updates(),
                        ),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: VanixBottomNav(
                    isDark: _isDark,
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

  // ── Card shell ──
  BoxDecoration _cardDeco() => BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(18), boxShadow: _shadow);

  TextStyle get _secLbl => const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: VanixColors.textHint);

  // ── Header (no bell/avatar — profile is in the bottom nav) ──
  Widget _header() {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 22, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_t('dashGreeting').toUpperCase(),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: VanixColors.textHint)),
          const SizedBox(height: 3),
          Text('James', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 1.15, color: _text1)),
          const SizedBox(height: 3),
          const Text('Thursday, 16 July', style: TextStyle(fontSize: 13, color: VanixColors.textHint)),
          const SizedBox(height: 16),
          Row(
            children: [
              Flexible(
                child: Container(
                  height: 38,
                  padding: const EdgeInsetsDirectional.symmetric(horizontal: 14),
                  decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(19), border: Border.all(color: _border)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.home_outlined, size: 15, color: _text1),
                    const SizedBox(width: 8),
                    Flexible(child: Text('${_t('dashAllFarms')} (3)', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _text1))),
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down, size: 16, color: _text1),
                  ]),
                ),
              ),
              const SizedBox(width: 10),
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.bar_chart, size: 15, color: VanixColors.greenInk),
                const SizedBox(width: 5),
                Text('${_t('dashLive')} · 74/77', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: VanixColors.greenInk)),
              ]),
            ],
          ),
        ],
      ),
    );
  }

  // ── Stat grid (2x2) ──
  Widget _statGrid() {
    return Column(children: [
      Row(children: [
        Expanded(child: _statCard('77', 'statTotalCattle', _subGreen('+3 ', 'dashAddedToday'))),
        const SizedBox(width: 12),
        Expanded(child: _statCard('14', 'statUnactionedAlerts', _subColor('2 ', 'criticalWord', VanixColors.danger), onInfo: _openAlertsSheet)),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _statCard('8', 'dashPendingTasks', _subMuted('5 ', 'dashDueToday', ' · 3 ', 'dashOverdue'))),
        const SizedBox(width: 12),
        Expanded(child: _statCard('2', 'dashPregnant', _subMuted('1 ', 'dashDueThisWeek', '', null))),
      ]),
    ]);
  }

  Widget _statCard(String num, String labelKey, Widget sub, {VoidCallback? onInfo}) {
    final card = Container(
      decoration: _cardDeco(),
      padding: const EdgeInsets.fromLTRB(14, 15, 14, 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(num, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, height: 1, color: _text1)),
          const SizedBox(height: 9),
          Text(_t(labelKey), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _text1)),
          const SizedBox(height: 3),
          sub,
        ],
      ),
    );
    if (onInfo == null) return card;
    return Stack(
      children: [
        card,
        PositionedDirectional(
          top: 6, end: 6,
          child: IconButton(
            iconSize: 18,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            onPressed: onInfo,
            icon: const Icon(Icons.info_outline, color: VanixColors.textHint),
          ),
        ),
      ],
    );
  }

  Widget _subGreen(String prefix, String key) => Text('$prefix${_t(key)}',
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: VanixColors.greenInk));
  Widget _subColor(String prefix, String key, Color c) => Text('$prefix${_t(key)}',
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c));
  Widget _subMuted(String p1, String k1, String p2, String? k2) => Text(
      '$p1${_t(k1)}$p2${k2 != null ? _t(k2) : ''}',
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: VanixColors.textHint));

  // ── Unactioned Alerts detail sheet (opened by the stat-card info button) ──
  void _openAlertsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _isDark ? VanixColors.darkSecond : VanixColors.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheet) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 8), decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2)))),
                  Row(children: [
                    Expanded(child: Text(_t('statUnactionedAlerts'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _text1))),
                    IconButton(onPressed: () => Navigator.of(sheetCtx).pop(), icon: Icon(Icons.close, color: _text1)),
                  ]),
                  Row(children: [
                    Text('14', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _text1)),
                    Text('  · 2 ${_t('criticalWord')}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: VanixColors.danger)),
                  ]),
                  _hr(),
                  _farmAlertRow('Sunrise Dairy', crit: '9  · 2 ${_t('criticalWord')}'),
                  const SizedBox(height: 9),
                  _farmAlertRow('Green Villa', plain: '3'),
                  const SizedBox(height: 9),
                  _farmAlertRow('Stones Dairy', plain: '2'),
                  _hr(),
                  if (_triaged)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text('✓ ${_t('dashTriageDone')}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: VanixColors.greenInk)),
                    )
                  else
                    _triageBlock(onDone: () { setState(() => _triaged = true); setSheet(() {}); }),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        backgroundColor: VanixColors.greenInk,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      onPressed: () { Navigator.of(sheetCtx).pop(); _onNavTap(3); },
                      child: Text('${_t('dashViewEvents')}  →', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _hr() => Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Container(height: 1, color: _divider));

  Widget _farmAlertRow(String name, {String? crit, String? plain}) {
    return Row(
      children: [
        Expanded(child: Text(name, style: TextStyle(fontSize: 14, color: _text1))),
        const SizedBox(width: 8),
        crit != null
            ? Text(crit, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: VanixColors.danger))
            : Text(plain!, style: const TextStyle(fontSize: 14, color: VanixColors.textHint)),
      ],
    );
  }

  Widget _triageBlock({required VoidCallback onDone}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: RichText(
                text: TextSpan(children: [
                  TextSpan(text: 'Is Kajri unwell? ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _text1)),
                  const TextSpan(text: '— Sunrise', style: TextStyle(fontSize: 14, color: VanixColors.textHint)),
                ]),
              ),
            ),
            Text('2h ${_t('dashWaiting')}', style: const TextStyle(fontSize: 12, color: VanixColors.textHint)),
          ],
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 40),
                side: BorderSide(color: _border),
                foregroundColor: _text1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: onDone,
              child: Text(_t('noWord'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 40),
                backgroundColor: VanixColors.greenInk,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: onDone,
              child: Text(_t('dashYesFever'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ),
        ]),
      ],
    );
  }

  // ── Two half cards ──
  Widget _twoCards() {
    return Row(children: [
      Expanded(child: _miniCard('2', 'dashEditsApproval', _text1)),
      const SizedBox(width: 12),
      Expanded(child: _miniCard('3', 'dashMilkMissing', VanixColors.warning)),
    ]);
  }

  Widget _miniCard(String num, String key, Color numColor) {
    return Container(
      decoration: _cardDeco(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(num, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: numColor)),
          const SizedBox(height: 6),
          Text(_t(key), style: TextStyle(fontSize: 13, height: 1.35, color: _text1)),
        ],
      ),
    );
  }

  // ── Insemination timer ──
  Widget _insemTimer() {
    return Container(
      decoration: _cardDeco(),
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(color: VanixColors.activeBg, borderRadius: BorderRadius.circular(11)),
          child: const Icon(Icons.schedule, size: 19, color: VanixColors.greenInk),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(children: [
              TextSpan(text: 'Gauri ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _text1)),
              TextSpan(text: '— ${_t('dashInsemWindow')}', style: const TextStyle(fontSize: 14, color: VanixColors.textHint)),
            ]),
          ),
        ),
        Text('9h ${_t('dashLeft')}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: VanixColors.greenInk)),
      ]),
    );
  }

  // ── Farms needing action ──
  Widget _farmsNeedingAction() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_t('dashFarmsNeedAction').toUpperCase(), style: _secLbl),
        const SizedBox(height: 10),
        InkWell(
          onTap: () => _onNavTap(1),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: _cardDeco(),
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text('Sunrise Dairy', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _text1)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: VanixColors.danger, borderRadius: BorderRadius.circular(8)),
                        child: Text(_t('sevCritical'), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: Colors.white)),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    Text('1 ${_t('cattleFever')} · 2 ${_t('cattleHeat')} · collar 3 ${_t('dashOffline')}',
                        style: const TextStyle(fontSize: 13, color: VanixColors.textHint)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 20, color: VanixColors.textHint),
            ]),
          ),
        ),
      ],
    );
  }

  // ── Schedule with Today / This week tabs ──
  Widget _scheduleTabs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          _schTabBtn('today', 'dashToday'),
          const SizedBox(width: 8),
          _schTabBtn('week', 'dashThisWeek'),
        ]),
        const SizedBox(height: 12),
        if (_schTab == 'today')
          Container(
            decoration: _cardDeco(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(children: [
              _scheduleRow('11:00 AM', 'dashVaccDrive', sub: 'dashStartsIn', barColor: VanixColors.greenDeep, divider: true),
              _scheduleRow('4:30 PM', 'dashVetVisit', barColor: _border, divider: true),
              _scheduleRow('6:00 PM', 'dashMilkLogging', barColor: _border, divider: false),
            ]),
          )
        else
          Container(
            decoration: _cardDeco(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: RichText(
                        text: TextSpan(children: [
                          TextSpan(text: _t('dashFmd'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _text1)),
                          TextSpan(text: ' — 5 ${_t('dashCows')}, Green Villa', style: const TextStyle(fontSize: 14, color: VanixColors.textHint)),
                        ]),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text('5d', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: VanixColors.warning)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(_t('dashRemindersNote'), style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: VanixColors.textHint)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _schTabBtn(String tab, String labelKey) {
    final on = _schTab == tab;
    return InkWell(
      onTap: () => setState(() => _schTab = tab),
      borderRadius: BorderRadius.circular(17),
      child: Container(
        constraints: const BoxConstraints(minHeight: 34),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? VanixColors.greenInk : _cardBg,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: on ? VanixColors.greenInk : _border),
        ),
        child: Text(_t(labelKey),
            style: TextStyle(fontSize: 13, fontWeight: on ? FontWeight.w600 : FontWeight.w500, color: on ? Colors.white : _text1)),
      ),
    );
  }

  Widget _scheduleRow(String time, String titleKey, {String? sub, required Color barColor, required bool divider}) {
    return Container(
      decoration: BoxDecoration(
        border: divider ? Border(bottom: BorderSide(color: _divider)) : null,
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: IntrinsicHeight(
        child: Row(children: [
          SizedBox(width: 64, child: Text(time, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _text1))),
          const SizedBox(width: 14),
          Container(width: 3, decoration: BoxDecoration(color: barColor, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_t(titleKey), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _text1)),
                if (sub != null) ...[
                  const SizedBox(height: 2),
                  Text(_t(sub), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: VanixColors.greenInk)),
                ],
              ],
            ),
          ),
        ]),
      ),
    );
  }

  // ── Updates (icon-less: event · details · time) ──
  Widget _updates() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_t('dashUpdates').toUpperCase(), style: _secLbl),
        const SizedBox(height: 10),
        Container(
          decoration: _cardDeco(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: [
            _updateRow('Bhoori — ${_t('dashRecovered')}', _t('dashFeverCaught'), '2d', divider: true),
            _updateRow('Mohini — ${_t('dashConfPreg')}', '${_t('dashInseminated')} 18 Sep', _t('dashYesterday'), divider: true),
            _updateRow('Ganga — ${_t('dashCalved')}', _t('dashHealthyCalf'), '05:40', divider: false),
          ]),
        ),
      ],
    );
  }

  Widget _updateRow(String event, String details, String time, {required bool divider}) {
    return Container(
      decoration: BoxDecoration(border: divider ? Border(bottom: BorderSide(color: _divider)) : null),
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _text1)),
                const SizedBox(height: 3),
                Text(details, style: const TextStyle(fontSize: 12, height: 1.4, color: VanixColors.textHint)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(time, style: const TextStyle(fontSize: 11, color: VanixColors.textHint)),
        ],
      ),
    );
  }
}
