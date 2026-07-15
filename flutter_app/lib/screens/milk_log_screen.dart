import 'package:flutter/material.dart';
import '../i18n/strings.dart';
import '../models/milk_models.dart';
import '../state/app_state.dart';
import '../theme/vanix_theme.dart';
import '../widgets/vanix_bottom_nav.dart';
import '../widgets/vanix_nav_items.dart';
import '../widgets/milk_filter_sheet.dart';
import '../widgets/option_sheet.dart';
import 'events_screen.dart';
import 'farms_screen.dart';
import 'account_screen.dart';
import 'milk_add_entry_screen.dart';
import 'milk_summary_screen.dart';

/// Milk Log — mirrors #page-milk in vanix_screens.html: hero (period pill,
/// total + delta, 3 stat tiles, view-complete-summary), dismissible status
/// banners, date-grouped entry cards, filter bottom sheet, FAB → add entry.
class MilkLogScreen extends StatefulWidget {
  final AppState appState;
  const MilkLogScreen({super.key, required this.appState});

  @override
  State<MilkLogScreen> createState() => _MilkLogScreenState();
}

class _Banner {
  final String title, sub;
  final Color bg, border, ink;
  bool dismissed = false;
  _Banner(this.title, this.sub, this.bg, this.border, this.ink);
}

class _MilkLogScreenState extends State<MilkLogScreen> {
  final int _navIndex = 2;
  final DateTime _today = DateTime(2026, 7, 3);
  late List<MilkEntry> _entries;
  String _period = 'Today';
  MilkFilter _filter = const MilkFilter();

  final List<_Banner> _banners = [
    _Banner('3 cows below 7-day average', 'Kajri, Dhauli and Mohini need attention', VanixColors.warningBg, VanixColors.warning, VanixColors.warningInk),
    _Banner('Morning session complete', 'All 18 assigned cows logged before 09:00', VanixColors.activeBg, VanixColors.greenDeep, VanixColors.greenInk),
  ];

  @override
  void initState() {
    super.initState();
    _entries = MilkSeed.entries(_today);
  }

