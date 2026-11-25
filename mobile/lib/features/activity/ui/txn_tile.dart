import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import '../../../core/theme/theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../data/models.dart';

IconData iconForType(String type) => switch (type) {
      'SEND_MONEY' => Icons.north_east_rounded,
      'RECEIVE_MONEY' => Icons.south_west_rounded,
      'PAYBILL' => Icons.receipt_long_rounded,
      'BUY_GOODS' => Icons.storefront_rounded,
      'AIRTIME' => Icons.phone_android_rounded,
      'UTILITY' => Icons.bolt_rounded,
      'DEPOSIT' => Icons.add_rounded,
      'CARD_PAYMENT' => Icons.credit_card_rounded,
      'BANK_TRANSFER' => Icons.account_balance_rounded,
      _ => Icons.swap_horiz_rounded,
    };

class TxnTile extends StatelessWidget {
  const TxnTile(this.t, {super.key, this.hideAmount = false});
  final Txn t;
  final bool hideAmount;
  @override
  Widget build(BuildContext context) {
    final failed = t.status == 'FAILED';
    final color = t.direction == 'CREDIT' ? PesaColors.emerald500 : context.colors.secondary;
    return InkWell(
      onTap: () => context.push('/activity/${t.id}'),
      borderRadius: BorderRadius.circular(Radii.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: (t.direction == 'CREDIT' ? PesaColors.emerald500 : PesaColors.navy700).withValues(alpha: .1), borderRadius: BorderRadius.circular(14)),
            child: Icon(iconForType(t.type), color: t.direction == 'CREDIT' ? PesaColors.emerald600 : context.colors.onSurface, size: 22),
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.titleSmall),
              const SizedBox(height: 2),
              Row(children: [
                Text(DateFormat('d MMM, HH:mm').format(t.createdAt.toLocal()), style: context.text.bodySmall?.copyWith(color: context.palette.text3)),
                if (t.status != 'SUCCESSFUL') ...[const SizedBox(width: 6), StatusChip(t.status)],
              ]),
            ]),
          ),
          MoneyText(t.total, hidden: hideAmount, signed: failed ? null : t.direction, compact: true,
              style: context.text.titleSmall?.copyWith(color: failed ? context.palette.text3 : t.direction == 'CREDIT' ? color : null, decoration: failed ? TextDecoration.lineThrough : null)),
        ]),
      ),
    );
  }
}
