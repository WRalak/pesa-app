// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dashboard.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LinkedAccount {

 String get id; String get kind; String get provider; String get displayName; String? get maskedIdentifier; String get currency; Money? get balance; String get balanceSource; DateTime? get balanceAsOf; bool get sandbox; String get status; bool get isDefault;
/// Create a copy of LinkedAccount
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LinkedAccountCopyWith<LinkedAccount> get copyWith => _$LinkedAccountCopyWithImpl<LinkedAccount>(this as LinkedAccount, _$identity);

  /// Serializes this LinkedAccount to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as LinkedAccount;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LinkedAccount&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.provider, _this.provider) || other.provider == _this.provider)&&(identical(other.displayName, _this.displayName) || other.displayName == _this.displayName)&&(identical(other.maskedIdentifier, _this.maskedIdentifier) || other.maskedIdentifier == _this.maskedIdentifier)&&(identical(other.currency, _this.currency) || other.currency == _this.currency)&&(identical(other.balance, _this.balance) || other.balance == _this.balance)&&(identical(other.balanceSource, _this.balanceSource) || other.balanceSource == _this.balanceSource)&&(identical(other.balanceAsOf, _this.balanceAsOf) || other.balanceAsOf == _this.balanceAsOf)&&(identical(other.sandbox, _this.sandbox) || other.sandbox == _this.sandbox)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.isDefault, _this.isDefault) || other.isDefault == _this.isDefault));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as LinkedAccount;
  return Object.hash(runtimeType,_this.id,_this.kind,_this.provider,_this.displayName,_this.maskedIdentifier,_this.currency,_this.balance,_this.balanceSource,_this.balanceAsOf,_this.sandbox,_this.status,_this.isDefault);
}

@override
String toString() {
  final _this = this as LinkedAccount;
  return 'LinkedAccount(id: ${_this.id}, kind: ${_this.kind}, provider: ${_this.provider}, displayName: ${_this.displayName}, maskedIdentifier: ${_this.maskedIdentifier}, currency: ${_this.currency}, balance: ${_this.balance}, balanceSource: ${_this.balanceSource}, balanceAsOf: ${_this.balanceAsOf}, sandbox: ${_this.sandbox}, status: ${_this.status}, isDefault: ${_this.isDefault})';
}


}

/// @nodoc
abstract mixin class $LinkedAccountCopyWith<$Res>  {
  factory $LinkedAccountCopyWith(LinkedAccount value, $Res Function(LinkedAccount) _then) = _$LinkedAccountCopyWithImpl;
@useResult
$Res call({
 String id, String kind, String provider, String displayName, String? maskedIdentifier, String currency, Money? balance, String balanceSource, DateTime? balanceAsOf, bool sandbox, String status, bool isDefault
});


$MoneyCopyWith<$Res>? get balance;

}
/// @nodoc
class _$LinkedAccountCopyWithImpl<$Res>
    implements $LinkedAccountCopyWith<$Res> {
  _$LinkedAccountCopyWithImpl(this._self, this._then);

  final LinkedAccount _self;
  final $Res Function(LinkedAccount) _then;

/// Create a copy of LinkedAccount
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kind = null,Object? provider = null,Object? displayName = null,Object? maskedIdentifier = freezed,Object? currency = null,Object? balance = freezed,Object? balanceSource = null,Object? balanceAsOf = freezed,Object? sandbox = null,Object? status = null,Object? isDefault = null,}) {
  return _then(LinkedAccount(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,maskedIdentifier: freezed == maskedIdentifier ? _self.maskedIdentifier : maskedIdentifier // ignore: cast_nullable_to_non_nullable
as String?,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,balance: freezed == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as Money?,balanceSource: null == balanceSource ? _self.balanceSource : balanceSource // ignore: cast_nullable_to_non_nullable
as String,balanceAsOf: freezed == balanceAsOf ? _self.balanceAsOf : balanceAsOf // ignore: cast_nullable_to_non_nullable
as DateTime?,sandbox: null == sandbox ? _self.sandbox : sandbox // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,isDefault: null == isDefault ? _self.isDefault : isDefault // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of LinkedAccount
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MoneyCopyWith<$Res>? get balance {
    if (_self.balance == null) {
    return null;
  }

  return $MoneyCopyWith<$Res>(_self.balance!, (value) {
    return _then(_self.copyWith(balance: value));
  });
}
}


/// Adds pattern-matching-related methods to [LinkedAccount].
extension LinkedAccountPatterns on LinkedAccount {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LinkedAccount value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LinkedAccount() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LinkedAccount value)  $default,){
final _that = this;
switch (_that) {
case _LinkedAccount():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LinkedAccount value)?  $default,){
final _that = this;
switch (_that) {
case _LinkedAccount() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String kind,  String provider,  String displayName,  String? maskedIdentifier,  String currency,  Money? balance,  String balanceSource,  DateTime? balanceAsOf,  bool sandbox,  String status,  bool isDefault)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LinkedAccount() when $default != null:
return $default(_that.id,_that.kind,_that.provider,_that.displayName,_that.maskedIdentifier,_that.currency,_that.balance,_that.balanceSource,_that.balanceAsOf,_that.sandbox,_that.status,_that.isDefault);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String kind,  String provider,  String displayName,  String? maskedIdentifier,  String currency,  Money? balance,  String balanceSource,  DateTime? balanceAsOf,  bool sandbox,  String status,  bool isDefault)  $default,) {final _that = this;
switch (_that) {
case _LinkedAccount():
return $default(_that.id,_that.kind,_that.provider,_that.displayName,_that.maskedIdentifier,_that.currency,_that.balance,_that.balanceSource,_that.balanceAsOf,_that.sandbox,_that.status,_that.isDefault);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String kind,  String provider,  String displayName,  String? maskedIdentifier,  String currency,  Money? balance,  String balanceSource,  DateTime? balanceAsOf,  bool sandbox,  String status,  bool isDefault)?  $default,) {final _that = this;
switch (_that) {
case _LinkedAccount() when $default != null:
return $default(_that.id,_that.kind,_that.provider,_that.displayName,_that.maskedIdentifier,_that.currency,_that.balance,_that.balanceSource,_that.balanceAsOf,_that.sandbox,_that.status,_that.isDefault);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LinkedAccount implements LinkedAccount {
  const _LinkedAccount({required this.id, required this.kind, required this.provider, required this.displayName, this.maskedIdentifier, required this.currency, this.balance, required this.balanceSource, this.balanceAsOf, this.sandbox = false, required this.status, this.isDefault = false});
  factory _LinkedAccount.fromJson(Map<String, dynamic> json) => _$LinkedAccountFromJson(json);

@override final  String id;
@override final  String kind;
@override final  String provider;
@override final  String displayName;
@override final  String? maskedIdentifier;
@override final  String currency;
@override final  Money? balance;
@override final  String balanceSource;
@override final  DateTime? balanceAsOf;
@override@JsonKey() final  bool sandbox;
@override final  String status;
@override@JsonKey() final  bool isDefault;

/// Create a copy of LinkedAccount
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LinkedAccountCopyWith<_LinkedAccount> get copyWith => __$LinkedAccountCopyWithImpl<_LinkedAccount>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LinkedAccountToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LinkedAccount&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.maskedIdentifier, maskedIdentifier) || other.maskedIdentifier == maskedIdentifier)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.balance, balance) || other.balance == balance)&&(identical(other.balanceSource, balanceSource) || other.balanceSource == balanceSource)&&(identical(other.balanceAsOf, balanceAsOf) || other.balanceAsOf == balanceAsOf)&&(identical(other.sandbox, sandbox) || other.sandbox == sandbox)&&(identical(other.status, status) || other.status == status)&&(identical(other.isDefault, isDefault) || other.isDefault == isDefault));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,kind,provider,displayName,maskedIdentifier,currency,balance,balanceSource,balanceAsOf,sandbox,status,isDefault);
}

