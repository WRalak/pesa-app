// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'savings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GoalAnalytics _$GoalAnalyticsFromJson(Map<String, dynamic> json) =>
    _GoalAnalytics(
      progressPercent: (json['progressPercent'] as num).toInt(),
      remaining: Money.fromJson(json['remaining'] as Map<String, dynamic>),
      projectedCompletion: json['projectedCompletion'] == null
          ? null
          : DateTime.parse(json['projectedCompletion'] as String),
      requiredMonthly: json['requiredMonthly'] == null
          ? null
          : Money.fromJson(json['requiredMonthly'] as Map<String, dynamic>),
      onTrack: json['onTrack'] as bool?,
    );

Map<String, dynamic> _$GoalAnalyticsToJson(_GoalAnalytics instance) =>
    <String, dynamic>{
      'progressPercent': instance.progressPercent,
      'remaining': instance.remaining.toJson(),
      'projectedCompletion': ?instance.projectedCompletion?.toIso8601String(),
      'requiredMonthly': ?instance.requiredMonthly?.toJson(),
      'onTrack': ?instance.onTrack,
    };

_Reminder _$ReminderFromJson(Map<String, dynamic> json) => _Reminder(
  frequency: json['frequency'] as String? ?? 'NONE',
  amount: json['amount'] == null
      ? null
      : Money.fromJson(json['amount'] as Map<String, dynamic>),
  nextAt: json['nextAt'] == null
      ? null
      : DateTime.parse(json['nextAt'] as String),
);

Map<String, dynamic> _$ReminderToJson(_Reminder instance) => <String, dynamic>{
  'frequency': instance.frequency,
  'amount': ?instance.amount?.toJson(),
  'nextAt': ?instance.nextAt?.toIso8601String(),
};

_SavingsGoal _$SavingsGoalFromJson(Map<String, dynamic> json) => _SavingsGoal(
  id: json['id'] as String,
  name: json['name'] as String,
  category: json['category'] as String,
  status: json['status'] as String,
  target: Money.fromJson(json['target'] as Map<String, dynamic>),
  saved: Money.fromJson(json['saved'] as Map<String, dynamic>),
  deadline: json['deadline'] == null
      ? null
      : DateTime.parse(json['deadline'] as String),
  color: json['color'] as String?,
  icon: json['icon'] as String?,
  custody: json['custody'] as String,
  custodyNote: json['custodyNote'] as String,
  reminder: Reminder.fromJson(json['reminder'] as Map<String, dynamic>),
  completedAt: json['completedAt'] == null
      ? null
      : DateTime.parse(json['completedAt'] as String),
  createdAt: DateTime.parse(json['createdAt'] as String),
  analytics: GoalAnalytics.fromJson(json['analytics'] as Map<String, dynamic>),
);

Map<String, dynamic> _$SavingsGoalToJson(_SavingsGoal instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'category': instance.category,
      'status': instance.status,
      'target': instance.target.toJson(),
      'saved': instance.saved.toJson(),
      'deadline': ?instance.deadline?.toIso8601String(),
      'color': ?instance.color,
      'icon': ?instance.icon,
      'custody': instance.custody,
      'custodyNote': instance.custodyNote,
      'reminder': instance.reminder.toJson(),
      'completedAt': ?instance.completedAt?.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'analytics': instance.analytics.toJson(),
    };

_Contribution _$ContributionFromJson(Map<String, dynamic> json) =>
    _Contribution(
      id: json['id'] as String,
      kind: json['kind'] as String,
      amount: Money.fromJson(json['amount'] as Map<String, dynamic>),
      note: json['note'] as String?,
      balanceAfter: Money.fromJson(
        json['balanceAfter'] as Map<String, dynamic>,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$ContributionToJson(_Contribution instance) =>
    <String, dynamic>{
      'id': instance.id,
      'kind': instance.kind,
      'amount': instance.amount.toJson(),
      'note': ?instance.note,
      'balanceAfter': instance.balanceAfter.toJson(),
      'createdAt': instance.createdAt.toIso8601String(),
    };