  void _onNavTap(int i) {
    if (i == 0) {
      Navigator.of(context).pop();
      return;
    }
    if (i == 1) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => FarmsScreen(appState: widget.appState)));
      return;
    }
    if (i == 3) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => EventsScreen(appState: widget.appState)));
      return;
    }
    if (i == 4) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => AccountScreen(appState: widget.appState)));
      return;
    }
  }

  List<MilkEntry> get _visibleTodayEntries {
    var list = _entries.where((e) => _isSameDay(e.date, _today)).toList();
    if (_filter.farm != null) list = list.where((e) => e.farm == _filter.farm).toList();
    if (_filter.session != null) list = list.where((e) => e.session == _filter.session).toList();
    if (_filter.sort == 'highest') list.sort((a, b) => b.litres.compareTo(a.litres));
    if (_filter.sort == 'lowest') list.sort((a, b) => a.litres.compareTo(b.litres));
    return list;
  }

  Map<String, List<MilkEntry>> get _groupedEntries {
    final map = <String, List<MilkEntry>>{};
    for (final e in _entries) {
      final label = _dateLabel(e.date);
      map.putIfAbsent(label, () => []).add(e);
    }
    return map;
  }

  String _dateLabel(DateTime d) {
    if (_isSameDay(d, _today)) return 'Today — ${d.day} Jul';
    if (_isSameDay(d, _today.subtract(const Duration(days: 1)))) return 'Yesterday — ${d.day} Jul';
    return '${d.day} Jul';
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  double get _totalToday => _visibleTodayEntries.fold(0, (sum, e) => sum + e.litres);
  MilkEntry? get _maxEntry => _visibleTodayEntries.isEmpty ? null : _visibleTodayEntries.reduce((a, b) => a.litres >= b.litres ? a : b);
  MilkEntry? get _minEntry => _visibleTodayEntries.isEmpty ? null : _visibleTodayEntries.reduce((a, b) => a.litres <= b.litres ? a : b);

  Future<void> _openAddEntry({MilkEntry? editing}) async {
    final result = await Navigator.of(context).push<MilkEntryResult>(
      MaterialPageRoute(builder: (_) => MilkAddEntryScreen(appState: widget.appState, allEntries: _entries, today: _today, editing: editing)),
    );
    if (result == null) return;
    setState(() {
      if (result.delete && editing != null) {
        _entries.removeWhere((e) => e.id == editing.id);
      } else if (result.entry != null) {
        final idx = _entries.indexWhere((e) => e.id == result.entry!.id);
        if (idx >= 0) {
          _entries[idx] = result.entry!;
        } else {
          _entries.add(result.entry!);
        }
      }
    });
  }

  void _openEntryActions(MilkEntry entry) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = widget.appState.isDark;
        final bg = isDark ? const Color(0xFF1C1C1C) : Colors.white;
        final textColor = isDark ? Colors.white : VanixColors.textPrimary;
        return Container(
          decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${entry.cow} — ${entry.session.label} · ${entry.litres} L', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
              Padding(padding: const EdgeInsets.only(top: 4), child: Text('Changes are sent to the Farm Owner for approval', style: TextStyle(fontSize: 12, color: VanixColors.textHint))),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                tileColor: VanixColors.bgWarm.withOpacity(isDark ? 0.06 : 1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit entry'),
                onTap: () {
                  Navigator.pop(context);
                  _openAddEntry(editing: entry);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                tileColor: VanixColors.dangerBg.withOpacity(isDark ? 0.10 : 1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: const Icon(Icons.delete_outline, color: VanixColors.danger),
                title: const Text('Delete entry', style: TextStyle(color: VanixColors.danger)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _entries.removeWhere((e) => e.id == entry.id));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.appState.isDark;
    final t = VanixStrings.of(widget.appState.languageCode);
    final textColor = isDark ? Colors.white : VanixColors.textPrimary;
    final total = _totalToday;
    final maxE = _maxEntry;
    final minE = _minEntry;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: VanixColors.darkPrimary,
        onPressed: () => _openAddEntry(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 120),
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
                  decoration: BoxDecoration(color: isDark ? VanixColors.darkPrimary : VanixColors.bgWarm, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 28, offset: const Offset(0, 12))]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Milk Log', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: textColor)),
                          Row(
                            children: [
                              _PeriodPill(
                                label: _period,
                                isDark: isDark,
                                onTap: () => showOptionSheet(
                                  context: context,
                                  title: 'Show data for',
                                  options: const ['Today', 'This Week', 'This Month', 'This Year', 'Custom…'],
                                  current: _period,
                                  onSelect: (v) => setState(() => _period = v),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _IconCircle(icon: Icons.filter_list, isDark: isDark, onTap: () => showMilkFilterSheet(context, current: _filter, onApply: (f) => setState(() => _filter = f))),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text('TOTAL MILK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 1, color: VanixColors.textHint)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text('${total.toStringAsFixed(1)} L', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: textColor)),
                          const SizedBox(width: 10),
                          const Text('▲ 8% vs yesterday', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: VanixColors.greenInk)),
                          const Spacer(),
                          _IconCircle(icon: Icons.download_outlined, isDark: isDark, onTap: () {}),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _StatBox(value: '${_visibleTodayEntries.length}', label: 'Cows milked', isDark: isDark)),
                          const SizedBox(width: 8),
                          Expanded(child: _StatBox(value: maxE != null ? '${maxE.litres} L' : '—', label: maxE != null ? 'Max — ${maxE.cow}' : 'Max', isDark: isDark)),
                          const SizedBox(width: 8),
                          Expanded(child: _StatBox(value: minE != null ? '${minE.litres} L' : '—', label: minE != null ? 'Min — ${minE.cow}' : 'Min', isDark: isDark)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MilkSummaryScreen(appState: widget.appState))),
                          icon: const Icon(Icons.chevron_right, size: 16, color: VanixColors.greenInk),
                          label: const Text('View complete summary', style: TextStyle(color: VanixColors.greenInk, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: SizedBox(
                    height: 76,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final b in _banners.where((b) => !b.dismissed))
                          Container(
                            width: 262,
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                            decoration: BoxDecoration(color: b.bg, border: Border.all(color: b.border), borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(b.title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: VanixColors.textPrimary)),
                                      Text(b.sub, style: TextStyle(fontSize: 12, color: VanixColors.textHint)),
                                    ],
                                  ),
                                ),
                                IconButton(iconSize: 15, onPressed: () => setState(() => b.dismissed = true), icon: const Icon(Icons.close), color: VanixColors.textHint),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final group in _groupedEntries.entries) ...[
                        Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(group.key.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: VanixColors.textHint))),
                        for (final entry in group.value) _EntryCard(entry: entry, isDark: isDark, onTap: () => _openEntryActions(entry)),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: VanixBottomNav(isDark: isDark, selectedIndex: _navIndex, onTap: _onNavTap, items: buildVanixNavItems(t, widget.appState)),
          ),
        ],
      ),
    );
  }
}

