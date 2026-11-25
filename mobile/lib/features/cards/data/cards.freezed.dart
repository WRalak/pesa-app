// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cards.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CardControls {

 Money? get perTransaction; Money? get daily; Money? get monthly; bool get online; bool get international; bool get atm;
/// Create a copy of CardControls
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CardControlsCopyWith<CardControls> get copyWith => _$CardControlsCopyWithImpl<CardControls>(this as CardControls, _$identity);

  /// Serializes this CardControls to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CardControls;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CardControls&&(identical(other.perTransaction, _this.perTransaction) || other.perTransaction == _this.perTransaction)&&(identical(other.daily, _this.daily) || other.daily == _this.daily)&&(identical(other.monthly, _this.monthly) || other.monthly == _this.monthly)&&(identical(other.online, _this.online) || other.online == _this.online)&&(identical(other.international, _this.international) || other.international == _this.international)&&(identical(other.atm, _this.atm) || other.atm == _this.atm));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CardControls;
  return Object.hash(runtimeType,_this.perTransaction,_this.daily,_this.monthly,_this.online,_this.international,_this.atm);
}

@override
String toString() {
  final _this = this as CardControls;
  return 'CardControls(perTransaction: ${_this.perTransaction}, daily: ${_this.daily}, monthly: ${_this.monthly}, online: ${_this.online}, international: ${_this.international}, atm: ${_this.atm})';
}


}

/// @nodoc
abstract mixin class $CardControlsCopyWith<$Res>  {
  factory $CardControlsCopyWith(CardControls value, $Res Function(CardControls) _then) = _$CardControlsCopyWithImpl;
@useResult
$Res call({
 Money? perTransaction, Money? daily, Money? monthly, bool online, bool international, bool atm
});


$MoneyCopyWith<$Res>? get perTransaction;$MoneyCopyWith<$Res>? get daily;$MoneyCopyWith<$Res>? get monthly;

}
/// @nodoc
class _$CardControlsCopyWithImpl<$Res>
    implements $CardControlsCopyWith<$Res> {
  _$CardControlsCopyWithImpl(this._self, this._then);

  final CardControls _self;
  final $Res Function(CardControls) _then;

/// Create a copy of CardControls
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? perTransaction = freezed,Object? daily = freezed,Object? monthly = freezed,Object? online = null,Object? international = null,Object? atm = null,}) {
  return _then(CardControls(
perTransaction: freezed == perTransaction ? _self.perTransaction : perTransaction // ignore: cast_nullable_to_non_nullable
as Money?,daily: freezed == daily ? _self.daily : daily // ignore: cast_nullable_to_non_nullable
as Money?,monthly: freezed == monthly ? _self.monthly : monthly // ignore: cast_nullable_to_non_nullable
as Money?,online: null == online ? _self.online : online // ignore: cast_nullable_to_non_nullable
as bool,international: null == international ? _self.international : international // ignore: cast_nullable_to_non_nullable
as bool,atm: null == atm ? _self.atm : atm // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of CardControls
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MoneyCopyWith<$Res>? get perTransaction {
    if (_self.perTransaction == null) {
    return null;
  }

  return $MoneyCopyWith<$Res>(_self.perTransaction!, (value) {
    return _then(_self.copyWith(perTransaction: value));
  });
}/// Create a copy of CardControls
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MoneyCopyWith<$Res>? get daily {
    if (_self.daily == null) {
    return null;
  }

  return $MoneyCopyWith<$Res>(_self.daily!, (value) {
    return _then(_self.copyWith(daily: value));
  });
}/// Create a copy of CardControls
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MoneyCopyWith<$Res>? get monthly {
    if (_self.monthly == null) {
    return null;
  }

  return $MoneyCopyWith<$Res>(_self.monthly!, (value) {
    return _then(_self.copyWith(monthly: value));
  });
}
}


/// Adds pattern-matching-related methods to [CardControls].
extension CardControlsPatterns on CardControls {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CardControls value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CardControls() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CardControls value)  $default,){
final _that = this;
switch (_that) {
case _CardControls():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CardControls value)?  $default,){
final _that = this;
switch (_that) {
case _CardControls() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Money? perTransaction,  Money? daily,  Money? monthly,  bool online,  bool international,  bool atm)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CardControls() when $default != null:
return $default(_that.perTransaction,_that.daily,_that.monthly,_that.online,_that.international,_that.atm);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Money? perTransaction,  Money? daily,  Money? monthly,  bool online,  bool international,  bool atm)  $default,) {final _that = this;
switch (_that) {
case _CardControls():
return $default(_that.perTransaction,_that.daily,_that.monthly,_that.online,_that.international,_that.atm);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Money? perTransaction,  Money? daily,  Money? monthly,  bool online,  bool international,  bool atm)?  $default,) {final _that = this;
switch (_that) {
case _CardControls() when $default != null:
return $default(_that.perTransaction,_that.daily,_that.monthly,_that.online,_that.international,_that.atm);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CardControls implements CardControls {
  const _CardControls({this.perTransaction, this.daily, this.monthly, this.online = true, this.international = false, this.atm = true});
  factory _CardControls.fromJson(Map<String, dynamic> json) => _$CardControlsFromJson(json);

@override final  Money? perTransaction;
@override final  Money? daily;
@override final  Money? monthly;
@override@JsonKey() final  bool online;
@override@JsonKey() final  bool international;
@override@JsonKey() final  bool atm;

/// Create a copy of CardControls
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CardControlsCopyWith<_CardControls> get copyWith => __$CardControlsCopyWithImpl<_CardControls>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CardControlsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CardControls&&(identical(other.perTransaction, perTransaction) || other.perTransaction == perTransaction)&&(identical(other.daily, daily) || other.daily == daily)&&(identical(other.monthly, monthly) || other.monthly == monthly)&&(identical(other.online, online) || other.online == online)&&(identical(other.international, international) || other.international == international)&&(identical(other.atm, atm) || other.atm == atm));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,perTransaction,daily,monthly,online,international,atm);
}

