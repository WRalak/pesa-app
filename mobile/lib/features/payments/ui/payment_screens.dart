import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../activity/data/activity_repository.dart';
import '../../activity/data/models.dart';
import '../../activity/ui/txn_tile.dart';
import '../../auth/data/auth_controller.dart';
import '../../auth/ui/auth_widgets.dart';
import '../../home/data/dashboard.dart';
import '../data/payments_repository.dart';

// ------------------------------------------------------------------ hub
class PayHubScreen extends ConsumerWidget {
  const PayHubScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opts = ref.watch(paymentOptionsProvider);
    final items = [
      ('send', Icons.north_east_rounded, 'Send money', 'To any M-Pesa number', PesaColors.emerald500),
      ('paybill', Icons.receipt_long_rounded, 'Paybill', 'Business number + account', PesaColors.gold500),
      ('till', Icons.storefront_rounded, 'Buy goods', 'Pay a till number', PesaColors.sky500),
      ('airtime', Icons.phone_android_rounded, 'Airtime', 'For you or someone else', PesaColors.coral500),
      ('deposit', Icons.add_rounded, 'Add money', 'From your M-Pesa via prompt', PesaColors.violet500),
      ('receive', Icons.qr_code_2_rounded, 'Receive', 'Share your QR or number', const Color(0xFF14B8A6)),
    ];
    const typeFor = {'send': 'SEND_MONEY', 'paybill': 'PAYBILL', 'till': 'BUY_GOODS', 'airtime': 'AIRTIME', 'deposit': 'DEPOSIT'};
    final available = opts.value?.availableTypes;
    // Only offer what a live provider can process (production availability
    // depends on partner agreements); Receive needs no provider.
    final shown = available == null ? items : items.where((i) => i.$1 == 'receive' || available.contains(typeFor[i.$1])).toList();
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).navPay)),
      body: ListView(padding: Space.page.copyWith(bottom: 32), children: [
        if (opts.value?.sandbox ?? false) Padding(padding: const EdgeInsets.only(bottom: Space.md), child: PesaCard(color: PesaColors.gold500.withValues(alpha: .12), child: Text(AppLocalizations.of(context).sandboxNotice))),
        GridView.count(
          crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: Space.md, crossAxisSpacing: Space.md, childAspectRatio: 1.25,
          children: [
            for (final (key, icon, title, sub, color) in shown)
              PesaCard(
                onTap: () => context.push('/pay/$key'),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Container(width: 42, height: 42, decoration: BoxDecoration(color: color.withValues(alpha: .14), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color)),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: context.text.titleSmall), Text(sub, style: context.text.bodySmall?.copyWith(color: context.palette.text3), maxLines: 1, overflow: TextOverflow.ellipsis)]),
                ]),
              ),
          ],
        ),
        if (available == null || available.contains('UTILITY')) const SectionHeader('Utilities & bills'),
        if (available == null || available.contains('UTILITY')) AsyncView(
          value: opts,
          onRetry: () => ref.invalidate(paymentOptionsProvider),
          data: (o) => PesaCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              for (final u in o.utilities)
                ListTile(
                  leading: const Icon(Icons.bolt_rounded),
                  title: Text(u.name),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/pay/utility?code=${u.code}&name=${Uri.encodeComponent(u.name)}'),
                ),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ------------------------------------------------------------------ form
/// One adaptive form for all payment types; fields depend on [kind].
class PaymentFormScreen extends ConsumerStatefulWidget {
  const PaymentFormScreen({super.key, required this.kind, this.utilityCode, this.utilityName});
  final String kind;
  final String? utilityCode, utilityName;
  @override
  ConsumerState<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends ConsumerState<PaymentFormScreen> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _phone = TextEditingController();
  final _name = TextEditingController();
  final _paybill = TextEditingController();
  final _account = TextEditingController();
  final _till = TextEditingController();
  late final PaymentDraft _draft;
  Quote? _quote;
  Timer? _debounce;
  bool _forSelf = true;

  static const _types = {'send': 'SEND_MONEY', 'paybill': 'PAYBILL', 'till': 'BUY_GOODS', 'airtime': 'AIRTIME', 'utility': 'UTILITY', 'deposit': 'DEPOSIT'};
  static const _titles = {'send': 'Send money', 'paybill': 'Pay bill', 'till': 'Buy goods', 'airtime': 'Buy airtime', 'utility': 'Pay utility', 'deposit': 'Add money'};

  @override
  void initState() {
    super.initState();
    _draft = PaymentDraft(type: _types[widget.kind] ?? 'SEND_MONEY', utilityCode: widget.utilityCode);
    _amount.addListener(_requote);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final c in [_amount, _phone, _name, _paybill, _account, _till]) {
      c.dispose();
    }
    super.dispose();
  }

  String get _currency => ref.read(currentUserProvider)?.currency ?? 'KES';

  void _requote() {
    _debounce?.cancel();
    final amt = Money.normalizeInput(_amount.text, _currency);
    if (amt == null) return setState(() => _quote = null);
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        final q = await ref.read(paymentsRepositoryProvider).quote(_draft.type, amt);
        if (mounted) setState(() => _quote = q);
      } catch (_) {/* fee preview is best-effort */}
    });
  }

  void _continue() {
    if (!_form.currentState!.validate()) return;
    _draft
      ..amount = Money.normalizeInput(_amount.text, _currency)!
      ..recipientPhone = switch (widget.kind) { 'send' => PhoneField.toE164(_phone.text), 'airtime' => _forSelf ? null : PhoneField.toE164(_phone.text), _ => null }
      ..recipientName = _name.text.trim().isEmpty ? null : _name.text.trim()
      ..paybillNumber = widget.kind == 'paybill' ? _paybill.text.trim() : null
      ..accountNumber = (widget.kind == 'paybill' || widget.kind == 'utility') ? _account.text.trim() : null
      ..tillNumber = widget.kind == 'till' ? _till.text.trim() : null;
    showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: (_) => ConfirmPaymentSheet(draft: _draft, quote: _quote, title: _titles[widget.kind]!, subtitle: _summary()));
  }

  String _summary() => switch (widget.kind) {
        'send' => 'To ${_name.text.trim().isEmpty ? PhoneField.toE164(_phone.text) : '${_name.text.trim()} · ${PhoneField.toE164(_phone.text)}'}',
        'paybill' => 'Paybill ${_paybill.text} · Acc ${_account.text}',
        'till' => 'Till ${_till.text}${_name.text.isNotEmpty ? ' · ${_name.text}' : ''}',
        'airtime' => _forSelf ? 'Airtime for your number' : 'Airtime for ${PhoneField.toE164(_phone.text)}',
        'utility' => '${widget.utilityName ?? 'Utility'} · ${_account.text}',
        'deposit' => 'An M-Pesa prompt will appear on your phone',
        _ => '',
      };

  @override
  Widget build(BuildContext context) {
    if (!_titles.containsKey(widget.kind)) {
      return Scaffold(appBar: AppBar(), body: const EmptyState(icon: Icons.link_off_rounded, title: 'Page not found'));
    }
    final available = ref.watch(paymentOptionsProvider).value?.availableTypes;
    if (available != null && !available.contains(_draft.type)) {
      return Scaffold(
        appBar: AppBar(title: Text(_titles[widget.kind] ?? 'Pay')),
        body: EmptyState(icon: Icons.schedule_rounded, title: 'Not available yet', message: 'This payment type isn\'t available in your area right now. We\'ll let you know when it is.', action: OutlinedButton(onPressed: () => context.pop(), child: const Text('Back'))),
      );
    }
    final digits = Money.minorUnits[_currency] ?? 2;
    final shortcode = [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(7)];
    return Scaffold(
      appBar: AppBar(title: Text(widget.kind == 'utility' ? (widget.utilityName ?? 'Pay utility') : _titles[widget.kind]!)),
      body: Form(
        key: _form,
        child: ListView(padding: Space.page.copyWith(bottom: 32), children: [
          if (widget.kind == 'send') ...[
            PhoneField(controller: _phone, label: 'Recipient phone number', autofocus: true),
            const SizedBox(height: Space.lg),
            TextFormField(controller: _name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Recipient name (optional)')),
          ],
          if (widget.kind == 'paybill') ...[
            TextFormField(controller: _paybill, autofocus: true, keyboardType: TextInputType.number, inputFormatters: shortcode, decoration: const InputDecoration(labelText: 'Business number'), validator: (v) => RegExp(r'^\d{5,7}$').hasMatch(v ?? '') ? null : 'Enter a 5–7 digit business number'),
            const SizedBox(height: Space.lg),
            TextFormField(controller: _account, decoration: const InputDecoration(labelText: 'Account number'), validator: (v) => (v ?? '').trim().isEmpty ? 'Enter the account number' : null),
          ],
          if (widget.kind == 'till') ...[
            TextFormField(controller: _till, autofocus: true, keyboardType: TextInputType.number, inputFormatters: shortcode, decoration: const InputDecoration(labelText: 'Till number'), validator: (v) => RegExp(r'^\d{5,7}$').hasMatch(v ?? '') ? null : 'Enter a 5–7 digit till number'),
            const SizedBox(height: Space.lg),
            TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Merchant name (optional)')),
          ],
          if (widget.kind == 'utility')
            TextFormField(controller: _account, autofocus: true, decoration: const InputDecoration(labelText: 'Meter / account number'), validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null),
          if (widget.kind == 'airtime') ...[
            SegmentedButton<bool>(segments: const [ButtonSegment(value: true, label: Text('My number')), ButtonSegment(value: false, label: Text('Another number'))], selected: {_forSelf}, onSelectionChanged: (s) => setState(() => _forSelf = s.first)),
            if (!_forSelf) ...[const SizedBox(height: Space.lg), PhoneField(controller: _phone, label: 'Phone number')],
          ],
          if (widget.kind == 'deposit')
            PesaCard(color: context.palette.surface2, child: const Text('You will receive an M-Pesa prompt on your phone. Enter your M-Pesa PIN there — Pesa never asks for it.')),
          const SizedBox(height: Space.xl),
          TextFormField(
            controller: _amount,
            keyboardType: TextInputType.numberWithOptions(decimal: digits > 0),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(digits > 0 ? r'[\d.,]' : r'[\d,]'))],
            style: context.text.headlineMedium,
            decoration: InputDecoration(labelText: AppLocalizations.of(context).amount, prefixText: '${Money.symbols[_currency] ?? _currency} '),
            validator: (v) => Money.normalizeInput(v ?? '', _currency) == null ? 'Enter a valid amount' : null,
          ),
          const SizedBox(height: Space.sm),
          if (_quote != null)
            Text(_quote!.fee.isZero ? 'No fee · total ${_quote!.total.format()}' : 'Fee ${_quote!.fee.format()} · total ${_quote!.total.format()}', style: context.text.bodyMedium?.copyWith(color: context.palette.text2)),
          const SizedBox(height: Space.xxl),
          FilledButton(onPressed: _continue, child: Text(AppLocalizations.of(context).continueLabel)),
        ]),
      ),
    );
  }
}

