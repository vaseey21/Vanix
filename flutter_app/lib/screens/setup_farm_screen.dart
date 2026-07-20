import 'package:flutter/material.dart';
import '../i18n/farm_strings.dart';
import '../models/farm_models.dart';
import '../state/app_state.dart';
import '../theme/vanix_theme.dart';

/// Setup Farm — full-screen page opened by the "Setup Farm" pill on the Farms
/// list (Highland Farm). Mirrors #page-setup-farm in prototype.html: an
/// "Invite a farm manager" card (name/email/phone -> pending chip row) and an
/// "Assign myself" card, either of which enables the Done button.
class SetupFarmScreen extends StatefulWidget {
  final AppState appState;
  final FarmModel farm;
  const SetupFarmScreen({super.key, required this.appState, required this.farm});

  @override
  State<SetupFarmScreen> createState() => _SetupFarmScreenState();
}

class _SetupFarmScreenState extends State<SetupFarmScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _invitePending = false;
  String _pendingName = '';
  bool _assignedSelf = false;

  String get _lang => widget.appState.languageCode;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _sendInvite() {
    setState(() {
      _pendingName = _nameCtrl.text.trim().isEmpty ? 'Farm manager' : _nameCtrl.text.trim();
      _invitePending = true;
    });
  }

  void _assignSelf() {
    setState(() => _assignedSelf = true);
  }

  void _done() {
    if (_assignedSelf) {
      widget.farm.manager = 'James Redmark';
      widget.farm.managerHi = 'जेम्स रेडमार्क';
      widget.farm.managerInvitePending = false;
      widget.farm.managerInviteEmail = '';
      widget.farm.status = FarmStatus.healthy;
    } else if (_invitePending) {
      widget.farm.manager = _pendingName;
      widget.farm.managerHi = _pendingName;
      widget.farm.managerInvitePending = true;
      widget.farm.managerInviteEmail = _emailCtrl.text.trim();
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        final isDark = widget.appState.isDark;
        final theme = isDark ? vanixDarkTheme(languageCode: _lang) : vanixLightTheme(languageCode: _lang);
        final textColor = isDark ? Colors.white : VanixColors.textPrimary;
        final subColor = isDark ? const Color(0xB3FFFFFF) : VanixColors.textHint;
        final cardBg = isDark ? VanixColors.darkSecond : VanixColors.bgCard;
        final borderCol = isDark ? VanixColors.darkBorder : VanixColors.border;

        return Theme(
          data: theme,
          child: Scaffold(
            backgroundColor: isDark ? VanixColors.darkPrimary : VanixColors.bgWarm,
            body: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 12),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(Icons.chevron_left, size: 26, color: textColor),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(FS.t(_lang, 'setupFarmTitle'), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: textColor)),
                              const SizedBox(height: 2),
                              Text(widget.farm.nm(_lang), style: TextStyle(fontSize: 13, color: subColor)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 16, 40),
                      children: [
                        // Invite a farm manager
                        Container(
                          padding: const EdgeInsetsDirectional.all(16),
                          decoration: BoxDecoration(
                            color: cardBg,
                            border: Border.all(color: borderCol),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(FS.t(_lang, 'sfInviteTitle'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textColor)),
                              const SizedBox(height: 4),
                              Text(FS.t(_lang, 'sfInviteSub'), style: TextStyle(fontSize: 12, height: 1.5, color: subColor)),
                              const SizedBox(height: 12),
                              if (!_invitePending) ...[
                                TextField(
                                  controller: _nameCtrl,
                                  style: TextStyle(fontSize: 15, color: textColor),
                                  decoration: InputDecoration(hintText: FS.t(_lang, 'sfManagerNamePh')),
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: _emailCtrl,
                                  keyboardType: TextInputType.emailAddress,
                                  style: TextStyle(fontSize: 15, color: textColor),
                                  decoration: InputDecoration(hintText: FS.t(_lang, 'emailPh')),
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: _phoneCtrl,
                                  keyboardType: TextInputType.phone,
                                  style: TextStyle(fontSize: 15, color: textColor),
                                  decoration: InputDecoration(hintText: FS.t(_lang, 'phonePh')),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: VanixColors.greenInk, foregroundColor: Colors.white, minimumSize: const Size(0, 48)),
                                    onPressed: _sendInvite,
                                    child: Text(FS.t(_lang, 'sfSendInvite')),
                                  ),
                                ),
                              ] else
                                Container(
                                  padding: const EdgeInsetsDirectional.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isDark ? VanixColors.darkPrimary : VanixColors.bgWarm,
                                    border: Border.all(color: borderCol),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(_pendingName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
                                            const SizedBox(height: 2),
                                            Text(FS.t(_lang, 'sfPendingNote'), style: TextStyle(fontSize: 11, color: subColor)),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsetsDirectional.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(color: VanixColors.warningBg, borderRadius: BorderRadius.circular(10)),
                                        child: Text(FS.t(_lang, 'vetPending').toUpperCase(),
                                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: VanixColors.warningInk)),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsetsDirectional.symmetric(vertical: 14),
                          child: Text(FS.t(_lang, 'sfOrWord'),
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: subColor)),
                        ),
                        // Assign myself
                        Container(
                          padding: const EdgeInsetsDirectional.all(16),
                          decoration: BoxDecoration(
                            color: cardBg,
                            border: Border.all(color: borderCol),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(FS.t(_lang, 'sfAssignTitle'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textColor)),
                              const SizedBox(height: 4),
                              Text(FS.t(_lang, 'sfAssignSub'), style: TextStyle(fontSize: 12, height: 1.5, color: subColor)),
                              const SizedBox(height: 12),
                              if (!_assignedSelf)
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(0, 48),
                                      side: const BorderSide(color: VanixColors.greenInk),
                                      foregroundColor: VanixColors.greenInk,
                                    ),
                                    onPressed: _assignSelf,
                                    child: Text(FS.t(_lang, 'sfAssignBtn')),
                                  ),
                                )
                              else
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsetsDirectional.all(16),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(color: VanixColors.activeBg, borderRadius: BorderRadius.circular(12)),
                                  child: Text(FS.t(_lang, 'sfAssignedMsg'),
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: VanixColors.greenInk)),
                                ),
                            ],
                          ),
                        ),
                        if (_invitePending || _assignedSelf)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(top: 18),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: VanixColors.greenInk, foregroundColor: Colors.white, minimumSize: const Size(0, 50)),
                                onPressed: _done,
                                child: Text(FS.t(_lang, 'sfDoneBtn')),
                              ),
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
