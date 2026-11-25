import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/app_settings.dart';
import '../../../core/config/env.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../../../core/theme/theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/data/auth_controller.dart';
import '../../auth/ui/auth_widgets.dart';
import '../../home/data/dashboard.dart';

final _api = Provider((ref) => ref.watch(apiClientProvider));

// ------------------------------------------------------------------ profile home
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final s = ref.watch(authControllerProvider);
    if (s is! Authenticated) return const SizedBox.shrink();
    final u = s.user;
    final p = s.profile;
    Widget tile(IconData i, String t, String route, {String? sub}) => ListTile(leading: Icon(i), title: Text(t), subtitle: sub == null ? null : Text(sub), trailing: const Icon(Icons.chevron_right_rounded), onTap: () => context.push(route));
    return Scaffold(
      appBar: AppBar(title: Text(l.navProfile)),
      body: ListView(padding: const EdgeInsets.only(bottom: 32), children: [
        Padding(
          padding: Space.page,
          child: PesaCard(onTap: () => context.push('/profile/personal'), child: Row(children: [
            CircleAvatar(radius: 28, backgroundColor: context.colors.primaryContainer, child: Text('${(p?.firstName ?? 'P').characters.first}${(p?.lastName ?? '').isEmpty ? '' : p!.lastName!.characters.first}', style: context.text.titleLarge?.copyWith(color: context.colors.primary))),
            const SizedBox(width: Space.lg),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${p?.firstName ?? ''} ${p?.lastName ?? ''}'.trim(), style: context.text.titleMedium),
              Text(u.phone, style: context.text.bodySmall?.copyWith(color: context.palette.text2)),
              const SizedBox(height: 4),
              _KycBadge(status: u.kycStatus, tier: u.kycTier),
            ])),
            const Icon(Icons.chevron_right_rounded),
          ])),
        ),
        if (u.kycStatus != 'VERIFIED') Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 0), child: PesaCard(color: PesaColors.gold500.withValues(alpha: .1), onTap: () => context.push('/profile/kyc'), child: Row(children: [const Icon(Icons.verified_user_outlined, color: PesaColors.warning), const SizedBox(width: Space.md), Expanded(child: Text(u.kycStatus == 'PENDING' ? 'Your identity is being verified.' : 'Verify your identity to raise your limits.')), const Icon(Icons.chevron_right_rounded)]))),
        const _Group('Money'),
        tile(Icons.account_balance_rounded, 'Linked accounts', '/profile/accounts'),
        tile(Icons.speed_rounded, 'Transaction limits', '/profile/limits'),
        tile(Icons.description_outlined, 'Statements', '/activity'),
        _Group(l.security),
        tile(Icons.lock_outline_rounded, 'PIN, password & biometrics', '/profile/security'),
        tile(Icons.devices_rounded, 'Devices & sessions', '/profile/devices'),
        const _Group('Preferences'),
        tile(Icons.notifications_none_rounded, l.notifications, '/profile/notifications'),
        tile(Icons.privacy_tip_outlined, 'Privacy & data', '/profile/privacy'),
        tile(Icons.translate_rounded, '${l.language} & ${l.theme.toLowerCase()}', '/profile/appearance'),
        _Group(l.support),
        tile(Icons.support_agent_rounded, 'Help & support', '/profile/support'),
        ListTile(leading: const Icon(Icons.info_outline_rounded), title: const Text('About Pesa'), onTap: () async {
          final info = await PackageInfo.fromPlatform();
          if (!context.mounted) return;
          showAboutDialog(context: context, applicationName: 'Pesa', applicationVersion: '${info.version} (${Env.env.name})', children: const [Text('Pesa is a financial management platform. Payments are processed by licensed payment service providers. Pesa does not hold customer funds and is not a bank.')]);
        }),
        const SizedBox(height: Space.lg),
        Padding(padding: Space.page, child: OutlinedButton.icon(onPressed: () => ref.read(authControllerProvider.notifier).logout(), icon: const Icon(Icons.logout_rounded), label: Text(l.signOut))),
      ]),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group(this.t);
  final String t;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.fromLTRB(20, 24, 20, 4), child: Text(t.toUpperCase(), style: context.text.labelSmall?.copyWith(color: context.palette.text3, letterSpacing: 1)));
}

class _KycBadge extends StatelessWidget {
  const _KycBadge({required this.status, required this.tier});
  final String status, tier;
  @override
  Widget build(BuildContext context) {
    final (c, t) = switch (status) { 'VERIFIED' => (PesaColors.emerald500, 'Verified · ${tier.replaceAll('_', ' ')}'), 'PENDING' => (PesaColors.gold500, 'Verification pending'), 'REJECTED' => (PesaColors.danger, 'Verification needed'), _ => (context.palette.text3, 'Not verified') };
    return Row(children: [Icon(Icons.verified_rounded, size: 14, color: c), const SizedBox(width: 4), Text(t, style: context.text.labelSmall?.copyWith(color: c))]);
  }
}

