import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../core/utils/money.dart';

part 'models.freezed.dart';
part 'models.g.dart';

@freezed
abstract class Counterparty with _$Counterparty {
  const factory Counterparty({String? name, String? phone, String? accountNumber, String? shortcode, String? network, String? utilityCode}) = _Counterparty;
  factory Counterparty.fromJson(Map<String, dynamic> json) => _$CounterpartyFromJson(json);
}

@freezed
abstract class Txn with _$Txn {
  const Txn._();
  const factory Txn({
    required String id,
    required String reference,
    required String type,
    required String direction,
    required String status,
    String? statusReason,
    required Money amount,
    required Money fee,
    required Money total,
    required String currency,
    required String provider,
    String? description,
    required String category,
    required Counterparty counterparty,
    String? externalRef,
    required DateTime createdAt,
    DateTime? completedAt,
  }) = _Txn;
  factory Txn.fromJson(Map<String, dynamic> json) => _$TxnFromJson(json);

  bool get isTerminal => status == 'SUCCESSFUL' || status == 'FAILED' || status == 'REVERSED';
  String get title => description ?? counterparty.name ?? type;
}

@freezed
abstract class TimelineEntry with _$TimelineEntry {
  const factory TimelineEntry({String? status, required String kind, required DateTime at, String? reason}) = _TimelineEntry;
  factory TimelineEntry.fromJson(Map<String, dynamic> json) => _$TimelineEntryFromJson(json);
}

@freezed
abstract class TxnPage with _$TxnPage {
  const factory TxnPage({required List<Txn> items, String? nextCursor, required bool hasMore}) = _TxnPage;
  factory TxnPage.fromJson(Map<String, dynamic> json) => _$TxnPageFromJson(json);
}
