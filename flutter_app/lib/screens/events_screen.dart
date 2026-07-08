import 'dart:async';
import 'package:flutter/material.dart';
import '../i18n/strings.dart';
import '../state/app_state.dart';
import '../theme/vanix_theme.dart';
import '../widgets/vanix_bottom_nav.dart';
import '../widgets/vanix_nav_items.dart';
import 'card_detail_screen.dart';
import 'heat_alert_screen.dart';
import 'milk_log_screen.dart';

enum _Tab { all, action, warnings, reminders }

/// Onboarded vets — contacting a vet is a pick, not a manual email entry.
/// Mirrors ONBOARDED_VETS in vanix_screens.html.
const List<String> kOnboardedVets = ['Dr. Sharma', 'Dr. Rao', 'Dr. Iyer'];

/// The four insemination methods a farmer can log. Mirrors INSEM_METHODS in
/// vanix_screens.html.
const List<String> kInseminationMethods = ['Artificial', 'Conventional', 'IVF', 'Embryo Transfer'];

/// Segmented 24h heat-window bar — 6h pre / 12h optimal / 6h suboptimal with
/// zone labels, detection/end times, and a single fill travelling across all
/// three segments. Mirrors #ev-heat-bar-wrap in vanix_screens.html.
class _HeatWindowBar extends StatelessWidget {
  final double simHours;
  final Color fillColor;
  const _HeatWindowBar({required this.simHours, required this.fillColor});

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.4, color: VanixColors.textHint);
    const timeStyle = TextStyle(fontSize: 10, color: VanixColors.textHint);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Expanded(flex: 25, child: Text('PRE 6h', textAlign: TextAlign.center, style: labelStyle)),
            Expanded(flex: 50, child: Text('OPTIMAL 12h', textAlign: TextAlign.center, style: labelStyle)),
            Expanded(flex: 25, child: Text('SUBOPT 6h', textAlign: TextAlign.center, style: labelStyle)),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 8,
            child: Stack(
              children: [
                const Positioned.fill(
                  child: Row(
                    children: [
                      Expanded(flex: 25, child: ColoredBox(color: VanixColors.warningBg)),
                      Expanded(flex: 50, child: ColoredBox(color: VanixColors.activeBg)),
                      Expanded(flex: 25, child: ColoredBox(color: VanixColors.dangerBg)),
                    ],
                  ),
                ),
                Positioned.fill(
                  child: Row(
                    children: [
                      const Spacer(flex: 25),
                      Container(width: 1, color: Colors.black.withOpacity(0.18)),
                      const Spacer(flex: 50),
                      Container(width: 1, color: Colors.black.withOpacity(0.18)),
                      const Spacer(flex: 25),
                    ],
                  ),
                ),
                Positioned.fill(
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: FractionallySizedBox(
                      widthFactor: (simHours / 24).clamp(0.0, 1.0),
                      heightFactor: 1,
                      child: Opacity(opacity: 0.85, child: ColoredBox(color: fillColor)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 3),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('04:30 detected', style: timeStyle),
            Text('+24h · 04:30', style: timeStyle),
          ],
        ),
      ],
    );
  }
}

/// Icon + short word for button labels — replaces full-sentence CTAs
/// ("No, she's fine") with a quick icon + 1 word so the card reads at a
/// glance ("less text, more pictorial" — farmer-friendly pass).
Widget _iconLabel(IconData icon, String label) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16),
      const SizedBox(width: 6),
      Text(label),
    ],
  );
}

/// 2x2 grid of method-select buttons, shared by the real Heat card and the
/// "View full cycle" walkthrough's own heat step. Mirrors seqMethodBtn() in
/// vanix_screens.html.
Widget _inseminationMethodGrid(String selected, ValueChanged<String> onSelect, {bool isDark = false}) {
  return GridView.count(
    crossAxisCount: 2,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    mainAxisSpacing: 8,
    crossAxisSpacing: 8,
    childAspectRatio: 2.6,
    children: kInseminationMethods.map((m) {
      final on = m == selected;
      return OutlinedButton(
        style: OutlinedButton.styleFrom(backgroundColor: on ? VanixColors.darkPrimary : null, foregroundColor: on ? Colors.white : (isDark ? const Color(0xFFF5F5F5) : VanixColors.textPrimary)),
        onPressed: () => onSelect(m),
        child: Text(m, textAlign: TextAlign.center),
      );
    }).toList(),
  );
}

/// Shared by every P0 card (Fever / Abortion / Fresh Cow) — diagnostic
/// confirm -> vet email -> requested. Mirrors evVetRequestFlow() in
/// vanix_screens.html.
enum _VetFlowState { initial, falseAlarm, awaitingEmail, requested }

/// Heat is a single evolving card, not a state machine of separate alerts.
/// Detection starts a real 24h clock (`_heatStartedAt`) immediately; Yes/No
/// is just the farmer's acknowledgement and does not pause/reset the clock.
/// `dismissed`/`logged`/`expired` are terminal; while `active`, the visible
/// phase (pre/optimal/suboptimal) is derived from elapsed time every tick.
enum _HeatState { initial, dismissed, active, logged, expired, missed }
enum _PregState { initial, failed, confirmed }

/// Shared by every P2 diagnostic card (Mastitis / Lameness / Ketosis) —
/// confirm -> flagged for physical inspection, no vet email. Mirrors
/// evInspectionFlow() in vanix_screens.html.
enum _InspectState { initial, falseAlarm, flagged }

/// Shared by every single-acknowledge card (Proestrus / Herd Heat Stress /
/// Calibration Complete). Mirrors evAcknowledgeFlow() in vanix_screens.html.
enum _AckState { initial, acknowledged }

/// Gestation is its own evolving card (like Heat) — 3/6/9-month vet checks,
/// call-vet-for-delivery (vet picker), then delivery confirmed w/ notes.
/// Only the final `delivered` state calls resolveEvent().
enum _GestationState { check3, check6, callVet, deliveryAsk, deliveryForm, deliveryFailed, delivered }

/// Milking notification — fires once gestation resolves. "Remind me later"
/// loops back to pending on a compressed timer without touching the badge;
/// only "Yes, add" resolves it.
enum _MilkingNotifState { pending, reminded, added }

/// End-of-lactation check-in — reached via the walkthrough's skip-ahead.
/// "Still milking" loops back to pending on a compressed timer without
/// touching the badge; only "Entered resting period" resolves it.
enum _LactationCheckState { pending, stillMilking, resting }

/// Events — mirrors #page-events in vanix_screens.html: All / Needs action /
/// Reminders tabs, 11 action cards spanning the P0-P3 priority matrix from
/// Cattle Health Logic v3.1 (Block 7 — Alert & Feedback), reminders, and a
/// date-grouped history timeline. Card resolution calls
/// AppState.resolveEvent() so the badge/dot stays synced with every other
/// nav on screen (Home, Milk Log) exactly like the JS evUpdateBadges().
class EventsScreen extends StatefulWidget {
  final AppState appState;
  const EventsScreen({super.key, required this.appState});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final int _navIndex = 3;
  _Tab _tab = _Tab.all;

  // P0 — critical
  _VetFlowState _fever = _VetFlowState.initial;
  _VetFlowState _abort = _VetFlowState.initial;
  _VetFlowState _freshCow = _VetFlowState.initial;
  String _feverVetName = '';
  String _abortVetName = '';
  String _freshCowVetName = '';

  // P1 — actionable
  _HeatState _heat = _HeatState.initial;
  bool _heatConfirmed = false;
  String _heatMethod = kInseminationMethods.first;
  final _heatTechCtrl = TextEditingController();
  String _heatLateMethod = kInseminationMethods.first;
  final _heatLateTimeCtrl = TextEditingController();
  final _heatLateTechCtrl = TextEditingController();
  bool _heatShowLateForm = false;
  late final DateTime _heatStartedAt;
  Timer? _heatTimer;
  // DEMO: 1 simulated hour = 4 real seconds (24h cycle plays out in 96s)
  // purely so the phase transitions are demoable live — replace with the
  // real backend peak_timestamp once wired up (Cattle Health Logic v3.1,
  // Block 7).
  static const double _simHoursPerSecond = 0.25;
  // Start-insemination flow: idle (button showing) | confirm (off-window
  // warning) | form (method/technician entry). Mirrors the JS substates.
  String _heatFormStage = 'idle';

  _PregState _preg = _PregState.initial;

  _GestationState _gestation = _GestationState.check3;
  String _gestationVetName = '';
  final _gestationNotesCtrl = TextEditingController();

  bool _milkingNotifShown = false;
  _MilkingNotifState _milkingNotif = _MilkingNotifState.pending;
  Timer? _milkingRemindTimer;

  _LactationCheckState _lactationCheck = _LactationCheckState.pending;
  Timer? _lactationRecheckTimer;

  // P2 — warning
  _InspectState _mastitis = _InspectState.initial;
  _InspectState _lameness = _InspectState.initial;
  _InspectState _ketosis = _InspectState.initial;
  _AckState _proestrus = _AckState.initial;

  // P3 — info
  _AckState _herdStress = _AckState.initial;
  _AckState _calib = _AckState.initial;

