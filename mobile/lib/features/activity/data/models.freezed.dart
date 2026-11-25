// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Counterparty {

 String? get name; String? get phone; String? get accountNumber; String? get shortcode; String? get network; String? get utilityCode;
/// Create a copy of Counterparty
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CounterpartyCopyWith<Counterparty> get copyWith => _$CounterpartyCopyWithImpl<Counterparty>(this as Counterparty, _$identity);

  /// Serializes this Counterparty to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Counterparty;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Counterparty&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.phone, _this.phone) || other.phone == _this.phone)&&(identical(other.accountNumber, _this.accountNumber) || other.accountNumber == _this.accountNumber)&&(identical(other.shortcode, _this.shortcode) || other.shortcode == _this.shortcode)&&(identical(other.network, _this.network) || other.network == _this.network)&&(identical(other.utilityCode, _this.utilityCode) || other.utilityCode == _this.utilityCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Counterparty;
  return Object.hash(runtimeType,_this.name,_this.phone,_this.accountNumber,_this.shortcode,_this.network,_this.utilityCode);
}

@override
String toString() {
  final _this = this as Counterparty;
  return 'Counterparty(name: ${_this.name}, phone: ${_this.phone}, accountNumber: ${_this.accountNumber}, shortcode: ${_this.shortcode}, network: ${_this.network}, utilityCode: ${_this.utilityCode})';
}


}

