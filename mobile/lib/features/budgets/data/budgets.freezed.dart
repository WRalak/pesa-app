// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'budgets.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BudgetCategory {

 String get category; Money get limit; Money get spent; Money get remaining; int get percentUsed; bool get overspent;
/// Create a copy of BudgetCategory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BudgetCategoryCopyWith<BudgetCategory> get copyWith => _$BudgetCategoryCopyWithImpl<BudgetCategory>(this as BudgetCategory, _$identity);

  /// Serializes this BudgetCategory to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BudgetCategory;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BudgetCategory&&(identical(other.category, _this.category) || other.category == _this.category)&&(identical(other.limit, _this.limit) || other.limit == _this.limit)&&(identical(other.spent, _this.spent) || other.spent == _this.spent)&&(identical(other.remaining, _this.remaining) || other.remaining == _this.remaining)&&(identical(other.percentUsed, _this.percentUsed) || other.percentUsed == _this.percentUsed)&&(identical(other.overspent, _this.overspent) || other.overspent == _this.overspent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BudgetCategory;
  return Object.hash(runtimeType,_this.category,_this.limit,_this.spent,_this.remaining,_this.percentUsed,_this.overspent);
}

@override
String toString() {
  final _this = this as BudgetCategory;
  return 'BudgetCategory(category: ${_this.category}, limit: ${_this.limit}, spent: ${_this.spent}, remaining: ${_this.remaining}, percentUsed: ${_this.percentUsed}, overspent: ${_this.overspent})';
}


}