@override
String toString() {
    return 'LinkedAccount(id: $id, kind: $kind, provider: $provider, displayName: $displayName, maskedIdentifier: $maskedIdentifier, currency: $currency, balance: $balance, balanceSource: $balanceSource, balanceAsOf: $balanceAsOf, sandbox: $sandbox, status: $status, isDefault: $isDefault)';
}


}

/// @nodoc
abstract mixin class _$LinkedAccountCopyWith<$Res> implements $LinkedAccountCopyWith<$Res> {
  factory _$LinkedAccountCopyWith(_LinkedAccount value, $Res Function(_LinkedAccount) _then) = __$LinkedAccountCopyWithImpl;
@override @useResult
$Res call({
 String id, String kind, String provider, String displayName, String? maskedIdentifier, String currency, Money? balance, String balanceSource, DateTime? balanceAsOf, bool sandbox, String status, bool isDefault
});


@override $MoneyCopyWith<$Res>? get balance;

}
/// @nodoc
class __$LinkedAccountCopyWithImpl<$Res>
    implements _$LinkedAccountCopyWith<$Res> {
  __$LinkedAccountCopyWithImpl(this._self, this._then);

  final _LinkedAccount _self;
  final $Res Function(_LinkedAccount) _then;

/// Create a copy of LinkedAccount
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kind = null,Object? provider = null,Object? displayName = null,Object? maskedIdentifier = freezed,Object? currency = null,Object? balance = freezed,Object? balanceSource = null,Object? balanceAsOf = freezed,Object? sandbox = null,Object? status = null,Object? isDefault = null,}) {
  return _then(_LinkedAccount(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,maskedIdentifier: freezed == maskedIdentifier ? _self.maskedIdentifier : maskedIdentifier // ignore: cast_nullable_to_non_nullable
as String?,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,balance: freezed == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as Money?,balanceSource: null == balanceSource ? _self.balanceSource : balanceSource // ignore: cast_nullable_to_non_nullable
as String,balanceAsOf: freezed == balanceAsOf ? _self.balanceAsOf : balanceAsOf // ignore: cast_nullable_to_non_nullable
as DateTime?,sandbox: null == sandbox ? _self.sandbox : sandbox // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,isDefault: null == isDefault ? _self.isDefault : isDefault // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of LinkedAccount
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MoneyCopyWith<$Res>? get balance {
    if (_self.balance == null) {
    return null;
  }

  return $MoneyCopyWith<$Res>(_self.balance!, (value) {
    return _then(_self.copyWith(balance: value));
  });
}
}


/// @nodoc
mixin _$BalanceGroup {

 Money? get total; int get accountCount; DateTime? get oldestAsOf; bool get sandbox;
/// Create a copy of BalanceGroup
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BalanceGroupCopyWith<BalanceGroup> get copyWith => _$BalanceGroupCopyWithImpl<BalanceGroup>(this as BalanceGroup, _$identity);

  /// Serializes this BalanceGroup to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BalanceGroup;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BalanceGroup&&(identical(other.total, _this.total) || other.total == _this.total)&&(identical(other.accountCount, _this.accountCount) || other.accountCount == _this.accountCount)&&(identical(other.oldestAsOf, _this.oldestAsOf) || other.oldestAsOf == _this.oldestAsOf)&&(identical(other.sandbox, _this.sandbox) || other.sandbox == _this.sandbox));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BalanceGroup;
  return Object.hash(runtimeType,_this.total,_this.accountCount,_this.oldestAsOf,_this.sandbox);
}

@override
String toString() {
  final _this = this as BalanceGroup;
  return 'BalanceGroup(total: ${_this.total}, accountCount: ${_this.accountCount}, oldestAsOf: ${_this.oldestAsOf}, sandbox: ${_this.sandbox})';
}


}

/// @nodoc
abstract mixin class $BalanceGroupCopyWith<$Res>  {
  factory $BalanceGroupCopyWith(BalanceGroup value, $Res Function(BalanceGroup) _then) = _$BalanceGroupCopyWithImpl;
@useResult
$Res call({
 Money? total, int accountCount, DateTime? oldestAsOf, bool sandbox
});


$MoneyCopyWith<$Res>? get total;

}
/// @nodoc
class _$BalanceGroupCopyWithImpl<$Res>
    implements $BalanceGroupCopyWith<$Res> {
  _$BalanceGroupCopyWithImpl(this._self, this._then);

  final BalanceGroup _self;
  final $Res Function(BalanceGroup) _then;

/// Create a copy of BalanceGroup
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? total = freezed,Object? accountCount = null,Object? oldestAsOf = freezed,Object? sandbox = null,}) {
  return _then(BalanceGroup(
total: freezed == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as Money?,accountCount: null == accountCount ? _self.accountCount : accountCount // ignore: cast_nullable_to_non_nullable
as int,oldestAsOf: freezed == oldestAsOf ? _self.oldestAsOf : oldestAsOf // ignore: cast_nullable_to_non_nullable
as DateTime?,sandbox: null == sandbox ? _self.sandbox : sandbox // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of BalanceGroup
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MoneyCopyWith<$Res>? get total {
    if (_self.total == null) {
    return null;
  }

  return $MoneyCopyWith<$Res>(_self.total!, (value) {
    return _then(_self.copyWith(total: value));
  });
}
}


/// Adds pattern-matching-related methods to [BalanceGroup].
extension BalanceGroupPatterns on BalanceGroup {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BalanceGroup value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BalanceGroup() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BalanceGroup value)  $default,){
final _that = this;
switch (_that) {
case _BalanceGroup():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BalanceGroup value)?  $default,){
final _that = this;
switch (_that) {
case _BalanceGroup() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Money? total,  int accountCount,  DateTime? oldestAsOf,  bool sandbox)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BalanceGroup() when $default != null:
return $default(_that.total,_that.accountCount,_that.oldestAsOf,_that.sandbox);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Money? total,  int accountCount,  DateTime? oldestAsOf,  bool sandbox)  $default,) {final _that = this;
switch (_that) {
case _BalanceGroup():
return $default(_that.total,_that.accountCount,_that.oldestAsOf,_that.sandbox);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Money? total,  int accountCount,  DateTime? oldestAsOf,  bool sandbox)?  $default,) {final _that = this;
switch (_that) {
case _BalanceGroup() when $default != null:
return $default(_that.total,_that.accountCount,_that.oldestAsOf,_that.sandbox);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BalanceGroup implements BalanceGroup {
  const _BalanceGroup({this.total, this.accountCount = 0, this.oldestAsOf, this.sandbox = false});
  factory _BalanceGroup.fromJson(Map<String, dynamic> json) => _$BalanceGroupFromJson(json);

@override final  Money? total;
@override@JsonKey() final  int accountCount;
@override final  DateTime? oldestAsOf;
@override@JsonKey() final  bool sandbox;

/// Create a copy of BalanceGroup
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BalanceGroupCopyWith<_BalanceGroup> get copyWith => __$BalanceGroupCopyWithImpl<_BalanceGroup>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BalanceGroupToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BalanceGroup&&(identical(other.total, total) || other.total == total)&&(identical(other.accountCount, accountCount) || other.accountCount == accountCount)&&(identical(other.oldestAsOf, oldestAsOf) || other.oldestAsOf == oldestAsOf)&&(identical(other.sandbox, sandbox) || other.sandbox == sandbox));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,total,accountCount,oldestAsOf,sandbox);
}

