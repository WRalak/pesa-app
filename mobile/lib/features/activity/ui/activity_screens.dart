import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../budgets/data/budgets.dart';
import '../data/activity_repository.dart';
import '../data/models.dart';
import 'txn_tile.dart';

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});
  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  final _scroll = ScrollController();
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 400) ref.read(txnListProvider.notifier).loadMore();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(txnListProvider);
    final c = ref.read(txnListProvider.notifier);
    final f = s.filter;
    final groups = <String, List<Txn>>{};
    for (final t in s.items) {
      groups.putIfAbsent(DateFormat('EEEE, d MMMM').format(t.createdAt.toLocal()), () => []).add(t);
    }
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).navActivity), actions: [
        IconButton(tooltip: 'Statements', icon: const Icon(Icons.description_outlined), onPressed: () => showModalBottomSheet<void>(context: context, builder: (_) => const StatementSheet())),
      ]),
      body: Column(children: [
        Padding(
          padding: Space.page,
          child: TextField(
            controller: _search,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(hintText: 'Search name, number, reference…', prefixIcon: const Icon(Icons.search_rounded), suffixIcon: _search.text.isEmpty ? null : IconButton(icon: const Icon(Icons.clear_rounded), onPressed: () { _search.clear(); c.setFilter(f.copyWith(q: '')); })),
            onSubmitted: (q) => unawaited(c.setFilter(f.copyWith(q: q.trim()))),
          ),
        ),
        SizedBox(
          height: 52,
          child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), children: [
            _chip('All', f.isEmpty, () { _search.clear(); c.setFilter(const TxnFilter()); }),
            _chip('Money in', f.direction == 'CREDIT', () => c.setFilter(f.copyWith(direction: f.direction == 'CREDIT' ? '' : 'CREDIT'))),
            _chip('Money out', f.direction == 'DEBIT', () => c.setFilter(f.copyWith(direction: f.direction == 'DEBIT' ? '' : 'DEBIT'))),
            _chip('Pending', f.status == 'PENDING,PROCESSING', () => f.status == 'PENDING,PROCESSING' ? c.setFilter(f.copyWith(clearStatus: true)) : c.setFilter(f.copyWith(status: 'PENDING,PROCESSING'))),
            _chip('Failed', f.status == 'FAILED', () => f.status == 'FAILED' ? c.setFilter(f.copyWith(clearStatus: true)) : c.setFilter(f.copyWith(status: 'FAILED'))),
            for (final (type, label) in const [('AIRTIME', 'Airtime'), ('PAYBILL,UTILITY', 'Bills'), ('SEND_MONEY', 'Sent'), ('BUY_GOODS', 'Shopping'), ('CARD_PAYMENT', 'Card')])
              _chip(label, f.type == type, () => f.type == type ? c.setFilter(f.copyWith(clearType: true)) : c.setFilter(f.copyWith(type: type))),
            _chip(f.from == null ? 'Date range' : '${DateFormat('d MMM').format(f.from!)} – ${DateFormat('d MMM').format(f.to!)}', f.from != null, () async {
              if (f.from != null) return c.setFilter(f.copyWith(clearDates: true));
              final r = await showDateRangePicker(context: context, firstDate: DateTime(2024), lastDate: DateTime.now());
              if (r != null) await c.setFilter(f.copyWith(from: r.start, to: r.end.add(const Duration(hours: 23, minutes: 59))));
            }),
          ]),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: c.refresh,
            child: s.items.isEmpty && !s.loading
                ? ListView(children: [s.error != null ? ErrorState(message: '${s.error}', onRetry: c.refresh) : EmptyState(icon: Icons.receipt_long_rounded, title: f.isEmpty ? 'No transactions yet' : 'Nothing matches these filters')])
                : ListView(controller: _scroll, padding: const EdgeInsets.fromLTRB(20, 0, 20, 32), children: [
                    for (final e in groups.entries) ...[
                      Padding(padding: const EdgeInsets.only(top: Space.lg, bottom: Space.xs), child: Text(e.key, style: context.text.labelLarge?.copyWith(color: context.palette.text3))),
                      ...e.value.map(TxnTile.new),
                    ],
                    if (s.loading) const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
                  ]),
          ),
        ),
      ]),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) => Padding(padding: const EdgeInsets.only(right: 8), child: FilterChip(label: Text(label), selected: selected, onSelected: (_) => onTap(), showCheckmark: false));
}

