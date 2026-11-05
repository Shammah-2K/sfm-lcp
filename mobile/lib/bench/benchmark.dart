/// The on-device benchmark (NFR1, NFR2): how long each bundled model takes to
/// load, how long one prediction takes, how big the model is and how much
/// memory loading it costs, measured on the phone in a release build.
///
/// Run from the PC with `bench/run_bench.py`, which builds `bench_main.dart`,
/// starts it on the phone and collects the lines printed by [benchLine] into
/// `bench/results.csv`. Nothing here invents a number: every field is measured
/// in the run that prints it.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../app/view_data.dart';
import '../data/ledger_repository.dart';
import '../domain/codebook.dart';
import '../domain/isolation_forest_detector.dart';
import '../domain/models.dart';
import '../domain/tfidf_categoriser.dart';
import 'bench_texts.dart';

/// Marks the benchmark's lines in logcat; `bench/run_bench.py` reads them.
const String benchTag = 'SFMBENCH';

/// Printed after the last result, so the runner knows the run is complete.
const String benchDone = 'SFMBENCH_DONE';

/// The line printed for one result.
String benchLine(ModelBench result) =>
    '$benchTag ${jsonEncode(result.toJson())}';

/// Latency summary over [n] timed calls, in microseconds.
///
/// Percentiles use the nearest-rank method: p is the smallest measured value
/// with at least p% of the measurements at or below it. Nothing is
/// interpolated, so every reported value was observed.
class LatencyStats {
  const LatencyStats({
    required this.n,
    required this.p50,
    required this.p95,
    required this.max,
    required this.mean,
  });

  factory LatencyStats.of(List<int> micros) {
    if (micros.isEmpty) throw ArgumentError('no measurements');
    final sorted = [...micros]..sort();
    final total = sorted.fold<int>(0, (a, b) => a + b);
    return LatencyStats(
      n: sorted.length,
      p50: nearestRank(sorted, 50),
      p95: nearestRank(sorted, 95),
      max: sorted.last,
      mean: total / sorted.length,
    );
  }

  final int n;
  final int p50;
  final int p95;
  final int max;
  final double mean;
}

/// The nearest-rank [percent]-th percentile of an ascending list.
int nearestRank(List<int> sorted, int percent) {
  final rank = (percent / 100 * sorted.length).ceil();
  return sorted[math.max(rank, 1) - 1];
}

/// One model's measurements from one run.
class ModelBench {
  const ModelBench({
    required this.model,
    required this.modelVersion,
    required this.modelBytes,
    required this.loadMs,
    required this.rssBeforeLoadBytes,
    required this.rssAfterLoadBytes,
    required this.firstCallMicros,
    required this.warmup,
    required this.latency,
    required this.inputs,
    required this.buildMode,
  });

  /// `categoriser` or `detector`.
  final String model;
  final String modelVersion;

  /// Size of the bundled model file.
  final int modelBytes;

  /// Asset read plus parse, as at app start.
  final double loadMs;

  /// Resident memory of the whole app just before and just after loading.
  final int rssBeforeLoadBytes;
  final int rssAfterLoadBytes;

  /// The first prediction after loading, before any warm-up.
  final int firstCallMicros;

  /// Untimed calls made before the timed ones.
  final int warmup;
  final LatencyStats latency;

  /// What was predicted on: number of descriptions (categoriser) or history
  /// entries per prediction (detector).
  final int inputs;

  /// `release`, `profile` or `debug`. Only release rows are evidence.
  final String buildMode;

  Map<String, Object> toJson() => {
    'model': model,
    'model_version': modelVersion,
    'model_bytes': modelBytes,
    'load_ms': double.parse(loadMs.toStringAsFixed(3)),
    'rss_before_load_bytes': rssBeforeLoadBytes,
    'rss_after_load_bytes': rssAfterLoadBytes,
    'first_call_us': firstCallMicros,
    'warmup': warmup,
    'n': latency.n,
    'p50_us': latency.p50,
    'p95_us': latency.p95,
    'max_us': latency.max,
    'mean_us': double.parse(latency.mean.toStringAsFixed(2)),
    'inputs': inputs,
    'build_mode': buildMode,
  };
}

String get currentBuildMode => kReleaseMode
    ? 'release'
    : kProfileMode
    ? 'profile'
    : 'debug';

/// Measures both bundled models, categoriser first. [iterations] timed calls
/// each, after [warmup] untimed ones.
Future<List<ModelBench>> runBenchmark(
  AssetBundle bundle, {
  int warmup = 100,
  int iterations = 1000,
}) async => [
  await benchCategoriser(bundle, warmup: warmup, iterations: iterations),
  await benchDetector(bundle, warmup: warmup, iterations: iterations),
];

