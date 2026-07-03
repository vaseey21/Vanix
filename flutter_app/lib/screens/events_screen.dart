import 'package:flutter/material.dart';
import '../i18n/strings.dart';
import '../state/app_state.dart';
import '../theme/vanix_theme.dart';
import '../widgets/vanix_bottom_nav.dart';
import '../widgets/vanix_nav_items.dart';
import 'milk_log_screen.dart';

enum _Tab { all, action, reminders }

enum _FeverState { initial, falseAlarm, awaitingEmail, requested }
enum _HeatState { initial, dismissed, windowOpen, watching }
enum _PregState { initial, failed, confirmed }

/// Events — mirrors #page-events in vanix_screens.html: All / Needs action /
/// Reminders tabs, three morphing action cards (fever, heat, pregnancy
/// check), reminders, and a date-grouped history timeline. Card resolution
/// calls AppState.resolveEvent() so the badge/dot stays synced with every
/// other nav on screen (Home, Milk Log) exactly like the JS evUpdateBadges().
class EventsScreen extends StatefulWidget {
  final AppState appState;
  const EventsScreen({super.key, required this.appState});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final int _navIndex = 3;
  _Tab _tab = _Tab.all;

  _FeverState _fever = _FeverState.initial;
  _HeatState _heat = _HeatState.initial;
  _PregState _preg = _PregState.initial;
  final _vetEmailCtrl = TextEditingController();

