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
    final textColor = isDark ? Colors.white : VanixColors.textPrimary;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Milk Entry' : 'Add Milk Entry'),
        actions: [
          if (isEdit) IconButton(onPressed: _confirmDelete, icon: const Icon(Icons.delete_outline, color: VanixColors.danger)),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            children: [
              const Text('FARM', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 1.1, color: VanixColors.textHint)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _farm,
                items: [for (final f in MilkSeed.farms) DropdownMenuItem(value: f, child: Text(f))],
                onChanged: (v) => setState(() => _farm = v!),
              ),
              const SizedBox(height: 20),
              const Text('COW', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 1.1, color: VanixColors.textHint)),
              const SizedBox(height: 8),
              DropdownButtonFormField<Cow>(
                initialValue: _cow,
                items: [for (final c in MilkSeed.cows) DropdownMenuItem(value: c, child: Text(c.display, overflow: TextOverflow.ellipsis))],
                onChanged: (v) => setState(() => _cow = v!),
              ),
              const SizedBox(height: 20),
              const Text('DATE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 1.1, color: VanixColors.textHint)),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${_date.day}/${_date.month}/${_date.year}', style: TextStyle(color: textColor)),
                      const Icon(Icons.calendar_today_outlined, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('MILKING SESSION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 1.1, color: VanixColors.textHint)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _SessionPill(label: 'Morning', active: _session == MilkSession.morning, locked: false, onTap: () => _selectSession(MilkSession.morning))),
                  const SizedBox(width: 10),
                  Expanded(child: _SessionPill(label: 'Evening', active: _session == MilkSession.evening, locked: _eveningLocked, onTap: () => _selectSession(MilkSession.evening))),
                ],
              ),
              if (_eveningLocked) const Padding(padding: EdgeInsets.only(top: 6), child: Text('Evening unlocks at 17:00 today', style: TextStyle(fontSize: 11, color: VanixColors.textHint))),
              const SizedBox(height: 24),
              const Text('LITRES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 1.1, color: VanixColors.textHint)),
              const SizedBox(height: 8),
              TextField(
                controller: _litresCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                decoration: const InputDecoration(border: UnderlineInputBorder(), suffixText: 'L'),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel'))),
                  const SizedBox(width: 10),
                  Expanded(child: ElevatedButton(onPressed: _onSave, child: const Text('Save'))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionPill extends StatelessWidget {
  final String label;
  final bool active, locked;
  final VoidCallback onTap;
  const _SessionPill({required this.label, required this.active, required this.locked, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? VanixColors.darkPrimary : Colors.transparent,
          border: Border.all(color: active ? VanixColors.darkPrimary : VanixColors.border),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (locked) const Padding(padding: EdgeInsets.only(right: 6), child: Icon(Icons.lock_outline, size: 13, color: VanixColors.textHint)),
            Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: active ? Colors.white : (locked ? VanixColors.textHint : VanixColors.textPrimary))),
          ],
        ),
      ),
    );
  }
}
