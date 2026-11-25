// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'savings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GoalAnalytics {

 int get progressPercent; Money get remaining; DateTime? get projectedCompletion; Money? get requiredMonthly; bool? get onTrack;
/// Create a copy of GoalAnalytics
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GoalAnalyticsCopyWith<GoalAnalytics> get copyWith => _$GoalAnalyticsCopyWithImpl<GoalAnalytics>(this as GoalAnalytics, _$identity);

  /// Serializes this GoalAnalytics to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as GoalAnalytics;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GoalAnalytics&&(identical(other.progressPercent, _this.progressPercent) || other.progressPercent == _this.progressPercent)&&(identical(other.remaining, _this.remaining) || other.remaining == _this.remaining)&&(identical(other.projectedCompletion, _this.projectedCompletion) || other.projectedCompletion == _this.projectedCompletion)&&(identical(other.requiredMonthly, _this.requiredMonthly) || other.requiredMonthly == _this.requiredMonthly)&&(identical(other.onTrack, _this.onTrack) || other.onTrack == _this.onTrack));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as GoalAnalytics;
  return Object.hash(runtimeType,_this.progressPercent,_this.remaining,_this.projectedCompletion,_this.requiredMonthly,_this.onTrack);
}

@override
String toString() {
  final _this = this as GoalAnalytics;
  return 'GoalAnalytics(progressPercent: ${_this.progressPercent}, remaining: ${_this.remaining}, projectedCompletion: ${_this.projectedCompletion}, requiredMonthly: ${_this.requiredMonthly}, onTrack: ${_this.onTrack})';
}


}