@override
String toString() {
    return 'CardControls(perTransaction: $perTransaction, daily: $daily, monthly: $monthly, online: $online, international: $international, atm: $atm)';
}


}

/// @nodoc
abstract mixin class _$CardControlsCopyWith<$Res> implements $CardControlsCopyWith<$Res> {
  factory _$CardControlsCopyWith(_CardControls value, $Res Function(_CardControls) _then) = __$CardControlsCopyWithImpl;
@override @useResult
$Res call({
 Money? perTransaction, Money? daily, Money? monthly, bool online, bool international, bool atm
});


@override $MoneyCopyWith<$Res>? get perTransaction;@override $MoneyCopyWith<$Res>? get daily;@override $MoneyCopyWith<$Res>? get monthly;

}
/// @nodoc
class __$CardControlsCopyWithImpl<$Res>
    implements _$CardControlsCopyWith<$Res> {
  __$CardControlsCopyWithImpl(this._self, this._then);

  final _CardControls _self;
  final $Res Function(_CardControls) _then;

/// Create a copy of CardControls
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? perTransaction = freezed,Object? daily = freezed,Object? monthly = freezed,Object? online = null,Object? international = null,Object? atm = null,}) {
  return _then(_CardControls(
perTransaction: freezed == perTransaction ? _self.perTransaction : perTransaction // ignore: cast_nullable_to_non_nullable
as Money?,daily: freezed == daily ? _self.daily : daily // ignore: cast_nullable_to_non_nullable
as Money?,monthly: freezed == monthly ? _self.monthly : monthly // ignore: cast_nullable_to_non_nullable
as Money?,online: null == online ? _self.online : online // ignore: cast_nullable_to_non_nullable
as bool,international: null == international ? _self.international : international // ignore: cast_nullable_to_non_nullable
as bool,atm: null == atm ? _self.atm : atm // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of CardControls
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MoneyCopyWith<$Res>? get perTransaction {
    if (_self.perTransaction == null) {
    return null;
  }

  return $MoneyCopyWith<$Res>(_self.perTransaction!, (value) {
    return _then(_self.copyWith(perTransaction: value));
  });
}/// Create a copy of CardControls
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MoneyCopyWith<$Res>? get daily {
    if (_self.daily == null) {
    return null;
  }

  return $MoneyCopyWith<$Res>(_self.daily!, (value) {
    return _then(_self.copyWith(daily: value));
  });
}/// Create a copy of CardControls
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MoneyCopyWith<$Res>? get monthly {
    if (_self.monthly == null) {
    return null;
  }

  return $MoneyCopyWith<$Res>(_self.monthly!, (value) {
    return _then(_self.copyWith(monthly: value));
  });
}
}


/// @nodoc
mixin _$PaymentCard {

 String get id; String get kind; String get issuer; String get brand; String get last4; String get expiry; String? get nameOnCard; String? get nickname; String get currency; String get status; bool get sandbox; CardControls get controls;
/// Create a copy of PaymentCard
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaymentCardCopyWith<PaymentCard> get copyWith => _$PaymentCardCopyWithImpl<PaymentCard>(this as PaymentCard, _$identity);

  /// Serializes this PaymentCard to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PaymentCard;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaymentCard&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.issuer, _this.issuer) || other.issuer == _this.issuer)&&(identical(other.brand, _this.brand) || other.brand == _this.brand)&&(identical(other.last4, _this.last4) || other.last4 == _this.last4)&&(identical(other.expiry, _this.expiry) || other.expiry == _this.expiry)&&(identical(other.nameOnCard, _this.nameOnCard) || other.nameOnCard == _this.nameOnCard)&&(identical(other.nickname, _this.nickname) || other.nickname == _this.nickname)&&(identical(other.currency, _this.currency) || other.currency == _this.currency)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.sandbox, _this.sandbox) || other.sandbox == _this.sandbox)&&(identical(other.controls, _this.controls) || other.controls == _this.controls));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PaymentCard;
  return Object.hash(runtimeType,_this.id,_this.kind,_this.issuer,_this.brand,_this.last4,_this.expiry,_this.nameOnCard,_this.nickname,_this.currency,_this.status,_this.sandbox,_this.controls);
}

@override
String toString() {
  final _this = this as PaymentCard;
  return 'PaymentCard(id: ${_this.id}, kind: ${_this.kind}, issuer: ${_this.issuer}, brand: ${_this.brand}, last4: ${_this.last4}, expiry: ${_this.expiry}, nameOnCard: ${_this.nameOnCard}, nickname: ${_this.nickname}, currency: ${_this.currency}, status: ${_this.status}, sandbox: ${_this.sandbox}, controls: ${_this.controls})';
}


}

/// @nodoc
abstract mixin class $PaymentCardCopyWith<$Res>  {
  factory $PaymentCardCopyWith(PaymentCard value, $Res Function(PaymentCard) _then) = _$PaymentCardCopyWithImpl;
@useResult
$Res call({
 String id, String kind, String issuer, String brand, String last4, String expiry, String? nameOnCard, String? nickname, String currency, String status, bool sandbox, CardControls controls
});


$CardControlsCopyWith<$Res> get controls;

}
/// @nodoc
class _$PaymentCardCopyWithImpl<$Res>
    implements $PaymentCardCopyWith<$Res> {
  _$PaymentCardCopyWithImpl(this._self, this._then);

  final PaymentCard _self;
  final $Res Function(PaymentCard) _then;

/// Create a copy of PaymentCard
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kind = null,Object? issuer = null,Object? brand = null,Object? last4 = null,Object? expiry = null,Object? nameOnCard = freezed,Object? nickname = freezed,Object? currency = null,Object? status = null,Object? sandbox = null,Object? controls = null,}) {
  return _then(PaymentCard(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,issuer: null == issuer ? _self.issuer : issuer // ignore: cast_nullable_to_non_nullable
as String,brand: null == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as String,last4: null == last4 ? _self.last4 : last4 // ignore: cast_nullable_to_non_nullable
as String,expiry: null == expiry ? _self.expiry : expiry // ignore: cast_nullable_to_non_nullable
as String,nameOnCard: freezed == nameOnCard ? _self.nameOnCard : nameOnCard // ignore: cast_nullable_to_non_nullable
as String?,nickname: freezed == nickname ? _self.nickname : nickname // ignore: cast_nullable_to_non_nullable
as String?,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,sandbox: null == sandbox ? _self.sandbox : sandbox // ignore: cast_nullable_to_non_nullable
as bool,controls: null == controls ? _self.controls : controls // ignore: cast_nullable_to_non_nullable
as CardControls,
  ));
}
/// Create a copy of PaymentCard
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CardControlsCopyWith<$Res> get controls {
  
  return $CardControlsCopyWith<$Res>(_self.controls, (value) {
    return _then(_self.copyWith(controls: value));
  });
}
}


