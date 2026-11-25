// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budgets.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BudgetCategory _$BudgetCategoryFromJson(Map<String, dynamic> json) =>
    _BudgetCategory(
      category: json['category'] as String,
      limit: Money.fromJson(json['limit'] as Map<String, dynamic>),
      spent: Money.fromJson(json['spent'] as Map<String, dynamic>),
      remaining: Money.fromJson(json['remaining'] as Map<String, dynamic>),
      percentUsed: (json['percentUsed'] as num).toInt(),
      overspent: json['overspent'] as bool,
    );

Map<String, dynamic> _$BudgetCategoryToJson(_BudgetCategory instance) =>
    <String, dynamic>{
      'category': instance.category,
      'limit': instance.limit.toJson(),
      'spent': instance.spent.toJson(),
      'remaining': instance.remaining.toJson(),
      'percentUsed': instance.percentUsed,
      'overspent': instance.overspent,
    };

_Budget _$BudgetFromJson(Map<String, dynamic> json) => _Budget(
  id: json['id'] as String,
  name: json['name'] as String,
  period: json['period'] as String,
  totalLimit: Money.fromJson(json['totalLimit'] as Map<String, dynamic>),
  spent: Money.fromJson(json['spent'] as Map<String, dynamic>),
  remaining: Money.fromJson(json['remaining'] as Map<String, dynamic>),
  percentUsed: (json['percentUsed'] as num).toInt(),
  periodElapsedPercent: (json['periodElapsedPercent'] as num).toInt(),
  onPace: json['onPace'] as bool,
  categories:
      (json['categories'] as List<dynamic>?)
          ?.map((e) => BudgetCategory.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <BudgetCategory>[],
  alertThresholds:
      (json['alertThresholds'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      const <int>[80, 100],
);

Map<String, dynamic> _$BudgetToJson(_Budget instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'period': instance.period,
  'totalLimit': instance.totalLimit.toJson(),
  'spent': instance.spent.toJson(),
  'remaining': instance.remaining.toJson(),
  'percentUsed': instance.percentUsed,
  'periodElapsedPercent': instance.periodElapsedPercent,
  'onPace': instance.onPace,
  'categories': instance.categories.map((e) => e.toJson()).toList(),
  'alertThresholds': instance.alertThresholds,
};

_Entry _$EntryFromJson(Map<String, dynamic> json) => _Entry(
  id: json['id'] as String,
  amount: Money.fromJson(json['amount'] as Map<String, dynamic>),
  category: json['category'] as String,
  description: json['description'] as String?,
  date: DateTime.parse(json['date'] as String),
  paymentMethod: json['paymentMethod'] as String?,
  recurring: json['recurring'] as bool? ?? false,
);

Map<String, dynamic> _$EntryToJson(_Entry instance) => <String, dynamic>{
  'id': instance.id,
  'amount': instance.amount.toJson(),
  'category': instance.category,
  'description': ?instance.description,
  'date': instance.date.toIso8601String(),
  'paymentMethod': ?instance.paymentMethod,
  'recurring': instance.recurring,
};