/// @nodoc
abstract mixin class $GoalAnalyticsCopyWith<$Res>  {
  factory $GoalAnalyticsCopyWith(GoalAnalytics value, $Res Function(GoalAnalytics) _then) = _$GoalAnalyticsCopyWithImpl;
@useResult
$Res call({
 int progressPercent, Money remaining, DateTime? projectedCompletion, Money? requiredMonthly, bool? onTrack
});


$MoneyCopyWith<$Res> get remaining;$MoneyCopyWith<$Res>? get requiredMonthly;

}
/// @nodoc
class _$GoalAnalyticsCopyWithImpl<$Res>
    implements $GoalAnalyticsCopyWith<$Res> {
  _$GoalAnalyticsCopyWithImpl(this._self, this._then);

  final GoalAnalytics _self;
  final $Res Function(GoalAnalytics) _then;

/// Create a copy of GoalAnalytics
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? progressPercent = null,Object? remaining = null,Object? projectedCompletion = freezed,Object? requiredMonthly = freezed,Object? onTrack = freezed,}) {
  return _then(GoalAnalytics(
progressPercent: null == progressPercent ? _self.progressPercent : progressPercent // ignore: cast_nullable_to_non_nullable
as int,remaining: null == remaining ? _self.remaining : remaining // ignore: cast_nullable_to_non_nullable
as Money,projectedCompletion: freezed == projectedCompletion ? _self.projectedCompletion : projectedCompletion // ignore: cast_nullable_to_non_nullable
as DateTime?,requiredMonthly: freezed == requiredMonthly ? _self.requiredMonthly : requiredMonthly // ignore: cast_nullable_to_non_nullable
as Money?,onTrack: freezed == onTrack ? _self.onTrack : onTrack // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}
/// Create a copy of GoalAnalytics
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MoneyCopyWith<$Res> get remaining {
  
  return $MoneyCopyWith<$Res>(_self.remaining, (value) {
    return _then(_self.copyWith(remaining: value));
  });
}/// Create a copy of GoalAnalytics
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MoneyCopyWith<$Res>? get requiredMonthly {
    if (_self.requiredMonthly == null) {
    return null;
  }

  return $MoneyCopyWith<$Res>(_self.requiredMonthly!, (value) {
    return _then(_self.copyWith(requiredMonthly: value));
  });
}
}


/// Adds pattern-matching-related methods to [GoalAnalytics].
extension GoalAnalyticsPatterns on GoalAnalytics {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GoalAnalytics value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GoalAnalytics() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GoalAnalytics value)  $default,){
final _that = this;
switch (_that) {
case _GoalAnalytics():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GoalAnalytics value)?  $default,){
final _that = this;
switch (_that) {
case _GoalAnalytics() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int progressPercent,  Money remaining,  DateTime? projectedCompletion,  Money? requiredMonthly,  bool? onTrack)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GoalAnalytics() when $default != null:
return $default(_that.progressPercent,_that.remaining,_that.projectedCompletion,_that.requiredMonthly,_that.onTrack);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int progressPercent,  Money remaining,  DateTime? projectedCompletion,  Money? requiredMonthly,  bool? onTrack)  $default,) {final _that = this;
switch (_that) {
case _GoalAnalytics():
return $default(_that.progressPercent,_that.remaining,_that.projectedCompletion,_that.requiredMonthly,_that.onTrack);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int progressPercent,  Money remaining,  DateTime? projectedCompletion,  Money? requiredMonthly,  bool? onTrack)?  $default,) {final _that = this;
switch (_that) {
case _GoalAnalytics() when $default != null:
return $default(_that.progressPercent,_that.remaining,_that.projectedCompletion,_that.requiredMonthly,_that.onTrack);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GoalAnalytics implements GoalAnalytics {
  const _GoalAnalytics({required this.progressPercent, required this.remaining, this.projectedCompletion, this.requiredMonthly, this.onTrack});
  factory _GoalAnalytics.fromJson(Map<String, dynamic> json) => _$GoalAnalyticsFromJson(json);

@override final  int progressPercent;
@override final  Money remaining;
@override final  DateTime? projectedCompletion;
@override final  Money? requiredMonthly;
@override final  bool? onTrack;

/// Create a copy of GoalAnalytics
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GoalAnalyticsCopyWith<_GoalAnalytics> get copyWith => __$GoalAnalyticsCopyWithImpl<_GoalAnalytics>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GoalAnalyticsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GoalAnalytics&&(identical(other.progressPercent, progressPercent) || other.progressPercent == progressPercent)&&(identical(other.remaining, remaining) || other.remaining == remaining)&&(identical(other.projectedCompletion, projectedCompletion) || other.projectedCompletion == projectedCompletion)&&(identical(other.requiredMonthly, requiredMonthly) || other.requiredMonthly == requiredMonthly)&&(identical(other.onTrack, onTrack) || other.onTrack == onTrack));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,progressPercent,remaining,projectedCompletion,requiredMonthly,onTrack);
}

@override
String toString() {
    return 'GoalAnalytics(progressPercent: $progressPercent, remaining: $remaining, projectedCompletion: $projectedCompletion, requiredMonthly: $requiredMonthly, onTrack: $onTrack)';
}


}

