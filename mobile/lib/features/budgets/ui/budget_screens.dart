import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import '../../../core/theme/theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/data/auth_controller.dart';
import '../data/budgets.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgets = ref.watch(budgetsProvider);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(title: const Text('Budgets'), bottom: const TabBar(tabs: [Tab(text: 'Budgets'), Tab(text: 'Expenses'), Tab(text: 'Income')])),
        body: TabBarView(children: [
          AsyncView(
            value: budgets,
            onRetry: () => ref.invalidate(budgetsProvider),
            data: (list) => RefreshableList(onRefresh: () async => ref.invalidate(budgetsProvider), children: [
              if (list.isEmpty) EmptyState(icon: Icons.pie_chart_rounded, title: 'No budget yet', message: 'Set limits for food, transport and more. We\'ll alert you at 80% and when you go over.', action: FilledButton(onPressed: () => context.push('/grow/budgets/new'), child: const Text('Create a budget'))),
              for (final b in list) Padding(padding: const EdgeInsets.only(bottom: Space.md), child: _BudgetCard(b)),
              if (list.isNotEmpty && list.length < 2) OutlinedButton.icon(onPressed: () => context.push('/grow/budgets/new'), icon: const Icon(Icons.add_rounded), label: const Text('Add a weekly or monthly budget')),
              const SectionHeader('Recurring'),
              const _RecurringList(),
            ]),
          ),
          const _Entries(kind: 'EXPENSE'),
          const _Entries(kind: 'INCOME'),
        ]),
      ),
    );
  }
}

class _BudgetCard extends ConsumerWidget {
  const _BudgetCard(this.b);
  final Budget b;
  @override
  Widget build(BuildContext context, WidgetRef ref) => PesaCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(b.name, style: context.text.titleMedium), Text(b.period == 'WEEKLY' ? 'This week' : 'This month', style: context.text.bodySmall?.copyWith(color: context.palette.text3))])),
            PopupMenuButton<String>(onSelected: (a) async {
              if (a == 'edit') await context.push('/grow/budgets/new', extra: b);
              if (a == 'delete') {
                try { await ref.read(budgetsRepositoryProvider).delete(b.id); ref.invalidate(budgetsProvider); } catch (e) { if (context.mounted) showError(context, e); }
              }
            }, itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('Edit')), PopupMenuItem(value: 'delete', child: Text('Delete'))]),
          ]),
          const SizedBox(height: Space.md),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            MoneyText(b.spent, compact: true, style: context.text.headlineSmall),
            Text('  of ${b.totalLimit.format(compact: true)}', style: context.text.bodyMedium?.copyWith(color: context.palette.text2)),
            const Spacer(),
            Text(b.onPace ? 'On track' : 'Ahead of pace', style: context.text.labelLarge?.copyWith(color: b.onPace ? PesaColors.emerald600 : PesaColors.coral500)),
          ]),
          const SizedBox(height: Space.sm),
          Stack(children: [
            ProgressBar(percent: b.percentUsed, height: 10),
            Positioned(left: 0, right: 0, top: 0, bottom: 0, child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: (b.periodElapsedPercent / 100).clamp(0.0, 1.0), child: Align(alignment: Alignment.centerRight, child: Container(width: 2, height: 14, color: context.colors.onSurface.withValues(alpha: .5))))),
          ]),
          const SizedBox(height: 4),
          Text('${b.remaining.format(compact: true)} left · ${b.periodElapsedPercent}% of the period gone', style: context.text.bodySmall?.copyWith(color: context.palette.text3)),
          if (b.categories.isNotEmpty) const SizedBox(height: Space.md),
          for (final c in b.categories) Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Expanded(child: Text(categoryLabel(c.category), style: context.text.bodyMedium)), Text('${c.spent.format(compact: true, symbol: false)} / ${c.limit.format(compact: true, symbol: false)}', style: context.text.bodySmall?.copyWith(color: c.overspent ? PesaColors.danger : context.palette.text2, fontWeight: c.overspent ? FontWeight.w700 : null))]),
              const SizedBox(height: 4),
              ProgressBar(percent: c.percentUsed, height: 6),
            ]),
          ),
        ]),
      );
}