/// Adds pattern-matching-related methods to [PaymentCard].
extension PaymentCardPatterns on PaymentCard {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PaymentCard value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PaymentCard() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PaymentCard value)  $default,){
final _that = this;
switch (_that) {
case _PaymentCard():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PaymentCard value)?  $default,){
final _that = this;
switch (_that) {
case _PaymentCard() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String kind,  String issuer,  String brand,  String last4,  String expiry,  String? nameOnCard,  String? nickname,  String currency,  String status,  bool sandbox,  CardControls controls)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PaymentCard() when $default != null:
return $default(_that.id,_that.kind,_that.issuer,_that.brand,_that.last4,_that.expiry,_that.nameOnCard,_that.nickname,_that.currency,_that.status,_that.sandbox,_that.controls);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String kind,  String issuer,  String brand,  String last4,  String expiry,  String? nameOnCard,  String? nickname,  String currency,  String status,  bool sandbox,  CardControls controls)  $default,) {final _that = this;
switch (_that) {
case _PaymentCard():
return $default(_that.id,_that.kind,_that.issuer,_that.brand,_that.last4,_that.expiry,_that.nameOnCard,_that.nickname,_that.currency,_that.status,_that.sandbox,_that.controls);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String kind,  String issuer,  String brand,  String last4,  String expiry,  String? nameOnCard,  String? nickname,  String currency,  String status,  bool sandbox,  CardControls controls)?  $default,) {final _that = this;
switch (_that) {
case _PaymentCard() when $default != null:
return $default(_that.id,_that.kind,_that.issuer,_that.brand,_that.last4,_that.expiry,_that.nameOnCard,_that.nickname,_that.currency,_that.status,_that.sandbox,_that.controls);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PaymentCard implements PaymentCard {
  const _PaymentCard({required this.id, required this.kind, required this.issuer, required this.brand, required this.last4, required this.expiry, this.nameOnCard, this.nickname, required this.currency, required this.status, this.sandbox = false, required this.controls});
  factory _PaymentCard.fromJson(Map<String, dynamic> json) => _$PaymentCardFromJson(json);

@override final  String id;
@override final  String kind;
@override final  String issuer;
@override final  String brand;
@override final  String last4;
@override final  String expiry;
@override final  String? nameOnCard;
@override final  String? nickname;
@override final  String currency;
@override final  String status;
@override@JsonKey() final  bool sandbox;
@override final  CardControls controls;

/// Create a copy of PaymentCard
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaymentCardCopyWith<_PaymentCard> get copyWith => __$PaymentCardCopyWithImpl<_PaymentCard>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PaymentCardToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PaymentCard&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.issuer, issuer) || other.issuer == issuer)&&(identical(other.brand, brand) || other.brand == brand)&&(identical(other.last4, last4) || other.last4 == last4)&&(identical(other.expiry, expiry) || other.expiry == expiry)&&(identical(other.nameOnCard, nameOnCard) || other.nameOnCard == nameOnCard)&&(identical(other.nickname, nickname) || other.nickname == nickname)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.status, status) || other.status == status)&&(identical(other.sandbox, sandbox) || other.sandbox == sandbox)&&(identical(other.controls, controls) || other.controls == controls));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,kind,issuer,brand,last4,expiry,nameOnCard,nickname,currency,status,sandbox,controls);
}