/// @nodoc
abstract mixin class $BudgetCategoryCopyWith<$Res>  {
  factory $BudgetCategoryCopyWith(BudgetCategory value, $Res Function(BudgetCategory) _then) = _$BudgetCategoryCopyWithImpl;
@useResult
$Res call({
 String category, Money limit, Money spent, Money remaining, int percentUsed, bool overspent
});


$MoneyCopyWith<$Res> get limit;$MoneyCopyWith<$Res> get spent;$MoneyCopyWith<$Res> get remaining;

}
/// @nodoc
class _$BudgetCategoryCopyWithImpl<$Res>
    implements $BudgetCategoryCopyWith<$Res> {
  _$BudgetCategoryCopyWithImpl(this._self, this._then);

  final BudgetCategory _self;
  final $Res Function(BudgetCategory) _then;

/// Create a copy of BudgetCategory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? category = null,Object? limit = null,Object? spent = null,Object? remaining = null,Object? percentUsed = null,Object? overspent = null,}) {
  return _then(BudgetCategory(
category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as Money,spent: null == spent ? _self.spent : spent // ignore: cast_nullable_to_non_nullable
as Money,remaining: null == remaining ? _self.remaining : remaining // ignore: cast_nullable_to_non_nullable
as Money,percentUsed: null == percentUsed ? _self.percentUsed : percentUsed // ignore: cast_nullable_to_non_nullable
as int,overspent: null == overspent ? _self.overspent : overspent // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of BudgetCategory
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MoneyCopyWith<$Res> get limit {
  
  return $MoneyCopyWith<$Res>(_self.limit, (value) {
    return _then(_self.copyWith(limit: value));
  });
}/// Create a copy of BudgetCategory
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MoneyCopyWith<$Res> get spent {
  
  return $MoneyCopyWith<$Res>(_self.spent, (value) {
    return _then(_self.copyWith(spent: value));
  });
}/// Create a copy of BudgetCategory
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MoneyCopyWith<$Res> get remaining {
  
  return $MoneyCopyWith<$Res>(_self.remaining, (value) {
    return _then(_self.copyWith(remaining: value));
  });
}
}


/// Adds pattern-matching-related methods to [BudgetCategory].
extension BudgetCategoryPatterns on BudgetCategory {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BudgetCategory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BudgetCategory() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BudgetCategory value)  $default,){
final _that = this;
switch (_that) {
case _BudgetCategory():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BudgetCategory value)?  $default,){
final _that = this;
switch (_that) {
case _BudgetCategory() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String category,  Money limit,  Money spent,  Money remaining,  int percentUsed,  bool overspent)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BudgetCategory() when $default != null:
return $default(_that.category,_that.limit,_that.spent,_that.remaining,_that.percentUsed,_that.overspent);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String category,  Money limit,  Money spent,  Money remaining,  int percentUsed,  bool overspent)  $default,) {final _that = this;
switch (_that) {
case _BudgetCategory():
return $default(_that.category,_that.limit,_that.spent,_that.remaining,_that.percentUsed,_that.overspent);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String category,  Money limit,  Money spent,  Money remaining,  int percentUsed,  bool overspent)?  $default,) {final _that = this;
switch (_that) {
case _BudgetCategory() when $default != null:
return $default(_that.category,_that.limit,_that.spent,_that.remaining,_that.percentUsed,_that.overspent);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BudgetCategory implements BudgetCategory {
  const _BudgetCategory({required this.category, required this.limit, required this.spent, required this.remaining, required this.percentUsed, required this.overspent});
  factory _BudgetCategory.fromJson(Map<String, dynamic> json) => _$BudgetCategoryFromJson(json);

@override final  String category;
@override final  Money limit;
@override final  Money spent;
@override final  Money remaining;
@override final  int percentUsed;
@override final  bool overspent;

/// Create a copy of BudgetCategory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BudgetCategoryCopyWith<_BudgetCategory> get copyWith => __$BudgetCategoryCopyWithImpl<_BudgetCategory>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BudgetCategoryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BudgetCategory&&(identical(other.category, category) || other.category == category)&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.spent, spent) || other.spent == spent)&&(identical(other.remaining, remaining) || other.remaining == remaining)&&(identical(other.percentUsed, percentUsed) || other.percentUsed == percentUsed)&&(identical(other.overspent, overspent) || other.overspent == overspent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,category,limit,spent,remaining,percentUsed,overspent);
}

@override
String toString() {
    return 'BudgetCategory(category: $category, limit: $limit, spent: $spent, remaining: $remaining, percentUsed: $percentUsed, overspent: $overspent)';
}


}

/// @nodoc
abstract mixin class _$BudgetCategoryCopyWith<$Res> implements $BudgetCategoryCopyWith<$Res> {
  factory _$BudgetCategoryCopyWith(_BudgetCategory value, $Res Function(_BudgetCategory) _then) = __$BudgetCategoryCopyWithImpl;
@override @useResult
$Res call({
 String category, Money limit, Money spent, Money remaining, int percentUsed, bool overspent
});


@override $MoneyCopyWith<$Res> get limit;@override $MoneyCopyWith<$Res> get spent;@override $MoneyCopyWith<$Res> get remaining;

}
/// @nodoc
class __$BudgetCategoryCopyWithImpl<$Res>
    implements _$BudgetCategoryCopyWith<$Res> {
  __$BudgetCategoryCopyWithImpl(this._self, this._then);

  final _BudgetCategory _self;
  final $Res Function(_BudgetCategory) _then;

/// Create a copy of BudgetCategory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? category = null,Object? limit = null,Object? spent = null,Object? remaining = null,Object? percentUsed = null,Object? overspent = null,}) {
  return _then(_BudgetCategory(
category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as Money,spent: null == spent ? _self.spent : spent // ignore: cast_nullable_to_non_nullable
as Money,remaining: null == remaining ? _self.remaining : remaining // ignore: cast_nullable_to_non_nullable
as Money,percentUsed: null == percentUsed ? _self.percentUsed : percentUsed // ignore: cast_nullable_to_non_nullable
as int,overspent: null == overspent ? _self.overspent : overspent // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of BudgetCategory
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MoneyCopyWith<$Res> get limit {
  
  return $MoneyCopyWith<$Res>(_self.limit, (value) {
    return _then(_self.copyWith(limit: value));
  });
}/// Create a copy of BudgetCategory
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MoneyCopyWith<$Res> get spent {
  
  return $MoneyCopyWith<$Res>(_self.spent, (value) {
    return _then(_self.copyWith(spent: value));
  });
}/// Create a copy of BudgetCategory
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MoneyCopyWith<$Res> get remaining {
  
  return $MoneyCopyWith<$Res>(_self.remaining, (value) {
    return _then(_self.copyWith(remaining: value));
  });
}
}


/// @nodoc
mixin _$Budget {

 String get id; String get name; String get period; Money get totalLimit; Money get spent; Money get remaining; int get percentUsed; int get periodElapsedPercent; bool get onPace; List<BudgetCategory> get categories; List<int> get alertThresholds;
/// Create a copy of Budget
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BudgetCopyWith<Budget> get copyWith => _$BudgetCopyWithImpl<Budget>(this as Budget, _$identity);

  /// Serializes this Budget to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Budget;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Budget&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.period, _this.period) || other.period == _this.period)&&(identical(other.totalLimit, _this.totalLimit) || other.totalLimit == _this.totalLimit)&&(identical(other.spent, _this.spent) || other.spent == _this.spent)&&(identical(other.remaining, _this.remaining) || other.remaining == _this.remaining)&&(identical(other.percentUsed, _this.percentUsed) || other.percentUsed == _this.percentUsed)&&(identical(other.periodElapsedPercent, _this.periodElapsedPercent) || other.periodElapsedPercent == _this.periodElapsedPercent)&&(identical(other.onPace, _this.onPace) || other.onPace == _this.onPace)&&const DeepCollectionEquality().equals(other.categories, _this.categories)&&const DeepCollectionEquality().equals(other.alertThresholds, _this.alertThresholds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Budget;
  return Object.hash(runtimeType,_this.id,_this.name,_this.period,_this.totalLimit,_this.spent,_this.remaining,_this.percentUsed,_this.periodElapsedPercent,_this.onPace,const DeepCollectionEquality().hash(_this.categories),const DeepCollectionEquality().hash(_this.alertThresholds));
}

@override
String toString() {
  final _this = this as Budget;
  return 'Budget(id: ${_this.id}, name: ${_this.name}, period: ${_this.period}, totalLimit: ${_this.totalLimit}, spent: ${_this.spent}, remaining: ${_this.remaining}, percentUsed: ${_this.percentUsed}, periodElapsedPercent: ${_this.periodElapsedPercent}, onPace: ${_this.onPace}, categories: ${_this.categories}, alertThresholds: ${_this.alertThresholds})';
}


}

/// @nodoc
abstract mixin class $BudgetCopyWith<$Res>  {
  factory $BudgetCopyWith(Budget value, $Res Function(Budget) _then) = _$BudgetCopyWithImpl;
@useResult
$Res call({
 String id, String name, String period, Money totalLimit, Money spent, Money remaining, int percentUsed, int periodElapsedPercent, bool onPace, List<BudgetCategory> categories, List<int> alertThresholds
});


$MoneyCopyWith<$Res> get totalLimit;$MoneyCopyWith<$Res> get spent;$MoneyCopyWith<$Res> get remaining;

}
/// @nodoc
class _$BudgetCopyWithImpl<$Res>
    implements $BudgetCopyWith<$Res> {
  _$BudgetCopyWithImpl(this._self, this._then);

  final Budget _self;
  final $Res Function(Budget) _then;

/// Create a copy of Budget
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? period = null,Object? totalLimit = null,Object? spent = null,Object? remaining = null,Object? percentUsed = null,Object? periodElapsedPercent = null,Object? onPace = null,Object? categories = null,Object? alertThresholds = null,}) {
  return _then(Budget(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as String,totalLimit: null == totalLimit ? _self.totalLimit : totalLimit // ignore: cast_nullable_to_non_nullable
as Money,spent: null == spent ? _self.spent : spent // ignore: cast_nullable_to_non_nullable
as Money,remaining: null == remaining ? _self.remaining : remaining // ignore: cast_nullable_to_non_nullable
as Money,percentUsed: null == percentUsed ? _self.percentUsed : percentUsed // ignore: cast_nullable_to_non_nullable
as int,periodElapsedPercent: null == periodElapsedPercent ? _self.periodElapsedPercent : periodElapsedPercent // ignore: cast_nullable_to_non_nullable
as int,onPace: null == onPace ? _self.onPace : onPace // ignore: cast_nullable_to_non_nullable
as bool,categories: null == categories ? _self.categories : categories // ignore: cast_nullable_to_non_nullable
as List<BudgetCategory>,alertThresholds: null == alertThresholds ? _self.alertThresholds : alertThresholds // ignore: cast_nullable_to_non_nullable
as List<int>,
  ));
}
/// Create a copy of Budget
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MoneyCopyWith<$Res> get totalLimit {
  
  return $MoneyCopyWith<$Res>(_self.totalLimit, (value) {
    return _then(_self.copyWith(totalLimit: value));
  });
}/// Create a copy of Budget
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MoneyCopyWith<$Res> get spent {
  
  return $MoneyCopyWith<$Res>(_self.spent, (value) {
    return _then(_self.copyWith(spent: value));
  });
}/// Create a copy of Budget
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MoneyCopyWith<$Res> get remaining {
  
  return $MoneyCopyWith<$Res>(_self.remaining, (value) {
    return _then(_self.copyWith(remaining: value));
  });
}
}