  @override
  void initState() {
    super.initState();
    _heatStartedAt = DateTime.now();
    _heatTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      final ticking = _heat == _HeatState.initial || _heat == _HeatState.active;
      if (!ticking) return;
      if (_heatElapsedSimHours >= 24) {
        setState(() => _heat = _HeatState.expired);
        _heatTimer?.cancel();
        return;
      }
      setState(() {});
    });
  }

  double get _heatElapsedSimHours => DateTime.now().difference(_heatStartedAt).inMilliseconds / 1000 * _simHoursPerSecond;

  @override
  void dispose() {
    _heatTimer?.cancel();
    _heatTechCtrl.dispose();
    _heatLateTimeCtrl.dispose();
    _heatLateTechCtrl.dispose();
    _gestationNotesCtrl.dispose();
    _milkingRemindTimer?.cancel();
    _lactationRecheckTimer?.cancel();
    super.dispose();
  }

  void _onNavTap(int i) {
    if (i == 0) {
      Navigator.of(context).pop();
      return;
    }
    if (i == 2) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => MilkLogScreen(appState: widget.appState)));
      return;
    }
    if (i == 4) widget.appState.toggleDark();
  }

  Future<void> _showFullCycleSheet(BuildContext context) async {
    final result = await Navigator.of(context).push<String?>(MaterialPageRoute(builder: (_) => HeatAlertScreen(isDark: widget.appState.isDark), fullscreenDialog: true));
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FullCycleSheet(isDark: widget.appState.isDark, heatPreDecision: result, restricted: result == null),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.appState.isDark;
    final t = VanixStrings.of(widget.appState.languageCode);
    final textColor = isDark ? Colors.white : VanixColors.textPrimary;
    final openCount = widget.appState.openEventsCount;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 120),
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                  decoration: BoxDecoration(color: isDark ? VanixColors.darkPrimary : VanixColors.bgWarm, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 28, offset: const Offset(0, 12))]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Events', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: textColor)),
                          _CountPill(count: openCount),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(child: Text('Health, breeding and reminders across all your farms', style: TextStyle(fontSize: 12, color: VanixColors.textHint))),
                          TextButton(
                            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                            onPressed: () => _showFullCycleSheet(context),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('View full cycle', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? VanixColors.greenDeep : VanixColors.greenInk)),
                                Icon(Icons.chevron_right, size: 14, color: isDark ? VanixColors.greenDeep : VanixColors.greenInk),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Row(
                    children: [
                      _TabChip(label: 'All', active: _tab == _Tab.all, isDark: isDark, onTap: () => setState(() => _tab = _Tab.all)),
                      const SizedBox(width: 8),
                      _TabChip(label: 'Needs action', active: _tab == _Tab.action, isDark: isDark, onTap: () => setState(() => _tab = _Tab.action)),
                      const SizedBox(width: 8),
                      _TabChip(label: 'Warnings', active: _tab == _Tab.warnings, isDark: isDark, onTap: () => setState(() => _tab = _Tab.warnings)),
                      const SizedBox(width: 8),
                      _TabChip(label: 'Reminders', active: _tab == _Tab.reminders, isDark: isDark, onTap: () => setState(() => _tab = _Tab.reminders)),
                    ],
                  ),
                ),
                if (_tab == _Tab.all || _tab == _Tab.action)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionLabel('Needs action'),
                        const SizedBox(height: 10),
                        _buildFeverCard(isDark),
                        const SizedBox(height: 10),
                        _buildAbortCard(isDark),
                        const SizedBox(height: 10),
                        _buildFreshCowCard(isDark),
                        const SizedBox(height: 10),
                        _buildHeatCard(isDark),
                        const SizedBox(height: 10),
                        _buildPregCard(isDark),
                        const SizedBox(height: 10),
                        _buildGestationCard(isDark),
                        const SizedBox(height: 10),
                        if (_milkingNotifShown) ...[
                          _buildMilkingNotifCard(isDark),
                          const SizedBox(height: 10),
                        ],
                        _buildLactationCheckCard(isDark),
                        const SizedBox(height: 10),
                        _buildMastitisCard(isDark),
                        const SizedBox(height: 10),
                        _buildLamenessCard(isDark),
                        const SizedBox(height: 10),
                        _buildKetosisCard(isDark),
                      ],
                    ),
                  ),
                if (_tab == _Tab.all || _tab == _Tab.warnings)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionLabel('Warnings'),
                        const SizedBox(height: 10),
                        _buildProestrusCard(isDark),
                        const SizedBox(height: 10),
                        _buildHerdStressCard(isDark),
                        const SizedBox(height: 10),
                        _buildCalibCard(isDark),
                      ],
                    ),
                  ),
                if (_tab == _Tab.all || _tab == _Tab.reminders)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionLabel('Reminders'),
                        const SizedBox(height: 10),
                        _ReminderCard(icon: Icons.child_care, title: 'Delivery approaching — Dhauli', sub: 'Expected around 12 Jul — prepare the calving pen. She starts milking after calving.', startDate: DateTime(2026, 6, 28), dueDate: DateTime(2026, 7, 12), isDark: isDark),
                        const SizedBox(height: 8),
                        _ReminderCard(icon: Icons.vaccines_outlined, title: 'FMD vaccination due', sub: '5 cows at Green Valley Farm — due 8 Jul', startDate: DateTime(2026, 6, 28), dueDate: DateTime(2026, 7, 8), isDark: isDark),
                        const SizedBox(height: 8),
                        _ReminderCard(icon: Icons.medical_services_outlined, title: 'Quarterly vet check-up', sub: 'Sunrise Dairy — 15 Jul, Dr. Sharma', startDate: DateTime(2026, 6, 24), dueDate: DateTime(2026, 7, 15), isDark: isDark),
                      ],
                    ),
                  ),
                if (_tab == _Tab.all)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionLabel('History'),
                        const SizedBox(height: 10),
                        Text('YESTERDAY — 2 JUL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: VanixColors.textHint)),
                        const SizedBox(height: 8),
                        _HistoryRow(dotColor: VanixColors.greenDeep, title: 'Calved — Ganga', stage: 'MILKING', stageColor: VanixColors.greenInk, sub: 'Healthy calf at 05:40 — Ganga now appears in the Milk Log', time: '05:40', isDark: isDark),
                        _HistoryRow(dotColor: VanixColors.warning, title: 'Pregnancy failed — Lakshmi', stage: 'HEAT WATCH', stageColor: VanixColors.warningInk, sub: 'Heat returned on day 16 of the 21-day watch — cycle restarted', time: '14:05', isDark: isDark),
                        const SizedBox(height: 12),
                        Text('30 JUN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: VanixColors.textHint)),
                        const SizedBox(height: 8),
                        _HistoryRow(dotColor: VanixColors.danger, title: 'Vet appointment completed — Bhoori', stage: 'RECOVERED', stageColor: VanixColors.greenInk, sub: 'Fever treated by Dr. Sharma — temperature back to normal', time: '11:30', isDark: isDark),
                        _HistoryRow(dotColor: VanixColors.greenDeep, title: 'Inseminated — Mohini', stage: '21-DAY WATCH', stageColor: VanixColors.greenInk, sub: 'Within the 18h window — pregnancy check set for 3 Jul', time: '09:15', isDark: isDark),
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

  // ── P0: Fever ──
  Widget _buildFeverCard(bool isDark) {
    const manager = 'Ramesh Kumar';
    switch (_fever) {
      case _VetFlowState.initial:
        return _ActionCard(
          isDark: isDark,
          bg: VanixColors.dangerBg,
          border: VanixColors.danger,
          escalated: true,
          priority: _Priority.p0,
          channel: 'Push + SMS · Immediate vet visit',
          manager: manager,
          title: 'Suspected fever — Kajri',
          sub: 'Sustained high temperature for 3 days with very little movement — she has mostly stayed in one spot.',
          meta: 'Green Valley Farm · Belt 63 · since 30 Jun',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(padding: EdgeInsets.only(top: 12, bottom: 10), child: Text('Does Kajri look unwell to you?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => setState(() { _fever = _VetFlowState.falseAlarm; widget.appState.resolveEvent(); }), child: const Text("No, she's fine"))),
                  const SizedBox(width: 8),
                  Expanded(flex: 2, child: ElevatedButton(onPressed: () => setState(() => _fever = _VetFlowState.awaitingEmail), child: const Text("Yes, it's fever"))),
                ],
              ),
            ],
          ),
        );
      case _VetFlowState.falseAlarm:
        return _ActionCard(
          isDark: isDark,
          bg: VanixColors.bgCard,
          border: VanixColors.border,
          priority: _Priority.p0,
          channel: 'Push + SMS · Immediate vet visit',
          manager: manager,
          title: 'Suspected fever — Kajri',
          sub: 'Sustained high temperature for 3 days with very little movement — she has mostly stayed in one spot.',
          meta: 'Green Valley Farm · Belt 63 · since 30 Jun',
          child: const Padding(padding: EdgeInsets.only(top: 12), child: Text('Marked as false alarm — monitoring continues. The owner has been notified.', style: TextStyle(fontSize: 13, color: VanixColors.textHint))),
        );
      case _VetFlowState.awaitingEmail:
        return _ActionCard(
          isDark: isDark,
          bg: VanixColors.dangerBg,
          border: VanixColors.danger,
          priority: _Priority.p0,
          channel: 'Push + SMS · Immediate vet visit',
          manager: manager,
          title: 'Suspected fever — Kajri',
          sub: 'Sustained high temperature for 3 days with very little movement — she has mostly stayed in one spot.',
          meta: 'Green Valley Farm · Belt 63 · since 30 Jun',
          child: _vetPicker((vetName) => setState(() { _feverVetName = vetName; _fever = _VetFlowState.requested; widget.appState.resolveEvent(); })),
        );
      case _VetFlowState.requested:
        return _ActionCard(
          isDark: isDark,
          bg: VanixColors.activeBg,
          border: VanixColors.greenDeep,
          priority: _Priority.p0,
          channel: 'Push + SMS · Immediate vet visit',
          manager: manager,
          title: 'Suspected fever — Kajri',
          sub: 'Sustained high temperature for 3 days with very little movement — she has mostly stayed in one spot.',
          meta: 'Green Valley Farm · Belt 63 · since 30 Jun',
          child: _vetRequestedMessage('Kajri · Fever · Green Valley Farm', _feverVetName),
        );
    }
  }

  // ── P0: Abortion / pregnancy loss ──
  Widget _buildAbortCard(bool isDark) {
    const manager = 'Suresh Yadav';
    switch (_abort) {
      case _VetFlowState.initial:
        return _ActionCard(
          isDark: isDark,
          bg: VanixColors.dangerBg,
          border: VanixColors.danger,
          priority: _Priority.p0,
          channel: 'Push + SMS · Immediate vet visit',
          manager: manager,
          title: 'Possible pregnancy loss — Mohini',
          sub: 'Sudden drop in rumination with a sustained temperature rise over the last 3 hours.',
          meta: 'Sunrise Dairy · Belt 91 · Day 48 of pregnancy',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(padding: EdgeInsets.only(top: 12, bottom: 10), child: Text('Does Mohini show these signs?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => setState(() { _abort = _VetFlowState.falseAlarm; widget.appState.resolveEvent(); }), child: const Text("No, she's fine"))),
                  const SizedBox(width: 8),
                  Expanded(flex: 2, child: ElevatedButton(onPressed: () => setState(() => _abort = _VetFlowState.awaitingEmail), child: const Text('Yes, report to vet'))),
                ],
              ),
            ],
          ),
        );
      case _VetFlowState.falseAlarm:
        return _ActionCard(
          isDark: isDark,
          bg: VanixColors.bgCard,
          border: VanixColors.border,
          priority: _Priority.p0,
          channel: 'Push + SMS · Immediate vet visit',
          manager: manager,
          title: 'Possible pregnancy loss — Mohini',
          sub: 'Sudden drop in rumination with a sustained temperature rise over the last 3 hours.',
          meta: 'Sunrise Dairy · Belt 91 · Day 48 of pregnancy',
          child: const Padding(padding: EdgeInsets.only(top: 12), child: Text('Marked as false alarm — monitoring continues.', style: TextStyle(fontSize: 13, color: VanixColors.textHint))),
        );
      case _VetFlowState.awaitingEmail:
        return _ActionCard(
          isDark: isDark,
          bg: VanixColors.dangerBg,
          border: VanixColors.danger,
          priority: _Priority.p0,
          channel: 'Push + SMS · Immediate vet visit',
          manager: manager,
          title: 'Possible pregnancy loss — Mohini',
          sub: 'Sudden drop in rumination with a sustained temperature rise over the last 3 hours.',
          meta: 'Sunrise Dairy · Belt 91 · Day 48 of pregnancy',
          child: _vetPicker((vetName) => setState(() { _abortVetName = vetName; _abort = _VetFlowState.requested; widget.appState.resolveEvent(); })),
        );
      case _VetFlowState.requested:
        return _ActionCard(
          isDark: isDark,
          bg: VanixColors.activeBg,
          border: VanixColors.greenDeep,
          priority: _Priority.p0,
          channel: 'Push + SMS · Immediate vet visit',
          manager: manager,
          title: 'Possible pregnancy loss — Mohini',
          sub: 'Sudden drop in rumination with a sustained temperature rise over the last 3 hours.',
          meta: 'Sunrise Dairy · Belt 91 · Day 48 of pregnancy',
          child: _vetRequestedMessage('Mohini · Pregnancy loss · Sunrise Dairy', _abortVetName),
        );
    }
  }

  // ── P0: Fresh cow / post-calving monitor ──
  Widget _buildFreshCowCard(bool isDark) {
    const manager = 'Ramesh Kumar';
    switch (_freshCow) {
      case _VetFlowState.initial:
        return _ActionCard(
          isDark: isDark,
          bg: VanixColors.dangerBg,
          border: VanixColors.danger,
          priority: _Priority.p0,
          channel: 'Push + SMS · Immediate vet visit',
          manager: manager,
          title: 'Fresh cow health dip — Ganga',
          sub: 'Calved 6 days ago and her health score has dropped — early days post-calving carry higher metabolic risk.',
          meta: 'Green Valley Farm · Belt 27 · Day 6 post-calving',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(padding: EdgeInsets.only(top: 12, bottom: 10), child: Text('Does Ganga seem off to you?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => setState(() { _freshCow = _VetFlowState.falseAlarm; widget.appState.resolveEvent(); }), child: const Text("No, she's fine"))),
                  const SizedBox(width: 8),
                  Expanded(flex: 2, child: ElevatedButton(onPressed: () => setState(() => _freshCow = _VetFlowState.awaitingEmail), child: const Text('Yes, report to vet'))),
                ],
              ),
            ],
          ),
        );
      case _VetFlowState.falseAlarm:
        return _ActionCard(
          isDark: isDark,
          bg: VanixColors.bgCard,
          border: VanixColors.border,
          priority: _Priority.p0,
          channel: 'Push + SMS · Immediate vet visit',
          manager: manager,
          title: 'Fresh cow health dip — Ganga',
          sub: 'Calved 6 days ago and her health score has dropped — early days post-calving carry higher metabolic risk.',
          meta: 'Green Valley Farm · Belt 27 · Day 6 post-calving',
          child: const Padding(padding: EdgeInsets.only(top: 12), child: Text('Marked as false alarm — monitoring continues.', style: TextStyle(fontSize: 13, color: VanixColors.textHint))),
        );
      case _VetFlowState.awaitingEmail:
        return _ActionCard(
          isDark: isDark,
          bg: VanixColors.dangerBg,
          border: VanixColors.danger,
          priority: _Priority.p0,
          channel: 'Push + SMS · Immediate vet visit',
          manager: manager,
          title: 'Fresh cow health dip — Ganga',
          sub: 'Calved 6 days ago and her health score has dropped — early days post-calving carry higher metabolic risk.',
          meta: 'Green Valley Farm · Belt 27 · Day 6 post-calving',
          child: _vetPicker((vetName) => setState(() { _freshCowVetName = vetName; _freshCow = _VetFlowState.requested; widget.appState.resolveEvent(); })),
        );
      case _VetFlowState.requested:
        return _ActionCard(
          isDark: isDark,
          bg: VanixColors.activeBg,
          border: VanixColors.greenDeep,
          priority: _Priority.p0,
          channel: 'Push + SMS · Immediate vet visit',
          manager: manager,
          title: 'Fresh cow health dip — Ganga',
          sub: 'Calved 6 days ago and her health score has dropped — early days post-calving carry higher metabolic risk.',
          meta: 'Green Valley Farm · Belt 27 · Day 6 post-calving',
          child: _vetRequestedMessage('Ganga · Post-calving · Green Valley Farm', _freshCowVetName),
        );
    }
  }

  // shared onboarded-vet picker + send button (P0 cards)
  Widget _vetPicker(ValueChanged<String> onSent) {
    return _VetPicker(onSent: onSent);
  }

  Widget _vetRequestedMessage(String context, String vetName) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Vet appointment requested ✓', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: VanixColors.greenInk)),
          Text("Sent to ${vetName.isEmpty ? kOnboardedVets.first : vetName} — $context. You'll be notified when the vet confirms.", style: const TextStyle(fontSize: 12, color: VanixColors.textHint)),
        ],
      ),
    );
  }

  // ── P1: Heat cycle → insemination window ──
  // Single evolving card: the confirm question and the ticking phase display
  // appear together (detection already started the clock). Yes/No only
  // acknowledges; it does not pause/reset the automatic pre→optimal→
  // suboptimal progression.
  Widget _buildHeatCard(bool isDark) {
    const manager = 'Ramesh Kumar';
    const title = 'Heat cycle detected — Gauri';
    const sub = 'Temperature swinging up and down with high movement since 04:30 this morning.';
    const meta = 'Green Valley Farm · Belt 41 · detected 04:30';

    if (_heat == _HeatState.dismissed) {
      return _ActionCard(
        isDark: isDark,
        bg: VanixColors.bgCard,
        border: VanixColors.border,
        priority: _Priority.p1,
        channel: 'App notification · Schedule inseminator',
          manager: manager,
        title: title,
        sub: sub,
        meta: 'Green Valley Farm · Belt 41',
        child: const Padding(padding: EdgeInsets.only(top: 12), child: Text('Marked as not in heat — monitoring continues.', style: TextStyle(fontSize: 13, color: VanixColors.textHint))),
      );
    }
    if (_heat == _HeatState.missed) {
      return _ActionCard(
        isDark: isDark,
        bg: VanixColors.bgCard,
        border: VanixColors.border,
        priority: _Priority.p1,
        channel: 'App notification · Schedule inseminator',
          manager: manager,
        title: title,
        sub: sub,
        meta: 'Green Valley Farm · Belt 41',
        child: const Padding(padding: EdgeInsets.only(top: 12), child: Text('Insemination missed — logged. Heat cycle monitoring resumes.', style: TextStyle(fontSize: 13, color: VanixColors.textHint))),
      );
    }
    if (_heat == _HeatState.expired) {
      return _ActionCard(
        isDark: isDark,
        bg: VanixColors.warningBg,
        border: VanixColors.warning,
        priority: _Priority.p1,
        channel: 'App notification · Schedule inseminator',
          manager: manager,
        title: title,
        sub: sub,
        meta: 'Green Valley Farm · Belt 41',
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Window expired', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const Padding(padding: EdgeInsets.only(top: 4), child: Text('Insemination window has closed. Was Gauri inseminated?', style: TextStyle(fontSize: 12, color: VanixColors.textHint))),
              if (!_heatShowLateForm) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(flex: 3, child: OutlinedButton(onPressed: () => setState(() { _heat = _HeatState.missed; widget.appState.resolveEvent(); }), child: const Text('Insemination missed', style: TextStyle(fontSize: 12.5)))),
                    const SizedBox(width: 8),
                    Expanded(flex: 2, child: ElevatedButton(onPressed: () => setState(() => _heatShowLateForm = true), child: const Text('Cow inseminated', style: TextStyle(fontSize: 12.5)))),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 10),
                const Text('Log insemination', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                _inseminationMethodGrid(_heatLateMethod, (m) => setState(() => _heatLateMethod = m), isDark: isDark),
                const SizedBox(height: 8),
                TextField(controller: _heatLateTimeCtrl, decoration: const InputDecoration(hintText: 'Time of insemination (e.g. 14:30)')),
                const SizedBox(height: 8),
                TextField(controller: _heatLateTechCtrl, decoration: const InputDecoration(hintText: 'Technician / vet name (optional)')),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => setState(() { _heatMethod = _heatLateMethod; _heat = _HeatState.logged; widget.appState.resolveEvent(); }),
                    child: const Text('Log insemination'),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }
    if (_heat == _HeatState.logged) {
      return _ActionCard(
        isDark: isDark,
        bg: VanixColors.activeBg,
        border: VanixColors.greenDeep,
        priority: _Priority.p1,
        channel: 'App notification · Schedule inseminator',
          manager: manager,
        title: title,
        sub: sub,
        meta: 'Green Valley Farm · Belt 41',
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Insemination logged ✓ — 21-day watch started', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: VanixColors.greenInk)),
              Text(
                "Method: $_heatMethod${_heatShowLateForm && _heatLateTimeCtrl.text.isNotEmpty ? ' · ${_heatLateTimeCtrl.text}' : ''}${(_heatShowLateForm ? _heatLateTechCtrl.text : _heatTechCtrl.text).isNotEmpty ? ' · ${_heatShowLateForm ? _heatLateTechCtrl.text : _heatTechCtrl.text}' : ''}. If no heat returns by 24 Jul, you'll get a pregnancy-check alert. If heat returns earlier, the cycle restarts.",
                style: const TextStyle(fontSize: 12, color: VanixColors.textHint),
              ),
            ],
          ),
        ),
      );
    }

    // _HeatState.initial or .active — same evolving display, driven by _heatElapsedSimHours.
    final h = _heatElapsedSimHours;
    String label;
    Color color;
    if (h < 6) {
      label = 'Pre-insemination — window opens in ${(6 - h).ceil()}h';
      color = VanixColors.warningInk;
    } else if (h < 18) {
      label = 'Optimal window — ${(18 - h).ceil()}h left';
      color = VanixColors.greenInk;
    } else {
      label = 'Suboptimal window — act soon, ${(24 - h).ceil()}h left';
      color = VanixColors.danger;
    }

    return _ActionCard(
      isDark: isDark,
      bg: VanixColors.warningBg,
      border: VanixColors.warning,
      priority: _Priority.p1,
      channel: 'App notification · Schedule inseminator',
          manager: manager,
      title: title,
      sub: sub,
      meta: meta,
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Is Gauri in heat?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
            const SizedBox(height: 6),
            _HeatWindowBar(simHours: h, fillColor: color),
            const SizedBox(height: 6),
            Text(
              _heatFormStage == 'form' ? 'Enter the insemination details once done.' : 'Best results within 6-18h of detection. The window opens automatically — no need to refresh.',
              style: const TextStyle(fontSize: 12, color: VanixColors.textHint),
            ),
            if (!_heatConfirmed) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => setState(() { _heat = _HeatState.dismissed; widget.appState.resolveEvent(); }), child: const Text('No'))),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => setState(() { _heatConfirmed = true; _heat = _HeatState.active; }),
                      child: const Text('Yes, in heat'),
                    ),
                  ),
                ],
              ),
            ] else if (_heatFormStage == 'idle') ...[
              // "Call vet" is available in every phase — outside the optimal
              // window it interposes a confirmation step first. Picking one of
              // the 3 onboarded vets then opens the log form.
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => setState(() => _heatFormStage = (h >= 6 && h < 18) ? 'vet' : 'confirm'),
                  child: const Text('Call vet'),
                ),
              ),
            ] else if (_heatFormStage == 'confirm') ...[
              const SizedBox(height: 10),
              const Text("You're outside the optimal window (best results 6–18h after detection). Continue anyway?", style: TextStyle(fontSize: 12, height: 1.5)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => setState(() => _heatFormStage = 'idle'), child: const Text('Cancel'))),
                  const SizedBox(width: 8),
                  Expanded(flex: 2, child: ElevatedButton(onPressed: () => setState(() => _heatFormStage = 'vet'), child: const Text('Continue'))),
                ],
              ),
            ] else if (_heatFormStage == 'vet') ...[
              _vetPicker((vetName) => setState(() { _heatTechCtrl.text = vetName; _heatFormStage = 'form'; })),
            ] else ...[
              const SizedBox(height: 10),
              const Text('Log insemination', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              _inseminationMethodGrid(_heatMethod, (m) => setState(() => _heatMethod = m), isDark: isDark),
              const SizedBox(height: 8),
              TextField(controller: _heatTechCtrl, decoration: const InputDecoration(hintText: 'Technician / vet name (optional)')),
              const SizedBox(height: 8),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => setState(() { _heat = _HeatState.logged; widget.appState.resolveEvent(); }), child: const Text('Log insemination'))),
            ],
          ],
        ),
      ),
    );
  }

  // ── P1: Pregnancy check due ──
  Widget _buildPregCard(bool isDark) {
    const manager = 'Suresh Yadav';
    switch (_preg) {
      case _PregState.initial:
        return _ActionCard(
          isDark: isDark,
          bg: VanixColors.warningBg,
          border: VanixColors.warning,
          priority: _Priority.p1,
          channel: 'App notification · Confirm with vet',
          manager: manager,
          title: 'Pregnancy check due — Mohini',
          sub: '21 days since insemination and no heat detected — confirm if she appears pregnant.',
          meta: 'Sunrise Dairy · Belt 91 · inseminated 12 Jun',
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () => setState(() { _preg = _PregState.failed; widget.appState.resolveEvent(); }), child: const Text('Not pregnant'))),
                const SizedBox(width: 8),
                Expanded(flex: 2, child: ElevatedButton(onPressed: () => setState(() { _preg = _PregState.confirmed; widget.appState.resolveEvent(); }), child: const Text('Confirm — pregnant'))),
              ],
            ),
          ),
        );
      case _PregState.failed:
        return _ActionCard(
          isDark: isDark,
          bg: VanixColors.bgCard,
          border: VanixColors.border,
          priority: _Priority.p1,
          channel: 'App notification · Confirm with vet',
          manager: manager,
          title: 'Pregnancy check due — Mohini',
          sub: '21 days since insemination and no heat detected.',
          meta: 'Sunrise Dairy · Belt 91',
          child: const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pregnancy failed — heat watch resumed', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: VanixColors.warningInk)),
                Text("Mohini goes back to heat monitoring. You'll be alerted on her next cycle.", style: TextStyle(fontSize: 12, color: VanixColors.textHint)),
              ],
            ),
          ),
        );
      case _PregState.confirmed:
        return _ActionCard(
          isDark: isDark,
          bg: VanixColors.activeBg,
          border: VanixColors.greenDeep,
          priority: _Priority.p1,
          channel: 'App notification · Confirm with vet',
          manager: manager,
          title: 'Pregnancy check due — Mohini',
          sub: '21 days since insemination and no heat detected.',
          meta: 'Sunrise Dairy · Belt 91',
          child: const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mohini is pregnant ✓', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: VanixColors.greenInk)),
                Text("Delivery expected around 3 Apr 2027 — you'll get a reminder as calving approaches, then she joins the Milk Log after calving.", style: TextStyle(fontSize: 12, color: VanixColors.textHint)),
              ],
            ),
          ),
        );
    }
  }

  // ── P1: 9-month vet check / delivery confirmed — the farmer-tapped action
  // that moves the cow's status to CALVED -> MILKING ──
  // ── P1: Gestation — 3/6/9-month vet checks -> call vet for delivery
  // (vet picker) -> delivery confirmed w/ notes. Single evolving card, like
  // Heat — only resolves (decrements badge) once, at final delivery confirm.
  Widget _buildGestationCard(bool isDark) {
    const manager = 'Ramesh Kumar';
    const meta = 'Green Valley Farm · Belt 52 · confirmed pregnant 4 Oct';
    const channel = 'App notification · Confirm with vet';

    if (_gestation == _GestationState.check3 || _gestation == _GestationState.check6) {
      final is3 = _gestation == _GestationState.check3;
      return _ActionCard(
        isDark: isDark,
        bg: VanixColors.warningBg,
        border: VanixColors.warning,
        priority: _Priority.p1,
        channel: channel,
          manager: manager,
        title: is3 ? '3-month vet check due — Lakshmi' : '6-month vet check due — Lakshmi',
        sub: 'Routine pregnancy vet check — confirm once done.',
        meta: meta,
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => setState(() => _gestation = is3 ? _GestationState.check6 : _GestationState.callVet),
              child: const Text('Vet check completed'),
            ),
          ),
        ),
      );
    }
    if (_gestation == _GestationState.callVet) {
      return _ActionCard(
        isDark: isDark,
        bg: VanixColors.warningBg,
        border: VanixColors.warning,
        priority: _Priority.p1,
        channel: channel,
          manager: manager,
        title: '9-month check — call your vet for delivery',
        sub: 'Approaching her due date — call a vet to be on hand for delivery.',
        meta: meta,
        child: _vetPicker((vetName) => setState(() { _gestationVetName = vetName; _gestation = _GestationState.deliveryAsk; })),
      );
    }
    if (_gestation == _GestationState.deliveryAsk) {
      return _ActionCard(
        isDark: isDark,
        bg: VanixColors.warningBg,
        border: VanixColors.warning,
        priority: _Priority.p1,
        channel: channel,
          manager: manager,
        title: 'Vet on the way — Lakshmi',
        sub: '$_gestationVetName has been called for the delivery.',
        meta: meta,
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Was the delivery successful?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => setState(() { _gestation = _GestationState.deliveryFailed; widget.appState.resolveEvent(); }), child: const Text('No'))),
                  const SizedBox(width: 8),
                  Expanded(flex: 2, child: ElevatedButton(onPressed: () => setState(() => _gestation = _GestationState.deliveryForm), child: const Text('Yes, successful'))),
                ],
              ),
            ],
          ),
        ),
      );
    }
    if (_gestation == _GestationState.deliveryForm) {
      return _ActionCard(
        isDark: isDark,
        bg: VanixColors.warningBg,
        border: VanixColors.warning,
        priority: _Priority.p1,
        channel: channel,
          manager: manager,
        title: 'Delivery successful — log it',
        sub: 'Add any notes from $_gestationVetName before logging the delivery.',
        meta: meta,
        child: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(controller: _gestationNotesCtrl, maxLines: 3, decoration: const InputDecoration(hintText: 'Delivery notes (optional)')),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => setState(() {
                    _gestation = _GestationState.delivered;
                    widget.appState.resolveEvent();
                    _milkingNotifShown = true;
                  }),
                  child: const Text('Log delivery'),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_gestation == _GestationState.deliveryFailed) {
      return _ActionCard(
        isDark: isDark,
        bg: VanixColors.dangerBg,
        border: VanixColors.danger,
        priority: _Priority.p1,
        channel: channel,
          manager: manager,
        title: 'Delivery unsuccessful — recorded',
        sub: '$_gestationVetName has been notified for an urgent check. Lakshmi will not enter the milking pool.',
        meta: meta,
        child: const SizedBox.shrink(),
      );
    }
    // delivered
    return _ActionCard(
      isDark: isDark,
      bg: VanixColors.activeBg,
      border: VanixColors.greenDeep,
      priority: _Priority.p1,
      channel: channel,
          manager: manager,
      title: 'Delivery logged ✓',
      sub: 'Lakshmi has moved to Calved. She\'ll appear in the Milk Log once you add her from the new lactation notification.',
      meta: meta,
      child: const SizedBox.shrink(),
    );
  }

  // ── P1: Milking notification — fires once, right after delivery is
  // confirmed. DEMO NOTE: "Remind me later" uses a compressed 24-simulated-
  // hour timer that flips back to pending without touching the badge — only
  // "Yes, add" resolves it. ──
  Widget _buildMilkingNotifCard(bool isDark) {
    const manager = 'Ramesh Kumar';
    const meta = 'Green Valley Farm · Belt 52';
    if (_milkingNotif == _MilkingNotifState.reminded) {
      return _ActionCard(
        isDark: isDark,
        bg: VanixColors.warningBg,
        border: VanixColors.warning,
        priority: _Priority.p1,
        channel: 'App notification · Add to Milk Log',
          manager: manager,
        title: 'Lakshmi is now in her lactation period (250 days)',
        sub: 'Add her to the milking list?',
        meta: meta,
        child: const Padding(padding: EdgeInsets.only(top: 12), child: Text("We'll remind you in 24 hours.", style: TextStyle(fontSize: 13, color: VanixColors.textHint))),
      );
    }
    if (_milkingNotif == _MilkingNotifState.added) {
      return _ActionCard(
        isDark: isDark,
        bg: VanixColors.activeBg,
        border: VanixColors.greenDeep,
        priority: _Priority.p1,
        channel: 'App notification · Add to Milk Log',
          manager: manager,
        title: 'Lakshmi is now in her lactation period (250 days)',
        sub: 'Add her to the milking list?',
        meta: meta,
        child: const Padding(
          padding: EdgeInsets.only(top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Added to Milk Log ✓', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: VanixColors.greenInk)),
              Text('Lakshmi now appears in Milk Log entries.', style: TextStyle(fontSize: 12, color: VanixColors.textHint)),
            ],
          ),
        ),
      );
    }
    return _ActionCard(
      isDark: isDark,
      bg: VanixColors.warningBg,
      border: VanixColors.warning,
      priority: _Priority.p1,
      channel: 'App notification · Add to Milk Log',
          manager: manager,
      title: 'Lakshmi is now in her lactation period (250 days)',
      sub: 'Add her to the milking list?',
      meta: meta,
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() => _milkingNotif = _MilkingNotifState.reminded);
                  _milkingRemindTimer?.cancel();
                  _milkingRemindTimer = Timer(const Duration(seconds: 24), () {
                    if (mounted) setState(() => _milkingNotif = _MilkingNotifState.pending);
                  });
                },
                child: const Text('Remind me later'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () {
                  _milkingRemindTimer?.cancel();
                  setState(() { _milkingNotif = _MilkingNotifState.added; widget.appState.resolveEvent(); });
                },
                child: const Text('Yes, add'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── P1: End-of-lactation check-in — reached via the walkthrough's
  // skip-ahead. DEMO NOTE: "Still milking" loops on a compressed 10-
  // simulated-day timer without touching the badge — only "Entered resting
  // period" resolves it. ──
  Widget _buildLactationCheckCard(bool isDark) {
    const manager = 'Ramesh Kumar';
    const meta = 'Green Valley Farm · Belt 52';
    const title = 'Lactation period ending — Lakshmi';
    const sub = 'Is Lakshmi still milking, or has she entered her resting period?';
    if (_lactationCheck == _LactationCheckState.stillMilking) {
      return _ActionCard(
        isDark: isDark,
        bg: VanixColors.warningBg,
        border: VanixColors.warning,
        priority: _Priority.p1,
        channel: 'App notification · Confirm status',
          manager: manager,
        title: title,
        sub: sub,
        meta: meta,
        child: const Padding(padding: EdgeInsets.only(top: 12), child: Text("Got it — we'll check again in 10 days.", style: TextStyle(fontSize: 13, color: VanixColors.textHint))),
      );
    }
    if (_lactationCheck == _LactationCheckState.resting) {
      return _ActionCard(
        isDark: isDark,
        bg: VanixColors.activeBg,
        border: VanixColors.greenDeep,
        priority: _Priority.p1,
        channel: 'App notification · Confirm status',
          manager: manager,
        title: title,
        sub: sub,
        meta: meta,
        child: const Padding(
          padding: EdgeInsets.only(top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Resting period started', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: VanixColors.greenInk)),
              Text("60-day cool-down begins. She won't appear in Milk Log entries during this time.", style: TextStyle(fontSize: 12, color: VanixColors.textHint)),
            ],
          ),
        ),
      );
    }
    return _ActionCard(
      isDark: isDark,
      bg: VanixColors.warningBg,
      border: VanixColors.warning,
      priority: _Priority.p1,
      channel: 'App notification · Confirm status',
          manager: manager,
      title: title,
      sub: sub,
      meta: meta,
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() => _lactationCheck = _LactationCheckState.stillMilking);
                  _lactationRecheckTimer?.cancel();
                  _lactationRecheckTimer = Timer(const Duration(seconds: 10), () {
                    if (mounted) setState(() => _lactationCheck = _LactationCheckState.pending);
                  });
                },
                child: const Text('Still milking'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () {
                  _lactationRecheckTimer?.cancel();
                  setState(() { _lactationCheck = _LactationCheckState.resting; widget.appState.resolveEvent(); });
                },
                child: const Text('Entered resting period'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // shared: P2 diagnostic card builder (Mastitis / Lameness / Ketosis)
  Widget _buildInspectCard({
    required bool isDark,
    required _InspectState state,
    required ValueChanged<_InspectState> onChange,
    required String title,
    required String sub,
    required String meta,
    required String question,
    String? manager,
  }) {
    switch (state) {
      case _InspectState.initial:
        return _ActionCard(
          isDark: isDark,
          bg: VanixColors.bgCard,
          border: VanixColors.border,
          leftAccentColor: VanixColors.warning,
          leftAccentWidth: 2,
          priority: _Priority.p2,
          channel: 'App inbox · Physical inspection',
          manager: manager,
          title: title,
          sub: sub,
          meta: meta,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(padding: const EdgeInsets.only(top: 12, bottom: 10), child: Text(question, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => onChange(_InspectState.falseAlarm), child: _iconLabel(Icons.close, 'No'))),
                  const SizedBox(width: 8),
                  Expanded(flex: 2, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: VanixColors.warning, foregroundColor: VanixColors.darkPrimary), onPressed: () => onChange(_InspectState.flagged), child: _iconLabel(Icons.flag, 'Flag it'))),
                ],
              ),
            ],
          ),
        );
      case _InspectState.falseAlarm:
        return _ActionCard(
          isDark: isDark,
          bg: VanixColors.bgCard,
          border: VanixColors.border,
          priority: _Priority.p2,
          channel: 'App inbox · Physical inspection',
          manager: manager,
          title: title,
          sub: sub,
          meta: meta,
          child: const Padding(padding: EdgeInsets.only(top: 12), child: Text('Marked as false alarm — monitoring continues.', style: TextStyle(fontSize: 13, color: VanixColors.textHint))),
        );
      case _InspectState.flagged:
        return _ActionCard(
          isDark: isDark,
          bg: VanixColors.bgCard,
          border: VanixColors.border,
          priority: _Priority.p2,
          channel: 'App inbox · Physical inspection',
          manager: manager,
          title: title,
          sub: sub,
          meta: meta,
          child: const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Flagged for inspection ✓', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: VanixColors.warningInk)),
                Text('She has been flagged for a physical check at the next milking.', style: TextStyle(fontSize: 12, color: VanixColors.textHint)),
              ],
            ),
          ),
        );
    }
  }

  Widget _buildMastitisCard(bool isDark) => _buildInspectCard(
        isDark: isDark,
        state: _mastitis,
        onChange: (s) => setState(() { _mastitis = s; if (s != _InspectState.initial) widget.appState.resolveEvent(); }),
        title: 'Possible mastitis — Bhoori',
        sub: 'Temperature up and feeding down — possible udder infection.',
        meta: 'Green Valley Farm · Belt 09',
        question: 'Does Bhoori show swelling or milk changes?',
        manager: 'Ramesh Kumar',
      );

  Widget _buildLamenessCard(bool isDark) => _buildInspectCard(
        isDark: isDark,
        state: _lameness,
        onChange: (s) => setState(() { _lameness = s; if (s != _InspectState.initial) widget.appState.resolveEvent(); }),
        title: 'Possible lameness — Dhauli',
        sub: 'Barely standing and resting far more than usual — possible leg or hoof issue.',
        meta: 'Green Valley Farm · Belt 18',
        question: 'Does Dhauli seem to be limping?',
        manager: 'Ramesh Kumar',
      );

  Widget _buildKetosisCard(bool isDark) => _buildInspectCard(
        isDark: isDark,
        state: _ketosis,
        onChange: (s) => setState(() { _ketosis = s; if (s != _InspectState.initial) widget.appState.resolveEvent(); }),
        title: 'Possible ketosis — Lakshmi',
        sub: 'Reduced rumination this early in her milking cycle — a metabolic condition common just after calving.',
        meta: 'Green Valley Farm · Belt 52 · Day 12 in milk',
        question: 'Does Lakshmi seem lethargic or off her feed?',
        manager: 'Ramesh Kumar',
      );

  // shared: single-acknowledge card builder (Proestrus / Herd Heat Stress / Calibration)
  Widget _buildAckCard({
    required bool isDark,
    required _AckState state,
    required ValueChanged<_AckState> onChange,
    required _Priority priority,
    required String title,
    required String sub,
    String? meta,
    required String buttonLabel,
    required String resolvedMessage,
    String? channel,
    String? manager,
  }) {
    final isP1 = priority == _Priority.p1;
    final isP2 = priority == _Priority.p2;
    final resolvedChannel = channel ?? (isP2 ? 'App inbox · Monitor closely' : 'App inbox · Info only');
    final bg = isP1 ? VanixColors.warningBg : VanixColors.bgCard;
    final border = isP1 ? VanixColors.warning : VanixColors.border;
    if (state == _AckState.initial) {
      return _ActionCard(
        isDark: isDark,
        bg: bg,
        border: border,
        leftAccentColor: isP2 ? VanixColors.warning : null,
        leftAccentWidth: isP1 ? 4 : (isP2 ? 2 : 0),
        priority: priority,
        channel: resolvedChannel,
        manager: manager,
        title: title,
        sub: sub,
        meta: meta,
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => onChange(_AckState.acknowledged), child: _iconLabel(Icons.check, buttonLabel))),
        ),
      );
    }
    return _ActionCard(
      isDark: isDark,
      bg: VanixColors.bgCard,
      border: VanixColors.border,
      priority: priority,
      channel: resolvedChannel,
      manager: manager,
      title: title,
      sub: sub,
      meta: meta,
      child: Padding(padding: const EdgeInsets.only(top: 12), child: Text(resolvedMessage, style: const TextStyle(fontSize: 13, color: VanixColors.textHint))),
    );
  }

  Widget _buildProestrusCard(bool isDark) => _buildAckCard(
        isDark: isDark,
        state: _proestrus,
        onChange: (s) => setState(() { _proestrus = s; widget.appState.resolveEvent(); }),
        priority: _Priority.p3,
        title: 'Rise in temperature — Kajri',
        sub: "A mild temperature rise — possible early signs of heat starting. Movement is normal. We'll alert you again if it strengthens.",
        meta: 'Green Valley Farm · Belt 63',
        buttonLabel: 'Got it, watching',
        resolvedMessage: "Watching Kajri closely — you'll get a separate alert if this strengthens to confirmed heat.",
        manager: 'Ramesh Kumar',
      );

  Widget _buildHerdStressCard(bool isDark) => _buildAckCard(
        isDark: isDark,
        state: _herdStress,
        onChange: (s) => setState(() { _herdStress = s; widget.appState.resolveEvent(); }),
        priority: _Priority.p3,
        title: 'Herd heat stress — Green Valley Farm',
        sub: '20%+ of cows in this zone are showing a temperature rise together — likely the weather, not individual cows.',
        buttonLabel: 'Checked cooling / shade',
        resolvedMessage: "Thanks — logged. Herd heat stress alerts don't need a vet visit.",
        manager: 'Ramesh Kumar',
      );

  Widget _buildCalibCard(bool isDark) => _buildAckCard(
        isDark: isDark,
        state: _calib,
        onChange: (s) => setState(() { _calib = s; widget.appState.resolveEvent(); }),
        priority: _Priority.p3,
        title: 'Collar calibrated — Ganga',
        sub: 'Her new collar has finished calibrating and is now live-monitored.',
        buttonLabel: 'Got it',
        resolvedMessage: 'Ganga is now fully live-monitored.',
        manager: 'Ramesh Kumar',
      );
}

