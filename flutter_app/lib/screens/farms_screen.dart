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
import 'farm_detail_screen.dart';
import 'setup_farm_screen.dart';

/// Farms list — screen 04. Mirrors #page-farms in prototype.html:
/// hero (title + subtitle, 3 stat tiles, auto-scrolling activity ticker),
/// search + two-pane filter sheet (Status / Location), and the farm cards
/// (severity corner tag, cattle count, 4 stat chips). Setup farms render as
/// a dashed-style row with a "Setup Farm" pill.
class FarmsScreen extends StatefulWidget {
  final AppState appState;
  const FarmsScreen({super.key, required this.appState});

  @override
  State<FarmsScreen> createState() => _FarmsScreenState();
}

class _FarmsScreenState extends State<FarmsScreen> with SingleTickerProviderStateMixin {
  final int _navIndex = 1;
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  String _statusFilter = 'all'; // all | healthy | attention | setup
  String _locFilter = 'all'; // all | coimbatore | erode | salem

  late final AnimationController _tickerCtrl;

  @override
  void initState() {
    super.initState();
    _tickerCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 55))..repeat();
  }

  @override
  void dispose() {
    _tickerCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  String _statusKey(FarmStatus s) {
    switch (s) {
      case FarmStatus.healthy:
        return 'healthy';
      case FarmStatus.attention:
        return 'attention';
      case FarmStatus.setup:
        return 'setup';
    }
  }

  List<FarmModel> get _filtered {
    final q = _query.trim().toLowerCase();
    return kFarms.where((f) {
      // Setting up a new farm is owner-only — Manager persona never sees
      // the dashed "Setup Farm" row.
      if (widget.appState.isManager && f.status == FarmStatus.setup) return false;
      if (_statusFilter != 'all' && _statusKey(f.status) != _statusFilter) return false;
      if (_locFilter != 'all' && f.locKey != _locFilter) return false;
      if (q.isNotEmpty && !('${f.name} ${f.nameHi}').toLowerCase().contains(q)) return false;
      return true;
    }).toList();
  }

  void _onNavTap(int i) {
    switch (i) {
      case 0:
        Navigator.of(context).popUntil((r) => r.isFirst);
        break;
      case 1:
        break; // current
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

  void _openFarm(FarmModel farm) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => FarmDetailScreen(appState: widget.appState, farm: farm)))
        .then((_) => setState(() {}));
  }

  void _openSetupFarm(FarmModel farm) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => SetupFarmScreen(appState: widget.appState, farm: farm)))
        .then((_) => setState(() {}));
  }

  void _openFilterSheet() {
    final lang = widget.appState.languageCode;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _FarmsFilterSheet(
        lang: lang,
        isDark: widget.appState.isDark,
        status: _statusFilter,
        location: _locFilter,
        onApply: (status, loc) => setState(() {
          _statusFilter = status;
          _locFilter = loc;
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
        final lang = widget.appState.languageCode;
        final t = VanixStrings.of(lang);
        final theme = isDark ? vanixDarkTheme(languageCode: lang) : vanixLightTheme(languageCode: lang);
        final textColor = isDark ? Colors.white : VanixColors.textPrimary;

        final list = _filtered;
        final totalFarms = kFarms.where((f) => f.status != FarmStatus.setup).length;
        final totalCattle = kFarms.fold<int>(0, (s, f) => s + f.cattle);
        final totalAlerts = kFarms.fold<int>(0, (s, f) => s + f.alerts);

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
                      _buildHero(isDark, lang, textColor, totalFarms, totalCattle, totalAlerts),
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 0),
                        child: Row(
                          children: [
                            Expanded(child: _buildSearch(isDark, lang)),
                            const SizedBox(width: 10),
                            _FilterButton(isDark: isDark, onTap: _openFilterSheet),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(16, 18, 16, 10),
                        child: Text(FS.t(lang, 'yourFarms'),
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor)),
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
                        child: list.isEmpty
                            ? Padding(
                                padding: const EdgeInsetsDirectional.only(top: 24),
                                child: Center(
                                  child: Text(FS.t(lang, 'noFarmsMatch'),
                                      style: const TextStyle(fontSize: 13, color: VanixColors.textHint)),
                                ),
                              )
                            : Column(
                                children: [
                                  for (final f in list)
                                    f.status == FarmStatus.setup
                                        ? _SetupFarmRow(farm: f, lang: lang, isDark: isDark, onTap: () => _openSetupFarm(f))
                                        : _FarmCard(farm: f, lang: lang, isDark: isDark, onTap: () => _openFarm(f)),
                                ],
                              ),
                      ),
                    ],
                  ),
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

  Widget _buildHero(bool isDark, String lang, Color textColor, int totalFarms, int totalCattle, int totalAlerts) {
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 20, 16, 18),
      decoration: BoxDecoration(
        color: isDark ? VanixColors.darkPrimary : VanixColors.bgWarm,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.10), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(FS.t(lang, 'farmsTitle'), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: textColor)),
          const SizedBox(height: 4),
          Text(FS.t(lang, 'farmsSubtitle'), style: const TextStyle(fontSize: 13, color: VanixColors.textHint)),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _StatTile(value: '$totalFarms', label: FS.t(lang, 'statTotalFarms'), isDark: isDark)),
              const SizedBox(width: 10),
              Expanded(child: _StatTile(value: '$totalCattle', label: FS.t(lang, 'statTotalCattle'), isDark: isDark)),
              const SizedBox(width: 10),
              Expanded(child: _StatTile(value: '$totalAlerts', label: FS.t(lang, 'statUnactionedAlerts'), isDark: isDark)),
            ],
          ),
          const SizedBox(height: 16),
          _Ticker(controller: _tickerCtrl, lang: lang, isDark: isDark),
        ],
      ),
    );
  }

  Widget _buildSearch(bool isDark, String lang) {
    return TextField(
      controller: _searchCtrl,
      onChanged: (v) => setState(() => _query = v),
      style: TextStyle(fontSize: 14, color: isDark ? Colors.white : VanixColors.textPrimary),
      decoration: InputDecoration(
        hintText: FS.t(lang, 'searchFarms'),
        prefixIcon: const Icon(Icons.search, size: 18, color: VanixColors.textHint),
      ),
    );
  }
}

