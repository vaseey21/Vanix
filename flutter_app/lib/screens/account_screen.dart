import 'package:flutter/material.dart';
import '../i18n/strings.dart';
import '../i18n/farm_strings.dart';
import '../models/farm_models.dart';
import '../state/app_state.dart';
import '../theme/vanix_theme.dart';
import '../widgets/vanix_bottom_nav.dart';
import '../widgets/vanix_nav_items.dart';
import '../widgets/language_sheet.dart';
import 'farms_screen.dart';
import 'milk_log_screen.dart';
import 'events_screen.dart';

/// Account / Settings — screen 11. Faithful port of #page-account plus its
/// sub-pages (#page-profile, #page-vets, #page-farmmgmt, #page-privacy,
/// #page-terms) from prototype.html. All chrome localized via FS.t; legal
/// body text stays English. Light + dark throughout.
class AccountScreen extends StatefulWidget {
  final AppState appState;
  const AccountScreen({super.key, required this.appState});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final int _navIndex = 4;
  bool _soundOn = true;

  void _onNavTap(int i) {
    if (i == 4) return;
    if (i == 0) {
      Navigator.of(context).popUntil((r) => r.isFirst);
      return;
    }
    Widget page;
    if (i == 1) {
      page = FarmsScreen(appState: widget.appState);
    } else if (i == 2) {
      page = MilkLogScreen(appState: widget.appState);
    } else {
      page = EventsScreen(appState: widget.appState);
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page)).then((_) {
      if (mounted) setState(() {});
    });
  }

  void _push(Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page)).then((_) {
      if (mounted) setState(() {});
    });
  }

  void _openLanguage(String lang) {
    showLanguageSheet(
      context,
      current: widget.appState.languageCode,
      onSelect: (code) => widget.appState.setLanguage(code),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        final isDark = widget.appState.isDark;
        final lang = widget.appState.languageCode;
        final t = VanixStrings.of(lang);
        final theme = isDark ? vanixDarkTheme(languageCode: lang) : vanixLightTheme(languageCode: lang);

        final currentLangNative = VanixLanguage.supported
            .firstWhere((l) => l.code == lang, orElse: () => VanixLanguage.supported[1])
            .native;

        return Theme(
          data: theme,
          child: Scaffold(
            body: Stack(
              children: [
                Positioned.fill(
                  child: SafeArea(
                    bottom: false,
                    child: ListView(
                    padding: const EdgeInsets.only(bottom: 130),
                    children: [
                      _Hero(title: FS.t(lang, 'navAccount'), isDark: isDark),
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile entry card
                            _GroupCard(
                              isDark: isDark,
                              children: [
                                _AccountRow(
                                  isDark: isDark,
                                  leading: _Avatar(initials: 'JR', size: 40, isDark: isDark),
                                  title: 'James Redmark',
                                  subtitle: FS.t(lang, 'farmOwner'),
                                  onTap: () => _push(_ProfilePage(appState: widget.appState)),
                                ),
                              ],
                            ),

                            // Farm Management group
                            _GroupLabel(FS.t(lang, 'grpFarmMgmt'), isDark: isDark),
                            _GroupCard(
                              isDark: isDark,
                              children: [
                                _AccountRow(
                                  isDark: isDark,
                                  title: FS.t(lang, 'grpFarmMgmt'),
                                  subtitle: FS.t(lang, 'acctFarmSub'),
                                  onTap: () => _push(_FarmMgmtPage(appState: widget.appState)),
                                ),
                                _AccountRow(
                                  isDark: isDark,
                                  title: FS.t(lang, 'rowCattleGroups'),
                                  subtitle: FS.t(lang, 'acctGroupsSub'),
                                  onTap: () {},
                                ),
                              ],
                            ),

                            // Alerts & Contacts
                            _GroupLabel(FS.t(lang, 'grpAlerts'), isDark: isDark),
                            _GroupCard(
                              isDark: isDark,
                              children: [
                                _AccountRow(
                                  isDark: isDark,
                                  title: FS.t(lang, 'rowSound'),
                                  subtitle: FS.t(lang, 'soundSub'),
                                  trailing: _Toggle(
                                    value: _soundOn,
                                    onChanged: (v) => setState(() => _soundOn = v),
                                  ),
                                  onTap: () => setState(() => _soundOn = !_soundOn),
                                ),
                                _AccountRow(
                                  isDark: isDark,
                                  title: FS.t(lang, 'rowVets'),
                                  subtitle: FS.t(lang, 'vetsSub'),
                                  onTap: () => _push(_VetsPage(appState: widget.appState)),
                                ),
                              ],
                            ),

                            // App
                            _GroupLabel(FS.t(lang, 'grpApp'), isDark: isDark),
                            _GroupCard(
                              isDark: isDark,
                              children: [
                                _AccountRow(
                                  isDark: isDark,
                                  title: FS.t(lang, 'rowLanguage'),
                                  subtitle: currentLangNative,
                                  onTap: () => _openLanguage(lang),
                                ),
                                _AccountRow(
                                  isDark: isDark,
                                  title: FS.t(lang, 'rowDark'),
                                  trailing: _Toggle(
                                    value: isDark,
                                    onChanged: (_) => widget.appState.toggleDark(),
                                  ),
                                  onTap: () => widget.appState.toggleDark(),
                                ),
                              ],
                            ),

                            // Legal
                            _GroupLabel(FS.t(lang, 'grpLegal'), isDark: isDark),
                            _GroupCard(
                              isDark: isDark,
                              children: [
                                _AccountRow(
                                  isDark: isDark,
                                  title: FS.t(lang, 'rowPrivacy'),
                                  onTap: () => _push(_LegalPage(
                                    appState: widget.appState,
                                    title: FS.t(lang, 'rowPrivacy'),
                                    sections: _privacySections,
                                  )),
                                ),
                                _AccountRow(
                                  isDark: isDark,
                                  title: FS.t(lang, 'rowTerms'),
                                  onTap: () => _push(_LegalPage(
                                    appState: widget.appState,
                                    title: FS.t(lang, 'rowTerms'),
                                    sections: _termsSections,
                                  )),
                                ),
                              ],
                            ),

                            // Support
                            _GroupLabel(FS.t(lang, 'grpSupport'), isDark: isDark),
                            _GroupCard(
                              isDark: isDark,
                              children: [
                                _AccountRow(
                                  isDark: isDark,
                                  title: FS.t(lang, 'rowHelp'),
                                  subtitle: FS.t(lang, 'helpSub'),
                                  onTap: () {},
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),
                            _GroupCard(
                              isDark: isDark,
                              children: [
                                _AccountRow(
                                  isDark: isDark,
                                  title: FS.t(lang, 'rowLogout'),
                                  titleColor: VanixColors.danger,
                                  showChevron: false,
                                  onTap: () {},
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: VanixBottomNav(
                    isDark: isDark,
                    selectedIndex: _navIndex,
                    onTap: _onNavTap,
                    items: buildVanixNavItems(t, widget.appState),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PROFILE — read-only
// ─────────────────────────────────────────────────────────────
class _ProfilePage extends StatelessWidget {
  final AppState appState;
  const _ProfilePage({required this.appState});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final isDark = appState.isDark;
        final lang = appState.languageCode;
        final theme = isDark ? vanixDarkTheme(languageCode: lang) : vanixLightTheme(languageCode: lang);
        return Theme(
          data: theme,
          child: Scaffold(
            body: SafeArea(
              child: ListView(
              padding: const EdgeInsets.only(bottom: 40),
              children: [
                _HeroBack(title: FS.t(lang, 'profTitle'), isDark: isDark),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child: _Avatar(initials: 'JR', size: 64, isDark: isDark)),
                      const SizedBox(height: 16),
                      _FieldLabel(FS.t(lang, 'fldName'), isDark: isDark),
                      _GrayBox('James Redmark', isDark: isDark),
                      const SizedBox(height: 12),
                      _FieldLabel(FS.t(lang, 'fldPhone'), isDark: isDark),
                      _GrayBox('+91 98765 43210', isDark: isDark),
                      _HintLine(FS.t(lang, 'phoneHint'), isDark: isDark),
                      const SizedBox(height: 12),
                      _FieldLabel(FS.t(lang, 'fldEmail'), isDark: isDark),
                      _GrayBox('james@sunrisedairy.in', isDark: isDark),
                      _HintLine(FS.t(lang, 'emailHint'), isDark: isDark),
                      const SizedBox(height: 12),
                      _FieldLabel(FS.t(lang, 'fldRole'), isDark: isDark),
                      _GrayBox(FS.t(lang, 'farmOwner'), isDark: isDark),
                      const SizedBox(height: 18),
                      _GroupLabel(FS.t(lang, 'grpDelete'), isDark: isDark, topPad: 0),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: isDark ? VanixColors.darkBorder : VanixColors.border, style: BorderStyle.solid),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          FS.t(lang, 'delNote'),
                          style: TextStyle(fontSize: 12, height: 1.5, color: isDark ? const Color(0xB3FFFFFF) : VanixColors.textHint),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            foregroundColor: VanixColors.danger,
                            backgroundColor: isDark ? Colors.transparent : VanixColors.dangerBg,
                            side: const BorderSide(color: VanixColors.danger, width: 1.5),
                            minimumSize: const Size(0, 48),
                            shape: const StadiumBorder(),
                          ),
                          child: Text(FS.t(lang, 'btnReqDelete'), style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
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
}

// ─────────────────────────────────────────────────────────────
// VETS
// ─────────────────────────────────────────────────────────────
class _VetsPage extends StatefulWidget {
  final AppState appState;
  const _VetsPage({required this.appState});

  @override
  State<_VetsPage> createState() => _VetsPageState();
}

class _VetsPageState extends State<_VetsPage> {
  String _vetInitials(String name) {
    final n = name.replaceFirst('Dr. ', '');
    return n.length >= 2 ? n.substring(0, 2) : n;
  }

  void _openEdit(VetModel vet) {
    final lang = widget.appState.languageCode;
    final isDark = widget.appState.isDark;
    final controller = TextEditingController(text: vet.name);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bg = isDark ? const Color(0xFF1C1C1C) : Colors.white;
        final textColor = isDark ? Colors.white : VanixColors.textPrimary;
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: VanixColors.greenInk, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: Text(FS.t(lang, 'editVet'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor))),
                    _CloseCircle(isDark: isDark, onTap: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 14),
                _FieldLabel(FS.t(lang, 'fldName'), isDark: isDark),
                TextField(controller: controller, style: TextStyle(fontSize: 13, color: textColor)),
                const SizedBox(height: 12),
                _FieldLabel(FS.t(lang, 'fldEmail'), isDark: isDark),
                _GrayBox(vet.email.isEmpty ? '—' : vet.email, isDark: isDark),
                const SizedBox(height: 12),
                _FieldLabel(FS.t(lang, 'fldPhone'), isDark: isDark),
                _GrayBox(vet.phone.isEmpty ? '—' : vet.phone, isDark: isDark),
                const SizedBox(height: 12),
                _FieldLabel(FS.t(lang, 'fldRole'), isDark: isDark),
                _GrayBox(FS.t(lang, 'roleVet'), isDark: isDark),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final nm = controller.text.trim();
                      if (nm.isNotEmpty) vet.name = nm;
                      Navigator.pop(ctx);
                      setState(() {});
                    },
                    child: Text(FS.t(lang, 'saveChanges')),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openAdd() {
    final lang = widget.appState.languageCode;
    final isDark = widget.appState.isDark;
    final nameC = TextEditingController();
    final emailC = TextEditingController();
    final phoneC = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bg = isDark ? const Color(0xFF1C1C1C) : Colors.white;
        final textColor = isDark ? Colors.white : VanixColors.textPrimary;
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: VanixColors.greenInk, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: Text(FS.t(lang, 'addVetTitle'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor))),
                    _CloseCircle(isDark: isDark, onTap: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(controller: nameC, style: TextStyle(fontSize: 13, color: textColor), decoration: InputDecoration(hintText: FS.t(lang, 'vetNamePh'))),
                const SizedBox(height: 8),
                TextField(controller: emailC, keyboardType: TextInputType.emailAddress, style: TextStyle(fontSize: 13, color: textColor), decoration: InputDecoration(hintText: FS.t(lang, 'emailPh'))),
                const SizedBox(height: 8),
                TextField(controller: phoneC, keyboardType: TextInputType.phone, style: TextStyle(fontSize: 13, color: textColor), decoration: InputDecoration(hintText: FS.t(lang, 'phonePh'))),
                const SizedBox(height: 10),
                Text(FS.t(lang, 'inviteHint'), style: TextStyle(fontSize: 10, height: 1.5, color: isDark ? const Color(0xB3FFFFFF) : VanixColors.textHint)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final name = nameC.text.trim();
                      final email = emailC.text.trim();
                      if (name.isEmpty || email.isEmpty) return;
                      kVets.add(VetModel(name: name, email: email, phone: phoneC.text.trim(), status: 'pending'));
                      Navigator.pop(ctx);
                      setState(() {});
                    },
                    child: Text(FS.t(lang, 'sendInvite')),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        final isDark = widget.appState.isDark;
        final lang = widget.appState.languageCode;
        final theme = isDark ? vanixDarkTheme(languageCode: lang) : vanixLightTheme(languageCode: lang);
        return Theme(
          data: theme,
          child: Scaffold(
            body: SafeArea(
              child: ListView(
              padding: const EdgeInsets.only(bottom: 40),
              children: [
                _HeroBack(title: FS.t(lang, 'rowVets'), subtitle: FS.t(lang, 'vetsSub'), isDark: isDark),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _GroupLabel(FS.t(lang, 'grpYourVets'), isDark: isDark, topPad: 0),
                      for (final vet in kVets) _vetCard(vet, isDark, lang),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _openAdd,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? Colors.white : VanixColors.textPrimary,
                            minimumSize: const Size(0, 46),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            side: BorderSide(color: isDark ? const Color(0x73FFFFFF) : VanixColors.textHint, width: 1),
                          ),
                          child: Text(FS.t(lang, 'addVet'), style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
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

  Widget _vetCard(VetModel vet, bool isDark, String lang) {
    final textColor = isDark ? Colors.white : VanixColors.textPrimary;
    final hint = isDark ? const Color(0xB3FFFFFF) : VanixColors.textHint;

    Color badgeBg, badgeBorder, badgeInk;
    String badgeKey;
    switch (vet.status) {
      case 'confirmed':
        badgeBg = VanixColors.activeBg;
        badgeBorder = VanixColors.greenDeep;
        badgeInk = VanixColors.greenInk;
        badgeKey = 'vetConfirmed';
        break;
      case 'declined':
        badgeBg = VanixColors.dangerBg;
        badgeBorder = VanixColors.danger;
        badgeInk = VanixColors.danger;
        badgeKey = 'vetDeclined';
        break;
      default:
        badgeBg = VanixColors.warningBg;
        badgeBorder = VanixColors.warning;
        badgeInk = const Color(0xFF8A5A00);
        badgeKey = 'vetPending';
    }

    final spec = vet.specKey != null ? FS.t(lang, vet.specKey!) : vet.phone;

    return InkWell(
      onTap: () => _openEdit(vet),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? VanixColors.darkSecond : VanixColors.bgCard,
          border: Border.all(color: isDark ? VanixColors.darkBorder : VanixColors.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? const Color(0xFF262626) : VanixColors.bgWarm,
                  ),
                  child: Text(_vetInitials(vet.name), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textColor)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(vet.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textColor)),
                      if (spec.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(spec, style: TextStyle(fontSize: 11, color: hint)),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: badgeBg, border: Border.all(color: badgeBorder), borderRadius: BorderRadius.circular(12)),
                  child: Text(FS.t(lang, badgeKey), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: badgeInk)),
                ),
              ],
            ),
            if (vet.status == 'pending') ...[
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(FS.t(lang, 'vetPendingNote'), style: TextStyle(fontSize: 11, color: hint)),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _MiniButton(
                      label: FS.t(lang, 'demoConfirm'),
                      color: VanixColors.greenInk,
                      borderColor: VanixColors.greenDeep,
                      onTap: () => setState(() => vet.status = 'confirmed'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MiniButton(
                      label: FS.t(lang, 'demoDecline'),
                      color: VanixColors.danger,
                      borderColor: isDark ? VanixColors.darkBorder : VanixColors.border,
                      onTap: () => setState(() => vet.status = 'declined'),
                    ),
                  ),
                ],
              ),
            ] else if (vet.status == 'declined') ...[
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(FS.t(lang, 'vetDeclinedNote'), style: TextStyle(fontSize: 11, color: hint)),
              ),
              const SizedBox(height: 8),
              _MiniButton(
                label: FS.t(lang, 'vetResend'),
                color: textColor,
                borderColor: isDark ? VanixColors.darkBorder : VanixColors.border,
                onTap: () => setState(() => vet.status = 'pending'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// FARM MANAGEMENT
// ─────────────────────────────────────────────────────────────
class _FarmMgmtPage extends StatefulWidget {
  final AppState appState;
  const _FarmMgmtPage({required this.appState});

  @override
  State<_FarmMgmtPage> createState() => _FarmMgmtPageState();
}

class _FarmMgmtPageState extends State<_FarmMgmtPage> {
  void _openAssignSheet(FarmModel farm) {
    final lang = widget.appState.languageCode;
    final isDark = widget.appState.isDark;
    final nameC = TextEditingController();
    final phoneC = TextEditingController();
    final emailC = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bg = isDark ? const Color(0xFF1C1C1C) : Colors.white;
        final textColor = isDark ? Colors.white : VanixColors.textPrimary;
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: VanixColors.greenInk, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: Text(farm.assigned ? FS.t(lang, 'reassignWord') : FS.t(lang, 'assignManager'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor))),
                    _CloseCircle(isDark: isDark, onTap: () => Navigator.pop(ctx)),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(farm.nm(lang), style: TextStyle(fontSize: 12, color: isDark ? const Color(0xB3FFFFFF) : VanixColors.textHint)),
                ),
                const SizedBox(height: 14),
                TextField(controller: nameC, style: TextStyle(fontSize: 13, color: textColor), decoration: InputDecoration(hintText: FS.t(lang, 'mgrNamePh'))),
                const SizedBox(height: 8),
                TextField(controller: phoneC, keyboardType: TextInputType.phone, style: TextStyle(fontSize: 13, color: textColor), decoration: InputDecoration(hintText: FS.t(lang, 'phonePh'))),
                const SizedBox(height: 8),
                TextField(controller: emailC, keyboardType: TextInputType.emailAddress, style: TextStyle(fontSize: 13, color: textColor), decoration: InputDecoration(hintText: FS.t(lang, 'emailPh'))),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final nm = nameC.text.trim();
                      if (nm.isNotEmpty) {
                        farm.manager = nm;
                        farm.managerHi = nm;
                      }
                      Navigator.pop(ctx);
                      setState(() {});
                    },
                    child: Text(FS.t(lang, 'confirmAssign')),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        final isDark = widget.appState.isDark;
        final lang = widget.appState.languageCode;
        final theme = isDark ? vanixDarkTheme(languageCode: lang) : vanixLightTheme(languageCode: lang);
        final textColor = isDark ? Colors.white : VanixColors.textPrimary;
        final farms = kFarms.where((f) => f.status != FarmStatus.setup).toList();

        return Theme(
          data: theme,
          child: Scaffold(
            body: SafeArea(
              child: ListView(
              padding: const EdgeInsets.only(bottom: 40),
              children: [
                _HeroBack(title: FS.t(lang, 'grpFarmMgmt'), subtitle: FS.t(lang, 'farmMgmtSub'), isDark: isDark),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final farm in farms)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? VanixColors.darkSecond : VanixColors.bgCard,
                            border: Border.all(color: isDark ? VanixColors.darkBorder : VanixColors.border),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(farm.nm(lang), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textColor)),
                              Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: farm.assigned
                                    ? Text('${FS.t(lang, 'managerWord')}: ${farm.mgr(lang)}', style: TextStyle(fontSize: 12, color: isDark ? const Color(0xB3FFFFFF) : VanixColors.textHint))
                                    : Text(FS.t(lang, 'unassignedWord'), style: const TextStyle(fontSize: 12, color: VanixColors.danger)),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _PillButton(
                                      label: farm.assigned ? FS.t(lang, 'reassignWord') : FS.t(lang, 'assignManager'),
                                      textColor: VanixColors.greenInk,
                                      bg: VanixColors.activeBg,
                                      borderColor: VanixColors.greenInk,
                                      onTap: () => _openAssignSheet(farm),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _PillButton(
                                      label: FS.t(lang, 'assignMe'),
                                      textColor: textColor,
                                      bg: Colors.transparent,
                                      borderColor: isDark ? VanixColors.darkBorder : VanixColors.border,
                                      onTap: () => setState(() {
                                        farm.manager = 'James Redmark';
                                        farm.managerHi = 'जेम्स रेडमार्क';
                                      }),
                                    ),
                                  ),
                                ],
                              ),
                              if (farm.assigned) ...[
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: _PillButton(
                                    label: FS.t(lang, 'removeManager'),
                                    textColor: VanixColors.danger,
                                    bg: Colors.transparent,
                                    borderColor: VanixColors.danger,
                                    minHeight: 36,
                                    onTap: () => setState(() {
                                      farm.manager = 'Unassigned';
                                      farm.managerHi = 'नियुक्त नहीं';
                                    }),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
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
}

// ─────────────────────────────────────────────────────────────
// LEGAL (Privacy / Terms)
// ─────────────────────────────────────────────────────────────
class _LegalSection {
  final String heading, body;
  const _LegalSection(this.heading, this.body);
}

const List<_LegalSection> _privacySections = [
  _LegalSection('Introduction', 'MyBovine.ai ("we," "us") provides farm and cattle management tools. This policy explains what information we collect when you use the app, how we use it, and the choices you have.'),
  _LegalSection('Information We Collect', 'Account details (name, phone, email, role); farm data (farm name, location, acreage, team members); cattle information (breed, weight, health and breeding records, milk yield); and device data from connected sensors or ear tags (battery level, connectivity status, readings), where applicable.'),
  _LegalSection('How Information Is Used', 'We use this information to operate core features such as health alerts, vet reports, and cattle group tracking; to notify you and your emergency contacts; and to maintain and improve the app.'),
  _LegalSection('Data Sharing & Third-Party Services', 'We share data only with people you authorize, such as vets or farm managers added to your account, and with service providers who help operate the app (e.g. SMS or notification delivery). We do not sell your personal data.'),
  _LegalSection('Data Security', 'We use encryption in transit, access controls, and secure servers to protect your data. No method of storage or transmission is completely secure, and we work to continually improve our safeguards.'),
  _LegalSection('Your Rights', 'You may view or update your profile and farm data at any time from within the app. You can also request a copy of your data or request deletion of your account and associated data, where applicable, by contacting us below.'),
  _LegalSection('Contact Us', 'For privacy-related questions or requests, contact privacy@mybovine.ai.'),
];

const List<_LegalSection> _termsSections = [
  _LegalSection('Acceptance of Terms', 'By creating an account or using MyBovine.ai, you agree to these Terms of Service. If you do not agree, please do not use the app.'),
  _LegalSection('User Responsibilities', 'You are responsible for the accuracy of the farm, cattle, and contact information you enter, and for keeping your login credentials confidential.'),
  _LegalSection('Acceptable Use', 'The app is intended for legitimate farm and cattle management. You agree not to misuse the service, attempt to disrupt it, or reverse-engineer any part of it.'),
  _LegalSection('Account Responsibilities', 'Farm Owners manage access for Farm Managers and other team members added to an account. You are responsible for the actions taken under roles you assign.'),
  _LegalSection('Limitation of Liability', 'MyBovine.ai is a monitoring and record-keeping aid, not a substitute for veterinary judgment. We are not liable for losses arising from reliance on alerts, records, or data accuracy.'),
  _LegalSection('Intellectual Property', 'The MyBovine.ai app, its design, logo, and underlying software are owned by us and may not be copied or redistributed without permission.'),
  _LegalSection('Termination or Suspension', 'We may suspend or terminate accounts that violate these terms or misuse the service. You may stop using the app and request account deletion at any time.'),
  _LegalSection('Contact Us', 'For support or legal queries, contact support@mybovine.ai.'),
];

class _LegalPage extends StatelessWidget {
  final AppState appState;
  final String title;
  final List<_LegalSection> sections;
  const _LegalPage({required this.appState, required this.title, required this.sections});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final isDark = appState.isDark;
        final lang = appState.languageCode;
        final theme = isDark ? vanixDarkTheme(languageCode: lang) : vanixLightTheme(languageCode: lang);
        final textColor = isDark ? Colors.white : VanixColors.textPrimary;
        final bodyColor = isDark ? const Color(0xE6FFFFFF) : VanixColors.textPrimary;
        final hint = isDark ? const Color(0xB3FFFFFF) : VanixColors.textHint;

        return Theme(
          data: theme,
          child: Scaffold(
            body: SafeArea(
              child: ListView(
              padding: const EdgeInsets.only(bottom: 40),
              children: [
                _HeroBack(title: title, isDark: isDark),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Text(FS.t(lang, 'legalUpdated'), style: TextStyle(fontSize: 11, color: hint)),
                      ),
                      for (final s in sections) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(s.heading, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textColor)),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(s.body, style: TextStyle(fontSize: 14, height: 1.6, color: bodyColor)),
                        ),
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
}

// ─────────────────────────────────────────────────────────────
// Shared widgets
// ─────────────────────────────────────────────────────────────
class _Hero extends StatelessWidget {
  final String title;
  final bool isDark;
  const _Hero({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: isDark ? VanixColors.darkPrimary : VanixColors.bgWarm,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 28, offset: const Offset(0, 12))],
      ),
      child: Text(title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: isDark ? Colors.white : VanixColors.textPrimary)),
    );
  }
}

class _HeroBack extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool isDark;
  const _HeroBack({required this.title, this.subtitle, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : VanixColors.textPrimary;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 18, 16, 18),
      decoration: BoxDecoration(
        color: isDark ? VanixColors.darkPrimary : VanixColors.bgWarm,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 28, offset: const Offset(0, 12))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(Icons.chevron_left, size: 24, color: textColor),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textColor)),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(subtitle!, style: TextStyle(fontSize: 11, color: isDark ? const Color(0xB3FFFFFF) : VanixColors.textHint)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  final String label;
  final bool isDark;
  final double topPad;
  const _GroupLabel(this.label, {required this.isDark, this.topPad = 16});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: topPad, bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: isDark ? const Color(0xB3FFFFFF) : VanixColors.textHint),
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final bool isDark;
  final List<Widget> children;
  const _GroupCard({required this.isDark, required this.children});

  @override
  Widget build(BuildContext context) {
    final divided = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      divided.add(children[i]);
      if (i != children.length - 1) {
        divided.add(Divider(height: 1, thickness: 0.5, color: isDark ? VanixColors.darkBorder : VanixColors.border));
      }
    }
    return Container(
      decoration: BoxDecoration(
        color: isDark ? VanixColors.darkSecond : VanixColors.bgCard,
        border: Border.all(color: isDark ? VanixColors.darkBorder : VanixColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: divided),
    );
  }
}

class _AccountRow extends StatelessWidget {
  final bool isDark;
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Color? titleColor;
  final bool showChevron;
  final VoidCallback onTap;
  const _AccountRow({
    required this.isDark,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.titleColor,
    this.showChevron = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = titleColor ?? (isDark ? Colors.white : VanixColors.textPrimary);
    final hint = isDark ? const Color(0xB3FFFFFF) : VanixColors.textHint;
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 10)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(subtitle!, style: TextStyle(fontSize: 11, color: hint)),
                    ),
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else if (showChevron)
              Icon(Icons.chevron_right, size: 18, color: hint),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String initials;
  final double size;
  final bool isDark;
  const _Avatar({required this.initials, required this.size, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: VanixColors.activeBg),
      child: Text(initials, style: TextStyle(fontSize: size >= 64 ? 18 : 13, fontWeight: FontWeight.w700, color: VanixColors.greenInk)),
    );
  }
}

class _Toggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _Toggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 40,
        height: 22,
        decoration: BoxDecoration(
          color: value ? VanixColors.greenInk : VanixColors.border,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            AnimatedPositionedDirectional(
              duration: const Duration(milliseconds: 180),
              top: 2,
              start: value ? 20 : 2,
              child: Container(width: 18, height: 18, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  final bool isDark;
  const _FieldLabel(this.label, {required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: isDark ? const Color(0xB3FFFFFF) : VanixColors.textHint),
      ),
    );
  }
}

class _GrayBox extends StatelessWidget {
  final String value;
  final bool isDark;
  const _GrayBox(this.value, {required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262626) : VanixColors.bgWarm,
        border: Border.all(color: isDark ? VanixColors.darkBorder : VanixColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(value, style: TextStyle(fontSize: 14, color: isDark ? const Color(0xB3FFFFFF) : VanixColors.textHint)),
    );
  }
}

class _HintLine extends StatelessWidget {
  final String text;
  final bool isDark;
  const _HintLine(this.text, {required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(text, style: TextStyle(fontSize: 10, color: isDark ? const Color(0x99FFFFFF) : VanixColors.textHint)),
    );
  }
}

class _CloseCircle extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;
  const _CloseCircle({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, color: isDark ? const Color(0xFF262626) : VanixColors.bgWarm),
        child: Icon(Icons.close, size: 15, color: isDark ? Colors.white : VanixColors.textPrimary),
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color borderColor;
  final VoidCallback onTap;
  const _MiniButton({required this.label, required this.color, required this.borderColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        constraints: const BoxConstraints(minHeight: 34),
        alignment: Alignment.center,
        decoration: BoxDecoration(border: Border.all(color: borderColor), borderRadius: BorderRadius.circular(17)),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final Color textColor;
  final Color bg;
  final Color borderColor;
  final double minHeight;
  final VoidCallback onTap;
  const _PillButton({
    required this.label,
    required this.textColor,
    required this.bg,
    required this.borderColor,
    this.minHeight = 38,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(minHeight / 2),
      child: Container(
        constraints: BoxConstraints(minHeight: minHeight),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(color: bg, border: Border.all(color: borderColor), borderRadius: BorderRadius.circular(minHeight / 2)),
        child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor)),
      ),
    );
  }
}
