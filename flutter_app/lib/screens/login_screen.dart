import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../i18n/strings.dart';
import '../state/app_state.dart';
import '../theme/vanix_theme.dart';
import '../widgets/language_sheet.dart';
import 'dashboard_screen.dart';
import 'farmer_dashboard_screen.dart';

enum _Panel { login, otp }

/// Login → OTP → Dashboard — pure OTP login, no password anywhere. Mirrors
/// the #s1-sheet flow in vanix_screens.html panel-for-panel.
///
/// The HTML version plays a looping, muted, auto-playing hero video behind the
/// sheet (assets/images/hero.mp4) with a dark scrim over it. `_HeroBackground`
/// wires that up via video_player, fading the video in over the fallback
/// gradient (mirrors the CSS `opacity 2.2s ease`).
class LoginScreen extends StatefulWidget {
  final AppState appState;
  const LoginScreen({super.key, required this.appState});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  _Panel _panel = _Panel.login;
  // Landing: video + logo at top + a Login CTA at bottom. Tapping Login
  // slides the sheet up (mirrors the HTML splash → landing → sheet flow).
  bool _landing = true;

  final _emailCtrl = TextEditingController();
  final List<TextEditingController> _otpCtrls = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocus = List.generate(6, (_) => FocusNode());

  Timer? _timer;
  int _secondsLeft = 30;
  bool _showResend = false;

  VideoPlayerController? _videoCtrl;
  bool _videoReady = false;

  VanixStrings get t => VanixStrings.of(widget.appState.languageCode);

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    final ctrl = VideoPlayerController.asset('assets/images/hero.mp4');
    _videoCtrl = ctrl;
    try {
      await ctrl.initialize();
      await ctrl.setVolume(0);
      await ctrl.setLooping(true);
      await ctrl.play();
      if (mounted) setState(() => _videoReady = true);
    } catch (_) {
      // Fall back to the gradient/first-frame background silently.
    }
  }

  @override
  void dispose() {
    _videoCtrl?.dispose();
    _timer?.cancel();
    for (final c in _otpCtrls) {
      c.dispose();
    }
    for (final f in _otpFocus) {
      f.dispose();
    }
    _emailCtrl.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _secondsLeft = 30;
      _showResend = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsLeft--;
        if (_secondsLeft <= 0) {
          timer.cancel();
          _showResend = true;
        }
      });
    });
  }

  void _goToOtp() {
    setState(() {
      _panel = _Panel.otp;
      for (final c in _otpCtrls) {
        c.clear();
      }
    });
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) => _otpFocus.first.requestFocus());
  }

  bool get _otpFilled => _otpCtrls.every((c) => c.text.isNotEmpty);

  void _confirmOtp() {
    if (!_otpFilled) return;
    _timer?.cancel();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => widget.appState.isFarmer
            ? FarmerDashboardScreen(appState: widget.appState)
            : DashboardScreen(appState: widget.appState),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.appState.isDark;
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        final theme = isDark ? vanixDarkTheme(languageCode: widget.appState.languageCode) : vanixLightTheme(languageCode: widget.appState.languageCode);
        return Theme(
          data: theme,
          child: Scaffold(
            backgroundColor: VanixColors.darkPrimary,
            body: Stack(
              children: [
                Positioned.fill(child: _HeroBackground(controller: _videoReady ? _videoCtrl : null)),
                // Top bar — persona toggle left, language selector right.
                // (Display-mode + dark-mode toggles removed: the app is fixed
                // to image cards + light mode.)
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 16, 14, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _PersonaToggle(
                          label: widget.appState.isOwner
                              ? 'Owner'
                              : (widget.appState.isSingleFarm ? 'Farmer · 1' : 'Farmer · N'),
                          onTap: widget.appState.cyclePersona,
                        ),
                        const Spacer(),
                        _PillButton(
                          label: VanixLanguage.supported.firstWhere((l) => l.code == widget.appState.languageCode).native,
                          isDark: isDark,
                          onTap: () => showLanguageSheet(context, current: widget.appState.languageCode, onSelect: widget.appState.setLanguage),
                        ),
                      ],
                    ),
                  ),
                ),
                // MyBovine logo — near the top on the landing screen.
                const Align(
                  alignment: Alignment(0, -0.62),
                  child: SafeArea(
                    child: Text.rich(TextSpan(children: [
                      TextSpan(text: 'My', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white)),
                      TextSpan(text: 'Bovine', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Color(0xFF4DDE95))),
                    ])),
                  ),
                ),
                // Landing CTA — slides out as the sheet slides in.
                AnimatedSlide(
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeOutCubic,
                  offset: _landing ? Offset.zero : const Offset(0, 2),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: _landing ? 1 : 0,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => setState(() => _landing = false),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(0, 52),
                                backgroundColor: VanixColors.greenInk,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                              ),
                              child: Text(t.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Login sheet — slides up once Login is tapped.
                AnimatedSlide(
                  duration: const Duration(milliseconds: 550),
                  curve: const Cubic(0.32, 0.72, 0, 1),
                  offset: _landing ? const Offset(0, 1) : Offset.zero,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: _SheetContainer(isDark: isDark, child: _buildPanel(isDark)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPanel(bool isDark) {
    switch (_panel) {
      case _Panel.login:
        return _LoginPanel(
          key: const ValueKey('login'),
          t: t,
          isDark: isDark,
          emailCtrl: _emailCtrl,
          currentLanguage: widget.appState.languageCode,
          onLanguageTap: () => showLanguageSheet(context, current: widget.appState.languageCode, onSelect: widget.appState.setLanguage),
          onContinue: _goToOtp,
        );
      case _Panel.otp:
        return _OtpPanel(
          key: const ValueKey('otp'),
          t: t,
          isDark: isDark,
          otpCtrls: _otpCtrls,
          otpFocus: _otpFocus,
          secondsLeft: _secondsLeft,
          showResend: _showResend,
          confirmEnabled: _otpFilled,
          targetEmail: _emailCtrl.text,
          onBack: () {
            _timer?.cancel();
            setState(() => _panel = _Panel.login);
          },
          onResend: _startTimer,
          onChanged: () {
            setState(() {});
            // all 6 digits in — advance automatically, no Confirm tap needed
            if (_otpFilled) {
              FocusScope.of(context).unfocus();
              Future.delayed(const Duration(milliseconds: 250), _confirmOtp);
            }
          },
          onConfirm: _confirmOtp,
        );
    }
  }
}

/// Looping, muted hero video with a 45% dark scrim (matches the HTML). When
/// the controller isn't ready it falls back gracefully to the brand gradient,
/// which also shows through beneath the video as it fades in.
class _HeroBackground extends StatelessWidget {
  final VideoPlayerController? controller;
  const _HeroBackground({this.controller});

  @override
  Widget build(BuildContext context) {
    final ready = controller != null && controller!.value.isInitialized;
    return Stack(
      fit: StackFit.expand,
      children: [
        // Fallback / underlay gradient.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF203A2C), Color(0xFF0E1A14)]),
          ),
        ),
        // Cover-fit video, faded in (mirrors CSS opacity 2.2s ease).
        AnimatedOpacity(
          duration: const Duration(milliseconds: 2200),
          opacity: ready ? 1 : 0,
          child: ready
              ? FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: controller!.value.size.width,
                    height: controller!.value.size.height,
                    child: VideoPlayer(controller!),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        // 45% dark scrim.
        Container(color: Colors.black.withValues(alpha: 0.45)),
      ],
    );
  }
}

/// Demo persona switcher (top-left on login): Owner → Farmer·N → Farmer·1.
class _PersonaToggle extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PersonaToggle({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_outline, size: 13, color: Colors.white),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;
  const _ThemeToggle({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        width: 54,
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isDark ? Colors.black.withValues(alpha: 0.60) : Colors.black.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.20) : Colors.white.withValues(alpha: 0.35)),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF333333) : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.30), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Icon(isDark ? Icons.dark_mode : Icons.wb_sunny_outlined, size: 13, color: isDark ? const Color(0xFFF5F5F5) : const Color(0xFF555555)),
          ),
        ),
      ),
    );
  }
}