/// @nodoc
abstract mixin class _$GoalAnalyticsCopyWith<$Res> implements $GoalAnalyticsCopyWith<$Res> {
  factory _$GoalAnalyticsCopyWith(_GoalAnalytics value, $Res Function(_GoalAnalytics) _then) = __$GoalAnalyticsCopyWithImpl;
@override @useResult
$Res call({
 int progressPercent, Money remaining, DateTime? projectedCompletion, Money? requiredMonthly, bool? onTrack
});


@override $MoneyCopyWith<$Res> get remaining;@override $MoneyCopyWith<$Res>? get requiredMonthly;

}
/// @nodoc
class __$GoalAnalyticsCopyWithImpl<$Res>
    implements _$GoalAnalyticsCopyWith<$Res> {
  __$GoalAnalyticsCopyWithImpl(this._self, this._then);

  final _GoalAnalytics _self;
  final $Res Function(_GoalAnalytics) _then;

/// Create a copy of GoalAnalytics
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? progressPercent = null,Object? remaining = null,Object? projectedCompletion = freezed,Object? requiredMonthly = freezed,Object? onTrack = freezed,}) {
  return _then(_GoalAnalytics(
progressPercent: null == progressPercent ? _self.progressPercent : progressPercent // ignore: cast_nullable_to_non_nullable
as int,remaining: null == remaining ? _self.remaining : remaining // ignore: cast_nullable_to_non_nullable
as Money,projectedCompletion: freezed == projectedCompletion ? _self.projectedCompletion : projectedCompletion // ignore: cast_nullable_to_non_nullable
as DateTime?,requiredMonthly: freezed == requiredMonthly ? _self.requiredMonthly : requiredMonthly // ignore: cast_nullable_to_non_nullable
as Money?,onTrack: freezed == onTrack ? _self.onTrack : onTrack // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

/// Create a copy of GoalAnalytics
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MoneyCopyWith<$Res> get remaining {
  
  return $MoneyCopyWith<$Res>(_self.remaining, (value) {
    return _then(_self.copyWith(remaining: value));
  });
}/// Create a copy of GoalAnalytics
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MoneyCopyWith<$Res>? get requiredMonthly {
    if (_self.requiredMonthly == null) {
    return null;
  }

  return $MoneyCopyWith<$Res>(_self.requiredMonthly!, (value) {
    return _then(_self.copyWith(requiredMonthly: value));
  });
}
}


/// @nodoc
mixin _$Reminder {

 String get frequency; Money? get amount; DateTime? get nextAt;
/// Create a copy of Reminder
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReminderCopyWith<Reminder> get copyWith => _$ReminderCopyWithImpl<Reminder>(this as Reminder, _$identity);

  /// Serializes this Reminder to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Reminder;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Reminder&&(identical(other.frequency, _this.frequency) || other.frequency == _this.frequency)&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.nextAt, _this.nextAt) || other.nextAt == _this.nextAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Reminder;
  return Object.hash(runtimeType,_this.frequency,_this.amount,_this.nextAt);
}

@override
String toString() {
  final _this = this as Reminder;
  return 'Reminder(frequency: ${_this.frequency}, amount: ${_this.amount}, nextAt: ${_this.nextAt})';
}


}

/// @nodoc
abstract mixin class $ReminderCopyWith<$Res>  {
  factory $ReminderCopyWith(Reminder value, $Res Function(Reminder) _then) = _$ReminderCopyWithImpl;
@useResult
$Res call({
 String frequency, Money? amount, DateTime? nextAt
});


$MoneyCopyWith<$Res>? get amount;

}
/// @nodoc
class _$ReminderCopyWithImpl<$Res>
    implements $ReminderCopyWith<$Res> {
  _$ReminderCopyWithImpl(this._self, this._then);

  final Reminder _self;
  final $Res Function(Reminder) _then;

/// Create a copy of Reminder
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? frequency = null,Object? amount = freezed,Object? nextAt = freezed,}) {
  return _then(Reminder(
frequency: null == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as String,amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Money?,nextAt: freezed == nextAt ? _self.nextAt : nextAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of Reminder
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MoneyCopyWith<$Res>? get amount {
    if (_self.amount == null) {
    return null;
  }

  return $MoneyCopyWith<$Res>(_self.amount!, (value) {
    return _then(_self.copyWith(amount: value));
  });
}
}


/// Adds pattern-matching-related methods to [Reminder].
extension ReminderPatterns on Reminder {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Reminder value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Reminder() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Reminder value)  $default,){
final _that = this;
switch (_that) {
case _Reminder():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Reminder value)?  $default,){
final _that = this;
switch (_that) {
case _Reminder() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String frequency,  Money? amount,  DateTime? nextAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Reminder() when $default != null:
return $default(_that.frequency,_that.amount,_that.nextAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String frequency,  Money? amount,  DateTime? nextAt)  $default,) {final _that = this;
switch (_that) {
case _Reminder():
return $default(_that.frequency,_that.amount,_that.nextAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String frequency,  Money? amount,  DateTime? nextAt)?  $default,) {final _that = this;
switch (_that) {
case _Reminder() when $default != null:
return $default(_that.frequency,_that.amount,_that.nextAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Reminder implements Reminder {
  const _Reminder({this.frequency = 'NONE', this.amount, this.nextAt});
  factory _Reminder.fromJson(Map<String, dynamic> json) => _$ReminderFromJson(json);

@override@JsonKey() final  String frequency;
@override final  Money? amount;
@override final  DateTime? nextAt;

/// Create a copy of Reminder
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReminderCopyWith<_Reminder> get copyWith => __$ReminderCopyWithImpl<_Reminder>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReminderToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Reminder&&(identical(other.frequency, frequency) || other.frequency == frequency)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.nextAt, nextAt) || other.nextAt == nextAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,frequency,amount,nextAt);
}

@override
String toString() {
    return 'Reminder(frequency: $frequency, amount: $amount, nextAt: $nextAt)';
}


}

/// @nodoc
abstract mixin class _$ReminderCopyWith<$Res> implements $ReminderCopyWith<$Res> {
  factory _$ReminderCopyWith(_Reminder value, $Res Function(_Reminder) _then) = __$ReminderCopyWithImpl;
@override @useResult
$Res call({
 String frequency, Money? amount, DateTime? nextAt
});


@override $MoneyCopyWith<$Res>? get amount;

}
/// @nodoc
class __$ReminderCopyWithImpl<$Res>
    implements _$ReminderCopyWith<$Res> {
  __$ReminderCopyWithImpl(this._self, this._then);

  final _Reminder _self;
  final $Res Function(_Reminder) _then;

/// Create a copy of Reminder
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? frequency = null,Object? amount = freezed,Object? nextAt = freezed,}) {
  return _then(_Reminder(
frequency: null == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as String,amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Money?,nextAt: freezed == nextAt ? _self.nextAt : nextAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of Reminder
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MoneyCopyWith<$Res>? get amount {
    if (_self.amount == null) {
    return null;
  }

  return $MoneyCopyWith<$Res>(_self.amount!, (value) {
    return _then(_self.copyWith(amount: value));
  });
}
}


/// @nodoc
mixin _$SavingsGoal {

 String get id; String get name; String get category; String get status; Money get target; Money get saved; DateTime? get deadline; String? get color; String? get icon; String get custody; String get custodyNote; Reminder get reminder; DateTime? get completedAt; DateTime get createdAt; GoalAnalytics get analytics;
/// Create a copy of SavingsGoal
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SavingsGoalCopyWith<SavingsGoal> get copyWith => _$SavingsGoalCopyWithImpl<SavingsGoal>(this as SavingsGoal, _$identity);

  /// Serializes this SavingsGoal to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SavingsGoal;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SavingsGoal&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.category, _this.category) || other.category == _this.category)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.target, _this.target) || other.target == _this.target)&&(identical(other.saved, _this.saved) || other.saved == _this.saved)&&(identical(other.deadline, _this.deadline) || other.deadline == _this.deadline)&&(identical(other.color, _this.color) || other.color == _this.color)&&(identical(other.icon, _this.icon) || other.icon == _this.icon)&&(identical(other.custody, _this.custody) || other.custody == _this.custody)&&(identical(other.custodyNote, _this.custodyNote) || other.custodyNote == _this.custodyNote)&&(identical(other.reminder, _this.reminder) || other.reminder == _this.reminder)&&(identical(other.completedAt, _this.completedAt) || other.completedAt == _this.completedAt)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.analytics, _this.analytics) || other.analytics == _this.analytics));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SavingsGoal;
  return Object.hash(runtimeType,_this.id,_this.name,_this.category,_this.status,_this.target,_this.saved,_this.deadline,_this.color,_this.icon,_this.custody,_this.custodyNote,_this.reminder,_this.completedAt,_this.createdAt,_this.analytics);
}

@override
String toString() {
  final _this = this as SavingsGoal;
  return 'SavingsGoal(id: ${_this.id}, name: ${_this.name}, category: ${_this.category}, status: ${_this.status}, target: ${_this.target}, saved: ${_this.saved}, deadline: ${_this.deadline}, color: ${_this.color}, icon: ${_this.icon}, custody: ${_this.custody}, custodyNote: ${_this.custodyNote}, reminder: ${_this.reminder}, completedAt: ${_this.completedAt}, createdAt: ${_this.createdAt}, analytics: ${_this.analytics})';
}


}

/// @nodoc
abstract mixin class $SavingsGoalCopyWith<$Res>  {
  factory $SavingsGoalCopyWith(SavingsGoal value, $Res Function(SavingsGoal) _then) = _$SavingsGoalCopyWithImpl;
@useResult
$Res call({
 String id, String name, String category, String status, Money target, Money saved, DateTime? deadline, String? color, String? icon, String custody, String custodyNote, Reminder reminder, DateTime? completedAt, DateTime createdAt, GoalAnalytics analytics
});


$MoneyCopyWith<$Res> get target;$MoneyCopyWith<$Res> get saved;$ReminderCopyWith<$Res> get reminder;$GoalAnalyticsCopyWith<$Res> get analytics;

}
/// @nodoc
class _$SavingsGoalCopyWithImpl<$Res>
    implements $SavingsGoalCopyWith<$Res> {
  _$SavingsGoalCopyWithImpl(this._self, this._then);

  final SavingsGoal _self;
  final $Res Function(SavingsGoal) _then;

/// Create a copy of SavingsGoal
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? category = null,Object? status = null,Object? target = null,Object? saved = null,Object? deadline = freezed,Object? color = freezed,Object? icon = freezed,Object? custody = null,Object? custodyNote = null,Object? reminder = null,Object? completedAt = freezed,Object? createdAt = null,Object? analytics = null,}) {
  return _then(SavingsGoal(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as Money,saved: null == saved ? _self.saved : saved // ignore: cast_nullable_to_non_nullable
as Money,deadline: freezed == deadline ? _self.deadline : deadline // ignore: cast_nullable_to_non_nullable
as DateTime?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String?,custody: null == custody ? _self.custody : custody // ignore: cast_nullable_to_non_nullable
as String,custodyNote: null == custodyNote ? _self.custodyNote : custodyNote // ignore: cast_nullable_to_non_nullable
as String,reminder: null == reminder ? _self.reminder : reminder // ignore: cast_nullable_to_non_nullable
as Reminder,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,analytics: null == analytics ? _self.analytics : analytics // ignore: cast_nullable_to_non_nullable
as GoalAnalytics,
  ));
}
/// Create a copy of SavingsGoal
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MoneyCopyWith<$Res> get target {
  
  return $MoneyCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}/// Create a copy of SavingsGoal
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MoneyCopyWith<$Res> get saved {
  
  return $MoneyCopyWith<$Res>(_self.saved, (value) {
    return _then(_self.copyWith(saved: value));
  });
}/// Create a copy of SavingsGoal
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReminderCopyWith<$Res> get reminder {
  
  return $ReminderCopyWith<$Res>(_self.reminder, (value) {
    return _then(_self.copyWith(reminder: value));
  });
}/// Create a copy of SavingsGoal
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GoalAnalyticsCopyWith<$Res> get analytics {
  
  return $GoalAnalyticsCopyWith<$Res>(_self.analytics, (value) {
    return _then(_self.copyWith(analytics: value));
  });
}
}


/// Adds pattern-matching-related methods to [SavingsGoal].
extension SavingsGoalPatterns on SavingsGoal {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SavingsGoal value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SavingsGoal() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SavingsGoal value)  $default,){
final _that = this;
switch (_that) {
case _SavingsGoal():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SavingsGoal value)?  $default,){
final _that = this;
switch (_that) {
case _SavingsGoal() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String category,  String status,  Money target,  Money saved,  DateTime? deadline,  String? color,  String? icon,  String custody,  String custodyNote,  Reminder reminder,  DateTime? completedAt,  DateTime createdAt,  GoalAnalytics analytics)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SavingsGoal() when $default != null:
return $default(_that.id,_that.name,_that.category,_that.status,_that.target,_that.saved,_that.deadline,_that.color,_that.icon,_that.custody,_that.custodyNote,_that.reminder,_that.completedAt,_that.createdAt,_that.analytics);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String category,  String status,  Money target,  Money saved,  DateTime? deadline,  String? color,  String? icon,  String custody,  String custodyNote,  Reminder reminder,  DateTime? completedAt,  DateTime createdAt,  GoalAnalytics analytics)  $default,) {final _that = this;
switch (_that) {
case _SavingsGoal():
return $default(_that.id,_that.name,_that.category,_that.status,_that.target,_that.saved,_that.deadline,_that.color,_that.icon,_that.custody,_that.custodyNote,_that.reminder,_that.completedAt,_that.createdAt,_that.analytics);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String category,  String status,  Money target,  Money saved,  DateTime? deadline,  String? color,  String? icon,  String custody,  String custodyNote,  Reminder reminder,  DateTime? completedAt,  DateTime createdAt,  GoalAnalytics analytics)?  $default,) {final _that = this;
switch (_that) {
case _SavingsGoal() when $default != null:
return $default(_that.id,_that.name,_that.category,_that.status,_that.target,_that.saved,_that.deadline,_that.color,_that.icon,_that.custody,_that.custodyNote,_that.reminder,_that.completedAt,_that.createdAt,_that.analytics);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SavingsGoal implements SavingsGoal {
  const _SavingsGoal({required this.id, required this.name, required this.category, required this.status, required this.target, required this.saved, this.deadline, this.color, this.icon, required this.custody, required this.custodyNote, required this.reminder, this.completedAt, required this.createdAt, required this.analytics});
  factory _SavingsGoal.fromJson(Map<String, dynamic> json) => _$SavingsGoalFromJson(json);

@override final  String id;
@override final  String name;
@override final  String category;
@override final  String status;
@override final  Money target;
@override final  Money saved;
@override final  DateTime? deadline;
@override final  String? color;
@override final  String? icon;
@override final  String custody;
@override final  String custodyNote;
@override final  Reminder reminder;
@override final  DateTime? completedAt;
@override final  DateTime createdAt;
@override final  GoalAnalytics analytics;

/// Create a copy of SavingsGoal
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SavingsGoalCopyWith<_SavingsGoal> get copyWith => __$SavingsGoalCopyWithImpl<_SavingsGoal>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SavingsGoalToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SavingsGoal&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.category, category) || other.category == category)&&(identical(other.status, status) || other.status == status)&&(identical(other.target, target) || other.target == target)&&(identical(other.saved, saved) || other.saved == saved)&&(identical(other.deadline, deadline) || other.deadline == deadline)&&(identical(other.color, color) || other.color == color)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.custody, custody) || other.custody == custody)&&(identical(other.custodyNote, custodyNote) || other.custodyNote == custodyNote)&&(identical(other.reminder, reminder) || other.reminder == reminder)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.analytics, analytics) || other.analytics == analytics));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,category,status,target,saved,deadline,color,icon,custody,custodyNote,reminder,completedAt,createdAt,analytics);
}

