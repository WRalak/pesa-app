import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../../../core/theme/theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../data/auth_controller.dart';
import '../data/auth_models.dart';
import 'auth_widgets.dart';

// ------------------------------------------------------------------ splash
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: PesaColors.navy950,
        body: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: .85, end: 1),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutBack,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const PesaLogo(size: 76),
              const SizedBox(height: Space.lg),
              Text('Pesa', style: context.text.headlineMedium?.copyWith(color: Colors.white)),
            ]),
          ),
        ),
      );
}

// ------------------------------------------------------------------ onboarding
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _page = PageController();
  int _index = 0;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  Future<void> _finish(String route) async {
    await ref.read(authControllerProvider.notifier).completeOnboarding();
    if (mounted) context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final pages = [
      (Icons.account_balance_wallet_rounded, l.onboardTitle1, l.onboardBody1, PesaColors.emerald500),
      (Icons.receipt_long_rounded, l.onboardTitle2, l.onboardBody2, PesaColors.gold500),
      (Icons.savings_rounded, l.onboardTitle3, l.onboardBody3, PesaColors.sky500),
    ];
    return Scaffold(
      backgroundColor: PesaColors.navy950,
      body: SafeArea(
        child: Column(children: [
          Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => _finish('/login'), child: Text(l.skip, style: const TextStyle(color: Colors.white70)))),
          Expanded(
            child: PageView.builder(
              controller: _page,
              itemCount: pages.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) {
                final (icon, title, body, accent) = pages[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      width: 120, height: 120,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(colors: [accent.withValues(alpha: .45), accent.withValues(alpha: 0)]),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Icon(icon, size: 56, color: accent),
                    ),
                    const SizedBox(height: 36),
                    Text(title, style: context.text.displaySmall?.copyWith(color: Colors.white, fontSize: 34)),
                    const SizedBox(height: 14),
                    Text(body, style: context.text.bodyLarge?.copyWith(color: const Color(0xFFA9C0D4), height: 1.5)),
                  ]),
                );
              },
            ),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 0; i < pages.length; i++)
              AnimatedContainer(duration: const Duration(milliseconds: 250), margin: const EdgeInsets.all(4), width: i == _index ? 22 : 8, height: 8, decoration: BoxDecoration(color: i == _index ? PesaColors.emerald500 : Colors.white24, borderRadius: BorderRadius.circular(8))),
          ]),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(children: [
              FilledButton(
                onPressed: () => _index < pages.length - 1 ? _page.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut) : _finish('/register'),
                child: Text(_index < pages.length - 1 ? l.next : l.getStarted),
              ),
              TextButton(onPressed: () => _finish('/login'), child: Text(l.haveAccount, style: const TextStyle(color: Colors.white))),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ------------------------------------------------------------------ login
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    ref.read(secureStoreProvider).lastPhone.then((p) {
      if (p != null && mounted && _phone.text.isEmpty) _phone.text = p.replaceFirst('+254', '');
    });
  }

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      // If an OTP step is needed the router redirects to /verify automatically.
      await ref.read(authControllerProvider.notifier).login(PhoneField.toE164(_phone.text), _password.text);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Form(
          key: _form,
          child: AutofillGroup(
            child: ListView(padding: Space.page, children: [
              AuthHeader(title: l.signIn, subtitle: 'Welcome back. Sign in with your phone number.'),
              PhoneField(controller: _phone, label: l.phoneNumber),
              const SizedBox(height: Space.lg),
              PasswordField(controller: _password, label: l.password),
              Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => context.push('/forgot-password'), child: Text(l.forgotPassword))),
              const SizedBox(height: Space.lg),
              LoadingButton(label: l.signIn, loading: _busy, onPressed: _submit),
              const SizedBox(height: Space.md),
              TextButton(onPressed: () => context.go('/register'), child: Text(l.createAccount)),
              TextButton(onPressed: () => context.push('/recovery'), child: const Text('Lost access to your phone number?')),
            ]),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ register
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _referral = TextEditingController();
  bool _terms = false;
  bool _marketing = false;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_first, _last, _phone, _email, _password, _referral]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (!_terms) return showMessage(context, 'Please accept the Terms and Privacy Policy to continue.');
    setState(() => _busy = true);
    try {
      await ref.read(authControllerProvider.notifier).register(
            phone: PhoneField.toE164(_phone.text), password: _password.text, firstName: _first.text.trim(), lastName: _last.text.trim(),
            email: _email.text.trim(), referralCode: _referral.text.trim(), marketingConsent: _marketing,
            locale: Localizations.localeOf(context).languageCode == 'sw' ? 'sw-KE' : 'en-KE',
          );
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Form(
          key: _form,
          child: AutofillGroup(
            child: ListView(padding: Space.page.copyWith(bottom: 32), children: [
              AuthHeader(title: l.createAccount, subtitle: 'It takes about a minute. You\'ll verify your number by SMS.'),
              Row(children: [
                Expanded(child: TextFormField(controller: _first, textCapitalization: TextCapitalization.words, autofillHints: const [AutofillHints.givenName], decoration: InputDecoration(labelText: l.firstName), validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null)),
                const SizedBox(width: Space.md),
                Expanded(child: TextFormField(controller: _last, textCapitalization: TextCapitalization.words, autofillHints: const [AutofillHints.familyName], decoration: InputDecoration(labelText: l.lastName), validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null)),
              ]),
              const SizedBox(height: Space.lg),
              PhoneField(controller: _phone, label: l.phoneNumber),
              const SizedBox(height: Space.lg),
              TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, autofillHints: const [AutofillHints.email], decoration: InputDecoration(labelText: l.emailOptional),
                  validator: (v) => (v ?? '').isEmpty || RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v!) ? null : 'Enter a valid email'),
              const SizedBox(height: Space.lg),
              PasswordField(controller: _password, label: l.password, newPassword: true, validator: validateNewPassword),
              const SizedBox(height: Space.lg),
              TextFormField(controller: _referral, textCapitalization: TextCapitalization.characters, decoration: InputDecoration(labelText: l.referralOptional)),
              const SizedBox(height: Space.md),
              CheckboxListTile(
                value: _terms, onChanged: (v) => setState(() => _terms = v ?? false), contentPadding: EdgeInsets.zero, controlAffinity: ListTileControlAffinity.leading,
                title: const Text('I agree to the Terms of Service and Privacy Policy'),
                subtitle: Text('We process your data under the Kenya Data Protection Act, 2019.', style: context.text.bodySmall?.copyWith(color: context.palette.text3)),
              ),
              CheckboxListTile(value: _marketing, onChanged: (v) => setState(() => _marketing = v ?? false), contentPadding: EdgeInsets.zero, controlAffinity: ListTileControlAffinity.leading, title: const Text('Send me offers and product news (optional)')),
              const SizedBox(height: Space.lg),
              LoadingButton(label: l.continueLabel, loading: _busy, onPressed: _submit),
              const SizedBox(height: Space.md),
              Text('Pesa is a money-management app. Payments are processed by licensed partners; Pesa does not hold your money.', style: context.text.bodySmall?.copyWith(color: context.palette.text3), textAlign: TextAlign.center),
            ]),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ OTP
class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});
  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _otpKey = GlobalKey<OtpFieldState>();
  bool _busy = false;
  int _cooldown = 30;

  @override
  void initState() {
    super.initState();
    _tick();
  }

  void _tick() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted || _cooldown == 0) return;
      setState(() => _cooldown--);
      _tick();
    });
  }

  Future<void> _verify(String code) async {
    setState(() => _busy = true);
    try {
      await ref.read(authControllerProvider.notifier).verifyOtp(code);
    } catch (e) {
      _otpKey.currentState?.clear();
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = ref.watch(authControllerProvider);
    final pending = s is Unauthenticated ? s.pending : null;
    return Scaffold(
      appBar: AppBar(leading: BackButton(onPressed: () => ref.read(authControllerProvider.notifier).setPending(null))),
      body: SafeArea(
        child: ListView(padding: Space.page, children: [
          AuthHeader(
            title: pending?.purpose == OtpPurpose.deviceVerify ? 'Verify this device' : l.verifyTitle,
            subtitle: pending?.purpose == OtpPurpose.deviceVerify ? 'For your security, confirm it\'s you. We sent a code to ${pending?.phone}.' : l.verifyBody(pending?.phone ?? ''),
          ),
          OtpField(key: _otpKey, onCompleted: _verify),
          const SizedBox(height: Space.xxl),
          if (_busy) const Center(child: CircularProgressIndicator()),
          Center(
            child: TextButton(
              onPressed: _cooldown > 0 || pending == null ? null : () async {
                try {
                  await ref.read(authRepositoryProvider).resendOtp(pending);
                  setState(() => _cooldown = 30);
                  _tick();
                  if (context.mounted) showMessage(context, 'A new code is on its way.');
                } catch (e) {
                  if (context.mounted) showError(context, e);
                }
              },
              child: Text(_cooldown > 0 ? '${l.resendCode} (${_cooldown}s)' : l.resendCode),
            ),
          ),
          const SizedBox(height: Space.lg),
          Text('Pesa will never call or text you asking for this code.', style: context.text.bodySmall?.copyWith(color: context.palette.text3), textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

// ------------------------------------------------------------------ create PIN
class CreatePinScreen extends ConsumerStatefulWidget {
  const CreatePinScreen({super.key});
  @override
  ConsumerState<CreatePinScreen> createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends ConsumerState<CreatePinScreen> {
  String? _first;
  String? _error;
  bool _busy = false;

  Future<void> _onPin(String pin) async {
    final l = AppLocalizations.of(context);
    if (_first == null) {
      setState(() { _first = pin; _error = null; });
      return;
    }
    if (pin != _first) {
      setState(() { _first = null; _error = l.pinMismatch; });
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).createPin(pin);
      final bio = ref.read(biometricServiceProvider);
      if (await bio.isAvailable() && mounted) {
        final enable = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
          title: const Text('Unlock with biometrics?'),
          content: const Text('Use your fingerprint or face to open Pesa. You will still need your PIN to approve payments.'),
          actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Not now')), FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Enable'))],
        ));
        if (enable == true && await bio.authenticate('Confirm to enable biometric unlock')) {
          await ref.read(secureStoreProvider).setBiometricEnabled(true);
          await ref.read(apiClientProvider).patch('/v1/me/devices/current', body: {'biometricEnabled': true});
        }
      }
      await ref.read(authControllerProvider.notifier).refreshUser();
    } catch (e) {
      setState(() { _first = null; _error = e is ApiException ? e.message : 'Could not save PIN'; });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: Space.page,
          child: Column(children: [
            const SizedBox(height: 40),
            AuthHeader(title: _first == null ? l.createPinTitle : l.confirmPinTitle, subtitle: l.createPinBody),
            const Spacer(),
            PinPad(onCompleted: _onPin, error: _error, busy: _busy),
            const SizedBox(height: Space.xxl),
          ]),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ app lock
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});
  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  String? _error;
  bool _busy = false;
  bool _bioAvailable = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final enabled = await ref.read(secureStoreProvider).biometricEnabled;
      final available = enabled && await ref.read(biometricServiceProvider).isAvailable();
      if (!mounted) return;
      setState(() => _bioAvailable = available);
      if (available) await _bio();
    });
  }

  Future<void> _bio() async {
    if (!mounted) return;
    final ok = await ref.read(authControllerProvider.notifier).unlockWithBiometrics(AppLocalizations.of(context).unlockBody);
    if (!ok && mounted) setState(() => _error = null);
  }

  Future<void> _pin(String pin) async {
    setState(() { _busy = true; _error = null; });
    try {
      await ref.read(authControllerProvider.notifier).unlockWithPin(pin);
    } catch (e) {
      setState(() => _error = e is ApiException ? e.message : 'Incorrect PIN');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: Space.page,
          child: Column(children: [
            const SizedBox(height: 48),
            const PesaLogo(size: 56),
            const SizedBox(height: Space.lg),
            Text(l.unlockTitle, style: context.text.headlineSmall),
            Text(l.unlockBody, style: context.text.bodyMedium?.copyWith(color: context.palette.text2)),
            const Spacer(),
            PinPad(onCompleted: _pin, error: _error, busy: _busy, biometricAction: _bioAvailable ? _bio : null),
            TextButton(onPressed: () => ref.read(authControllerProvider.notifier).logout(), child: Text(l.signOut)),
            const SizedBox(height: Space.md),
          ]),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ forgot password
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  bool _codeSent = false;
  bool _busy = false;

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final repo = ref.read(authRepositoryProvider);
    try {
      if (!_codeSent) {
        await repo.forgotPassword(PhoneField.toE164(_phone.text));
        setState(() => _codeSent = true);
      } else {
        await repo.resetPassword(PhoneField.toE164(_phone.text), _code.text, _password.text);
        if (!mounted) return;
        showMessage(context, 'Password reset. Sign in with your new password — you\'ll verify this device again.');
        context.go('/login');
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(),
        body: SafeArea(
          child: Form(
            key: _form,
            child: ListView(padding: Space.page, children: [
              AuthHeader(title: 'Reset password', subtitle: _codeSent ? 'If the number is registered, we sent a reset code by SMS.' : 'Enter your phone number and we\'ll send a reset code.'),
              PhoneField(controller: _phone),
              if (_codeSent) ...[
                const SizedBox(height: Space.lg),
                TextFormField(controller: _code, keyboardType: TextInputType.number, maxLength: 6, autofillHints: const [AutofillHints.oneTimeCode], decoration: const InputDecoration(labelText: 'Reset code'), validator: (v) => RegExp(r'^\d{6}$').hasMatch(v ?? '') ? null : 'Enter the 6-digit code'),
                PasswordField(controller: _password, label: 'New password', newPassword: true, validator: validateNewPassword),
              ],
              const SizedBox(height: Space.xxl),
              LoadingButton(label: _codeSent ? 'Reset password' : 'Send code', loading: _busy, onPressed: _submit),
            ]),
          ),
        ),
      );
}

// ------------------------------------------------------------------ account recovery
class RecoveryScreen extends ConsumerStatefulWidget {
  const RecoveryScreen({super.key});
  @override
  ConsumerState<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends ConsumerState<RecoveryScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _phone = TextEditingController();
  final _details = TextEditingController();
  bool _sent = false;
  bool _busy = false;
  String? _ticket;

  @override
  void dispose() {
    for (final c in [_email, _code, _phone, _details]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final repo = ref.read(authRepositoryProvider);
    try {
      if (!_sent) {
        await repo.startRecovery(_email.text.trim());
        setState(() => _sent = true);
      } else {
        final t = await repo.completeRecovery(_email.text.trim(), _code.text, PhoneField.toE164(_phone.text), _details.text.trim().isEmpty ? null : _details.text.trim());
        setState(() => _ticket = t);
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(),
        body: SafeArea(
          child: _ticket != null
              ? EmptyState(icon: Icons.verified_user_rounded, title: 'Request received', message: 'Reference $_ticket. Our team will verify your identity before moving your account to the new number. This protects you from SIM-swap fraud.', action: FilledButton(onPressed: () => context.go('/login'), child: const Text('Back to sign in')))
              : Form(
                  key: _form,
                  child: ListView(padding: Space.page, children: [
                    const AuthHeader(title: 'Recover your account', subtitle: 'Lost your SIM or number? Use the email you verified. A support agent reviews every number change.'),
                    TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Verified email'), validator: (v) => (v ?? '').contains('@') ? null : 'Enter your email'),
                    if (_sent) ...[
                      const SizedBox(height: Space.lg),
                      TextFormField(controller: _code, keyboardType: TextInputType.number, maxLength: 6, decoration: const InputDecoration(labelText: 'Code from email'), validator: (v) => RegExp(r'^\d{6}$').hasMatch(v ?? '') ? null : 'Enter the 6-digit code'),
                      PhoneField(controller: _phone, label: 'New phone number'),
                      const SizedBox(height: Space.lg),
                      TextFormField(controller: _details, maxLines: 3, maxLength: 1000, decoration: const InputDecoration(labelText: 'What happened? (optional)')),
                    ],
                    const SizedBox(height: Space.xl),
                    LoadingButton(label: _sent ? 'Submit for review' : 'Send code', loading: _busy, onPressed: _submit),
                  ]),
                ),
        ),
      );
}
