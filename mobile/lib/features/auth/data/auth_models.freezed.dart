// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AppUser {

 String get id; String get phone; bool get phoneVerified; String? get email; bool get emailVerified; String get status; String get country; String get currency; String get locale; String get kycTier; String get kycStatus; bool get hasPin; String get referralCode; List<String> get restrictions; Consents get consents;
/// Create a copy of AppUser
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppUserCopyWith<AppUser> get copyWith => _$AppUserCopyWithImpl<AppUser>(this as AppUser, _$identity);

  /// Serializes this AppUser to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as AppUser;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppUser&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.phone, _this.phone) || other.phone == _this.phone)&&(identical(other.phoneVerified, _this.phoneVerified) || other.phoneVerified == _this.phoneVerified)&&(identical(other.email, _this.email) || other.email == _this.email)&&(identical(other.emailVerified, _this.emailVerified) || other.emailVerified == _this.emailVerified)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.country, _this.country) || other.country == _this.country)&&(identical(other.currency, _this.currency) || other.currency == _this.currency)&&(identical(other.locale, _this.locale) || other.locale == _this.locale)&&(identical(other.kycTier, _this.kycTier) || other.kycTier == _this.kycTier)&&(identical(other.kycStatus, _this.kycStatus) || other.kycStatus == _this.kycStatus)&&(identical(other.hasPin, _this.hasPin) || other.hasPin == _this.hasPin)&&(identical(other.referralCode, _this.referralCode) || other.referralCode == _this.referralCode)&&const DeepCollectionEquality().equals(other.restrictions, _this.restrictions)&&(identical(other.consents, _this.consents) || other.consents == _this.consents));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AppUser;
  return Object.hash(runtimeType,_this.id,_this.phone,_this.phoneVerified,_this.email,_this.emailVerified,_this.status,_this.country,_this.currency,_this.locale,_this.kycTier,_this.kycStatus,_this.hasPin,_this.referralCode,const DeepCollectionEquality().hash(_this.restrictions),_this.consents);
}

@override
String toString() {
  final _this = this as AppUser;
  return 'AppUser(id: ${_this.id}, phone: ${_this.phone}, phoneVerified: ${_this.phoneVerified}, email: ${_this.email}, emailVerified: ${_this.emailVerified}, status: ${_this.status}, country: ${_this.country}, currency: ${_this.currency}, locale: ${_this.locale}, kycTier: ${_this.kycTier}, kycStatus: ${_this.kycStatus}, hasPin: ${_this.hasPin}, referralCode: ${_this.referralCode}, restrictions: ${_this.restrictions}, consents: ${_this.consents})';
}


}

/// @nodoc
abstract mixin class $AppUserCopyWith<$Res>  {
  factory $AppUserCopyWith(AppUser value, $Res Function(AppUser) _then) = _$AppUserCopyWithImpl;
@useResult
$Res call({
 String id, String phone, bool phoneVerified, String? email, bool emailVerified, String status, String country, String currency, String locale, String kycTier, String kycStatus, bool hasPin, String referralCode, List<String> restrictions, Consents consents
});


$ConsentsCopyWith<$Res> get consents;

}
/// @nodoc
class _$AppUserCopyWithImpl<$Res>
    implements $AppUserCopyWith<$Res> {
  _$AppUserCopyWithImpl(this._self, this._then);

  final AppUser _self;
  final $Res Function(AppUser) _then;

/// Create a copy of AppUser
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? phone = null,Object? phoneVerified = null,Object? email = freezed,Object? emailVerified = null,Object? status = null,Object? country = null,Object? currency = null,Object? locale = null,Object? kycTier = null,Object? kycStatus = null,Object? hasPin = null,Object? referralCode = null,Object? restrictions = null,Object? consents = null,}) {
  return _then(AppUser(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,phoneVerified: null == phoneVerified ? _self.phoneVerified : phoneVerified // ignore: cast_nullable_to_non_nullable
as bool,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,emailVerified: null == emailVerified ? _self.emailVerified : emailVerified // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,country: null == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,locale: null == locale ? _self.locale : locale // ignore: cast_nullable_to_non_nullable
as String,kycTier: null == kycTier ? _self.kycTier : kycTier // ignore: cast_nullable_to_non_nullable
as String,kycStatus: null == kycStatus ? _self.kycStatus : kycStatus // ignore: cast_nullable_to_non_nullable
as String,hasPin: null == hasPin ? _self.hasPin : hasPin // ignore: cast_nullable_to_non_nullable
as bool,referralCode: null == referralCode ? _self.referralCode : referralCode // ignore: cast_nullable_to_non_nullable
as String,restrictions: null == restrictions ? _self.restrictions : restrictions // ignore: cast_nullable_to_non_nullable
as List<String>,consents: null == consents ? _self.consents : consents // ignore: cast_nullable_to_non_nullable
as Consents,
  ));
}
/// Create a copy of AppUser
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ConsentsCopyWith<$Res> get consents {
  
  return $ConsentsCopyWith<$Res>(_self.consents, (value) {
    return _then(_self.copyWith(consents: value));
  });
}
}


