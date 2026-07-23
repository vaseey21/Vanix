import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../i18n/farm_strings.dart';
import '../i18n/strings.dart';
import '../models/farm_models.dart';
import '../state/app_state.dart';
import '../theme/vanix_theme.dart';
import '../widgets/vanix_bottom_nav.dart';
import '../widgets/vanix_nav_items.dart';
import 'milk_log_screen.dart';
import 'events_screen.dart';
import 'farms_screen.dart';
import 'farm_detail_screen.dart';
import 'account_screen.dart';
import 'approvals_screen.dart';

/// Home dashboard — Screen 03 (Farm Owner). Mirrors #s1-dash /
/// #dash-scroll in vanix_screens_preview.html (Home r3): header (logo +
/// farm selector), a "Farm Status" section with 3 compact stat cards
/// (Total Cattle / Cows Pregnant / Cows in Heat), a Today/This-week tab
/// row (now a purely visual toggle — both tabs show the same list) above
/// a "Needs Attention" section with 3 tappable "View All" rows (Pending
/// Approvals → [ApprovalsScreen], Milking Sessions Missed → Milk Log,
/// Critical Alerts → Events), a horizontal "Cows in heat" row (tapping a
/// card opens the same full-screen heat-alert carousel + walkthrough as
/// Events' "View full cycle"), a horizontal "Cows in gestation" row
/// (tapping a card opens the walkthrough sheet directly at its gestation
/// step), and an icon-less Updates list.
class DashboardScreen extends StatefulWidget {
  final AppState appState;
  const DashboardScreen({super.key, required this.appState});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _navIndex = 0;
  String _schTab = 'today';
  // Farm selector — 'all' or a FarmModel.id; label updates on selection.
  String _farmSel = 'all';

  String get _lang => widget.appState.languageCode;
  bool get _isDark => widget.appState.isDark;

