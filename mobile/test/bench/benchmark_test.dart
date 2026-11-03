// The benchmark's own rules. These run on the PC and check the harness, not
// the phone: the numbers it prints here are not measurements of anything.
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sfm_lcp/bench/bench_texts.dart';
import 'package:sfm_lcp/bench/benchmark.dart';
import 'package:sfm_lcp/data/ledger_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('nearest-rank percentiles', () {
    test('p50 and p95 of 1..100 are 50 and 95', () {
      final sorted = [for (var i = 1; i <= 100; i++) i];
      expect(nearestRank(sorted, 50), 50);
      expect(nearestRank(sorted, 95), 95);
    });

    test('every reported value is one that was measured', () {
      final stats = LatencyStats.of([30, 10, 20]);
      expect(stats.p50, 20);
      expect(stats.p95, 30);
      expect(stats.max, 30);
      expect(stats.mean, 20);
      expect(stats.n, 3);
    });

    test('a single measurement is every percentile', () {
      final stats = LatencyStats.of([7]);
      expect([stats.p50, stats.p95, stats.max], [7, 7, 7]);
    });

    test('no measurements is an error, not a zero', () {
      expect(() => LatencyStats.of([]), throwsArgumentError);
    });
  });

  group('inputs', () {
    test('the descriptions are the 300 held-out parity cases', () {
      expect(benchTexts, hasLength(300));
    });

    test('the history covers the ledger window and is the same every run', () {
      final a = benchHistory();
      final b = benchHistory();
      expect(a.length, b.length);
      expect(
        [for (final h in a) h.amountNgwee],
        [for (final h in b) h.amountNgwee],
      );
      final oldest = a
          .map((h) => h.occurredAtMs)
          .reduce((x, y) => x < y ? x : y);
      expect(
        benchNowMs - oldest,
        lessThanOrEqualTo(LedgerRepository.historyWindow.inMilliseconds),
      );
      expect(a.every((h) => h.occurredAtMs < benchNowMs), isTrue);
    });
  });

  test('a run measures both bundled models and prints one line each', () async {
    final results = await runBenchmark(rootBundle, warmup: 2, iterations: 20);
    expect([for (final r in results) r.model], ['categoriser', 'detector']);
    for (final r in results) {
      expect(r.latency.n, 20);
      expect(r.modelBytes, greaterThan(0));
      expect(r.modelVersion, isNotEmpty);
      final line = benchLine(r);
      expect(line, startsWith('$benchTag {'));
      final json =
          jsonDecode(line.substring(benchTag.length + 1))
              as Map<String, dynamic>;
      expect(json.keys, containsAll(['model', 'p50_us', 'p95_us', 'load_ms']));
      expect(json['build_mode'], 'debug');
    }
  });
}