@override
String toString() {
    return 'SavingsGoal(id: $id, name: $name, category: $category, status: $status, target: $target, saved: $saved, deadline: $deadline, color: $color, icon: $icon, custody: $custody, custodyNote: $custodyNote, reminder: $reminder, completedAt: $completedAt, createdAt: $createdAt, analytics: $analytics)';
}


}

/// @nodoc
abstract mixin class _$SavingsGoalCopyWith<$Res> implements $SavingsGoalCopyWith<$Res> {
  factory _$SavingsGoalCopyWith(_SavingsGoal value, $Res Function(_SavingsGoal) _then) = __$SavingsGoalCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String category, String status, Money target, Money saved, DateTime? deadline, String? color, String? icon, String custody, String custodyNote, Reminder reminder, DateTime? completedAt, DateTime createdAt, GoalAnalytics analytics
});


@override $MoneyCopyWith<$Res> get target;@override $MoneyCopyWith<$Res> get saved;@override $ReminderCopyWith<$Res> get reminder;@override $GoalAnalyticsCopyWith<$Res> get analytics;

}
/// @nodoc
class __$SavingsGoalCopyWithImpl<$Res>
    implements _$SavingsGoalCopyWith<$Res> {
  __$SavingsGoalCopyWithImpl(this._self, this._then);

  final _SavingsGoal _self;
  final $Res Function(_SavingsGoal) _then;

/// Create a copy of SavingsGoal
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? category = null,Object? status = null,Object? target = null,Object? saved = null,Object? deadline = freezed,Object? color = freezed,Object? icon = freezed,Object? custody = null,Object? custodyNote = null,Object? reminder = null,Object? completedAt = freezed,Object? createdAt = null,Object? analytics = null,}) {
  return _then(_SavingsGoal(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as Money,saved: null == saved ? _self.saved : saved // ignore: cast_nullable_to_non_nullable
as Money,deadline: freezed == deadline ? _self.deadline : deadline // ignore: cast_nullable_to_non_nullable
as DateTime?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String?,custody: null == custody ? _self.custody : custody // ignore: cast_nullable_to_non_nullable
as String,custodyNote: null == custodyNote ? _self.custodyNote : custodyNote // ignore: cast_nullable_to_non_nullable
as String,reminder: null == reminder ? _self.reminder : reminder // ignore: cast_nullable_to_non_nullable
as Reminder,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,analytics: null == analytics ? _self.analytics : analytics // ignore: cast_nullable_to_non_nullable
as GoalAnalytics,
  ));
}

