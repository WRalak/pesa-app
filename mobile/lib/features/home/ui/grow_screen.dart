import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../core/theme/theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';

class GrowScreen extends StatelessWidget {
  const GrowScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final items = [
      (Icons.savings_rounded, l.savingsGoals, 'Track goals like rent, school fees and emergencies', '/grow/savings', PesaColors.emerald500),
      (Icons.pie_chart_rounded, l.budgets, 'Weekly and monthly limits with alerts', '/grow/budgets', PesaColors.sky500),
      (Icons.auto_awesome_rounded, l.insights, 'Monthly report, patterns and suggestions', '/grow/insights', PesaColors.violet500),
      (Icons.stars_rounded, l.rewards, 'Points, cashback and referrals', '/grow/rewards', PesaColors.gold500),
      (Icons.credit_card_rounded, l.cards, 'Virtual and linked cards with controls', '/grow/cards', PesaColors.coral500),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l.navGrow)),
      body: ListView.separated(
        padding: Space.page.copyWith(bottom: 32),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: Space.md),
        itemBuilder: (_, i) {
          final (icon, title, sub, route, color) = items[i];
          return PesaCard(
            onTap: () => context.push(route),
            child: Row(children: [
              Container(width: 48, height: 48, decoration: BoxDecoration(color: color.withValues(alpha: .14), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: color)),
              const SizedBox(width: Space.lg),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: context.text.titleMedium), Text(sub, style: context.text.bodySmall?.copyWith(color: context.palette.text2))])),
              const Icon(Icons.chevron_right_rounded),
            ]),
          );
        },
      ),
    );
  }
}