// ------------------------------------------------------------------ personal info
class PersonalInfoScreen extends ConsumerStatefulWidget {
  const PersonalInfoScreen({super.key});
  @override
  ConsumerState<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends ConsumerState<PersonalInfoScreen> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _occupation = TextEditingController();
  final _city = TextEditingController();
  final _email = TextEditingController();
  DateTime? _dob;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final s = ref.read(authControllerProvider);
    if (s is Authenticated) {
      _first.text = s.profile?.firstName ?? '';
      _last.text = s.profile?.lastName ?? '';
      _occupation.text = s.profile?.occupation ?? '';
      _city.text = '${s.profile?.address['city'] ?? ''}';
      _email.text = s.user.email ?? '';
      _dob = s.profile?.dateOfBirth;
    }
  }

  @override
  void dispose() {
    for (final c in [_first, _last, _occupation, _city, _email]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(authControllerProvider);
    final user = s is Authenticated ? s.user : null;
    final locked = user?.kycStatus == 'VERIFIED';
    return Scaffold(
      appBar: AppBar(title: const Text('Personal information')),
      body: ListView(padding: Space.page.copyWith(bottom: 32), children: [
        if (locked) Padding(padding: const EdgeInsets.only(bottom: Space.md), child: Text('Your name and date of birth match your verified ID. Contact support to change them.', style: context.text.bodySmall?.copyWith(color: context.palette.text2))),
        TextField(controller: _first, enabled: !locked, decoration: const InputDecoration(labelText: 'First name')),
        const SizedBox(height: Space.md),
        TextField(controller: _last, enabled: !locked, decoration: const InputDecoration(labelText: 'Last name')),
        const SizedBox(height: Space.md),
        ListTile(contentPadding: EdgeInsets.zero, enabled: !locked, title: const Text('Date of birth'), subtitle: Text(_dob == null ? 'Not set' : DateFormat('d MMMM yyyy').format(_dob!)), trailing: const Icon(Icons.edit_calendar_rounded), onTap: () async {
          final d = await showDatePicker(context: context, firstDate: DateTime(1920), lastDate: DateTime.now().subtract(const Duration(days: 365 * 16)), initialDate: _dob ?? DateTime(1995));
          if (d != null) setState(() => _dob = d);
        }),
        TextField(controller: _occupation, decoration: const InputDecoration(labelText: 'Occupation')),
        const SizedBox(height: Space.md),
        TextField(controller: _city, decoration: const InputDecoration(labelText: 'Town / city')),
        const SizedBox(height: Space.xl),
        LoadingButton(label: 'Save', loading: _busy, onPressed: () async {
          setState(() => _busy = true);
          try {
            await ref.read(_api).patch('/v1/me/profile', body: {
              if (!locked && _first.text.trim().isNotEmpty) 'firstName': _first.text.trim(),
              if (!locked && _last.text.trim().isNotEmpty) 'lastName': _last.text.trim(),
              if (!locked && _dob != null) 'dateOfBirth': DateFormat('yyyy-MM-dd').format(_dob!),
              if (_occupation.text.trim().isNotEmpty) 'occupation': _occupation.text.trim(),
              if (_city.text.trim().isNotEmpty) 'address': {'city': _city.text.trim()},
            });
            await ref.read(authControllerProvider.notifier).refreshUser();
            if (context.mounted) showMessage(context, 'Saved');
          } catch (e) {
            if (context.mounted) showError(context, e);
          } finally {
            if (mounted) setState(() => _busy = false);
          }
        }),
        const SectionHeader('Email'),
        Row(children: [
          Expanded(child: TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: 'Email', suffixIcon: user?.emailVerified == true ? const Icon(Icons.verified_rounded, color: PesaColors.emerald500) : null))),
          const SizedBox(width: Space.sm),
          TextButton(onPressed: () => _verifyEmail(context), child: Text(user?.emailVerified == true ? 'Change' : 'Verify')),
        ]),
        Text('A verified email lets you recover your account if you lose your phone number.', style: context.text.bodySmall?.copyWith(color: context.palette.text3)),
      ]),
    );
  }

  Future<void> _verifyEmail(BuildContext context) async {
    final repo = ref.read(authRepositoryProvider);
    try {
      await repo.requestEmailCode(_email.text.trim());
      if (!context.mounted) return;
      final code = await showDialog<String>(context: context, builder: (c) {
        final ctl = TextEditingController();
        return AlertDialog(title: const Text('Enter the code we emailed you'), content: TextField(controller: ctl, keyboardType: TextInputType.number, maxLength: 6), actions: [FilledButton(onPressed: () => Navigator.pop(c, ctl.text), child: const Text('Verify'))]);
      });
      if (code == null) return;
      await repo.verifyEmail(code);
      await ref.read(authControllerProvider.notifier).refreshUser();
      if (context.mounted) showMessage(context, 'Email verified');
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }
}

// ------------------------------------------------------------------ KYC
class KycScreen extends ConsumerStatefulWidget {
  const KycScreen({super.key});
  @override
  ConsumerState<KycScreen> createState() => _KycScreenState();
}

final _kycProvider = FutureProvider.autoDispose<Json>((ref) => ref.watch(_api).get('/v1/me/kyc'));

class _KycScreenState extends ConsumerState<KycScreen> {
  final _idNumber = TextEditingController();
  final _name = TextEditingController();
  DateTime? _dob;
  String _idType = 'NATIONAL_ID';
  bool _busy = false;