@override
String toString() {
    return 'BalanceGroup(total: $total, accountCount: $accountCount, oldestAsOf: $oldestAsOf, sandbox: $sandbox)';
}


}

/// @nodoc
abstract mixin class _$BalanceGroupCopyWith<$Res> implements $BalanceGroupCopyWith<$Res> {
  factory _$BalanceGroupCopyWith(_BalanceGroup value, $Res Function(_BalanceGroup) _then) = __$BalanceGroupCopyWithImpl;
@override @useResult
$Res call({
 Money? total, int accountCount, DateTime? oldestAsOf, bool sandbox
});


@override $MoneyCopyWith<$Res>? get total;

}
/// @nodoc
class __$BalanceGroupCopyWithImpl<$Res>
    implements _$BalanceGroupCopyWith<$Res> {
  __$BalanceGroupCopyWithImpl(this._self, this._then);

  final _BalanceGroup _self;
  final $Res Function(_BalanceGroup) _then;

/// Create a copy of BalanceGroup
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? total = freezed,Object? accountCount = null,Object? oldestAsOf = freezed,Object? sandbox = null,}) {
  return _then(_BalanceGroup(
total: freezed == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as Money?,accountCount: null == accountCount ? _self.accountCount : accountCount // ignore: cast_nullable_to_non_nullable
as int,oldestAsOf: freezed == oldestAsOf ? _self.oldestAsOf : oldestAsOf // ignore: cast_nullable_to_non_nullable
as DateTime?,sandbox: null == sandbox ? _self.sandbox : sandbox // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of BalanceGroup
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MoneyCopyWith<$Res>? get total {
    if (_self.total == null) {
    return null;
  }

  return $MoneyCopyWith<$Res>(_self.total!, (value) {
    return _then(_self.copyWith(total: value));
  });
}
}


/// @nodoc
mixin _$CategoryAmount {

 String get category; Money get amount; double get share;
/// Create a copy of CategoryAmount
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CategoryAmountCopyWith<CategoryAmount> get copyWith => _$CategoryAmountCopyWithImpl<CategoryAmount>(this as CategoryAmount, _$identity);

  /// Serializes this CategoryAmount to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CategoryAmount;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CategoryAmount&&(identical(other.category, _this.category) || other.category == _this.category)&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.share, _this.share) || other.share == _this.share));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CategoryAmount;
  return Object.hash(runtimeType,_this.category,_this.amount,_this.share);
}

@override
String toString() {
  final _this = this as CategoryAmount;
  return 'CategoryAmount(category: ${_this.category}, amount: ${_this.amount}, share: ${_this.share})';
}


}

/// @nodoc
abstract mixin class $CategoryAmountCopyWith<$Res>  {
  factory $CategoryAmountCopyWith(CategoryAmount value, $Res Function(CategoryAmount) _then) = _$CategoryAmountCopyWithImpl;
@useResult
$Res call({
 String category, Money amount, double share
});


$MoneyCopyWith<$Res> get amount;

}
/// @nodoc
class _$CategoryAmountCopyWithImpl<$Res>
    implements $CategoryAmountCopyWith<$Res> {
  _$CategoryAmountCopyWithImpl(this._self, this._then);

  final CategoryAmount _self;
  final $Res Function(CategoryAmount) _then;

/// Create a copy of CategoryAmount
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? category = null,Object? amount = null,Object? share = null,}) {
  return _then(CategoryAmount(
category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Money,share: null == share ? _self.share : share // ignore: cast_nullable_to_non_nullable
as double,
  ));
}
/// Create a copy of CategoryAmount
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MoneyCopyWith<$Res> get amount {
  
  return $MoneyCopyWith<$Res>(_self.amount, (value) {
    return _then(_self.copyWith(amount: value));
  });
}
}


