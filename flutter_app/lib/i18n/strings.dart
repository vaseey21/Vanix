/// Mirrors the STRINGS object in vanix_screens.html — keep both in sync.
/// Default locale is Hindi (see CLAUDE.md); Phase 1 supports en / hi / bho.
class VanixStrings {
  final String title, email, pass, cont, forgot;
  final String vtitle, sent, desc, enterotp, timer, nootp, resend, confirm;
  final String ftitle, fdesc, fsend;
  final String rptitle, newpass, repass, nomatch, rpsave, pwSaved;
  final String phEmail, phPass;
  final String navHome, navFarms, navMilk, navEvents, navAccount;

  const VanixStrings({
    required this.title,
    required this.email,
    required this.pass,
    required this.cont,
    required this.forgot,
    required this.vtitle,
    required this.sent,
    required this.desc,
    required this.enterotp,
    required this.timer,
    required this.nootp,
    required this.resend,
    required this.confirm,
    required this.ftitle,
    required this.fdesc,
    required this.fsend,
    required this.rptitle,
    required this.newpass,
    required this.repass,
    required this.nomatch,
    required this.rpsave,
    required this.pwSaved,
    required this.phEmail,
    required this.phPass,
    required this.navHome,
    required this.navFarms,
    required this.navMilk,
    required this.navEvents,
    required this.navAccount,
  });

  static const Map<String, VanixStrings> all = {
    'en': VanixStrings(
      title: 'Login', email: 'EMAIL', pass: 'PASSWORD', cont: 'Continue', forgot: 'Forgot password?',
      vtitle: 'Verification', sent: 'OTP was sent to', desc: 'Enter the code to log in securely to your account.',
      enterotp: 'ENTER OTP', timer: 'Time Remaining', nootp: "Didn't receive OTP?", resend: 'Resend', confirm: 'Confirm',
      ftitle: 'Forgot password', fdesc: "Enter your registered email and we'll send you an OTP to reset your password.", fsend: 'Send OTP',
      rptitle: 'Set new password', newpass: 'NEW PASSWORD', repass: 'RE-ENTER PASSWORD', nomatch: "Passwords don't match",
      rpsave: 'Save password', pwSaved: 'Password updated — log in with your new password',
      phEmail: 'you@example.com', phPass: 'Enter your password',
      navHome: 'Home', navFarms: 'Farms', navMilk: 'Milk', navEvents: 'Events', navAccount: 'Account',
    ),
    'hi': VanixStrings(
      title: 'लॉगिन', email: 'ईमेल', pass: 'पासवर्ड', cont: 'जारी रखें', forgot: 'पासवर्ड भूल गए?',
      vtitle: 'सत्यापन', sent: 'OTP भेजा गया', desc: 'अपने खाते में सुरक्षित लॉगिन के लिए कोड डालें।',
      enterotp: 'OTP डालें', timer: 'समय शेष', nootp: 'OTP नहीं मिला?', resend: 'फिर से भेजें', confirm: 'पुष्टि करें',
      ftitle: 'पासवर्ड भूल गए', fdesc: 'अपना पंजीकृत ईमेल डालें, हम पासवर्ड रीसेट के लिए OTP भेजेंगे।', fsend: 'OTP भेजें',
      rptitle: 'नया पासवर्ड सेट करें', newpass: 'नया पासवर्ड', repass: 'पासवर्ड फिर से डालें', nomatch: 'पासवर्ड मेल नहीं खाते',
      rpsave: 'पासवर्ड सहेजें', pwSaved: 'पासवर्ड बदल गया — नए पासवर्ड से लॉगिन करें',
      phEmail: 'अपना ईमेल डालें', phPass: 'अपना पासवर्ड डालें',
      navHome: 'होम', navFarms: 'खेत', navMilk: 'दूध', navEvents: 'कार्यक्रम', navAccount: 'खाता',
    ),
    'bho': VanixStrings(
      title: 'लॉगिन', email: 'ईमेल', pass: 'पासवर्ड', cont: 'आगे बढ़ीं', forgot: 'पासवर्ड भुला गइनी?',
      vtitle: 'सत्यापन', sent: 'OTP भेजल गइल', desc: 'आपन खाता में सुरक्षित लॉगिन खातिर कोड डालीं।',
      enterotp: 'OTP डालीं', timer: 'समय बाकी', nootp: 'OTP ना मिलल?', resend: 'फिर से भेजीं', confirm: 'पुष्टि करीं',
      ftitle: 'पासवर्ड भुला गइनी', fdesc: 'आपन पंजीकृत ईमेल डालीं, हम पासवर्ड रीसेट खातिर OTP भेजब।', fsend: 'OTP भेजीं',
      rptitle: 'नया पासवर्ड सेट करीं', newpass: 'नया पासवर्ड', repass: 'पासवर्ड फिर से डालीं', nomatch: 'पासवर्ड मेल ना खाला',
      rpsave: 'पासवर्ड सहेजीं', pwSaved: 'पासवर्ड बदल गइल — नया पासवर्ड से लॉगिन करीं',
      phEmail: 'आपन ईमेल डालीं', phPass: 'आपन पासवर्ड डालीं',
      navHome: 'होम', navFarms: 'खेत', navMilk: 'दूध', navEvents: 'कार्यक्रम', navAccount: 'खाता',
    ),
  };

  static VanixStrings of(String languageCode) => all[languageCode] ?? all['hi']!;
}

class VanixLanguage {
  final String code, native, english;
  const VanixLanguage(this.code, this.native, this.english);

  static const supported = [
    VanixLanguage('en', 'English', 'English'),
    VanixLanguage('hi', 'हिंदी', 'Hindi'),
    VanixLanguage('bho', 'भोजपुरी', 'Bhojpuri'),
  ];
}
