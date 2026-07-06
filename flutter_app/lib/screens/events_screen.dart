import 'dart:async';
import 'package:flutter/material.dart';
import '../i18n/strings.dart';
import '../state/app_state.dart';
import '../theme/vanix_theme.dart';
import '../widgets/vanix_bottom_nav.dart';
import '../widgets/vanix_nav_items.dart';
import 'milk_log_screen.dart';

enum _Tab { all, action, reminders }

/// Shared by every P0 card (Fever / Abortion / Fresh Cow) — diagnostic
/// confirm -> vet email -> requested. Mirrors evVetRequestFlow() in
/// vanix_screens.html.
enum _VetFlowState { initial, falseAlarm, awaitingEmail, requested }

/// Heat is a single evolving card, not a state machine of separate alerts.
/// Detection starts a real 24h clock (`_heatStartedAt`) immediately; Yes/No
/// is just the farmer's acknowledgement and does not pause/reset the clock.
/// `dismissed`/`logged`/`expired` are terminal; while `active`, the visible
/// phase (pre/optimal/suboptimal) is derived from elapsed time every tick.
enum _HeatState { initial, dismissed, active, logged, expired }
enum _PregState { initial, failed, confirmed }

/// Shared by every P2 diagnostic card (Mastitis / Lameness / Ketosis) —
/// confirm -> flagged for physical inspection, no vet email. Mirrors
/// evInspectionFlow() in vanix_screens.html.
enum _InspectState { initial, falseAlarm, flagged }

