import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sfm_lcp_prototype/domain/categories.dart';
import 'package:sfm_lcp_prototype/ml/categoriser.dart';

void main() {
  final categoriser = Categoriser.fromJson(
    jsonDecode(File(categoriserAsset).readAsStringSync())
        as Map<String, dynamic>,
  );
  final parity =
      jsonDecode(File('test/fixtures/parity_cases.json').readAsStringSync())
          as Map<String, dynamic>;
  final cases = (parity['cases'] as List<dynamic>).cast<Map<String, dynamic>>();

  test('fixture and model come from the same export', () {
    expect(parity['model_version'], categoriser.modelVersion);
    expect(parity['classes'], categoriser.classes);
    expect(cases, hasLength(300));
  });

  test(
    'Dart probabilities match scikit-learn predict_proba within 1e-6 on every case',
    () {
      var worst = 0.0;
      for (final c in cases) {
        final text = c['text'] as String;
        final expected = (c['proba'] as List<dynamic>).cast<num>();
        final actual = categoriser.suggestUnrestricted(text);
        for (var i = 0; i < expected.length; i++) {
          final diff = (actual[i] - expected[i]).abs();
          if (diff > worst) worst = diff;
          expect(
            diff,
            lessThanOrEqualTo(1e-6),
            reason: '${categoriser.classes[i]} for "$text"',
          );
        }
      }
      printOnFailure('largest absolute difference: $worst');
    },
  );

  test(
    'suggest restricts to the requested kind and returns null for blank text',
    () {
      final expense = categoriser.suggest(
        'bus fare to Matero',
        CategoryKind.expense,
      )!;
      expect(categoryByCode[expense.categoryCode]!.kind, CategoryKind.expense);
      expect(
        expense.top3.every(
          (s) => categoryByCode[s.code]!.kind == CategoryKind.expense,
        ),
        isTrue,
      );
      expect(
        expense.top3.fold<double>(0, (sum, s) => sum + s.probability),
        lessThanOrEqualTo(1 + 1e-9),
      );
      expect(
        expense.preselect,
        expense.confidence >= categoriser.confidenceCutoff,
      );

      final sale = categoriser.suggest(
        'bus fare to Matero',
        CategoryKind.income,
      )!;
      expect(categoryByCode[sale.categoryCode]!.kind, CategoryKind.income);

      expect(categoriser.suggest('   ', CategoryKind.expense), isNull);
    },
  );
}
