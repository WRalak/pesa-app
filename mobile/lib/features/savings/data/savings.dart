import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers.dart';
import '../../../core/utils/money.dart';

part 'savings.freezed.dart';
part 'savings.g.dart';

@freezed
abstract class GoalAnalytics with _$GoalAnalytics {
  const factory GoalAnalytics({required int progressPercent, required Money remaining, DateTime? projectedCompletion, Money? requiredMonthly, bool? onTrack}) = _GoalAnalytics;
  factory GoalAnalytics.fromJson(Map<String, dynamic> json) => _$GoalAnalyticsFromJson(json);
}

@freezed
abstract class Reminder with _$Reminder {
  const factory Reminder({@Default('NONE') String frequency, Money? amount, DateTime? nextAt}) = _Reminder;
  factory Reminder.fromJson(Map<String, dynamic> json) => _$ReminderFromJson(json);
}

@freezed
abstract class SavingsGoal with _$SavingsGoal {
  const factory SavingsGoal({
    required String id, required String name, required String category, required String status, required Money target, required Money saved,
    DateTime? deadline, String? color, String? icon, required String custody, required String custodyNote, required Reminder reminder,
    DateTime? completedAt, required DateTime createdAt, required GoalAnalytics analytics,
  }) = _SavingsGoal;
  factory SavingsGoal.fromJson(Map<String, dynamic> json) => _$SavingsGoalFromJson(json);
}

@freezed
abstract class Contribution with _$Contribution {
  const factory Contribution({required String id, required String kind, required Money amount, String? note, required Money balanceAfter, required DateTime createdAt}) = _Contribution;
  factory Contribution.fromJson(Map<String, dynamic> json) => _$ContributionFromJson(json);
}

const goalCategories = {
  'EMERGENCY': 'Emergency fund', 'RENT': 'Rent', 'EDUCATION': 'Education', 'BUSINESS': 'Business capital', 'TRAVEL': 'Travel',
  'ELECTRONICS': 'Electronics', 'HOME': 'Home', 'HEALTH': 'Health', 'OTHER': 'Other',
};

class SavingsRepository {
  SavingsRepository(this._api);
  final ApiClient _api;

  Future<(List<SavingsGoal>, Json?)> goals({String? status}) async {
    final r = await _api.get('/v1/savings/goals', query: {'status': status});
    return ([for (final g in r['items'] as List) SavingsGoal.fromJson(g as Json)], r['summary'] as Json?);
  }

  Future<SavingsGoal> goal(String id) async => SavingsGoal.fromJson(await _api.get('/v1/savings/goals/$id'));
  Future<SavingsGoal> create(Json body) async => SavingsGoal.fromJson((await _api.post('/v1/savings/goals', body: body))!);
  Future<SavingsGoal> update(String id, Json body) async => SavingsGoal.fromJson(await _api.patch('/v1/savings/goals/$id', body: body));
  Future<SavingsGoal> archive(String id, bool archived) async => SavingsGoal.fromJson((await _api.post('/v1/savings/goals/$id/${archived ? 'archive' : 'restore'}'))!);
  Future<SavingsGoal> contribute(String id, String kind, String amount, String? note) async =>
      SavingsGoal.fromJson((await _api.post('/v1/savings/goals/$id/contributions', body: {'kind': kind, 'amount': amount, 'note': ?note}))!['goal'] as Json);
  Future<List<Contribution>> contributions(String id) async => [for (final c in (await _api.get('/v1/savings/goals/$id/contributions', query: {'limit': 50}))['items'] as List) Contribution.fromJson(c as Json)];
  Future<List<Json>> analytics() async => ((await _api.get('/v1/savings/analytics'))['series'] as List).cast<Json>();
}

final savingsRepositoryProvider = Provider((ref) => SavingsRepository(ref.watch(apiClientProvider)));
final goalsProvider = FutureProvider.autoDispose.family<(List<SavingsGoal>, Json?), String?>((ref, status) => ref.watch(savingsRepositoryProvider).goals(status: status));
final goalProvider = FutureProvider.autoDispose.family<SavingsGoal, String>((ref, id) => ref.watch(savingsRepositoryProvider).goal(id));
final contributionsProvider = FutureProvider.autoDispose.family<List<Contribution>, String>((ref, id) => ref.watch(savingsRepositoryProvider).contributions(id));
final savingsSeriesProvider = FutureProvider.autoDispose((ref) => ref.watch(savingsRepositoryProvider).analytics());