/// Adds pattern-matching-related methods to [Budget].
extension BudgetPatterns on Budget {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Budget value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Budget() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Budget value)  $default,){
final _that = this;
switch (_that) {
case _Budget():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Budget value)?  $default,){
final _that = this;
switch (_that) {
case _Budget() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String period,  Money totalLimit,  Money spent,  Money remaining,  int percentUsed,  int periodElapsedPercent,  bool onPace,  List<BudgetCategory> categories,  List<int> alertThresholds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Budget() when $default != null:
return $default(_that.id,_that.name,_that.period,_that.totalLimit,_that.spent,_that.remaining,_that.percentUsed,_that.periodElapsedPercent,_that.onPace,_that.categories,_that.alertThresholds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String period,  Money totalLimit,  Money spent,  Money remaining,  int percentUsed,  int periodElapsedPercent,  bool onPace,  List<BudgetCategory> categories,  List<int> alertThresholds)  $default,) {final _that = this;
switch (_that) {
case _Budget():
return $default(_that.id,_that.name,_that.period,_that.totalLimit,_that.spent,_that.remaining,_that.percentUsed,_that.periodElapsedPercent,_that.onPace,_that.categories,_that.alertThresholds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String period,  Money totalLimit,  Money spent,  Money remaining,  int percentUsed,  int periodElapsedPercent,  bool onPace,  List<BudgetCategory> categories,  List<int> alertThresholds)?  $default,) {final _that = this;
switch (_that) {
case _Budget() when $default != null:
return $default(_that.id,_that.name,_that.period,_that.totalLimit,_that.spent,_that.remaining,_that.percentUsed,_that.periodElapsedPercent,_that.onPace,_that.categories,_that.alertThresholds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Budget implements Budget {
  const _Budget({required this.id, required this.name, required this.period, required this.totalLimit, required this.spent, required this.remaining, required this.percentUsed, required this.periodElapsedPercent, required this.onPace,  List<BudgetCategory> categories = const <BudgetCategory>[],  List<int> alertThresholds = const <int>[80, 100]}): _categories = categories,_alertThresholds = alertThresholds;
  factory _Budget.fromJson(Map<String, dynamic> json) => _$BudgetFromJson(json);

@override final  String id;
@override final  String name;
@override final  String period;
@override final  Money totalLimit;
@override final  Money spent;
@override final  Money remaining;
@override final  int percentUsed;
@override final  int periodElapsedPercent;
@override final  bool onPace;
 final  List<BudgetCategory> _categories;
@override@JsonKey() List<BudgetCategory> get categories {
  if (_categories is EqualUnmodifiableListView) return _categories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categories);
}

 final  List<int> _alertThresholds;
@override@JsonKey() List<int> get alertThresholds {
  if (_alertThresholds is EqualUnmodifiableListView) return _alertThresholds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_alertThresholds);
}


/// Create a copy of Budget
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BudgetCopyWith<_Budget> get copyWith => __$BudgetCopyWithImpl<_Budget>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BudgetToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Budget&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.period, period) || other.period == period)&&(identical(other.totalLimit, totalLimit) || other.totalLimit == totalLimit)&&(identical(other.spent, spent) || other.spent == spent)&&(identical(other.remaining, remaining) || other.remaining == remaining)&&(identical(other.percentUsed, percentUsed) || other.percentUsed == percentUsed)&&(identical(other.periodElapsedPercent, periodElapsedPercent) || other.periodElapsedPercent == periodElapsedPercent)&&(identical(other.onPace, onPace) || other.onPace == onPace)&&const DeepCollectionEquality().equals(other.categories, _categories)&&const DeepCollectionEquality().equals(other.alertThresholds, _alertThresholds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,period,totalLimit,spent,remaining,percentUsed,periodElapsedPercent,onPace,const DeepCollectionEquality().hash(_categories),const DeepCollectionEquality().hash(_alertThresholds));
}

@override
String toString() {
    return 'Budget(id: $id, name: $name, period: $period, totalLimit: $totalLimit, spent: $spent, remaining: $remaining, percentUsed: $percentUsed, periodElapsedPercent: $periodElapsedPercent, onPace: $onPace, categories: $categories, alertThresholds: $alertThresholds)';
}


}