// ── Hero pieces ──────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  final String value, label;
  final bool isDark;
  const _StatTile({required this.value, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : VanixColors.textPrimary;
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: isDark ? VanixColors.darkSecond : VanixColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        boxShadow: isDark ? VanixShadow.cardDark : VanixShadow.card,
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textColor)),
          const SizedBox(height: 3),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: VanixColors.textHint)),
        ],
      ),
    );
  }
}

class _Ticker extends StatelessWidget {
  final AnimationController controller;
  final String lang;
  final bool isDark;
  const _Ticker({required this.controller, required this.lang, required this.isDark});

  static const _items = [
    ['tickHeat', 'danger'],
    ['tickMilk', 'greenink'],
    ['tickFever', 'warnink'],
    ['tickVet', 'greenink'],
    ['tickInsem', 'warning'],
  ];

  Color _dotColor(String key) {
    switch (key) {
      case 'danger':
        return VanixColors.danger;
      case 'warning':
        return VanixColors.warning;
      case 'warnink':
        return VanixColors.warningInk;
      default:
        return VanixColors.greenInk;
    }
  }

  @override
  Widget build(BuildContext context) {
    final chips = [
      for (final it in _items) _tickerChip(FS.t(lang, it[0]), _dotColor(it[1])),
    ];
    // Loop the list twice so the scroll wraps seamlessly.
    final row = Row(mainAxisSize: MainAxisSize.min, children: [...chips, ...chips]);

    return SizedBox(
      height: 30,
      child: ClipRect(
        child: LayoutBuilder(
          builder: (context, _) {
            return AnimatedBuilder(
              animation: controller,
              builder: (context, child) {
                return _MeasuredScroller(progress: controller.value, child: child!);
              },
              child: row,
            );
          },
        ),
      ),
    );
  }

  Widget _tickerChip(String label, Color dot) {
    return Container(
      margin: const EdgeInsetsDirectional.only(end: 8),
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? VanixColors.darkSecond : VanixColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? VanixColors.darkBorder : VanixColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: isDark ? Colors.white : VanixColors.textPrimary)),
        ],
      ),
    );
  }
}

