// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppUser _$AppUserFromJson(Map<String, dynamic> json) => _AppUser(
  id: json['id'] as String,
  phone: json['phone'] as String,
  phoneVerified: json['phoneVerified'] as bool,
  email: json['email'] as String?,
  emailVerified: json['emailVerified'] as bool,
  status: json['status'] as String,
  country: json['country'] as String,
  currency: json['currency'] as String,
  locale: json['locale'] as String,
  kycTier: json['kycTier'] as String,
  kycStatus: json['kycStatus'] as String,
  hasPin: json['hasPin'] as bool,
  referralCode: json['referralCode'] as String,
  restrictions:
      (json['restrictions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  consents: json['consents'] == null
      ? const Consents()
      : Consents.fromJson(json['consents'] as Map<String, dynamic>),
);

Map<String, dynamic> _$AppUserToJson(_AppUser instance) => <String, dynamic>{
  'id': instance.id,
  'phone': instance.phone,
  'phoneVerified': instance.phoneVerified,
  'email': ?instance.email,
  'emailVerified': instance.emailVerified,
  'status': instance.status,
  'country': instance.country,
  'currency': instance.currency,
  'locale': instance.locale,
  'kycTier': instance.kycTier,
  'kycStatus': instance.kycStatus,
  'hasPin': instance.hasPin,
  'referralCode': instance.referralCode,
  'restrictions': instance.restrictions,
  'consents': instance.consents.toJson(),
};

_Consents _$ConsentsFromJson(Map<String, dynamic> json) => _Consents(
  marketing: json['marketing'] as bool? ?? false,
  aiInsights: json['aiInsights'] as bool? ?? false,
  externalAiProcessing: json['externalAiProcessing'] as bool? ?? false,
);

Map<String, dynamic> _$ConsentsToJson(_Consents instance) => <String, dynamic>{
  'marketing': instance.marketing,
  'aiInsights': instance.aiInsights,
  'externalAiProcessing': instance.externalAiProcessing,
};

_Profile _$ProfileFromJson(Map<String, dynamic> json) => _Profile(
  firstName: json['firstName'] as String?,
  lastName: json['lastName'] as String?,
  dateOfBirth: json['dateOfBirth'] == null
      ? null
      : DateTime.parse(json['dateOfBirth'] as String),
  occupation: json['occupation'] as String?,
  hasAvatar: json['hasAvatar'] as bool? ?? false,
  address:
      json['address'] as Map<String, dynamic>? ?? const <String, dynamic>{},
  notificationPreferences:
      json['notificationPreferences'] as Map<String, dynamic>? ??
      const <String, dynamic>{},
  privacy:
      json['privacy'] as Map<String, dynamic>? ?? const <String, dynamic>{},
);

Map<String, dynamic> _$ProfileToJson(_Profile instance) => <String, dynamic>{
  'firstName': ?instance.firstName,
  'lastName': ?instance.lastName,
  'dateOfBirth': ?instance.dateOfBirth?.toIso8601String(),
  'occupation': ?instance.occupation,
  'hasAvatar': instance.hasAvatar,
  'address': instance.address,
  'notificationPreferences': instance.notificationPreferences,
  'privacy': instance.privacy,
};

_AuthTokens _$AuthTokensFromJson(Map<String, dynamic> json) => _AuthTokens(
  accessToken: json['accessToken'] as String,
  refreshToken: json['refreshToken'] as String,
  expiresIn: (json['expiresIn'] as num).toInt(),
  sessionId: json['sessionId'] as String,
);

Map<String, dynamic> _$AuthTokensToJson(_AuthTokens instance) =>
    <String, dynamic>{
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
      'expiresIn': instance.expiresIn,
      'sessionId': instance.sessionId,
    };