  @override
  void dispose() {
    _idNumber.dispose();
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kyc = ref.watch(_kycProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Verify your identity')),
      body: AsyncView(value: kyc, onRetry: () => ref.invalidate(_kycProvider), data: (k) {
        final status = '${k['status']}';
        if (status == 'VERIFIED' || status == 'PENDING') {
          return EmptyState(icon: status == 'VERIFIED' ? Icons.verified_rounded : Icons.hourglass_top_rounded, title: status == 'VERIFIED' ? 'You\'re verified' : 'Verification in progress', message: status == 'VERIFIED' ? 'Tier: ${'${k['tier']}'.replaceAll('_', ' ')}' : 'We\'ll notify you when it\'s done — usually within one business day.');
        }
        final latest = k['latest'] as Map<String, dynamic>?;
        return ListView(padding: Space.page.copyWith(bottom: 32), children: [
          if (latest?['rejectionReason'] != null) PesaCard(color: PesaColors.danger.withValues(alpha: .08), child: Text('Previous attempt: ${latest!['rejectionReason']}')),
          const SizedBox(height: Space.md),
          Text('Required by Kenyan law (AML/KYC) to raise your limits. Your ID number is encrypted and only seen by our compliance team.', style: context.text.bodyMedium?.copyWith(color: context.palette.text2)),
          const SizedBox(height: Space.xl),
          DropdownButtonFormField<String>(initialValue: _idType, decoration: const InputDecoration(labelText: 'ID type'), items: [for (final t in (k['acceptedIdTypes'] as List).cast<String>()) DropdownMenuItem(value: t, child: Text(t.replaceAll('_', ' ').toLowerCase().replaceFirstMapped(RegExp('^.'), (m) => m[0]!.toUpperCase())))], onChanged: (v) => setState(() => _idType = v!)),
          const SizedBox(height: Space.md),
          TextField(controller: _idNumber, decoration: const InputDecoration(labelText: 'ID number')),
          const SizedBox(height: Space.md),
          TextField(controller: _name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Full name as on ID')),
          ListTile(contentPadding: EdgeInsets.zero, title: const Text('Date of birth'), subtitle: Text(_dob == null ? 'Select' : DateFormat('d MMMM yyyy').format(_dob!)), trailing: const Icon(Icons.edit_calendar_rounded), onTap: () async {
            final d = await showDatePicker(context: context, firstDate: DateTime(1920), lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)), initialDate: DateTime(1995));
            if (d != null) setState(() => _dob = d);
          }),
          const SizedBox(height: Space.xl),
          LoadingButton(label: 'Submit for verification', loading: _busy, onPressed: () async {
            if (_idNumber.text.trim().length < 5 || _name.text.trim().length < 3 || _dob == null) return showMessage(context, 'Please complete all fields');
            setState(() => _busy = true);
            try {
              await ref.read(_api).post('/v1/me/kyc', body: {'idType': _idType, 'idNumber': _idNumber.text.trim(), 'fullName': _name.text.trim(), 'dateOfBirth': DateFormat('yyyy-MM-dd').format(_dob!)});
              ref.invalidate(_kycProvider);
              await ref.read(authControllerProvider.notifier).refreshUser();
            } catch (e) {
              if (context.mounted) showError(context, e);
            } finally {
              if (mounted) setState(() => _busy = false);
            }
          }),
        ]);
      }),
    );
  }
}

