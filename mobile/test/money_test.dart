import 'package:flutter_test/flutter_test.dart';
import 'package:pesa/core/utils/money.dart';

void main() {
  group('Money', () {
    test('formats using the exact decimal string (no floating point)', () {
      const m = Money(amountMinor: 150050, currency: 'KES', amount: '1500.50');
      expect(m.format(), 'KSh 1,500.50');
      expect(const Money(amountMinor: 30000000001, currency: 'KES', amount: '300000000.01').format(), 'KSh 300,000,000.01');
    });

    test('compact drops zero decimals only', () {
      expect(const Money(amountMinor: 150000, currency: 'KES', amount: '1500.00').format(compact: true), 'KSh 1,500');
      expect(const Money(amountMinor: 150050, currency: 'KES', amount: '1500.50').format(compact: true), 'KSh 1,500.50');
    });

    test('handles zero-decimal currencies and negatives', () {
      expect(const Money(amountMinor: 1500, currency: 'UGX', amount: '1500').format(), 'USh 1,500');
      expect(const Money(amountMinor: -500, currency: 'KES', amount: '-5.00').format(), '-KSh 5.00');
    });

    test('normalises user input per currency precision', () {
      expect(Money.normalizeInput('1,500.5', 'KES'), '1500.5');
      expect(Money.normalizeInput('1500.555', 'KES'), isNull);
      expect(Money.normalizeInput('1500.5', 'UGX'), isNull);
      expect(Money.normalizeInput('2000', 'UGX'), '2000');
      expect(Money.normalizeInput('0', 'KES'), isNull);
      expect(Money.normalizeInput('abc', 'KES'), isNull);
      expect(Money.normalizeInput('-5', 'KES'), isNull);
    });

    test('round-trips JSON from the API', () {
      final m = Money.fromJson({'amountMinor': 2500, 'currency': 'KES', 'amount': '25.00'});
      expect(m.toJson(), {'amountMinor': 2500, 'currency': 'KES', 'amount': '25.00'});
    });
  });
}
