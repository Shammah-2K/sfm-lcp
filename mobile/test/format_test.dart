import 'package:flutter_test/flutter_test.dart';
import 'package:sfm_lcp/core/format/money.dart';
import 'package:sfm_lcp/ui/widgets/amount_entry.dart';

void main() {
  group('formatKwacha', () {
    test('two decimals and thousands separators', () {
      expect(formatKwacha(2500), 'K25.00');
      expect(formatKwacha(2550), 'K25.50');
      expect(formatKwacha(1), 'K0.01');
      expect(formatKwacha(100000050), 'K1,000,000.50');
    });

    test('negative amounts use a true minus sign', () {
      expect(formatKwacha(-251500), '−K2,515.00');
    });

    test('signed amounts', () {
      expect(formatSignedKwacha(5000, moneyIn: true), '+K50.00');
      expect(formatSignedKwacha(2500, moneyIn: false), '−K25.00');
    });
  });

  group('parseTypedNgwee', () {
    const valid = {
      '25': 2500,
      '25.5': 2550,
      '25.50': 2550,
      '0.01': 1,
      '.5': 50,
      '25.': 2500,
      '007': 700,
    };
    valid.forEach((text, ngwee) {
      test(
        '"$text" is $ngwee ngwee',
        () => expect(parseTypedNgwee(text), ngwee),
      );
    });

    for (final text in ['', '.', '0', '0.00', '25.505', '1.2.3', 'abc', '-5']) {
      test('"$text" is rejected', () => expect(parseTypedNgwee(text), isNull));
    }
  });

  group('AmountKeypad.press keeps the text well-formed', () {
    String type(String keys) => keys.split('').fold('', AmountKeypad.press);

    test('one decimal point, two decimals at most', () {
      expect(type('25..5'), '25.5');
      expect(type('1.234'), '1.23');
    });

    test('a leading point becomes 0.', () => expect(type('.5'), '0.5'));

    test('a leading zero is replaced', () => expect(type('07'), '7'));

    test(
      'at most seven whole-kwacha digits',
      () => expect(type('123456789'), '1234567'),
    );

    test('backspace removes one character', () {
      expect(AmountKeypad.press('25', AmountKeypad.backspace), '2');
      expect(AmountKeypad.press('', AmountKeypad.backspace), '');
    });
  });
}
