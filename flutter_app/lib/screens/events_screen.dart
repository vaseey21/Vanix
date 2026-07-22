import 'dart:async';
import 'package:flutter/material.dart';
import '../i18n/strings.dart';
import '../state/app_state.dart';
import '../theme/vanix_theme.dart';
import '../widgets/vanix_bottom_nav.dart';
import '../widgets/vanix_nav_items.dart';
import 'heat_alert_screen.dart';
import 'milk_log_screen.dart';
import 'farms_screen.dart';
import 'account_screen.dart';

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
                      Container(width: 1, color: Colors.black.withValues(alpha: 0.18)),
                      const Spacer(flex: 50),
                      Container(width: 1, color: Colors.black.withValues(alpha: 0.18)),
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
      Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center)),
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
  _InspectState _vaccination = _InspectState.initial;
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
    if (i == 1) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => FarmsScreen(appState: widget.appState)));
      return;
    }
    if (i == 2) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => MilkLogScreen(appState: widget.appState)));
      return;
    }
    if (i == 4) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => AccountScreen(appState: widget.appState)));
      return;
    }
  }

  // Entry point for the "View full cycle" link — opens the full-screen heat
  // alert carousel first, then drops into the bottom-sheet walkthrough.
  Future<void> _showFullCycleSheet(BuildContext context) async {
    await openFullCycleFlow(context, widget.appState);
  }

  // Lightweight filter sheet stub — keeps the Filter button functional
  // without duplicating the full two-pane sheet wiring here.
  void _openFilterSheet(BuildContext context) {
    final isDark = widget.appState.isDark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1C1C1C) : VanixColors.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Filter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white : VanixColors.textPrimary)),
              const SizedBox(height: 6),
              const Text('All events are shown.', style: TextStyle(fontSize: 13, color: VanixColors.textHint)),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.appState.isDark;
    final t = VanixStrings.of(widget.appState.languageCode);
    final textColor = isDark ? Colors.white : VanixColors.textPrimary;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: ListView(
              padding: const EdgeInsets.only(bottom: 120),
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                  decoration: BoxDecoration(color: isDark ? VanixColors.darkPrimary : VanixColors.bgWarm, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 28, offset: const Offset(0, 12))]),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Events', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: textColor)),
                            GestureDetector(
                              onTap: () => _showFullCycleSheet(context),
                              child: const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Text('View full cycle ›', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: VanixColors.greenInk)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _FilterButton(isDark: isDark, onTap: () => _openFilterSheet(context)),
                    ],
                  ),
                ),
                if (true)
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
                        const SizedBox(height: 10),
                        _buildVaccinationCard(isDark),
                      ],
                    ),
                  ),
                if (true)
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
                if (true)
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
                        // Matches the calendar-with-checkmark SVG in vanix_screens_preview.html
                        // (a scheduled/confirmed appointment glyph, not a medical-bag icon).
                        _ReminderCard(icon: Icons.event_available_outlined, title: 'Quarterly vet check-up', sub: 'Sunrise Dairy — 15 Jul, Dr. Sharma', startDate: DateTime(2026, 6, 24), dueDate: DateTime(2026, 7, 15), isDark: isDark),
                      ],
                    ),
                  ),
                if (true)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionLabel('History'),
                        const SizedBox(height: 10),
                        const Text('YESTERDAY — 2 JUL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: VanixColors.textHint)),
                        const SizedBox(height: 8),
                        _HistoryRow(dotColor: VanixColors.greenDeep, title: 'Calved — Ganga', stage: 'MILKING', stageColor: VanixColors.greenInk, sub: 'Healthy calf at 05:40 — Ganga now appears in the Milk Log', time: '05:40', isDark: isDark),
                        _HistoryRow(dotColor: VanixColors.warning, title: 'Pregnancy failed — Lakshmi', stage: 'HEAT WATCH', stageColor: VanixColors.warningInk, sub: 'Heat returned on day 16 of the 21-day watch — cycle restarted', time: '14:05', isDark: isDark),
                        const SizedBox(height: 12),
                        const Text('30 JUN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: VanixColors.textHint)),
                        const SizedBox(height: 8),
                        _HistoryRow(dotColor: VanixColors.danger, title: 'Vet appointment completed — Bhoori', stage: 'RECOVERED', stageColor: VanixColors.greenInk, sub: 'Fever treated by Dr. Sharma — temperature back to normal', time: '11:30', isDark: isDark),
                        _HistoryRow(dotColor: VanixColors.greenDeep, title: 'Inseminated — Mohini', stage: '21-DAY WATCH', stageColor: VanixColors.greenInk, sub: 'Within the 18h window — pregnancy check set for 3 Jul', time: '09:15', isDark: isDark),
                      ],
                    ),
                  ),
              ],
            ),
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
          timeAgo: '2h ago',
          showOwnerContext: !widget.appState.isFarmer,
          illustrationAssets: const ['assets/images/cow_icon.png'],
          imageMode: widget.appState.displayImageMode,
          photoBg: 'assets/images/fever_photo.jpg',
          photoCowBreed: 'Kajri · Jersey',
          conditionIcon: Icons.thermostat,
          conditionIconColor: VanixColors.danger,
          title: 'Suspected fever — Kajri',
          sub: 'Sustained high temperature for 3 days with very little movement — she has mostly stayed in one spot.',
          meta: 'Green Valley Farm · Belt 63 · since 30 Jun',
          photoQuestion: 'Is Kajri unwell?',
          onPhotoNo: () => setState(() { _fever = _VetFlowState.falseAlarm; widget.appState.resolveEvent(); }),
          onPhotoYes: () => setState(() => _fever = _VetFlowState.awaitingEmail),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(padding: EdgeInsets.only(top: 12, bottom: 10), child: Text('Does Kajri look unwell to you?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => setState(() { _fever = _VetFlowState.falseAlarm; widget.appState.resolveEvent(); }), child: _iconLabel(Icons.close, 'No'))),
                  const SizedBox(width: 8),
                  Expanded(flex: 2, child: ElevatedButton(onPressed: () => setState(() => _fever = _VetFlowState.awaitingEmail), child: _iconLabel(Icons.check, 'Yes, fever'))),
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
          illustrationAssets: const ['assets/images/cow_icon.png'],
          imageMode: widget.appState.displayImageMode,
          photoBg: 'assets/images/fever_photo.jpg',
          photoCowBreed: 'Kajri · Jersey',
          conditionIcon: Icons.thermostat,
          conditionIconColor: VanixColors.danger,
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
          illustrationAssets: const ['assets/images/cow_icon.png'],
          imageMode: widget.appState.displayImageMode,
          photoBg: 'assets/images/fever_photo.jpg',
          photoCowBreed: 'Kajri · Jersey',
          conditionIcon: Icons.thermostat,
          conditionIconColor: VanixColors.danger,
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
          illustrationAssets: const ['assets/images/cow_icon.png'],
          imageMode: widget.appState.displayImageMode,
          photoBg: 'assets/images/fever_photo.jpg',
          photoCowBreed: 'Kajri · Jersey',
          conditionIcon: Icons.thermostat,
          conditionIconColor: VanixColors.danger,
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
          avatarEmoji: '🐄⚠️',
          imageMode: widget.appState.displayImageMode,
          photoBg: 'assets/images/vetvisit_photo.jpg',
          photoCowBreed: 'Mohini · Gir/Sahiwal',
          title: 'Possible pregnancy loss — Mohini',
          sub: 'Sudden drop in rumination with a sustained temperature rise over the last 3 hours.',
          meta: 'Sunrise Dairy · Belt 91 · Day 48 of pregnancy',
          photoQuestion: 'Mohini at risk?',
          onPhotoNo: () => setState(() { _abort = _VetFlowState.falseAlarm; widget.appState.resolveEvent(); }),
          onPhotoYes: () => setState(() => _abort = _VetFlowState.awaitingEmail),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(padding: EdgeInsets.only(top: 12, bottom: 10), child: Text('Does Mohini show these signs?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => setState(() { _abort = _VetFlowState.falseAlarm; widget.appState.resolveEvent(); }), child: _iconLabel(Icons.close, 'No'))),
                  const SizedBox(width: 8),
                  Expanded(flex: 2, child: ElevatedButton(onPressed: () => setState(() => _abort = _VetFlowState.awaitingEmail), child: _iconLabel(Icons.check, 'Yes, notify vet'))),
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
          avatarEmoji: '🐄⚠️',
          imageMode: widget.appState.displayImageMode,
          photoBg: 'assets/images/vetvisit_photo.jpg',
          photoCowBreed: 'Mohini · Gir/Sahiwal',
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
          avatarEmoji: '🐄⚠️',
          imageMode: widget.appState.displayImageMode,
          photoBg: 'assets/images/vetvisit_photo.jpg',
          photoCowBreed: 'Mohini · Gir/Sahiwal',
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
          avatarEmoji: '🐄⚠️',
          imageMode: widget.appState.displayImageMode,
          photoBg: 'assets/images/vetvisit_photo.jpg',
          photoCowBreed: 'Mohini · Gir/Sahiwal',
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
          avatarEmoji: '🐄🆕',
          imageMode: widget.appState.displayImageMode,
          photoBg: 'assets/images/vetvisit_photo.jpg',
          photoCowBreed: 'Ganga · Ongole',
          title: 'Fresh cow health dip — Ganga',
          sub: 'Calved 6 days ago and her health score has dropped — early days post-calving carry higher metabolic risk.',
          meta: 'Green Valley Farm · Belt 27 · Day 6 post-calving',
          photoQuestion: 'Is Ganga unwell?',
          onPhotoNo: () => setState(() { _freshCow = _VetFlowState.falseAlarm; widget.appState.resolveEvent(); }),
          onPhotoYes: () => setState(() => _freshCow = _VetFlowState.awaitingEmail),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(padding: EdgeInsets.only(top: 12, bottom: 10), child: Text('Does Ganga seem off to you?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => setState(() { _freshCow = _VetFlowState.falseAlarm; widget.appState.resolveEvent(); }), child: _iconLabel(Icons.close, 'No'))),
                  const SizedBox(width: 8),
                  Expanded(flex: 2, child: ElevatedButton(onPressed: () => setState(() => _freshCow = _VetFlowState.awaitingEmail), child: _iconLabel(Icons.check, 'Yes, notify vet'))),
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
          avatarEmoji: '🐄🆕',
          imageMode: widget.appState.displayImageMode,
          photoBg: 'assets/images/vetvisit_photo.jpg',
          photoCowBreed: 'Ganga · Ongole',
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
          avatarEmoji: '🐄🆕',
          imageMode: widget.appState.displayImageMode,
          photoBg: 'assets/images/vetvisit_photo.jpg',
          photoCowBreed: 'Ganga · Ongole',
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
          avatarEmoji: '🐄🆕',
          imageMode: widget.appState.displayImageMode,
          photoBg: 'assets/images/vetvisit_photo.jpg',
          photoCowBreed: 'Ganga · Ongole',
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
          illustrationAssets: const ['assets/images/cow_icon.png', 'assets/images/bull_icon.png', 'assets/images/insemination_icon.png'],
          imageMode: widget.appState.displayImageMode,
          photoBg: 'assets/images/heat_photo.jpg',
          photoCowBreed: 'Gauri · Desi',
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
          illustrationAssets: const ['assets/images/cow_icon.png', 'assets/images/bull_icon.png', 'assets/images/insemination_icon.png'],
          imageMode: widget.appState.displayImageMode,
          photoBg: 'assets/images/heat_photo.jpg',
          photoCowBreed: 'Gauri · Desi',
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
          illustrationAssets: const ['assets/images/cow_icon.png', 'assets/images/bull_icon.png', 'assets/images/insemination_icon.png'],
          imageMode: widget.appState.displayImageMode,
          photoBg: 'assets/images/heat_photo.jpg',
          photoCowBreed: 'Gauri · Desi',
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
          illustrationAssets: const ['assets/images/cow_icon.png', 'assets/images/bull_icon.png', 'assets/images/insemination_icon.png'],
          imageMode: widget.appState.displayImageMode,
          photoBg: 'assets/images/heat_photo.jpg',
          photoCowBreed: 'Gauri · Desi',
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
          timeAgo: '20 min ago',
          showOwnerContext: !widget.appState.isFarmer,
          severityLabel: 'HIGH',
          severityColor: VanixColors.warning,
          illustrationAssets: const ['assets/images/cow_icon.png', 'assets/images/bull_icon.png', 'assets/images/insemination_icon.png'],
          imageMode: widget.appState.displayImageMode,
          photoBg: 'assets/images/heat_photo.jpg',
          photoCowBreed: 'Gauri · Desi',
      title: title,
      sub: sub,
      meta: meta,
      photoQuestion: 'Gauri in heat?',
      onPhotoNo: _heatConfirmed ? null : () => setState(() { _heat = _HeatState.dismissed; widget.appState.resolveEvent(); }),
      onPhotoYes: _heatConfirmed ? null : () => setState(() { _heatConfirmed = true; _heat = _HeatState.active; }),
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
                  Expanded(child: OutlinedButton(onPressed: () => setState(() { _heat = _HeatState.dismissed; widget.appState.resolveEvent(); }), child: _iconLabel(Icons.close, 'No'))),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => setState(() { _heatConfirmed = true; _heat = _HeatState.active; }),
                      child: _iconLabel(Icons.check, 'Yes, in heat'),
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
          illustrationAssets: const ['assets/images/pregnancy_icon.png'],
          imageMode: widget.appState.displayImageMode,
          photoBg: 'assets/images/gestation_photo.jpg',
          photoCowBreed: 'Mohini · Gir/Sahiwal',
          title: 'Pregnancy check due — Mohini',
          sub: '21 days since insemination and no heat detected — confirm if she appears pregnant.',
          meta: 'Sunrise Dairy · Belt 91 · inseminated 12 Jun',
          photoQuestion: 'Is Mohini pregnant?',
          onPhotoNo: () => setState(() { _preg = _PregState.failed; widget.appState.resolveEvent(); }),
          onPhotoYes: () => setState(() { _preg = _PregState.confirmed; widget.appState.resolveEvent(); }),
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
          illustrationAssets: const ['assets/images/pregnancy_icon.png'],
          photoBg: 'assets/images/gestation_photo.jpg',
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
          illustrationAssets: const ['assets/images/pregnancy_icon.png'],
          photoBg: 'assets/images/gestation_photo.jpg',
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
        photoBg: 'assets/images/gestation_photo.jpg',
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
        photoBg: 'assets/images/gestation_photo.jpg',
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
        imageMode: widget.appState.displayImageMode,
        photoBg: 'assets/images/gestation_photo.jpg',
        photoCowBreed: 'Lakshmi · Ongole',
        title: 'Vet on the way — Lakshmi',
        sub: '$_gestationVetName has been called for the delivery.',
        meta: meta,
        photoQuestion: 'Delivery successful?',
        onPhotoNo: () => setState(() { _gestation = _GestationState.deliveryFailed; widget.appState.resolveEvent(); }),
        onPhotoYes: () => setState(() => _gestation = _GestationState.deliveryForm),
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
        photoBg: 'assets/images/gestation_photo.jpg',
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
        photoBg: 'assets/images/gestation_photo.jpg',
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
        photoBg: 'assets/images/milking_started_photo.jpg',
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
        photoBg: 'assets/images/milking_started_photo.jpg',
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
      conditionIcon: Icons.water_drop,
      conditionIconColor: VanixColors.greenInk,
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
        photoBg: 'assets/images/milking_ended_photo.jpg',
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
        photoBg: 'assets/images/milking_ended_photo.jpg',
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
    required String photoQuestion,
    required String photoCowBreed,
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
          imageMode: widget.appState.displayImageMode,
          photoBg: 'assets/images/fever_photo.jpg',
          photoCowBreed: photoCowBreed,
          title: title,
          sub: sub,
          meta: meta,
          photoQuestion: photoQuestion,
          photoNoLabel: 'No',
          photoYesLabel: 'Flag it',
          onPhotoNo: () => onChange(_InspectState.falseAlarm),
          onPhotoYes: () => onChange(_InspectState.flagged),
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
          photoBg: 'assets/images/fever_photo.jpg',
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
          photoBg: 'assets/images/fever_photo.jpg',
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
        photoQuestion: 'Bhoori — mastitis?',
        photoCowBreed: 'Bhoori · Sahiwal',
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
        photoQuestion: 'Dhauli limping?',
        photoCowBreed: 'Dhauli · Gir',
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
        photoQuestion: 'Lakshmi off feed?',
        photoCowBreed: 'Lakshmi · Ongole',
        manager: 'Ramesh Kumar',
      );

  // Vaccination due — same P2 photo-header + title/manager compact card
  // format as Mastitis/Lameness/Ketosis, but with "Not yet" (stays pending) /
  // "Mark done" (resolves, syncs the badge) instead of a diagnostic
  // No/Flag-it choice. Mirrors #ev-vaccination in vanix_screens.html.
  Widget _buildVaccinationCard(bool isDark) {
    const title = 'Vaccination due — Dhauli';
    const sub = 'FMD booster due this week per the vaccination schedule.';
    const meta = 'Green Valley Farm · Belt 09';
    const manager = 'Ramesh Kumar';
    switch (_vaccination) {
      case _InspectState.initial:
        return _ActionCard(
          isDark: isDark,
          bg: VanixColors.bgCard,
          border: VanixColors.border,
          leftAccentColor: VanixColors.warning,
          leftAccentWidth: 2,
          priority: _Priority.p2,
          channel: 'App inbox · Vaccination schedule',
          manager: manager,
          photoBg: 'assets/images/vetvisit_photo.jpg',
          title: title,
          sub: sub,
          meta: meta,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(padding: EdgeInsets.only(top: 12, bottom: 10), child: Text('FMD vaccination due — done?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => setState(() => _vaccination = _InspectState.falseAlarm), child: const Text('Not yet', style: TextStyle(fontSize: 12.5)))),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => setState(() { _vaccination = _InspectState.flagged; widget.appState.resolveEvent(); }),
                      child: _iconLabel(Icons.check, 'Mark done'),
                    ),
                  ),
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
          channel: 'App inbox · Vaccination schedule',
          manager: manager,
          photoBg: 'assets/images/vetvisit_photo.jpg',
          title: title,
          sub: sub,
          meta: meta,
          child: const Padding(padding: EdgeInsets.only(top: 12), child: Text('Still pending — you\'ll be reminded again.', style: TextStyle(fontSize: 13, color: VanixColors.textHint))),
        );
      case _InspectState.flagged:
        return _ActionCard(
          isDark: isDark,
          bg: VanixColors.bgCard,
          border: VanixColors.border,
          priority: _Priority.p2,
          channel: 'App inbox · Vaccination schedule',
          manager: manager,
          photoBg: 'assets/images/vetvisit_photo.jpg',
          title: title,
          sub: sub,
          meta: meta,
          child: const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text('FMD vaccination recorded for Dhauli.', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: VanixColors.greenInk)),
          ),
        );
    }
  }

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

/// Filter button in the Events hero — funnel icon + "Filter" (mirrors
/// #ev-filter-btn in the HTML).
class _FilterButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;
  const _FilterButton({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1C) : VanixColors.bgCard,
          border: Border.all(color: isDark ? const Color(0xFF3A3A3A) : VanixColors.border),
          borderRadius: BorderRadius.circular(17),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.filter_alt_outlined, size: 15, color: isDark ? Colors.white : VanixColors.textPrimary),
            const SizedBox(width: 6),
            Text('Filter', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : VanixColors.textPrimary)),
          ],
        ),
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
  // How long this card has been unactioned (e.g. "2h ago") — shown to the
  // Farm Owner persona only, alongside `meta` (farm + manager context),
  // mirroring the vanix_screens.html farm-owner-only reveal.
  final String? timeAgo;
  final bool showOwnerContext;
  // Overrides the priority-derived severity badge text/color on the
  // full-bleed photo card — used by Fever/Heat so they read "CRITICAL"/"HIGH"
  // based on how long they've been unactioned, rather than reusing the
  // generic P0="CRITICAL"/P1="MEDIUM" labels other cards show.
  final String? severityLabel;
  final Color? severityColor;
  // Cow + condition emoji "illustration" leading the card (e.g. 🐄⚠️ for
  // abortion) — farmer-friendly pictorial cue, in place of a plain text-only
  // header. Legacy combo-emoji tile, still used by cards not yet swapped to
  // the real photo (Abortion, Fresh-Cow Monitor). Not every card has one yet
  // (see CLAUDE.md pending list).
  final String? avatarEmoji;
  // Real cow photo + a small SEPARATE condition icon beside it (not
  // overlapping) — Fever, Heat, Milking notification. Takes precedence over
  // avatarEmoji when set.
  final IconData? conditionIcon;
  final Color? conditionIconColor;
  // Custom line-art icon assets (cow/bull/pregnancy/insemination) shown side
  // by side, no border/tint container — Fever, Heat, Pregnancy Check Due.
  // Takes precedence over conditionIcon's cow-photo pairing when set.
  final List<String>? illustrationAssets;
  // Text/Image app-wide display preference (AppState.displayImageMode).
  // When false ("text" mode), the card always renders the plain
  // description-first layout below — avatarEmoji/conditionIcon/
  // illustrationAssets/photoBg are ignored entirely (the pre-illustration-
  // pass design). When true and photoBg is set (Fever, Heat so far), the
  // card renders as a full-bleed photo card instead.
  final bool imageMode;
  // Full-bleed background photo + cow·breed caption for the "Image" display
  // mode card (Fever, Heat) — takes precedence over avatarEmoji/
  // conditionIcon/illustrationAssets when imageMode is true.
  final String? photoBg;
  final String? photoCowBreed;
  // Full-bleed photo cards use a SHORT question + bare "No"/"Yes" CTAs over the
  // bottom scrim instead of the verbose `child` (long question + "Yes, fever"
  // etc.). When onPhotoYes is set, the photo card builds its own question/CTAs
  // and the real flow runs through these callbacks; the underlying `child`
  // (used in text mode) keeps the long copy. When onPhotoYes is null (message /
  // vet-picker / form states) the photo card just renders `child`.
  final String? photoQuestion;
  final VoidCallback? onPhotoYes;
  final VoidCallback? onPhotoNo;
  // Short CTA labels for the full-bleed photo card (default No / Yes).
  final String photoNoLabel;
  final String photoYesLabel;
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
    this.timeAgo,
    this.showOwnerContext = false,
    this.severityLabel,
    this.severityColor,
    this.avatarEmoji,
    this.conditionIcon,
    this.conditionIconColor,
    this.illustrationAssets,
    this.imageMode = false,
    this.photoBg,
    this.photoCowBreed,
    this.photoQuestion,
    this.onPhotoYes,
    this.onPhotoNo,
    this.photoNoLabel = 'No',
    this.photoYesLabel = 'Yes',
    required this.child,
    this.escalated = false,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    // Full-bleed compact photo card (Image display mode): the photo fills the
    // whole card, cow name/breed top-left, severity badge top-right, short
    // question + No/Yes over the bottom scrim. Mirrors
    // #flow-root.display-fullbleed .ev-photo-card in prototype.html, capped at
    // a compact ~300px height. Only the two-button question states use it;
    // form/message states fall through to the contained-banner layout below.
    if (imageMode && photoBg != null && photoQuestion != null && onPhotoYes != null && onPhotoNo != null) {
      return _buildFullBleedPhotoCard();
    }
    final accentColor = leftAccentColor ?? border;
    final titleColor = isDark ? Colors.white : VanixColors.textPrimary;
    // Flutter forbids a borderRadius on a border with non-uniform colors/widths,
    // so the HTML's "1px all + 4px coloured left" can't be a raw Border. We use a
    // uniform coloured outline (same severity colour the HTML border reads as) and
    // paint the thicker left accent as a clipped stripe overlay below.
    final decoration = BoxDecoration(
      color: isDark ? const Color(0xFF1C1C1C) : bg,
      border: Border.all(color: accentColor, width: 1.5),
      borderRadius: BorderRadius.circular(16),
    );

    // Compact contained-banner card (mirrors the P2 mastitis card in the
    // HTML): an optional rounded photo banner on top, then the title +
    // manager line, then the question / flow buttons bundled in `child`.
    // No priority chip, no "View Details" link.
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (photoBg != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              photoBg!,
              width: double.infinity,
              height: 130,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => Container(
                width: double.infinity,
                height: 130,
                color: isDark ? const Color(0xFF2A2A2A) : VanixColors.border,
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: titleColor)),
        if (priority == _Priority.p1)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: _P1Chip(),
          ),
        if (manager != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_outline, size: 12, color: VanixColors.textHint),
                const SizedBox(width: 3),
                Flexible(child: Text(manager!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: VanixColors.textHint))),
              ],
            ),
          ),
        if (showOwnerContext && (meta != null || timeAgo != null))
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              [if (timeAgo != null) timeAgo, if (meta != null) meta].whereType<String>().join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: VanixColors.textHint),
            ),
          ),
        child,
      ],
    );

    final card = Container(
      decoration: decoration,
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // 4px severity accent down the left edge (mirrors the HTML border-left)
          PositionedDirectional(start: 0, top: 0, bottom: 0, child: Container(width: 4, color: accentColor)),
          Padding(padding: const EdgeInsets.all(14), child: body),
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

  Widget _buildFullBleedPhotoCard() {
    // Severity badge — CRITICAL (p0) / MEDIUM (p1) / LOW (p2,p3), unless
    // `severityLabel` overrides it (Fever/Heat: CRITICAL/HIGH by elapsed time).
    String badgeText;
    Color badgeColor;
    if (severityLabel != null) {
      badgeText = severityLabel!;
      badgeColor = severityColor ?? VanixColors.warning;
    } else {
      switch (priority) {
        case _Priority.p0:
          badgeText = 'CRITICAL';
          badgeColor = VanixColors.danger;
          break;
        case _Priority.p1:
          badgeText = 'MEDIUM';
          badgeColor = VanixColors.warning;
          break;
        case _Priority.p2:
        case _Priority.p3:
          badgeText = 'LOW';
          badgeColor = VanixColors.textHint;
          break;
      }
    }

    final cowBreed = photoCowBreed ?? '';
    final parts = cowBreed.split('·');
    final cowName = parts.first.trim();
    final breed = parts.length > 1 ? parts.sublist(1).join('·').trim() : '';

    final noBtn = SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onPhotoNo,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.12),
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(photoNoLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
      ),
    );
    final yesBtn = SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onPhotoYes,
        style: ElevatedButton.styleFrom(
          backgroundColor: VanixColors.greenInk,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(photoYesLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 300,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              photoBg!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => const ColoredBox(color: Color(0xFF0A2318)),
            ),
            // Two-band dark scrim — darker top for the caption, darker bottom
            // for the question + buttons.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xD1000000), Color(0x8C000000), Color(0x00000000),
                    Color(0x00000000), Color(0xB8000000), Color(0xF2000000),
                  ],
                  stops: [0.0, 0.20, 0.33, 0.46, 0.58, 1.0],
                ),
              ),
            ),
            // Cow name + breed — top-left.
            Positioned(
              top: 18,
              left: 20,
              right: 68,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(cowName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white, height: 1.2)),
                  if (breed.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(breed, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.82))),
                    ),
                  if (showOwnerContext && (meta != null || timeAgo != null))
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          [if (timeAgo != null) timeAgo, if (meta != null) meta].whereType<String>().join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Severity badge — top-right.
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 8, 16, 9),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: const BorderRadius.only(topRight: Radius.circular(20), bottomLeft: Radius.circular(16)),
                ),
                child: Text(badgeText, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.66, color: Colors.white)),
              ),
            ),
            // Question + CTAs — pinned bottom.
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(photoQuestion!, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white, height: 1.2)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: noBtn),
                      const SizedBox(width: 12),
                      Expanded(child: yesBtn),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bell + "P1" pill shown on P1 (actionable) cards — mirrors the
