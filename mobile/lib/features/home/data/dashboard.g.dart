// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LinkedAccount _$LinkedAccountFromJson(Map<String, dynamic> json) =>
    _LinkedAccount(
      id: json['id'] as String,
      kind: json['kind'] as String,
      provider: json['provider'] as String,
      displayName: json['displayName'] as String,
      maskedIdentifier: json['maskedIdentifier'] as String?,
      currency: json['currency'] as String,
      balance: json['balance'] == null
          ? null
          : Money.fromJson(json['balance'] as Map<String, dynamic>),
      balanceSource: json['balanceSource'] as String,
      balanceAsOf: json['balanceAsOf'] == null
          ? null
          : DateTime.parse(json['balanceAsOf'] as String),
      sandbox: json['sandbox'] as bool? ?? false,
      status: json['status'] as String,
      isDefault: json['isDefault'] as bool? ?? false,
    );

Map<String, dynamic> _$LinkedAccountToJson(_LinkedAccount instance) =>
    <String, dynamic>{
      'id': instance.id,
      'kind': instance.kind,
      'provider': instance.provider,
      'displayName': instance.displayName,
      'maskedIdentifier': ?instance.maskedIdentifier,
      'currency': instance.currency,
      'balance': ?instance.balance?.toJson(),
      'balanceSource': instance.balanceSource,
      'balanceAsOf': ?instance.balanceAsOf?.toIso8601String(),
      'sandbox': instance.sandbox,
      'status': instance.status,
      'isDefault': instance.isDefault,
    };

_BalanceGroup _$BalanceGroupFromJson(Map<String, dynamic> json) =>
    _BalanceGroup(
      total: json['total'] == null
          ? null
          : Money.fromJson(json['total'] as Map<String, dynamic>),
      accountCount: (json['accountCount'] as num?)?.toInt() ?? 0,
      oldestAsOf: json['oldestAsOf'] == null
          ? null
          : DateTime.parse(json['oldestAsOf'] as String),
      sandbox: json['sandbox'] as bool? ?? false,
    );

Map<String, dynamic> _$BalanceGroupToJson(_BalanceGroup instance) =>
    <String, dynamic>{
      'total': ?instance.total?.toJson(),
      'accountCount': instance.accountCount,
      'oldestAsOf': ?instance.oldestAsOf?.toIso8601String(),
      'sandbox': instance.sandbox,
    };

_CategoryAmount _$CategoryAmountFromJson(Map<String, dynamic> json) =>
    _CategoryAmount(
      category: json['category'] as String,
      amount: Money.fromJson(json['amount'] as Map<String, dynamic>),
      share: (json['share'] as num?)?.toDouble() ?? 0,
    );

Map<String, dynamic> _$CategoryAmountToJson(_CategoryAmount instance) =>
    <String, dynamic>{
      'category': instance.category,
      'amount': instance.amount.toJson(),
      'share': instance.share,
    };

_DailySpend _$DailySpendFromJson(Map<String, dynamic> json) => _DailySpend(
  date: json['date'] as String,
  spent: Money.fromJson(json['spent'] as Map<String, dynamic>),
);

Map<String, dynamic> _$DailySpendToJson(_DailySpend instance) =>
    <String, dynamic>{'date': instance.date, 'spent': instance.spent.toJson()};

_MonthSummary _$MonthSummaryFromJson(Map<String, dynamic> json) =>
    _MonthSummary(
      income: Money.fromJson(json['income'] as Map<String, dynamic>),
      expenses: Money.fromJson(json['expenses'] as Map<String, dynamic>),
      net: Money.fromJson(json['net'] as Map<String, dynamic>),
      byCategory:
          (json['byCategory'] as List<dynamic>?)
              ?.map((e) => CategoryAmount.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <CategoryAmount>[],
      changeInExpensesPercent: (json['changeInExpensesPercent'] as num?)
          ?.toDouble(),
      daily:
          (json['daily'] as List<dynamic>?)
              ?.map((e) => DailySpend.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <DailySpend>[],
      basisNote: json['basisNote'] as String?,
    );

Map<String, dynamic> _$MonthSummaryToJson(_MonthSummary instance) =>
    <String, dynamic>{
      'income': instance.income.toJson(),
      'expenses': instance.expenses.toJson(),
      'net': instance.net.toJson(),
      'byCategory': instance.byCategory.map((e) => e.toJson()).toList(),
      'changeInExpensesPercent': ?instance.changeInExpensesPercent,
      'daily': instance.daily.map((e) => e.toJson()).toList(),
      'basisNote': ?instance.basisNote,
    };
