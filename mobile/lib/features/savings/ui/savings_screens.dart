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
import '../data/savings.dart';

IconData goalIcon(String c) => switch (c) {
      'EMERGENCY' => Icons.health_and_safety_rounded, 'RENT' => Icons.home_rounded, 'EDUCATION' => Icons.school_rounded,
      'BUSINESS' => Icons.storefront_rounded, 'TRAVEL' => Icons.flight_rounded, 'ELECTRONICS' => Icons.devices_rounded,
      'HOME' => Icons.chair_rounded, 'HEALTH' => Icons.favorite_rounded, _ => Icons.savings_rounded,
    };

class SavingsScreen extends ConsumerStatefulWidget {
  const SavingsScreen({super.key});
  @override
  ConsumerState<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends ConsumerState<SavingsScreen> {
  String? _status;
  @override
  Widget build(BuildContext context) {
    final goals = ref.watch(goalsProvider(_status));
    final series = ref.watch(savingsSeriesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Savings goals')),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => context.push('/grow/savings/new'), icon: const Icon(Icons.add_rounded), label: const Text('New goal')),
      body: AsyncView(
        value: goals,
        onRetry: () => ref.invalidate(goalsProvider(_status)),
        data: (v) {
          final (items, summary) = v;
          return RefreshableList(
            onRefresh: () async { ref.invalidate(goalsProvider(_status)); ref.invalidate(savingsSeriesProvider); },
            children: [
              PesaCard(color: context.palette.surface2, child: Row(children: [
                const Icon(Icons.info_outline_rounded, size: 18),
                const SizedBox(width: Space.sm),
                Expanded(child: Text('Goals help you track money you set aside. Funds stay in your own accounts.', style: context.text.bodySmall)),
              ])),
              if (summary != null && _status == null) ...[
                const SizedBox(height: Space.lg),
                Text('Total saved', style: context.text.bodyMedium?.copyWith(color: context.palette.text2)),
                MoneyText(Money.fromJson(summary['saved'] as Map<String, dynamic>), style: context.text.headlineMedium),
                Text('${summary['progressPercent']}% of ${Money.fromJson(summary['target'] as Map<String, dynamic>).format(compact: true)}', style: context.text.bodySmall),
              ],
              series.maybeWhen(data: (s) => s.any((m) => (m['contributed'] as Map)['amountMinor'] != 0) ? _SeriesChart(s) : const SizedBox.shrink(), orElse: () => const SizedBox.shrink()),
              const SizedBox(height: Space.md),
              SegmentedButton<String?>(
                segments: const [ButtonSegment(value: null, label: Text('Active')), ButtonSegment(value: 'COMPLETED', label: Text('Completed')), ButtonSegment(value: 'ARCHIVED', label: Text('Archived'))],
                selected: {_status}, onSelectionChanged: (s) => setState(() => _status = s.first),
              ),
              const SizedBox(height: Space.md),
              if (items.isEmpty) EmptyState(icon: Icons.savings_rounded, title: 'No goals here', message: 'Emergency fund, rent, school fees, a new phone — start with one goal.', action: _status == null ? FilledButton(onPressed: () => context.push('/grow/savings/new'), child: const Text('Create a goal')) : null),
              for (final g in items) Padding(padding: const EdgeInsets.only(bottom: Space.md), child: _GoalCard(g)),
              const SizedBox(height: 60),
            ],
          );
        },
      ),
    );
  }
}

class _SeriesChart extends StatelessWidget {
  const _SeriesChart(this.series);
  final List<Map<String, dynamic>> series;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: Space.lg),
        child: SizedBox(
          height: 120,
          child: BarChart(BarChartData(
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(), rightTitles: const AxisTitles(), topTitles: const AxisTitles(),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) => Text(DateFormat('MMM').format(DateTime.parse('${series[v.toInt()]['month']}-01')), style: context.text.labelSmall))),
            ),
            barGroups: [
              for (var i = 0; i < series.length; i++)
                BarChartGroupData(x: i, barRods: [BarChartRodData(toY: ((series[i]['contributed'] as Map)['amountMinor'] as int).toDouble(), color: PesaColors.emerald500, width: 18, borderRadius: BorderRadius.circular(6))]),
            ],
          )),
        ),
      );
}