/// Adds pattern-matching-related methods to [AppUser].
extension AppUserPatterns on AppUser {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppUser value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppUser() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppUser value)  $default,){
final _that = this;
switch (_that) {
case _AppUser():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppUser value)?  $default,){
final _that = this;
switch (_that) {
case _AppUser() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String phone,  bool phoneVerified,  String? email,  bool emailVerified,  String status,  String country,  String currency,  String locale,  String kycTier,  String kycStatus,  bool hasPin,  String referralCode,  List<String> restrictions,  Consents consents)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppUser() when $default != null:
return $default(_that.id,_that.phone,_that.phoneVerified,_that.email,_that.emailVerified,_that.status,_that.country,_that.currency,_that.locale,_that.kycTier,_that.kycStatus,_that.hasPin,_that.referralCode,_that.restrictions,_that.consents);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String phone,  bool phoneVerified,  String? email,  bool emailVerified,  String status,  String country,  String currency,  String locale,  String kycTier,  String kycStatus,  bool hasPin,  String referralCode,  List<String> restrictions,  Consents consents)  $default,) {final _that = this;
switch (_that) {
case _AppUser():
return $default(_that.id,_that.phone,_that.phoneVerified,_that.email,_that.emailVerified,_that.status,_that.country,_that.currency,_that.locale,_that.kycTier,_that.kycStatus,_that.hasPin,_that.referralCode,_that.restrictions,_that.consents);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String phone,  bool phoneVerified,  String? email,  bool emailVerified,  String status,  String country,  String currency,  String locale,  String kycTier,  String kycStatus,  bool hasPin,  String referralCode,  List<String> restrictions,  Consents consents)?  $default,) {final _that = this;
switch (_that) {
case _AppUser() when $default != null:
return $default(_that.id,_that.phone,_that.phoneVerified,_that.email,_that.emailVerified,_that.status,_that.country,_that.currency,_that.locale,_that.kycTier,_that.kycStatus,_that.hasPin,_that.referralCode,_that.restrictions,_that.consents);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppUser implements AppUser {
  const _AppUser({required this.id, required this.phone, required this.phoneVerified, this.email, required this.emailVerified, required this.status, required this.country, required this.currency, required this.locale, required this.kycTier, required this.kycStatus, required this.hasPin, required this.referralCode,  List<String> restrictions = const <String>[], this.consents = const Consents()}): _restrictions = restrictions;
  factory _AppUser.fromJson(Map<String, dynamic> json) => _$AppUserFromJson(json);

@override final  String id;
@override final  String phone;
@override final  bool phoneVerified;
@override final  String? email;
@override final  bool emailVerified;
@override final  String status;
@override final  String country;
@override final  String currency;
@override final  String locale;
@override final  String kycTier;
@override final  String kycStatus;
@override final  bool hasPin;
@override final  String referralCode;
 final  List<String> _restrictions;
@override@JsonKey() List<String> get restrictions {
  if (_restrictions is EqualUnmodifiableListView) return _restrictions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_restrictions);
}

@override@JsonKey() final  Consents consents;

/// Create a copy of AppUser
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppUserCopyWith<_AppUser> get copyWith => __$AppUserCopyWithImpl<_AppUser>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppUserToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppUser&&(identical(other.id, id) || other.id == id)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.phoneVerified, phoneVerified) || other.phoneVerified == phoneVerified)&&(identical(other.email, email) || other.email == email)&&(identical(other.emailVerified, emailVerified) || other.emailVerified == emailVerified)&&(identical(other.status, status) || other.status == status)&&(identical(other.country, country) || other.country == country)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.locale, locale) || other.locale == locale)&&(identical(other.kycTier, kycTier) || other.kycTier == kycTier)&&(identical(other.kycStatus, kycStatus) || other.kycStatus == kycStatus)&&(identical(other.hasPin, hasPin) || other.hasPin == hasPin)&&(identical(other.referralCode, referralCode) || other.referralCode == referralCode)&&const DeepCollectionEquality().equals(other.restrictions, _restrictions)&&(identical(other.consents, consents) || other.consents == consents));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,phone,phoneVerified,email,emailVerified,status,country,currency,locale,kycTier,kycStatus,hasPin,referralCode,const DeepCollectionEquality().hash(_restrictions),consents);
}