/// @nodoc
abstract mixin class _$BudgetCopyWith<$Res> implements $BudgetCopyWith<$Res> {
  factory _$BudgetCopyWith(_Budget value, $Res Function(_Budget) _then) = __$BudgetCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String period, Money totalLimit, Money spent, Money remaining, int percentUsed, int periodElapsedPercent, bool onPace, List<BudgetCategory> categories, List<int> alertThresholds
});


@override $MoneyCopyWith<$Res> get totalLimit;@override $MoneyCopyWith<$Res> get spent;@override $MoneyCopyWith<$Res> get remaining;

}
/// @nodoc
class __$BudgetCopyWithImpl<$Res>
    implements _$BudgetCopyWith<$Res> {
  __$BudgetCopyWithImpl(this._self, this._then);

  final _Budget _self;
  final $Res Function(_Budget) _then;

/// Create a copy of Budget
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? period = null,Object? totalLimit = null,Object? spent = null,Object? remaining = null,Object? percentUsed = null,Object? periodElapsedPercent = null,Object? onPace = null,Object? categories = null,Object? alertThresholds = null,}) {
  return _then(_Budget(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as String,totalLimit: null == totalLimit ? _self.totalLimit : totalLimit // ignore: cast_nullable_to_non_nullable
as Money,spent: null == spent ? _self.spent : spent // ignore: cast_nullable_to_non_nullable
as Money,remaining: null == remaining ? _self.remaining : remaining // ignore: cast_nullable_to_non_nullable
as Money,percentUsed: null == percentUsed ? _self.percentUsed : percentUsed // ignore: cast_nullable_to_non_nullable
as int,periodElapsedPercent: null == periodElapsedPercent ? _self.periodElapsedPercent : periodElapsedPercent // ignore: cast_nullable_to_non_nullable
as int,onPace: null == onPace ? _self.onPace : onPace // ignore: cast_nullable_to_non_nullable
as bool,categories: null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as List<BudgetCategory>,alertThresholds: null == alertThresholds ? _self._alertThresholds : alertThresholds // ignore: cast_nullable_to_non_nullable
as List<int>,
  ));
}