/// @nodoc
abstract mixin class $CounterpartyCopyWith<$Res>  {
  factory $CounterpartyCopyWith(Counterparty value, $Res Function(Counterparty) _then) = _$CounterpartyCopyWithImpl;
@useResult
$Res call({
 String? name, String? phone, String? accountNumber, String? shortcode, String? network, String? utilityCode
});




}
/// @nodoc
class _$CounterpartyCopyWithImpl<$Res>
    implements $CounterpartyCopyWith<$Res> {
  _$CounterpartyCopyWithImpl(this._self, this._then);

  final Counterparty _self;
  final $Res Function(Counterparty) _then;

/// Create a copy of Counterparty
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = freezed,Object? phone = freezed,Object? accountNumber = freezed,Object? shortcode = freezed,Object? network = freezed,Object? utilityCode = freezed,}) {
  return _then(Counterparty(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,accountNumber: freezed == accountNumber ? _self.accountNumber : accountNumber // ignore: cast_nullable_to_non_nullable
as String?,shortcode: freezed == shortcode ? _self.shortcode : shortcode // ignore: cast_nullable_to_non_nullable
as String?,network: freezed == network ? _self.network : network // ignore: cast_nullable_to_non_nullable
as String?,utilityCode: freezed == utilityCode ? _self.utilityCode : utilityCode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Counterparty].
extension CounterpartyPatterns on Counterparty {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Counterparty value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Counterparty() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Counterparty value)  $default,){
final _that = this;
switch (_that) {
case _Counterparty():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Counterparty value)?  $default,){
final _that = this;
switch (_that) {
case _Counterparty() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? name,  String? phone,  String? accountNumber,  String? shortcode,  String? network,  String? utilityCode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Counterparty() when $default != null:
return $default(_that.name,_that.phone,_that.accountNumber,_that.shortcode,_that.network,_that.utilityCode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? name,  String? phone,  String? accountNumber,  String? shortcode,  String? network,  String? utilityCode)  $default,) {final _that = this;
switch (_that) {
case _Counterparty():
return $default(_that.name,_that.phone,_that.accountNumber,_that.shortcode,_that.network,_that.utilityCode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? name,  String? phone,  String? accountNumber,  String? shortcode,  String? network,  String? utilityCode)?  $default,) {final _that = this;
switch (_that) {
case _Counterparty() when $default != null:
return $default(_that.name,_that.phone,_that.accountNumber,_that.shortcode,_that.network,_that.utilityCode);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Counterparty implements Counterparty {
  const _Counterparty({this.name, this.phone, this.accountNumber, this.shortcode, this.network, this.utilityCode});
  factory _Counterparty.fromJson(Map<String, dynamic> json) => _$CounterpartyFromJson(json);

@override final  String? name;
@override final  String? phone;
@override final  String? accountNumber;
@override final  String? shortcode;
@override final  String? network;
@override final  String? utilityCode;

/// Create a copy of Counterparty
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CounterpartyCopyWith<_Counterparty> get copyWith => __$CounterpartyCopyWithImpl<_Counterparty>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CounterpartyToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Counterparty&&(identical(other.name, name) || other.name == name)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.accountNumber, accountNumber) || other.accountNumber == accountNumber)&&(identical(other.shortcode, shortcode) || other.shortcode == shortcode)&&(identical(other.network, network) || other.network == network)&&(identical(other.utilityCode, utilityCode) || other.utilityCode == utilityCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,phone,accountNumber,shortcode,network,utilityCode);
}

@override
String toString() {
    return 'Counterparty(name: $name, phone: $phone, accountNumber: $accountNumber, shortcode: $shortcode, network: $network, utilityCode: $utilityCode)';
}


}

/// @nodoc
abstract mixin class _$CounterpartyCopyWith<$Res> implements $CounterpartyCopyWith<$Res> {
  factory _$CounterpartyCopyWith(_Counterparty value, $Res Function(_Counterparty) _then) = __$CounterpartyCopyWithImpl;
@override @useResult
$Res call({
 String? name, String? phone, String? accountNumber, String? shortcode, String? network, String? utilityCode
});




}
/// @nodoc
class __$CounterpartyCopyWithImpl<$Res>
    implements _$CounterpartyCopyWith<$Res> {
  __$CounterpartyCopyWithImpl(this._self, this._then);

  final _Counterparty _self;
  final $Res Function(_Counterparty) _then;

/// Create a copy of Counterparty
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = freezed,Object? phone = freezed,Object? accountNumber = freezed,Object? shortcode = freezed,Object? network = freezed,Object? utilityCode = freezed,}) {
  return _then(_Counterparty(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,accountNumber: freezed == accountNumber ? _self.accountNumber : accountNumber // ignore: cast_nullable_to_non_nullable
as String?,shortcode: freezed == shortcode ? _self.shortcode : shortcode // ignore: cast_nullable_to_non_nullable
as String?,network: freezed == network ? _self.network : network // ignore: cast_nullable_to_non_nullable
as String?,utilityCode: freezed == utilityCode ? _self.utilityCode : utilityCode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$Txn {

 String get id; String get reference; String get type; String get direction; String get status; String? get statusReason; Money get amount; Money get fee; Money get total; String get currency; String get provider; String? get description; String get category; Counterparty get counterparty; String? get externalRef; DateTime get createdAt; DateTime? get completedAt;
/// Create a copy of Txn
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TxnCopyWith<Txn> get copyWith => _$TxnCopyWithImpl<Txn>(this as Txn, _$identity);

  /// Serializes this Txn to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Txn;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Txn&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.reference, _this.reference) || other.reference == _this.reference)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.direction, _this.direction) || other.direction == _this.direction)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.statusReason, _this.statusReason) || other.statusReason == _this.statusReason)&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.fee, _this.fee) || other.fee == _this.fee)&&(identical(other.total, _this.total) || other.total == _this.total)&&(identical(other.currency, _this.currency) || other.currency == _this.currency)&&(identical(other.provider, _this.provider) || other.provider == _this.provider)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.category, _this.category) || other.category == _this.category)&&(identical(other.counterparty, _this.counterparty) || other.counterparty == _this.counterparty)&&(identical(other.externalRef, _this.externalRef) || other.externalRef == _this.externalRef)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.completedAt, _this.completedAt) || other.completedAt == _this.completedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Txn;
  return Object.hash(runtimeType,_this.id,_this.reference,_this.type,_this.direction,_this.status,_this.statusReason,_this.amount,_this.fee,_this.total,_this.currency,_this.provider,_this.description,_this.category,_this.counterparty,_this.externalRef,_this.createdAt,_this.completedAt);
}

@override
String toString() {
  final _this = this as Txn;
  return 'Txn(id: ${_this.id}, reference: ${_this.reference}, type: ${_this.type}, direction: ${_this.direction}, status: ${_this.status}, statusReason: ${_this.statusReason}, amount: ${_this.amount}, fee: ${_this.fee}, total: ${_this.total}, currency: ${_this.currency}, provider: ${_this.provider}, description: ${_this.description}, category: ${_this.category}, counterparty: ${_this.counterparty}, externalRef: ${_this.externalRef}, createdAt: ${_this.createdAt}, completedAt: ${_this.completedAt})';
}


}

/// @nodoc
abstract mixin class $TxnCopyWith<$Res>  {
  factory $TxnCopyWith(Txn value, $Res Function(Txn) _then) = _$TxnCopyWithImpl;
@useResult
$Res call({
 String id, String reference, String type, String direction, String status, String? statusReason, Money amount, Money fee, Money total, String currency, String provider, String? description, String category, Counterparty counterparty, String? externalRef, DateTime createdAt, DateTime? completedAt
});


$MoneyCopyWith<$Res> get amount;$MoneyCopyWith<$Res> get fee;$MoneyCopyWith<$Res> get total;$CounterpartyCopyWith<$Res> get counterparty;

}
/// @nodoc
class _$TxnCopyWithImpl<$Res>
    implements $TxnCopyWith<$Res> {
  _$TxnCopyWithImpl(this._self, this._then);

  final Txn _self;
  final $Res Function(Txn) _then;

/// Create a copy of Txn
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? reference = null,Object? type = null,Object? direction = null,Object? status = null,Object? statusReason = freezed,Object? amount = null,Object? fee = null,Object? total = null,Object? currency = null,Object? provider = null,Object? description = freezed,Object? category = null,Object? counterparty = null,Object? externalRef = freezed,Object? createdAt = null,Object? completedAt = freezed,}) {
  return _then(Txn(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,reference: null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,statusReason: freezed == statusReason ? _self.statusReason : statusReason // ignore: cast_nullable_to_non_nullable
as String?,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Money,fee: null == fee ? _self.fee : fee // ignore: cast_nullable_to_non_nullable
as Money,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as Money,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,counterparty: null == counterparty ? _self.counterparty : counterparty // ignore: cast_nullable_to_non_nullable
as Counterparty,externalRef: freezed == externalRef ? _self.externalRef : externalRef // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of Txn
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MoneyCopyWith<$Res> get amount {
  
  return $MoneyCopyWith<$Res>(_self.amount, (value) {
    return _then(_self.copyWith(amount: value));
  });
}/// Create a copy of Txn
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MoneyCopyWith<$Res> get fee {
  
  return $MoneyCopyWith<$Res>(_self.fee, (value) {
    return _then(_self.copyWith(fee: value));
  });
}/// Create a copy of Txn
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MoneyCopyWith<$Res> get total {
  
  return $MoneyCopyWith<$Res>(_self.total, (value) {
    return _then(_self.copyWith(total: value));
  });
}/// Create a copy of Txn
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CounterpartyCopyWith<$Res> get counterparty {
  
  return $CounterpartyCopyWith<$Res>(_self.counterparty, (value) {
    return _then(_self.copyWith(counterparty: value));
  });
}
}


/// Adds pattern-matching-related methods to [Txn].
extension TxnPatterns on Txn {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Txn value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Txn() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Txn value)  $default,){
final _that = this;
switch (_that) {
case _Txn():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Txn value)?  $default,){
final _that = this;
switch (_that) {
case _Txn() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String reference,  String type,  String direction,  String status,  String? statusReason,  Money amount,  Money fee,  Money total,  String currency,  String provider,  String? description,  String category,  Counterparty counterparty,  String? externalRef,  DateTime createdAt,  DateTime? completedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Txn() when $default != null:
return $default(_that.id,_that.reference,_that.type,_that.direction,_that.status,_that.statusReason,_that.amount,_that.fee,_that.total,_that.currency,_that.provider,_that.description,_that.category,_that.counterparty,_that.externalRef,_that.createdAt,_that.completedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String reference,  String type,  String direction,  String status,  String? statusReason,  Money amount,  Money fee,  Money total,  String currency,  String provider,  String? description,  String category,  Counterparty counterparty,  String? externalRef,  DateTime createdAt,  DateTime? completedAt)  $default,) {final _that = this;
switch (_that) {
case _Txn():
return $default(_that.id,_that.reference,_that.type,_that.direction,_that.status,_that.statusReason,_that.amount,_that.fee,_that.total,_that.currency,_that.provider,_that.description,_that.category,_that.counterparty,_that.externalRef,_that.createdAt,_that.completedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String reference,  String type,  String direction,  String status,  String? statusReason,  Money amount,  Money fee,  Money total,  String currency,  String provider,  String? description,  String category,  Counterparty counterparty,  String? externalRef,  DateTime createdAt,  DateTime? completedAt)?  $default,) {final _that = this;
switch (_that) {
case _Txn() when $default != null:
return $default(_that.id,_that.reference,_that.type,_that.direction,_that.status,_that.statusReason,_that.amount,_that.fee,_that.total,_that.currency,_that.provider,_that.description,_that.category,_that.counterparty,_that.externalRef,_that.createdAt,_that.completedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Txn extends Txn {
  const _Txn({required this.id, required this.reference, required this.type, required this.direction, required this.status, this.statusReason, required this.amount, required this.fee, required this.total, required this.currency, required this.provider, this.description, required this.category, required this.counterparty, this.externalRef, required this.createdAt, this.completedAt}): super._();
  factory _Txn.fromJson(Map<String, dynamic> json) => _$TxnFromJson(json);

@override final  String id;
@override final  String reference;
@override final  String type;
@override final  String direction;
@override final  String status;
@override final  String? statusReason;
@override final  Money amount;
@override final  Money fee;
@override final  Money total;
@override final  String currency;
@override final  String provider;
@override final  String? description;
@override final  String category;
@override final  Counterparty counterparty;
@override final  String? externalRef;
@override final  DateTime createdAt;
@override final  DateTime? completedAt;

/// Create a copy of Txn
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TxnCopyWith<_Txn> get copyWith => __$TxnCopyWithImpl<_Txn>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TxnToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Txn&&(identical(other.id, id) || other.id == id)&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.type, type) || other.type == type)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.status, status) || other.status == status)&&(identical(other.statusReason, statusReason) || other.statusReason == statusReason)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.fee, fee) || other.fee == fee)&&(identical(other.total, total) || other.total == total)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.description, description) || other.description == description)&&(identical(other.category, category) || other.category == category)&&(identical(other.counterparty, counterparty) || other.counterparty == counterparty)&&(identical(other.externalRef, externalRef) || other.externalRef == externalRef)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,reference,type,direction,status,statusReason,amount,fee,total,currency,provider,description,category,counterparty,externalRef,createdAt,completedAt);
}