/// Slides its child leftwards by [progress] of half its own width, so a
/// doubled child list scrolls seamlessly and wraps.
class _MeasuredScroller extends StatelessWidget {
  final double progress;
  final Widget child;
  const _MeasuredScroller({required this.progress, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: OverflowBox(
        alignment: AlignmentDirectional.centerStart,
        maxWidth: double.infinity,
        child: FractionalTranslation(
          // The child is two copies; shifting by up to half its width wraps cleanly.
          translation: Offset(-progress * 0.5, 0),
          child: child,
        ),
      ),
    );
  }
}

// ── Filter button ───────────────────────────────────────────

class _FilterButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;
  const _FilterButton({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isDark ? VanixColors.darkSecond : VanixColors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? VanixColors.darkBorder : VanixColors.border),
        ),
        child: Icon(Icons.filter_list, size: 20, color: isDark ? Colors.white : VanixColors.textPrimary),
      ),
    );
  }
}

// ── Farm cards ───────────────────────────────────────────────

class _FarmCard extends StatelessWidget {
  final FarmModel farm;
  final String lang;
  final bool isDark;
  final VoidCallback onTap;
  const _FarmCard({required this.farm, required this.lang, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : VanixColors.textPrimary;
    final attention = farm.status == FarmStatus.attention;
    final tagBg = attention ? VanixColors.danger : VanixColors.greenInk;
    final tagLabel = attention ? FS.t(lang, 'sevCritical') : FS.t(lang, 'healthyWord');

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? VanixColors.darkSecond : VanixColors.bgCard,
            borderRadius: BorderRadius.circular(18),
            boxShadow: isDark ? VanixShadow.cardDark : VanixShadow.card,
          ),
          child: Stack(
            children: [
              // Corner severity tag.
              PositionedDirectional(
                top: 0,
                end: 0,
                child: Container(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 5, 14, 6),
                  decoration: BoxDecoration(
                    color: tagBg,
                    borderRadius: const BorderRadiusDirectional.only(
                      topEnd: Radius.circular(17),
                      bottomStart: Radius.circular(12),
                    ),
                  ),
                  child: Text(tagLabel,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: Colors.white)),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(farm.nm(lang),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textColor)),
                              const SizedBox(height: 3),
                              _MetaLine(icon: Icons.place_outlined, text: farm.loc(lang)),
                              const SizedBox(height: 2),
                              _MetaLine(icon: Icons.person_outline, text: farm.mgr(lang)),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsetsDirectional.only(top: 28, end: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CowHeadIcon(color: textColor, size: 13),
                              const SizedBox(width: 4),
                              Text('${farm.cattle}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textColor)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _Chip(bg: VanixColors.dangerBg, ink: VanixColors.danger, value: '${farm.heat}', label: FS.t(lang, 'cattleHeat')),
                        const SizedBox(width: 6),
                        _Chip(bg: VanixColors.bgWarm, ink: VanixColors.textPrimary, value: '${farm.insem}', label: FS.t(lang, 'insemWord')),
                        const SizedBox(width: 6),
                        _Chip(bg: const Color(0x1A2563EB), ink: const Color(0xFF2563EB), value: '${farm.preg}', label: FS.t(lang, 'statusPregnantChip')),
                        const SizedBox(width: 6),
                        _Chip(bg: VanixColors.warningBg, ink: VanixColors.warningInk, value: '${farm.fever}', label: FS.t(lang, 'cattleFever')),
                        const SizedBox(width: 6),
                        _Chip(bg: VanixColors.activeBg, ink: VanixColors.greenInk, value: '${farm.milkToday} L', label: FS.t(lang, 'statMilkToday')),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: VanixColors.textHint),
        const SizedBox(width: 4),
        Expanded(
          child: Text(text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: VanixColors.textHint)),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final Color bg, ink;
  final String value, label;
  const _Chip({required this.bg, required this.ink, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ink)),
            const SizedBox(height: 2),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: ink.withValues(alpha: 0.85))),
          ],
        ),
      ),
    );
  }
}