// ── Priority chip (P0-P3) — reuses only the locked color tokens ──
enum _Priority { p0, p1, p2, p3 }

class _PriorityChip extends StatelessWidget {
  final _Priority priority;
  const _PriorityChip({required this.priority});

  // Icon + 1-word label replaces the old "P1 · ACTIONABLE"-style text chip —
  // less to read, same severity colours (locked tokens, no new colours).
  @override
  Widget build(BuildContext context) {
    switch (priority) {
      case _Priority.p0:
        return _chip(Icons.emergency, 'P0', bg: const Color(0xFF8B2800), fg: Colors.white, outline: false);
      case _Priority.p1:
        return _chip(Icons.notifications_active, 'P1', bg: VanixColors.warningInk, fg: Colors.white, outline: false);
      case _Priority.p2:
        return _chip(Icons.warning_amber_rounded, 'P2', bg: VanixColors.warningBg, fg: VanixColors.warningInk, outline: true, borderColor: VanixColors.warning);
      case _Priority.p3:
        return _chip(Icons.info_outline, 'P3', bg: VanixColors.bgCard, fg: VanixColors.textHint, outline: true, borderColor: VanixColors.border);
    }
  }

  Widget _chip(IconData icon, String label, {required Color bg, required Color fg, required bool outline, Color? borderColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10), border: outline ? Border.all(color: borderColor!) : null),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg)),
        ],
      ),
    );
  }
}