// ------------------------------------------------------------------ linked accounts
class LinkedAccountsScreen extends ConsumerWidget {
  const LinkedAccountsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider);
    void refresh() { ref.invalidate(accountsProvider); ref.invalidate(dashboardProvider); }
    return Scaffold(
      appBar: AppBar(title: const Text('Linked accounts')),
      body: AsyncView(value: accounts, onRetry: refresh, data: (list) => RefreshableList(onRefresh: () async => refresh(), children: [
        Text('Verified balances come directly from your provider. Manual accounts show what you enter and are labelled as such.', style: context.text.bodySmall?.copyWith(color: context.palette.text2)),
        const SizedBox(height: Space.md),
        for (final a in list) Padding(padding: const EdgeInsets.only(bottom: Space.md), child: PesaCard(child: Row(children: [
          Icon(a.kind == 'MOBILE_MONEY' ? Icons.phone_android_rounded : a.kind == 'CASH' ? Icons.payments_rounded : Icons.account_balance_rounded),
          const SizedBox(width: Space.md),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(a.displayName, style: context.text.titleSmall),
            Text('${a.maskedIdentifier ?? ''} ${a.balanceSource == 'PROVIDER_VERIFIED' ? '· verified' : a.balanceSource == 'MANUAL' ? '· manual' : ''}${a.balanceAsOf != null ? ' · ${DateFormat('d MMM HH:mm').format(a.balanceAsOf!.toLocal())}' : ''}', style: context.text.bodySmall?.copyWith(color: context.palette.text3)),
          ])),
          if (a.balance != null) MoneyText(a.balance!, compact: true),
          PopupMenuButton<String>(onSelected: (op) async {
            try {
              final api = ref.read(_api);
              if (op == 'refresh') await api.post('/v1/accounts/${a.id}/refresh');
              if (op == 'unlink') await api.delete('/v1/accounts/${a.id}');
              if (op == 'edit' && context.mounted) {
                final ctl = TextEditingController(text: a.balance?.amount);
                final v = await showDialog<String>(context: context, builder: (c) => AlertDialog(title: const Text('Update balance'), content: TextField(controller: ctl, keyboardType: const TextInputType.numberWithOptions(decimal: true)), actions: [FilledButton(onPressed: () => Navigator.pop(c, ctl.text), child: const Text('Save'))]));
                final n = v == null ? null : Money.normalizeInput(v, a.currency);
                if (n != null) await api.patch('/v1/accounts/${a.id}', body: {'balance': n});
              }
              refresh();
            } catch (e) {
              if (context.mounted) showError(context, e);
            }
          }, itemBuilder: (_) => [
            if (a.provider != 'manual') const PopupMenuItem(value: 'refresh', child: Text('Refresh balance')),
            if (a.provider == 'manual') const PopupMenuItem(value: 'edit', child: Text('Update balance')),
            const PopupMenuItem(value: 'unlink', child: Text('Remove')),
          ]),
        ]))),
        FilledButton.icon(onPressed: () => _link(context, ref), icon: const Icon(Icons.link_rounded), label: const Text('Link an account')),
        const SizedBox(height: Space.md),
        OutlinedButton.icon(onPressed: () => _manual(context, ref), icon: const Icon(Icons.edit_note_rounded), label: const Text('Track an account manually')),
      ])),
    );
  }

  Future<void> _link(BuildContext context, WidgetRef ref) async {
    try {
      final inst = ((await ref.read(_api).get('/v1/accounts/institutions'))['items'] as List).cast<Json>();
      if (!context.mounted) return;
      if (inst.isEmpty) return showMessage(context, 'Account linking is coming soon.');
      final pick = await showModalBottomSheet<String>(context: context, builder: (c) => ListView(shrinkWrap: true, children: [
        const ListTile(title: Text('Choose your provider'), subtitle: Text('You\'ll approve access on the provider\'s secure page.')),
        for (final i in inst) ListTile(leading: Icon(i['kind'] == 'BANK' ? Icons.account_balance_rounded : Icons.phone_android_rounded), title: Text('${i['name']}'), onTap: () => Navigator.pop(c, '${i['code']}')),
      ]));
      if (pick == null) return;
      await ref.read(_api).post('/v1/accounts/link', body: {'institution': pick});
      ref.invalidate(accountsProvider);
      ref.invalidate(dashboardProvider);
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  Future<void> _manual(BuildContext context, WidgetRef ref) async {
    final name = TextEditingController();
    final balance = TextEditingController();
    var kind = 'CASH';
    final ok = await showModalBottomSheet<bool>(context: context, isScrollControlled: true, builder: (c) => StatefulBuilder(builder: (c, set) => Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.viewInsetsOf(c).bottom),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Manual account', style: c.text.titleLarge),
        const SizedBox(height: Space.md),
        DropdownButtonFormField<String>(initialValue: kind, items: const [DropdownMenuItem(value: 'CASH', child: Text('Cash')), DropdownMenuItem(value: 'SACCO', child: Text('SACCO / chama')), DropdownMenuItem(value: 'BANK', child: Text('Bank')), DropdownMenuItem(value: 'MOBILE_MONEY', child: Text('Mobile money')), DropdownMenuItem(value: 'OTHER', child: Text('Other'))], onChanged: (v) => set(() => kind = v!)),
        const SizedBox(height: Space.md),
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
        const SizedBox(height: Space.md),
        TextField(controller: balance, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Current balance (optional)')),
        const SizedBox(height: Space.lg),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Add')),
      ]),
    )));
    if (ok != true || name.text.trim().isEmpty) return;
    try {
      final currency = ref.read(currentUserProvider)?.currency ?? 'KES';
      await ref.read(_api).post('/v1/accounts/manual', body: {'kind': kind, 'displayName': name.text.trim(), 'balance': ?Money.normalizeInput(balance.text, currency)});
      ref.invalidate(accountsProvider);
      ref.invalidate(dashboardProvider);
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }
}