// ------------------------------------------------------------------ confirm + PIN
class ConfirmPaymentSheet extends ConsumerStatefulWidget {
  const ConfirmPaymentSheet({super.key, required this.draft, required this.quote, required this.title, required this.subtitle});
  final PaymentDraft draft;
  final Quote? quote;
  final String title, subtitle;
  @override
  ConsumerState<ConfirmPaymentSheet> createState() => _ConfirmPaymentSheetState();
}

class _ConfirmPaymentSheetState extends ConsumerState<ConfirmPaymentSheet> {
  bool _busy = false;
  String? _error;

  Future<void> _pay(String pin) async {
    setState(() { _busy = true; _error = null; });
    try {
      final (txn, message) = await ref.read(paymentsRepositoryProvider).pay(widget.draft, pin);
      ref.read(txnListProvider.notifier).upsert(txn);
      ref.invalidate(dashboardProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      context.pushReplacement('/pay/status/${txn.id}', extra: message);
    } on ApiException catch (e) {
      // A definitive rejection: the user may edit and retry, so rotate the key.
      if (e.status >= 400 && e.status < 500) widget.draft.renewKey();
      if (e.code == 'POSSIBLE_DUPLICATE' && mounted) {
        final again = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
          title: const Text('Pay again?'),
          content: Text(e.message),
          actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Pay again'))],
        ));
        if (again == true) {
          widget.draft.confirmDuplicate = true;
          return _pay(pin);
        }
      }
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final currency = ref.read(currentUserProvider)?.currency ?? 'KES';
    final amount = Money(amountMinor: 0, currency: currency, amount: widget.draft.amount);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 0, 24, 16 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(l.confirmPayment, style: context.text.titleLarge),
          const SizedBox(height: Space.md),
          Text(amount.format(), style: context.text.displaySmall),
          const SizedBox(height: 4),
          Text(widget.subtitle, textAlign: TextAlign.center, style: context.text.bodyMedium?.copyWith(color: context.palette.text2)),
          if (widget.quote != null && !widget.quote!.fee.isZero) Text('Fee ${widget.quote!.fee.format()} · Total ${widget.quote!.total.format()}', style: context.text.bodySmall),
          const SizedBox(height: Space.lg),
          Text(l.enterPinToPay, style: context.text.titleSmall),
          const SizedBox(height: Space.sm),
          PinPad(onCompleted: _pay, busy: _busy, error: _error),
        ]),
      ),
    );
  }
}