class _GoalCard extends StatelessWidget {
  const _GoalCard(this.g);
  final SavingsGoal g;
  @override
  Widget build(BuildContext context) {
    final color = g.color != null ? Color(int.parse('FF${g.color!.substring(1)}', radix: 16)) : context.colors.primary;
    return PesaCard(
      onTap: () => context.push('/grow/savings/${g.id}'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withValues(alpha: .14), borderRadius: BorderRadius.circular(12)), child: Icon(goalIcon(g.category), color: color)),
          const SizedBox(width: Space.md),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(g.name, style: context.text.titleSmall),
            Text(g.deadline != null ? 'By ${DateFormat('d MMM yyyy').format(g.deadline!)}' : goalCategories[g.category] ?? '', style: context.text.bodySmall?.copyWith(color: context.palette.text3)),
          ])),
          if (g.status == 'COMPLETED') const Icon(Icons.emoji_events_rounded, color: PesaColors.gold500),
        ]),
        const SizedBox(height: Space.md),
        ProgressBar(percent: g.analytics.progressPercent, color: color),
        const SizedBox(height: Space.sm),
        Row(children: [
          MoneyText(g.saved, compact: true, style: context.text.titleSmall),
          Text(' of ${g.target.format(compact: true)}', style: context.text.bodySmall?.copyWith(color: context.palette.text2)),
          const Spacer(),
          Text('${g.analytics.progressPercent}%', style: context.text.labelLarge),
        ]),
      ]),
    );
  }
}

class GoalDetailScreen extends ConsumerWidget {
  const GoalDetailScreen({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goal = ref.watch(goalProvider(id));
    final history = ref.watch(contributionsProvider(id));
    void refresh() { ref.invalidate(goalProvider(id)); ref.invalidate(contributionsProvider(id)); ref.invalidate(goalsProvider); }
    return Scaffold(
      appBar: AppBar(actions: [
        goal.maybeWhen(
          data: (g) => PopupMenuButton<String>(onSelected: (a) async {
            if (a == 'edit') { await context.push('/grow/savings/${g.id}/edit', extra: g); refresh(); }
            if (a == 'archive' || a == 'restore') {
              try { await ref.read(savingsRepositoryProvider).archive(g.id, a == 'archive'); refresh(); } catch (e) { if (context.mounted) showError(context, e); }
            }
          }, itemBuilder: (_) => [
            if (g.status != 'ARCHIVED') const PopupMenuItem(value: 'edit', child: Text('Edit goal')),
            PopupMenuItem(value: g.status == 'ARCHIVED' ? 'restore' : 'archive', child: Text(g.status == 'ARCHIVED' ? 'Restore' : 'Archive')),
          ]),
          orElse: () => const SizedBox.shrink(),
        ),
      ]),
      body: AsyncView(
        value: goal,
        onRetry: refresh,
        data: (g) => RefreshableList(onRefresh: () async => refresh(), children: [
          Row(children: [Icon(goalIcon(g.category), color: context.colors.primary), const SizedBox(width: 8), Expanded(child: Text(g.name, style: context.text.headlineSmall))]),
          const SizedBox(height: Space.lg),
          Center(
            child: SizedBox(
              width: 180, height: 180,
              child: Stack(alignment: Alignment.center, children: [
                SizedBox.expand(child: TweenAnimationBuilder<double>(tween: Tween(begin: 0, end: g.analytics.progressPercent / 100), duration: const Duration(milliseconds: 900), curve: Curves.easeOutCubic, builder: (_, v, _) => CircularProgressIndicator(value: v, strokeWidth: 14, strokeCap: StrokeCap.round, backgroundColor: context.palette.surface2))),
                Column(mainAxisSize: MainAxisSize.min, children: [Text('${g.analytics.progressPercent}%', style: context.text.headlineMedium), Text('saved', style: context.text.bodySmall)]),
              ]),
            ),
          ),
          const SizedBox(height: Space.lg),
          Center(child: MoneyText(g.saved, style: context.text.headlineSmall)),
          Center(child: Text('of ${g.target.format()} · ${g.analytics.remaining.format(compact: true)} to go', style: context.text.bodyMedium?.copyWith(color: context.palette.text2))),
          const SizedBox(height: Space.lg),
          if (g.analytics.requiredMonthly != null) PesaCard(child: Row(children: [
            Icon(g.analytics.onTrack == true ? Icons.trending_up_rounded : Icons.flag_rounded, color: g.analytics.onTrack == true ? PesaColors.emerald500 : PesaColors.gold500),
            const SizedBox(width: Space.md),
            Expanded(child: Text(g.analytics.onTrack == true ? 'On track to finish by the deadline.' : 'Save about ${g.analytics.requiredMonthly!.format(compact: true)} a month to finish on time.')),
          ])),
          if (g.analytics.projectedCompletion != null && g.status == 'ACTIVE') Padding(padding: const EdgeInsets.only(top: Space.sm), child: Text('At your current pace you\'ll finish around ${DateFormat('MMMM yyyy').format(g.analytics.projectedCompletion!)}.', style: context.text.bodySmall?.copyWith(color: context.palette.text2))),
          const SizedBox(height: Space.lg),
          if (g.status != 'ARCHIVED') Row(children: [
            Expanded(child: FilledButton.icon(onPressed: () => _entry(context, ref, g, 'CONTRIBUTION'), icon: const Icon(Icons.add_rounded), label: const Text('Add savings'))),
            const SizedBox(width: Space.md),
            Expanded(child: OutlinedButton(onPressed: g.saved.isZero ? null : () => _entry(context, ref, g, 'WITHDRAWAL'), child: const Text('Withdraw'))),
          ]),
          const SizedBox(height: Space.sm),
          Text(g.custodyNote, style: context.text.bodySmall?.copyWith(color: context.palette.text3), textAlign: TextAlign.center),
          const SectionHeader('History'),
          AsyncView(value: history, data: (list) => list.isEmpty ? const Text('No entries yet') : Column(children: [
            for (final c in list) ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(c.kind == 'CONTRIBUTION' ? Icons.south_west_rounded : Icons.north_east_rounded, color: c.kind == 'CONTRIBUTION' ? PesaColors.emerald500 : PesaColors.coral500),
              title: Text(c.note ?? (c.kind == 'CONTRIBUTION' ? 'Added' : 'Withdrawn')),
              subtitle: Text(DateFormat('d MMM yyyy').format(c.createdAt.toLocal())),
              trailing: MoneyText(c.amount, signed: c.kind == 'CONTRIBUTION' ? 'CREDIT' : 'DEBIT', compact: true),
            ),
          ])),
        ]),
      ),
    );
  }