/// The categoriser, timed through [TfidfCategoriser.suggest] as the entry
/// screen calls it, cycling through the held-out [benchTexts].
Future<ModelBench> benchCategoriser(
  AssetBundle bundle, {
  required int warmup,
  required int iterations,
}) async {
  final rssBefore = ProcessInfo.currentRss;
  final load = Stopwatch()..start();
  final model = await TfidfCategoriser.load(bundle);
  load.stop();
  final rssAfter = ProcessInfo.currentRss;

  // Each description is asked about as the kind its most likely category
  // belongs to, as a user would have chosen Sale or Expense first. Untimed.
  final cases = [
    for (final text in benchTexts) (text, _likelyKind(model, text)),
  ];

  Future<int> timeOne(int i) async {
    final (text, kind) = cases[i % cases.length];
    final sw = Stopwatch()..start();
    await model.suggest(text, kind);
    sw.stop();
    return sw.elapsedMicroseconds;
  }

  final first = await timeOne(0);
  for (var i = 0; i < warmup; i++) {
    await timeOne(i);
  }
  final micros = [for (var i = 0; i < iterations; i++) await timeOne(i)];

  return ModelBench(
    model: 'categoriser',
    modelVersion: model.modelVersion,
    modelBytes: (await bundle.load(categoriserAsset)).lengthInBytes,
    loadMs: load.elapsedMicroseconds / 1000,
    rssBeforeLoadBytes: rssBefore,
    rssAfterLoadBytes: rssAfter,
    firstCallMicros: first,
    warmup: warmup,
    latency: LatencyStats.of(micros),
    inputs: cases.length,
    buildMode: currentBuildMode,
  );
}

EntryType _likelyKind(TfidfCategoriser model, String text) {
  final p = model.probabilitiesUnrestricted(text);
  var best = 0;
  for (var c = 1; c < p.length; c++) {
    if (p[c] > p[best]) best = c;
  }
  final code = model.classes[best];
  return codebook.firstWhere((k) => k.code == code).type;
}

/// The detector, timed through [IsolationForestDetector.score] as the ledger
/// calls it: each new entry is scored against the whole of one trader's
/// recent history ([benchHistory]), which the detector filters itself. The
/// database query that fetches the history in the app is not included.
Future<ModelBench> benchDetector(
  AssetBundle bundle, {
  required int warmup,
  required int iterations,
}) async {
  final rssBefore = ProcessInfo.currentRss;
  final load = Stopwatch()..start();
  final model = await IsolationForestDetector.load(bundle);
  load.stop();
  final rssAfter = ProcessInfo.currentRss;

  final history = benchHistory();
  final candidates = benchCandidates(count: 200);

  Future<int> timeOne(int i) async {
    final sw = Stopwatch()..start();
    final result = await model.score(
      candidates[i % candidates.length],
      history,
    );
    sw.stop();
    if (result == null) throw StateError('benchmark entry got no score');
    return sw.elapsedMicroseconds;
  }

  final first = await timeOne(0);
  for (var i = 0; i < warmup; i++) {
    await timeOne(i);
  }
  final micros = [for (var i = 0; i < iterations; i++) await timeOne(i)];

  return ModelBench(
    model: 'detector',
    modelVersion: model.modelVersion,
    modelBytes: (await bundle.load(detectorAsset)).lengthInBytes,
    loadMs: load.elapsedMicroseconds / 1000,
    rssBeforeLoadBytes: rssBefore,
    rssAfterLoadBytes: rssAfter,
    firstCallMicros: first,
    warmup: warmup,
    latency: LatencyStats.of(micros),
    inputs: history.length,
    buildMode: currentBuildMode,
  );
}

/// The moment the benchmark's entries are made: 1 Nov 2026, 12:00 in Lusaka.
final int benchNowMs = DateTime.utc(2026, 11, 1, 10).millisecondsSinceEpoch;

/// The categories the benchmark trader uses, with a usual amount in ngwee and
/// entries per day. A load figure for the benchmark only, not a claim about
/// real traders: it sets how much history each prediction has to look through.
const List<(EntryType, String, int, int)> benchTrader = [
  (EntryType.sale, 'sales_goods', 2500, 12),
  (EntryType.sale, 'sales_service', 5000, 2),
  (EntryType.expense, 'stock', 40000, 1),
  (EntryType.expense, 'transport', 1500, 2),
  (EntryType.expense, 'airtime', 1000, 1),
  (EntryType.expense, 'food', 2000, 1),
];

/// One trader's entries over the ledger's whole history window
/// ([LedgerRepository.historyWindow]) before [benchNowMs]. Deterministic.
List<HistoryItem> benchHistory() {
  final random = math.Random(42);
  final days = LedgerRepository.historyWindow.inDays;
  const dayMs = Duration.millisecondsPerDay;
  return [
    for (var d = 1; d <= days; d++)
      for (final (type, code, usual, perDay) in benchTrader)
        for (var k = 0; k < perDay; k++)
          HistoryItem(
            type: type,
            amountNgwee: _near(usual, random),
            categoryCode: code,
            occurredAtMs: benchNowMs - d * dayMs + random.nextInt(dayMs),
          ),
  ];
}

/// New entries to score, one category after another, about one in ten typed
/// with an extra zero so both outcomes are exercised. Deterministic.
List<EntryCandidate> benchCandidates({required int count}) {
  final random = math.Random(7);
  return [
    for (var i = 0; i < count; i++)
      () {
        final (type, code, usual, _) = benchTrader[i % benchTrader.length];
        final amount = _near(usual, random);
        return EntryCandidate(
          type: type,
          amountNgwee: i % 10 == 9 ? amount * 10 : amount,
          categoryCode: code,
          occurredAtMs: benchNowMs,
        );
      }(),
  ];
}

/// [usual] scaled by a factor between 0.6 and 1.6, rounded to 50 ngwee.
int _near(int usual, math.Random random) {
  final scaled = usual * (0.6 + random.nextDouble());
  return math.max(50, (scaled / 50).round() * 50);
}