class _RecurringList extends ConsumerWidget {
  const _RecurringList();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(recurringProvider);
    return AsyncView(value: items, data: (list) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final r in list) ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(r['kind'] == 'INCOME' ? Icons.south_west_rounded : Icons.repeat_rounded),
        title: Text('${r['description'] ?? categoryLabel('${r['category']}')}'),
        subtitle: Text('${(r['frequency'] as String).toLowerCase()} · next ${DateFormat('d MMM').format(DateTime.parse('${r['nextRunAt']}').toLocal())}'),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [MoneyText(Money.fromJson(r['amount'] as Map<String, dynamic>), compact: true, style: context.text.bodyMedium), IconButton(tooltip: 'Stop', icon: const Icon(Icons.close_rounded), onPressed: () async { await ref.read(budgetsRepositoryProvider).stopRecurring('${r['id']}'); ref.invalidate(recurringProvider); })]),
      ),
      TextButton.icon(onPressed: () => _addEntry(context, ref, 'EXPENSE', recurring: true), icon: const Icon(Icons.add_rounded), label: const Text('Add recurring rent, salary, subscription…')),
    ]));
  }
}

class _Entries extends ConsumerWidget {
  const _Entries({required this.kind});
  final String kind;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(entriesProvider(kind));
    return Scaffold(
      floatingActionButton: FloatingActionButton(heroTag: kind, onPressed: () => _addEntry(context, ref, kind), tooltip: kind == 'INCOME' ? 'Add income' : 'Add expense', child: const Icon(Icons.add_rounded)),
      body: AsyncView(value: entries, onRetry: () => ref.invalidate(entriesProvider(kind)), data: (list) => RefreshableList(onRefresh: () async => ref.invalidate(entriesProvider(kind)), children: [
        Text(kind == 'INCOME' ? 'Income you record here (salary, business, gifts) is included in your monthly summary.' : 'Record cash and other spending not paid through Pesa so budgets stay accurate.', style: context.text.bodySmall?.copyWith(color: context.palette.text3)),
        const SizedBox(height: Space.md),
        if (list.isEmpty) EmptyState(icon: kind == 'INCOME' ? Icons.payments_rounded : Icons.shopping_basket_rounded, title: kind == 'INCOME' ? 'No income recorded' : 'No manual expenses'),
        for (final e in list) Dismissible(
          key: ValueKey(e.id),
          direction: DismissDirection.endToStart,
          background: Container(color: PesaColors.danger, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete_rounded, color: Colors.white)),
          onDismissed: (_) async { await ref.read(budgetsRepositoryProvider).deleteEntry(kind, e.id); ref.invalidate(entriesProvider(kind)); ref.invalidate(budgetsProvider); },
          child: ListTile(contentPadding: EdgeInsets.zero, title: Text(e.description ?? categoryLabel(e.category)), subtitle: Text('${categoryLabel(e.category)} · ${DateFormat('d MMM').format(e.date.toLocal())}${e.recurring ? ' · recurring' : ''}'), trailing: MoneyText(e.amount, compact: true, signed: kind == 'INCOME' ? 'CREDIT' : 'DEBIT', style: context.text.titleSmall)),
        ),
        const SizedBox(height: 80),
      ])),
    );
  }
}

