import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/widgets.dart';
import '../data/rewards.dart';

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = ref.watch(rewardsProvider);
    final history = ref.watch(rewardHistoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Rewards')),
      body: AsyncView(value: r, onRetry: () => ref.invalidate(rewardsProvider), data: (d) {
        final cash = d['cashback'] as Map<String, dynamic>;
        final ref0 = d['referral'] as Map<String, dynamic>;
        final points = d['points'] as int;
        return RefreshableList(onRefresh: () async { ref.invalidate(rewardsProvider); ref.invalidate(rewardHistoryProvider); }, children: [
          Container(
            padding: const EdgeInsets.all(Space.xl),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(Radii.xl), gradient: const LinearGradient(colors: [Color(0xFF3B2A06), PesaColors.navy900], begin: Alignment.topLeft, end: Alignment.bottomRight)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [const Icon(Icons.stars_rounded, color: PesaColors.gold500), const SizedBox(width: 6), Text('Pesa Points', style: context.text.labelLarge?.copyWith(color: PesaColors.gold500))]),
              const SizedBox(height: Space.sm),
              Text(NumberFormat.decimalPattern().format(points), style: context.text.displaySmall?.copyWith(color: Colors.white)),
              Text('${NumberFormat.decimalPattern().format(d['lifetimePoints'])} earned all-time', style: context.text.bodySmall?.copyWith(color: Colors.white60)),
              const SizedBox(height: Space.lg),
              Row(children: [
                Expanded(child: _stat(context, 'Cashback available', Money.fromJson(cash['available'] as Map<String, dynamic>))),
                Expanded(child: _stat(context, 'Pending', Money.fromJson(cash['pending'] as Map<String, dynamic>))),
              ]),
              const SizedBox(height: Space.sm),
              Text('${cash['note']}', style: context.text.bodySmall?.copyWith(color: Colors.white54)),
            ]),
          ),
          const SectionHeader('Redeem points'),
          for (final (code, label, cost) in const [('AIRTIME_50', 'KSh 50 airtime', 500), ('AIRTIME_100', 'KSh 100 airtime', 1000), ('DATA_1GB', '1 GB data bundle', 1500)])
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.redeem_rounded),
              title: Text(label),
              subtitle: Text('$cost points'),
              trailing: FilledButton.tonal(onPressed: points < cost ? null : () async {
                try {
                  final res = await ref.read(rewardsRepositoryProvider).redeem(code, cost);
                  ref.invalidate(rewardsProvider);
                  ref.invalidate(rewardHistoryProvider);
                  if (context.mounted) showMessage(context, '${res['note']}');
                } catch (e) {
                  if (context.mounted) showError(context, e);
                }
              }, child: const Text('Redeem')),
            ),
          const SectionHeader('Invite friends'),
          PesaCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(ref0['rewardPoints'] != null ? 'Earn ${ref0['rewardPoints']} points when a friend makes their first payment.' : 'Share Pesa with friends.', style: context.text.bodyMedium),
            const SizedBox(height: Space.md),
            Row(children: [
              Expanded(child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), decoration: BoxDecoration(color: context.palette.surface2, borderRadius: BorderRadius.circular(Radii.sm)), child: Text('${ref0['code']}', style: context.text.titleLarge?.copyWith(letterSpacing: 3)))),
              IconButton(tooltip: 'Copy code', onPressed: () { Clipboard.setData(ClipboardData(text: '${ref0['code']}')); showMessage(context, 'Code copied'); }, icon: const Icon(Icons.copy_rounded)),
              IconButton.filled(tooltip: 'Share', onPressed: () => SharePlus.instance.share(ShareParams(text: '${ref0['shareMessage']}')), icon: const Icon(Icons.share_rounded)),
            ]),
            const SizedBox(height: Space.md),
            Text('${ref0['invited']} invited · ${ref0['rewarded']} rewarded · ${ref0['pending']} pending', style: context.text.bodySmall?.copyWith(color: context.palette.text2)),
          ])),
          if ((d['offers'] as List).isNotEmpty) ...[
            const SectionHeader('Offers'),
            for (final o in (d['offers'] as List).cast<Map<String, dynamic>>())
              Padding(padding: const EdgeInsets.only(bottom: Space.md), child: PesaCard(child: Row(children: [
                Container(width: 44, height: 44, decoration: BoxDecoration(color: PesaColors.gold500.withValues(alpha: .15), borderRadius: BorderRadius.circular(12)), child: Icon(o['type'] == 'CASHBACK' ? Icons.percent_rounded : o['type'] == 'PARTNER_DEAL' ? Icons.handshake_rounded : Icons.stars_rounded, color: PesaColors.gold500)),
                const SizedBox(width: Space.md),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${o['name']}', style: context.text.titleSmall),
                  if (o['description'] != null) Text('${o['description']}', style: context.text.bodySmall?.copyWith(color: context.palette.text2)),
                  if (o['endsAt'] != null) Text('Ends ${DateFormat('d MMM').format(DateTime.parse('${o['endsAt']}'))}', style: context.text.labelSmall?.copyWith(color: context.palette.text3)),
                ])),
              ]))),
          ],
          const SectionHeader('History'),
          AsyncView(value: history, data: (h) => h.isEmpty ? const Text('No rewards yet — they appear after your payments complete.') : Column(children: [
            for (final e in h) ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${e['description'] ?? e['entryType']}'),
              subtitle: Text(DateFormat('d MMM yyyy').format(DateTime.parse('${e['createdAt']}').toLocal())),
              trailing: Text(e['kind'] == 'POINTS' ? '${(e['points'] as int) > 0 ? '+' : ''}${e['points']} pts' : Money.fromJson(e['amount'] as Map<String, dynamic>).format(compact: true), style: context.text.titleSmall),
            ),
          ])),
        ]);
      }),
    );
  }

  Widget _stat(BuildContext context, String label, Money m) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: context.text.bodySmall?.copyWith(color: Colors.white60)),
        MoneyText(m, compact: true, style: context.text.titleMedium?.copyWith(color: Colors.white)),
      ]);
}