/// Picks one of the onboarded vets instead of typing an email. Mirrors
/// vetPickerHtml()/wireVetPicker() in vanix_screens.html.
class _VetPicker extends StatefulWidget {
  final ValueChanged<String> onSent;
  const _VetPicker({required this.onSent});

  @override
  State<_VetPicker> createState() => _VetPickerState();
}

class _VetPickerState extends State<_VetPicker> {
  String _selected = kOnboardedVets.first;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Request a vet appointment', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          ...kOnboardedVets.map((name) {
            final on = name == _selected;
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => _selected = name),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: on ? VanixColors.greenDeep : VanixColors.border),
                    color: on ? VanixColors.activeBg : VanixColors.bgCard,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: on ? VanixColors.greenDeep : VanixColors.border, width: 2),
                          color: on ? VanixColors.greenDeep : Colors.transparent,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(name, style: TextStyle(fontSize: 14, fontWeight: on ? FontWeight.w600 : FontWeight.w500, color: VanixColors.textPrimary)),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => widget.onSent(_selected),
              child: const Text('Send appointment request'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  final int count;
  const _CountPill({required this.count});

  @override
  Widget build(BuildContext context) {
    final clear = count == 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: clear ? VanixColors.activeBg : VanixColors.dangerBg, border: Border.all(color: clear ? VanixColors.greenDeep : VanixColors.danger), borderRadius: BorderRadius.circular(14)),
      child: Text(clear ? 'All clear' : '$count need${count == 1 ? 's' : ''} action', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: clear ? VanixColors.greenInk : VanixColors.dangerInk)),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool active, isDark;
  final VoidCallback onTap;
  const _TabChip({required this.label, required this.active, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? VanixColors.darkPrimary : (isDark ? const Color(0xFF1C1C1C) : VanixColors.bgCard),
          border: Border.all(color: active ? VanixColors.darkPrimary : VanixColors.border),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: active ? FontWeight.w600 : FontWeight.w500, color: active ? Colors.white : (isDark ? Colors.white : VanixColors.textPrimary))),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: VanixColors.textHint));
}

