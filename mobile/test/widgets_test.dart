import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pesa/core/theme/theme.dart';
import 'package:pesa/core/utils/money.dart';
import 'package:pesa/core/widgets/widgets.dart';
import 'package:pesa/features/auth/ui/auth_widgets.dart';

Widget wrap(Widget child) => ProviderScope(child: MaterialApp(theme: PesaTheme.light(), home: Scaffold(body: child)));

void main() {
  testWidgets('PinPad collects digits and reports completion', (tester) async {
    String? pin;
    await tester.pumpWidget(wrap(PinPad(onCompleted: (p) => pin = p)));
    for (final d in ['2', '5', '8', '0']) {
      await tester.tap(find.text(d));
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 200));
    expect(pin, '2580');
  });

  testWidgets('PinPad delete removes the last digit', (tester) async {
    String? pin;
    await tester.pumpWidget(wrap(PinPad(onCompleted: (p) => pin = p)));
    await tester.tap(find.text('1'));
    await tester.tap(find.text('2'));
    await tester.tap(find.bySemanticsLabel('Delete'));
    for (final d in ['3', '4', '5']) {
      await tester.tap(find.text(d));
    }
    await tester.pump(const Duration(milliseconds: 200));
    expect(pin, '1345');
  });

  testWidgets('MoneyText hides amounts when privacy mode is on', (tester) async {
    const m = Money(amountMinor: 150050, currency: 'KES', amount: '1500.50');
    await tester.pumpWidget(wrap(const Column(children: [MoneyText(m), MoneyText(m, hidden: true), MoneyText(m, signed: 'DEBIT')])));
    expect(find.text('KSh 1,500.50'), findsOneWidget);
    expect(find.text('KSh ••••'), findsOneWidget);
    expect(find.text('−KSh 1,500.50'), findsOneWidget);
  });

  testWidgets('StatusChip labels provider states', (tester) async {
    await tester.pumpWidget(wrap(const Row(children: [StatusChip('PROCESSING'), StatusChip('SUCCESSFUL'), StatusChip('FAILED')])));
    expect(find.text('Confirming'), findsOneWidget);
    expect(find.text('Successful'), findsOneWidget);
    expect(find.text('Failed'), findsOneWidget);
  });

  test('PhoneField validates and normalises Kenyan numbers', () {
    expect(PhoneField.validate('0712345678'), isNull);
    expect(PhoneField.validate('712 345 678'), isNull);
    expect(PhoneField.validate('254112345678'), isNull);
    expect(PhoneField.validate('0812345678'), isNotNull);
    expect(PhoneField.validate('12345'), isNotNull);
    expect(PhoneField.toE164('0712 345 678'), '+254712345678');
    expect(PhoneField.toE164('254712345678'), '+254712345678');
  });

  test('new password policy matches the server', () {
    expect(validateNewPassword('short1'), isNotNull);
    expect(validateNewPassword('allletters'), isNotNull);
    expect(validateNewPassword('Str0ngPass'), isNull);
  });

  testWidgets('dark theme renders shared components without errors', (tester) async {
    await tester.pumpWidget(ProviderScope(child: MaterialApp(theme: PesaTheme.dark(), home: const Scaffold(body: EmptyState(icon: Icons.inbox, title: 'Empty', message: 'Nothing yet')))));
    expect(find.text('Empty'), findsOneWidget);
  });
}
