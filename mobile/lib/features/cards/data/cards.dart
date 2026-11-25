import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers.dart';
import '../../../core/utils/money.dart';
import '../../activity/data/models.dart';

part 'cards.freezed.dart';
part 'cards.g.dart';

@freezed
abstract class CardControls with _$CardControls {
  const factory CardControls({Money? perTransaction, Money? daily, Money? monthly, @Default(true) bool online, @Default(false) bool international, @Default(true) bool atm}) = _CardControls;
  factory CardControls.fromJson(Map<String, dynamic> json) => _$CardControlsFromJson(json);
}

@freezed
abstract class PaymentCard with _$PaymentCard {
  const factory PaymentCard({
    required String id, required String kind, required String issuer, required String brand, required String last4, required String expiry,
    String? nameOnCard, String? nickname, required String currency, required String status, @Default(false) bool sandbox, required CardControls controls,
  }) = _PaymentCard;
  factory PaymentCard.fromJson(Map<String, dynamic> json) => _$PaymentCardFromJson(json);
}

class CardsRepository {
  CardsRepository(this._api);
  final ApiClient _api;
  Future<(List<PaymentCard>, bool)> list() async {
    final r = await _api.get('/v1/cards');
    return ([for (final c in r['items'] as List) PaymentCard.fromJson(c as Json)], r['issuingAvailable'] as bool? ?? false);
  }

  Future<PaymentCard> issue(String pin, String? nickname) async => PaymentCard.fromJson((await _api.post('/v1/cards/virtual', body: {'pin': pin, 'nickname': ?nickname}))!);
  Future<PaymentCard> link(String token) async => PaymentCard.fromJson((await _api.post('/v1/cards/link', body: {'paymentMethodToken': token}))!);
  Future<PaymentCard> freeze(String id, bool frozen) async => PaymentCard.fromJson((await _api.post('/v1/cards/$id/${frozen ? 'freeze' : 'unfreeze'}'))!);
  Future<PaymentCard> controls(String id, Json body) async => PaymentCard.fromJson(await _api.patch('/v1/cards/$id/controls', body: body));
  Future<Json> secureDisplay(String id, String pin) async => (await _api.post('/v1/cards/$id/secure-display', body: {'pin': pin}))!;
  Future<void> close(String id) => _api.delete('/v1/cards/$id');
  Future<List<Txn>> transactions(String id) async => [for (final t in (await _api.get('/v1/cards/$id/transactions'))['items'] as List) Txn.fromJson(t as Json)];
  Future<Json> simulate(String id, String amount, String merchant) async => (await _api.post('/v1/cards/$id/simulate-authorization', body: {'amount': amount, 'merchantName': merchant}))!;
}

final cardsRepositoryProvider = Provider((ref) => CardsRepository(ref.watch(apiClientProvider)));
final cardsProvider = FutureProvider.autoDispose((ref) => ref.watch(cardsRepositoryProvider).list());
final cardTransactionsProvider = FutureProvider.autoDispose.family<List<Txn>, String>((ref, id) => ref.watch(cardsRepositoryProvider).transactions(id));
