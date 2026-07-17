import 'package:flutter/material.dart';
import '../models/milk_models.dart';
import '../state/app_state.dart';
import '../theme/vanix_theme.dart';

class MilkEntryResult {
  final bool delete;
  final MilkEntry? entry;
  const MilkEntryResult.save(MilkEntry this.entry) : delete = false;
  const MilkEntryResult.delete() : entry = null, delete = true;
}

/// Add / edit a milk-log entry — mirrors #s8-page in vanix_screens.html:
/// farm + cow dropdowns, date (max today), session pills (Evening locked
/// until 17:00 today, no future sessions ever), litres, sticky Cancel/Save
/// footer. Duplicate-entry guard and session-mismatch warning both fire on
/// Save, matching the HTML confirm modals.
class MilkAddEntryScreen extends StatefulWidget {
  final AppState appState;
  final List<MilkEntry> allEntries;
  final MilkEntry? editing;
  final DateTime today;

  const MilkAddEntryScreen({super.key, required this.appState, required this.allEntries, required this.today, this.editing});

  @override
  State<MilkAddEntryScreen> createState() => _MilkAddEntryScreenState();
}

class _MilkAddEntryScreenState extends State<MilkAddEntryScreen> {
  late String _farm;
  late Cow _cow;
  late DateTime _date;
  late MilkSession _session;
  final _litresCtrl = TextEditingController();