/// A single event card. P0/P1 use a full tint wash (bg + border) with a
/// solid priority chip; P2/P3 stay neutral (bgCard/border) with a thin or
/// no left accent and an outline chip — same visual hierarchy the HTML
/// version uses. All tints stay light in dark mode (locked design rule).
class _ActionCard extends StatelessWidget {
  final Color bg, border;
  final Color? leftAccentColor;
  final double leftAccentWidth;
  final _Priority priority;
  // Notification-channel routing text (e.g. "App notification · Schedule
  // inseminator") — kept as a field so existing call sites don't need
  // updating, but no longer rendered: cards were too text-heavy for the
  // farm-owner persona and this line was the least essential (internal
  // routing info, not something the farmer needs to act on).
  final String channel;
  final String title, sub;
  final String? meta;
  final String? manager;
  // Cow + condition emoji "illustration" leading the card (e.g. 🐄🌡️ for
  // fever) — farmer-friendly pictorial cue, in place of a plain text-only
  // header. Not every card has one yet (see CLAUDE.md pending list).
  final String? avatarEmoji;
  final Widget child;
  final bool escalated;
  final bool isDark;

  const _ActionCard({
    required this.bg,
    required this.border,
    this.leftAccentColor,
    this.leftAccentWidth = 4,
    required this.priority,
    required this.channel,
    required this.title,
    required this.sub,
    this.meta,
    this.manager,
    this.avatarEmoji,
    required this.child,
    this.escalated = false,
    this.isDark = false,
  });

