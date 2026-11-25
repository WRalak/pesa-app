import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:intl/intl.dart';

part 'money.freezed.dart';
part 'money.g.dart';

/// Money as returned by the API: integer minor units plus an exact decimal
/// string. The app never does arithmetic on doubles for money; display uses
/// the server-provided decimal string.
@freezed
abstract class Money with _$Money {
  const Money._();
  const factory Money({required int amountMinor, required String currency, required String amount}) = _Money;
  factory Money.fromJson(Map<String, dynamic> json) => _$MoneyFromJson(json);

  static const minorUnits = {'KES': 2, 'UGX': 0, 'TZS': 2, 'RWF': 0, 'NGN': 2, 'GHS': 2, 'ZAR': 2};
  static const symbols = {'KES': 'KSh', 'UGX': 'USh', 'TZS': 'TSh', 'RWF': 'FRw', 'NGN': '₦', 'GHS': 'GH₵', 'ZAR': 'R'};

  bool get isZero => amountMinor == 0;

  /// "KSh 1,500.50" — grouped using the decimal string, not a double.
  String format({bool symbol = true, bool compact = false, String locale = 'en_KE'}) {
    final neg = amount.startsWith('-');
    final parts = amount.replaceFirst('-', '').split('.');
    final whole = NumberFormat.decimalPattern(locale).format(BigInt.parse(parts[0]).toInt());
    var frac = parts.length > 1 ? parts[1] : '';
    if (compact && frac.replaceAll('0', '').isEmpty) frac = '';
    final body = frac.isEmpty ? whole : '$whole.$frac';
    final prefix = symbol ? '${symbols[currency] ?? currency} ' : '';
    return '${neg ? '-' : ''}$prefix$body';
  }

  /// Parses user input ("1,500.5") into an API decimal string without floats.
  static String? normalizeInput(String input, String currency) {
    final cleaned = input.replaceAll(',', '').replaceAll(' ', '').trim();
    final digits = minorUnits[currency] ?? 2;
    final re = RegExp(digits == 0 ? r'^\d{1,12}$' : '^\\d{1,12}(\\.\\d{1,$digits})?\$');
    if (!re.hasMatch(cleaned)) return null;
    if (BigInt.parse(cleaned.replaceAll('.', '')) == BigInt.zero) return null;
    return cleaned;
  }
}
