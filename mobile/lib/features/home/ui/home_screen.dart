import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import '../../../core/theme/theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../activity/ui/txn_tile.dart';
import '../../budgets/data/budgets.dart';
import '../data/dashboard.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool? _hidden;

  @override
  Widget build(BuildContext context) {
    final dash = ref.watch(dashboardProvider);
    return Scaffold(
      body: SafeArea(
        child: AsyncView(
          value: dash,
          onRetry: () => ref.invalidate(dashboardProvider),
          data: (d) {
            final hidden = _hidden ?? d.hideBalances;
            return RefreshableList(
              onRefresh: () async => ref.refresh(dashboardProvider.future),
              children: [
                _Header(name: d.greetingName, unread: d.unreadNotifications),
                const SizedBox(height: Space.lg),
                _BalanceHero(d: d, hidden: hidden, onToggle: () => setState(() => _hidden = !hidden)),
                if (d.pendingTransactions > 0) ...[
                  const SizedBox(height: Space.md),
                  PesaCard(
                    color: PesaColors.gold500.withValues(alpha: .12),
                    onTap: () => context.go('/activity'),
                    child: Row(children: [
                      const Icon(Icons.hourglass_top_rounded, color: PesaColors.warning),
                      const SizedBox(width: Space.md),
                      Expanded(child: Text('${d.pendingTransactions} payment${d.pendingTransactions == 1 ? '' : 's'} awaiting provider confirmation', style: context.text.bodyMedium)),
                      const Icon(Icons.chevron_right_rounded),
                    ]),
                  ),
                ],
                const SizedBox(height: Space.xl),
                const _QuickActions(),
                _MonthCard(m: d.month, hidden: hidden),
                if (d.month.byCategory.isNotEmpty) _CategoryCard(m: d.month, hidden: hidden),
                if (d.savings?['goals'] is List && (d.savings!['goals'] as List).isNotEmpty) _SavingsPreview(d.savings!, hidden: hidden),
                if (d.budget != null) _BudgetPreview(Budget.fromJson(d.budget!), hidden: hidden),
                SectionHeader(AppLocalizations.of(context).recentActivity, action: AppLocalizations.of(context).seeAll, onAction: () => context.go('/activity')),
                if (d.recentTransactions.isEmpty)
                  const EmptyState(icon: Icons.receipt_long_rounded, title: 'No activity yet', message: 'Your payments will appear here.')
                else
                  ...d.recentTransactions.map((t) => TxnTile(t, hideAmount: hidden)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({this.name, required this.unread});
  final String? name;
  final int unread;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final h = DateTime.now().hour;
    final greet = h < 12 ? l.goodMorning : h < 17 ? l.goodAfternoon : l.goodEvening;
    return Row(children: [
      CircleAvatar(radius: 22, backgroundColor: context.colors.primaryContainer, child: Text((name ?? 'P').characters.first.toUpperCase(), style: context.text.titleMedium?.copyWith(color: context.colors.primary))),
      const SizedBox(width: Space.md),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(greet, style: context.text.bodySmall?.copyWith(color: context.palette.text2)),
        Text(name ?? 'there', style: context.text.titleLarge),
      ])),
      IconButton(
        tooltip: 'Notifications',
        onPressed: () => context.push('/notifications'),
        icon: Badge(isLabelVisible: unread > 0, label: Text('$unread'), child: const Icon(Icons.notifications_none_rounded)),
      ),
    ]);
  }
}

class _BalanceHero extends StatelessWidget {
  const _BalanceHero({required this.d, required this.hidden, required this.onToggle});
  final Dashboard d;
  final bool hidden;
  final VoidCallback onToggle;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final v = d.verified;
    return Container(
      padding: const EdgeInsets.all(Space.xl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Radii.xl),
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [PesaColors.navy900, PesaColors.navy700]),
        boxShadow: [BoxShadow(color: PesaColors.navy900.withValues(alpha: .25), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.verified_rounded, size: 16, color: PesaColors.emerald500),
          const SizedBox(width: 6),
          Text(l.verifiedBalance, style: context.text.labelLarge?.copyWith(color: const Color(0xFFA9C0D4))),
          if (v.sandbox) ...[const SizedBox(width: 8), _chip('SANDBOX', PesaColors.gold500)],
          const Spacer(),
          IconButton(onPressed: onToggle, tooltip: hidden ? 'Show balances' : 'Hide balances', icon: Icon(hidden ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.white70, size: 20)),
        ]),
        if (v.total != null) ...[
          MoneyText(v.total!, hidden: hidden, style: context.text.displaySmall?.copyWith(color: Colors.white, fontSize: 36)),
          const SizedBox(height: 4),
          Text('${v.accountCount} linked account${v.accountCount == 1 ? '' : 's'}${v.oldestAsOf != null ? ' · as of ${DateFormat('d MMM, HH:mm').format(v.oldestAsOf!.toLocal())}' : ''}', style: context.text.bodySmall?.copyWith(color: const Color(0xFF8EA2B6))),
        ] else ...[
          const SizedBox(height: 4),
          Text(l.noLinkedAccounts, style: context.text.titleMedium?.copyWith(color: Colors.white)),
          const SizedBox(height: Space.md),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white30), minimumSize: const Size(0, 42)),
            onPressed: () => context.push('/profile/accounts'),
            icon: const Icon(Icons.link_rounded, size: 18),
            label: const Text('Link account'),
          ),
        ],
        if (d.manual.total != null) ...[
          const SizedBox(height: Space.md),
          const Divider(color: Colors.white12),
          const SizedBox(height: Space.sm),
          Row(children: [
            Text(l.manualBalance, style: context.text.bodySmall?.copyWith(color: const Color(0xFF8EA2B6))),
            const Spacer(),
            MoneyText(d.manual.total!, hidden: hidden, style: context.text.titleSmall?.copyWith(color: Colors.white)),
          ]),
        ],
      ]),
    );
  }

  Widget _chip(String t, Color c) => Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1), decoration: BoxDecoration(color: c.withValues(alpha: .2), borderRadius: BorderRadius.circular(6)), child: Text(t, style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w800)));
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final actions = [
      (Icons.north_east_rounded, l.sendMoney, '/pay/send', PesaColors.emerald500),
      (Icons.qr_code_2_rounded, l.receiveMoney, '/pay/receive', PesaColors.sky500),
      (Icons.add_rounded, l.addMoney, '/pay/deposit', PesaColors.violet500),
      (Icons.phone_android_rounded, l.buyAirtime, '/pay/airtime', PesaColors.coral500),
      (Icons.receipt_long_rounded, l.payBills, '/pay', PesaColors.gold500),
      (Icons.savings_rounded, l.saveMoney, '/grow/savings', const Color(0xFF14B8A6)),
    ];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: Space.md,
      crossAxisSpacing: Space.md,
      childAspectRatio: 1.15,
      children: [
        for (final (icon, label, route, color) in actions)
          PesaCard(
            padding: const EdgeInsets.all(Space.md),
            onTap: () => context.push(route),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withValues(alpha: .14), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 22)),
              const SizedBox(height: Space.sm),
              Text(label, style: context.text.labelLarge, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
      ],
    );
  }
}