class _PeriodPill extends StatelessWidget {
  final String label;
  final bool isDark;
  final VoidCallback onTap;
  const _PeriodPill({required this.label, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : VanixColors.textPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(border: Border.all(color: VanixColors.border), borderRadius: BorderRadius.circular(16)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor)),
            const SizedBox(width: 6),
            Icon(Icons.keyboard_arrow_down, size: 14, color: textColor),
          ],
        ),
      ),
    );
  }
}

class _IconCircle extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;
  const _IconCircle({required this.icon, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: VanixColors.border)),
        child: Icon(icon, size: 15, color: isDark ? Colors.white : VanixColors.textPrimary),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value, label;
  final bool isDark;
  const _StatBox({required this.value, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF262626) : VanixColors.bgCard, border: Border.all(color: isDark ? const Color(0xFF3A3A3A) : VanixColors.border), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: isDark ? Colors.white : VanixColors.textPrimary)),
          Text(label, style: const TextStyle(fontSize: 11, color: VanixColors.textHint), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  final MilkEntry entry;
  final bool isDark;
  final VoidCallback onTap;
  const _EntryCard({required this.entry, required this.isDark, required this.onTap});

  Color get _boxColor {
    if (entry.litres >= 8) return VanixColors.greenInk;
    if (entry.litres >= 4) return VanixColors.warningInk;
    return VanixColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : VanixColors.textPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: isDark ? const Color(0xFF1C1C1C) : VanixColors.bgCard, border: Border.all(color: isDark ? const Color(0xFF3A3A3A) : VanixColors.border), borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${entry.cow} — ${entry.breed}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(color: isDark ? const Color(0xFF262626) : VanixColors.bgWarm, border: Border.all(color: isDark ? const Color(0xFF3A3A3A) : VanixColors.border), borderRadius: BorderRadius.circular(10)),
                        child: Text(entry.session.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor)),
                      ),
                      const SizedBox(width: 8),
                      Text(entry.time.format(context), style: const TextStyle(fontSize: 13, color: VanixColors.textHint)),
                      const SizedBox(width: 8),
                      if (entry.onTime) const Icon(Icons.check, size: 14, color: VanixColors.greenInk) else const Icon(Icons.schedule, size: 14, color: VanixColors.warningInk),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('${entry.farm} — ${entry.manager}', style: const TextStyle(fontSize: 12, color: VanixColors.textHint)),
                ],
              ),
            ),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: _boxColor, borderRadius: BorderRadius.circular(14)),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${entry.litres}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                  const Text('Ltrs', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