/// Create a copy of Budget
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MoneyCopyWith<$Res> get totalLimit {
  
  return $MoneyCopyWith<$Res>(_self.totalLimit, (value) {
    return _then(_self.copyWith(totalLimit: value));
  });
}/// Create a copy of Budget
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MoneyCopyWith<$Res> get spent {
  
  return $MoneyCopyWith<$Res>(_self.spent, (value) {
    return _then(_self.copyWith(spent: value));
  });
}/// Create a copy of Budget
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MoneyCopyWith<$Res> get remaining {
  
  return $MoneyCopyWith<$Res>(_self.remaining, (value) {
    return _then(_self.copyWith(remaining: value));
  });
}
}


/// @nodoc
mixin _$Entry {

 String get id; Money get amount; String get category; String? get description; DateTime get date; String? get paymentMethod; bool get recurring;
/// Create a copy of Entry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EntryCopyWith<Entry> get copyWith => _$EntryCopyWithImpl<Entry>(this as Entry, _$identity);

  /// Serializes this Entry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Entry;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Entry&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.category, _this.category) || other.category == _this.category)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.date, _this.date) || other.date == _this.date)&&(identical(other.paymentMethod, _this.paymentMethod) || other.paymentMethod == _this.paymentMethod)&&(identical(other.recurring, _this.recurring) || other.recurring == _this.recurring));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Entry;
  return Object.hash(runtimeType,_this.id,_this.amount,_this.category,_this.description,_this.date,_this.paymentMethod,_this.recurring);
}

@override
String toString() {
  final _this = this as Entry;
  return 'Entry(id: ${_this.id}, amount: ${_this.amount}, category: ${_this.category}, description: ${_this.description}, date: ${_this.date}, paymentMethod: ${_this.paymentMethod}, recurring: ${_this.recurring})';
}


}