class TransactionDetailScreen extends ConsumerWidget {
  const TransactionDetailScreen({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(transactionDetailProvider(id));
    return Scaffold(
      appBar: AppBar(title: const Text('Transaction')),
      body: AsyncView(
        value: d,
        onRetry: () => ref.invalidate(transactionDetailProvider(id)),
        data: (v) {
          final (t, timeline) = v;
          return RefreshableList(
            onRefresh: () async => ref.invalidate(transactionDetailProvider(id)),
            children: [
              Center(child: Container(width: 64, height: 64, decoration: BoxDecoration(color: context.colors.primaryContainer, borderRadius: BorderRadius.circular(20)), child: Icon(iconForType(t.type), color: context.colors.primary, size: 30))),
              const SizedBox(height: Space.md),
              Center(child: MoneyText(t.total, signed: t.status == 'FAILED' ? null : t.direction, style: context.text.displaySmall)),
              const SizedBox(height: 4),
              Center(child: Text(t.title, style: context.text.bodyLarge?.copyWith(color: context.palette.text2), textAlign: TextAlign.center)),
              const SizedBox(height: Space.sm),
              Center(child: StatusChip(t.status)),
              if (t.statusReason != null && t.status == 'FAILED') Padding(padding: const EdgeInsets.only(top: 8), child: Text(t.statusReason!, textAlign: TextAlign.center, style: context.text.bodySmall?.copyWith(color: PesaColors.danger))),
              const SizedBox(height: Space.xl),
              PesaCard(child: Column(children: [
                _kv(context, 'Amount', t.amount.format()),
                _kv(context, 'Fee', t.fee.format()),
                _kv(context, 'Reference', t.reference, copy: true),
                if (t.externalRef != null) _kv(context, 'Provider receipt', t.externalRef!, copy: true),
                if (t.counterparty.phone != null) _kv(context, 'Phone', t.counterparty.phone!),
                if (t.counterparty.shortcode != null) _kv(context, t.type == 'BUY_GOODS' ? 'Till' : 'Paybill', t.counterparty.shortcode!),
                if (t.counterparty.accountNumber != null) _kv(context, 'Account', t.counterparty.accountNumber!),
                _kv(context, 'Date', DateFormat('d MMM yyyy, HH:mm').format(t.createdAt.toLocal())),
                InkWell(
                  onTap: () => _pickCategory(context, ref, t),
                  child: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [Text('Category', style: context.text.bodyMedium?.copyWith(color: context.palette.text2)), const Spacer(), Text(categoryLabel(t.category), style: context.text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)), const Icon(Icons.edit_rounded, size: 16)])),
                ),
              ])),
              const SectionHeader('Status history'),
              PesaCard(child: Column(children: [
                for (var i = 0; i < timeline.length; i++)
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Column(children: [
                      Container(width: 12, height: 12, margin: const EdgeInsets.only(top: 4), decoration: BoxDecoration(color: context.colors.primary, shape: BoxShape.circle)),
                      if (i < timeline.length - 1) Container(width: 2, height: 34, color: context.palette.border),
                    ]),
                    const SizedBox(width: Space.md),
                    Expanded(child: Padding(padding: const EdgeInsets.only(bottom: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(timeline[i].kind == 'REVERSAL_REQUESTED' ? 'Reversal requested' : (timeline[i].status ?? '').toLowerCase().replaceFirstMapped(RegExp('^.'), (m) => m[0]!.toUpperCase()), style: context.text.titleSmall),
                      Text(DateFormat('d MMM, HH:mm:ss').format(timeline[i].at.toLocal()), style: context.text.bodySmall?.copyWith(color: context.palette.text3)),
                    ]))),
                  ]),
              ])),
              const SizedBox(height: Space.xl),
              if (t.status == 'SUCCESSFUL') FilledButton.icon(onPressed: () => _shareReceipt(context, ref, t), icon: const Icon(Icons.ios_share_rounded), label: const Text('Share receipt')),
              if (!t.isTerminal) OutlinedButton.icon(onPressed: () async { try { await ref.read(activityRepositoryProvider).refreshStatus(t.id); ref.invalidate(transactionDetailProvider(id)); } catch (e) { if (context.mounted) showError(context, e); } }, icon: const Icon(Icons.refresh_rounded), label: const Text('Check status')),
              const SizedBox(height: Space.md),
              TextButton(onPressed: () => context.push('/profile/support/new?transactionId=${t.id}&subject=${Uri.encodeComponent('Issue with ${t.reference}')}'), child: const Text('Report a problem')),
            ],
          );
        },
      ),
    );
  }

  Widget _kv(BuildContext context, String k, String v, {bool copy = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [Text(k, style: context.text.bodyMedium?.copyWith(color: context.palette.text2)), const SizedBox(width: 12), Expanded(child: copy ? SelectableText(v, textAlign: TextAlign.end, style: context.text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)) : Text(v, textAlign: TextAlign.end, style: context.text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)))]),
      );

  Future<void> _pickCategory(BuildContext context, WidgetRef ref, Txn t) async {
    final cats = await ref.read(categoriesProvider.future);
    if (!context.mounted) return;
    final list = t.direction == 'CREDIT' ? cats.$2 : cats.$1;
    final picked = await showModalBottomSheet<String>(context: context, builder: (c) => ListView(shrinkWrap: true, children: [for (final cat in list) ListTile(title: Text(cat.label), trailing: cat.key == t.category ? const Icon(Icons.check_rounded) : null, onTap: () => Navigator.pop(c, cat.key))]));
    if (picked == null || picked == t.category) return;
    try {
      await ref.read(activityRepositoryProvider).setCategory(t.id, picked);
      ref.invalidate(transactionDetailProvider(t.id));
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  Future<void> _shareReceipt(BuildContext context, WidgetRef ref, Txn t) async {
    try {
      final r = await ref.read(activityRepositoryProvider).receipt(t.id);
      final lines = [
        '${r['title']}',
        'Reference: ${r['reference']}',
        if (r['providerReceipt'] != null) 'Provider receipt: ${r['providerReceipt']}',
        'Amount: ${t.amount.format()}',
        'Fee: ${t.fee.format()}',
        'Total: ${t.total.format()}',
        'Paid: ${DateFormat('d MMM yyyy, HH:mm').format(t.completedAt!.toLocal())}',
        t.title,
        if (r['sandbox'] == true) 'SANDBOX — not a real payment',
        '${r['disclaimer']}',
      ];
      await SharePlus.instance.share(ShareParams(text: lines.join('\n'), subject: 'Receipt ${t.reference}'));
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }
}

class StatementSheet extends ConsumerStatefulWidget {
  const StatementSheet({super.key});
  @override
  ConsumerState<StatementSheet> createState() => _StatementSheetState();
}

class _StatementSheetState extends ConsumerState<StatementSheet> {
  DateTimeRange _range = DateTimeRange(start: DateTime(DateTime.now().year, DateTime.now().month, 1), end: DateTime.now());
  String _format = 'pdf';
  bool _busy = false;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Download statement', style: context.text.titleLarge),
            const SizedBox(height: Space.lg),
            OutlinedButton.icon(
              icon: const Icon(Icons.date_range_rounded),
              label: Text('${DateFormat('d MMM yyyy').format(_range.start)} – ${DateFormat('d MMM yyyy').format(_range.end)}'),
              onPressed: () async {
                final r = await showDateRangePicker(context: context, firstDate: DateTime(2024), lastDate: DateTime.now(), initialDateRange: _range);
                if (r != null) setState(() => _range = r);
              },
            ),
            const SizedBox(height: Space.md),
            SegmentedButton<String>(segments: const [ButtonSegment(value: 'pdf', label: Text('PDF')), ButtonSegment(value: 'csv', label: Text('CSV (Excel)'))], selected: {_format}, onSelectionChanged: (s) => setState(() => _format = s.first)),
            const SizedBox(height: Space.xl),
            LoadingButton(
              label: 'Download & share',
              loading: _busy,
              onPressed: () async {
                setState(() => _busy = true);
                try {
                  final dir = await getTemporaryDirectory();
                  final path = '${dir.path}/pesa-statement-${DateFormat('yyyyMMdd').format(_range.start)}-${DateFormat('yyyyMMdd').format(_range.end)}.$_format';
                  await ref.read(activityRepositoryProvider).downloadStatement(_range.start, _range.end.add(const Duration(hours: 23, minutes: 59)), _format, path);
                  await SharePlus.instance.share(ShareParams(files: [XFile(path)], subject: 'Pesa statement'));
                  if (await File(path).exists()) await File(path).delete();
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) showError(context, e);
                } finally {
                  if (mounted) setState(() => _busy = false);
                }
              },
            ),
          ]),
        ),
      );
}
