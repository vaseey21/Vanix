/// Mirrors the STRINGS object in vanix_screens.html — keep both in sync.
/// Default locale is Hindi (see CLAUDE.md); Phase 1 supports en / hi / bho.
class VanixStrings {
  final String title, email, cont;
  final String vtitle, sent, desc, enterotp, timer, nootp, resend, confirm;
  final String phEmail;
  final String navHome, navFarms, navMilk, navEvents, navAccount;

  const VanixStrings({
    required this.title,
    required this.email,
    required this.cont,
    required this.vtitle,
    required this.sent,
    required this.desc,
    required this.enterotp,
    required this.timer,
    required this.nootp,
    required this.resend,
    required this.confirm,
    required this.phEmail,
    required this.navHome,
    required this.navFarms,
    required this.navMilk,
    required this.navEvents,
    required this.navAccount,
  });

  static const Map<String, VanixStrings> all = {
    'en': VanixStrings(
      title: 'Login', email: 'EMAIL', cont: 'Continue',
      vtitle: 'Verification', sent: 'OTP was sent to', desc: 'Enter the code to log in securely to your account.',
      enterotp: 'ENTER OTP', timer: 'Time Remaining', nootp: "Didn't receive OTP?", resend: 'Resend', confirm: 'Confirm',
      phEmail: 'you@example.com',
      navHome: 'Home', navFarms: 'Farms', navMilk: 'Milk', navEvents: 'Events', navAccount: 'Account',
    ),
    'hi': VanixStrings(
      title: 'लॉगिन', email: 'ईमेल', cont: 'जारी रखें',
      vtitle: 'सत्यापन', sent: 'OTP भेजा गया', desc: 'अपने खाते में सुरक्षित लॉगिन के लिए कोड डालें।',
      enterotp: 'OTP डालें', timer: 'समय शेष', nootp: 'OTP नहीं मिला?', resend: 'फिर से भेजें', confirm: 'पुष्टि करें',
      phEmail: 'अपना ईमेल डालें',
      navHome: 'होम', navFarms: 'खेत', navMilk: 'दूध', navEvents: 'कार्यक्रम', navAccount: 'खाता',
    ),
    'bho': VanixStrings(
      title: 'लॉगिन', email: 'ईमेल', cont: 'आगे बढ़ीं',
      vtitle: 'सत्यापन', sent: 'OTP भेजल गइल', desc: 'आपन खाता में सुरक्षित लॉगिन खातिर कोड डालीं।',
      enterotp: 'OTP डालीं', timer: 'समय बाकी', nootp: 'OTP ना मिलल?', resend: 'फिर से भेजीं', confirm: 'पुष्टि करीं',
      phEmail: 'आपन ईमेल डालीं',
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