@override
String toString() {
    return 'AppUser(id: $id, phone: $phone, phoneVerified: $phoneVerified, email: $email, emailVerified: $emailVerified, status: $status, country: $country, currency: $currency, locale: $locale, kycTier: $kycTier, kycStatus: $kycStatus, hasPin: $hasPin, referralCode: $referralCode, restrictions: $restrictions, consents: $consents)';
}


}

/// @nodoc
abstract mixin class _$AppUserCopyWith<$Res> implements $AppUserCopyWith<$Res> {
  factory _$AppUserCopyWith(_AppUser value, $Res Function(_AppUser) _then) = __$AppUserCopyWithImpl;
@override @useResult
$Res call({
 String id, String phone, bool phoneVerified, String? email, bool emailVerified, String status, String country, String currency, String locale, String kycTier, String kycStatus, bool hasPin, String referralCode, List<String> restrictions, Consents consents
});


@override $ConsentsCopyWith<$Res> get consents;

}
/// @nodoc
class __$AppUserCopyWithImpl<$Res>
    implements _$AppUserCopyWith<$Res> {
  __$AppUserCopyWithImpl(this._self, this._then);

  final _AppUser _self;
  final $Res Function(_AppUser) _then;

/// Create a copy of AppUser
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? phone = null,Object? phoneVerified = null,Object? email = freezed,Object? emailVerified = null,Object? status = null,Object? country = null,Object? currency = null,Object? locale = null,Object? kycTier = null,Object? kycStatus = null,Object? hasPin = null,Object? referralCode = null,Object? restrictions = null,Object? consents = null,}) {
  return _then(_AppUser(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,phoneVerified: null == phoneVerified ? _self.phoneVerified : phoneVerified // ignore: cast_nullable_to_non_nullable
as bool,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,emailVerified: null == emailVerified ? _self.emailVerified : emailVerified // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,country: null == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,locale: null == locale ? _self.locale : locale // ignore: cast_nullable_to_non_nullable
as String,kycTier: null == kycTier ? _self.kycTier : kycTier // ignore: cast_nullable_to_non_nullable
as String,kycStatus: null == kycStatus ? _self.kycStatus : kycStatus // ignore: cast_nullable_to_non_nullable
as String,hasPin: null == hasPin ? _self.hasPin : hasPin // ignore: cast_nullable_to_non_nullable
as bool,referralCode: null == referralCode ? _self.referralCode : referralCode // ignore: cast_nullable_to_non_nullable
as String,restrictions: null == restrictions ? _self._restrictions : restrictions // ignore: cast_nullable_to_non_nullable
as List<String>,consents: null == consents ? _self.consents : consents // ignore: cast_nullable_to_non_nullable
as Consents,
  ));
}

/// Create a copy of AppUser
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ConsentsCopyWith<$Res> get consents {
  
  return $ConsentsCopyWith<$Res>(_self.consents, (value) {
    return _then(_self.copyWith(consents: value));
  });
}
}


/// @nodoc
mixin _$Consents {

 bool get marketing; bool get aiInsights; bool get externalAiProcessing;
/// Create a copy of Consents
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConsentsCopyWith<Consents> get copyWith => _$ConsentsCopyWithImpl<Consents>(this as Consents, _$identity);

  /// Serializes this Consents to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Consents;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Consents&&(identical(other.marketing, _this.marketing) || other.marketing == _this.marketing)&&(identical(other.aiInsights, _this.aiInsights) || other.aiInsights == _this.aiInsights)&&(identical(other.externalAiProcessing, _this.externalAiProcessing) || other.externalAiProcessing == _this.externalAiProcessing));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Consents;
  return Object.hash(runtimeType,_this.marketing,_this.aiInsights,_this.externalAiProcessing);
}

@override
String toString() {
  final _this = this as Consents;
  return 'Consents(marketing: ${_this.marketing}, aiInsights: ${_this.aiInsights}, externalAiProcessing: ${_this.externalAiProcessing})';
}


}