  // Deterministic mock temp/movement series so the detail page's graphs have
  // something to draw — no real 10-day sensor dataset exists yet. Seeded off
  // the title so each card gets a stable, slightly different series; the
  // final ("today") value is always the spike/dip that triggered the alert.
  List<double> _mockTemps() {
    final h = title.hashCode;
    final base = 38.2 + (h % 5) * 0.1;
    return List.generate(9, (i) => base + ((h >> i) % 4) * 0.08)..add(base + 0.9);
  }

  List<int> _mockMoves() {
    // Rise in temperature is a temperature-only signal — movement stays
    // flat/normal, unlike the other cards where it also spikes.
    if (title.startsWith('Rise in temperature')) return List.filled(10, 4);
    final h = title.hashCode;
    return List.generate(9, (i) => 3 + ((h >> i) % 5))..add(9 + (h % 3));
  }

  void _openDetails(BuildContext context) {
    String label;
    Color pBg, pFg;
    bool outline = false;
    Color? borderColor;
    switch (priority) {
      case _Priority.p0:
        label = 'P0 · CRITICAL';
        pBg = const Color(0xFF8B2800);
        pFg = Colors.white;
        break;
      case _Priority.p1:
        label = 'P1 · ACTIONABLE';
        pBg = VanixColors.warningInk;
        pFg = Colors.white;
        break;
      case _Priority.p2:
        label = 'P2 · WARNING';
        pBg = VanixColors.warningBg;
        pFg = VanixColors.warningInk;
        outline = true;
        borderColor = VanixColors.warning;
        break;
      case _Priority.p3:
        label = 'P3 · WARNING';
        pBg = VanixColors.bgCard;
        pFg = VanixColors.textHint;
        outline = true;
        borderColor = VanixColors.border;
        break;
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CardDetailScreen(
        title: title,
        sub: sub,
        meta: meta,
        manager: manager,
        priorityLabel: label,
        priorityBg: pBg,
        priorityFg: pFg,
        priorityOutline: outline,
        priorityBorderColor: borderColor,
        isDark: isDark,
        temps: _mockTemps(),
        moves: _mockMoves(),
        moveIsFlat: _mockMoves().toSet().length == 1,
        cta: child,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = leftAccentColor ?? border;
    final titleColor = isDark ? Colors.white : VanixColors.textPrimary;
    final card = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1C) : bg,
        border: Border(
          top: BorderSide(color: border),
          bottom: BorderSide(color: border),
          left: BorderSide(color: accentColor, width: leftAccentWidth == 0 ? 1 : leftAccentWidth),
          right: BorderSide(color: border),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (avatarEmoji != null) Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Container(
                  width: 44,
                  height: 40,
                  decoration: BoxDecoration(color: bg, border: Border.all(color: border), borderRadius: BorderRadius.circular(14)),
                  alignment: Alignment.center,
                  child: Text(avatarEmoji!, style: const TextStyle(fontSize: 19)),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: titleColor)),
                    if (manager != null) Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.person_outline, size: 12, color: VanixColors.textHint),
                          const SizedBox(width: 3),
                          Text(manager!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: VanixColors.textHint)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: TextButton(
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap, alignment: Alignment.centerLeft),
                        onPressed: () => _openDetails(context),
                        child: Text('View Details ›', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? VanixColors.greenDeep : VanixColors.greenInk)),
                      ),
                    ),
                  ],
                ),
              ),
              // P0 cards signal severity via the red card tint + corner badge
              // instead of a text chip (see _CornerBadge below).
              if (priority != _Priority.p0) _PriorityChip(priority: priority),
            ],
          ),
          child,
        ],
      ),
    );
    if (priority != _Priority.p0) return card;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        card,
        if (escalated) const Positioned(top: -6, right: -6, child: _CornerBadge()),
      ],
    );
  }
}