/// Adds pattern-matching-related methods to [CategoryAmount].
extension CategoryAmountPatterns on CategoryAmount {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CategoryAmount value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CategoryAmount() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CategoryAmount value)  $default,){
final _that = this;
switch (_that) {
case _CategoryAmount():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CategoryAmount value)?  $default,){
final _that = this;
switch (_that) {
case _CategoryAmount() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String category,  Money amount,  double share)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CategoryAmount() when $default != null:
return $default(_that.category,_that.amount,_that.share);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String category,  Money amount,  double share)  $default,) {final _that = this;
switch (_that) {
case _CategoryAmount():
return $default(_that.category,_that.amount,_that.share);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String category,  Money amount,  double share)?  $default,) {final _that = this;
switch (_that) {
case _CategoryAmount() when $default != null:
return $default(_that.category,_that.amount,_that.share);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CategoryAmount implements CategoryAmount {
  const _CategoryAmount({required this.category, required this.amount, this.share = 0});
  factory _CategoryAmount.fromJson(Map<String, dynamic> json) => _$CategoryAmountFromJson(json);

@override final  String category;
@override final  Money amount;
@override@JsonKey() final  double share;

/// Create a copy of CategoryAmount
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CategoryAmountCopyWith<_CategoryAmount> get copyWith => __$CategoryAmountCopyWithImpl<_CategoryAmount>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CategoryAmountToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CategoryAmount&&(identical(other.category, category) || other.category == category)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.share, share) || other.share == share));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,category,amount,share);
}

@override
String toString() {
    return 'CategoryAmount(category: $category, amount: $amount, share: $share)';
}


}

/// @nodoc
abstract mixin class _$CategoryAmountCopyWith<$Res> implements $CategoryAmountCopyWith<$Res> {
  factory _$CategoryAmountCopyWith(_CategoryAmount value, $Res Function(_CategoryAmount) _then) = __$CategoryAmountCopyWithImpl;
@override @useResult
$Res call({
 String category, Money amount, double share
});


@override $MoneyCopyWith<$Res> get amount;

}
/// @nodoc
class __$CategoryAmountCopyWithImpl<$Res>
    implements _$CategoryAmountCopyWith<$Res> {
  __$CategoryAmountCopyWithImpl(this._self, this._then);

  final _CategoryAmount _self;
  final $Res Function(_CategoryAmount) _then;

/// Create a copy of CategoryAmount
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? category = null,Object? amount = null,Object? share = null,}) {
  return _then(_CategoryAmount(
category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Money,share: null == share ? _self.share : share // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

/// Create a copy of CategoryAmount
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MoneyCopyWith<$Res> get amount {
  
  return $MoneyCopyWith<$Res>(_self.amount, (value) {
    return _then(_self.copyWith(amount: value));
  });
}
}


/// @nodoc
mixin _$DailySpend {

 String get date; Money get spent;
/// Create a copy of DailySpend
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DailySpendCopyWith<DailySpend> get copyWith => _$DailySpendCopyWithImpl<DailySpend>(this as DailySpend, _$identity);

  /// Serializes this DailySpend to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as DailySpend;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DailySpend&&(identical(other.date, _this.date) || other.date == _this.date)&&(identical(other.spent, _this.spent) || other.spent == _this.spent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as DailySpend;
  return Object.hash(runtimeType,_this.date,_this.spent);
}

@override
String toString() {
  final _this = this as DailySpend;
  return 'DailySpend(date: ${_this.date}, spent: ${_this.spent})';
}


}

/// @nodoc
abstract mixin class $DailySpendCopyWith<$Res>  {
  factory $DailySpendCopyWith(DailySpend value, $Res Function(DailySpend) _then) = _$DailySpendCopyWithImpl;
@useResult
$Res call({
 String date, Money spent
});


$MoneyCopyWith<$Res> get spent;

}
/// @nodoc
class _$DailySpendCopyWithImpl<$Res>
    implements $DailySpendCopyWith<$Res> {
  _$DailySpendCopyWithImpl(this._self, this._then);

  final DailySpend _self;
  final $Res Function(DailySpend) _then;

/// Create a copy of DailySpend
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? spent = null,}) {
  return _then(DailySpend(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,spent: null == spent ? _self.spent : spent // ignore: cast_nullable_to_non_nullable
as Money,
  ));
}
/// Create a copy of DailySpend
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MoneyCopyWith<$Res> get spent {
  
  return $MoneyCopyWith<$Res>(_self.spent, (value) {
    return _then(_self.copyWith(spent: value));
  });
}
}


/// Adds pattern-matching-related methods to [DailySpend].
extension DailySpendPatterns on DailySpend {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DailySpend value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DailySpend() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DailySpend value)  $default,){
final _that = this;
switch (_that) {
case _DailySpend():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DailySpend value)?  $default,){
final _that = this;
switch (_that) {
case _DailySpend() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String date,  Money spent)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DailySpend() when $default != null:
return $default(_that.date,_that.spent);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String date,  Money spent)  $default,) {final _that = this;
switch (_that) {
case _DailySpend():
return $default(_that.date,_that.spent);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String date,  Money spent)?  $default,) {final _that = this;
switch (_that) {
case _DailySpend() when $default != null:
return $default(_that.date,_that.spent);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DailySpend implements DailySpend {
  const _DailySpend({required this.date, required this.spent});
  factory _DailySpend.fromJson(Map<String, dynamic> json) => _$DailySpendFromJson(json);

@override final  String date;
@override final  Money spent;

/// Create a copy of DailySpend
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DailySpendCopyWith<_DailySpend> get copyWith => __$DailySpendCopyWithImpl<_DailySpend>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DailySpendToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DailySpend&&(identical(other.date, date) || other.date == date)&&(identical(other.spent, spent) || other.spent == spent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,date,spent);
}

@override
String toString() {
    return 'DailySpend(date: $date, spent: $spent)';
}


}

/// @nodoc
abstract mixin class _$DailySpendCopyWith<$Res> implements $DailySpendCopyWith<$Res> {
  factory _$DailySpendCopyWith(_DailySpend value, $Res Function(_DailySpend) _then) = __$DailySpendCopyWithImpl;
@override @useResult
$Res call({
 String date, Money spent
});


@override $MoneyCopyWith<$Res> get spent;

}
/// @nodoc
class __$DailySpendCopyWithImpl<$Res>
    implements _$DailySpendCopyWith<$Res> {
  __$DailySpendCopyWithImpl(this._self, this._then);

  final _DailySpend _self;
  final $Res Function(_DailySpend) _then;

/// Create a copy of DailySpend
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? spent = null,}) {
  return _then(_DailySpend(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,spent: null == spent ? _self.spent : spent // ignore: cast_nullable_to_non_nullable
as Money,
  ));
}

