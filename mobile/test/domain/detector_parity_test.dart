// The Dart detector must compute Python's features and scikit-learn's scores.
// The fixture and the model are written together by ml/train_detector.py.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sfm_lcp/app/view_data.dart';
import 'package:sfm_lcp/domain/isolation_forest_detector.dart';
import 'package:sfm_lcp/domain/models.dart';

void main() {
  final detector = IsolationForestDetector.fromJson(
    jsonDecode(File(detectorAsset).readAsStringSync()) as Map<String, dynamic>,
  );
  final parity =
      jsonDecode(File('test/fixtures/detector_parity.json').readAsStringSync())
          as Map<String, dynamic>;
  final cases = (parity['cases'] as List<dynamic>).cast<Map<String, dynamic>>();

  test('the fixture belongs to the bundled model', () {
    expect(parity['model_version'], detector.modelVersion);
    expect(cases.length, greaterThan(200));
  });

  test('features and scores match Python within 1e-12', () {
    var worst = 0.0;
    for (final c in cases) {
      final x = detector.features(
        c['amount'] as int,
        (c['history'] as List<dynamic>).cast<int>(),
      );
      if (c['features'] == null) {
        expect(x, isNull, reason: 'too little history: no opinion');
        continue;
      }
      final expected = (c['features'] as List<dynamic>).cast<num>();
      for (var i = 0; i < expected.length; i++) {
        worst = [
          worst,
          (x![i] - expected[i]).abs(),
        ].reduce((a, b) => a > b ? a : b);
      }
      final s = detector.scoreFeatures(x!);
      worst = [
        worst,
        (s - (c['score'] as num)).abs(),
      ].reduce((a, b) => a > b ? a : b);
    }
    expect(worst, lessThan(1e-12), reason: 'largest difference $worst');
  });

  List<HistoryItem> usual(int ngwee, int n, {String category = 'transport'}) =>
      [
        for (var i = 0; i < n; i++)
          HistoryItem(
            type: EntryType.expense,
            amountNgwee: ngwee + (i % 3) * 100,
            categoryCode: category,
            occurredAtMs: 1000 + i,
          ),
      ];

  EntryCandidate entry(int ngwee, {String category = 'transport'}) =>
      EntryCandidate(
        type: EntryType.expense,
        amountNgwee: ngwee,
        categoryCode: category,
        occurredAtMs: 100000,
      );

  test('an extra zero is flagged; the usual amount is not', () async {
    final history = usual(2500, 10);
    expect((await detector.score(entry(25000), history))!.flagged, isTrue);
    expect((await detector.score(entry(2600), history))!.flagged, isFalse);
  });

  test('other categories and too little history give no opinion', () async {
    expect(await detector.score(entry(25000), usual(2500, 4)), isNull);
    expect(
      await detector.score(entry(25000), usual(2500, 10, category: 'food')),
      isNull,
    );
  });

  test('"usually about" is the median of the category, from 3 entries', () {
    expect(detector.typicalNgwee('transport', usual(2500, 2)), isNull);
    expect(detector.typicalNgwee('transport', usual(2500, 3)), 2600);
  });
}