  Future<void> _entry(BuildContext context, WidgetRef ref, SavingsGoal g, String kind) async {
    final amount = TextEditingController();
    final note = TextEditingController();
    final currency = g.target.currency;
    final ok = await showModalBottomSheet<bool>(context: context, isScrollControlled: true, builder: (c) => Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.viewInsetsOf(c).bottom),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(kind == 'CONTRIBUTION' ? 'Add to ${g.name}' : 'Withdraw from ${g.name}', style: c.text.titleLarge),
        const SizedBox(height: Space.lg),
        TextField(controller: amount, autofocus: true, keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))], decoration: InputDecoration(labelText: 'Amount', prefixText: '${Money.symbols[currency]} ')),
        const SizedBox(height: Space.md),
        TextField(controller: note, maxLength: 140, decoration: const InputDecoration(labelText: 'Note (optional)')),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Save')),
      ]),
    ));
    if (ok != true) return;
    final value = Money.normalizeInput(amount.text, currency);
    if (value == null) { if (context.mounted) showMessage(context, 'Enter a valid amount'); return; }
    try {
      await ref.read(savingsRepositoryProvider).contribute(g.id, kind, value, note.text.trim().isEmpty ? null : note.text.trim());
      ref.invalidate(goalProvider(g.id));
      ref.invalidate(contributionsProvider(g.id));
      ref.invalidate(goalsProvider);
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }
}

class GoalFormScreen extends ConsumerStatefulWidget {
  const GoalFormScreen({super.key, this.goal});
  final SavingsGoal? goal;
  @override
  ConsumerState<GoalFormScreen> createState() => _GoalFormScreenState();
}

