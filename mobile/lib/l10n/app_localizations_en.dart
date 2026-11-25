// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Pesa';

  @override
  String get tagline => 'Your money, clearly.';

  @override
  String get navHome => 'Home';

  @override
  String get navActivity => 'Activity';

  @override
  String get navPay => 'Pay';

  @override
  String get navGrow => 'Grow';

  @override
  String get navProfile => 'Profile';

  @override
  String get onboardTitle1 => 'All your money in one place';

  @override
  String get onboardBody1 =>
      'See M-Pesa and bank balances side by side, verified by your providers.';

  @override
  String get onboardTitle2 => 'Pay bills and send money';

  @override
  String get onboardBody2 =>
      'Paybill, Till, airtime and utilities — with receipts you can trust.';

  @override
  String get onboardTitle3 => 'Save with purpose';

  @override
  String get onboardBody3 =>
      'Set goals, track budgets and get insights that help you plan.';

  @override
  String get getStarted => 'Get started';

  @override
  String get haveAccount => 'I already have an account';

  @override
  String get next => 'Next';

  @override
  String get skip => 'Skip';

  @override
  String get signIn => 'Sign in';

  @override
  String get createAccount => 'Create account';

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get password => 'Password';

  @override
  String get firstName => 'First name';

  @override
  String get lastName => 'Last name';

  @override
  String get emailOptional => 'Email (optional)';

  @override
  String get referralOptional => 'Referral code (optional)';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get continueLabel => 'Continue';

  @override
  String get verifyTitle => 'Enter the code';

  @override
  String verifyBody(String phone) {
    return 'We sent a 6-digit code by SMS to $phone.';
  }

  @override
  String get resendCode => 'Resend code';

  @override
  String get createPinTitle => 'Create your transaction PIN';

  @override
  String get createPinBody =>
      'You\'ll use this 4-digit PIN to approve payments. It is not your M-Pesa PIN.';

  @override
  String get confirmPinTitle => 'Confirm your PIN';

  @override
  String get pinMismatch => 'PINs didn\'t match. Try again.';

  @override
  String get unlockTitle => 'Welcome back';

  @override
  String get unlockBody => 'Enter your PIN to unlock';

  @override
  String get useBiometrics => 'Use fingerprint or face';

  @override
  String get signOut => 'Sign out';

  @override
  String get goodMorning => 'Good morning';

  @override
  String get goodAfternoon => 'Good afternoon';

  @override
  String get goodEvening => 'Good evening';

  @override
  String get verifiedBalance => 'Verified balance';

  @override
  String get manualBalance => 'Tracked manually';

  @override
  String get noLinkedAccounts => 'Link an account to see verified balances';

  @override
  String get thisMonth => 'This month';

  @override
  String get income => 'Income';

  @override
  String get expenses => 'Spending';

  @override
  String get estimated => 'Estimated';

  @override
  String get sendMoney => 'Send';

  @override
  String get receiveMoney => 'Receive';

  @override
  String get addMoney => 'Add money';

  @override
  String get buyAirtime => 'Airtime';

  @override
  String get payBills => 'Pay bills';

  @override
  String get saveMoney => 'Save';

  @override
  String get recentActivity => 'Recent activity';

  @override
  String get seeAll => 'See all';

  @override
  String get amount => 'Amount';

  @override
  String get recipient => 'Recipient';

  @override
  String get confirmPayment => 'Confirm payment';

  @override
  String get enterPinToPay => 'Enter your PIN to pay';

  @override
  String get paymentPending => 'Payment in progress';

  @override
  String get paymentSuccess => 'Payment successful';

  @override
  String get paymentFailed => 'Payment failed';

  @override
  String get savingsGoals => 'Savings goals';

  @override
  String get budgets => 'Budgets';

  @override
  String get insights => 'Insights';

  @override
  String get rewards => 'Rewards';

  @override
  String get cards => 'Cards';

  @override
  String get notifications => 'Notifications';

  @override
  String get security => 'Security';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get support => 'Help & support';

  @override
  String get sandboxNotice => 'Sandbox mode — no real money moves.';
}
