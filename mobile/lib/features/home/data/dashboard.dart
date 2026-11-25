import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../core/providers.dart';
import '../../../core/utils/money.dart';
import '../../activity/data/models.dart';

part 'dashboard.freezed.dart';
part 'dashboard.g.dart';

@freezed
abstract class LinkedAccount with _$LinkedAccount {
  const factory LinkedAccount({
    required String id, required String kind, required String provider, required String displayName, String? maskedIdentifier,
    required String currency, Money? balance, required String balanceSource, DateTime? balanceAsOf, @Default(false) bool sandbox,
    required String status, @Default(false) bool isDefault,
  }) = _LinkedAccount;
  factory LinkedAccount.fromJson(Map<String, dynamic> json) => _$LinkedAccountFromJson(json);
}

@freezed
abstract class BalanceGroup with _$BalanceGroup {
  const factory BalanceGroup({Money? total, @Default(0) int accountCount, DateTime? oldestAsOf, @Default(false) bool sandbox}) = _BalanceGroup;
  factory BalanceGroup.fromJson(Map<String, dynamic> json) => _$BalanceGroupFromJson(json);
}

@freezed
abstract class CategoryAmount with _$CategoryAmount {
  const factory CategoryAmount({required String category, required Money amount, @Default(0) double share}) = _CategoryAmount;
  factory CategoryAmount.fromJson(Map<String, dynamic> json) => _$CategoryAmountFromJson(json);
}

@freezed
abstract class DailySpend with _$DailySpend {
  const factory DailySpend({required String date, required Money spent}) = _DailySpend;
  factory DailySpend.fromJson(Map<String, dynamic> json) => _$DailySpendFromJson(json);
}

@freezed
abstract class MonthSummary with _$MonthSummary {
  const factory MonthSummary({required Money income, required Money expenses, required Money net, @Default(<CategoryAmount>[]) List<CategoryAmount> byCategory, double? changeInExpensesPercent, @Default(<DailySpend>[]) List<DailySpend> daily, String? basisNote}) = _MonthSummary;
  factory MonthSummary.fromJson(Map<String, dynamic> json) => _$MonthSummaryFromJson(json);
}

@freezed
abstract class Dashboard with _$Dashboard {
  const factory Dashboard({
    String? greetingName,
    @Default(false) bool hideBalances,
    required BalanceGroup verified,
    required BalanceGroup manual,
    @Default(<LinkedAccount>[]) List<LinkedAccount> accounts,
    required MonthSummary month,
    @Default(<Txn>[]) List<Txn> recentTransactions,
    @Default(0) int pendingTransactions,
    @Default(0) int unreadNotifications,
    Map<String, dynamic>? savings,
    Map<String, dynamic>? budget,
  }) = _Dashboard;

  factory Dashboard.fromApi(Map<String, dynamic> j) {
    final b = j['balances'] as Map<String, dynamic>;
    return Dashboard(
      greetingName: j['greetingName'] as String?,
      hideBalances: j['hideBalances'] as bool? ?? false,
      verified: BalanceGroup.fromJson(b['verified'] as Map<String, dynamic>),
      manual: BalanceGroup.fromJson(b['manual'] as Map<String, dynamic>),
      accounts: [for (final a in b['accounts'] as List) LinkedAccount.fromJson(a as Map<String, dynamic>)],
      month: MonthSummary.fromJson(j['month'] as Map<String, dynamic>),
      recentTransactions: [for (final t in j['recentTransactions'] as List) Txn.fromJson(t as Map<String, dynamic>)],
      pendingTransactions: j['pendingTransactions'] as int? ?? 0,
      unreadNotifications: j['unreadNotifications'] as int? ?? 0,
      savings: j['savings'] as Map<String, dynamic>?,
      budget: j['budget'] as Map<String, dynamic>?,
    );
  }
}

final dashboardProvider = FutureProvider.autoDispose<Dashboard>((ref) async => Dashboard.fromApi(await ref.watch(apiClientProvider).get('/v1/dashboard')));
final accountsProvider = FutureProvider.autoDispose<List<LinkedAccount>>((ref) async =>
    [for (final a in (await ref.watch(apiClientProvider).get('/v1/accounts'))['items'] as List) LinkedAccount.fromJson(a as Map<String, dynamic>)]);