/// Create a copy of SavingsGoal
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MoneyCopyWith<$Res> get target {
  
  return $MoneyCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}/// Create a copy of SavingsGoal
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MoneyCopyWith<$Res> get saved {
  
  return $MoneyCopyWith<$Res>(_self.saved, (value) {
    return _then(_self.copyWith(saved: value));
  });
}/// Create a copy of SavingsGoal
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReminderCopyWith<$Res> get reminder {
  
  return $ReminderCopyWith<$Res>(_self.reminder, (value) {
    return _then(_self.copyWith(reminder: value));
  });
}/// Create a copy of SavingsGoal
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GoalAnalyticsCopyWith<$Res> get analytics {
  
  return $GoalAnalyticsCopyWith<$Res>(_self.analytics, (value) {
    return _then(_self.copyWith(analytics: value));
  });
}
}


/// @nodoc
mixin _$Contribution {

 String get id; String get kind; Money get amount; String? get note; Money get balanceAfter; DateTime get createdAt;
/// Create a copy of Contribution
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContributionCopyWith<Contribution> get copyWith => _$ContributionCopyWithImpl<Contribution>(this as Contribution, _$identity);

  /// Serializes this Contribution to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Contribution;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Contribution&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.note, _this.note) || other.note == _this.note)&&(identical(other.balanceAfter, _this.balanceAfter) || other.balanceAfter == _this.balanceAfter)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Contribution;
  return Object.hash(runtimeType,_this.id,_this.kind,_this.amount,_this.note,_this.balanceAfter,_this.createdAt);
}

