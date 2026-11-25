import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers.dart';

class RewardsRepository {
  RewardsRepository(this._api);
  final ApiClient _api;
  Future<Json> dashboard() => _api.get('/v1/rewards');
  Future<List<Json>> history() async => ((await _api.get('/v1/rewards/history', query: {'limit': 50}))['items'] as List).cast<Json>();
  Future<Json> redeem(String reward, int points) async => (await _api.post('/v1/rewards/redeem', body: {'reward': reward, 'points': points}))!;
}

final rewardsRepositoryProvider = Provider((ref) => RewardsRepository(ref.watch(apiClientProvider)));
final rewardsProvider = FutureProvider.autoDispose((ref) => ref.watch(rewardsRepositoryProvider).dashboard());
final rewardHistoryProvider = FutureProvider.autoDispose((ref) => ref.watch(rewardsRepositoryProvider).history());