  @override
  void dispose() {
    _vetEmailCtrl.dispose();
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
                        _buildHeatCard(isDark),
                        const SizedBox(height: 10),
                        _buildPregCard(isDark),
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

  Widget _buildFeverCard(bool isDark) {
    switch (_fever) {
      case _FeverState.initial:
        return _ActionCard(
          bg: VanixColors.dangerBg,
          border: VanixColors.danger,
          escalated: true,
          title: 'Suspected fever — Kajri',
          sub: 'Sustained high temperature for 3 days with very little movement — she has mostly stayed in one spot.',
          meta: 'Green Valley Farm · Belt 63 · since 30 Jun',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(padding: EdgeInsets.only(top: 12, bottom: 10), child: Text('Does Kajri look unwell to you?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => setState(() { _fever = _FeverState.falseAlarm; widget.appState.resolveEvent(); }), child: const Text("No, she's fine"))),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: VanixColors.danger),
                      onPressed: () => setState(() => _fever = _FeverState.awaitingEmail),
                      child: const Text("Yes, it's fever"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      case _FeverState.falseAlarm:
        return _ActionCard(
          bg: VanixColors.bgCard,
          border: VanixColors.border,
          title: 'Suspected fever — Kajri',
          sub: 'Sustained high temperature for 3 days with very little movement — she has mostly stayed in one spot.',
          meta: 'Green Valley Farm · Belt 63 · since 30 Jun',
          child: const Padding(padding: EdgeInsets.only(top: 12), child: Text('Marked as false alarm — monitoring continues. The owner has been notified.', style: TextStyle(fontSize: 13, color: VanixColors.textHint))),
        );
      case _FeverState.awaitingEmail:
        return _ActionCard(
          bg: VanixColors.dangerBg,
          border: VanixColors.danger,
          title: 'Suspected fever — Kajri',
          sub: 'Sustained high temperature for 3 days with very little movement — she has mostly stayed in one spot.',
          meta: 'Green Valley Farm · Belt 63 · since 30 Jun',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(padding: EdgeInsets.only(top: 12, bottom: 8), child: Text('Request a vet appointment', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
              TextField(
                controller: _vetEmailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: "Vet's email — vet@example.com"),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: VanixColors.danger),
                  onPressed: () {
                    if (!_vetEmailCtrl.text.contains('@')) return;
                    setState(() { _fever = _FeverState.requested; widget.appState.resolveEvent(); });
                  },
                  child: const Text('Send appointment request'),
                ),
              ),
            ],
          ),
        );
      case _FeverState.requested:
        return _ActionCard(
          bg: VanixColors.activeBg,
          border: VanixColors.greenDeep,
          title: 'Suspected fever — Kajri',
          sub: 'Sustained high temperature for 3 days with very little movement — she has mostly stayed in one spot.',
          meta: 'Green Valley Farm · Belt 63 · since 30 Jun',
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Vet appointment requested ✓', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: VanixColors.greenInk)),
                Text("Sent to ${_vetEmailCtrl.text} — Kajri · Fever · Green Valley Farm. You'll be notified when the vet confirms.", style: const TextStyle(fontSize: 12, color: VanixColors.textHint)),
              ],
            ),
          ),
        );
    }
  }

  Widget _buildHeatCard(bool isDark) {
    switch (_heat) {
      case _HeatState.initial:
        return _ActionCard(
          bg: VanixColors.warningBg,
          border: VanixColors.warning,
          title: 'Heat cycle detected — Gauri',
          sub: 'Temperature swinging up and down with high movement since 04:30 this morning.',
          meta: 'Green Valley Farm · Belt 41 · auto-confirms in 4h',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(padding: EdgeInsets.only(top: 12, bottom: 10), child: Text('Is Gauri in heat?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => setState(() { _heat = _HeatState.dismissed; widget.appState.resolveEvent(); }), child: const Text('No'))),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: VanixColors.warningInk),
                      onPressed: () => setState(() => _heat = _HeatState.windowOpen),
                      child: const Text('Yes, in heat'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      case _HeatState.dismissed:
        return _ActionCard(
          bg: VanixColors.bgCard,
          border: VanixColors.border,
          title: 'Heat cycle detected — Gauri',
          sub: 'Temperature swinging up and down with high movement since 04:30 this morning.',
          meta: 'Green Valley Farm · Belt 41',
          child: const Padding(padding: EdgeInsets.only(top: 12), child: Text('Marked as not in heat — monitoring continues.', style: TextStyle(fontSize: 13, color: VanixColors.textHint))),
        );
      case _HeatState.windowOpen:
        return _ActionCard(
          bg: VanixColors.warningBg,
          border: VanixColors.warning,
          title: 'Heat cycle detected — Gauri',
          sub: 'Temperature swinging up and down with high movement since 04:30 this morning.',
          meta: 'Green Valley Farm · Belt 41',
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Insemination window open — 17h 45m left', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(value: 0.08, minHeight: 6, backgroundColor: Colors.black.withOpacity(0.10), valueColor: const AlwaysStoppedAnimation(VanixColors.warningInk)),
                ),
                const SizedBox(height: 6),
                const Text('Best results within 18 hours of heat onset. Log the insemination once done.', style: TextStyle(fontSize: 12, color: VanixColors.textHint)),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(onPressed: () => setState(() { _heat = _HeatState.watching; widget.appState.resolveEvent(); }), child: const Text('Log insemination')),
                ),
              ],
            ),
          ),
        );
      case _HeatState.watching:
        return _ActionCard(
          bg: VanixColors.activeBg,
          border: VanixColors.greenDeep,
          title: 'Heat cycle detected — Gauri',
          sub: 'Temperature swinging up and down with high movement since 04:30 this morning.',
          meta: 'Green Valley Farm · Belt 41',
          child: const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Insemination logged ✓ — 21-day watch started', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: VanixColors.greenInk)),
                Text("If no heat returns by 24 Jul, you'll get a pregnancy-check alert. If heat returns earlier, the cycle restarts.", style: TextStyle(fontSize: 12, color: VanixColors.textHint)),
              ],
            ),
          ),
        );
    }
  }

  Widget _buildPregCard(bool isDark) {
    switch (_preg) {
      case _PregState.initial:
        return _ActionCard(
          bg: VanixColors.warningBg,
          border: VanixColors.warning,
          title: 'Pregnancy check due — Mohini',
          sub: '21 days since insemination and no heat detected. Call your vet to confirm the pregnancy.',
          meta: 'Sunrise Dairy · Belt 91 · inseminated 12 Jun',
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () => setState(() { _preg = _PregState.failed; widget.appState.resolveEvent(); }), child: const Text('Not pregnant'))),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(onPressed: () => setState(() { _preg = _PregState.confirmed; widget.appState.resolveEvent(); }), child: const Text('Vet confirmed — pregnant')),
                ),
              ],
            ),
          ),
        );
      case _PregState.failed:
        return _ActionCard(
          bg: VanixColors.bgCard,
          border: VanixColors.border,
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

class _ActionCard extends StatelessWidget {
  final Color bg, border;
  final String title, sub, meta;
  final Widget child;
  final bool escalated;
  const _ActionCard({required this.bg, required this.border, required this.title, required this.sub, required this.meta, required this.child, this.escalated = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bg, border: Border.all(color: border), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: border.withOpacity(0.35), blurRadius: 1, spreadRadius: 3)]),
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
                    Padding(padding: const EdgeInsets.only(top: 6), child: Text(meta, style: const TextStyle(fontSize: 11, color: VanixColors.textHint))),
                  ],
                ),
              ),
              if (escalated)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFF8B2800), borderRadius: BorderRadius.circular(10)),
                  child: const Text('ESCALATED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
            ],
          ),
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
