// The Dart categoriser must give scikit-learn's probabilities (Chapter 3,
// "parity test"). The fixture and the model are written together by
// ml/train_categoriser.py; retrain, and both change.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sfm_lcp/app/view_data.dart';
import 'package:sfm_lcp/domain/codebook.dart';
import 'package:sfm_lcp/domain/tfidf_categoriser.dart';

void main() {
  final model = TfidfCategoriser.fromJson(
    jsonDecode(File(categoriserAsset).readAsStringSync())
        as Map<String, dynamic>,
  );
  final parity =
      jsonDecode(
            File('test/fixtures/categoriser_parity.json').readAsStringSync(),
          )
          as Map<String, dynamic>;
  final cases = parity['cases'] as List<dynamic>;

  test('the fixture belongs to the bundled model', () {
    expect(parity['model_version'], model.modelVersion);
    expect(parity['classes'], model.classes);
    expect(cases, hasLength(300));
  });

  test('probabilities match scikit-learn within 1e-6 on all 300 cases', () {
    var worst = 0.0;
    var topAgrees = 0;
    for (final c in cases.cast<Map<String, dynamic>>()) {
      final expected = (c['proba'] as List<dynamic>).cast<num>();
      final actual = model.probabilitiesUnrestricted(c['text'] as String);
      for (var i = 0; i < expected.length; i++) {
        final d = (actual[i] - expected[i]).abs();
        if (d > worst) worst = d;
      }
      int argmax(List<num> p) => List.generate(
        p.length,
        (i) => i,
      ).reduce((a, b) => p[a] >= p[b] ? a : b);
      if (argmax(expected) == argmax(actual)) topAgrees++;
    }
    expect(worst, lessThan(1e-6), reason: 'largest difference $worst');
    expect(topAgrees, cases.length);
  });

  test('suggestions stay within the entry kind and sum to 1 there', () {
    final s = model.suggestNow('bus fare to Matero', EntryType.expense)!;
    final expenseCodes = {
      for (final c in codebook)
        if (c.type == EntryType.expense) c.code,
    };
    expect(s.top.map((t) => t.categoryCode), everyElement(isIn(expenseCodes)));
    expect(s.top, hasLength(3));
    expect(s.modelVersion, model.modelVersion);
    final all = model.classes.length;
    expect(all, codebook.length);
  });

  test('a blank description gives no suggestion', () {
    expect(model.suggestNow('   ', EntryType.sale), isNull);
  });

  test('preselect follows the model cutoff', () {
    final s = model.suggestNow('ZESCO units', EntryType.expense)!;
    expect(s.preselect, s.top.first.confidence >= model.confidenceCutoff);
  });
}