/// Shared by every single-acknowledge card (Proestrus / Herd Heat Stress /
/// Calibration Complete). Mirrors evAcknowledgeFlow() in vanix_screens.html.
enum _AckState { initial, acknowledged }

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
  final _feverEmailCtrl = TextEditingController();
  final _abortEmailCtrl = TextEditingController();
  final _freshCowEmailCtrl = TextEditingController();

  // P1 — actionable
  _HeatState _heat = _HeatState.initial;
  bool _heatConfirmed = false;
  String _heatMethod = 'AI';
  final _heatTechCtrl = TextEditingController();
  late final DateTime _heatStartedAt;
  Timer? _heatTimer;
  // DEMO: 24 real hours compressed into 24 real seconds (1s = 1 simulated
  // hour) purely so the phase transitions are demoable live — replace with
  // the real backend peak_timestamp once wired up (Cattle Health Logic v3.1,
  // Block 7).
  static const double _simHoursPerSecond = 1;

  _PregState _preg = _PregState.initial;
  _AckState _gestation = _AckState.initial;

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
      if (_heat == _HeatState.active && _heatElapsedSimHours >= 24) {
        setState(() { _heat = _HeatState.expired; widget.appState.resolveEvent(); });
        _heatTimer?.cancel();
        return;
      }
      if (_heat == _HeatState.active) setState(() {});
    });
  }

  double get _heatElapsedSimHours => DateTime.now().difference(_heatStartedAt).inMilliseconds / 1000 * _simHoursPerSecond;

  @override
  void dispose() {
    _heatTimer?.cancel();
    _feverEmailCtrl.dispose();
    _abortEmailCtrl.dispose();
    _freshCowEmailCtrl.dispose();
    _heatTechCtrl.dispose();
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
                      const Text('Health, breeding and reminders across all your farms', style: TextStyle(fontSize: 12, color: VanixColors.textHint)),
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
                        _buildMastitisCard(isDark),
                        const SizedBox(height: 10),
                        _buildLamenessCard(isDark),
                        const SizedBox(height: 10),
                        _buildKetosisCard(isDark),
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
                        _ReminderCard(icon: Icons.child_care, title: 'Delivery approaching — Dhauli', sub: 'Expected around 12 Jul — prepare the calving pen. She starts milking after calving.', isDark: isDark),
                        const SizedBox(height: 8),
                        _ReminderCard(icon: Icons.vaccines_outlined, title: 'FMD vaccination due', sub: '5 cows at Green Valley Farm — due 8 Jul', isDark: isDark),
                        const SizedBox(height: 8),
                        _ReminderCard(icon: Icons.medical_services_outlined, title: 'Quarterly vet check-up', sub: 'Sunrise Dairy — 15 Jul, Dr. Sharma', isDark: isDark),
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
    switch (_fever) {
      case _VetFlowState.initial:
        return _ActionCard(
          bg: VanixColors.dangerBg,
          border: VanixColors.danger,
          escalated: true,
          priority: _Priority.p0,
          channel: 'Push + SMS · Immediate vet visit',
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
                  Expanded(flex: 2, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: VanixColors.danger), onPressed: () => setState(() => _fever = _VetFlowState.awaitingEmail), child: const Text("Yes, it's fever"))),
                ],
              ),
            ],
          ),
        );
      case _VetFlowState.falseAlarm:
        return _ActionCard(
          bg: VanixColors.bgCard,
          border: VanixColors.border,
          priority: _Priority.p0,
          channel: 'Push + SMS · Immediate vet visit',
          title: 'Suspected fever — Kajri',
          sub: 'Sustained high temperature for 3 days with very little movement — she has mostly stayed in one spot.',
          meta: 'Green Valley Farm · Belt 63 · since 30 Jun',
          child: const Padding(padding: EdgeInsets.only(top: 12), child: Text('Marked as false alarm — monitoring continues. The owner has been notified.', style: TextStyle(fontSize: 13, color: VanixColors.textHint))),
        );
      case _VetFlowState.awaitingEmail:
        return _ActionCard(
          bg: VanixColors.dangerBg,
          border: VanixColors.danger,
          priority: _Priority.p0,
          channel: 'Push + SMS · Immediate vet visit',
          title: 'Suspected fever — Kajri',
          sub: 'Sustained high temperature for 3 days with very little movement — she has mostly stayed in one spot.',
          meta: 'Green Valley Farm · Belt 63 · since 30 Jun',
          child: _vetEmailForm(_feverEmailCtrl, () => setState(() { _fever = _VetFlowState.requested; widget.appState.resolveEvent(); })),
        );
      case _VetFlowState.requested:
        return _ActionCard(
          bg: VanixColors.activeBg,
          border: VanixColors.greenDeep,
          priority: _Priority.p0,
          channel: 'Push + SMS · Immediate vet visit',
          title: 'Suspected fever — Kajri',
          sub: 'Sustained high temperature for 3 days with very little movement — she has mostly stayed in one spot.',
          meta: 'Green Valley Farm · Belt 63 · since 30 Jun',
          child: _vetRequestedMessage('Kajri · Fever · Green Valley Farm', _feverEmailCtrl.text),
        );
    }
  }

  // ── P0: Abortion / pregnancy loss ──
  Widget _buildAbortCard(bool isDark) {
    switch (_abort) {
      case _VetFlowState.initial:
        return _ActionCard(
          bg: VanixColors.dangerBg,
          border: VanixColors.danger,
          priority: _Priority.p0,
          channel: 'Push + SMS · Immediate vet visit',
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
                  Expanded(flex: 2, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: VanixColors.danger), onPressed: () => setState(() => _abort = _VetFlowState.awaitingEmail), child: const Text('Yes, report to vet'))),
                ],
              ),
            ],
          ),
        );
      case _VetFlowState.falseAlarm:
        return _ActionCard(
          bg: VanixColors.bgCard,
          border: VanixColors.border,
          priority: _Priority.p0,
          channel: 'Push + SMS · Immediate vet visit',
          title: 'Possible pregnancy loss — Mohini',
          sub: 'Sudden drop in rumination with a sustained temperature rise over the last 3 hours.',
          meta: 'Sunrise Dairy · Belt 91 · Day 48 of pregnancy',
          child: const Padding(padding: EdgeInsets.only(top: 12), child: Text('Marked as false alarm — monitoring continues.', style: TextStyle(fontSize: 13, color: VanixColors.textHint))),
        );
      case _VetFlowState.awaitingEmail:
        return _ActionCard(
          bg: VanixColors.dangerBg,
          border: VanixColors.danger,
          priority: _Priority.p0,
          channel: 'Push + SMS · Immediate vet visit',
          title: 'Possible pregnancy loss — Mohini',
          sub: 'Sudden drop in rumination with a sustained temperature rise over the last 3 hours.',
          meta: 'Sunrise Dairy · Belt 91 · Day 48 of pregnancy',
          child: _vetEmailForm(_abortEmailCtrl, () => setState(() { _abort = _VetFlowState.requested; widget.appState.resolveEvent(); })),
        );
      case _VetFlowState.requested:
        return _ActionCard(
          bg: VanixColors.activeBg,
          border: VanixColors.greenDeep,
          priority: _Priority.p0,
          channel: 'Push + SMS · Immediate vet visit',
          title: 'Possible pregnancy loss — Mohini',
          sub: 'Sudden drop in rumination with a sustained temperature rise over the last 3 hours.',
          meta: 'Sunrise Dairy · Belt 91 · Day 48 of pregnancy',
          child: _vetRequestedMessage('Mohini · Pregnancy loss · Sunrise Dairy', _abortEmailCtrl.text),
        );
    }
  }

  // ── P0: Fresh cow / post-calving monitor ──
  Widget _buildFreshCowCard(bool isDark) {
    switch (_freshCow) {
      case _VetFlowState.initial:
        return _ActionCard(
          bg: VanixColors.dangerBg,
          border: VanixColors.danger,
          priority: _Priority.p0,
          channel: 'Push + SMS · Immediate vet visit',
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
                  Expanded(flex: 2, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: VanixColors.danger), onPressed: () => setState(() => _freshCow = _VetFlowState.awaitingEmail), child: const Text('Yes, report to vet'))),
                ],
              ),
            ],
          ),
        );
      case _VetFlowState.falseAlarm:
        return _ActionCard(
          bg: VanixColors.bgCard,
          border: VanixColors.border,
          priority: _Priority.p0,
          channel: 'Push + SMS · Immediate vet visit',
          title: 'Fresh cow health dip — Ganga',
          sub: 'Calved 6 days ago and her health score has dropped — early days post-calving carry higher metabolic risk.',
          meta: 'Green Valley Farm · Belt 27 · Day 6 post-calving',
          child: const Padding(padding: EdgeInsets.only(top: 12), child: Text('Marked as false alarm — monitoring continues.', style: TextStyle(fontSize: 13, color: VanixColors.textHint))),
        );
      case _VetFlowState.awaitingEmail:
        return _ActionCard(
          bg: VanixColors.dangerBg,
          border: VanixColors.danger,
          priority: _Priority.p0,
          channel: 'Push + SMS · Immediate vet visit',
          title: 'Fresh cow health dip — Ganga',
          sub: 'Calved 6 days ago and her health score has dropped — early days post-calving carry higher metabolic risk.',
          meta: 'Green Valley Farm · Belt 27 · Day 6 post-calving',
          child: _vetEmailForm(_freshCowEmailCtrl, () => setState(() { _freshCow = _VetFlowState.requested; widget.appState.resolveEvent(); })),
        );
      case _VetFlowState.requested:
        return _ActionCard(
          bg: VanixColors.activeBg,
          border: VanixColors.greenDeep,
          priority: _Priority.p0,
          channel: 'Push + SMS · Immediate vet visit',
          title: 'Fresh cow health dip — Ganga',
          sub: 'Calved 6 days ago and her health score has dropped — early days post-calving carry higher metabolic risk.',
          meta: 'Green Valley Farm · Belt 27 · Day 6 post-calving',
          child: _vetRequestedMessage('Ganga · Post-calving · Green Valley Farm', _freshCowEmailCtrl.text),
        );
    }
  }

  // shared vet-email input + send button (P0 cards)
  Widget _vetEmailForm(TextEditingController ctrl, VoidCallback onSent) {
    return _VetEmailForm(controller: ctrl, onSent: onSent);
  }

  Widget _vetRequestedMessage(String context, String email) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Vet appointment requested ✓', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: VanixColors.greenInk)),
          Text("Sent to ${email.isEmpty ? 'the vet' : email} — $context. You'll be notified when the vet confirms.", style: const TextStyle(fontSize: 12, color: VanixColors.textHint)),
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
    const title = 'Heat cycle detected — Gauri';
    const sub = 'Temperature swinging up and down with high movement since 04:30 this morning.';
    const meta = 'Green Valley Farm · Belt 41 · detected 04:30';

    if (_heat == _HeatState.dismissed) {
      return _ActionCard(
        bg: VanixColors.bgCard,
        border: VanixColors.border,
        priority: _Priority.p1,
        channel: 'App notification · Schedule inseminator',
        title: title,
        sub: sub,
        meta: 'Green Valley Farm · Belt 41',
        child: const Padding(padding: EdgeInsets.only(top: 12), child: Text('Marked as not in heat — monitoring continues.', style: TextStyle(fontSize: 13, color: VanixColors.textHint))),
      );
    }
    if (_heat == _HeatState.expired) {
      return _ActionCard(
        bg: VanixColors.bgCard,
        border: VanixColors.border,
        priority: _Priority.p1,
        channel: 'App notification · Schedule inseminator',
        title: title,
        sub: sub,
        meta: 'Green Valley Farm · Belt 41',
        child: const Padding(padding: EdgeInsets.only(top: 12), child: Text('Window closed — no insemination logged. Heat cycle monitoring resumes.', style: TextStyle(fontSize: 13, color: VanixColors.textHint))),
      );
    }
    if (_heat == _HeatState.logged) {
      return _ActionCard(
        bg: VanixColors.activeBg,
        border: VanixColors.greenDeep,
        priority: _Priority.p1,
        channel: 'App notification · Schedule inseminator',
        title: title,
        sub: sub,
        meta: 'Green Valley Farm · Belt 41',
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Insemination logged ✓ — 21-day watch started', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: VanixColors.greenInk)),
              Text("Method: $_heatMethod${_heatTechCtrl.text.isNotEmpty ? ' · ${_heatTechCtrl.text}' : ''}. If no heat returns by 24 Jul, you'll get a pregnancy-check alert. If heat returns earlier, the cycle restarts.", style: const TextStyle(fontSize: 12, color: VanixColors.textHint)),
            ],
          ),
        ),
      );
    }

    // _HeatState.initial or .active — same evolving display, driven by _heatElapsedSimHours.
    final h = _heatElapsedSimHours;
    String label;
    double pct;
    Color color;
    if (h < 6) {
      label = 'Pre-insemination — window opens in ${(6 - h).ceil()}h';
      pct = h / 6;
      color = VanixColors.warningInk;
    } else if (h < 18) {
      label = 'Optimal window — ${(18 - h).ceil()}h left';
      pct = (h - 6) / 12;
      color = VanixColors.greenInk;
    } else {
      label = 'Suboptimal window — act soon, ${(24 - h).ceil()}h left';
      pct = (h - 18) / 6;
      color = VanixColors.danger;
    }

    return _ActionCard(
      bg: VanixColors.warningBg,
      border: VanixColors.warning,
      priority: _Priority.p1,
      channel: 'App notification · Schedule inseminator',
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
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(value: pct.clamp(0, 1), minHeight: 6, backgroundColor: Colors.black.withOpacity(0.10), valueColor: AlwaysStoppedAnimation(color)),
            ),
            const SizedBox(height: 6),
            Text(
              _heatConfirmed ? 'Enter the insemination details once done.' : 'Best results within 6-18h of detection. The window opens automatically — no need to refresh.',
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
                      style: ElevatedButton.styleFrom(backgroundColor: VanixColors.warningInk),
                      onPressed: () => setState(() { _heatConfirmed = true; _heat = _HeatState.active; }),
                      child: const Text('Yes, in heat'),
                    ),
                  ),
                ],
              ),
            ],
            if (_heatConfirmed && h >= 6) ...[
              const SizedBox(height: 10),
              const Text('Log insemination', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(backgroundColor: _heatMethod == 'AI' ? VanixColors.darkPrimary : null, foregroundColor: _heatMethod == 'AI' ? Colors.white : VanixColors.textPrimary),
                      onPressed: () => setState(() => _heatMethod = 'AI'),
                      child: const Text('AI'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(backgroundColor: _heatMethod == 'Natural' ? VanixColors.darkPrimary : null, foregroundColor: _heatMethod == 'Natural' ? Colors.white : VanixColors.textPrimary),
                      onPressed: () => setState(() => _heatMethod = 'Natural'),
                      child: const Text('Natural'),
                    ),
                  ),
                ],
              ),
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
    switch (_preg) {
      case _PregState.initial:
        return _ActionCard(
          bg: VanixColors.warningBg,
          border: VanixColors.warning,
          priority: _Priority.p1,
          channel: 'App notification · Confirm with vet',
          title: 'Pregnancy check due — Mohini',
          sub: '21 days since insemination and no heat detected. Call your vet to confirm the pregnancy.',
          meta: 'Sunrise Dairy · Belt 91 · inseminated 12 Jun',
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () => setState(() { _preg = _PregState.failed; widget.appState.resolveEvent(); }), child: const Text('Not pregnant'))),
                const SizedBox(width: 8),
                Expanded(flex: 2, child: ElevatedButton(onPressed: () => setState(() { _preg = _PregState.confirmed; widget.appState.resolveEvent(); }), child: const Text('Vet confirmed — pregnant'))),
              ],
            ),
          ),
        );
      case _PregState.failed:
        return _ActionCard(
          bg: VanixColors.bgCard,
          border: VanixColors.border,
          priority: _Priority.p1,
          channel: 'App notification · Confirm with vet',
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
          bg: VanixColors.activeBg,
          border: VanixColors.greenDeep,
          priority: _Priority.p1,
          channel: 'App notification · Confirm with vet',
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

  // shared: P2 diagnostic card builder (Mastitis / Lameness / Ketosis)
  Widget _buildInspectCard({
    required bool isDark,
    required _InspectState state,
    required ValueChanged<_InspectState> onChange,
    required String title,
    required String sub,
    required String meta,
    required String question,
  }) {
    switch (state) {
      case _InspectState.initial:
        return _ActionCard(
          bg: VanixColors.bgCard,
          border: VanixColors.border,
          leftAccentColor: VanixColors.warning,
          leftAccentWidth: 2,
          priority: _Priority.p2,
          channel: 'App inbox · Physical inspection',
          title: title,
          sub: sub,
          meta: meta,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(padding: const EdgeInsets.only(top: 12, bottom: 10), child: Text(question, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => onChange(_InspectState.falseAlarm), child: const Text('No'))),
                  const SizedBox(width: 8),
                  Expanded(flex: 2, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: VanixColors.warning, foregroundColor: VanixColors.darkPrimary), onPressed: () => onChange(_InspectState.flagged), child: const Text('Yes, flag it'))),
                ],
              ),
            ],
          ),
        );
      case _InspectState.falseAlarm:
        return _ActionCard(
          bg: VanixColors.bgCard,
          border: VanixColors.border,
          priority: _Priority.p2,
          channel: 'App inbox · Physical inspection',
          title: title,
          sub: sub,
          meta: meta,
          child: const Padding(padding: EdgeInsets.only(top: 12), child: Text('Marked as false alarm — monitoring continues.', style: TextStyle(fontSize: 13, color: VanixColors.textHint))),
        );
      case _InspectState.flagged:
        return _ActionCard(
          bg: VanixColors.bgCard,
          border: VanixColors.border,
          priority: _Priority.p2,
          channel: 'App inbox · Physical inspection',
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
      );

  Widget _buildLamenessCard(bool isDark) => _buildInspectCard(
        isDark: isDark,
        state: _lameness,
        onChange: (s) => setState(() { _lameness = s; if (s != _InspectState.initial) widget.appState.resolveEvent(); }),
        title: 'Possible lameness — Dhauli',
        sub: 'Barely standing and resting far more than usual — possible leg or hoof issue.',
        meta: 'Green Valley Farm · Belt 18',
        question: 'Does Dhauli seem to be limping?',
      );

  Widget _buildKetosisCard(bool isDark) => _buildInspectCard(
        isDark: isDark,
        state: _ketosis,
        onChange: (s) => setState(() { _ketosis = s; if (s != _InspectState.initial) widget.appState.resolveEvent(); }),
        title: 'Possible ketosis — Lakshmi',
        sub: 'Reduced rumination this early in her milking cycle — a metabolic condition common just after calving.',
        meta: 'Green Valley Farm · Belt 52 · Day 12 in milk',
        question: 'Does Lakshmi seem lethargic or off her feed?',
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
  }) {
    final isP2 = priority == _Priority.p2;
    if (state == _AckState.initial) {
      return _ActionCard(
        bg: VanixColors.bgCard,
        border: VanixColors.border,
        leftAccentColor: isP2 ? VanixColors.warning : null,
        leftAccentWidth: isP2 ? 2 : 0,
        priority: priority,
        channel: isP2 ? 'App inbox · Monitor closely' : 'App inbox · Info only',
        title: title,
        sub: sub,
        meta: meta,
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => onChange(_AckState.acknowledged), child: Text(buttonLabel))),
        ),
      );
    }
    return _ActionCard(
      bg: VanixColors.bgCard,
      border: VanixColors.border,
      priority: priority,
      channel: isP2 ? 'App inbox · Monitor closely' : 'App inbox · Info only',
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
        priority: _Priority.p2,
        title: 'Early heat signs — Kajri',
        sub: "Mild temperature and activity rise — possible early signs of heat starting. We'll alert you again if it strengthens.",
        meta: 'Green Valley Farm · Belt 63',
        buttonLabel: 'Got it, watching',
        resolvedMessage: "Watching Kajri closely — you'll get a separate alert if this strengthens to confirmed heat.",
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
      );
}