/// @nodoc
abstract mixin class $ConsentsCopyWith<$Res>  {
  factory $ConsentsCopyWith(Consents value, $Res Function(Consents) _then) = _$ConsentsCopyWithImpl;
@useResult
$Res call({
 bool marketing, bool aiInsights, bool externalAiProcessing
});




}
/// @nodoc
class _$ConsentsCopyWithImpl<$Res>
    implements $ConsentsCopyWith<$Res> {
  _$ConsentsCopyWithImpl(this._self, this._then);

  final Consents _self;
  final $Res Function(Consents) _then;

/// Create a copy of Consents
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? marketing = null,Object? aiInsights = null,Object? externalAiProcessing = null,}) {
  return _then(Consents(
marketing: null == marketing ? _self.marketing : marketing // ignore: cast_nullable_to_non_nullable
as bool,aiInsights: null == aiInsights ? _self.aiInsights : aiInsights // ignore: cast_nullable_to_non_nullable
as bool,externalAiProcessing: null == externalAiProcessing ? _self.externalAiProcessing : externalAiProcessing // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Consents].
extension ConsentsPatterns on Consents {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Consents value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Consents() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Consents value)  $default,){
final _that = this;
switch (_that) {
case _Consents():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Consents value)?  $default,){
final _that = this;
switch (_that) {
case _Consents() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool marketing,  bool aiInsights,  bool externalAiProcessing)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Consents() when $default != null:
return $default(_that.marketing,_that.aiInsights,_that.externalAiProcessing);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool marketing,  bool aiInsights,  bool externalAiProcessing)  $default,) {final _that = this;
switch (_that) {
case _Consents():
return $default(_that.marketing,_that.aiInsights,_that.externalAiProcessing);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool marketing,  bool aiInsights,  bool externalAiProcessing)?  $default,) {final _that = this;
switch (_that) {
case _Consents() when $default != null:
return $default(_that.marketing,_that.aiInsights,_that.externalAiProcessing);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Consents implements Consents {
  const _Consents({this.marketing = false, this.aiInsights = false, this.externalAiProcessing = false});
  factory _Consents.fromJson(Map<String, dynamic> json) => _$ConsentsFromJson(json);

@override@JsonKey() final  bool marketing;
@override@JsonKey() final  bool aiInsights;
@override@JsonKey() final  bool externalAiProcessing;

/// Create a copy of Consents
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConsentsCopyWith<_Consents> get copyWith => __$ConsentsCopyWithImpl<_Consents>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ConsentsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Consents&&(identical(other.marketing, marketing) || other.marketing == marketing)&&(identical(other.aiInsights, aiInsights) || other.aiInsights == aiInsights)&&(identical(other.externalAiProcessing, externalAiProcessing) || other.externalAiProcessing == externalAiProcessing));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,marketing,aiInsights,externalAiProcessing);
}

@override
String toString() {
    return 'Consents(marketing: $marketing, aiInsights: $aiInsights, externalAiProcessing: $externalAiProcessing)';
}


}

