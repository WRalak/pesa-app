import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'network/api_client.dart';
import 'security/biometric_service.dart';
import 'storage/secure_store.dart';

/// Infrastructure providers. Overridden in tests with fakes.
final secureStoreProvider = Provider<SecureStore>((ref) => SecureStore());
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(ref.watch(secureStoreProvider)));
final biometricServiceProvider = Provider<BiometricService>((ref) => BiometricService());
