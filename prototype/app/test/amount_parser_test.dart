import 'package:flutter_test/flutter_test.dart';
import 'package:sfm_lcp_prototype/domain/money.dart';

void main() {
  group('parseAmountNgwee accepts', () {
    const valid = {
      '25': 2500,
      '25.5': 2550,
      '25.50': 2550,
      '25.05': 2505,
      '0.01': 1,
      '.5': 50,
      '25.': 2500,
      '007': 700,
      '1000000': 100000000,
      '1000000.00': 100000000,
      ' 12.30 ': 1230,
    };
    valid.forEach((input, ngwee) {
      test(
        '"$input" as $ngwee ngwee',
        () => expect(parseAmountNgwee(input), ngwee),
      );
    });
  });

  group('parseAmountNgwee rejects', () {
    const invalid = [
      '',
      '.',
      '0',
      '0.00',
      '-5',
      '25.505',
      '1000000.01',
      '1000001',
      '99999999999999999999',
      '1.2.3',
      'abc',
      '25,00',
      'K25',
      '1e3',
    ];
    for (final input in invalid) {
      test('"$input"', () => expect(parseAmountNgwee(input), isNull));
    }
  });

  test(
    'formatNgwee writes kwacha with two decimals and thousands separators',
    () {
      expect(formatNgwee(2500), 'K25.00');
      expect(formatNgwee(2550), 'K25.50');
      expect(formatNgwee(1), 'K0.01');
      expect(formatNgwee(100000000), 'K1,000,000.00');
    },
  );
}
