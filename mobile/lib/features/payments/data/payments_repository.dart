import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers.dart';
import '../../../core/utils/money.dart';
import '../../activity/data/models.dart';

/// What the user is paying. Converted to the API payload on submit.
class PaymentDraft {
  PaymentDraft({required this.type, this.amount = '', this.recipientPhone, this.recipientName, this.paybillNumber, this.accountNumber, this.tillNumber, this.utilityCode, this.network, this.description})
      : _key = const Uuid().v4();
  final String type;
  String amount;
  String? recipientPhone, recipientName, paybillNumber, accountNumber, tillNumber, utilityCode, network, description;
  bool confirmDuplicate = false;

  /// One key per payment attempt. Retries after a timeout/5xx (unknown outcome)
  /// reuse it, so the server can never create the payment twice. After a
  /// definitive 4xx the user may change the request, so a new key is issued.
  String _key;
  String get idempotencyKey => _key;
  void renewKey() => _key = const Uuid().v4();

  Map<String, dynamic> toJson(String pin) => {
        'type': type, 'amount': amount, 'pin': pin,
        'recipientPhone': ?recipientPhone, 'recipientName': ?recipientName,
        'paybillNumber': ?paybillNumber, 'accountNumber': ?accountNumber,
        'tillNumber': ?tillNumber, 'utilityCode': ?utilityCode, 'network': ?network,
        'description': ?description,
        if (confirmDuplicate) 'confirmDuplicate': true,
      };
}

class Quote {
  Quote(this.fee, this.total, this.provider);
  final Money fee, total;
  final String provider;
}

class PaymentOptions {
  PaymentOptions(this.json);
  final Json json;
  List<({String code, String name})> get utilities => [for (final u in json['utilities'] as List) (code: '${(u as Json)['code']}', name: '${u['name']}')];
  List<String> get networks => (json['networks'] as List).cast<String>();
  bool get sandbox => (json['providers'] as List).any((p) => (p as Json)['sandbox'] == true);

  /// Payment types some enabled, non-maintenance provider can actually process.
  Set<String> get availableTypes => {
        for (final p in (json['providers'] as List).cast<Json>())
          if (p['maintenance'] != true) ...(p['types'] as List).cast<String>(),
      };
}

class PaymentsRepository {
  PaymentsRepository(this._api);
  final ApiClient _api;

  Future<PaymentOptions> options() async => PaymentOptions(await _api.get('/v1/payments/options'));

  Future<Quote> quote(String type, String amount) async {
    final r = (await _api.post('/v1/payments/quote', body: {'type': type, 'amount': amount}))!;
    return Quote(Money.fromJson(r['fee'] as Json), Money.fromJson(r['total'] as Json), '${r['provider']}');
  }

  Future<(Txn, String?)> pay(PaymentDraft d, String pin) async {
    final r = (await _api.post('/v1/payments', body: d.toJson(pin), idempotencyKey: d.idempotencyKey))!;
    return (Txn.fromJson(r['transaction'] as Json), r['customerMessage'] as String?);
  }
}

final paymentsRepositoryProvider = Provider((ref) => PaymentsRepository(ref.watch(apiClientProvider)));
final paymentOptionsProvider = FutureProvider.autoDispose((ref) => ref.watch(paymentsRepositoryProvider).options());
