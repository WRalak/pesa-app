// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Counterparty _$CounterpartyFromJson(Map<String, dynamic> json) =>
    _Counterparty(
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      accountNumber: json['accountNumber'] as String?,
      shortcode: json['shortcode'] as String?,
      network: json['network'] as String?,
      utilityCode: json['utilityCode'] as String?,
    );

Map<String, dynamic> _$CounterpartyToJson(_Counterparty instance) =>
    <String, dynamic>{
      'name': ?instance.name,
      'phone': ?instance.phone,
      'accountNumber': ?instance.accountNumber,
      'shortcode': ?instance.shortcode,
      'network': ?instance.network,
      'utilityCode': ?instance.utilityCode,
    };

_Txn _$TxnFromJson(Map<String, dynamic> json) => _Txn(
  id: json['id'] as String,
  reference: json['reference'] as String,
  type: json['type'] as String,
  direction: json['direction'] as String,
  status: json['status'] as String,
  statusReason: json['statusReason'] as String?,
  amount: Money.fromJson(json['amount'] as Map<String, dynamic>),
  fee: Money.fromJson(json['fee'] as Map<String, dynamic>),
  total: Money.fromJson(json['total'] as Map<String, dynamic>),
  currency: json['currency'] as String,
  provider: json['provider'] as String,
  description: json['description'] as String?,
  category: json['category'] as String,
  counterparty: Counterparty.fromJson(
    json['counterparty'] as Map<String, dynamic>,
  ),
  externalRef: json['externalRef'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  completedAt: json['completedAt'] == null
      ? null
      : DateTime.parse(json['completedAt'] as String),
);

Map<String, dynamic> _$TxnToJson(_Txn instance) => <String, dynamic>{
  'id': instance.id,
  'reference': instance.reference,
  'type': instance.type,
  'direction': instance.direction,
  'status': instance.status,
  'statusReason': ?instance.statusReason,
  'amount': instance.amount.toJson(),
  'fee': instance.fee.toJson(),
  'total': instance.total.toJson(),
  'currency': instance.currency,
  'provider': instance.provider,
  'description': ?instance.description,
  'category': instance.category,
  'counterparty': instance.counterparty.toJson(),
  'externalRef': ?instance.externalRef,
  'createdAt': instance.createdAt.toIso8601String(),
  'completedAt': ?instance.completedAt?.toIso8601String(),
};

_TimelineEntry _$TimelineEntryFromJson(Map<String, dynamic> json) =>
    _TimelineEntry(
      status: json['status'] as String?,
      kind: json['kind'] as String,
      at: DateTime.parse(json['at'] as String),
      reason: json['reason'] as String?,
    );

Map<String, dynamic> _$TimelineEntryToJson(_TimelineEntry instance) =>
    <String, dynamic>{
      'status': ?instance.status,
      'kind': instance.kind,
      'at': instance.at.toIso8601String(),
      'reason': ?instance.reason,
    };

_TxnPage _$TxnPageFromJson(Map<String, dynamic> json) => _TxnPage(
  items: (json['items'] as List<dynamic>)
      .map((e) => Txn.fromJson(e as Map<String, dynamic>))
      .toList(),
  nextCursor: json['nextCursor'] as String?,
  hasMore: json['hasMore'] as bool,
);

Map<String, dynamic> _$TxnPageToJson(_TxnPage instance) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'nextCursor': ?instance.nextCursor,
  'hasMore': instance.hasMore,
};
