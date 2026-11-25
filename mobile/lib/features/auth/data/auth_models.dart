import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_models.freezed.dart';
part 'auth_models.g.dart';

@freezed
abstract class AppUser with _$AppUser {
  const factory AppUser({
    required String id,
    required String phone,
    required bool phoneVerified,
    String? email,
    required bool emailVerified,
    required String status,
    required String country,
    required String currency,
    required String locale,
    required String kycTier,
    required String kycStatus,
    required bool hasPin,
    required String referralCode,
    @Default(<String>[]) List<String> restrictions,
    @Default(Consents()) Consents consents,
  }) = _AppUser;
  factory AppUser.fromJson(Map<String, dynamic> json) => _$AppUserFromJson(json);
}

@freezed
abstract class Consents with _$Consents {
  const factory Consents({@Default(false) bool marketing, @Default(false) bool aiInsights, @Default(false) bool externalAiProcessing}) = _Consents;
  factory Consents.fromJson(Map<String, dynamic> json) => _$ConsentsFromJson(json);
}

@freezed
abstract class Profile with _$Profile {
  const factory Profile({
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
    String? occupation,
    @Default(false) bool hasAvatar,
    @Default(<String, dynamic>{}) Map<String, dynamic> address,
    @Default(<String, dynamic>{}) Map<String, dynamic> notificationPreferences,
    @Default(<String, dynamic>{}) Map<String, dynamic> privacy,
  }) = _Profile;
  factory Profile.fromJson(Map<String, dynamic> json) => _$ProfileFromJson(json);
}

@freezed
abstract class AuthTokens with _$AuthTokens {
  const factory AuthTokens({required String accessToken, required String refreshToken, required int expiresIn, required String sessionId}) = _AuthTokens;
  factory AuthTokens.fromJson(Map<String, dynamic> json) => _$AuthTokensFromJson(json);
}

/// A pending OTP step the user must complete.
enum OtpPurpose { phoneVerify, deviceVerify, passwordReset }

@freezed
abstract class PendingOtp with _$PendingOtp {
  const factory PendingOtp({required String phone, required OtpPurpose purpose, String? challengeId, DateTime? expiresAt}) = _PendingOtp;
}