@override
String toString() {
    return 'PaymentCard(id: $id, kind: $kind, issuer: $issuer, brand: $brand, last4: $last4, expiry: $expiry, nameOnCard: $nameOnCard, nickname: $nickname, currency: $currency, status: $status, sandbox: $sandbox, controls: $controls)';
}


}

/// @nodoc
abstract mixin class _$PaymentCardCopyWith<$Res> implements $PaymentCardCopyWith<$Res> {
  factory _$PaymentCardCopyWith(_PaymentCard value, $Res Function(_PaymentCard) _then) = __$PaymentCardCopyWithImpl;
@override @useResult
$Res call({
 String id, String kind, String issuer, String brand, String last4, String expiry, String? nameOnCard, String? nickname, String currency, String status, bool sandbox, CardControls controls
});


@override $CardControlsCopyWith<$Res> get controls;

}
/// @nodoc
class __$PaymentCardCopyWithImpl<$Res>
    implements _$PaymentCardCopyWith<$Res> {
  __$PaymentCardCopyWithImpl(this._self, this._then);

  final _PaymentCard _self;
  final $Res Function(_PaymentCard) _then;

/// Create a copy of PaymentCard
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kind = null,Object? issuer = null,Object? brand = null,Object? last4 = null,Object? expiry = null,Object? nameOnCard = freezed,Object? nickname = freezed,Object? currency = null,Object? status = null,Object? sandbox = null,Object? controls = null,}) {
  return _then(_PaymentCard(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,issuer: null == issuer ? _self.issuer : issuer // ignore: cast_nullable_to_non_nullable
as String,brand: null == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as String,last4: null == last4 ? _self.last4 : last4 // ignore: cast_nullable_to_non_nullable
as String,expiry: null == expiry ? _self.expiry : expiry // ignore: cast_nullable_to_non_nullable
as String,nameOnCard: freezed == nameOnCard ? _self.nameOnCard : nameOnCard // ignore: cast_nullable_to_non_nullable
as String?,nickname: freezed == nickname ? _self.nickname : nickname // ignore: cast_nullable_to_non_nullable
as String?,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,sandbox: null == sandbox ? _self.sandbox : sandbox // ignore: cast_nullable_to_non_nullable
as bool,controls: null == controls ? _self.controls : controls // ignore: cast_nullable_to_non_nullable
as CardControls,
  ));
}

/// Create a copy of PaymentCard
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CardControlsCopyWith<$Res> get controls {
  
  return $CardControlsCopyWith<$Res>(_self.controls, (value) {
    return _then(_self.copyWith(controls: value));
  });
}
}

// dart format on
