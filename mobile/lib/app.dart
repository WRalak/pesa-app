import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart' hide GlobalMaterialLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'core/app_settings.dart';
import 'core/push/push_service.dart';
import 'core/realtime/socket_service.dart';
import 'core/router.dart';
import 'core/theme/theme.dart';
import 'core/widgets/widgets.dart';
import 'features/auth/data/auth_controller.dart';
import 'l10n/app_localizations.dart';

class PesaApp extends ConsumerStatefulWidget {
  const PesaApp({super.key});
  @override
  ConsumerState<PesaApp> createState() => _PesaAppState();
}

class _PesaAppState extends ConsumerState<PesaApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ref.read(socketServiceProvider);
    final push = ref.read(pushServiceProvider);
    push.onOpenRoute = (route) => ref.read(routerProvider).push(route);
    push.init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Auto-lock after inactivity in the background (sensitive financial data).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final auth = ref.read(authControllerProvider.notifier);
    if (state == AppLifecycleState.paused) auth.onBackgrounded();
    if (state == AppLifecycleState.resumed) auth.onResumed();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    return MaterialApp.router(
      title: 'Pesa',
      debugShowCheckedModeBanner: false,
      theme: PesaTheme.light(),
      darkTheme: PesaTheme.dark(),
      themeMode: settings.themeMode,
      locale: settings.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        // Still required for iOS text-selection menus; migrate with cupertino_ui.
        // ignore: deprecated_member_use
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: Theme.of(context).brightness == Brightness.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        // Caps text scaling so layouts stay usable on small Android devices while honouring accessibility.
        child: MediaQuery.withClampedTextScaling(maxScaleFactor: 1.4, child: SandboxBanner(child: child!)),
      ),
    );
  }
}