/// @nodoc
abstract mixin class _$ConsentsCopyWith<$Res> implements $ConsentsCopyWith<$Res> {
  factory _$ConsentsCopyWith(_Consents value, $Res Function(_Consents) _then) = __$ConsentsCopyWithImpl;
@override @useResult
$Res call({
 bool marketing, bool aiInsights, bool externalAiProcessing
});




}
/// @nodoc
class __$ConsentsCopyWithImpl<$Res>
    implements _$ConsentsCopyWith<$Res> {
  __$ConsentsCopyWithImpl(this._self, this._then);

  final _Consents _self;
  final $Res Function(_Consents) _then;

/// Create a copy of Consents
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? marketing = null,Object? aiInsights = null,Object? externalAiProcessing = null,}) {
  return _then(_Consents(
marketing: null == marketing ? _self.marketing : marketing // ignore: cast_nullable_to_non_nullable
as bool,aiInsights: null == aiInsights ? _self.aiInsights : aiInsights // ignore: cast_nullable_to_non_nullable
as bool,externalAiProcessing: null == externalAiProcessing ? _self.externalAiProcessing : externalAiProcessing // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$Profile {

 String? get firstName; String? get lastName; DateTime? get dateOfBirth; String? get occupation; bool get hasAvatar; Map<String, dynamic> get address; Map<String, dynamic> get notificationPreferences; Map<String, dynamic> get privacy;
/// Create a copy of Profile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfileCopyWith<Profile> get copyWith => _$ProfileCopyWithImpl<Profile>(this as Profile, _$identity);

  /// Serializes this Profile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Profile;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Profile&&(identical(other.firstName, _this.firstName) || other.firstName == _this.firstName)&&(identical(other.lastName, _this.lastName) || other.lastName == _this.lastName)&&(identical(other.dateOfBirth, _this.dateOfBirth) || other.dateOfBirth == _this.dateOfBirth)&&(identical(other.occupation, _this.occupation) || other.occupation == _this.occupation)&&(identical(other.hasAvatar, _this.hasAvatar) || other.hasAvatar == _this.hasAvatar)&&const DeepCollectionEquality().equals(other.address, _this.address)&&const DeepCollectionEquality().equals(other.notificationPreferences, _this.notificationPreferences)&&const DeepCollectionEquality().equals(other.privacy, _this.privacy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Profile;
  return Object.hash(runtimeType,_this.firstName,_this.lastName,_this.dateOfBirth,_this.occupation,_this.hasAvatar,const DeepCollectionEquality().hash(_this.address),const DeepCollectionEquality().hash(_this.notificationPreferences),const DeepCollectionEquality().hash(_this.privacy));
}

@override
String toString() {
  final _this = this as Profile;
  return 'Profile(firstName: ${_this.firstName}, lastName: ${_this.lastName}, dateOfBirth: ${_this.dateOfBirth}, occupation: ${_this.occupation}, hasAvatar: ${_this.hasAvatar}, address: ${_this.address}, notificationPreferences: ${_this.notificationPreferences}, privacy: ${_this.privacy})';
}


}

/// @nodoc
abstract mixin class $ProfileCopyWith<$Res>  {
  factory $ProfileCopyWith(Profile value, $Res Function(Profile) _then) = _$ProfileCopyWithImpl;
@useResult
$Res call({
 String? firstName, String? lastName, DateTime? dateOfBirth, String? occupation, bool hasAvatar, Map<String, dynamic> address, Map<String, dynamic> notificationPreferences, Map<String, dynamic> privacy
});




}
/// @nodoc
class _$ProfileCopyWithImpl<$Res>
    implements $ProfileCopyWith<$Res> {
  _$ProfileCopyWithImpl(this._self, this._then);

  final Profile _self;
  final $Res Function(Profile) _then;

/// Create a copy of Profile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? firstName = freezed,Object? lastName = freezed,Object? dateOfBirth = freezed,Object? occupation = freezed,Object? hasAvatar = null,Object? address = null,Object? notificationPreferences = null,Object? privacy = null,}) {
  return _then(Profile(
firstName: freezed == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String?,lastName: freezed == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String?,dateOfBirth: freezed == dateOfBirth ? _self.dateOfBirth : dateOfBirth // ignore: cast_nullable_to_non_nullable
as DateTime?,occupation: freezed == occupation ? _self.occupation : occupation // ignore: cast_nullable_to_non_nullable
as String?,hasAvatar: null == hasAvatar ? _self.hasAvatar : hasAvatar // ignore: cast_nullable_to_non_nullable
as bool,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,notificationPreferences: null == notificationPreferences ? _self.notificationPreferences : notificationPreferences // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,privacy: null == privacy ? _self.privacy : privacy // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [Profile].
extension ProfilePatterns on Profile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Profile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Profile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Profile value)  $default,){
final _that = this;
switch (_that) {
case _Profile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Profile value)?  $default,){
final _that = this;
switch (_that) {
case _Profile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? firstName,  String? lastName,  DateTime? dateOfBirth,  String? occupation,  bool hasAvatar,  Map<String, dynamic> address,  Map<String, dynamic> notificationPreferences,  Map<String, dynamic> privacy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Profile() when $default != null:
return $default(_that.firstName,_that.lastName,_that.dateOfBirth,_that.occupation,_that.hasAvatar,_that.address,_that.notificationPreferences,_that.privacy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? firstName,  String? lastName,  DateTime? dateOfBirth,  String? occupation,  bool hasAvatar,  Map<String, dynamic> address,  Map<String, dynamic> notificationPreferences,  Map<String, dynamic> privacy)  $default,) {final _that = this;
switch (_that) {
case _Profile():
return $default(_that.firstName,_that.lastName,_that.dateOfBirth,_that.occupation,_that.hasAvatar,_that.address,_that.notificationPreferences,_that.privacy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? firstName,  String? lastName,  DateTime? dateOfBirth,  String? occupation,  bool hasAvatar,  Map<String, dynamic> address,  Map<String, dynamic> notificationPreferences,  Map<String, dynamic> privacy)?  $default,) {final _that = this;
switch (_that) {
case _Profile() when $default != null:
return $default(_that.firstName,_that.lastName,_that.dateOfBirth,_that.occupation,_that.hasAvatar,_that.address,_that.notificationPreferences,_that.privacy);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Profile implements Profile {
  const _Profile({this.firstName, this.lastName, this.dateOfBirth, this.occupation, this.hasAvatar = false,  Map<String, dynamic> address = const <String, dynamic>{},  Map<String, dynamic> notificationPreferences = const <String, dynamic>{},  Map<String, dynamic> privacy = const <String, dynamic>{}}): _address = address,_notificationPreferences = notificationPreferences,_privacy = privacy;
  factory _Profile.fromJson(Map<String, dynamic> json) => _$ProfileFromJson(json);

@override final  String? firstName;
@override final  String? lastName;
@override final  DateTime? dateOfBirth;
@override final  String? occupation;
@override@JsonKey() final  bool hasAvatar;
 final  Map<String, dynamic> _address;
@override@JsonKey() Map<String, dynamic> get address {
  if (_address is EqualUnmodifiableMapView) return _address;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_address);
}

 final  Map<String, dynamic> _notificationPreferences;
@override@JsonKey() Map<String, dynamic> get notificationPreferences {
  if (_notificationPreferences is EqualUnmodifiableMapView) return _notificationPreferences;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_notificationPreferences);
}

 final  Map<String, dynamic> _privacy;
@override@JsonKey() Map<String, dynamic> get privacy {
  if (_privacy is EqualUnmodifiableMapView) return _privacy;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_privacy);
}


/// Create a copy of Profile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfileCopyWith<_Profile> get copyWith => __$ProfileCopyWithImpl<_Profile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProfileToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Profile&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.dateOfBirth, dateOfBirth) || other.dateOfBirth == dateOfBirth)&&(identical(other.occupation, occupation) || other.occupation == occupation)&&(identical(other.hasAvatar, hasAvatar) || other.hasAvatar == hasAvatar)&&const DeepCollectionEquality().equals(other.address, _address)&&const DeepCollectionEquality().equals(other.notificationPreferences, _notificationPreferences)&&const DeepCollectionEquality().equals(other.privacy, _privacy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,firstName,lastName,dateOfBirth,occupation,hasAvatar,const DeepCollectionEquality().hash(_address),const DeepCollectionEquality().hash(_notificationPreferences),const DeepCollectionEquality().hash(_privacy));
}

@override
String toString() {
    return 'Profile(firstName: $firstName, lastName: $lastName, dateOfBirth: $dateOfBirth, occupation: $occupation, hasAvatar: $hasAvatar, address: $address, notificationPreferences: $notificationPreferences, privacy: $privacy)';
}


}

/// @nodoc
abstract mixin class _$ProfileCopyWith<$Res> implements $ProfileCopyWith<$Res> {
  factory _$ProfileCopyWith(_Profile value, $Res Function(_Profile) _then) = __$ProfileCopyWithImpl;
@override @useResult
$Res call({
 String? firstName, String? lastName, DateTime? dateOfBirth, String? occupation, bool hasAvatar, Map<String, dynamic> address, Map<String, dynamic> notificationPreferences, Map<String, dynamic> privacy
});




}
/// @nodoc
class __$ProfileCopyWithImpl<$Res>
    implements _$ProfileCopyWith<$Res> {
  __$ProfileCopyWithImpl(this._self, this._then);

  final _Profile _self;
  final $Res Function(_Profile) _then;

/// Create a copy of Profile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? firstName = freezed,Object? lastName = freezed,Object? dateOfBirth = freezed,Object? occupation = freezed,Object? hasAvatar = null,Object? address = null,Object? notificationPreferences = null,Object? privacy = null,}) {
  return _then(_Profile(
firstName: freezed == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String?,lastName: freezed == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String?,dateOfBirth: freezed == dateOfBirth ? _self.dateOfBirth : dateOfBirth // ignore: cast_nullable_to_non_nullable
as DateTime?,occupation: freezed == occupation ? _self.occupation : occupation // ignore: cast_nullable_to_non_nullable
as String?,hasAvatar: null == hasAvatar ? _self.hasAvatar : hasAvatar // ignore: cast_nullable_to_non_nullable
as bool,address: null == address ? _self._address : address // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,notificationPreferences: null == notificationPreferences ? _self._notificationPreferences : notificationPreferences // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,privacy: null == privacy ? _self._privacy : privacy // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}


/// @nodoc
mixin _$AuthTokens {

 String get accessToken; String get refreshToken; int get expiresIn; String get sessionId;
/// Create a copy of AuthTokens
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthTokensCopyWith<AuthTokens> get copyWith => _$AuthTokensCopyWithImpl<AuthTokens>(this as AuthTokens, _$identity);

  /// Serializes this AuthTokens to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as AuthTokens;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthTokens&&(identical(other.accessToken, _this.accessToken) || other.accessToken == _this.accessToken)&&(identical(other.refreshToken, _this.refreshToken) || other.refreshToken == _this.refreshToken)&&(identical(other.expiresIn, _this.expiresIn) || other.expiresIn == _this.expiresIn)&&(identical(other.sessionId, _this.sessionId) || other.sessionId == _this.sessionId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AuthTokens;
  return Object.hash(runtimeType,_this.accessToken,_this.refreshToken,_this.expiresIn,_this.sessionId);
}

@override
String toString() {
  final _this = this as AuthTokens;
  return 'AuthTokens(accessToken: ${_this.accessToken}, refreshToken: ${_this.refreshToken}, expiresIn: ${_this.expiresIn}, sessionId: ${_this.sessionId})';
}


}

/// @nodoc
abstract mixin class $AuthTokensCopyWith<$Res>  {
  factory $AuthTokensCopyWith(AuthTokens value, $Res Function(AuthTokens) _then) = _$AuthTokensCopyWithImpl;
@useResult
$Res call({
 String accessToken, String refreshToken, int expiresIn, String sessionId
});




}
/// @nodoc
class _$AuthTokensCopyWithImpl<$Res>
    implements $AuthTokensCopyWith<$Res> {
  _$AuthTokensCopyWithImpl(this._self, this._then);

  final AuthTokens _self;
  final $Res Function(AuthTokens) _then;

/// Create a copy of AuthTokens
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? accessToken = null,Object? refreshToken = null,Object? expiresIn = null,Object? sessionId = null,}) {
  return _then(AuthTokens(
accessToken: null == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as String,refreshToken: null == refreshToken ? _self.refreshToken : refreshToken // ignore: cast_nullable_to_non_nullable
as String,expiresIn: null == expiresIn ? _self.expiresIn : expiresIn // ignore: cast_nullable_to_non_nullable
as int,sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AuthTokens].
extension AuthTokensPatterns on AuthTokens {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthTokens value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthTokens() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthTokens value)  $default,){
final _that = this;
switch (_that) {
case _AuthTokens():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthTokens value)?  $default,){
final _that = this;
switch (_that) {
case _AuthTokens() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String accessToken,  String refreshToken,  int expiresIn,  String sessionId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthTokens() when $default != null:
return $default(_that.accessToken,_that.refreshToken,_that.expiresIn,_that.sessionId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String accessToken,  String refreshToken,  int expiresIn,  String sessionId)  $default,) {final _that = this;
switch (_that) {
case _AuthTokens():
return $default(_that.accessToken,_that.refreshToken,_that.expiresIn,_that.sessionId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String accessToken,  String refreshToken,  int expiresIn,  String sessionId)?  $default,) {final _that = this;
switch (_that) {
case _AuthTokens() when $default != null:
return $default(_that.accessToken,_that.refreshToken,_that.expiresIn,_that.sessionId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AuthTokens implements AuthTokens {
  const _AuthTokens({required this.accessToken, required this.refreshToken, required this.expiresIn, required this.sessionId});
  factory _AuthTokens.fromJson(Map<String, dynamic> json) => _$AuthTokensFromJson(json);

@override final  String accessToken;
@override final  String refreshToken;
@override final  int expiresIn;
@override final  String sessionId;

/// Create a copy of AuthTokens
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthTokensCopyWith<_AuthTokens> get copyWith => __$AuthTokensCopyWithImpl<_AuthTokens>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AuthTokensToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthTokens&&(identical(other.accessToken, accessToken) || other.accessToken == accessToken)&&(identical(other.refreshToken, refreshToken) || other.refreshToken == refreshToken)&&(identical(other.expiresIn, expiresIn) || other.expiresIn == expiresIn)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,accessToken,refreshToken,expiresIn,sessionId);
}

@override
String toString() {
    return 'AuthTokens(accessToken: $accessToken, refreshToken: $refreshToken, expiresIn: $expiresIn, sessionId: $sessionId)';
}


}

/// @nodoc
abstract mixin class _$AuthTokensCopyWith<$Res> implements $AuthTokensCopyWith<$Res> {
  factory _$AuthTokensCopyWith(_AuthTokens value, $Res Function(_AuthTokens) _then) = __$AuthTokensCopyWithImpl;
@override @useResult
$Res call({
 String accessToken, String refreshToken, int expiresIn, String sessionId
});




}
/// @nodoc
class __$AuthTokensCopyWithImpl<$Res>
    implements _$AuthTokensCopyWith<$Res> {
  __$AuthTokensCopyWithImpl(this._self, this._then);

  final _AuthTokens _self;
  final $Res Function(_AuthTokens) _then;

/// Create a copy of AuthTokens
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? accessToken = null,Object? refreshToken = null,Object? expiresIn = null,Object? sessionId = null,}) {
  return _then(_AuthTokens(
accessToken: null == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as String,refreshToken: null == refreshToken ? _self.refreshToken : refreshToken // ignore: cast_nullable_to_non_nullable
as String,expiresIn: null == expiresIn ? _self.expiresIn : expiresIn // ignore: cast_nullable_to_non_nullable
as int,sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$PendingOtp {

 String get phone; OtpPurpose get purpose; String? get challengeId; DateTime? get expiresAt;
/// Create a copy of PendingOtp
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PendingOtpCopyWith<PendingOtp> get copyWith => _$PendingOtpCopyWithImpl<PendingOtp>(this as PendingOtp, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PendingOtp;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PendingOtp&&(identical(other.phone, _this.phone) || other.phone == _this.phone)&&(identical(other.purpose, _this.purpose) || other.purpose == _this.purpose)&&(identical(other.challengeId, _this.challengeId) || other.challengeId == _this.challengeId)&&(identical(other.expiresAt, _this.expiresAt) || other.expiresAt == _this.expiresAt));
}


@override
int get hashCode {
  final _this = this as PendingOtp;
  return Object.hash(runtimeType,_this.phone,_this.purpose,_this.challengeId,_this.expiresAt);
}

@override
String toString() {
  final _this = this as PendingOtp;
  return 'PendingOtp(phone: ${_this.phone}, purpose: ${_this.purpose}, challengeId: ${_this.challengeId}, expiresAt: ${_this.expiresAt})';
}


}

/// @nodoc
abstract mixin class $PendingOtpCopyWith<$Res>  {
  factory $PendingOtpCopyWith(PendingOtp value, $Res Function(PendingOtp) _then) = _$PendingOtpCopyWithImpl;
@useResult
$Res call({
 String phone, OtpPurpose purpose, String? challengeId, DateTime? expiresAt
});




}
/// @nodoc
class _$PendingOtpCopyWithImpl<$Res>
    implements $PendingOtpCopyWith<$Res> {
  _$PendingOtpCopyWithImpl(this._self, this._then);

  final PendingOtp _self;
  final $Res Function(PendingOtp) _then;

/// Create a copy of PendingOtp
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? phone = null,Object? purpose = null,Object? challengeId = freezed,Object? expiresAt = freezed,}) {
  return _then(PendingOtp(
phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,purpose: null == purpose ? _self.purpose : purpose // ignore: cast_nullable_to_non_nullable
as OtpPurpose,challengeId: freezed == challengeId ? _self.challengeId : challengeId // ignore: cast_nullable_to_non_nullable
as String?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [PendingOtp].
extension PendingOtpPatterns on PendingOtp {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PendingOtp value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PendingOtp() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PendingOtp value)  $default,){
final _that = this;
switch (_that) {
case _PendingOtp():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PendingOtp value)?  $default,){
final _that = this;
switch (_that) {
case _PendingOtp() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String phone,  OtpPurpose purpose,  String? challengeId,  DateTime? expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PendingOtp() when $default != null:
return $default(_that.phone,_that.purpose,_that.challengeId,_that.expiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String phone,  OtpPurpose purpose,  String? challengeId,  DateTime? expiresAt)  $default,) {final _that = this;
switch (_that) {
case _PendingOtp():
return $default(_that.phone,_that.purpose,_that.challengeId,_that.expiresAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String phone,  OtpPurpose purpose,  String? challengeId,  DateTime? expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _PendingOtp() when $default != null:
return $default(_that.phone,_that.purpose,_that.challengeId,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc


class _PendingOtp implements PendingOtp {
  const _PendingOtp({required this.phone, required this.purpose, this.challengeId, this.expiresAt});
  

@override final  String phone;
@override final  OtpPurpose purpose;
@override final  String? challengeId;
@override final  DateTime? expiresAt;

/// Create a copy of PendingOtp
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PendingOtpCopyWith<_PendingOtp> get copyWith => __$PendingOtpCopyWithImpl<_PendingOtp>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PendingOtp&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.purpose, purpose) || other.purpose == purpose)&&(identical(other.challengeId, challengeId) || other.challengeId == challengeId)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,phone,purpose,challengeId,expiresAt);
}

@override
String toString() {
    return 'PendingOtp(phone: $phone, purpose: $purpose, challengeId: $challengeId, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$PendingOtpCopyWith<$Res> implements $PendingOtpCopyWith<$Res> {
  factory _$PendingOtpCopyWith(_PendingOtp value, $Res Function(_PendingOtp) _then) = __$PendingOtpCopyWithImpl;
@override @useResult
$Res call({
 String phone, OtpPurpose purpose, String? challengeId, DateTime? expiresAt
});




}
/// @nodoc
class __$PendingOtpCopyWithImpl<$Res>
    implements _$PendingOtpCopyWith<$Res> {
  __$PendingOtpCopyWithImpl(this._self, this._then);

  final _PendingOtp _self;
  final $Res Function(_PendingOtp) _then;

/// Create a copy of PendingOtp
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? phone = null,Object? purpose = null,Object? challengeId = freezed,Object? expiresAt = freezed,}) {
  return _then(_PendingOtp(
phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,purpose: null == purpose ? _self.purpose : purpose // ignore: cast_nullable_to_non_nullable
as OtpPurpose,challengeId: freezed == challengeId ? _self.challengeId : challengeId // ignore: cast_nullable_to_non_nullable
as String?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
