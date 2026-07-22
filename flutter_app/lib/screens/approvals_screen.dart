import 'package:flutter/material.dart';
import '../i18n/farm_strings.dart';
import '../state/app_state.dart';
import '../theme/vanix_theme.dart';

/// Approvals — opened from the Home dashboard's "Pending Approvals" View
/// All row. Mirrors #page-approvals in vanix_screens_preview.html: back
/// header + "Approvals" title, an All/Pending/Approved/Denied filter chip
/// row, a "Pending Approvals" section on top (each pending item has a
/// Deny/Approve button pair — tapping either resolves it in place and
/// re-renders), followed by a "History" section grouped under date-bucket
/// headers (Today, Yesterday, This Week, Last Week, Last Month — empty
/// buckets skipped). Demo data + bucket cutoffs are computed against a
/// fixed reference "today" of 2026-07-22, matching the HTML mock exactly.
class ApprovalsScreen extends StatefulWidget {
  final AppState appState;
  const ApprovalsScreen({super.key, required this.appState});

  @override
  State<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalItem {
  final String id;
  final String title;
  final String sub;
  final String farm;
  String date;
  String status; // 'pending' | 'approved' | 'denied'
  _ApprovalItem({required this.id, required this.title, required this.sub, required this.farm, required this.date, required this.status});
}

class _ApprovalsScreenState extends State<ApprovalsScreen> {
  // Fixed demo "today" — CLAUDE.md currentDate for this build — so bucket
  // grouping renders identically to the HTML mock, never DateTime.now().
  static final DateTime _today = DateTime(2026, 7, 22);

  String _filter = 'all';

  final List<_ApprovalItem> _data = [
    _ApprovalItem(id: 'a1', title: 'Milk entry edit — Kajri', sub: 'Morning session, 8.2L → 8.6L', farm: 'Green Valley Farm', date: '2026-07-22', status: 'pending'),
    _ApprovalItem(id: 'a2', title: 'Milk entry edit — Gauri', sub: 'Evening session correction requested', farm: 'Sunrise Dairy', date: '2026-07-21', status: 'pending'),
    _ApprovalItem(id: 'a3', title: 'Milk entry edit — Ganga', sub: 'Morning session, 6.0L → 6.4L', farm: 'Sunrise Dairy', date: '2026-07-22', status: 'approved'),
    _ApprovalItem(id: 'a4', title: 'Milk entry delete — Mohini', sub: 'Duplicate evening entry', farm: 'Sunrise Dairy', date: '2026-07-21', status: 'denied'),
    _ApprovalItem(id: 'a5', title: 'Cattle detail edit — Chandni', sub: 'Belt number correction', farm: 'Stones Dairy', date: '2026-07-18', status: 'approved'),
    _ApprovalItem(id: 'a6', title: 'Milk entry edit — Rani', sub: 'Evening session, 5.1L → 7.0L', farm: 'Sunrise Dairy', date: '2026-07-16', status: 'denied'),
    _ApprovalItem(id: 'a7', title: 'Cattle detail edit — Lakshmi', sub: 'Breed field correction', farm: 'Green Villa', date: '2026-07-10', status: 'approved'),
    _ApprovalItem(id: 'a8', title: 'Milk entry edit — Devi', sub: 'Morning session, 7.4L → 7.9L', farm: 'Stones Dairy', date: '2026-07-08', status: 'approved'),
    _ApprovalItem(id: 'a9', title: 'Cattle detail edit — Meera', sub: 'Age correction', farm: 'Green Villa', date: '2026-06-15', status: 'denied'),
    _ApprovalItem(id: 'a10', title: 'Milk entry edit — Kaveri', sub: 'Evening session, 6.6L → 6.8L', farm: 'Green Villa', date: '2026-06-10', status: 'approved'),
  ];

  String get _lang => widget.appState.languageCode;
  bool get _isDark => widget.appState.isDark;
  String _t(String k) => FS.t(_lang, k);

  Color get _cardBg => _isDark ? VanixColors.darkSecond : VanixColors.bgCard;
  Color get _text1 => _isDark ? Colors.white : VanixColors.textPrimary;
  Color get _border => _isDark ? VanixColors.darkBorder : VanixColors.border;
  Color get _divider => _isDark ? VanixColors.darkDivider : VanixColors.divider;

  int _daysAgo(String iso) {
    final d = DateTime.parse(iso);
    return _today.difference(d).inDays;
  }

  // 'today' | 'yesterday' | 'thisWeek' | 'lastWeek' | 'lastMonth'
  String _bucketFor(String iso) {
    final n = _daysAgo(iso);
    if (n <= 0) return 'today';
    if (n == 1) return 'yesterday';
    if (n <= 6) return 'thisWeek';
    if (n <= 13) return 'lastWeek';
    return 'lastMonth';
  }