/// @nodoc
abstract mixin class $EntryCopyWith<$Res>  {
  factory $EntryCopyWith(Entry value, $Res Function(Entry) _then) = _$EntryCopyWithImpl;
@useResult
$Res call({
 String id, Money amount, String category, String? description, DateTime date, String? paymentMethod, bool recurring
});


$MoneyCopyWith<$Res> get amount;

}
/// @nodoc
class _$EntryCopyWithImpl<$Res>
    implements $EntryCopyWith<$Res> {
  _$EntryCopyWithImpl(this._self, this._then);

  final Entry _self;
  final $Res Function(Entry) _then;

/// Create a copy of Entry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? amount = null,Object? category = null,Object? description = freezed,Object? date = null,Object? paymentMethod = freezed,Object? recurring = null,}) {
  return _then(Entry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Money,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,paymentMethod: freezed == paymentMethod ? _self.paymentMethod : paymentMethod // ignore: cast_nullable_to_non_nullable
as String?,recurring: null == recurring ? _self.recurring : recurring // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of Entry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MoneyCopyWith<$Res> get amount {
  
  return $MoneyCopyWith<$Res>(_self.amount, (value) {
    return _then(_self.copyWith(amount: value));
  });
}
}


/// Adds pattern-matching-related methods to [Entry].
extension EntryPatterns on Entry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Entry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Entry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Entry value)  $default,){
final _that = this;
switch (_that) {
case _Entry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Entry value)?  $default,){
final _that = this;
switch (_that) {
case _Entry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  Money amount,  String category,  String? description,  DateTime date,  String? paymentMethod,  bool recurring)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Entry() when $default != null:
return $default(_that.id,_that.amount,_that.category,_that.description,_that.date,_that.paymentMethod,_that.recurring);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  Money amount,  String category,  String? description,  DateTime date,  String? paymentMethod,  bool recurring)  $default,) {final _that = this;
switch (_that) {
case _Entry():
return $default(_that.id,_that.amount,_that.category,_that.description,_that.date,_that.paymentMethod,_that.recurring);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  Money amount,  String category,  String? description,  DateTime date,  String? paymentMethod,  bool recurring)?  $default,) {final _that = this;
switch (_that) {
case _Entry() when $default != null:
return $default(_that.id,_that.amount,_that.category,_that.description,_that.date,_that.paymentMethod,_that.recurring);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Entry implements Entry {
  const _Entry({required this.id, required this.amount, required this.category, this.description, required this.date, this.paymentMethod, this.recurring = false});
  factory _Entry.fromJson(Map<String, dynamic> json) => _$EntryFromJson(json);

@override final  String id;
@override final  Money amount;
@override final  String category;
@override final  String? description;
@override final  DateTime date;
@override final  String? paymentMethod;
@override@JsonKey() final  bool recurring;

/// Create a copy of Entry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EntryCopyWith<_Entry> get copyWith => __$EntryCopyWithImpl<_Entry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EntryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Entry&&(identical(other.id, id) || other.id == id)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.category, category) || other.category == category)&&(identical(other.description, description) || other.description == description)&&(identical(other.date, date) || other.date == date)&&(identical(other.paymentMethod, paymentMethod) || other.paymentMethod == paymentMethod)&&(identical(other.recurring, recurring) || other.recurring == recurring));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,amount,category,description,date,paymentMethod,recurring);
}

@override
String toString() {
    return 'Entry(id: $id, amount: $amount, category: $category, description: $description, date: $date, paymentMethod: $paymentMethod, recurring: $recurring)';
}


}

/// @nodoc
abstract mixin class _$EntryCopyWith<$Res> implements $EntryCopyWith<$Res> {
  factory _$EntryCopyWith(_Entry value, $Res Function(_Entry) _then) = __$EntryCopyWithImpl;
@override @useResult
$Res call({
 String id, Money amount, String category, String? description, DateTime date, String? paymentMethod, bool recurring
});


@override $MoneyCopyWith<$Res> get amount;

}
/// @nodoc
class __$EntryCopyWithImpl<$Res>
    implements _$EntryCopyWith<$Res> {
  __$EntryCopyWithImpl(this._self, this._then);

  final _Entry _self;
  final $Res Function(_Entry) _then;

/// Create a copy of Entry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? amount = null,Object? category = null,Object? description = freezed,Object? date = null,Object? paymentMethod = freezed,Object? recurring = null,}) {
  return _then(_Entry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Money,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,paymentMethod: freezed == paymentMethod ? _self.paymentMethod : paymentMethod // ignore: cast_nullable_to_non_nullable
as String?,recurring: null == recurring ? _self.recurring : recurring // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of Entry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MoneyCopyWith<$Res> get amount {
  
  return $MoneyCopyWith<$Res>(_self.amount, (value) {
    return _then(_self.copyWith(amount: value));
  });
}
}

// dart format on