// ------------------------------------------------------------------ security
class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({super.key});
  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen> {
  bool? _bio;
  bool _bioAvailable = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final enabled = await ref.read(secureStoreProvider).biometricEnabled;
      final available = await ref.read(biometricServiceProvider).isAvailable();
      if (mounted) setState(() { _bio = enabled; _bioAvailable = available; });
    });
  }

  Future<void> _changePin() async {
    final cur = TextEditingController();
    final next = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      title: const Text('Change PIN'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: cur, obscureText: true, keyboardType: TextInputType.number, maxLength: 6, decoration: const InputDecoration(labelText: 'Current PIN')),
        TextField(controller: next, obscureText: true, keyboardType: TextInputType.number, maxLength: 6, decoration: const InputDecoration(labelText: 'New PIN')),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Change'))],
    ));
    if (ok != true) return;
    try {
      await ref.read(authRepositoryProvider).changePin(cur.text, next.text);
      if (mounted) showMessage(context, 'PIN changed');
    } catch (e) {
      if (!mounted) return;
      showError(context, e);
      if (e is ApiException && e.status == 423) await _resetPin();
    }
  }

  Future<void> _resetPin() async {
    final repo = ref.read(authRepositoryProvider);
    try {
      await repo.requestPinReset();
      if (!mounted) return;
      final code = TextEditingController();
      final pass = TextEditingController();
      final pin = TextEditingController();
      final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
        title: const Text('Reset PIN'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('We sent a code to your phone.'),
          TextField(controller: code, keyboardType: TextInputType.number, maxLength: 6, decoration: const InputDecoration(labelText: 'SMS code')),
          TextField(controller: pass, obscureText: true, decoration: const InputDecoration(labelText: 'Your password')),
          TextField(controller: pin, obscureText: true, keyboardType: TextInputType.number, maxLength: 6, decoration: const InputDecoration(labelText: 'New PIN')),
        ])),
        actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Reset'))],
      ));
      if (ok != true) return;
      await repo.resetPin(code.text, pass.text, pin.text);
      if (mounted) showMessage(context, 'PIN reset');
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _changePassword() async {
    final cur = TextEditingController();
    final next = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      title: const Text('Change password'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [PasswordField(controller: cur, label: 'Current password'), const SizedBox(height: 8), PasswordField(controller: next, label: 'New password', newPassword: true)]),
      actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Change'))],
    ));
    if (ok != true) return;
    final err = validateNewPassword(next.text);
    if (err != null) { if (mounted) showMessage(context, err); return; }
    try {
      await ref.read(authRepositoryProvider).changePassword(cur.text, next.text);
      if (mounted) showMessage(context, 'Password changed. Other devices were signed out.');
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Security')),
        body: ListView(children: [
          ListTile(leading: const Icon(Icons.pin_rounded), title: const Text('Change transaction PIN'), onTap: _changePin),
          ListTile(leading: const Icon(Icons.lock_reset_rounded), title: const Text('Forgot PIN'), onTap: _resetPin),
          ListTile(leading: const Icon(Icons.password_rounded), title: const Text('Change password'), onTap: _changePassword),
          if (_bioAvailable) SwitchListTile(
            secondary: const Icon(Icons.fingerprint_rounded),
            title: const Text('Unlock with biometrics'),
            subtitle: const Text('Payments still require your PIN.'),
            value: _bio ?? false,
            onChanged: (v) async {
              if (v && !await ref.read(biometricServiceProvider).authenticate('Confirm to enable biometric unlock')) return;
              await ref.read(secureStoreProvider).setBiometricEnabled(v);
              try { await ref.read(_api).patch('/v1/me/devices/current', body: {'biometricEnabled': v}); } catch (_) {}
              setState(() => _bio = v);
            },
          ),
          const Divider(),
          ListTile(leading: const Icon(Icons.logout_rounded, color: PesaColors.danger), title: const Text('Sign out of all devices'), onTap: () async {
            final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: const Text('Sign out everywhere?'), content: const Text('You will need to sign in again on every device.'), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Sign out'))]));
            if (ok == true) await ref.read(authControllerProvider.notifier).logout(everywhere: true);
          }),
        ]),
      );
}

final _devicesProvider = FutureProvider.autoDispose((ref) async => ((await ref.watch(_api).get('/v1/me/devices'))['items'] as List).cast<Json>());
final _sessionsProvider = FutureProvider.autoDispose((ref) async => ((await ref.watch(_api).get('/v1/me/sessions'))['items'] as List).cast<Json>());

class DevicesScreen extends ConsumerWidget {
  const DevicesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(_devicesProvider);
    final sessions = ref.watch(_sessionsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Devices & sessions')),
      body: RefreshableList(onRefresh: () async { ref.invalidate(_devicesProvider); ref.invalidate(_sessionsProvider); }, children: [
        Text('If you don\'t recognise a device, remove it and change your password.', style: context.text.bodySmall?.copyWith(color: context.palette.text2)),
        const SectionHeader('Trusted devices'),
        AsyncView(value: devices, data: (l) => Column(children: [
          for (final d in l) ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(d['platform'] == 'ios' ? Icons.phone_iphone_rounded : Icons.phone_android_rounded),
            title: Text('${d['name']}${d['current'] == true ? ' (this device)' : ''}'),
            subtitle: Text('Last active ${d['lastSeenAt'] == null ? '—' : DateFormat('d MMM, HH:mm').format(DateTime.parse('${d['lastSeenAt']}').toLocal())}'),
            trailing: d['current'] == true ? null : IconButton(tooltip: 'Remove device', icon: const Icon(Icons.delete_outline_rounded), onPressed: () async { await ref.read(_api).delete('/v1/me/devices/${d['id']}'); ref.invalidate(_devicesProvider); ref.invalidate(_sessionsProvider); }),
          ),
        ])),
        const SectionHeader('Active sessions'),
        AsyncView(value: sessions, data: (l) => Column(children: [
          for (final s in l) ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.key_rounded),
            title: Text('${s['device']}${s['current'] == true ? ' (current)' : ''}'),
            subtitle: Text('Signed in ${DateFormat('d MMM yyyy').format(DateTime.parse('${s['createdAt']}').toLocal())}'),
            trailing: s['current'] == true ? null : TextButton(onPressed: () async { await ref.read(_api).delete('/v1/me/sessions/${s['id']}'); ref.invalidate(_sessionsProvider); }, child: const Text('Sign out')),
          ),
        ])),
      ]),
    );
  }
}