/// Single red circle + "!" badge for escalated P0 cards, replacing the old
/// stacked "P0 · CRITICAL" + "ESCALATED" chips. Mirrors .ev-corner-badge in
/// vanix_screens.html.
class _CornerBadge extends StatelessWidget {
  const _CornerBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: const Color(0xFF8B2800),
        shape: BoxShape.circle,
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 1))],
      ),
      alignment: Alignment.center,
      child: const Text('!', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white, height: 1)),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final IconData icon;
  final String title, sub;
  final DateTime startDate, dueDate;
  final bool isDark;
  const _ReminderCard({required this.icon, required this.title, required this.sub, required this.startDate, required this.dueDate, required this.isDark});

  // DEMO: "today" is fixed to match the History section's "YESTERDAY — 2 JUL"
  // reference (i.e. today = 3 Jul) — replace with the real current date once
  // wired to a backend. Static days-left, not a live countdown.
  static final DateTime _demoToday = DateTime(2026, 7, 3);

  @override
  Widget build(BuildContext context) {
    final days = dueDate.difference(_demoToday).inDays;
    String dueLabel;
    Color dueColor;
    if (days < 0) {
      dueLabel = 'Overdue by ${-days}d';
      dueColor = VanixColors.danger;
    } else if (days == 0) {
      dueLabel = 'Due today';
      dueColor = VanixColors.danger;
    } else if (days <= 2) {
      dueLabel = '$days day${days == 1 ? '' : 's'} left';
      dueColor = VanixColors.warningInk;
    } else {
      dueLabel = '$days days left';
      dueColor = VanixColors.textHint;
    }
    final span = dueDate.difference(startDate).inMinutes;
    final elapsed = _demoToday.difference(startDate).inMinutes;
    final pct = span > 0 ? (elapsed / span).clamp(0.0, 1.0) : 1.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF1C1C1C) : VanixColors.bgCard, border: Border.all(color: isDark ? const Color(0xFF3A3A3A) : VanixColors.border), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: isDark ? const Color(0xFF0F2A1E) : VanixColors.activeBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 17, color: VanixColors.greenInk),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : VanixColors.textPrimary)),
                Text(sub, style: const TextStyle(fontSize: 12, color: VanixColors.textHint)),
                Padding(padding: const EdgeInsets.only(top: 4), child: Text(dueLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: dueColor))),
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 4,
                      backgroundColor: isDark ? const Color(0xFF3A3A3A) : VanixColors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(dueColor),
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
}

class _HistoryRow extends StatelessWidget {
  final Color dotColor, stageColor;
  final String title, stage, sub, time;
  final bool isDark;
  const _HistoryRow({required this.dotColor, required this.title, required this.stage, required this.stageColor, required this.sub, required this.time, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF1C1C1C) : VanixColors.bgCard, border: Border.all(color: isDark ? const Color(0xFF3A3A3A) : VanixColors.border), borderRadius: BorderRadius.circular(14)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(top: 5), child: Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle))),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title on its own line, stage chip on the next — avoids the
                // chip wrapping/clipping when the cow name is long.
                Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : VanixColors.textPrimary)),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                  decoration: BoxDecoration(color: stageColor.withOpacity(0.12), border: Border.all(color: stageColor), borderRadius: BorderRadius.circular(9)),
                  child: Text(stage, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: stageColor)),
                ),
                const SizedBox(height: 4),
                Text(sub, style: const TextStyle(fontSize: 12, color: VanixColors.textHint)),
              ],
            ),
          ),
          Text(time, style: const TextStyle(fontSize: 11, color: VanixColors.textHint)),
        ],
      ),
    );
  }
}

/// "View full cycle" — a self-contained walkthrough of the whole breeding/
/// lactation year for one cow (Gauri), presented as 7 sequential bottom-
/// sheet steps. Deliberately has its OWN local state — it never calls
/// AppState.resolveEvent() and never touches the real inline Heat/Preg/
/// Gestation cards on the Events screen, so running the demo never
/// consumes any of the farmer's actual pending alerts.
class _FullCycleSheet extends StatefulWidget {
  final bool isDark;
  /// 'yes' / 'no' if the farmer already resolved the heat question on the
  /// full-screen alert; null if they dismissed it (close/"View in app").
  final String? heatPreDecision;
  /// True when entered via dismiss-without-resolving — the heat step renders
  /// a trimmed "restricted" detail view until the farmer taps Yes/No here.
  final bool restricted;
  const _FullCycleSheet({required this.isDark, this.heatPreDecision, this.restricted = false});

  @override
  State<_FullCycleSheet> createState() => _FullCycleSheetState();
}

enum _SeqStep { heat, watch21, preg, gestation9, delivery, milking, lactationCheck, dry, interrupted, complete }

class _FullCycleSheetState extends State<_FullCycleSheet> {
  static const int totalSteps = 8;
  _SeqStep _step = _SeqStep.heat;

  DateTime? _heatStartedAt;
  bool _heatConfirmed = false;
  String _heatMethod = kInseminationMethods.first;
  String _heatFormStage = 'idle'; // idle | confirm | form
  Timer? _heatTimer;
  // Walkthrough demo speed — 24h plays out in 48s.
  static const double _simHoursPerSecond = 0.5;

  @override
  void initState() {
    super.initState();
    if (widget.heatPreDecision == 'no') {
      _interruptedMessage = 'Cycle interrupted — heat not confirmed. Closing walkthrough.';
      _step = _SeqStep.interrupted;
    } else {
      _startHeat();
    }
  }