/// Create a copy of DailySpend
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MoneyCopyWith<$Res> get spent {
  
  return $MoneyCopyWith<$Res>(_self.spent, (value) {
    return _then(_self.copyWith(spent: value));
  });
}
}


/// @nodoc
mixin _$MonthSummary {

 Money get income; Money get expenses; Money get net; List<CategoryAmount> get byCategory; double? get changeInExpensesPercent; List<DailySpend> get daily; String? get basisNote;
/// Create a copy of MonthSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MonthSummaryCopyWith<MonthSummary> get copyWith => _$MonthSummaryCopyWithImpl<MonthSummary>(this as MonthSummary, _$identity);

  /// Serializes this MonthSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as MonthSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MonthSummary&&(identical(other.income, _this.income) || other.income == _this.income)&&(identical(other.expenses, _this.expenses) || other.expenses == _this.expenses)&&(identical(other.net, _this.net) || other.net == _this.net)&&const DeepCollectionEquality().equals(other.byCategory, _this.byCategory)&&(identical(other.changeInExpensesPercent, _this.changeInExpensesPercent) || other.changeInExpensesPercent == _this.changeInExpensesPercent)&&const DeepCollectionEquality().equals(other.daily, _this.daily)&&(identical(other.basisNote, _this.basisNote) || other.basisNote == _this.basisNote));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as MonthSummary;
  return Object.hash(runtimeType,_this.income,_this.expenses,_this.net,const DeepCollectionEquality().hash(_this.byCategory),_this.changeInExpensesPercent,const DeepCollectionEquality().hash(_this.daily),_this.basisNote);
}

@override
String toString() {
  final _this = this as MonthSummary;
  return 'MonthSummary(income: ${_this.income}, expenses: ${_this.expenses}, net: ${_this.net}, byCategory: ${_this.byCategory}, changeInExpensesPercent: ${_this.changeInExpensesPercent}, daily: ${_this.daily}, basisNote: ${_this.basisNote})';
}


}

/// @nodoc
abstract mixin class $MonthSummaryCopyWith<$Res>  {
  factory $MonthSummaryCopyWith(MonthSummary value, $Res Function(MonthSummary) _then) = _$MonthSummaryCopyWithImpl;
@useResult
$Res call({
 Money income, Money expenses, Money net, List<CategoryAmount> byCategory, double? changeInExpensesPercent, List<DailySpend> daily, String? basisNote
});


$MoneyCopyWith<$Res> get income;$MoneyCopyWith<$Res> get expenses;$MoneyCopyWith<$Res> get net;

}
/// @nodoc
class _$MonthSummaryCopyWithImpl<$Res>
    implements $MonthSummaryCopyWith<$Res> {
  _$MonthSummaryCopyWithImpl(this._self, this._then);

  final MonthSummary _self;
  final $Res Function(MonthSummary) _then;

/// Create a copy of MonthSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? income = null,Object? expenses = null,Object? net = null,Object? byCategory = null,Object? changeInExpensesPercent = freezed,Object? daily = null,Object? basisNote = freezed,}) {
  return _then(MonthSummary(
income: null == income ? _self.income : income // ignore: cast_nullable_to_non_nullable
as Money,expenses: null == expenses ? _self.expenses : expenses // ignore: cast_nullable_to_non_nullable
as Money,net: null == net ? _self.net : net // ignore: cast_nullable_to_non_nullable
as Money,byCategory: null == byCategory ? _self.byCategory : byCategory // ignore: cast_nullable_to_non_nullable
as List<CategoryAmount>,changeInExpensesPercent: freezed == changeInExpensesPercent ? _self.changeInExpensesPercent : changeInExpensesPercent // ignore: cast_nullable_to_non_nullable
as double?,daily: null == daily ? _self.daily : daily // ignore: cast_nullable_to_non_nullable
as List<DailySpend>,basisNote: freezed == basisNote ? _self.basisNote : basisNote // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of MonthSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MoneyCopyWith<$Res> get income {
  
  return $MoneyCopyWith<$Res>(_self.income, (value) {
    return _then(_self.copyWith(income: value));
  });
}/// Create a copy of MonthSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MoneyCopyWith<$Res> get expenses {
  
  return $MoneyCopyWith<$Res>(_self.expenses, (value) {
    return _then(_self.copyWith(expenses: value));
  });
}/// Create a copy of MonthSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MoneyCopyWith<$Res> get net {
  
  return $MoneyCopyWith<$Res>(_self.net, (value) {
    return _then(_self.copyWith(net: value));
  });
}
}