class _SetupFarmRow extends StatelessWidget {
  final FarmModel farm;
  final String lang;
  final bool isDark;
  final VoidCallback onTap;
  const _SetupFarmRow({required this.farm, required this.lang, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : VanixColors.textPrimary;
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsetsDirectional.all(14),
          decoration: BoxDecoration(
            color: isDark ? VanixColors.darkSecond : VanixColors.bgCard,
            borderRadius: BorderRadius.circular(18),
            boxShadow: isDark ? VanixShadow.cardDark : VanixShadow.card,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(farm.nm(lang), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textColor)),
                    const SizedBox(height: 2),
                    Text('${FS.t(lang, 'notSetUp')} · 0 ${FS.t(lang, 'wordCattle')}',
                        style: const TextStyle(fontSize: 12, color: VanixColors.textHint)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                constraints: const BoxConstraints(minHeight: 36),
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark ? VanixColors.darkPrimary : VanixColors.bgCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isDark ? VanixColors.darkBorder : VanixColors.border),
                ),
                child: Text(FS.t(lang, 'setupFarm'),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Two-pane filter sheet ────────────────────────────────────

class _FarmsFilterSheet extends StatefulWidget {
  final String lang;
  final bool isDark;
  final String status, location;
  final void Function(String status, String location) onApply;
  const _FarmsFilterSheet({
    required this.lang,
    required this.isDark,
    required this.status,
    required this.location,
    required this.onApply,
  });

  @override
  State<_FarmsFilterSheet> createState() => _FarmsFilterSheetState();
}

class _FarmsFilterSheetState extends State<_FarmsFilterSheet> {
  int _cat = 0; // 0 status, 1 location
  late String _status;
  late String _loc;

  @override
  void initState() {
    super.initState();
    _status = widget.status;
    _loc = widget.location;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final lang = widget.lang;
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
                Text(FS.t(lang, 'filterWord'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor)),
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
                      _CatTab(label: FS.t(lang, 'statusWord'), active: _cat == 0, isDark: isDark, onTap: () => setState(() => _cat = 0)),
                      _CatTab(label: FS.t(lang, 'locationWord'), active: _cat == 1, isDark: isDark, onTap: () => setState(() => _cat = 1)),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    color: isDark ? VanixColors.darkSubSurface : VanixColors.bgWarm,
                    padding: const EdgeInsetsDirectional.all(12),
                    child: _cat == 0 ? _statusPane(isDark, lang) : _locationPane(isDark, lang),
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
                widget.onApply(_status, _loc);
                Navigator.of(context).pop();
              },
              child: Text(FS.t(lang, 'applyFilters')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusPane(bool isDark, String lang) {
    return ListView(
      children: [
        _OptRow(label: FS.t(lang, 'filterAllFarms'), active: _status == 'all', isDark: isDark, onTap: () => setState(() => _status = 'all')),
        _OptRow(label: FS.t(lang, 'filterHealthy'), active: _status == 'healthy', isDark: isDark, onTap: () => setState(() => _status = 'healthy')),
        _OptRow(label: FS.t(lang, 'filterAttention'), active: _status == 'attention', isDark: isDark, onTap: () => setState(() => _status = 'attention')),
        _OptRow(label: FS.t(lang, 'filterSetup'), active: _status == 'setup', isDark: isDark, onTap: () => setState(() => _status = 'setup')),
      ],
    );
  }

  Widget _locationPane(bool isDark, String lang) {
    return ListView(
      children: [
        _OptRow(label: FS.t(lang, 'allWord'), active: _loc == 'all', isDark: isDark, onTap: () => setState(() => _loc = 'all')),
        _OptRow(label: FS.t(lang, 'locCoimbatore'), active: _loc == 'coimbatore', isDark: isDark, onTap: () => setState(() => _loc = 'coimbatore')),
        _OptRow(label: FS.t(lang, 'locErode'), active: _loc == 'erode', isDark: isDark, onTap: () => setState(() => _loc = 'erode')),
        _OptRow(label: FS.t(lang, 'locSalem'), active: _loc == 'salem', isDark: isDark, onTap: () => setState(() => _loc = 'salem')),
      ],
    );
  }
}

class _CatTab extends StatelessWidget {
  final String label;
  final bool active, isDark;
  final VoidCallback onTap;
  const _CatTab({required this.label, required this.active, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final activeColor = isDark ? VanixColors.textOnDarkDim : Colors.white;
    final textColor = isDark ? Colors.white : VanixColors.textPrimary;
    return InkWell(
      onTap: onTap,
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
}

class _OptRow extends StatelessWidget {
  final String label;
  final bool active, isDark;
  final VoidCallback onTap;
  const _OptRow({required this.label, required this.active, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
}