@override
String toString() {
    return 'Txn(id: $id, reference: $reference, type: $type, direction: $direction, status: $status, statusReason: $statusReason, amount: $amount, fee: $fee, total: $total, currency: $currency, provider: $provider, description: $description, category: $category, counterparty: $counterparty, externalRef: $externalRef, createdAt: $createdAt, completedAt: $completedAt)';
}


}

/// @nodoc
abstract mixin class _$TxnCopyWith<$Res> implements $TxnCopyWith<$Res> {
  factory _$TxnCopyWith(_Txn value, $Res Function(_Txn) _then) = __$TxnCopyWithImpl;
@override @useResult
$Res call({
 String id, String reference, String type, String direction, String status, String? statusReason, Money amount, Money fee, Money total, String currency, String provider, String? description, String category, Counterparty counterparty, String? externalRef, DateTime createdAt, DateTime? completedAt
});


@override $MoneyCopyWith<$Res> get amount;@override $MoneyCopyWith<$Res> get fee;@override $MoneyCopyWith<$Res> get total;@override $CounterpartyCopyWith<$Res> get counterparty;

}
/// @nodoc
class __$TxnCopyWithImpl<$Res>
    implements _$TxnCopyWith<$Res> {
  __$TxnCopyWithImpl(this._self, this._then);

  final _Txn _self;
  final $Res Function(_Txn) _then;

/// Create a copy of Txn
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? reference = null,Object? type = null,Object? direction = null,Object? status = null,Object? statusReason = freezed,Object? amount = null,Object? fee = null,Object? total = null,Object? currency = null,Object? provider = null,Object? description = freezed,Object? category = null,Object? counterparty = null,Object? externalRef = freezed,Object? createdAt = null,Object? completedAt = freezed,}) {
  return _then(_Txn(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,reference: null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,statusReason: freezed == statusReason ? _self.statusReason : statusReason // ignore: cast_nullable_to_non_nullable
as String?,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Money,fee: null == fee ? _self.fee : fee // ignore: cast_nullable_to_non_nullable
as Money,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as Money,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,counterparty: null == counterparty ? _self.counterparty : counterparty // ignore: cast_nullable_to_non_nullable
as Counterparty,externalRef: freezed == externalRef ? _self.externalRef : externalRef // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of Txn
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MoneyCopyWith<$Res> get amount {
  
  return $MoneyCopyWith<$Res>(_self.amount, (value) {
    return _then(_self.copyWith(amount: value));
  });
}/// Create a copy of Txn
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MoneyCopyWith<$Res> get fee {
  
  return $MoneyCopyWith<$Res>(_self.fee, (value) {
    return _then(_self.copyWith(fee: value));
  });
}/// Create a copy of Txn
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MoneyCopyWith<$Res> get total {
  
  return $MoneyCopyWith<$Res>(_self.total, (value) {
    return _then(_self.copyWith(total: value));
  });
}/// Create a copy of Txn
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CounterpartyCopyWith<$Res> get counterparty {
  
  return $CounterpartyCopyWith<$Res>(_self.counterparty, (value) {
    return _then(_self.copyWith(counterparty: value));
  });
}
}


/// @nodoc
mixin _$TimelineEntry {

 String? get status; String get kind; DateTime get at; String? get reason;
/// Create a copy of TimelineEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TimelineEntryCopyWith<TimelineEntry> get copyWith => _$TimelineEntryCopyWithImpl<TimelineEntry>(this as TimelineEntry, _$identity);

  /// Serializes this TimelineEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as TimelineEntry;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TimelineEntry&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.at, _this.at) || other.at == _this.at)&&(identical(other.reason, _this.reason) || other.reason == _this.reason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TimelineEntry;
  return Object.hash(runtimeType,_this.status,_this.kind,_this.at,_this.reason);
}

@override
String toString() {
  final _this = this as TimelineEntry;
  return 'TimelineEntry(status: ${_this.status}, kind: ${_this.kind}, at: ${_this.at}, reason: ${_this.reason})';
}


}

/// @nodoc
abstract mixin class $TimelineEntryCopyWith<$Res>  {
  factory $TimelineEntryCopyWith(TimelineEntry value, $Res Function(TimelineEntry) _then) = _$TimelineEntryCopyWithImpl;
@useResult
$Res call({
 String? status, String kind, DateTime at, String? reason
});




}
/// @nodoc
class _$TimelineEntryCopyWithImpl<$Res>
    implements $TimelineEntryCopyWith<$Res> {
  _$TimelineEntryCopyWithImpl(this._self, this._then);

  final TimelineEntry _self;
  final $Res Function(TimelineEntry) _then;

/// Create a copy of TimelineEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = freezed,Object? kind = null,Object? at = null,Object? reason = freezed,}) {
  return _then(TimelineEntry(
status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TimelineEntry].
extension TimelineEntryPatterns on TimelineEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TimelineEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TimelineEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TimelineEntry value)  $default,){
final _that = this;
switch (_that) {
case _TimelineEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TimelineEntry value)?  $default,){
final _that = this;
switch (_that) {
case _TimelineEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? status,  String kind,  DateTime at,  String? reason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TimelineEntry() when $default != null:
return $default(_that.status,_that.kind,_that.at,_that.reason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? status,  String kind,  DateTime at,  String? reason)  $default,) {final _that = this;
switch (_that) {
case _TimelineEntry():
return $default(_that.status,_that.kind,_that.at,_that.reason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? status,  String kind,  DateTime at,  String? reason)?  $default,) {final _that = this;
switch (_that) {
case _TimelineEntry() when $default != null:
return $default(_that.status,_that.kind,_that.at,_that.reason);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TimelineEntry implements TimelineEntry {
  const _TimelineEntry({this.status, required this.kind, required this.at, this.reason});
  factory _TimelineEntry.fromJson(Map<String, dynamic> json) => _$TimelineEntryFromJson(json);

@override final  String? status;
@override final  String kind;
@override final  DateTime at;
@override final  String? reason;

/// Create a copy of TimelineEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TimelineEntryCopyWith<_TimelineEntry> get copyWith => __$TimelineEntryCopyWithImpl<_TimelineEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TimelineEntryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TimelineEntry&&(identical(other.status, status) || other.status == status)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.at, at) || other.at == at)&&(identical(other.reason, reason) || other.reason == reason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,status,kind,at,reason);
}

@override
String toString() {
    return 'TimelineEntry(status: $status, kind: $kind, at: $at, reason: $reason)';
}


}

/// @nodoc
abstract mixin class _$TimelineEntryCopyWith<$Res> implements $TimelineEntryCopyWith<$Res> {
  factory _$TimelineEntryCopyWith(_TimelineEntry value, $Res Function(_TimelineEntry) _then) = __$TimelineEntryCopyWithImpl;
@override @useResult
$Res call({
 String? status, String kind, DateTime at, String? reason
});




}
/// @nodoc
class __$TimelineEntryCopyWithImpl<$Res>
    implements _$TimelineEntryCopyWith<$Res> {
  __$TimelineEntryCopyWithImpl(this._self, this._then);

  final _TimelineEntry _self;
  final $Res Function(_TimelineEntry) _then;

/// Create a copy of TimelineEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = freezed,Object? kind = null,Object? at = null,Object? reason = freezed,}) {
  return _then(_TimelineEntry(
status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$TxnPage {

 List<Txn> get items; String? get nextCursor; bool get hasMore;
/// Create a copy of TxnPage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TxnPageCopyWith<TxnPage> get copyWith => _$TxnPageCopyWithImpl<TxnPage>(this as TxnPage, _$identity);

  /// Serializes this TxnPage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as TxnPage;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TxnPage&&const DeepCollectionEquality().equals(other.items, _this.items)&&(identical(other.nextCursor, _this.nextCursor) || other.nextCursor == _this.nextCursor)&&(identical(other.hasMore, _this.hasMore) || other.hasMore == _this.hasMore));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TxnPage;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.items),_this.nextCursor,_this.hasMore);
}

@override
String toString() {
  final _this = this as TxnPage;
  return 'TxnPage(items: ${_this.items}, nextCursor: ${_this.nextCursor}, hasMore: ${_this.hasMore})';
}


}

/// @nodoc
abstract mixin class $TxnPageCopyWith<$Res>  {
  factory $TxnPageCopyWith(TxnPage value, $Res Function(TxnPage) _then) = _$TxnPageCopyWithImpl;
@useResult
$Res call({
 List<Txn> items, String? nextCursor, bool hasMore
});




}
/// @nodoc
class _$TxnPageCopyWithImpl<$Res>
    implements $TxnPageCopyWith<$Res> {
  _$TxnPageCopyWithImpl(this._self, this._then);

  final TxnPage _self;
  final $Res Function(TxnPage) _then;

/// Create a copy of TxnPage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? nextCursor = freezed,Object? hasMore = null,}) {
  return _then(TxnPage(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<Txn>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [TxnPage].
extension TxnPagePatterns on TxnPage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TxnPage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TxnPage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TxnPage value)  $default,){
final _that = this;
switch (_that) {
case _TxnPage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TxnPage value)?  $default,){
final _that = this;
switch (_that) {
case _TxnPage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Txn> items,  String? nextCursor,  bool hasMore)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TxnPage() when $default != null:
return $default(_that.items,_that.nextCursor,_that.hasMore);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Txn> items,  String? nextCursor,  bool hasMore)  $default,) {final _that = this;
switch (_that) {
case _TxnPage():
return $default(_that.items,_that.nextCursor,_that.hasMore);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Txn> items,  String? nextCursor,  bool hasMore)?  $default,) {final _that = this;
switch (_that) {
case _TxnPage() when $default != null:
return $default(_that.items,_that.nextCursor,_that.hasMore);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TxnPage implements TxnPage {
  const _TxnPage({required  List<Txn> items, this.nextCursor, required this.hasMore}): _items = items;
  factory _TxnPage.fromJson(Map<String, dynamic> json) => _$TxnPageFromJson(json);

 final  List<Txn> _items;
@override List<Txn> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  String? nextCursor;
@override final  bool hasMore;

/// Create a copy of TxnPage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TxnPageCopyWith<_TxnPage> get copyWith => __$TxnPageCopyWithImpl<_TxnPage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TxnPageToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TxnPage&&const DeepCollectionEquality().equals(other.items, _items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),nextCursor,hasMore);
}

@override
String toString() {
    return 'TxnPage(items: $items, nextCursor: $nextCursor, hasMore: $hasMore)';
}


}

/// @nodoc
abstract mixin class _$TxnPageCopyWith<$Res> implements $TxnPageCopyWith<$Res> {
  factory _$TxnPageCopyWith(_TxnPage value, $Res Function(_TxnPage) _then) = __$TxnPageCopyWithImpl;
@override @useResult
$Res call({
 List<Txn> items, String? nextCursor, bool hasMore
});




}
/// @nodoc
class __$TxnPageCopyWithImpl<$Res>
    implements _$TxnPageCopyWith<$Res> {
  __$TxnPageCopyWithImpl(this._self, this._then);

  final _TxnPage _self;
  final $Res Function(_TxnPage) _then;

/// Create a copy of TxnPage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? nextCursor = freezed,Object? hasMore = null,}) {
  return _then(_TxnPage(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<Txn>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