/// Adds pattern-matching-related methods to [MonthSummary].
extension MonthSummaryPatterns on MonthSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MonthSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MonthSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MonthSummary value)  $default,){
final _that = this;
switch (_that) {
case _MonthSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MonthSummary value)?  $default,){
final _that = this;
switch (_that) {
case _MonthSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Money income,  Money expenses,  Money net,  List<CategoryAmount> byCategory,  double? changeInExpensesPercent,  List<DailySpend> daily,  String? basisNote)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MonthSummary() when $default != null:
return $default(_that.income,_that.expenses,_that.net,_that.byCategory,_that.changeInExpensesPercent,_that.daily,_that.basisNote);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Money income,  Money expenses,  Money net,  List<CategoryAmount> byCategory,  double? changeInExpensesPercent,  List<DailySpend> daily,  String? basisNote)  $default,) {final _that = this;
switch (_that) {
case _MonthSummary():
return $default(_that.income,_that.expenses,_that.net,_that.byCategory,_that.changeInExpensesPercent,_that.daily,_that.basisNote);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Money income,  Money expenses,  Money net,  List<CategoryAmount> byCategory,  double? changeInExpensesPercent,  List<DailySpend> daily,  String? basisNote)?  $default,) {final _that = this;
switch (_that) {
case _MonthSummary() when $default != null:
return $default(_that.income,_that.expenses,_that.net,_that.byCategory,_that.changeInExpensesPercent,_that.daily,_that.basisNote);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MonthSummary implements MonthSummary {
  const _MonthSummary({required this.income, required this.expenses, required this.net,  List<CategoryAmount> byCategory = const <CategoryAmount>[], this.changeInExpensesPercent,  List<DailySpend> daily = const <DailySpend>[], this.basisNote}): _byCategory = byCategory,_daily = daily;
  factory _MonthSummary.fromJson(Map<String, dynamic> json) => _$MonthSummaryFromJson(json);

@override final  Money income;
@override final  Money expenses;
@override final  Money net;
 final  List<CategoryAmount> _byCategory;
@override@JsonKey() List<CategoryAmount> get byCategory {
  if (_byCategory is EqualUnmodifiableListView) return _byCategory;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_byCategory);
}

@override final  double? changeInExpensesPercent;
 final  List<DailySpend> _daily;
@override@JsonKey() List<DailySpend> get daily {
  if (_daily is EqualUnmodifiableListView) return _daily;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_daily);
}

@override final  String? basisNote;

/// Create a copy of MonthSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MonthSummaryCopyWith<_MonthSummary> get copyWith => __$MonthSummaryCopyWithImpl<_MonthSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MonthSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MonthSummary&&(identical(other.income, income) || other.income == income)&&(identical(other.expenses, expenses) || other.expenses == expenses)&&(identical(other.net, net) || other.net == net)&&const DeepCollectionEquality().equals(other.byCategory, _byCategory)&&(identical(other.changeInExpensesPercent, changeInExpensesPercent) || other.changeInExpensesPercent == changeInExpensesPercent)&&const DeepCollectionEquality().equals(other.daily, _daily)&&(identical(other.basisNote, basisNote) || other.basisNote == basisNote));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,income,expenses,net,const DeepCollectionEquality().hash(_byCategory),changeInExpensesPercent,const DeepCollectionEquality().hash(_daily),basisNote);
}

@override
String toString() {
    return 'MonthSummary(income: $income, expenses: $expenses, net: $net, byCategory: $byCategory, changeInExpensesPercent: $changeInExpensesPercent, daily: $daily, basisNote: $basisNote)';
}


}

/// @nodoc
abstract mixin class _$MonthSummaryCopyWith<$Res> implements $MonthSummaryCopyWith<$Res> {
  factory _$MonthSummaryCopyWith(_MonthSummary value, $Res Function(_MonthSummary) _then) = __$MonthSummaryCopyWithImpl;
@override @useResult
$Res call({
 Money income, Money expenses, Money net, List<CategoryAmount> byCategory, double? changeInExpensesPercent, List<DailySpend> daily, String? basisNote
});


@override $MoneyCopyWith<$Res> get income;@override $MoneyCopyWith<$Res> get expenses;@override $MoneyCopyWith<$Res> get net;

}
/// @nodoc
class __$MonthSummaryCopyWithImpl<$Res>
    implements _$MonthSummaryCopyWith<$Res> {
  __$MonthSummaryCopyWithImpl(this._self, this._then);

  final _MonthSummary _self;
  final $Res Function(_MonthSummary) _then;

/// Create a copy of MonthSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? income = null,Object? expenses = null,Object? net = null,Object? byCategory = null,Object? changeInExpensesPercent = freezed,Object? daily = null,Object? basisNote = freezed,}) {
  return _then(_MonthSummary(
income: null == income ? _self.income : income // ignore: cast_nullable_to_non_nullable
as Money,expenses: null == expenses ? _self.expenses : expenses // ignore: cast_nullable_to_non_nullable
as Money,net: null == net ? _self.net : net // ignore: cast_nullable_to_non_nullable
as Money,byCategory: null == byCategory ? _self._byCategory : byCategory // ignore: cast_nullable_to_non_nullable
as List<CategoryAmount>,changeInExpensesPercent: freezed == changeInExpensesPercent ? _self.changeInExpensesPercent : changeInExpensesPercent // ignore: cast_nullable_to_non_nullable
as double?,daily: null == daily ? _self._daily : daily // ignore: cast_nullable_to_non_nullable
as List<DailySpend>,basisNote: freezed == basisNote ? _self.basisNote : basisNote // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of MonthSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MoneyCopyWith<$Res> get income {
  
  return $MoneyCopyWith<$Res>(_self.income, (value) {
    return _then(_self.copyWith(income: value));
  });
}/// Create a copy of MonthSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MoneyCopyWith<$Res> get expenses {
  
  return $MoneyCopyWith<$Res>(_self.expenses, (value) {
    return _then(_self.copyWith(expenses: value));
  });
}/// Create a copy of MonthSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MoneyCopyWith<$Res> get net {
  
  return $MoneyCopyWith<$Res>(_self.net, (value) {
    return _then(_self.copyWith(net: value));
  });
}
}

/// @nodoc
mixin _$Dashboard {

 String? get greetingName; bool get hideBalances; BalanceGroup get verified; BalanceGroup get manual; List<LinkedAccount> get accounts; MonthSummary get month; List<Txn> get recentTransactions; int get pendingTransactions; int get unreadNotifications; Map<String, dynamic>? get savings; Map<String, dynamic>? get budget;
/// Create a copy of Dashboard
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DashboardCopyWith<Dashboard> get copyWith => _$DashboardCopyWithImpl<Dashboard>(this as Dashboard, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Dashboard;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Dashboard&&(identical(other.greetingName, _this.greetingName) || other.greetingName == _this.greetingName)&&(identical(other.hideBalances, _this.hideBalances) || other.hideBalances == _this.hideBalances)&&(identical(other.verified, _this.verified) || other.verified == _this.verified)&&(identical(other.manual, _this.manual) || other.manual == _this.manual)&&const DeepCollectionEquality().equals(other.accounts, _this.accounts)&&(identical(other.month, _this.month) || other.month == _this.month)&&const DeepCollectionEquality().equals(other.recentTransactions, _this.recentTransactions)&&(identical(other.pendingTransactions, _this.pendingTransactions) || other.pendingTransactions == _this.pendingTransactions)&&(identical(other.unreadNotifications, _this.unreadNotifications) || other.unreadNotifications == _this.unreadNotifications)&&const DeepCollectionEquality().equals(other.savings, _this.savings)&&const DeepCollectionEquality().equals(other.budget, _this.budget));
}


@override
int get hashCode {
  final _this = this as Dashboard;
  return Object.hash(runtimeType,_this.greetingName,_this.hideBalances,_this.verified,_this.manual,const DeepCollectionEquality().hash(_this.accounts),_this.month,const DeepCollectionEquality().hash(_this.recentTransactions),_this.pendingTransactions,_this.unreadNotifications,const DeepCollectionEquality().hash(_this.savings),const DeepCollectionEquality().hash(_this.budget));
}