// Text (plain description-first Events cards) vs Image (photo-illustration
// cards) — app-wide display preference, same pill styling as _ThemeToggle.
class _DisplayModeToggle extends StatelessWidget {
  final bool imageMode;
  final VoidCallback onTap;
  const _DisplayModeToggle({required this.imageMode, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        width: 54,
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          alignment: imageMode ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.30), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Icon(imageMode ? Icons.image_outlined : Icons.notes, size: 13, color: const Color(0xFF555555)),
          ),
        ),
      ),
    );
  }
}

class _SheetContainer extends StatelessWidget {
  final bool isDark;
  final Widget child;
  const _SheetContainer({required this.isDark, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
      decoration: BoxDecoration(
        color: isDark ? const Color(0x9E101010) : Colors.white.withValues(alpha: 0.72),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: isDark ? 0.10 : 0.55))),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 32, offset: const Offset(0, -8))],
      ),
      child: SafeArea(
        top: false,
        child: AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: child),
      ),
    );
  }
}

class _LoginPanel extends StatelessWidget {
  final VanixStrings t;
  final bool isDark;
  final TextEditingController emailCtrl;
  final String currentLanguage;
  final VoidCallback onLanguageTap, onContinue;

  const _LoginPanel({
    super.key,
    required this.t,
    required this.isDark,
    required this.emailCtrl,
    required this.currentLanguage,
    required this.onLanguageTap,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : VanixColors.textPrimary;
    final native = VanixLanguage.supported.firstWhere((l) => l.code == currentLanguage).native;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 26),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(t.title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: textColor)),
            _PillButton(label: native, onTap: onLanguageTap, isDark: isDark),
          ],
        ),
        const SizedBox(height: 36),
        _FieldLabel(t.email, isDark: isDark),
        _UnderlineField(controller: emailCtrl, hint: t.phEmail, isDark: isDark),
        const SizedBox(height: 44),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: onContinue, style: ElevatedButton.styleFrom(backgroundColor: VanixColors.greenInk, foregroundColor: Colors.white), child: Text(t.cont))),
      ],
    );
  }
}

