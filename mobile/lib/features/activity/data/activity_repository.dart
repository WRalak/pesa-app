import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers.dart';
import 'models.dart';

class TxnFilter {
  const TxnFilter({this.status, this.type, this.from, this.to, this.q, this.minAmount, this.maxAmount, this.direction});
  final String? status, type, q, minAmount, maxAmount, direction;
  final DateTime? from, to;
  Map<String, dynamic> toQuery() => {
        'status': status, 'type': type, 'q': q, 'minAmount': minAmount, 'maxAmount': maxAmount, 'direction': direction,
        'from': from?.toUtc().toIso8601String(), 'to': to?.toUtc().toIso8601String(),
      };
  bool get isEmpty => toQuery().values.every((v) => v == null || v == '');
  TxnFilter copyWith({String? status, String? type, String? q, DateTime? from, DateTime? to, String? direction, bool clearStatus = false, bool clearType = false, bool clearDates = false}) => TxnFilter(
        status: clearStatus ? null : status ?? this.status, type: clearType ? null : type ?? this.type, q: q ?? this.q,
        from: clearDates ? null : from ?? this.from, to: clearDates ? null : to ?? this.to, direction: direction ?? this.direction, minAmount: minAmount, maxAmount: maxAmount);
}

class ActivityRepository {
  ActivityRepository(this._api);
  final ApiClient _api;

  Future<TxnPage> list(TxnFilter f, {String? cursor, int limit = 20}) async =>
      TxnPage.fromJson(await _api.get('/v1/transactions', query: {...f.toQuery(), 'cursor': cursor, 'limit': limit}));

  Future<(Txn, List<TimelineEntry>)> detail(String id) async {
    final r = await _api.get('/v1/transactions/$id');
    return (Txn.fromJson(r['transaction'] as Json), (r['timeline'] as List).map((e) => TimelineEntry.fromJson(e as Json)).toList());
  }

  Future<Json> receipt(String id) async => (await _api.get('/v1/transactions/$id/receipt'))['receipt'] as Json;
  Future<Txn> setCategory(String id, String category) async => Txn.fromJson((await _api.patch('/v1/transactions/$id/category', body: {'category': category}))['transaction'] as Json);
  Future<Txn> refreshStatus(String id) async => Txn.fromJson((await _api.post('/v1/payments/$id/refresh-status'))!['transaction'] as Json);
  Future<void> downloadStatement(DateTime from, DateTime to, String format, String savePath) =>
      _api.download('/v1/transactions/statement', savePath, query: {'from': from.toUtc().toIso8601String(), 'to': to.toUtc().toIso8601String(), 'format': format});
}

final activityRepositoryProvider = Provider((ref) => ActivityRepository(ref.watch(apiClientProvider)));

final transactionDetailProvider = FutureProvider.autoDispose.family<(Txn, List<TimelineEntry>), String>((ref, id) => ref.watch(activityRepositoryProvider).detail(id));

/// Cursor-paginated transaction list with filters.
class TxnListState {
  const TxnListState({this.items = const [], this.cursor, this.hasMore = true, this.loading = false, this.error, this.filter = const TxnFilter()});
  final List<Txn> items;
  final String? cursor;
  final bool hasMore, loading;
  final Object? error;
  final TxnFilter filter;
  TxnListState copyWith({List<Txn>? items, String? cursor, bool? hasMore, bool? loading, Object? error, TxnFilter? filter, bool clearError = false}) =>
      TxnListState(items: items ?? this.items, cursor: cursor ?? this.cursor, hasMore: hasMore ?? this.hasMore, loading: loading ?? this.loading, error: clearError ? null : error ?? this.error, filter: filter ?? this.filter);
}

class TxnListController extends Notifier<TxnListState> {
  @override
  TxnListState build() {
    Future.microtask(refresh);
    return const TxnListState(loading: true);
  }

  Future<void> refresh() async {
    state = TxnListState(loading: true, filter: state.filter);
    await _load(reset: true);
  }

  Future<void> setFilter(TxnFilter f) async {
    state = TxnListState(loading: true, filter: f);
    await _load(reset: true);
  }

  Future<void> loadMore() async {
    if (state.loading || !state.hasMore) return;
    state = state.copyWith(loading: true);
    await _load(reset: false);
  }

  Future<void> _load({required bool reset}) async {
    try {
      final page = await ref.read(activityRepositoryProvider).list(state.filter, cursor: reset ? null : state.cursor);
      state = state.copyWith(items: reset ? page.items : [...state.items, ...page.items], cursor: page.nextCursor, hasMore: page.hasMore, loading: false, clearError: true);
    } catch (e) {
      state = state.copyWith(loading: false, error: e);
    }
  }

  /// Applies a real-time update pushed over Socket.IO.
  void upsert(Txn t) {
    final i = state.items.indexWhere((x) => x.id == t.id);
    state = state.copyWith(items: i >= 0 ? ([...state.items]..[i] = t) : [t, ...state.items]);
  }
}

final txnListProvider = NotifierProvider<TxnListController, TxnListState>(TxnListController.new);
