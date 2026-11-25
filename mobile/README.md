# Pesa — Flutter app

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # Freezed / JSON models
flutter gen-l10n                                           # English + Swahili
flutter run --dart-define=ENV=dev --dart-define=API_BASE_URL=http://10.0.2.2:4000
flutter analyze && flutter test
```

Structure: `lib/core` (config, theme, network, storage, security, realtime, push, router, shared widgets) and `lib/features/<feature>/{data,ui}`. See [../docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md#mobile-architecture-mobilelib).