Future<void> _addEntry(BuildContext context, WidgetRef ref, String kind, {bool recurring = false}) async {
  final cats = await ref.read(categoriesProvider.future);
  if (!context.mounted) return;
  final currency = ref.read(currentUserProvider)?.currency ?? 'KES';
  final amount = TextEditingController();
  final desc = TextEditingController();
  var entryKind = kind;
  var category = (kind == 'INCOME' ? cats.$2 : cats.$1).first.key;
  var frequency = 'MONTHLY';
  final saved = await showModalBottomSheet<bool>(context: context, isScrollControlled: true, builder: (c) => StatefulBuilder(builder: (c, set) {
    final list = entryKind == 'INCOME' ? cats.$2 : cats.$1;
    if (!list.any((x) => x.key == category)) category = list.first.key;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.viewInsetsOf(c).bottom),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(recurring ? 'Recurring item' : entryKind == 'INCOME' ? 'Record income' : 'Record expense', style: c.text.titleLarge),
        if (recurring) ...[const SizedBox(height: Space.md), SegmentedButton<String>(segments: const [ButtonSegment(value: 'EXPENSE', label: Text('Expense')), ButtonSegment(value: 'INCOME', label: Text('Income'))], selected: {entryKind}, onSelectionChanged: (s) => set(() => entryKind = s.first))],
        const SizedBox(height: Space.md),
        TextField(controller: amount, autofocus: true, keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))], decoration: InputDecoration(labelText: 'Amount', prefixText: '${Money.symbols[currency]} ')),
        const SizedBox(height: Space.md),
        DropdownButtonFormField<String>(initialValue: category, decoration: const InputDecoration(labelText: 'Category'), items: [for (final x in list) DropdownMenuItem(value: x.key, child: Text(x.label))], onChanged: (v) => set(() => category = v!)),
        const SizedBox(height: Space.md),
        TextField(controller: desc, maxLength: 140, decoration: const InputDecoration(labelText: 'Description (optional)')),
        if (recurring) SegmentedButton<String>(segments: const [ButtonSegment(value: 'WEEKLY', label: Text('Weekly')), ButtonSegment(value: 'MONTHLY', label: Text('Monthly'))], selected: {frequency}, onSelectionChanged: (s) => set(() => frequency = s.first)),
        const SizedBox(height: Space.md),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Save')),
      ]),
    );
  }));
  if (saved != true) return;
  final value = Money.normalizeInput(amount.text, currency);
  if (value == null) { if (context.mounted) showMessage(context, 'Enter a valid amount'); return; }
  try {
    final repo = ref.read(budgetsRepositoryProvider);
    final body = {'amount': value, 'category': category, if (desc.text.trim().isNotEmpty) 'description': desc.text.trim()};
    if (recurring) {
      await repo.addRecurring({...body, 'kind': entryKind, 'frequency': frequency});
      ref.invalidate(recurringProvider);
    } else {
      await repo.addEntry(entryKind, body);
    }
    ref.invalidate(entriesProvider(entryKind));
    ref.invalidate(budgetsProvider);
  } catch (e) {
    if (context.mounted) showError(context, e);
  }
}

class BudgetFormScreen extends ConsumerStatefulWidget {
  const BudgetFormScreen({super.key, this.budget});
  final Budget? budget;
  @override
  ConsumerState<BudgetFormScreen> createState() => _BudgetFormScreenState();
}