// ------------------------------------------------------------------ notification settings
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(authControllerProvider);
    final prefs = s is Authenticated ? (s.profile?.notificationPreferences ?? const {}) : const <String, dynamic>{};
    Future<void> set(String k, bool v) async {
      try {
        await ref.read(_api).patch('/v1/me/notification-preferences', body: {k: v});
        await ref.read(authControllerProvider.notifier).refreshUser();
      } catch (e) {
        if (context.mounted) showError(context, e);
      }
    }
    Widget sw(String k, String t, String sub, {bool def = true}) => SwitchListTile(title: Text(t), subtitle: Text(sub), value: prefs[k] as bool? ?? def, onChanged: (v) => set(k, v));
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(children: [
        sw('push', 'Push notifications', 'Alerts on this phone'),
        sw('email', 'Email', 'Statements and important updates'),
        const Divider(),
        sw('transactions', 'Payments', 'Confirmations and failures'),
        sw('savings', 'Savings reminders', 'Nudges for your goals'),
        sw('budgets', 'Budget alerts', 'When you near or pass a limit'),
        sw('promotions', 'Offers & promotions', 'Rewards, cashback and partner deals', def: false),
        const ListTile(leading: Icon(Icons.shield_rounded), title: Text('Security alerts'), subtitle: Text('Always on — we\'ll always tell you about sign-ins and account changes.')),
      ]),
    );
  }
}

// ------------------------------------------------------------------ privacy & data
class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(authControllerProvider);
    if (s is! Authenticated) return const SizedBox.shrink();
    final c = s.user.consents;
    final privacy = s.profile?.privacy ?? const {};
    Future<void> set(Map<String, bool> body) async {
      try {
        await ref.read(_api).patch('/v1/me/privacy', body: body);
        await ref.read(authControllerProvider.notifier).refreshUser();
        ref.invalidate(dashboardProvider);
      } catch (e) {
        if (context.mounted) showError(context, e);
      }
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & data')),
      body: ListView(children: [
        SwitchListTile(title: const Text('Hide balances on home'), subtitle: const Text('Show •••• until you tap the eye icon'), value: privacy['hideBalances'] as bool? ?? false, onChanged: (v) => set({'hideBalances': v})),
        SwitchListTile(title: const Text('Smart insights'), subtitle: const Text('Analyse your spending inside Pesa to give tips'), value: c.aiInsights, onChanged: (v) => set({'aiInsights': v})),
        SwitchListTile(title: const Text('AI-written summaries'), subtitle: const Text('Send category totals only (no names, numbers or references) to our AI provider to write your monthly summary'), value: c.externalAiProcessing, onChanged: (v) => set({'externalAiProcessing': v})),
        SwitchListTile(title: const Text('Marketing'), subtitle: const Text('Offers and product news'), value: c.marketing, onChanged: (v) => set({'marketing': v})),
        SwitchListTile(title: const Text('Product analytics'), subtitle: const Text('Help us improve the app with anonymous usage data'), value: privacy['analyticsOptIn'] as bool? ?? false, onChanged: (v) => set({'analyticsOptIn': v})),
        const Divider(),
        ListTile(leading: const Icon(Icons.download_rounded), title: const Text('Download my data'), subtitle: const Text('Kenya Data Protection Act, s.38'), onTap: () async {
          try {
            final data = await ref.read(_api).get('/v1/me/export');
            if (context.mounted) showDialog<void>(context: context, builder: (c) => AlertDialog(title: const Text('Your data'), content: SingleChildScrollView(child: SelectableText(const JsonEncoder.withIndent('  ').convert(data))), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Close'))]));
          } catch (e) {
            if (context.mounted) showError(context, e);
          }
        }),
        ListTile(leading: const Icon(Icons.policy_outlined), title: const Text('Privacy policy'), onTap: () => launchUrl(Uri.parse('https://pesa.africa/privacy'))),
        ListTile(leading: const Icon(Icons.delete_forever_rounded, color: PesaColors.danger), title: const Text('Close my account'), onTap: () => context.push('/profile/close')),
      ]),
    );
  }
}

class CloseAccountScreen extends ConsumerStatefulWidget {
  const CloseAccountScreen({super.key});
  @override
  ConsumerState<CloseAccountScreen> createState() => _CloseAccountScreenState();
}

class _CloseAccountScreenState extends ConsumerState<CloseAccountScreen> {
  final _password = TextEditingController();
  final _reason = TextEditingController();
  bool _busy = false;
  @override
  void dispose() {
    _password.dispose();
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Close account')),
        body: ListView(padding: Space.page, children: [
          Text('Closing your account removes your personal details from Pesa. By law we keep transaction records for 7 years (anti-money-laundering rules) in a form that no longer identifies you directly.', style: context.text.bodyMedium),
          const SizedBox(height: Space.lg),
          TextField(controller: _reason, decoration: const InputDecoration(labelText: 'Why are you leaving? (optional)')),
          const SizedBox(height: Space.md),
          PasswordField(controller: _password, label: 'Confirm with your password'),
          const SizedBox(height: Space.xl),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: PesaColors.danger),
            onPressed: _busy ? null : () async {
              setState(() => _busy = true);
              try {
                await ref.read(_api).post('/v1/me/close', body: {'password': _password.text, if (_reason.text.trim().isNotEmpty) 'reason': _reason.text.trim()});
                await ref.read(authControllerProvider.notifier).logout();
              } catch (e) {
                if (context.mounted) showError(context, e);
              } finally {
                if (mounted) setState(() => _busy = false);
              }
            },
            child: const Text('Close my account'),
          ),
        ]),
      );
}

