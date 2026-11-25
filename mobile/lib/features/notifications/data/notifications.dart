import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers.dart';

part 'notifications.freezed.dart';
part 'notifications.g.dart';

@freezed
abstract class AppNotification with _$AppNotification {
  const factory AppNotification({required String id, required String category, required String type, required String title, required String body, Map<String, dynamic>? data, required bool read, required DateTime createdAt}) = _AppNotification;
  factory AppNotification.fromJson(Map<String, dynamic> json) => _$AppNotificationFromJson(json);
}

class NotificationsRepository {
  NotificationsRepository(this._api);
  final ApiClient _api;
  Future<(List<AppNotification>, int)> list() async {
    final r = await _api.get('/v1/notifications', query: {'limit': 50});
    return ([for (final n in r['items'] as List) AppNotification.fromJson(n as Json)], r['unreadCount'] as int);
  }

  Future<void> markRead(String id) => _api.post('/v1/notifications/$id/read');
  Future<void> markAllRead() => _api.post('/v1/notifications/read-all');
}

final notificationsRepositoryProvider = Provider((ref) => NotificationsRepository(ref.watch(apiClientProvider)));
final notificationsProvider = FutureProvider.autoDispose((ref) => ref.watch(notificationsRepositoryProvider).list());
