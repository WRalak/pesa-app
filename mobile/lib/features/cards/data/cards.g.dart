// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cards.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CardControls _$CardControlsFromJson(Map<String, dynamic> json) =>
    _CardControls(
      perTransaction: json['perTransaction'] == null
          ? null
          : Money.fromJson(json['perTransaction'] as Map<String, dynamic>),
      daily: json['daily'] == null
          ? null
          : Money.fromJson(json['daily'] as Map<String, dynamic>),
      monthly: json['monthly'] == null
          ? null
          : Money.fromJson(json['monthly'] as Map<String, dynamic>),
      online: json['online'] as bool? ?? true,
      international: json['international'] as bool? ?? false,
      atm: json['atm'] as bool? ?? true,
    );

Map<String, dynamic> _$CardControlsToJson(_CardControls instance) =>
    <String, dynamic>{
      'perTransaction': ?instance.perTransaction?.toJson(),
      'daily': ?instance.daily?.toJson(),
      'monthly': ?instance.monthly?.toJson(),
      'online': instance.online,
      'international': instance.international,
      'atm': instance.atm,
    };

_PaymentCard _$PaymentCardFromJson(Map<String, dynamic> json) => _PaymentCard(
  id: json['id'] as String,
  kind: json['kind'] as String,
  issuer: json['issuer'] as String,
  brand: json['brand'] as String,
  last4: json['last4'] as String,
  expiry: json['expiry'] as String,
  nameOnCard: json['nameOnCard'] as String?,
  nickname: json['nickname'] as String?,
  currency: json['currency'] as String,
  status: json['status'] as String,
  sandbox: json['sandbox'] as bool? ?? false,
  controls: CardControls.fromJson(json['controls'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PaymentCardToJson(_PaymentCard instance) =>
    <String, dynamic>{
      'id': instance.id,
      'kind': instance.kind,
      'issuer': instance.issuer,
      'brand': instance.brand,
      'last4': instance.last4,
      'expiry': instance.expiry,
      'nameOnCard': ?instance.nameOnCard,
      'nickname': ?instance.nickname,
      'currency': instance.currency,
      'status': instance.status,
      'sandbox': instance.sandbox,
      'controls': instance.controls.toJson(),
    };
