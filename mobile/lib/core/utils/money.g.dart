// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'money.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Money _$MoneyFromJson(Map<String, dynamic> json) => _Money(
  amountMinor: (json['amountMinor'] as num).toInt(),
  currency: json['currency'] as String,
  amount: json['amount'] as String,
);

Map<String, dynamic> _$MoneyToJson(_Money instance) => <String, dynamic>{
  'amountMinor': instance.amountMinor,
  'currency': instance.currency,
  'amount': instance.amount,
};