// ------------------------------------------------------------------ live status
/// Shows the provider-confirmed outcome. Updates arrive via Socket.IO; polling
/// is a fallback. The app never decides success itself.
class PaymentStatusScreen extends ConsumerStatefulWidget {
  const PaymentStatusScreen({super.key, required this.id, this.message});
  final String id;
  final String? message;
  @override
  ConsumerState<PaymentStatusScreen> createState() => _PaymentStatusScreenState();
}

class _PaymentStatusScreenState extends ConsumerState<PaymentStatusScreen> {
  Timer? _poll;
  final _started = DateTime.now();

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(const Duration(seconds: 4), (_) {
      final v = ref.read(transactionDetailProvider(widget.id)).value;
      if (v != null && v.$1.isTerminal) return _poll?.cancel();
      ref.invalidate(transactionDetailProvider(widget.id));
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final detail = ref.watch(transactionDetailProvider(widget.id));
    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => context.go('/home'))),
        body: AsyncView(
          value: detail,
          onRetry: () => ref.invalidate(transactionDetailProvider(widget.id)),
          data: (d) {
            final t = d.$1;
            final (icon, color, title) = switch (t.status) {
              'SUCCESSFUL' => (Icons.check_rounded, PesaColors.emerald500, l.paymentSuccess),
              'FAILED' => (Icons.close_rounded, PesaColors.danger, l.paymentFailed),
              'REVERSED' => (Icons.undo_rounded, PesaColors.sky500, 'Payment reversed'),
              _ => (Icons.hourglass_top_rounded, PesaColors.gold500, l.paymentPending),
            };
            final slow = !t.isTerminal && DateTime.now().difference(_started) > const Duration(seconds: 45);
            return ListView(padding: Space.page, children: [
              const SizedBox(height: Space.xxl),
              Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: 96, height: 96,
                  decoration: BoxDecoration(color: color.withValues(alpha: .15), shape: BoxShape.circle),
                  child: t.isTerminal ? Icon(icon, size: 48, color: color) : const Padding(padding: EdgeInsets.all(28), child: CircularProgressIndicator(strokeWidth: 3)),
                ),
              ),
              const SizedBox(height: Space.xl),
              Text(title, textAlign: TextAlign.center, style: context.text.headlineSmall),
              const SizedBox(height: Space.sm),
              Text(t.total.format(), textAlign: TextAlign.center, style: context.text.displaySmall),
              const SizedBox(height: Space.sm),
              Text(t.title, textAlign: TextAlign.center, style: context.text.bodyMedium?.copyWith(color: context.palette.text2)),
              if (!t.isTerminal) ...[
                const SizedBox(height: Space.lg),
                Text(widget.message ?? 'Waiting for confirmation from the provider. This usually takes a few seconds.', textAlign: TextAlign.center, style: context.text.bodyMedium),
              ],
              if (t.status == 'FAILED' && t.statusReason != null) Padding(padding: const EdgeInsets.only(top: Space.md), child: Text(t.statusReason!, textAlign: TextAlign.center, style: context.text.bodyMedium?.copyWith(color: PesaColors.danger))),
              const SizedBox(height: Space.xxl),
              PesaCard(child: Column(children: [
                _row(context, 'Reference', t.reference),
                if (t.externalRef != null) _row(context, 'Provider receipt', t.externalRef!),
                _row(context, 'Fee', t.fee.format()),
                _row(context, 'Status', t.status.toLowerCase()),
              ])),
              const SizedBox(height: Space.xl),
              if (slow) OutlinedButton(onPressed: () async { try { await ref.read(activityRepositoryProvider).refreshStatus(t.id); ref.invalidate(transactionDetailProvider(t.id)); } catch (e) { if (context.mounted) showError(context, e); } }, child: const Text('Check status again')),
              if (t.status == 'SUCCESSFUL') FilledButton.icon(onPressed: () => context.push('/activity/${t.id}'), icon: const Icon(Icons.receipt_rounded), label: const Text('View receipt')),
              const SizedBox(height: Space.md),
              TextButton(onPressed: () => context.go('/home'), child: const Text('Done')),
            ]);
          },
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String k, String v) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [Text(k, style: context.text.bodyMedium?.copyWith(color: context.palette.text2)), const Spacer(), SelectableText(v, style: context.text.bodyMedium?.copyWith(fontWeight: FontWeight.w600))]));
}