  void _startHeat() {
    _heatStartedAt = DateTime.now();
    _heatConfirmed = widget.heatPreDecision == 'yes';
    _heatMethod = kInseminationMethods.first;
    _heatFormStage = 'idle';
    _heatTimer?.cancel();
    _heatTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (_step == _SeqStep.heat) setState(() {});
    });
  }

  double get _heatElapsedSimHours => _heatStartedAt == null ? 0 : DateTime.now().difference(_heatStartedAt!).inMilliseconds / 1000 * _simHoursPerSecond;

  @override
  void dispose() {
    _heatTimer?.cancel();
    super.dispose();
  }

  void _goTo(_SeqStep step) {
    _heatTimer?.cancel();
    setState(() => _step = step);
  }

  int get _stepNumber {
    switch (_step) {
      case _SeqStep.heat: return 1;
      case _SeqStep.watch21: return 2;
      case _SeqStep.preg: return 3;
      case _SeqStep.gestation9: return 4;
      case _SeqStep.delivery: return 5;
      case _SeqStep.milking: return 6;
      case _SeqStep.lactationCheck: return 7;
      case _SeqStep.dry: return 8;
      case _SeqStep.interrupted:
      case _SeqStep.complete:
        return totalSteps;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bg = isDark ? const Color(0xFF1C1C1C) : Colors.white;
    final textColor = isDark ? Colors.white : VanixColors.textPrimary;
    final hintColor = isDark ? const Color(0xFF8C8780) : VanixColors.textHint;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.78),
        child: Container(
          decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 36, height: 4, margin: const EdgeInsets.symmetric(vertical: 8), decoration: BoxDecoration(color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(2)))),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _step == _SeqStep.interrupted || _step == _SeqStep.complete ? 'Walkthrough ended' : 'Step $_stepNumber of $totalSteps',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: hintColor),
                    ),
                    if (_step != _SeqStep.interrupted && _step != _SeqStep.complete)
                      TextButton(
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Skip walkthrough', style: TextStyle(fontSize: 12, color: hintColor)),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildStepBody(textColor, hintColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepBody(Color textColor, Color hintColor) {
    switch (_step) {
      case _SeqStep.heat:
        return _heatStepBody(textColor, hintColor);
      case _SeqStep.watch21:
        return _interstitial(
          textColor, hintColor,
          title: '21-day pregnancy watch',
          text: "Watching for 21 days to see if heat returns. If it doesn't, a pregnancy check is due.",
          onContinue: () => _goTo(_SeqStep.preg),
        );
      case _SeqStep.preg:
        return _pregStepBody(textColor, hintColor);
      case _SeqStep.gestation9:
        return _interstitial(
          textColor, hintColor,
          title: '9-month gestation',
          text: 'Carrying to term for roughly 9 months, with vet checks at 3, 6, and 9 months.',
          onContinue: () => _goTo(_SeqStep.delivery),
        );
      case _SeqStep.delivery:
        return _deliveryStepBody(textColor, hintColor);
      case _SeqStep.milking:
        return _milkingStepBody(textColor, hintColor);
      case _SeqStep.lactationCheck:
        return _lactationCheckStepBody(textColor, hintColor);
      case _SeqStep.dry:
        return _dryStepBody(textColor, hintColor);
      case _SeqStep.interrupted:
        return _closingBody(textColor, _interruptedMessage);
      case _SeqStep.complete:
        return _closingBody(textColor, 'Cycle complete ✓ — Gauri is ready for her next heat cycle.');
    }
  }

  String _interruptedMessage = '';

  Widget _interstitial(Color textColor, Color hintColor, {required String title, required String text, required VoidCallback onContinue}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
        Padding(padding: const EdgeInsets.only(top: 6), child: Text(text, style: TextStyle(fontSize: 13, color: hintColor, height: 1.5))),
        const SizedBox(height: 14),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: onContinue, child: const Text('Continue'))),
      ],
    );
  }

  Widget _closingBody(Color textColor, String message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: VanixColors.greenInk, height: 1.5)),
        const SizedBox(height: 14),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))),
      ],
    );
  }

  Widget _heatStepBody(Color textColor, Color hintColor) {
    final h = _heatElapsedSimHours;
    String label;
    Color color;
    if (h < 6) {
      label = 'Pre-insemination — window opens in ${(6 - h).ceil()}h';
      color = VanixColors.warningInk;
    } else if (h < 18) {
      label = 'Optimal window — ${(18 - h).ceil()}h left';
      color = VanixColors.greenInk;
    } else {
      label = 'Suboptimal window — act soon, ${(24 - h).ceil()}h left';
      color = VanixColors.danger;
    }

    final restrictedNow = widget.restricted && !_heatConfirmed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Heat cycle detected — Gauri', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
        if (restrictedNow)
          const Padding(padding: EdgeInsets.only(top: 10), child: Text('Is Gauri in heat?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)))
        else ...[
          Padding(padding: const EdgeInsets.only(top: 3), child: Text('Temperature swinging up and down with high movement since 04:30 this morning.', style: TextStyle(fontSize: 12, color: hintColor, height: 1.5))),
          const Padding(padding: EdgeInsets.only(top: 10), child: Text('Is Gauri in heat?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
          const SizedBox(height: 6),
          _HeatWindowBar(simHours: h, fillColor: color),
        ],
        if (!_heatConfirmed) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _heatTimer?.cancel();
                    setState(() {
                      _interruptedMessage = 'Cycle interrupted — heat not confirmed. Closing walkthrough.';
                      _step = _SeqStep.interrupted;
                    });
                  },
                  child: const Text('No'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () => setState(() => _heatConfirmed = true),
                  child: const Text('Yes, in heat'),
                ),
              ),
            ],
          ),
        ] else if (_heatFormStage == 'idle') ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => setState(() => _heatFormStage = (h >= 6 && h < 18) ? 'vet' : 'confirm'),
              child: const Text('Call vet'),
            ),
          ),
        ] else if (_heatFormStage == 'confirm') ...[
          const SizedBox(height: 10),
          const Text("You're outside the optimal window (best results 6–18h after detection). Continue anyway?", style: TextStyle(fontSize: 12, height: 1.5)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: () => setState(() => _heatFormStage = 'idle'), child: const Text('Cancel'))),
              const SizedBox(width: 8),
              Expanded(flex: 2, child: ElevatedButton(onPressed: () => setState(() => _heatFormStage = 'vet'), child: const Text('Continue'))),
            ],
          ),
        ] else if (_heatFormStage == 'vet') ...[
          _VetPicker(onSent: (_) => setState(() => _heatFormStage = 'form')),
        ] else ...[
          const SizedBox(height: 10),
          const Text('Log insemination', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          _inseminationMethodGrid(_heatMethod, (m) => setState(() => _heatMethod = m), isDark: widget.isDark),
          const SizedBox(height: 8),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => _goTo(_SeqStep.watch21), child: const Text('Log insemination'))),
        ],
      ],
    );
  }

  Widget _pregStepBody(Color textColor, Color hintColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pregnancy check due — Gauri', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
        Padding(padding: const EdgeInsets.only(top: 3), child: Text('21 days since insemination and no heat detected — confirm if she appears pregnant.', style: TextStyle(fontSize: 12, color: hintColor, height: 1.5))),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() {
                  _interruptedMessage = 'Cycle interrupted — pregnancy not confirmed. Heat watch would resume.';
                  _step = _SeqStep.interrupted;
                }),
                child: const Text('Not pregnant'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(flex: 2, child: ElevatedButton(onPressed: () => _goTo(_SeqStep.gestation9), child: const Text('Confirm — pregnant'))),
          ],
        ),
      ],
    );
  }

  // Gestation walkthrough sub-steps: vet (pick a vet) → ask (was it successful?)
  // → log (notes) → milking; "No" interrupts the walkthrough.
  String _seqGestStage = 'vet';

  Widget _deliveryStepBody(Color textColor, Color hintColor) {
    Widget header = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('9-month check — call your vet for delivery', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
        Padding(padding: const EdgeInsets.only(top: 3), child: Text('Approaching her due date — call a vet to be on hand for delivery.', style: TextStyle(fontSize: 12, color: hintColor, height: 1.5))),
      ],
    );
    if (_seqGestStage == 'vet') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [header, _VetPicker(onSent: (_) => setState(() => _seqGestStage = 'ask'))],
      );
    }
    if (_seqGestStage == 'ask') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          const Padding(padding: EdgeInsets.only(top: 12), child: Text('Was the delivery successful?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: () => setState(() {
                _interruptedMessage = 'Cycle interrupted — delivery unsuccessful. The vet has been notified for an urgent check.';
                _step = _SeqStep.interrupted;
              }), child: const Text('No'))),
              const SizedBox(width: 8),
              Expanded(flex: 2, child: ElevatedButton(onPressed: () => setState(() => _seqGestStage = 'log'), child: const Text('Yes, successful'))),
            ],
          ),
        ],
      );
    }
    // log
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Delivery successful — log it', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
        const SizedBox(height: 10),
        const TextField(maxLines: 3, decoration: InputDecoration(hintText: 'Delivery notes (optional)')),
        const SizedBox(height: 8),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => _goTo(_SeqStep.milking), child: const Text('Log delivery'))),
      ],
    );
  }

  String _milkStepChoice = 'pending'; // pending | reminded | added
  String _lactStepChoice = 'pending'; // pending | still | resting

  Widget _milkingStepBody(Color textColor, Color hintColor) {
    if (_milkStepChoice == 'reminded') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("We'll remind you in 24 hours.", style: TextStyle(fontSize: 13, color: hintColor)),
          const SizedBox(height: 14),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => _goTo(_SeqStep.lactationCheck), child: const Text('Continue'))),
        ],
      );
    }
    if (_milkStepChoice == 'added') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Added to Milk Log ✓', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: VanixColors.greenInk)),
          const SizedBox(height: 14),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => _goTo(_SeqStep.lactationCheck), child: const Text('Skip ahead (250 days)'))),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Gauri is now in her lactation period (250 days)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
        Padding(padding: const EdgeInsets.only(top: 3), child: Text('Add her to the milking list?', style: TextStyle(fontSize: 12, color: hintColor, height: 1.5))),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: OutlinedButton(onPressed: () => setState(() => _milkStepChoice = 'reminded'), child: const Text('Remind me later'))),
            const SizedBox(width: 8),
            Expanded(flex: 2, child: ElevatedButton(onPressed: () => setState(() => _milkStepChoice = 'added'), child: const Text('Yes, add'))),
          ],
        ),
      ],
    );
  }

  Widget _lactationCheckStepBody(Color textColor, Color hintColor) {
    if (_lactStepChoice == 'still') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Got it — we'll check again in 10 days.", style: TextStyle(fontSize: 13, color: hintColor)),
          const SizedBox(height: 14),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => setState(() => _lactStepChoice = 'pending'), child: const Text('Skip ahead (10 days)'))),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Lactation period ending — Gauri', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
        Padding(padding: const EdgeInsets.only(top: 3), child: Text('Is Gauri still milking, or has she entered her resting period?', style: TextStyle(fontSize: 12, color: hintColor, height: 1.5))),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: OutlinedButton(onPressed: () => setState(() => _lactStepChoice = 'still'), child: const Text('Still milking'))),
            const SizedBox(width: 8),
            Expanded(flex: 2, child: ElevatedButton(onPressed: () => _goTo(_SeqStep.dry), child: const Text('Entered resting period'))),
          ],
        ),
      ],
    );
  }

  Widget _dryStepBody(Color textColor, Color hintColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Dry / resting period — Gauri', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
        Padding(padding: const EdgeInsets.only(top: 3), child: Text("60-day dry period — Gauri is resting and won't produce milk. She'll be ready for her next heat cycle after this.", style: TextStyle(fontSize: 12, color: hintColor, height: 1.5))),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => _goTo(_SeqStep.complete), child: const Text('Finish'))),
      ],
    );
  }
}
