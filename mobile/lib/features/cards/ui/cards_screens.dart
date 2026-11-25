import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../core/config/env.dart';
import '../../../core/theme/theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/widgets.dart';
import '../../activity/ui/txn_tile.dart';
import '../data/cards.dart';

class CardsScreen extends ConsumerWidget {
  const CardsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref.watch(cardsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Cards')),
      body: AsyncView(value: cards, onRetry: () => ref.invalidate(cardsProvider), data: (v) {
        final (list, issuing) = v;
        return RefreshableList(onRefresh: () async => ref.invalidate(cardsProvider), children: [
          if (list.isEmpty) const EmptyState(icon: Icons.credit_card_rounded, title: 'No cards yet', message: 'Get a virtual card for online payments, or link a card you already have.'),
          for (final c in list) Padding(padding: const EdgeInsets.only(bottom: Space.lg), child: GestureDetector(onTap: () => context.push('/grow/cards/${c.id}', extra: c), child: CardFace(card: c))),
          if (issuing) FilledButton.icon(onPressed: () => _issue(context, ref), icon: const Icon(Icons.add_card_rounded), label: const Text('Get a virtual card')),
          const SizedBox(height: Space.md),
          OutlinedButton.icon(onPressed: () => _link(context, ref), icon: const Icon(Icons.link_rounded), label: const Text('Link an existing card')),
          const SizedBox(height: Space.lg),
          Text('Cards are issued by our licensed partner. Pesa never stores your full card number or CVV.', style: context.text.bodySmall?.copyWith(color: context.palette.text3), textAlign: TextAlign.center),
        ]);
      }),
    );
  }

  Future<void> _issue(BuildContext context, WidgetRef ref) async {
    final pin = await askPin(context, 'Enter your PIN to create a card');
    if (pin == null) return;
    try {
      await ref.read(cardsRepositoryProvider).issue(pin, 'Virtual card');
      ref.invalidate(cardsProvider);
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  /// In production the card form is rendered by the PSP's SDK, which returns a
  /// token; our app never sees the card number. Sandbox uses test tokens.
  Future<void> _link(BuildContext context, WidgetRef ref) async {
    if (Env.isProd) return showMessage(context, 'Card linking opens your bank\'s secure form.');
    final token = await showModalBottomSheet<String>(context: context, builder: (c) => ListView(shrinkWrap: true, children: [
      const ListTile(title: Text('Sandbox test cards'), subtitle: Text('Production uses the card partner\'s secure form.')),
      ListTile(leading: const Icon(Icons.credit_card), title: const Text('Visa ••4242'), onTap: () => Navigator.pop(c, 'tok_sandbox_visa')),
      ListTile(leading: const Icon(Icons.credit_card), title: const Text('Mastercard ••4444'), onTap: () => Navigator.pop(c, 'tok_sandbox_mastercard')),
    ]));
    if (token == null) return;
    try {
      await ref.read(cardsRepositoryProvider).link(token);
      ref.invalidate(cardsProvider);
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }
}

Future<String?> askPin(BuildContext context, String title) => showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (c) => SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(24, 0, 24, 16), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(title, style: c.text.titleMedium),
        const SizedBox(height: Space.md),
        PinPad(onCompleted: (p) => Navigator.pop(c, p)),
      ]))),
    );

class CardFace extends StatelessWidget {
  const CardFace({super.key, required this.card});
  final PaymentCard card;
  @override
  Widget build(BuildContext context) {
    final frozen = card.status == 'FROZEN';
    return AspectRatio(
      aspectRatio: 1.586,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: frozen ? .55 : 1,
        child: Container(
          padding: const EdgeInsets.all(Space.xl),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.xl),
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: card.kind == 'VIRTUAL' ? const [PesaColors.emerald600, PesaColors.navy900] : const [PesaColors.navy700, PesaColors.navy950]),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(card.nickname ?? (card.kind == 'VIRTUAL' ? 'Virtual card' : 'Linked card'), style: context.text.titleSmall?.copyWith(color: Colors.white)),
              const Spacer(),
              if (frozen) const Icon(Icons.ac_unit_rounded, color: Colors.white),
              if (card.sandbox) Container(margin: const EdgeInsets.only(left: 8), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: PesaColors.gold500, borderRadius: BorderRadius.circular(6)), child: const Text('SANDBOX', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: PesaColors.navy900))),
            ]),
            const Spacer(),
            Text('••••  ••••  ••••  ${card.last4}', style: context.text.titleLarge?.copyWith(color: Colors.white, letterSpacing: 2)),
            const SizedBox(height: Space.sm),
            Row(children: [
              Text('EXP ${card.expiry}', style: context.text.bodySmall?.copyWith(color: Colors.white70)),
              const Spacer(),
              Text(card.brand, style: context.text.titleMedium?.copyWith(color: Colors.white, fontStyle: FontStyle.italic, fontWeight: FontWeight.w900)),
            ]),
          ]),
        ),
      ),
    );
  }
}