// ── Priority chip (P0-P3) — reuses only the locked color tokens ──
enum _Priority { p0, p1, p2, p3 }

class _PriorityChip extends StatelessWidget {
  final _Priority priority;
  const _PriorityChip({required this.priority});

  @override
  Widget build(BuildContext context) {
    switch (priority) {
      case _Priority.p0:
        return _chip('P0 · CRITICAL', bg: const Color(0xFF8B2800), fg: Colors.white, outline: false);
      case _Priority.p1:
        return _chip('P1 · ACTIONABLE', bg: VanixColors.warningInk, fg: Colors.white, outline: false);
      case _Priority.p2:
        return _chip('P2 · WARNING', bg: VanixColors.warningBg, fg: VanixColors.warningInk, outline: true, borderColor: VanixColors.warning);
      case _Priority.p3:
        return _chip('P3 · INFO', bg: VanixColors.bgCard, fg: VanixColors.textHint, outline: true, borderColor: VanixColors.border);
    }
  }

  Widget _chip(String label, {required Color bg, required Color fg, required bool outline, Color? borderColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10), border: outline ? Border.all(color: borderColor!) : null),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

class _VetEmailForm extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSent;
  const _VetEmailForm({required this.controller, required this.onSent});

  @override
  State<_VetEmailForm> createState() => _VetEmailFormState();
}