// ------------------------------------------------------------------ limits
final _limitsProvider = FutureProvider.autoDispose<Json>((ref) => ref.watch(_api).get('/v1/me/limits'));

class LimitsScreen extends ConsumerWidget {
  const LimitsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = ref.watch(_limitsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Transaction limits')),
      body: AsyncView(value: l, onRetry: () => ref.invalidate(_limitsProvider), data: (d) {
        final eff = d['effective'] as Json;
        final reg = d['regulatory'] as Json;
        final currency = (eff['perTransaction'] as Json)['currency'] as String;
        Future<void> edit(String key, String label) async {
          final ctl = TextEditingController();
          final v = await showDialog<String?>(context: context, builder: (c) => AlertDialog(title: Text('Set your $label limit'), content: TextField(controller: ctl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(prefixText: '${Money.symbols[currency]} ', helperText: 'Max ${Money.fromJson(reg[key] as Json).format(compact: true)}')), actions: [TextButton(onPressed: () => Navigator.pop(c, ''), child: const Text('Use maximum')), FilledButton(onPressed: () => Navigator.pop(c, ctl.text), child: const Text('Save'))]));
          if (v == null) return;
          try {
            final custom = d['custom'] as Json;
            await ref.read(_api).put('/v1/me/limits', body: {
              'perTransaction': key == 'perTransaction' ? (v.isEmpty ? null : Money.normalizeInput(v, currency)) : (custom['perTransaction'] as Json?)?['amount'],
              'daily': key == 'daily' ? (v.isEmpty ? null : Money.normalizeInput(v, currency)) : (custom['daily'] as Json?)?['amount'],
            });
            ref.invalidate(_limitsProvider);
          } catch (e) {
            if (context.mounted) showError(context, e);
          }
        }
        return ListView(padding: Space.page, children: [
          Text('Your verification level: ${'${d['kycTier']}'.replaceAll('_', ' ')}. Lower limits add protection if your phone is lost.', style: context.text.bodyMedium?.copyWith(color: context.palette.text2)),
          const SizedBox(height: Space.lg),
          ListTile(contentPadding: EdgeInsets.zero, title: const Text('Per transaction'), subtitle: Text('Maximum ${Money.fromJson(reg['perTransaction'] as Json).format(compact: true)}'), trailing: Text(Money.fromJson(eff['perTransaction'] as Json).format(compact: true), style: context.text.titleSmall), onTap: () => edit('perTransaction', 'per-transaction')),
          ListTile(contentPadding: EdgeInsets.zero, title: const Text('Daily'), subtitle: Text('Maximum ${Money.fromJson(reg['daily'] as Json).format(compact: true)}'), trailing: Text(Money.fromJson(eff['daily'] as Json).format(compact: true), style: context.text.titleSmall), onTap: () => edit('daily', 'daily')),
          ListTile(contentPadding: EdgeInsets.zero, title: const Text('Monthly'), subtitle: const Text('Set by regulation'), trailing: Text(Money.fromJson(eff['monthly'] as Json).format(compact: true), style: context.text.titleSmall)),
          const SizedBox(height: Space.lg),
          OutlinedButton(onPressed: () => context.push('/profile/kyc'), child: const Text('Raise my limits')),
        ]);
      }),
    );
  }
}

// ------------------------------------------------------------------ appearance
class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appSettingsProvider);
    final c = ref.read(appSettingsProvider.notifier);
    final current = s.locale?.languageCode ?? Localizations.localeOf(context).languageCode;
    return Scaffold(
      appBar: AppBar(title: const Text('Language & theme')),
      body: ListView(children: [
        const _Group('Language'),
        RadioGroup<String>(groupValue: current, onChanged: (v) => c.setLocale(v!), child: const Column(children: [
          RadioListTile(value: 'en', title: Text('English')),
          RadioListTile(value: 'sw', title: Text('Kiswahili')),
        ])),
        const _Group('Theme'),
        RadioGroup<ThemeMode>(groupValue: s.themeMode, onChanged: (v) => c.setTheme(v!), child: const Column(children: [
          RadioListTile(value: ThemeMode.system, title: Text('Match system')),
          RadioListTile(value: ThemeMode.light, title: Text('Light')),
          RadioListTile(value: ThemeMode.dark, title: Text('Dark')),
        ])),
      ]),
    );
  }
}

// ------------------------------------------------------------------ support
final _ticketsProvider = FutureProvider.autoDispose((ref) async => ((await ref.watch(_api).get('/v1/support/tickets'))['items'] as List).cast<Json>());
final _ticketProvider = FutureProvider.autoDispose.family<Json, String>((ref, id) => ref.watch(_api).get('/v1/support/tickets/$id'));