  void _onNavTap(int i) {
    if (i == 1) {
      if (widget.appState.isManager && widget.appState.isSingleFarm) {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => FarmDetailScreen(appState: widget.appState, farm: kFarms.first))).then((_) => setState(() {}));
        return;
      }
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
  Color get _text2 => VanixColors.textHint;
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
                        if (widget.appState.isManager)
                          Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(16, 20, 16, 0),
                            child: _managerAttention(),
                          )
                        else
                          Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(16, 20, 16, 0),
                            child: _scheduleTabs(),
                          ),
                        // Cows in Fever / Cows in Heat / Updates — shown to
                        // both Owner and Manager personas (Manager just also
                        // gets the Milking/Critical-Alerts/Contact-Vet block
                        // above).
                        ...[
                          Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(0, 20, 0, 0),
                            child: _cowsInFeverRow(),
                          ),
                          Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(0, 20, 0, 0),
                            child: _cowsInHeatRow(),
                          ),
                          Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(16, 20, 16, 0),
                            child: _updates(),
                          ),
                        ],
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
  BoxDecoration _cardDeco() => BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(16), boxShadow: _shadow);

  TextStyle get _secLbl => const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: VanixColors.textHint);

  String get _farmSelLabel {
    if (_farmSel == 'all') return '${_t('dashAllFarms')} (${kFarms.length})';
    return kFarms.firstWhere((f) => f.id == _farmSel).nm(_lang);
  }

  // Manager viewing a single farm sees a plain farm-name label instead of
  // the interactive All-Farms dropdown (mirrors the HTML's dash-farmsel
  // swap in applyPersona()).
  bool get _isSingleFarmManager => widget.appState.isManager && widget.appState.isSingleFarm;

  void _openFarmSelector() {
    if (_isSingleFarmManager) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        Widget row(String id, String label) {
          final on = _farmSel == id;
          return InkWell(
            onTap: () {
              setState(() => _farmSel = id);
              Navigator.of(ctx).pop();
            },
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
              alignment: AlignmentDirectional.centerStart,
              child: Row(children: [
                Expanded(child: Text(label, style: TextStyle(fontSize: 15, fontWeight: on ? FontWeight.w700 : FontWeight.w500, color: _text1))),
                if (on) const Icon(Icons.check, size: 18, color: VanixColors.greenInk),
              ]),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(color: _cardBg, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
          padding: const EdgeInsets.only(top: 8, bottom: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 10), decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2))),
              row('all', '${_t('dashAllFarms')} (${kFarms.length})'),
              for (final f in kFarms) row(f.id, f.nm(_lang)),
            ],
          ),
        );
      },
    );
  }

  // ── Header: logo (left) + farm selector (right). SafeArea (top) already
  // clears the device status bar; this just adds a little breathing room. ──
  Widget _header() {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 20, 16, 6),
      child: Row(
        children: [
          Text.rich(
            TextSpan(children: [
              TextSpan(text: 'My', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: _text1)),
              const TextSpan(text: 'Bovine', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: VanixColors.greenInk)),
            ]),
          ),
          const SizedBox(width: 12),
          // Expanded + end-alignment pins the pill to the trailing edge at
          // every width (a Spacer+Flexible pair let it drift left on wide
          // screens because the free space was split between the two).
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: InkWell(
                onTap: _isSingleFarmManager ? null : _openFarmSelector,
                borderRadius: BorderRadius.circular(19),
                child: Container(
                  height: 38,
                  padding: const EdgeInsetsDirectional.symmetric(horizontal: 14),
                  decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(19), border: Border.all(color: _border)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Flexible(
                      child: Text(
                        _isSingleFarmManager ? kFarms.first.nm(_lang) : _farmSelLabel,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _text1),
                      ),
                    ),
                    if (!_isSingleFarmManager) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down, size: 16, color: _text1),
                    ],
                  ]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Farm Status: 3 compact stat tiles (number + label) — Total Cattle /
  // Cows Pregnant / Cows in Heat. Mirrors the `.m-stat-card` row under the
  // "Farm Status" heading in #dash-scroll (Home r3). ──
  Widget _statGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsetsDirectional.only(bottom: 10), child: Text(_t('farmStatusTitle').toUpperCase(), style: _secLbl)),
        Row(children: [
          Expanded(child: _statTile('77', 'statTotalCattle')),
          const SizedBox(width: 10),
          Expanded(child: _statTile('2', 'homeCowsPregnant')),
          const SizedBox(width: 10),
          Expanded(child: _statTile('4', 'homeCowsHeat')),
        ]),
      ],
    );
  }

  Widget _statTile(String num, String labelKey, {VoidCallback? onInfo}) {
    // labelKey text may contain literal '\n' for a 2-line label (matches the
    // HTML's white-space:pre-line labels, e.g. "Cows\nPregnant").
    final card = Container(
      decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      child: Column(
        children: [
          Text(num, textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, height: 1, color: _text1)),
          const SizedBox(height: 7),
          Text(_t(labelKey), textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, height: 1.3, color: _text1)),
        ],
      ),
    );
    if (onInfo == null) return card;
    return Stack(
      children: [
        card,
        PositionedDirectional(
          top: 2, end: 2,
          child: IconButton(
            iconSize: 15,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
            onPressed: onInfo,
            icon: const Icon(Icons.info_outline, color: VanixColors.textHint),
          ),
        ),
      ],
    );
  }

  // ── Today / This week tabs above Needs Attention — purely a visual
  // toggle now (mirrors the HTML's simplification): both tabs render the
  // same Needs Attention list, they just reflect which window the farm
  // owner is scoping to. ──
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

  // ── Needs Attention: Today/This-week tab row (visual only) + 3
  // tappable "View All" rows — Pending Approvals / Milking Sessions
  // Missed / Critical Alerts. Mirrors #dash-scroll's Needs Attention
  // block (Home r3), replacing the old per-time schedule rows. ──
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
        Padding(padding: const EdgeInsetsDirectional.only(bottom: 10), child: Text(_t('needsAttentionTitle').toUpperCase(), style: _secLbl)),
        Container(
          decoration: _cardDeco(),
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
          child: Column(children: [
            _needsAttentionRow('2', 'rowPendingApprovals', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ApprovalsScreen(appState: widget.appState)))),
            _needsAttentionRow('3', 'rowMilkingMissed', () => _onNavTap(2), divider: true),
            _needsAttentionRow('14', 'rowCriticalAlerts', () => _onNavTap(3), divider: false),
          ]),
        ),
      ],
    );
  }

  // ── Manager persona: Milking (Morning) progress / Critical Alerts /
  // Contact Vet. Replaces only the owner's Today/This-week tabs + Needs
  // Attention block — Cows-in-heat/gestation + Updates stay visible for
  // both personas. Mirrors [data-manager-only] in prototype.html. ──
  Widget _managerAttention() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsetsDirectional.only(bottom: 10), child: Text(_t('needsAttentionTitle').toUpperCase(), style: _secLbl)),
        Container(
          decoration: _cardDeco(),
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
          child: Column(children: [
            _managerChevronRow('${_t('mgrMilkingMorning')} — 0/20', () {
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => MilkLogScreen(appState: widget.appState, openAddOnStart: true)))
                  .then((_) => setState(() {}));
            }, divider: true),
            _managerChevronRow('14 ${_t('rowCriticalAlerts')}', () => _onNavTap(3), divider: false),
          ]),
        ),
        const SizedBox(height: 14),
        _contactVetCard(),
      ],
    );
  }

  Widget _managerChevronRow(String label, VoidCallback onTap, {required bool divider}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(border: divider ? Border(bottom: BorderSide(color: _divider)) : null),
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _text1))),
          Icon(Icons.chevron_right, size: 18, color: _text2),
        ]),
      ),
    );
  }

  Widget _contactVetCard() {
    return InkWell(
      onTap: _openContactVet,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(color: VanixColors.activeBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: VanixColors.greenInk, width: 1.5)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: const BoxDecoration(color: VanixColors.greenInk, shape: BoxShape.circle),
            child: const Icon(Icons.phone, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_t('mgrContactVet'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: VanixColors.greenInk)),
                const SizedBox(height: 2),
                Text(_t('mgrContactVetSub'), style: const TextStyle(fontSize: 11, color: VanixColors.textHint)),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  void _openContactVet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          var picked = kVets.first;
          return Container(
            decoration: BoxDecoration(color: _cardBg, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 14), decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2))),
                Align(alignment: Alignment.centerLeft, child: Text(_t('mgrContactVet'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _text1))),
                const SizedBox(height: 12),
                for (final vet in kVets)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () => setSheetState(() => picked = vet),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 46),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(border: Border.all(color: _border), borderRadius: BorderRadius.circular(12)),
                        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text(vet.name, style: TextStyle(fontSize: 14, fontWeight: picked == vet ? FontWeight.w600 : FontWeight.w500, color: _text1)),
                          if (picked == vet) const Icon(Icons.check, size: 16, color: VanixColors.greenInk),
                        ]),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _callVet(picked.phone);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: VanixColors.greenInk, foregroundColor: Colors.white, minimumSize: const Size(0, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                    child: Text(_t('callWord')),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  void _callVet(String phone) {
    final uri = Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'\s+'), ''));
    launchUrl(uri);
  }

  Widget _needsAttentionRow(String count, String labelKey, VoidCallback onViewAll, {bool divider = true}) {
    return Container(
      decoration: BoxDecoration(border: divider ? Border(bottom: BorderSide(color: _divider)) : null),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: RichText(
              text: TextSpan(children: [
                TextSpan(text: '$count ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _text1)),
                TextSpan(text: _t(labelKey), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _text1)),
              ]),
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: onViewAll,
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 32), foregroundColor: VanixColors.greenInk),
            child: Text('${_t('viewAllWord')} ›', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: VanixColors.greenInk)),
          ),
        ],
      ),
    );
  }

  // ── Cows in Fever (horizontal scroll, compact photo alert cards) — photo
  // vertically centered against a 3-line block (Name | Belt / time-ago /
  // Farm). Tapping opens the Events page. Mirrors the "Cows in fever
  // (horizontal scroll photo alert cards)" row in prototype.html. ──
  Widget _cowsInFeverRow() {
    final cards = [
      _AlertCardData('Gauri', 'Belt 41', 'Sunrise Dairy', 'assets/images/cows/gowri.jpg', '20 mins ago'),
      _AlertCardData('Kajri', 'Belt 12', 'Green Villa', 'assets/images/cows/kaveri.jpg', '2 hrs ago'),
      _AlertCardData('Rani', 'Belt 23', 'Stones Dairy', 'assets/images/cows/chinnu.jpg', '1 hr ago'),
      _AlertCardData('Chandni', 'Belt 34', 'Green Villa', 'assets/images/cows/giri.jpg', '4 hrs ago'),
    ];
    return _alertCardRow('homeCowsInFever', cards, () {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => EventsScreen(appState: widget.appState))).then((_) => setState(() {}));
    });
  }

  // ── Cows in Heat (horizontal scroll, compact photo alert cards) — same
  // layout as Cows in Fever. Mirrors the "Cows in heat (horizontal scroll
  // photo alert cards)" row in prototype.html. ──
  Widget _cowsInHeatRow() {
    final cards = [
      _AlertCardData('Lakshmi', 'Belt 08', 'Green Villa', 'assets/images/cows/nandini.jpg', '45 mins ago'),
      _AlertCardData('Mohini', 'Belt 91', 'Sunrise Dairy', 'assets/images/cows/ramya.jpg', '3 hrs ago'),
      _AlertCardData('Ganga', 'Belt 56', 'Stones Dairy', 'assets/images/cows/giri.jpg', '5 hrs ago'),
      _AlertCardData('Bhoori', 'Belt 19', 'Sunrise Dairy', 'assets/images/cows/chinnu.jpg', '6 hrs ago'),
    ];
    return _alertCardRow('homeCowsInHeat', cards, () {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => EventsScreen(appState: widget.appState))).then((_) => setState(() {}));
    });
  }

  Widget _alertCardRow(String titleKey, List<_AlertCardData> cards, VoidCallback onTapCard) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsetsDirectional.only(start: 16, end: 16, bottom: 10), child: Text(_t(titleKey).toUpperCase(), style: _secLbl)),
        SizedBox(
          height: 78,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsetsDirectional.only(start: 16, end: 16),
            itemCount: cards.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final c = cards[i];
              return InkWell(
                onTap: onTapCard,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 190,
                  decoration: _cardDeco(),
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(color: VanixColors.bgWarm, borderRadius: BorderRadius.circular(10)),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(c.photo, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox()),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RichText(
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(children: [
                                TextSpan(text: c.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _text1)),
                                TextSpan(text: ' | ${c.belt}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: VanixColors.textHint)),
                              ]),
                            ),
                            const SizedBox(height: 3),
                            Text(c.timeAgo, style: const TextStyle(fontSize: 11, color: VanixColors.textHint)),
                            const SizedBox(height: 3),
                            Text(c.farm, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: VanixColors.textHint)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
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

class _AlertCardData {
  final String name, belt, farm, photo, timeAgo;
  const _AlertCardData(this.name, this.belt, this.farm, this.photo, this.timeAgo);
}
