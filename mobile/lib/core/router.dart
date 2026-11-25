import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../features/activity/ui/activity_screens.dart';
import '../features/auth/data/auth_controller.dart';
import '../features/auth/ui/auth_screens.dart';
import '../features/budgets/data/budgets.dart';
import '../features/budgets/ui/budget_screens.dart';
import '../features/cards/data/cards.dart';
import '../features/cards/ui/cards_screens.dart';
import '../features/home/ui/grow_screen.dart';
import '../features/home/ui/home_screen.dart';
import '../features/notifications/ui/notifications_screen.dart';
import '../features/payments/ui/payment_screens.dart';
import '../features/profile/ui/profile_screens.dart';
import '../features/rewards/ui/rewards_screen.dart';
import '../features/savings/data/savings.dart';
import '../features/savings/ui/savings_screens.dart';
import '../l10n/app_localizations.dart';
import 'widgets/widgets.dart';

/// Bridges Riverpod auth state to GoRouter's refreshListenable.
class _AuthListenable extends ChangeNotifier {
  _AuthListenable(Ref ref) {
    ref.listen(authControllerProvider, (_, _) => notifyListeners());
  }
}

const _publicRoutes = {'/login', '/register', '/verify', '/forgot-password', '/recovery', '/onboarding'};

final routerProvider = Provider<GoRouter>((ref) {
  final listenable = _AuthListenable(ref);
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: listenable,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final loc = state.matchedLocation;
      switch (auth) {
        case AuthUnknown():
          return loc == '/splash' ? null : '/splash';
        case Unauthenticated(:final onboarded, :final pending):
          if (!onboarded) return loc == '/onboarding' ? null : '/onboarding';
          if (pending != null && loc != '/verify') return '/verify';
          if (pending == null && loc == '/verify') return '/login';
          return _publicRoutes.contains(loc) && loc != '/onboarding' ? null : '/login';
        case Locked():
          return loc == '/lock' ? null : '/lock';
        case Authenticated(:final user):
          if (!user.hasPin) return loc == '/create-pin' ? null : '/create-pin';
          if (loc == '/splash' || loc == '/lock' || loc == '/create-pin' || _publicRoutes.contains(loc)) return '/home';
          return null;
      }
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(path: '/verify', builder: (_, _) => const OtpScreen()),
      GoRoute(path: '/forgot-password', builder: (_, _) => const ForgotPasswordScreen()),
      GoRoute(path: '/recovery', builder: (_, _) => const RecoveryScreen()),
      GoRoute(path: '/create-pin', builder: (_, _) => const CreatePinScreen()),
      GoRoute(path: '/lock', builder: (_, _) => const LockScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => _Shell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (_, _) => const HomeScreen())]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/activity', builder: (_, _) => const ActivityScreen(), routes: [
              GoRoute(path: ':id', builder: (_, s) => TransactionDetailScreen(id: s.pathParameters['id']!)),
            ]),
          ]),
          StatefulShellBranch(routes: [GoRoute(path: '/pay', builder: (_, _) => const PayHubScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/grow', builder: (_, _) => const GrowScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen())]),
        ],
      ),
      // Full-screen flows pushed above the shell.
      GoRoute(path: '/pay/receive', builder: (_, _) => const ReceiveScreen()),
      GoRoute(path: '/pay/status/:id', builder: (_, s) => PaymentStatusScreen(id: s.pathParameters['id']!, message: s.extra as String?)),
      GoRoute(path: '/pay/:kind', builder: (_, s) => PaymentFormScreen(kind: s.pathParameters['kind']!, utilityCode: s.uri.queryParameters['code'], utilityName: s.uri.queryParameters['name'])),
      GoRoute(path: '/notifications', builder: (_, _) => const NotificationsScreen()),
      GoRoute(path: '/grow/savings', builder: (_, _) => const SavingsScreen()),
      GoRoute(path: '/grow/savings/new', builder: (_, _) => const GoalFormScreen()),
      GoRoute(path: '/grow/savings/:id', builder: (_, s) => GoalDetailScreen(id: s.pathParameters['id']!)),
      GoRoute(path: '/grow/savings/:id/edit', builder: (_, s) => GoalFormScreen(goal: s.extra as SavingsGoal?)),
      GoRoute(path: '/grow/budgets', builder: (_, _) => const BudgetsScreen()),
      GoRoute(path: '/grow/budgets/new', builder: (_, s) => BudgetFormScreen(budget: s.extra as Budget?)),
      GoRoute(path: '/grow/insights', builder: (_, _) => const InsightsScreen()),
      GoRoute(path: '/grow/rewards', builder: (_, _) => const RewardsScreen()),
      GoRoute(path: '/grow/cards', builder: (_, _) => const CardsScreen()),
      GoRoute(path: '/grow/cards/:id', builder: (_, s) => s.extra is PaymentCard ? CardDetailScreen(card: s.extra! as PaymentCard) : _CardLoader(id: s.pathParameters['id']!)),
      GoRoute(path: '/profile/personal', builder: (_, _) => const PersonalInfoScreen()),
      GoRoute(path: '/profile/kyc', builder: (_, _) => const KycScreen()),
      GoRoute(path: '/profile/accounts', builder: (_, _) => const LinkedAccountsScreen()),
      GoRoute(path: '/profile/security', builder: (_, _) => const SecurityScreen()),
      GoRoute(path: '/profile/devices', builder: (_, _) => const DevicesScreen()),
      GoRoute(path: '/profile/notifications', builder: (_, _) => const NotificationSettingsScreen()),
      GoRoute(path: '/profile/privacy', builder: (_, _) => const PrivacyScreen()),
      GoRoute(path: '/profile/close', builder: (_, _) => const CloseAccountScreen()),
      GoRoute(path: '/profile/limits', builder: (_, _) => const LimitsScreen()),
      GoRoute(path: '/profile/appearance', builder: (_, _) => const AppearanceScreen()),
      GoRoute(path: '/profile/support', builder: (_, _) => const SupportScreen()),
      GoRoute(path: '/profile/support/new', builder: (_, s) => NewTicketScreen(transactionId: s.uri.queryParameters['transactionId'], subject: s.uri.queryParameters['subject'])),
      GoRoute(path: '/profile/support/:id', builder: (_, s) => TicketScreen(id: s.pathParameters['id']!)),
    ],
  );
});

class _CardLoader extends ConsumerWidget {
  const _CardLoader({required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        body: AsyncView(value: ref.watch(cardsProvider), data: (v) {
          final match = v.$1.where((c) => c.id == id);
          return match.isEmpty ? const ErrorState(message: 'Card not found') : CardDetailScreen(card: match.first);
        }),
      );
}

class _Shell extends StatelessWidget {
  const _Shell({required this.shell});
  final StatefulNavigationShell shell;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home_rounded), label: l.navHome),
          NavigationDestination(icon: const Icon(Icons.receipt_long_outlined), selectedIcon: const Icon(Icons.receipt_long_rounded), label: l.navActivity),
          NavigationDestination(icon: const Icon(Icons.swap_horizontal_circle_outlined), selectedIcon: const Icon(Icons.swap_horizontal_circle_rounded), label: l.navPay),
          NavigationDestination(icon: const Icon(Icons.trending_up_rounded), selectedIcon: const Icon(Icons.trending_up_rounded), label: l.navGrow),
          NavigationDestination(icon: const Icon(Icons.person_outline_rounded), selectedIcon: const Icon(Icons.person_rounded), label: l.navProfile),
        ],
      ),
    );
  }
}