@override
String toString() {
  final _this = this as Dashboard;
  return 'Dashboard(greetingName: ${_this.greetingName}, hideBalances: ${_this.hideBalances}, verified: ${_this.verified}, manual: ${_this.manual}, accounts: ${_this.accounts}, month: ${_this.month}, recentTransactions: ${_this.recentTransactions}, pendingTransactions: ${_this.pendingTransactions}, unreadNotifications: ${_this.unreadNotifications}, savings: ${_this.savings}, budget: ${_this.budget})';
}


}

/// @nodoc
abstract mixin class $DashboardCopyWith<$Res>  {
  factory $DashboardCopyWith(Dashboard value, $Res Function(Dashboard) _then) = _$DashboardCopyWithImpl;
@useResult
$Res call({
 String? greetingName, bool hideBalances, BalanceGroup verified, BalanceGroup manual, List<LinkedAccount> accounts, MonthSummary month, List<Txn> recentTransactions, int pendingTransactions, int unreadNotifications, Map<String, dynamic>? savings, Map<String, dynamic>? budget
});


$BalanceGroupCopyWith<$Res> get verified;$BalanceGroupCopyWith<$Res> get manual;$MonthSummaryCopyWith<$Res> get month;

}
/// @nodoc
class _$DashboardCopyWithImpl<$Res>
    implements $DashboardCopyWith<$Res> {
  _$DashboardCopyWithImpl(this._self, this._then);

  final Dashboard _self;
  final $Res Function(Dashboard) _then;

/// Create a copy of Dashboard
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? greetingName = freezed,Object? hideBalances = null,Object? verified = null,Object? manual = null,Object? accounts = null,Object? month = null,Object? recentTransactions = null,Object? pendingTransactions = null,Object? unreadNotifications = null,Object? savings = freezed,Object? budget = freezed,}) {
  return _then(Dashboard(
greetingName: freezed == greetingName ? _self.greetingName : greetingName // ignore: cast_nullable_to_non_nullable
as String?,hideBalances: null == hideBalances ? _self.hideBalances : hideBalances // ignore: cast_nullable_to_non_nullable
as bool,verified: null == verified ? _self.verified : verified // ignore: cast_nullable_to_non_nullable
as BalanceGroup,manual: null == manual ? _self.manual : manual // ignore: cast_nullable_to_non_nullable
as BalanceGroup,accounts: null == accounts ? _self.accounts : accounts // ignore: cast_nullable_to_non_nullable
as List<LinkedAccount>,month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as MonthSummary,recentTransactions: null == recentTransactions ? _self.recentTransactions : recentTransactions // ignore: cast_nullable_to_non_nullable
as List<Txn>,pendingTransactions: null == pendingTransactions ? _self.pendingTransactions : pendingTransactions // ignore: cast_nullable_to_non_nullable
as int,unreadNotifications: null == unreadNotifications ? _self.unreadNotifications : unreadNotifications // ignore: cast_nullable_to_non_nullable
as int,savings: freezed == savings ? _self.savings : savings // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,budget: freezed == budget ? _self.budget : budget // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}
/// Create a copy of Dashboard
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BalanceGroupCopyWith<$Res> get verified {
  
  return $BalanceGroupCopyWith<$Res>(_self.verified, (value) {
    return _then(_self.copyWith(verified: value));
  });
}/// Create a copy of Dashboard
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BalanceGroupCopyWith<$Res> get manual {
  
  return $BalanceGroupCopyWith<$Res>(_self.manual, (value) {
    return _then(_self.copyWith(manual: value));
  });
}/// Create a copy of Dashboard
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MonthSummaryCopyWith<$Res> get month {
  
  return $MonthSummaryCopyWith<$Res>(_self.month, (value) {
    return _then(_self.copyWith(month: value));
  });
}
}


/// Adds pattern-matching-related methods to [Dashboard].
extension DashboardPatterns on Dashboard {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Dashboard value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Dashboard() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Dashboard value)  $default,){
final _that = this;
switch (_that) {
case _Dashboard():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Dashboard value)?  $default,){
final _that = this;
switch (_that) {
case _Dashboard() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? greetingName,  bool hideBalances,  BalanceGroup verified,  BalanceGroup manual,  List<LinkedAccount> accounts,  MonthSummary month,  List<Txn> recentTransactions,  int pendingTransactions,  int unreadNotifications,  Map<String, dynamic>? savings,  Map<String, dynamic>? budget)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Dashboard() when $default != null:
return $default(_that.greetingName,_that.hideBalances,_that.verified,_that.manual,_that.accounts,_that.month,_that.recentTransactions,_that.pendingTransactions,_that.unreadNotifications,_that.savings,_that.budget);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? greetingName,  bool hideBalances,  BalanceGroup verified,  BalanceGroup manual,  List<LinkedAccount> accounts,  MonthSummary month,  List<Txn> recentTransactions,  int pendingTransactions,  int unreadNotifications,  Map<String, dynamic>? savings,  Map<String, dynamic>? budget)  $default,) {final _that = this;
switch (_that) {
case _Dashboard():
return $default(_that.greetingName,_that.hideBalances,_that.verified,_that.manual,_that.accounts,_that.month,_that.recentTransactions,_that.pendingTransactions,_that.unreadNotifications,_that.savings,_that.budget);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? greetingName,  bool hideBalances,  BalanceGroup verified,  BalanceGroup manual,  List<LinkedAccount> accounts,  MonthSummary month,  List<Txn> recentTransactions,  int pendingTransactions,  int unreadNotifications,  Map<String, dynamic>? savings,  Map<String, dynamic>? budget)?  $default,) {final _that = this;
switch (_that) {
case _Dashboard() when $default != null:
return $default(_that.greetingName,_that.hideBalances,_that.verified,_that.manual,_that.accounts,_that.month,_that.recentTransactions,_that.pendingTransactions,_that.unreadNotifications,_that.savings,_that.budget);case _:
  return null;

}
}

}

/// @nodoc


