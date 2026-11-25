// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swahili (`sw`).
class AppLocalizationsSw extends AppLocalizations {
  AppLocalizationsSw([String locale = 'sw']) : super(locale);

  @override
  String get appName => 'Pesa';

  @override
  String get tagline => 'Pesa zako, wazi.';

  @override
  String get navHome => 'Nyumbani';

  @override
  String get navActivity => 'Shughuli';

  @override
  String get navPay => 'Lipa';

  @override
  String get navGrow => 'Kua';

  @override
  String get navProfile => 'Wasifu';

  @override
  String get onboardTitle1 => 'Pesa zako zote mahali pamoja';

  @override
  String get onboardBody1 =>
      'Ona salio la M-Pesa na benki pamoja, limethibitishwa na watoa huduma wako.';

  @override
  String get onboardTitle2 => 'Lipa bili na tuma pesa';

  @override
  String get onboardBody2 =>
      'Paybill, Till, muda wa maongezi na huduma — pamoja na risiti za kuaminika.';

  @override
  String get onboardTitle3 => 'Weka akiba kwa lengo';

  @override
  String get onboardBody3 =>
      'Weka malengo, fuatilia bajeti na upate maarifa ya kupanga.';

  @override
  String get getStarted => 'Anza';

  @override
  String get haveAccount => 'Tayari nina akaunti';

  @override
  String get next => 'Endelea';

  @override
  String get skip => 'Ruka';

  @override
  String get signIn => 'Ingia';

  @override
  String get createAccount => 'Fungua akaunti';

  @override
  String get phoneNumber => 'Nambari ya simu';

  @override
  String get password => 'Nenosiri';

  @override
  String get firstName => 'Jina la kwanza';

  @override
  String get lastName => 'Jina la mwisho';

  @override
  String get emailOptional => 'Barua pepe (si lazima)';

  @override
  String get referralOptional => 'Msimbo wa rufaa (si lazima)';

  @override
  String get forgotPassword => 'Umesahau nenosiri?';

  @override
  String get continueLabel => 'Endelea';

  @override
  String get verifyTitle => 'Weka msimbo';

  @override
  String verifyBody(String phone) {
    return 'Tumetuma msimbo wa tarakimu 6 kwa SMS kwa $phone.';
  }

  @override
  String get resendCode => 'Tuma tena';

  @override
  String get createPinTitle => 'Unda PIN yako ya malipo';

  @override
  String get createPinBody =>
      'Utatumia PIN hii ya tarakimu 4 kuidhinisha malipo. Si PIN yako ya M-Pesa.';

  @override
  String get confirmPinTitle => 'Thibitisha PIN yako';

  @override
  String get pinMismatch => 'PIN hazilingani. Jaribu tena.';

  @override
  String get unlockTitle => 'Karibu tena';

  @override
  String get unlockBody => 'Weka PIN kufungua';

  @override
  String get useBiometrics => 'Tumia alama ya kidole au uso';

  @override
  String get signOut => 'Toka';

  @override
  String get goodMorning => 'Habari za asubuhi';

  @override
  String get goodAfternoon => 'Habari za mchana';

  @override
  String get goodEvening => 'Habari za jioni';

  @override
  String get verifiedBalance => 'Salio lililothibitishwa';

  @override
  String get manualBalance => 'Linafuatiliwa kwa mkono';

  @override
  String get noLinkedAccounts =>
      'Unganisha akaunti kuona salio lililothibitishwa';

  @override
  String get thisMonth => 'Mwezi huu';

  @override
  String get income => 'Mapato';

  @override
  String get expenses => 'Matumizi';

  @override
  String get estimated => 'Makadirio';

  @override
  String get sendMoney => 'Tuma';

  @override
  String get receiveMoney => 'Pokea';

  @override
  String get addMoney => 'Ongeza pesa';

  @override
  String get buyAirtime => 'Muda wa maongezi';

  @override
  String get payBills => 'Lipa bili';

  @override
  String get saveMoney => 'Weka akiba';

  @override
  String get recentActivity => 'Shughuli za hivi karibuni';

  @override
  String get seeAll => 'Ona zote';

  @override
  String get amount => 'Kiasi';

  @override
  String get recipient => 'Mpokeaji';

  @override
  String get confirmPayment => 'Thibitisha malipo';

  @override
  String get enterPinToPay => 'Weka PIN kulipa';

  @override
  String get paymentPending => 'Malipo yanaendelea';

  @override
  String get paymentSuccess => 'Malipo yamefanikiwa';

  @override
  String get paymentFailed => 'Malipo yameshindikana';

  @override
  String get savingsGoals => 'Malengo ya akiba';

  @override
  String get budgets => 'Bajeti';

  @override
  String get insights => 'Maarifa';

  @override
  String get rewards => 'Zawadi';

  @override
  String get cards => 'Kadi';

  @override
  String get notifications => 'Arifa';

  @override
  String get security => 'Usalama';

  @override
  String get language => 'Lugha';

  @override
  String get theme => 'Mandhari';

  @override
  String get support => 'Msaada';

  @override
  String get sandboxNotice =>
      'Hali ya majaribio — hakuna pesa halisi inayohamishwa.';
}