class CardDetailScreen extends ConsumerStatefulWidget {
  const CardDetailScreen({super.key, required this.card});
  final PaymentCard card;
  @override
  ConsumerState<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends ConsumerState<CardDetailScreen> {
  late PaymentCard _card = widget.card;

  Future<void> _run(Future<PaymentCard> Function() op) async {
    try {
      final c = await op();
      setState(() => _card = c);
      ref.invalidate(cardsProvider);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _limit() async {
    final ctl = TextEditingController(text: _card.controls.perTransaction?.amount);
    final v = await showDialog<String?>(context: context, builder: (c) => AlertDialog(
      title: const Text('Per-transaction limit'),
      content: TextField(controller: ctl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(prefixText: '${Money.symbols[_card.currency]} ', hintText: 'No limit')),
      actions: [TextButton(onPressed: () => Navigator.pop(c, ''), child: const Text('Remove limit')), FilledButton(onPressed: () => Navigator.pop(c, ctl.text), child: const Text('Save'))],
    ));
    if (v == null) return;
    final amount = v.isEmpty ? null : Money.normalizeInput(v, _card.currency);
    if (v.isNotEmpty && amount == null) return;
    await _run(() => ref.read(cardsRepositoryProvider).controls(_card.id, {'perTransaction': amount}));
  }

  @override
  Widget build(BuildContext context) {
    final txs = ref.watch(cardTransactionsProvider(_card.id));
    final c = _card.controls;
    return Scaffold(
      appBar: AppBar(title: Text(_card.nickname ?? 'Card')),
      body: RefreshableList(onRefresh: () async => ref.invalidate(cardTransactionsProvider(_card.id)), children: [
        CardFace(card: _card),
        const SizedBox(height: Space.lg),
        Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: () => _run(() => ref.read(cardsRepositoryProvider).freeze(_card.id, _card.status != 'FROZEN')), icon: Icon(_card.status == 'FROZEN' ? Icons.lock_open_rounded : Icons.ac_unit_rounded), label: Text(_card.status == 'FROZEN' ? 'Unfreeze' : 'Freeze'))),
          if (_card.kind == 'VIRTUAL') ...[
            const SizedBox(width: Space.md),
            Expanded(child: OutlinedButton.icon(onPressed: () async {
              final pin = await askPin(context, 'Enter your PIN to view card details');
              if (pin == null) return;
              try {
                await ref.read(cardsRepositoryProvider).secureDisplay(_card.id, pin);
                if (context.mounted) showMessage(context, 'Card details open in the issuer\'s secure viewer.');
              } catch (e) {
                if (context.mounted) showError(context, e);
              }
            }, icon: const Icon(Icons.visibility_rounded), label: const Text('Show details'))),
          ],
        ]),
        const SectionHeader('Controls'),
        PesaCard(padding: EdgeInsets.zero, child: Column(children: [
          SwitchListTile(title: const Text('Online payments'), value: c.online, onChanged: (v) => _run(() => ref.read(cardsRepositoryProvider).controls(_card.id, {'online': v}))),
          SwitchListTile(title: const Text('International payments'), value: c.international, onChanged: (v) => _run(() => ref.read(cardsRepositoryProvider).controls(_card.id, {'international': v}))),
          SwitchListTile(title: const Text('ATM withdrawals'), value: c.atm, onChanged: (v) => _run(() => ref.read(cardsRepositoryProvider).controls(_card.id, {'atm': v}))),
          ListTile(title: const Text('Per-transaction limit'), subtitle: Text(c.perTransaction?.format() ?? 'No limit'), trailing: const Icon(Icons.chevron_right_rounded), onTap: _limit),
        ])),
        if (!Env.isProd) ...[
          const SizedBox(height: Space.md),
          TextButton.icon(onPressed: () async {
            try {
              final r = await ref.read(cardsRepositoryProvider).simulate(_card.id, '350', 'Java House');
              ref.invalidate(cardTransactionsProvider(_card.id));
              if (context.mounted) showMessage(context, 'Sandbox authorization: ${r['status']}${r['reason'] != null ? ' (${r['reason']})' : ''}');
            } catch (e) {
              if (context.mounted) showError(context, e);
            }
          }, icon: const Icon(Icons.science_outlined), label: const Text('Simulate a card payment (sandbox)')),
        ],
        const SectionHeader('Transactions'),
        AsyncView(value: txs, data: (l) => l.isEmpty ? const Text('No card payments yet') : Column(children: [for (final t in l) TxnTile(t)])),
        const SizedBox(height: Space.xl),
        TextButton(style: TextButton.styleFrom(foregroundColor: PesaColors.danger), onPressed: () async {
          final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: const Text('Close this card?'), content: const Text('This cannot be undone.'), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Close card'))]));
          if (ok != true) return;
          try {
            await ref.read(cardsRepositoryProvider).close(_card.id);
            ref.invalidate(cardsProvider);
            if (context.mounted) context.pop();
          } catch (e) {
            if (context.mounted) showError(context, e);
          }
        }, child: const Text('Close card')),
      ]),
    );
  }
}