class _Dashboard implements Dashboard {
  const _Dashboard({this.greetingName, this.hideBalances = false, required this.verified, required this.manual,  List<LinkedAccount> accounts = const <LinkedAccount>[], required this.month,  List<Txn> recentTransactions = const <Txn>[], this.pendingTransactions = 0, this.unreadNotifications = 0,  Map<String, dynamic>? savings,  Map<String, dynamic>? budget}): _accounts = accounts,_recentTransactions = recentTransactions,_savings = savings,_budget = budget;
  

@override final  String? greetingName;
@override@JsonKey() final  bool hideBalances;
@override final  BalanceGroup verified;
@override final  BalanceGroup manual;
 final  List<LinkedAccount> _accounts;
@override@JsonKey() List<LinkedAccount> get accounts {
  if (_accounts is EqualUnmodifiableListView) return _accounts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_accounts);
}

@override final  MonthSummary month;
 final  List<Txn> _recentTransactions;
@override@JsonKey() List<Txn> get recentTransactions {
  if (_recentTransactions is EqualUnmodifiableListView) return _recentTransactions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_recentTransactions);
}

@override@JsonKey() final  int pendingTransactions;
@override@JsonKey() final  int unreadNotifications;
 final  Map<String, dynamic>? _savings;
@override Map<String, dynamic>? get savings {
  final value = _savings;
  if (value == null) return null;
  if (_savings is EqualUnmodifiableMapView) return _savings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

 final  Map<String, dynamic>? _budget;
@override Map<String, dynamic>? get budget {
  final value = _budget;
  if (value == null) return null;
  if (_budget is EqualUnmodifiableMapView) return _budget;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of Dashboard
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DashboardCopyWith<_Dashboard> get copyWith => __$DashboardCopyWithImpl<_Dashboard>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Dashboard&&(identical(other.greetingName, greetingName) || other.greetingName == greetingName)&&(identical(other.hideBalances, hideBalances) || other.hideBalances == hideBalances)&&(identical(other.verified, verified) || other.verified == verified)&&(identical(other.manual, manual) || other.manual == manual)&&const DeepCollectionEquality().equals(other.accounts, _accounts)&&(identical(other.month, month) || other.month == month)&&const DeepCollectionEquality().equals(other.recentTransactions, _recentTransactions)&&(identical(other.pendingTransactions, pendingTransactions) || other.pendingTransactions == pendingTransactions)&&(identical(other.unreadNotifications, unreadNotifications) || other.unreadNotifications == unreadNotifications)&&const DeepCollectionEquality().equals(other.savings, _savings)&&const DeepCollectionEquality().equals(other.budget, _budget));
}


@override
int get hashCode {
    return Object.hash(runtimeType,greetingName,hideBalances,verified,manual,const DeepCollectionEquality().hash(_accounts),month,const DeepCollectionEquality().hash(_recentTransactions),pendingTransactions,unreadNotifications,const DeepCollectionEquality().hash(_savings),const DeepCollectionEquality().hash(_budget));
}

@override
String toString() {
    return 'Dashboard(greetingName: $greetingName, hideBalances: $hideBalances, verified: $verified, manual: $manual, accounts: $accounts, month: $month, recentTransactions: $recentTransactions, pendingTransactions: $pendingTransactions, unreadNotifications: $unreadNotifications, savings: $savings, budget: $budget)';
}


}

/// @nodoc
abstract mixin class _$DashboardCopyWith<$Res> implements $DashboardCopyWith<$Res> {
  factory _$DashboardCopyWith(_Dashboard value, $Res Function(_Dashboard) _then) = __$DashboardCopyWithImpl;
@override @useResult
$Res call({
 String? greetingName, bool hideBalances, BalanceGroup verified, BalanceGroup manual, List<LinkedAccount> accounts, MonthSummary month, List<Txn> recentTransactions, int pendingTransactions, int unreadNotifications, Map<String, dynamic>? savings, Map<String, dynamic>? budget
});


@override $BalanceGroupCopyWith<$Res> get verified;@override $BalanceGroupCopyWith<$Res> get manual;@override $MonthSummaryCopyWith<$Res> get month;

}
/// @nodoc
class __$DashboardCopyWithImpl<$Res>
    implements _$DashboardCopyWith<$Res> {
  __$DashboardCopyWithImpl(this._self, this._then);

  final _Dashboard _self;
  final $Res Function(_Dashboard) _then;

/// Create a copy of Dashboard
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? greetingName = freezed,Object? hideBalances = null,Object? verified = null,Object? manual = null,Object? accounts = null,Object? month = null,Object? recentTransactions = null,Object? pendingTransactions = null,Object? unreadNotifications = null,Object? savings = freezed,Object? budget = freezed,}) {
  return _then(_Dashboard(
greetingName: freezed == greetingName ? _self.greetingName : greetingName // ignore: cast_nullable_to_non_nullable
as String?,hideBalances: null == hideBalances ? _self.hideBalances : hideBalances // ignore: cast_nullable_to_non_nullable
as bool,verified: null == verified ? _self.verified : verified // ignore: cast_nullable_to_non_nullable
as BalanceGroup,manual: null == manual ? _self.manual : manual // ignore: cast_nullable_to_non_nullable
as BalanceGroup,accounts: null == accounts ? _self._accounts : accounts // ignore: cast_nullable_to_non_nullable
as List<LinkedAccount>,month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as MonthSummary,recentTransactions: null == recentTransactions ? _self._recentTransactions : recentTransactions // ignore: cast_nullable_to_non_nullable
as List<Txn>,pendingTransactions: null == pendingTransactions ? _self.pendingTransactions : pendingTransactions // ignore: cast_nullable_to_non_nullable
as int,unreadNotifications: null == unreadNotifications ? _self.unreadNotifications : unreadNotifications // ignore: cast_nullable_to_non_nullable
as int,savings: freezed == savings ? _self._savings : savings // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,budget: freezed == budget ? _self._budget : budget // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

/// Create a copy of Dashboard
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BalanceGroupCopyWith<$Res> get verified {
  
  return $BalanceGroupCopyWith<$Res>(_self.verified, (value) {
    return _then(_self.copyWith(verified: value));
  });
}/// Create a copy of Dashboard
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BalanceGroupCopyWith<$Res> get manual {
  
  return $BalanceGroupCopyWith<$Res>(_self.manual, (value) {
    return _then(_self.copyWith(manual: value));
  });
}/// Create a copy of Dashboard
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MonthSummaryCopyWith<$Res> get month {
  
  return $MonthSummaryCopyWith<$Res>(_self.month, (value) {
    return _then(_self.copyWith(month: value));
  });
}
}

// dart format on