class _BudgetFormScreenState extends ConsumerState<BudgetFormScreen> {
  late final _name = TextEditingController(text: widget.budget?.name ?? DateFormat('MMMM').format(DateTime.now()));
  late String _period = widget.budget?.period ?? 'MONTHLY';
  late final Map<String, TextEditingController> _limits = {for (final c in widget.budget?.categories ?? const <BudgetCategory>[]) c.category: TextEditingController(text: c.limit.amount)};
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    for (final c in _limits.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cats = ref.watch(categoriesProvider);
    final currency = ref.read(currentUserProvider)?.currency ?? 'KES';
    return Scaffold(
      appBar: AppBar(title: Text(widget.budget == null ? 'New budget' : 'Edit budget')),
      body: AsyncView(value: cats, data: (c) => ListView(padding: Space.page.copyWith(bottom: 32), children: [
        TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
        const SizedBox(height: Space.md),
        if (widget.budget == null) SegmentedButton<String>(segments: const [ButtonSegment(value: 'MONTHLY', label: Text('Monthly')), ButtonSegment(value: 'WEEKLY', label: Text('Weekly'))], selected: {_period}, onSelectionChanged: (s) => setState(() => _period = s.first)),
        const SectionHeader('Category limits'),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final cat in c.$1.where((x) => !['transfers', 'savings', 'uncategorised'].contains(x.key)))
            FilterChip(label: Text(cat.label), selected: _limits.containsKey(cat.key), onSelected: (on) => setState(() => on ? _limits[cat.key] = TextEditingController() : _limits.remove(cat.key)?.dispose())),
        ]),
        const SizedBox(height: Space.lg),
        for (final e in _limits.entries) Padding(padding: const EdgeInsets.only(bottom: Space.md), child: TextField(controller: e.value, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: categoryLabel(e.key), prefixText: '${Money.symbols[currency]} '))),
        const SizedBox(height: Space.lg),
        LoadingButton(label: 'Save budget', loading: _busy, onPressed: () async {
          final limits = <Map<String, String>>[];
          for (final e in _limits.entries) {
            final v = Money.normalizeInput(e.value.text, currency);
            if (v == null) return showMessage(context, 'Enter a valid limit for ${categoryLabel(e.key)}');
            limits.add({'category': e.key, 'limit': v});
          }
          if (limits.isEmpty) return showMessage(context, 'Choose at least one category');
          setState(() => _busy = true);
          try {
            final repo = ref.read(budgetsRepositoryProvider);
            widget.budget == null
                ? await repo.create({'name': _name.text.trim(), 'period': _period, 'categories': limits})
                : await repo.update(widget.budget!.id, {'name': _name.text.trim(), 'categories': limits});
            ref.invalidate(budgetsProvider);
            if (context.mounted) context.pop();
          } catch (e) {
            if (context.mounted) showError(context, e);
          } finally {
            if (mounted) setState(() => _busy = false);
          }
        }),
      ])),
    );
  }
}

