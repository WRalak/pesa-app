import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import '../../../core/theme/theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../home/data/dashboard.dart';
import '../data/notifications.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  IconData _icon(String c) => switch (c) {
        'SECURITY' => Icons.shield_rounded, 'PAYMENT' || 'TRANSACTION' => Icons.receipt_long_rounded, 'SAVINGS' => Icons.savings_rounded,
        'BUDGET' => Icons.pie_chart_rounded, 'REWARD' || 'PROMOTION' => Icons.stars_rounded, _ => Icons.notifications_rounded,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = ref.watch(notificationsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications'), actions: [
        TextButton(onPressed: () async { await ref.read(notificationsRepositoryProvider).markAllRead(); ref.invalidate(notificationsProvider); ref.invalidate(dashboardProvider); }, child: const Text('Mark all read')),
        IconButton(tooltip: 'Settings', onPressed: () => context.push('/profile/notifications'), icon: const Icon(Icons.tune_rounded)),
      ]),
      body: AsyncView(value: n, onRetry: () => ref.invalidate(notificationsProvider), data: (v) {
        final (items, _) = v;
        if (items.isEmpty) return const EmptyState(icon: Icons.notifications_none_rounded, title: 'You\'re all caught up');
        return RefreshableList(onRefresh: () async => ref.invalidate(notificationsProvider), children: [
          for (final x in items) ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 4),
            leading: CircleAvatar(backgroundColor: (x.category == 'SECURITY' ? PesaColors.coral500 : context.colors.primary).withValues(alpha: .12), child: Icon(_icon(x.category), color: x.category == 'SECURITY' ? PesaColors.coral500 : context.colors.primary)),
            title: Text(x.title, style: context.text.titleSmall?.copyWith(fontWeight: x.read ? FontWeight.w500 : FontWeight.w700)),
            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(x.body), Text(DateFormat('d MMM, HH:mm').format(x.createdAt.toLocal()), style: context.text.labelSmall?.copyWith(color: context.palette.text3))]),
            trailing: x.read ? null : Container(width: 8, height: 8, decoration: const BoxDecoration(color: PesaColors.emerald500, shape: BoxShape.circle)),
            onTap: () async {
              if (!x.read) {
                await ref.read(notificationsRepositoryProvider).markRead(x.id);
                ref.invalidate(notificationsProvider);
                ref.invalidate(dashboardProvider);
              }
              final route = x.data?['route'];
              if (route is String && route.startsWith('/') && context.mounted) await context.push(route.replaceFirst('/savings', '/grow/savings').replaceFirst('/budgets', '/grow/budgets').replaceFirst('/rewards', '/grow/rewards').replaceFirst('/cards', '/grow/cards'));
            },
          ),
        ]);
      }),
    );
  }
}
