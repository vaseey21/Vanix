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
import 'farms_screen.dart';
import 'farm_detail_screen.dart';
import 'account_screen.dart';

/// Farmer Home — simpler, action-first dashboard (mirrors #farmer-dash in
/// prototype.html). Two tabs: Immediate (heat/fever/delivery) and To-dos
/// (vet appointment/insemination window/milk logging); each row opens its
/// event card. A single-farm Farmer lands straight in his farm's detail.
class FarmerDashboardScreen extends StatefulWidget {
  final AppState appState;
  const FarmerDashboardScreen({super.key, required this.appState});

  @override
  State<FarmerDashboardScreen> createState() => _FarmerDashboardScreenState();
}

class _FarmerDashboardScreenState extends State<FarmerDashboardScreen> {
  int _navIndex = 0;
  String _tab = 'immediate';

  String get _lang => widget.appState.languageCode;
  bool get _isDark => widget.appState.isDark;
  String _t(String k) => FS.t(_lang, k);

  @override
  void initState() {
    super.initState();
    // Single-farm farmer opens directly into his farm's detail page.
    if (widget.appState.isSingleFarm) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openFarms());
    }
  }

  void _openFarms() {
    final target = widget.appState.isSingleFarm
        ? FarmDetailScreen(appState: widget.appState, farm: kFarms.first)
        : FarmsScreen(appState: widget.appState);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => target)).then((_) => setState(() {}));
  }

  void _onNavTap(int i) {
    switch (i) {
      case 1:
        _openFarms();
        break;
      case 2:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => MilkLogScreen(appState: widget.appState))).then((_) => setState(() {}));
        break;
      case 3:
        _openEvents();
        break;
      case 4:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => AccountScreen(appState: widget.appState))).then((_) => setState(() {}));
        break;
      default:
        setState(() => _navIndex = 0);
    }
  }

  void _openEvents() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => EventsScreen(appState: widget.appState))).then((_) => setState(() {}));
  }

  Color get _cardBg => _isDark ? VanixColors.darkSecond : VanixColors.bgCard;
  Color get _text1 => _isDark ? Colors.white : VanixColors.textPrimary;
  Color get _border => _isDark ? VanixColors.darkBorder : VanixColors.border;
  List<BoxShadow> get _shadow => _isDark ? VanixShadow.cardDark : VanixShadow.card;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        final t = VanixStrings.of(_lang);
        final theme = _isDark ? vanixDarkTheme(languageCode: _lang) : vanixLightTheme(languageCode: _lang);
        final immediate = _tab == 'immediate';
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
                        // Header: logo + greeting
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(16, 20, 16, 6),
                          child: Row(
                            children: [
                              Text.rich(TextSpan(children: [
                                TextSpan(text: 'My', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: _text1)),
                                const TextSpan(text: 'Bovine', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: VanixColors.greenInk)),
                              ])),
                              const Spacer(),
                              Text(_t('fpGreeting'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: VanixColors.textHint)),
                            ],
                          ),
                        ),
                        // Tabs
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 0),
                          child: Row(children: [
                            _tabBtn('immediate', _t('fpImmediate'), VanixColors.danger),
                            const SizedBox(width: 8),
                            _tabBtn('todos', _t('fpTodos'), VanixColors.greenInk),
                          ]),
                        ),
                        const SizedBox(height: 14),
                        // Rows
                        Padding(
                          padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
                          child: Column(children: immediate ? _immediateRows() : _todoRows()),
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

  Widget _tabBtn(String tab, String label, Color onColor) {
    final on = _tab == tab;
    return InkWell(
      onTap: () => setState(() => _tab = tab),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        constraints: const BoxConstraints(minHeight: 36),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? onColor : _cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: on ? onColor : _border),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: on ? FontWeight.w600 : FontWeight.w500, color: on ? Colors.white : _text1)),
      ),
    );
  }

  // Priority tab = event-style cards (mirrors the HTML #fp-immediate cards).
  // Tapping opens the Events screen where the card's full flow runs
  // (Heat→insemination→vet log; Fever→call vet→schedule→log; Delivery→confirm).
  List<Widget> _immediateRows() => [
        _priorityCard('cattleFever', 'Kajri', 'Sahiwal', 'cardFeverQ', VanixColors.danger, VanixColors.dangerBg, VanixColors.danger),
        _priorityCard('cattleHeat', 'Gauri', 'Gir', 'cardHeatQ', VanixColors.warning, VanixColors.warningBg, VanixColors.warningInk),
        _priorityCard('fpDelivery', 'Lakshmi', 'HF Cross', 'cardGestationQ', VanixColors.warning, VanixColors.warningBg, VanixColors.warningInk),
      ];

  Widget _priorityCard(String typeKey, String cow, String breed, String qKey, Color border, Color tint, Color eyebrow) {
    final tintBg = _isDark ? VanixColors.darkSecond : tint;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: _openEvents,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: tintBg,
            borderRadius: BorderRadius.circular(16),
            border: Border(
              left: BorderSide(color: border, width: 4),
              top: BorderSide(color: border),
              right: BorderSide(color: border),
              bottom: BorderSide(color: border),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_t(typeKey).toUpperCase(),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: eyebrow)),
              const SizedBox(height: 4),
              Text.rich(TextSpan(children: [
                TextSpan(text: cow, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _text1)),
                TextSpan(text: '  —  $breed', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: VanixColors.textHint)),
              ])),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(child: Text(_t(qKey), style: const TextStyle(fontSize: 13, color: VanixColors.textHint))),
                const Icon(Icons.chevron_right, size: 18, color: VanixColors.textHint),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _todoRows() => [
        _row(VanixColors.greenInk, 'fpVetAppt', 'Kajri', 'fpVetApptSub'),
        _row(VanixColors.warning, 'fpInsem', 'Gauri', 'fpInsemSub'),
        _row(_border, 'fpMilkLog', '', 'fpMilkLogSub'),
      ];

  Widget _row(Color bar, String titleKey, String name, String subKey) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(16), boxShadow: _shadow),
      child: IntrinsicHeight(
        child: Row(children: [
          Container(width: 4, decoration: BoxDecoration(color: bar, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(name.isEmpty ? _t(titleKey) : '${_t(titleKey)} — $name',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _text1)),
                const SizedBox(height: 3),
                Text(_t(subKey), style: const TextStyle(fontSize: 12, color: VanixColors.textHint)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: _openEvents,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              backgroundColor: VanixColors.greenInk,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            child: Text(_t('fpOpen'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ]),
      ),
    );
  }
}