class _VetEmailFormState extends State<_VetEmailForm> {
  bool _invalid = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Request a vet appointment', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextField(
            controller: widget.controller,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: "Vet's email — vet@example.com",
              enabledBorder: _invalid ? OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: VanixColors.danger, width: 1.5)) : null,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: VanixColors.danger),
              onPressed: () {
                if (!widget.controller.text.contains('@')) {
                  setState(() => _invalid = true);
                  return;
                }
                widget.onSent();
              },
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
  final String channel;
  final String title, sub;
  final String? meta;
  final Widget child;
  final bool escalated;

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
    required this.child,
    this.escalated = false,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = leftAccentColor ?? border;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: VanixColors.textPrimary)),
                    Padding(padding: const EdgeInsets.only(top: 3), child: Text(sub, style: const TextStyle(fontSize: 12, color: VanixColors.textHint, height: 1.5))),
                    if (meta != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(meta!, style: const TextStyle(fontSize: 11, color: VanixColors.textHint))),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _PriorityChip(priority: priority),
                  if (escalated)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFF8B2800), borderRadius: BorderRadius.circular(10)),
                        child: const Text('ESCALATED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
                      ),
                    ),
                ],
              ),
            ],
          ),
          Padding(padding: const EdgeInsets.only(top: 2), child: Text(channel, style: const TextStyle(fontSize: 11, color: VanixColors.textHint))),
          child,
        ],
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final IconData icon;
  final String title, sub;
  final bool isDark;
  const _ReminderCard({required this.icon, required this.title, required this.sub, required this.isDark});

  @override
  Widget build(BuildContext context) {
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
                Row(
                  children: [
                    Flexible(child: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : VanixColors.textPrimary), overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                      decoration: BoxDecoration(color: stageColor.withOpacity(0.12), border: Border.all(color: stageColor), borderRadius: BorderRadius.circular(9)),
                      child: Text(stage, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: stageColor)),
                    ),
                  ],
                ),
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