class _GoalFormScreenState extends ConsumerState<GoalFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.goal?.name);
  late final _target = TextEditingController(text: widget.goal?.target.amount);
  late final _reminderAmount = TextEditingController(text: widget.goal?.reminder.amount?.amount);
  late String _category = widget.goal?.category ?? 'EMERGENCY';
  late DateTime? _deadline = widget.goal?.deadline;
  late String _frequency = widget.goal?.reminder.frequency ?? 'NONE';
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    _reminderAmount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.read(currentUserProvider)?.currency ?? 'KES';
    return Scaffold(
      appBar: AppBar(title: Text(widget.goal == null ? 'New goal' : 'Edit goal')),
      body: Form(
        key: _form,
        child: ListView(padding: Space.page.copyWith(bottom: 32), children: [
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final e in goalCategories.entries) ChoiceChip(avatar: Icon(goalIcon(e.key), size: 18), label: Text(e.value), selected: _category == e.key, onSelected: (_) => setState(() { _category = e.key; if (_name.text.isEmpty || goalCategories.values.contains(_name.text)) _name.text = e.value; })),
          ]),
          const SizedBox(height: Space.xl),
          TextFormField(controller: _name, maxLength: 60, decoration: const InputDecoration(labelText: 'Goal name'), validator: (v) => (v ?? '').trim().isEmpty ? 'Give your goal a name' : null),
          TextFormField(controller: _target, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'Target amount', prefixText: '${Money.symbols[currency]} '), validator: (v) => Money.normalizeInput(v ?? '', currency) == null ? 'Enter a valid amount' : null),
          const SizedBox(height: Space.lg),
          ListTile(
            contentPadding: EdgeInsets.zero, leading: const Icon(Icons.event_rounded), title: const Text('Deadline'),
            subtitle: Text(_deadline == null ? 'No deadline' : DateFormat('d MMMM yyyy').format(_deadline!)),
            trailing: _deadline == null ? null : IconButton(icon: const Icon(Icons.clear_rounded), onPressed: () => setState(() => _deadline = null)),
            onTap: () async {
              final d = await showDatePicker(context: context, firstDate: DateTime.now().add(const Duration(days: 1)), lastDate: DateTime.now().add(const Duration(days: 3650)), initialDate: _deadline ?? DateTime.now().add(const Duration(days: 90)));
              if (d != null) setState(() => _deadline = d);
            },
          ),
          const SectionHeader('Reminders'),
          SegmentedButton<String>(segments: const [ButtonSegment(value: 'NONE', label: Text('Off')), ButtonSegment(value: 'WEEKLY', label: Text('Weekly')), ButtonSegment(value: 'MONTHLY', label: Text('Monthly'))], selected: {_frequency == 'DAILY' ? 'WEEKLY' : _frequency}, onSelectionChanged: (s) => setState(() => _frequency = s.first)),
          if (_frequency != 'NONE') ...[const SizedBox(height: Space.md), TextFormField(controller: _reminderAmount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'Suggested amount (optional)', prefixText: '${Money.symbols[currency]} '))],
          const SizedBox(height: Space.xxl),
          LoadingButton(label: widget.goal == null ? 'Create goal' : 'Save changes', loading: _busy, onPressed: () async {
            if (!_form.currentState!.validate()) return;
            setState(() => _busy = true);
            final reminderAmt = Money.normalizeInput(_reminderAmount.text, currency);
            final body = {
              'name': _name.text.trim(), 'category': _category, 'target': Money.normalizeInput(_target.text, currency),
              'deadline': _deadline?.toUtc().toIso8601String(),
              'reminder': {'frequency': _frequency, if (_frequency != 'NONE' && reminderAmt != null) 'amount': reminderAmt},
            };
            try {
              final repo = ref.read(savingsRepositoryProvider);
              final g = widget.goal == null ? await repo.create(body..removeWhere((_, v) => v == null)) : await repo.update(widget.goal!.id, body);
              ref.invalidate(goalsProvider);
              if (context.mounted) widget.goal == null ? context.pushReplacement('/grow/savings/${g.id}') : context.pop();
            } catch (e) {
              if (context.mounted) showError(context, e);
            } finally {
              if (mounted) setState(() => _busy = false);
            }
          }),
        ]),
      ),
    );
  }
}