@override
String toString() {
  final _this = this as Contribution;
  return 'Contribution(id: ${_this.id}, kind: ${_this.kind}, amount: ${_this.amount}, note: ${_this.note}, balanceAfter: ${_this.balanceAfter}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $ContributionCopyWith<$Res>  {
  factory $ContributionCopyWith(Contribution value, $Res Function(Contribution) _then) = _$ContributionCopyWithImpl;
@useResult
$Res call({
 String id, String kind, Money amount, String? note, Money balanceAfter, DateTime createdAt
});


$MoneyCopyWith<$Res> get amount;$MoneyCopyWith<$Res> get balanceAfter;

}
/// @nodoc
class _$ContributionCopyWithImpl<$Res>
    implements $ContributionCopyWith<$Res> {
  _$ContributionCopyWithImpl(this._self, this._then);

  final Contribution _self;
  final $Res Function(Contribution) _then;

/// Create a copy of Contribution
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kind = null,Object? amount = null,Object? note = freezed,Object? balanceAfter = null,Object? createdAt = null,}) {
  return _then(Contribution(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Money,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,balanceAfter: null == balanceAfter ? _self.balanceAfter : balanceAfter // ignore: cast_nullable_to_non_nullable
as Money,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of Contribution
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MoneyCopyWith<$Res> get amount {
  
  return $MoneyCopyWith<$Res>(_self.amount, (value) {
    return _then(_self.copyWith(amount: value));
  });
}/// Create a copy of Contribution
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MoneyCopyWith<$Res> get balanceAfter {
  
  return $MoneyCopyWith<$Res>(_self.balanceAfter, (value) {
    return _then(_self.copyWith(balanceAfter: value));
  });
}
}


/// Adds pattern-matching-related methods to [Contribution].
extension ContributionPatterns on Contribution {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Contribution value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Contribution() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Contribution value)  $default,){
final _that = this;
switch (_that) {
case _Contribution():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Contribution value)?  $default,){
final _that = this;
switch (_that) {
case _Contribution() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String kind,  Money amount,  String? note,  Money balanceAfter,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Contribution() when $default != null:
return $default(_that.id,_that.kind,_that.amount,_that.note,_that.balanceAfter,_that.createdAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String kind,  Money amount,  String? note,  Money balanceAfter,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _Contribution():
return $default(_that.id,_that.kind,_that.amount,_that.note,_that.balanceAfter,_that.createdAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String kind,  Money amount,  String? note,  Money balanceAfter,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Contribution() when $default != null:
return $default(_that.id,_that.kind,_that.amount,_that.note,_that.balanceAfter,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Contribution implements Contribution {
  const _Contribution({required this.id, required this.kind, required this.amount, this.note, required this.balanceAfter, required this.createdAt});
  factory _Contribution.fromJson(Map<String, dynamic> json) => _$ContributionFromJson(json);

@override final  String id;
@override final  String kind;
@override final  Money amount;
@override final  String? note;
@override final  Money balanceAfter;
@override final  DateTime createdAt;

/// Create a copy of Contribution
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ContributionCopyWith<_Contribution> get copyWith => __$ContributionCopyWithImpl<_Contribution>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ContributionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Contribution&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.note, note) || other.note == note)&&(identical(other.balanceAfter, balanceAfter) || other.balanceAfter == balanceAfter)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,kind,amount,note,balanceAfter,createdAt);
}

@override
String toString() {
    return 'Contribution(id: $id, kind: $kind, amount: $amount, note: $note, balanceAfter: $balanceAfter, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$ContributionCopyWith<$Res> implements $ContributionCopyWith<$Res> {
  factory _$ContributionCopyWith(_Contribution value, $Res Function(_Contribution) _then) = __$ContributionCopyWithImpl;
@override @useResult
$Res call({
 String id, String kind, Money amount, String? note, Money balanceAfter, DateTime createdAt
});


@override $MoneyCopyWith<$Res> get amount;@override $MoneyCopyWith<$Res> get balanceAfter;

}
/// @nodoc
class __$ContributionCopyWithImpl<$Res>
    implements _$ContributionCopyWith<$Res> {
  __$ContributionCopyWithImpl(this._self, this._then);

  final _Contribution _self;
  final $Res Function(_Contribution) _then;

/// Create a copy of Contribution
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kind = null,Object? amount = null,Object? note = freezed,Object? balanceAfter = null,Object? createdAt = null,}) {
  return _then(_Contribution(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Money,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,balanceAfter: null == balanceAfter ? _self.balanceAfter : balanceAfter // ignore: cast_nullable_to_non_nullable
as Money,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of Contribution
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MoneyCopyWith<$Res> get amount {
  
  return $MoneyCopyWith<$Res>(_self.amount, (value) {
    return _then(_self.copyWith(amount: value));
  });
}/// Create a copy of Contribution
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MoneyCopyWith<$Res> get balanceAfter {
  
  return $MoneyCopyWith<$Res>(_self.balanceAfter, (value) {
    return _then(_self.copyWith(balanceAfter: value));
  });
}
}

// dart format on