class SupportScreen extends ConsumerWidget {
  const SupportScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(_ticketsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Help & support')),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => context.push('/profile/support/new'), icon: const Icon(Icons.add_comment_rounded), label: const Text('New request')),
      body: AsyncView(value: t, onRetry: () => ref.invalidate(_ticketsProvider), data: (list) => RefreshableList(onRefresh: () async => ref.invalidate(_ticketsProvider), children: [
        PesaCard(color: context.palette.surface2, child: const Text('Pesa staff will never ask for your PIN, password or verification codes.')),
        const SizedBox(height: Space.md),
        if (list.isEmpty) const EmptyState(icon: Icons.support_agent_rounded, title: 'No requests yet', message: 'Questions about a payment? Open a request and we\'ll help.'),
        for (final x in list) ListTile(contentPadding: EdgeInsets.zero, title: Text('${x['subject']}'), subtitle: Text('${x['reference']} · ${'${x['status']}'.replaceAll('_', ' ').toLowerCase()}'), trailing: const Icon(Icons.chevron_right_rounded), onTap: () => context.push('/profile/support/${x['id']}')),
      ])),
    );
  }
}

class NewTicketScreen extends ConsumerStatefulWidget {
  const NewTicketScreen({super.key, this.transactionId, this.subject});
  final String? transactionId, subject;
  @override
  ConsumerState<NewTicketScreen> createState() => _NewTicketScreenState();
}

class _NewTicketScreenState extends ConsumerState<NewTicketScreen> {
  late final _subject = TextEditingController(text: widget.subject);
  final _message = TextEditingController();
  late String _category = widget.transactionId != null ? 'PAYMENT' : 'OTHER';
  bool _busy = false;
  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('New request')),
        body: ListView(padding: Space.page, children: [
          DropdownButtonFormField<String>(initialValue: _category, decoration: const InputDecoration(labelText: 'Topic'), items: const [
            DropdownMenuItem(value: 'PAYMENT', child: Text('A payment')), DropdownMenuItem(value: 'ACCOUNT', child: Text('My account')), DropdownMenuItem(value: 'KYC', child: Text('Identity verification')),
            DropdownMenuItem(value: 'CARD', child: Text('Cards')), DropdownMenuItem(value: 'SECURITY', child: Text('Security concern')), DropdownMenuItem(value: 'FEEDBACK', child: Text('Feedback')), DropdownMenuItem(value: 'OTHER', child: Text('Something else')),
          ], onChanged: (v) => setState(() => _category = v!)),
          const SizedBox(height: Space.md),
          TextField(controller: _subject, maxLength: 140, decoration: const InputDecoration(labelText: 'Subject')),
          TextField(controller: _message, maxLines: 6, maxLength: 4000, decoration: const InputDecoration(labelText: 'How can we help?', alignLabelWithHint: true)),
          const SizedBox(height: Space.md),
          LoadingButton(label: 'Send', loading: _busy, onPressed: () async {
            if (_subject.text.trim().length < 3 || _message.text.trim().length < 5) return showMessage(context, 'Please add a subject and a short description');
            setState(() => _busy = true);
            try {
              await ref.read(_api).post('/v1/support/tickets', body: {'category': _category, 'subject': _subject.text.trim(), 'message': _message.text.trim(), 'transactionId': ?widget.transactionId});
              ref.invalidate(_ticketsProvider);
              if (context.mounted) { showMessage(context, 'Request sent. We\'ll reply here and notify you.'); context.pop(); }
            } catch (e) {
              if (context.mounted) showError(context, e);
            } finally {
              if (mounted) setState(() => _busy = false);
            }
          }),
        ]),
      );
}

class TicketScreen extends ConsumerStatefulWidget {
  const TicketScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends ConsumerState<TicketScreen> {
  final _reply = TextEditingController();
  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(_ticketProvider(widget.id));
    return Scaffold(
      appBar: AppBar(title: Text(t.value?['reference'] as String? ?? 'Request')),
      body: AsyncView(value: t, onRetry: () => ref.invalidate(_ticketProvider(widget.id)), data: (x) => Column(children: [
        Expanded(child: ListView(padding: Space.page, children: [
          Text('${x['subject']}', style: context.text.titleMedium),
          const SizedBox(height: Space.md),
          for (final m in (x['messages'] as List).cast<Json>())
            Align(
              alignment: m['authorType'] == 'USER' ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12), constraints: const BoxConstraints(maxWidth: 300),
                decoration: BoxDecoration(color: m['authorType'] == 'USER' ? context.colors.primaryContainer : context.palette.surface2, borderRadius: BorderRadius.circular(Radii.md)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${m['body']}'), Text(DateFormat('d MMM HH:mm').format(DateTime.parse('${m['createdAt']}').toLocal()), style: context.text.labelSmall?.copyWith(color: context.palette.text3))]),
              ),
            ),
        ])),
        if (x['status'] != 'CLOSED') SafeArea(child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
          Expanded(child: TextField(controller: _reply, decoration: const InputDecoration(hintText: 'Reply…'))),
          IconButton.filled(tooltip: 'Send', onPressed: () async {
            if (_reply.text.trim().isEmpty) return;
            try {
              await ref.read(_api).post('/v1/support/tickets/${widget.id}/messages', body: {'message': _reply.text.trim()});
              _reply.clear();
              ref.invalidate(_ticketProvider(widget.id));
            } catch (e) {
              if (context.mounted) showError(context, e);
            }
          }, icon: const Icon(Icons.send_rounded)),
        ]))),
      ])),
    );
  }
}