/// Monthly report: local insights, trends, unusual spending and suggestions.
class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});
  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  bool _narrative = false;
  @override
  Widget build(BuildContext context) {
    final report = ref.watch(reportProvider(_narrative));
    final trends = ref.watch(trendsProvider);
    final user = ref.watch(currentUserProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: AsyncView(value: report, onRetry: () => ref.invalidate(reportProvider(_narrative)), data: (r) {
        final ai = r['externalAi'] as Map<String, dynamic>;
        return RefreshableList(onRefresh: () async { ref.invalidate(reportProvider(_narrative)); ref.invalidate(trendsProvider); }, children: [
          PesaCard(
            color: PesaColors.navy900,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [const Icon(Icons.auto_awesome_rounded, color: PesaColors.gold500, size: 18), const SizedBox(width: 6), Text(r['generatedBy'] == 'EXTERNAL_AI' ? 'AI summary' : 'Your month', style: context.text.labelLarge?.copyWith(color: const Color(0xFFA9C0D4)))]),
              const SizedBox(height: Space.sm),
              Text('${r['summary']}', style: context.text.titleMedium?.copyWith(color: Colors.white, height: 1.4)),
              for (final tip in (r['aiTips'] as List? ?? const [])) Padding(padding: const EdgeInsets.only(top: 6), child: Text('• $tip', style: context.text.bodyMedium?.copyWith(color: Colors.white70))),
            ]),
          ),
          if (ai['available'] == true) SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('AI-written summary'),
            subtitle: Text(user?.consents.externalAiProcessing == true ? 'Uses only totals per category — never names, numbers or references.' : 'Requires your consent in Privacy settings.', style: context.text.bodySmall),
            value: _narrative && user?.consents.externalAiProcessing == true,
            onChanged: user?.consents.externalAiProcessing == true ? (v) => setState(() => _narrative = v) : (_) => context.push('/profile/privacy'),
          ),
          trends.maybeWhen(data: (m) => _TrendChart(m), orElse: () => const SizedBox.shrink()),
          for (final i in (r['insights'] as List).cast<Map<String, dynamic>>())
            Padding(padding: const EdgeInsets.only(top: Space.md), child: PesaCard(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(switch (i['severity']) { 'WARNING' => Icons.warning_amber_rounded, 'POSITIVE' => Icons.thumb_up_alt_rounded, _ => Icons.lightbulb_rounded }, color: switch (i['severity']) { 'WARNING' => PesaColors.gold500, 'POSITIVE' => PesaColors.emerald500, _ => PesaColors.sky500 }),
              const SizedBox(width: Space.md),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${i['title']}', style: context.text.titleSmall), Text('${i['detail']}', style: context.text.bodySmall?.copyWith(color: context.palette.text2))])),
            ]))),
          if ((r['unusualTransactions'] as List).isNotEmpty) ...[
            const SectionHeader('Unusual spending'),
            for (final u in (r['unusualTransactions'] as List).cast<Map<String, dynamic>>())
              ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.priority_high_rounded, color: PesaColors.coral500), title: Text('${Money.fromJson(u['amount'] as Map<String, dynamic>).format()} on ${categoryLabel('${u['category']}')}'), subtitle: Text('About ${u['timesTypical']}× your usual ${Money.fromJson(u['typical'] as Map<String, dynamic>).format(compact: true)}'), onTap: () => context.push('/activity/${u['transactionId']}')),
          ],
          for (final s in (r['suggestions'] as List).cast<Map<String, dynamic>>()) ...[
            SectionHeader('${s['title']}'),
            Text('${s['detail']}', style: context.text.bodyMedium?.copyWith(color: context.palette.text2)),
            for (final c in (s['categories'] as List? ?? const []).cast<Map<String, dynamic>>())
              ListTile(contentPadding: EdgeInsets.zero, dense: true, title: Text(categoryLabel('${c['category']}')), trailing: Text(Money.fromJson(c['suggestedLimit'] as Map<String, dynamic>).format(compact: true))),
            if (s['type'] == 'CREATE_BUDGET') OutlinedButton(onPressed: () => context.push('/grow/budgets/new'), child: const Text('Create this budget')),
          ],
          const SizedBox(height: Space.lg),
          Text('Insights are estimates from your completed transactions and the entries you record. They are not financial advice.', style: context.text.bodySmall?.copyWith(color: context.palette.text3)),
        ]);
      }),
    );
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart(this.months);
  final List<Map<String, dynamic>> months;
  @override
  Widget build(BuildContext context) {
    double v(Map<String, dynamic> m, String k) => ((m[k] as Map)['amountMinor'] as int).toDouble();
    return Padding(
      padding: const EdgeInsets.only(top: Space.lg),
      child: PesaCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Income vs spending', style: context.text.titleSmall),
        const SizedBox(height: Space.md),
        SizedBox(height: 160, child: BarChart(BarChartData(
          gridData: const FlGridData(show: false), borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(leftTitles: const AxisTitles(), rightTitles: const AxisTitles(), topTitles: const AxisTitles(),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (x, _) => Text(DateFormat('MMM').format(DateTime.parse('${months[x.toInt()]['month']}-01')), style: context.text.labelSmall)))),
          barGroups: [for (var i = 0; i < months.length; i++) BarChartGroupData(x: i, barsSpace: 4, barRods: [
            BarChartRodData(toY: v(months[i], 'income'), color: PesaColors.emerald500, width: 9, borderRadius: BorderRadius.circular(4)),
            BarChartRodData(toY: v(months[i], 'expenses'), color: PesaColors.coral500, width: 9, borderRadius: BorderRadius.circular(4)),
          ])],
        ))),
        const SizedBox(height: Space.sm),
        Row(children: [_dot(PesaColors.emerald500), const Text(' Income   '), _dot(PesaColors.coral500), const Text(' Spending')]),
      ])),
    );
  }

  Widget _dot(Color c) => Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle));
}

