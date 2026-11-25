import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../features/activity/data/activity_repository.dart';
import '../../features/activity/data/models.dart';
import '../../features/auth/data/auth_controller.dart';
import '../../features/home/data/dashboard.dart';
import '../../features/notifications/data/notifications.dart';
import '../config/env.dart';
import '../providers.dart';

/// Live updates over Socket.IO: payment status changes and new notifications
/// arrive instantly instead of by polling. Connected only while signed in.
class SocketService {
  SocketService(this._ref);
  final Ref _ref;
  io.Socket? _socket;

  Future<void> connect() async {
    final token = await _ref.read(secureStoreProvider).accessToken;
    if (token == null) return;
    _socket?.dispose();
    final s = io.io(Env.apiBaseUrl, io.OptionBuilder().setPath('/realtime').setTransports(['websocket']).setAuth({'token': token}).disableAutoConnect().enableReconnection().build());
    s.on('transaction.updated', (data) {
      if (data is Map<String, dynamic>) {
        final t = Txn.fromJson(data);
        _ref.read(txnListProvider.notifier).upsert(t);
        _ref.invalidate(transactionDetailProvider(t.id));
        if (t.isTerminal) _ref.invalidate(dashboardProvider);
      }
    });
    s.on('notification', (_) => _ref.invalidate(notificationsProvider));
    s.onConnectError((_) async {
      // The access token may have expired: refresh, then reconnect with the new one.
      if (await _ref.read(apiClientProvider).refreshSession()) {
        s.auth = {'token': await _ref.read(secureStoreProvider).accessToken};
      }
    });
    s.connect();
    _socket = s;
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }
}

final socketServiceProvider = Provider<SocketService>((ref) {
  final svc = SocketService(ref);
  ref.listen(authControllerProvider, (_, next) => next is Authenticated ? svc.connect() : svc.disconnect(), fireImmediately: true);
  ref.onDispose(svc.disconnect);
  return svc;
});
