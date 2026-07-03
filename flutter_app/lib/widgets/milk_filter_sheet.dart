import 'package:flutter/material.dart';
import '../models/milk_models.dart';
import '../theme/vanix_theme.dart';

class MilkFilter {
  final String? farm; // null = all farms
  final MilkSession? session; // null = both
  final String sort; // 'recent' | 'highest' | 'lowest'
  const MilkFilter({this.farm, this.session, this.sort = 'recent'});

  MilkFilter copyWith({String? farm, bool clearFarm = false, MilkSession? session, bool clearSession = false, String? sort}) {
    return MilkFilter(
      farm: clearFarm ? null : (farm ?? this.farm),
      session: clearSession ? null : (session ?? this.session),
      sort: sort ?? this.sort,
    );
  }
}

/// Two-pane filter bottom sheet: category rail (left) + option rows (right).
/// Mirrors #s7-sheet in vanix_screens.html — option rows are always tinted
/// bgWarm, never white, per the design rule.
Future<void> showMilkFilterSheet(BuildContext context, {required MilkFilter current, required ValueChanged<MilkFilter> onApply}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => _FilterSheet(initial: current, onApply: onApply),
  );
}

class _FilterSheet extends StatefulWidget {
  final MilkFilter initial;
  final ValueChanged<MilkFilter> onApply;
  const _FilterSheet({required this.initial, required this.onApply});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late MilkFilter _draft;
  int _cat = 0; // 0 farm, 1 time, 2 sort

  @override
  void initState() {
    super.initState();
    _draft = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1C1C1C) : Colors.white;
    final railBg = isDark ? VanixColors.darkPrimary : VanixColors.bgWarm;
    final textColor = isDark ? Colors.white : VanixColors.textPrimary;

    return Container(
      decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 36, height: 4, margin: const EdgeInsets.only(top: 12), decoration: BoxDecoration(color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor)),
                IconButton(onPressed: () => Navigator.of(context).pop(), icon: Icon(Icons.close, size: 16, color: isDark ? const Color(0xA6FFFFFF) : VanixColors.textHint)),
              ],
            ),
          ),
          SizedBox(
            height: 272,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 126,
                  color: railBg,
                  child: Column(
                    children: [
                      _CatTab(label: 'Farm', active: _cat == 0, onTap: () => setState(() => _cat = 0), isDark: isDark),
                      _CatTab(label: 'Milking time', active: _cat == 1, onTap: () => setState(() => _cat = 1), isDark: isDark),
                      _CatTab(label: 'Sort by', active: _cat == 2, onTap: () => setState(() => _cat = 2), isDark: isDark),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    color: isDark ? const Color(0xFF262626) : VanixColors.bgWarm,
                    padding: const EdgeInsets.all(12),
                    child: _buildOptions(isDark),
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
                widget.onApply(_draft);
                Navigator.of(context).pop();
              },
              child: const Text('Apply'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptions(bool isDark) {
    switch (_cat) {
      case 0:
        return ListView(
          children: [
            _OptRow(label: 'All farms', active: _draft.farm == null, isDark: isDark, onTap: () => setState(() => _draft = _draft.copyWith(clearFarm: true))),
            for (final farm in MilkSeed.farms) _OptRow(label: farm, active: _draft.farm == farm, isDark: isDark, onTap: () => setState(() => _draft = _draft.copyWith(farm: farm))),
          ],
        );
      case 1:
        return ListView(
          children: [
            _OptRow(label: 'Both sessions', active: _draft.session == null, isDark: isDark, onTap: () => setState(() => _draft = _draft.copyWith(clearSession: true))),
            _OptRow(label: 'Morning', active: _draft.session == MilkSession.morning, isDark: isDark, onTap: () => setState(() => _draft = _draft.copyWith(session: MilkSession.morning))),
            _OptRow(label: 'Evening', active: _draft.session == MilkSession.evening, isDark: isDark, onTap: () => setState(() => _draft = _draft.copyWith(session: MilkSession.evening))),
          ],
        );
      case 2:
        return ListView(
          children: [
            _OptRow(label: 'Most recent', active: _draft.sort == 'recent', isDark: isDark, onTap: () => setState(() => _draft = _draft.copyWith(sort: 'recent'))),
            _OptRow(label: 'Highest yield', active: _draft.sort == 'highest', isDark: isDark, onTap: () => setState(() => _draft = _draft.copyWith(sort: 'highest'))),
            _OptRow(label: 'Lowest yield', active: _draft.sort == 'lowest', isDark: isDark, onTap: () => setState(() => _draft = _draft.copyWith(sort: 'lowest'))),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _CatTab extends StatelessWidget {
  final String label;
  final bool active;
  final bool isDark;
  final VoidCallback onTap;
  const _CatTab({required this.label, required this.active, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final activeColor = isDark ? const Color(0xFFF5F5F5) : Colors.white;
    final textColor = isDark ? Colors.white : VanixColors.textPrimary;
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: active ? activeColor : Colors.transparent,
          border: active ? const Border(left: BorderSide(color: VanixColors.greenInk, width: 3)) : null,
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: active ? FontWeight.w600 : FontWeight.w400, color: textColor)),
      ),
    );
  }
}

class _OptRow extends StatelessWidget {
  final String label;
  final bool active;
  final bool isDark;
  final VoidCallback onTap;
  const _OptRow({required this.label, required this.active, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final activeBg = isDark ? const Color(0xFFF5F5F5) : VanixColors.darkPrimary;
    final activeText = isDark ? VanixColors.darkPrimary : Colors.white;
    final inactiveText = isDark ? Colors.white : VanixColors.textPrimary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: AlignmentDirectional.centerStart,
          decoration: BoxDecoration(color: active ? activeBg : Colors.transparent, borderRadius: BorderRadius.circular(12)),
          child: Text(label, style: TextStyle(fontSize: 13, color: active ? activeText : inactiveText)),
        ),
      ),
    );
  }
}