// ------------------------------------------------------------------ receive
class ReceiveScreen extends ConsumerWidget {
  const ReceiveScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final auth = ref.watch(authControllerProvider);
    final name = auth is Authenticated ? '${auth.profile?.firstName ?? ''} ${auth.profile?.lastName ?? ''}'.trim() : '';
    final phone = user?.phone ?? '';
    final payload = 'pesa://pay?to=${Uri.encodeComponent(phone)}&name=${Uri.encodeComponent(name)}';
    return Scaffold(
      appBar: AppBar(title: const Text('Receive money')),
      body: ListView(padding: Space.page, children: [
        const SizedBox(height: Space.lg),
        PesaCard(
          padding: const EdgeInsets.all(Space.xxl),
          child: Column(children: [
            Text(name.isEmpty ? 'Your number' : name, style: context.text.titleLarge),
            const SizedBox(height: 4),
            SelectableText(phone, style: context.text.titleMedium?.copyWith(color: context.palette.text2)),
            const SizedBox(height: Space.xl),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(Radii.lg)),
              child: QrImageView(data: payload, size: 210, eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: PesaColors.navy900), dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: PesaColors.navy900), semanticsLabel: 'QR code to pay $phone'),
            ),
            const SizedBox(height: Space.lg),
            Text('People can send money to this number from M-Pesa or by scanning in Pesa.', textAlign: TextAlign.center, style: context.text.bodySmall?.copyWith(color: context.palette.text3)),
          ]),
        ),
        const SizedBox(height: Space.xl),
        FilledButton.icon(onPressed: () => SharePlus.instance.share(ShareParams(text: 'Send me money on M-Pesa: $phone${name.isEmpty ? '' : ' ($name)'}')), icon: const Icon(Icons.share_rounded), label: const Text('Share my details')),
        const SizedBox(height: Space.md),
        OutlinedButton.icon(onPressed: () { Clipboard.setData(ClipboardData(text: phone)); showMessage(context, 'Number copied'); }, icon: const Icon(Icons.copy_rounded), label: const Text('Copy number')),
      ]),
    );
  }
}

/// Small helper used by other screens to show a list of transactions.
class TxnList extends StatelessWidget {
  const TxnList(this.items, {super.key});
  final List<Txn> items;
  @override
  Widget build(BuildContext context) => Column(children: [for (final t in items) TxnTile(t)]);
}
