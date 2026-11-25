import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import 'auth_models.dart';
import 'auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository(ref.watch(apiClientProvider), ref.watch(secureStoreProvider)));

sealed class AuthState { const AuthState(); }
class AuthUnknown extends AuthState { const AuthUnknown(); }
class Unauthenticated extends AuthState { const Unauthenticated({required this.onboarded, this.pending}); final bool onboarded; final PendingOtp? pending; }
class Locked extends AuthState { const Locked(this.user); final AppUser user; }
class Authenticated extends AuthState { const Authenticated(this.user, this.profile); final AppUser user; final Profile? profile; }

/// Owns the session lifecycle: bootstrap, sign-in, OTP steps, app lock and
/// sign-out. The router redirects purely from this state.
class AuthController extends Notifier<AuthState> {
  late final AuthRepository _repo = ref.read(authRepositoryProvider);
  DateTime? _backgroundedAt;
  static const lockAfter = Duration(minutes: 2);

  @override
  AuthState build() {
    ref.read(apiClientProvider).onSessionExpired = () {
      if (state is Authenticated || state is Locked) state = const Unauthenticated(onboarded: true);
    };
    Future.microtask(bootstrap);
    return const AuthUnknown();
  }

  Future<void> bootstrap() async {
    final store = ref.read(secureStoreProvider);
    final onboarded = await store.onboarded;
    if (await store.refreshToken == null) {
      state = Unauthenticated(onboarded: onboarded);
      return;
    }
    try {
      final (user, profile) = await _repo.me();
      state = await store.biometricEnabled ? Locked(user) : Authenticated(user, profile);
    } catch (_) {
      state = Unauthenticated(onboarded: onboarded);
    }
  }

  Future<void> completeOnboarding() async {
    await ref.read(secureStoreProvider).setOnboarded();
    state = const Unauthenticated(onboarded: true);
  }

  void setPending(PendingOtp? p) => state = Unauthenticated(onboarded: true, pending: p);

  Future<void> _afterLogin(LoginResult r) async {
    switch (r) {
      case LoggedIn():
        final (user, profile) = await _repo.me();
        state = Authenticated(user, profile);
      case NeedsOtp(:final pending):
        setPending(pending);
    }
  }

  Future<void> login(String phone, String password) async => _afterLogin(await _repo.login(phone, password));

  Future<void> register({required String phone, required String password, required String firstName, required String lastName, String? email, String? referralCode, required bool marketingConsent, required String locale}) async {
    setPending(await _repo.register(phone: phone, password: password, firstName: firstName, lastName: lastName, email: email, referralCode: referralCode, marketingConsent: marketingConsent, locale: locale));
  }

  Future<void> verifyOtp(String code) async {
    final p = switch (state) { Unauthenticated(:final pending) => pending, _ => null };
    if (p == null) throw StateError('No pending verification');
    await _afterLogin(await _repo.verifyOtp(p, code));
  }

  Future<void> refreshUser() async {
    final (user, profile) = await _repo.me();
    state = Authenticated(user, profile);
  }

  /// Unlock with biometrics (local) — the session itself is still validated server-side.
  Future<bool> unlockWithBiometrics(String reason) async {
    final ok = await ref.read(biometricServiceProvider).authenticate(reason);
    if (ok) await refreshUser();
    return ok;
  }

  /// Unlock with the transaction PIN, verified by the server (lockout applies).
  Future<void> unlockWithPin(String pin) async {
    await _repo.verifyPin(pin);
    await refreshUser();
  }

  void onBackgrounded() => _backgroundedAt = DateTime.now();

  Future<void> onResumed() async {
    final at = _backgroundedAt;
    _backgroundedAt = null;
    final s = state;
    if (at == null || s is! Authenticated) return;
    if (DateTime.now().difference(at) > lockAfter && s.user.hasPin) state = Locked(s.user);
  }

  Future<void> logout({bool everywhere = false}) async {
    await _repo.logout(everywhere: everywhere);
    state = const Unauthenticated(onboarded: true);
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);

final currentUserProvider = Provider<AppUser?>((ref) => switch (ref.watch(authControllerProvider)) { Authenticated(:final user) => user, _ => null });