/// .ev-chip.ev-chip-p1 bell-icon chip in vanix_screens_preview.html
/// (Heat/Pregnancy-check/Gestation/Milking-notification cards).
class _P1Chip extends StatelessWidget {
  const _P1Chip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: VanixColors.warningBg, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.notifications_none, size: 11, color: VanixColors.warningInk),
          SizedBox(width: 3),
          Text('P1', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: VanixColors.warningInk)),
        ],
      ),
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
      decoration: const BoxDecoration(
        color: Color(0xFF8B2800),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 1))],
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
                  decoration: BoxDecoration(color: stageColor.withValues(alpha: 0.12), border: Border.all(color: stageColor), borderRadius: BorderRadius.circular(9)),
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
// Entry point for the Events "View full cycle" link AND Home's "Cows in
// heat" row cards — opens the full-screen heat alert carousel first, then
// drops into the bottom-sheet walkthrough (mirrors window.evOpenFullCycle
// in vanix_screens_preview.html).
Future<void> openFullCycleFlow(BuildContext context, AppState appState) async {
  final result = await Navigator.of(context).push<String?>(MaterialPageRoute(builder: (_) => HeatAlertScreen(isDark: appState.isDark), fullscreenDialog: true));
  if (!context.mounted) return;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _FullCycleSheet(isDark: appState.isDark, heatPreDecision: result, restricted: result == null),
  );
}

// Direct entry into the walkthrough's gestation step — used by Home's "Cows
// in gestation" cards so they open the same full-width alert-style step card
// the walkthrough uses, not the plain Events sheet (mirrors
// window.evOpenGestationSlider in vanix_screens_preview.html).
void openGestationSliderFlow(BuildContext context, AppState appState) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _FullCycleSheet(isDark: appState.isDark, initialStep: _SeqStep.gestation9),
  );
}

class _FullCycleSheet extends StatefulWidget {
  final bool isDark;
  /// 'yes' / 'no' if the farmer already resolved the heat question on the
  /// full-screen alert; null if they dismissed it (close/"View in app").
  final String? heatPreDecision;
  /// True when entered via dismiss-without-resolving — the heat step renders
  /// a trimmed "restricted" detail view until the farmer taps Yes/No here.
  final bool restricted;
  /// When set, the sheet opens directly at this step (skipping the heat
  /// timer setup) — used to deep-link into e.g. the gestation step from Home.
  final _SeqStep? initialStep;
  const _FullCycleSheet({required this.isDark, this.heatPreDecision, this.restricted = false, this.initialStep});

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
        Text(message, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: VanixColors.greenInk, height: 1.5)),
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