class _OtpPanel extends StatelessWidget {
  final VanixStrings t;
  final bool isDark;
  final List<TextEditingController> otpCtrls;
  final List<FocusNode> otpFocus;
  final int secondsLeft;
  final bool showResend, confirmEnabled;
  final String targetEmail;
  final VoidCallback onBack, onResend, onChanged, onConfirm;

  const _OtpPanel({
    super.key,
    required this.t,
    required this.isDark,
    required this.otpCtrls,
    required this.otpFocus,
    required this.secondsLeft,
    required this.showResend,
    required this.confirmEnabled,
    required this.targetEmail,
    required this.onBack,
    required this.onResend,
    required this.onChanged,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : VanixColors.textPrimary;
    final hintColor = isDark ? const Color(0xA6FFFFFF) : VanixColors.textHint;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 22),
        _BackRow(title: t.vtitle, isDark: isDark, onBack: onBack),
        Padding(
          padding: const EdgeInsets.only(top: 28),
          child: RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 14, color: textColor, fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily),
              children: [
                TextSpan(text: '${t.sent} '),
                TextSpan(text: targetEmail.isEmpty ? 'you@example.com' : targetEmail, style: const TextStyle(fontWeight: FontWeight.w600, decoration: TextDecoration.underline)),
              ],
            ),
          ),
        ),
        Padding(padding: const EdgeInsets.only(top: 6), child: Text(t.desc, style: TextStyle(fontSize: 13, color: hintColor))),
        const SizedBox(height: 20),
        _FieldLabel(t.enterotp, isDark: isDark),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < 6; i++)
              SizedBox(
                width: 42,
                height: 52,
                child: TextField(
                  controller: otpCtrls[i],
                  focusNode: otpFocus[i],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textColor),
                  decoration: InputDecoration(counterText: '', contentPadding: EdgeInsets.zero, enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0x66FFFFFF) : const Color(0xFF9A948A)))),
                  onChanged: (v) {
                    if (v.isNotEmpty && i < 5) otpFocus[i + 1].requestFocus();
                    onChanged();
                  },
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(t.nootp, style: TextStyle(fontSize: 12, color: hintColor)),
            if (!showResend)
              Text('${t.timer} 0:${secondsLeft < 10 ? '0$secondsLeft' : secondsLeft}s', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: hintColor))
            else
              GestureDetector(onTap: onResend, child: Text(t.resend, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: VanixColors.greenInk))),
          ],
        ),
        const SizedBox(height: 30),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: confirmEnabled ? onConfirm : null, child: Text(t.confirm))),
      ],
    );
  }
}

// ── shared bits ──────────────────────────────────────────────

class _BackRow extends StatelessWidget {
  final String title;
  final bool isDark;
  final VoidCallback onBack;
  const _BackRow({required this.title, required this.isDark, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final color = isDark ? Colors.white : VanixColors.textPrimary;
    return Row(
      children: [
        IconButton(onPressed: onBack, icon: Icon(Icons.chevron_left, color: color), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 34, minHeight: 34)),
        const SizedBox(width: 4),
        Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: color)),
      ],
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.1, color: isDark ? const Color(0xA6FFFFFF) : VanixColors.textPrimary)),
    );
  }
}

class _UnderlineField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool isDark;
  const _UnderlineField({required this.controller, required this.hint, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : VanixColors.textPrimary;
    final lineColor = isDark ? const Color(0x66FFFFFF) : const Color(0xFFCCCCCC);
    return TextField(
      controller: controller,
      style: TextStyle(fontSize: 17, color: textColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 13, color: isDark ? const Color(0x73FFFFFF) : VanixColors.textHint),
        filled: false,
        contentPadding: const EdgeInsets.only(bottom: 10),
        border: UnderlineInputBorder(borderSide: BorderSide(color: lineColor)),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: lineColor)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: VanixColors.greenDeep)),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final bool isDark;
  final VoidCallback onTap;
  const _PillButton({required this.label, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : VanixColors.textPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: isDark ? const Color(0x4DFFFFFF) : VanixColors.border),
          color: isDark ? Colors.black.withValues(alpha: 0.30) : Colors.white.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor)),
            const SizedBox(width: 6),
            Icon(Icons.keyboard_arrow_down, size: 14, color: textColor),
          ],
        ),
      ),
    );
  }
}
