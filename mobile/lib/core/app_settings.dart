import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'providers.dart';

/// Theme and language preferences (persisted locally).
class AppSettings {
  const AppSettings({this.themeMode = ThemeMode.system, this.locale});
  final ThemeMode themeMode;
  final Locale? locale;
}

class AppSettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    Future.microtask(_load);
    return const AppSettings();
  }

  Future<void> _load() async {
    final store = ref.read(secureStoreProvider);
    final mode = await store.themeMode;
    final loc = await store.locale;
    state = AppSettings(themeMode: ThemeMode.values.firstWhere((m) => m.name == mode, orElse: () => ThemeMode.system), locale: loc == null ? null : Locale(loc));
    if (loc != null) ref.read(apiClientProvider).locale = loc == 'sw' ? 'sw-KE' : 'en-KE';
  }

  Future<void> setTheme(ThemeMode m) async {
    state = AppSettings(themeMode: m, locale: state.locale);
    await ref.read(secureStoreProvider).setThemeMode(m.name);
  }

  Future<void> setLocale(String code) async {
    state = AppSettings(themeMode: state.themeMode, locale: Locale(code));
    ref.read(apiClientProvider).locale = code == 'sw' ? 'sw-KE' : 'en-KE';
    await ref.read(secureStoreProvider).setLocale(code);
  }
}

final appSettingsProvider = NotifierProvider<AppSettingsController, AppSettings>(AppSettingsController.new);