  static const _bucketOrder = ['today', 'yesterday', 'thisWeek', 'lastWeek', 'lastMonth'];
  static const _bucketKey = {
    'today': 'dashToday',
    'yesterday': 'dashYesterday',
    'thisWeek': 'bucketThisWeek',
    'lastWeek': 'bucketLastWeek',
    'lastMonth': 'bucketLastMonth',
  };

  void _resolve(_ApprovalItem item, String status) {
    setState(() {
      item.status = status;
      item.date = '2026-07-22';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        final theme = _isDark ? vanixDarkTheme(languageCode: _lang) : vanixLightTheme(languageCode: _lang);
        final matches = _data.where((it) => _filter == 'all' || it.status == _filter).toList();
        final pending = matches.where((it) => it.status == 'pending').toList();
        final rest = matches.where((it) => it.status != 'pending').toList();
        final buckets = <String, List<_ApprovalItem>>{};
        for (final it in rest) {
          buckets.putIfAbsent(_bucketFor(it.date), () => []).add(it);
        }
        final hasHistory = _bucketOrder.any((b) => (buckets[b]?.isNotEmpty ?? false));

        return Theme(
          data: theme,
          child: Scaffold(
            backgroundColor: VanixColors.bgWarm,
            body: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _header(),
                  _filterChips(),
                  Expanded(
                    child: (!pending.isNotEmpty && !hasHistory)
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Text(_t('noApprovalsWord'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: VanixColors.textHint)),
                            ),
                          )
                        : ListView(
                            padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 40),
                            children: [
                              if (pending.isNotEmpty) ...[
                                _sectionLabel(_t('approvalsPendingHeader')),
                                for (final it in pending) _approvalRow(it, showActions: true),
                              ],
                              if (hasHistory) ...[
                                Padding(
                                  padding: EdgeInsetsDirectional.only(top: pending.isNotEmpty ? 20 : 0),
                                  child: _sectionLabel(_t('approvalsHistoryHeader')),
                                ),
                                for (final b in _bucketOrder)
                                  if (buckets[b]?.isNotEmpty ?? false) ...[
                                    Padding(
                                      padding: const EdgeInsetsDirectional.only(top: 14, bottom: 8),
                                      child: Text(_t(_bucketKey[b]!), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _isDark ? Colors.white70 : VanixColors.textHint)),
                                    ),
                                    for (final it in buckets[b]!) _approvalRow(it, showActions: false),
                                  ],
                              ],
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsetsDirectional.only(bottom: 10),
        child: Text(text.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: VanixColors.textHint)),
      );

  Widget _header() {
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: VanixColors.bgWarm,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 28, offset: const Offset(0, 12))],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: IconButton(
              padding: EdgeInsets.zero,
              style: IconButton.styleFrom(backgroundColor: _cardBg, shape: const CircleBorder()),
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(Icons.chevron_left, size: 20, color: _text1),
            ),
          ),
          const SizedBox(width: 10),
          Text(_t('approvalsPageTitle'), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: _text1)),
        ],
      ),
    );
  }

  Widget _filterChips() {
    final filters = ['all', 'pending', 'approved', 'denied'];
    final labels = {'all': _t('allWord'), 'pending': _t('statusPending'), 'approved': _t('approvedWord'), 'denied': _t('deniedWord')};
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 0),
      child: SizedBox(
        height: 34,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: filters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final f = filters[i];
            final on = _filter == f;
            return InkWell(
              onTap: () => setState(() => _filter = f),
              borderRadius: BorderRadius.circular(17),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: on ? VanixColors.greenInk : _border, width: on ? 1.4 : 1),
                ),
                child: Text(labels[f]!, style: TextStyle(fontSize: 13, fontWeight: on ? FontWeight.w600 : FontWeight.w500, color: on ? VanixColors.greenInk : _text1)),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _statusPill(String status) {
    final color = status == 'pending' ? VanixColors.warning : (status == 'approved' ? VanixColors.greenInk : VanixColors.danger);
    final key = status == 'pending' ? 'statusPending' : (status == 'approved' ? 'approvedWord' : 'deniedWord');
    return Text(_t(key).toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: color));
  }

  Widget _approvalRow(_ApprovalItem item, {required bool showActions}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16), BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 3, offset: const Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(item.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _text1))),
              const SizedBox(width: 10),
              _statusPill(item.status),
            ],
          ),
          const SizedBox(height: 3),
          Text(item.sub, style: const TextStyle(fontSize: 12, color: VanixColors.textHint)),
          const SizedBox(height: 4),
          Text(item.farm, style: const TextStyle(fontSize: 11, color: VanixColors.textHint)),
          if (showActions) ...[
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
                  onPressed: () => _resolve(item, 'denied'),
                  child: Text('✕ ${_t('denyWord')}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
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
                  onPressed: () => _resolve(item, 'approved'),
                  child: Text('✓ ${_t('approveWord')}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ),
            ]),
          ],
        ],
      ),
    );
  }
}
