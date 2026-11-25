import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'app.dart';
import 'core/network/api_exception.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(ProviderScope(
    // Don't auto-retry client errors (4xx); network/5xx get a short backoff.
    retry: (count, error) => error is ApiException && error.status >= 400 && error.status < 500 ? null : (count < 2 ? Duration(milliseconds: 400 * (count + 1)) : null),
    child: const PesaApp(),
  ));
}