  bool get _isToday => _date.year == widget.today.year && _date.month == widget.today.month && _date.day == widget.today.day;
  bool get _eveningLocked => _isToday && TimeOfDay.now().hour < 17;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    _farm = e?.farm ?? MilkSeed.farms.first;
    _cow = e != null ? MilkSeed.cows.firstWhere((c) => c.name == e.cow, orElse: () => MilkSeed.cows.first) : MilkSeed.cows.first;
    _date = e?.date ?? widget.today;
    _session = e?.session ?? (TimeOfDay.now().hour < 17 ? MilkSession.morning : MilkSession.evening);
    if (_session == MilkSession.evening && _eveningLocked) _session = MilkSession.morning;
    _litresCtrl.text = e != null ? e.litres.toString() : '';
  }

  @override
  void dispose() {
    _litresCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: widget.today);
    if (picked != null) {
      setState(() {
        _date = picked;
        if (_session == MilkSession.evening && _eveningLocked) _session = MilkSession.morning;
      });
    }
  }

  void _selectSession(MilkSession s) {
    if (s == MilkSession.evening && _eveningLocked) {
      _showPastSessionWarning(s);
      return;
    }
    setState(() => _session = s);
  }

  void _showPastSessionWarning(MilkSession target) {
    final hour = TimeOfDay.now().hour;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Are you sure?'),
        content: Text('This is ${17 - hour}h before the usual Evening milking time (17:00). Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _session = target);
            },
            child: const Text('Proceed'),
          ),
        ],
      ),
    );
  }

  bool _hasDuplicate() {
    return widget.allEntries.any((e) =>
        e.id != widget.editing?.id &&
        e.cow == _cow.name &&
        e.session == _session &&
        e.date.year == _date.year &&
        e.date.month == _date.month &&
        e.date.day == _date.day);
  }

  MilkEntry? _existingDuplicate() {
    try {
      return widget.allEntries.firstWhere((e) =>
          e.id != widget.editing?.id &&
          e.cow == _cow.name &&
          e.session == _session &&
          e.date.year == _date.year &&
          e.date.month == _date.month &&
          e.date.day == _date.day);
    } catch (_) {
      return null;
    }
  }

  void _onSave() {
    final litres = double.tryParse(_litresCtrl.text);
    if (litres == null || litres <= 0) return;

    if (_hasDuplicate()) {
      final dup = _existingDuplicate()!;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Entry already exists'),
          content: Text('${_cow.name} already has a ${_session.label} entry today (${dup.litres} L). Your entry will be added to it after the Farm Owner approves. Continue?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                Navigator.pop(context); // dialog
                Navigator.pop(context, MilkEntryResult.save(_buildEntry(pending: true, pendingLabel: '+$litres L (second entry)')));
              },
              child: const Text('Yes, continue'),
            ),
          ],
        ),
      );
      return;
    }

    Navigator.pop(context, MilkEntryResult.save(_buildEntry()));
  }

  MilkEntry _buildEntry({bool pending = false, String? pendingLabel}) {
    final litres = double.parse(_litresCtrl.text);
    return MilkEntry(
      id: widget.editing?.id ?? 'e${DateTime.now().microsecondsSinceEpoch}',
      cow: _cow.name,
      breed: _cow.breed,
      belt: _cow.belt,
      farm: _farm,
      manager: widget.editing?.manager ?? 'Anita',
      date: _date,
      session: _session,
      time: TimeOfDay.now(),
      litres: litres,
      pendingApproval: pending,
      pendingLabel: pendingLabel,
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete entry?'),
        content: Text('This will delete ${_cow.name} — ${_session.label} · ${_litresCtrl.text} L.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: VanixColors.danger),
            onPressed: () {
              Navigator.pop(context); // dialog
              Navigator.pop(context, const MilkEntryResult.delete());
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editing != null;
    final isDark = widget.appState.isDark;
    final bg = isDark ? VanixColors.darkPrimary : VanixColors.bgWarm;
    final cardBg = isDark ? VanixColors.darkSecond : VanixColors.bgCard;
    final textColor = isDark ? Colors.white : VanixColors.textPrimary;
    final borderColor = isDark ? VanixColors.darkBorder : VanixColors.border;
    const hintColor = VanixColors.textHint;

    InputDecoration fieldDecoration() => InputDecoration(
          isDense: true,
          filled: true,
          fillColor: cardBg,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: VanixColors.greenInk)),
        );

    Widget sectionLabel(String text) => Text(
          text,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 1.1, color: hintColor),
        );

    Widget helperText(String text) => Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(text, style: const TextStyle(fontSize: 10, color: hintColor)),
        );

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Custom header — back chevron (40x40) + title, matches #s8 header ──
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(24, 14, 24, 4),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cardBg,
                        border: Border.all(color: borderColor),
                      ),
                      child: Icon(Icons.chevron_left, size: 22, color: textColor),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      isEdit ? 'Edit Milk Entry' : 'Add Milk Entry',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: textColor),
                    ),
                  ),
                  if (isEdit)
                    InkWell(
                      onTap: _confirmDelete,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        child: const Icon(Icons.delete_outline, size: 22, color: VanixColors.danger),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsetsDirectional.fromSTEB(24, 18, 24, 8),
                children: [
                  sectionLabel('FARM'),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _farm,
                    decoration: fieldDecoration(),
                    style: TextStyle(fontSize: 15, color: textColor),
                    dropdownColor: cardBg,
                    items: [for (final f in MilkSeed.farms) DropdownMenuItem(value: f, child: Text(f))],
                    onChanged: (v) => setState(() => _farm = v!),
                  ),
                  const SizedBox(height: 14),
                  sectionLabel('COW'),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<Cow>(
                    initialValue: _cow,
                    decoration: fieldDecoration(),
                    style: TextStyle(fontSize: 15, color: textColor),
                    dropdownColor: cardBg,
                    isExpanded: true,
                    items: [for (final c in MilkSeed.cows) DropdownMenuItem(value: c, child: Text(c.display, overflow: TextOverflow.ellipsis))],
                    onChanged: (v) => setState(() => _cow = v!),
                  ),
                  helperText('Only CALVED and MILKING cows are listed'),
                  const SizedBox(height: 14),
                  sectionLabel('DATE'),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: fieldDecoration(),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${_date.day}/${_date.month}/${_date.year}', style: TextStyle(fontSize: 15, color: textColor)),
                          Icon(Icons.calendar_today_outlined, size: 16, color: hintColor),
                        ],
                      ),
                    ),
                  ),
                  helperText('Defaults to today · future dates not allowed'),
                  const SizedBox(height: 14),
                  sectionLabel('MILKING SESSION'),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(child: _SessionPill(label: 'Morning', active: _session == MilkSession.morning, locked: false, textColor: textColor, borderColor: borderColor, onTap: () => _selectSession(MilkSession.morning))),
                      const SizedBox(width: 8),
                      Expanded(child: _SessionPill(label: 'Evening', active: _session == MilkSession.evening, locked: _eveningLocked, textColor: textColor, borderColor: borderColor, onTap: () => _selectSession(MilkSession.evening))),
                    ],
                  ),
                  helperText('Defaults to the current time of day'),
                  const SizedBox(height: 28),
                  sectionLabel('LITRES'),
                  const SizedBox(height: 10),
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0xFF9A948A), width: 1.5)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _litresCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: textColor),
                            decoration: InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.only(bottom: 10),
                              hintText: '0.0',
                              hintStyle: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: hintColor),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: Text('Ltrs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: hintColor)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // ── Pinned footer — Cancel / Save, matches #s8-actions ──
            Container(
              color: bg,
              padding: const EdgeInsetsDirectional.fromSTEB(24, 12, 24, 16),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textColor,
                          side: BorderSide(color: borderColor),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        ),
                        child: const Text('Cancel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _onSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: VanixColors.greenInk,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        ),
                        child: const Text('Save', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
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

class _SessionPill extends StatelessWidget {
  final String label;
  final bool active, locked;
  final Color textColor, borderColor;
  final VoidCallback onTap;
  const _SessionPill({required this.label, required this.active, required this.locked, required this.textColor, required this.borderColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Matches #s8-sessions: active = greenInk fill/border + white w600 text;
    // locked (Evening before 17:00) = 0.4 opacity, no lock icon (per HTML).
    return Opacity(
      opacity: locked ? 0.4 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(21),
        child: Container(
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? VanixColors.greenInk : Colors.transparent,
            border: Border.all(color: active ? VanixColors.greenInk : VanixColors.border),
            borderRadius: BorderRadius.circular(21),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              color: active ? Colors.white : VanixColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
