import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers.dart';
import '../../../core/utils/money.dart';
import '../../home/data/dashboard.dart';

part 'budgets.freezed.dart';
part 'budgets.g.dart';

@freezed
abstract class BudgetCategory with _$BudgetCategory {
  const factory BudgetCategory({required String category, required Money limit, required Money spent, required Money remaining, required int percentUsed, required bool overspent}) = _BudgetCategory;
  factory BudgetCategory.fromJson(Map<String, dynamic> json) => _$BudgetCategoryFromJson(json);
}

@freezed
abstract class Budget with _$Budget {
  const factory Budget({
    required String id, required String name, required String period, required Money totalLimit, required Money spent, required Money remaining,
    required int percentUsed, required int periodElapsedPercent, required bool onPace, @Default(<BudgetCategory>[]) List<BudgetCategory> categories,
    @Default(<int>[80, 100]) List<int> alertThresholds,
  }) = _Budget;
  factory Budget.fromJson(Map<String, dynamic> json) => _$BudgetFromJson(json);
}

@freezed
abstract class Entry with _$Entry {
  const factory Entry({required String id, required Money amount, required String category, String? description, required DateTime date, String? paymentMethod, @Default(false) bool recurring}) = _Entry;
  factory Entry.fromJson(Map<String, dynamic> json) => _$EntryFromJson(json);
}

class CategoryDef {
  const CategoryDef(this.key, this.label, this.icon);
  final String key, label, icon;
}

class BudgetsRepository {
  BudgetsRepository(this._api);
  final ApiClient _api;

  Future<(List<CategoryDef>, List<CategoryDef>)> categories() async {
    final r = await _api.get('/v1/budgets/categories');
    List<CategoryDef> map(List<dynamic> l) => [for (final c in l) CategoryDef('${(c as Json)['key']}', '${c['label']}', '${c['icon']}')];
    return (map(r['expense'] as List), map(r['income'] as List));
  }

  Future<List<Budget>> budgets() async => [for (final b in (await _api.get('/v1/budgets'))['items'] as List) Budget.fromJson(b as Json)];
  Future<void> create(Json body) => _api.post('/v1/budgets', body: body);
  Future<void> update(String id, Json body) => _api.patch('/v1/budgets/$id', body: body);
  Future<void> delete(String id) => _api.delete('/v1/budgets/$id');
  Future<List<Entry>> entries(String kind) async => [for (final e in (await _api.get('/v1/budgets/${kind == 'INCOME' ? 'income' : 'expenses'}', query: {'limit': 50}))['items'] as List) Entry.fromJson(e as Json)];
  Future<void> addEntry(String kind, Json body) => _api.post('/v1/budgets/${kind == 'INCOME' ? 'income' : 'expenses'}', body: body);
  Future<void> deleteEntry(String kind, String id) => _api.delete('/v1/budgets/${kind == 'INCOME' ? 'income' : 'expenses'}/$id');
  Future<List<Json>> recurring() async => ((await _api.get('/v1/budgets/recurring'))['items'] as List).cast<Json>();
  Future<void> addRecurring(Json body) => _api.post('/v1/budgets/recurring', body: body);
  Future<void> stopRecurring(String id) => _api.delete('/v1/budgets/recurring/$id');
  Future<MonthSummary> summary(String period) async => MonthSummary.fromJson(await _api.get('/v1/analytics/summary', query: {'period': period}));
  Future<List<Json>> trends() async => ((await _api.get('/v1/analytics/trends', query: {'months': 6}))['months'] as List).cast<Json>();
  Future<Json> report({bool narrative = false}) => _api.get('/v1/insights/monthly-report', query: {'narrative': narrative ? 'true' : null});
}

final budgetsRepositoryProvider = Provider((ref) => BudgetsRepository(ref.watch(apiClientProvider)));
final budgetsProvider = FutureProvider.autoDispose((ref) => ref.watch(budgetsRepositoryProvider).budgets());
final categoriesProvider = FutureProvider((ref) => ref.watch(budgetsRepositoryProvider).categories());
final entriesProvider = FutureProvider.autoDispose.family<List<Entry>, String>((ref, kind) => ref.watch(budgetsRepositoryProvider).entries(kind));
final recurringProvider = FutureProvider.autoDispose((ref) => ref.watch(budgetsRepositoryProvider).recurring());
final summaryProvider = FutureProvider.autoDispose.family<MonthSummary, String>((ref, period) => ref.watch(budgetsRepositoryProvider).summary(period));
final trendsProvider = FutureProvider.autoDispose((ref) => ref.watch(budgetsRepositoryProvider).trends());
final reportProvider = FutureProvider.autoDispose.family<Json, bool>((ref, narrative) => ref.watch(budgetsRepositoryProvider).report(narrative: narrative));

String categoryLabel(String key) => key.replaceAll('_', ' ').replaceFirstMapped(RegExp('^.'), (m) => m[0]!.toUpperCase());
