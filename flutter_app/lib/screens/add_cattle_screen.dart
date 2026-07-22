import 'package:flutter/material.dart';
import '../i18n/farm_strings.dart';
import '../models/farm_models.dart';
import '../state/app_state.dart';
import '../theme/vanix_theme.dart';

/// Add Cattle — mirrors #page-add-cattle in prototype.html. Full-screen form
/// opened by the Farm Detail + FAB: photo upload, cattle type, breed/gender,
/// name, age + status, device details, and a cow-history block with a
/// lactation-number stepper. Cancel / Save footer.
class AddCattleScreen extends StatefulWidget {
  final AppState appState;
  final FarmModel farm;
  const AddCattleScreen({super.key, required this.appState, required this.farm});

  @override
  State<AddCattleScreen> createState() => _AddCattleScreenState();
}

class _AddCattleScreenState extends State<AddCattleScreen> {
  bool _fillHistory = true;
  int _lactation = 2;

  String get _lang => widget.appState.languageCode;
  bool get _isDark => widget.appState.isDark;

  @override
  Widget build(BuildContext context) {
    final theme = _isDark ? vanixDarkTheme(languageCode: _lang) : vanixLightTheme(languageCode: _lang);
    final textColor = _isDark ? Colors.white : VanixColors.textPrimary;
    return Theme(
      data: theme,
      child: Scaffold(
        // Background changed to white in light mode (was bgWarm) — mirrors
        // #page-add-cattle's background:#FFFFFF in vanix_screens_preview.html.
        backgroundColor: _isDark ? VanixColors.darkSecond : Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // header
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        alignment: AlignmentDirectional.centerStart,
                        icon: Icon(Icons.chevron_left, color: textColor),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(FS.t(_lang, 'addCattle'),
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: textColor)),
                          const SizedBox(height: 2),
                          Text('${FS.t(_lang, 'acSubPre')} ${widget.farm.nm(_lang)}',
                              style: const TextStyle(fontSize: 13, color: VanixColors.textHint)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // body
              Expanded(
                child: ListView(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 16, 24),
                  children: [
                    _label('acPhotoLabel'),
                    _photoUpload(),
                    _label('acCattleType', top: 18),
                    _select(FS.t(_lang, 'acTypeCow')),
                    _hint('acTypeHint'),
                    Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label('breedWord', top: 18), _select(FS.t(_lang, 'selectWord'))])),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label('genderWord', top: 18), _select(FS.t(_lang, 'selectWord'))])),
                    ]),
                    _label('acCowName', top: 18),
                    _input('e.g. Gowri'),
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _label('ageWord', top: 18),
                          Row(children: [
                            Expanded(child: _select(FS.t(_lang, 'yearsWord'))),
                            const SizedBox(width: 8),
                            Expanded(child: _select(FS.t(_lang, 'monthsWord'))),
                          ]),
                        ]),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label('cowStatusWord', top: 18), _select(FS.t(_lang, 'selectWord'))])),
                    ]),
                    _label('acDeviceDetails', top: 22, big: true),
                    _label('acBeltNo'),
                    _input('e.g. 026'),
                    _label('acMacId', top: 16),
                    _input('A4:C1:38:2B:9F:11'),
                    // cow history
                    Padding(
                      padding: const EdgeInsets.only(top: 22),
                      child: Row(children: [
                        _label('acCowHistory', top: 0, big: true),
                        const SizedBox(width: 8),
                        Text(FS.t(_lang, 'optionalWord'), style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: VanixColors.textHint)),
                      ]),
                    ),
                    const SizedBox(height: 10),
                    Row(children: [
                      _radio(FS.t(_lang, 'acFillHistory'), _fillHistory, () => setState(() => _fillHistory = true)),
                      const SizedBox(width: 18),
                      _radio(FS.t(_lang, 'acHistUnknown'), !_fillHistory, () => setState(() => _fillHistory = false)),
                    ]),
                    if (_fillHistory) _historyBlock(),
                  ],
                ),
              ),
              // footer
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: BoxDecoration(
                  color: _isDark ? VanixColors.darkPrimary : VanixColors.bgWarm,
                  border: Border(top: BorderSide(color: _isDark ? VanixColors.darkBorder : VanixColors.border)),
                ),
                child: Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 50),
                        side: BorderSide(color: _isDark ? VanixColors.darkBorder : VanixColors.border),
                        foregroundColor: textColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(FS.t(_lang, 'cancelWord')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 50),
                        backgroundColor: VanixColors.greenInk,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(FS.t(_lang, 'saveWord'), style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String key, {double top = 0, bool big = false}) => Padding(
        padding: EdgeInsets.only(top: top, bottom: 7),
        child: Text(FS.t(_lang, key).toUpperCase(),
            style: TextStyle(fontSize: big ? 12 : 11, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: VanixColors.textHint)),
      );

  Widget _hint(String key) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(FS.t(_lang, key), style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: VanixColors.textHint)),
      );

  BoxDecoration get _fieldDeco => BoxDecoration(
        color: _isDark ? VanixColors.darkSecond : VanixColors.bgCard,
        border: Border.all(color: _isDark ? VanixColors.darkBorder : VanixColors.border),
        borderRadius: BorderRadius.circular(VanixRadius.md),
      );

  Widget _input(String placeholder) {
    final textColor = _isDark ? Colors.white : VanixColors.textPrimary;
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: _fieldDeco,
      alignment: AlignmentDirectional.centerStart,
      child: TextField(
        style: TextStyle(fontSize: 15, color: textColor),
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          hintText: placeholder,
          hintStyle: const TextStyle(color: VanixColors.textHint, fontSize: 15),
        ),
      ),
    );
  }

  Widget _select(String value) {
    final textColor = _isDark ? Colors.white : VanixColors.textPrimary;
    final isPlaceholder = value == FS.t(_lang, 'selectWord') ||
        value == FS.t(_lang, 'yearsWord') ||
        value == FS.t(_lang, 'monthsWord');
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: _fieldDeco,
      child: Row(children: [
        Expanded(child: Text(value, style: TextStyle(fontSize: 15, color: isPlaceholder ? VanixColors.textHint : textColor))),
        const Icon(Icons.keyboard_arrow_down, size: 18, color: VanixColors.textHint),
      ]),
    );
  }

  Widget _photoUpload() {
    return Container(
      height: 118,
      decoration: BoxDecoration(
        color: _isDark ? VanixColors.darkSecond : VanixColors.bgCard,
        borderRadius: BorderRadius.circular(VanixRadius.lg),
        border: Border.all(color: _isDark ? VanixColors.darkBorder : VanixColors.border, width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.image_outlined, size: 22, color: VanixColors.textHint),
          const SizedBox(height: 8),
          Text(FS.t(_lang, 'acPhotoHint'), style: const TextStyle(fontSize: 13, color: VanixColors.textHint)),
        ],
      ),
    );
  }

  Widget _radio(String label, bool selected, VoidCallback onTap) {
    final textColor = _isDark ? Colors.white : VanixColors.textPrimary;
    return InkWell(
      onTap: onTap,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(selected ? Icons.radio_button_checked : Icons.radio_button_unchecked, size: 20, color: selected ? VanixColors.greenInk : VanixColors.textHint),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 14, color: textColor)),
      ]),
    );
  }

  Widget _historyBlock() {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsetsDirectional.only(start: 16),
      decoration: BoxDecoration(
        border: BorderDirectional(start: BorderSide(color: _isDark ? VanixColors.darkBorder : VanixColors.border, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('acLastHeat'),
          _dateField(),
          _label('acLastInsem', top: 14),
          _dateField(),
          _label('acLastPreg', top: 14),
          _dateField(),
          _label('acLastCalving', top: 14),
          _dateField(),
          _label('acLactationNo', top: 14),
          _stepper(),
          _hint('acLactHint'),
        ],
      ),
    );
  }

  Widget _dateField() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: _fieldDeco,
      child: Row(children: [
        Expanded(child: Text(FS.t(_lang, 'selectDate'), style: const TextStyle(fontSize: 15, color: VanixColors.textHint))),
        const Icon(Icons.calendar_today_outlined, size: 16, color: VanixColors.textHint),
      ]),
    );
  }

  Widget _stepper() {
    final textColor = _isDark ? Colors.white : VanixColors.textPrimary;
    return Container(
      height: 48,
      decoration: _fieldDeco,
      child: Row(children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text('$_lactation', style: TextStyle(fontSize: 15, color: textColor)),
          ),
        ),
        _stepBtn('–', () => setState(() { if (_lactation > 0) _lactation--; })),
        _stepBtn('+', () => setState(() => _lactation++)),
      ]),
    );
  }

  Widget _stepBtn(String glyph, VoidCallback onTap) {
    final textColor = _isDark ? Colors.white : VanixColors.textPrimary;
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(border: BorderDirectional(start: BorderSide(color: _isDark ? VanixColors.darkBorder : VanixColors.border))),
        child: Text(glyph, style: TextStyle(fontSize: 20, color: textColor)),
      ),
    );
  }
}