class _MonthCard extends StatelessWidget {
  const _MonthCard({required this.m, required this.hidden});
  final MonthSummary m;
  final bool hidden;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final spots = <FlSpot>[];
    var cum = 0;
    for (var i = 0; i < m.daily.length; i++) {
      cum += m.daily[i].spent.amountMinor;
      spots.add(FlSpot(i.toDouble(), cum / 100));
    }
    return Padding(
      padding: const EdgeInsets.only(top: Space.xl),
      child: PesaCard(
        onTap: () => context.push('/grow/insights'),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(l.thisMonth, style: context.text.titleMedium),
            const SizedBox(width: 8),
            Tooltip(message: m.basisNote ?? '', child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: context.palette.surface2, borderRadius: BorderRadius.circular(99)), child: Text(l.estimated, style: context.text.labelSmall))),
            const Spacer(),
            if (m.changeInExpensesPercent != null)
              Text('${m.changeInExpensesPercent! > 0 ? '▲' : '▼'} ${m.changeInExpensesPercent!.abs().toStringAsFixed(0)}%', style: context.text.labelLarge?.copyWith(color: m.changeInExpensesPercent! > 0 ? PesaColors.coral500 : PesaColors.emerald600)),
          ]),
          const SizedBox(height: Space.md),
          Row(children: [
            Expanded(child: _stat(context, l.income, m.income, PesaColors.emerald500)),
            Expanded(child: _stat(context, l.expenses, m.expenses, PesaColors.coral500)),
          ]),
          if (spots.length > 1) ...[
            const SizedBox(height: Space.lg),
            SizedBox(
              height: 90,
              child: LineChart(LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineTouchData: const LineTouchData(enabled: false),
                lineBarsData: [LineChartBarData(spots: spots, isCurved: true, preventCurveOverShooting: true, barWidth: 2.5, color: PesaColors.emerald500, dotData: const FlDotData(show: false), belowBarData: BarAreaData(show: true, gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [PesaColors.emerald500.withValues(alpha: .25), PesaColors.emerald500.withValues(alpha: 0)])))],
              )),
            ),
            Text('Cumulative spending this month', style: context.text.bodySmall?.copyWith(color: context.palette.text3)),
          ],
        ]),
      ),
    );
  }

  Widget _stat(BuildContext context, String label, Money v, Color c) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)), const SizedBox(width: 6), Text(label, style: context.text.bodySmall?.copyWith(color: context.palette.text2))]),
        const SizedBox(height: 4),
        MoneyText(v, hidden: hidden, compact: true, style: context.text.titleLarge),
      ]);
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.m, required this.hidden});
  final MonthSummary m;
  final bool hidden;
  @override
  Widget build(BuildContext context) {
    final cats = m.byCategory.take(5).toList();
    return Padding(
      padding: const EdgeInsets.only(top: Space.md),
      child: PesaCard(
        child: Row(children: [
          SizedBox(
            width: 110, height: 110,
            child: PieChart(PieChartData(sectionsSpace: 2, centerSpaceRadius: 32, sections: [
              for (var i = 0; i < cats.length; i++) PieChartSectionData(value: cats[i].amount.amountMinor.toDouble(), color: PesaColors.chart[i % PesaColors.chart.length], radius: 18, showTitle: false),
            ])),
          ),
          const SizedBox(width: Space.lg),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Where it went', style: context.text.titleSmall),
              const SizedBox(height: Space.sm),
              for (var i = 0; i < cats.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: PesaColors.chart[i % PesaColors.chart.length], shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Expanded(child: Text(categoryLabel(cats[i].category), style: context.text.bodySmall, overflow: TextOverflow.ellipsis)),
                    Text('${cats[i].share.toStringAsFixed(0)}%', style: context.text.labelMedium),
                  ]),
                ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _SavingsPreview extends StatelessWidget {
  const _SavingsPreview(this.s, {required this.hidden});
  final Map<String, dynamic> s;
  final bool hidden;
  @override
  Widget build(BuildContext context) {
    final goals = (s['goals'] as List).cast<Map<String, dynamic>>();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionHeader(AppLocalizations.of(context).savingsGoals, action: AppLocalizations.of(context).seeAll, onAction: () => context.push('/grow/savings')),
      SizedBox(
        height: 120,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: goals.length,
          separatorBuilder: (_, _) => const SizedBox(width: Space.md),
          itemBuilder: (_, i) {
            final g = goals[i];
            final pct = (g['analytics'] as Map<String, dynamic>)['progressPercent'] as int;
            return SizedBox(
              width: 200,
              child: PesaCard(
                onTap: () => context.push('/grow/savings/${g['id']}'),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('${g['name']}', style: context.text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  MoneyText(Money.fromJson(g['saved'] as Map<String, dynamic>), hidden: hidden, compact: true),
                  ProgressBar(percent: pct),
                  Text('$pct% of ${hidden ? '••••' : Money.fromJson(g['target'] as Map<String, dynamic>).format(compact: true)}', style: context.text.bodySmall?.copyWith(color: context.palette.text3)),
                ]),
              ),
            );
          },
        ),
      ),
    ]);
  }
}

class _BudgetPreview extends StatelessWidget {
  const _BudgetPreview(this.b, {required this.hidden});
  final Budget b;
  final bool hidden;
  @override
  Widget build(BuildContext context) => Column(children: [
        SectionHeader(AppLocalizations.of(context).budgets, action: AppLocalizations.of(context).seeAll, onAction: () => context.push('/grow/budgets')),
        PesaCard(
          onTap: () => context.push('/grow/budgets'),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(b.name, style: context.text.titleSmall)),
              Text(b.onPace ? 'On track' : 'Spending fast', style: context.text.labelMedium?.copyWith(color: b.onPace ? PesaColors.emerald600 : PesaColors.coral500)),
            ]),
            const SizedBox(height: Space.sm),
            ProgressBar(percent: b.percentUsed),
            const SizedBox(height: Space.sm),
            Text(hidden ? '${b.percentUsed}% used' : '${b.spent.format(compact: true)} of ${b.totalLimit.format(compact: true)} · ${b.periodElapsedPercent}% of period elapsed', style: context.text.bodySmall?.copyWith(color: context.palette.text2)),
          ]),
        ),
      ]);
}
