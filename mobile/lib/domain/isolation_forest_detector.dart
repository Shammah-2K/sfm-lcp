import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart';

import 'models.dart';

/// The bundled model, written by `ml/train_detector.py`.
const String detectorAsset = 'assets/models/detector.json';

/// The on-device anomaly detector (FR4, Chapter 3: Isolation Forest).
///
/// An entry is compared with the same business's earlier entries of the same
/// type and category (the features in `ml/anomaly_features.py`): how many times
/// bigger or smaller than usual it is, on a log scale, and that distance in units
/// of the trader's usual spread. The forest's score is between 0 and 1, higher
/// is more unusual, and is stored in `ledger_entry.anomaly_score`; at or above
/// the trained threshold the entry is flagged for "Is this right?".
///
/// With fewer than `min_history` earlier entries in the category there is no
/// opinion (null), so a new trader is never nagged. The parity test
/// (`test/domain/detector_parity_test.dart`) checks features and scores against
/// Python.
class IsolationForestDetector implements AnomalyDetector {
  IsolationForestDetector._({
    required this.modelVersion,
    required this.threshold,
    required int minHistory,
    required int historyDays,
    required int maxSamples,
    required List<_Tree> trees,
  }) : _minHistory = minHistory,
       _historyMs = historyDays * Duration.millisecondsPerDay,
       _trees = trees,
       _cMax = _averagePathLength(maxSamples.toDouble());

  factory IsolationForestDetector.fromJson(Map<String, dynamic> json) {
    if ((json['features'] as List<dynamic>).join(',') != 'log_ratio,robust_z') {
      throw FormatException('unsupported detector features', json['features']);
    }
    return IsolationForestDetector._(
      modelVersion: json['model_version'] as String,
      threshold: (json['threshold'] as num).toDouble(),
      minHistory: json['min_history'] as int,
      historyDays: json['history_days'] as int,
      maxSamples: json['max_samples'] as int,
      trees: [
        for (final t in json['trees'] as List<dynamic>)
          _Tree.fromJson(t as Map<String, dynamic>),
      ],
    );
  }

  static Future<IsolationForestDetector> load(AssetBundle bundle) async =>
      IsolationForestDetector.fromJson(
        jsonDecode(await bundle.loadString(detectorAsset))
            as Map<String, dynamic>,
      );

  final String modelVersion;

  /// Score at or above which an entry is flagged.
  final double threshold;

  final int _minHistory;
  final int _historyMs;
  final List<_Tree> _trees;
  final double _cMax;

  /// Time taken by the last [score], for researcher mode and the benchmark.
  int lastElapsedMicros = 0;

  static const int _typicalMinHistory = 3;
  static const double _madScale = 1.4826;
  static const double _spreadFloor = 0.05;
  static const double _eulerGamma = 0.5772156649015329;

  @override
  Future<AnomalyResult?> score(
    EntryCandidate entry,
    List<HistoryItem> history,
  ) async {
    final stopwatch = Stopwatch()..start();
    final from = entry.occurredAtMs - _historyMs;
    final amounts = [
      for (final h in history)
        if (h.type == entry.type &&
            h.categoryCode == entry.categoryCode &&
            h.occurredAtMs >= from &&
            h.occurredAtMs < entry.occurredAtMs)
          h.amountNgwee,
    ];
    final x = features(entry.amountNgwee, amounts);
    if (x == null) return null;
    final s = scoreFeatures(x);
    stopwatch.stop();
    lastElapsedMicros = stopwatch.elapsedMicroseconds;
    return AnomalyResult(score: s, flagged: s >= threshold);
  }

  /// The median of this category's history: "Usually about K…".
  @override
  int? typicalNgwee(String categoryCode, List<HistoryItem> history) {
    final amounts = [
      for (final h in history)
        if (h.categoryCode == categoryCode) h.amountNgwee.toDouble(),
    ];
    if (amounts.length < _typicalMinHistory) return null;
    return _median(amounts).round();
  }

  /// `ml/anomaly_features.py`'s features: [log_ratio, robust_z], or null with
  /// too little history.
  List<double>? features(int amountNgwee, List<int> historyNgwee) {
    if (historyNgwee.length < _minHistory) return null;
    final logs = [for (final h in historyNgwee) math.log(h)];
    final centre = _median(logs);
    final mad = _median([for (final v in logs) (v - centre).abs()]);
    final logRatio = math.log(amountNgwee) - centre;
    return [logRatio, logRatio / (_madScale * mad + _spreadFloor)];
  }

  /// scikit-learn's `-score_samples`: 2^(-mean path length / c(max_samples)).
  /// Like scikit-learn's trees, compares feature values as float32.
  double scoreFeatures(List<double> x) {
    final x32 = Float32List.fromList(x);
    var total = 0.0;
    for (final t in _trees) {
      var node = 0;
      var depth = 0;
      while (t.left[node] != -1) {
        node = x32[t.feature[node]] <= t.threshold[node]
            ? t.left[node]
            : t.right[node];
        depth++;
      }
      total += depth + _averagePathLength(t.nSamples[node].toDouble());
    }
    return math.pow(2.0, -(total / _trees.length) / _cMax).toDouble();
  }

  static double _median(List<double> values) {
    final s = [...values]..sort();
    final mid = s.length ~/ 2;
    return s.length.isOdd ? s[mid] : (s[mid - 1] + s[mid]) / 2.0;
  }

  /// c(n): the average path length of an unsuccessful search among n points.
  static double _averagePathLength(double n) {
    if (n <= 1) return 0;
    if (n <= 2) return 1;
    return 2.0 * (math.log(n - 1.0) + _eulerGamma) - 2.0 * (n - 1.0) / n;
  }
}

class _Tree {
  _Tree({
    required this.left,
    required this.right,
    required this.feature,
    required this.threshold,
    required this.nSamples,
  });

  factory _Tree.fromJson(Map<String, dynamic> j) {
    Int32List ints(String k) =>
        Int32List.fromList((j[k] as List<dynamic>).cast<int>());
    return _Tree(
      left: ints('left'),
      right: ints('right'),
      feature: ints('feature'),
      threshold: Float64List.fromList([
        for (final v in j['threshold'] as List<dynamic>) (v as num).toDouble(),
      ]),
      nSamples: ints('n_samples'),
    );
  }

  final Int32List left;
  final Int32List right;
  final Int32List feature;
  final Float64List threshold;
  final Int32List nSamples;
}
