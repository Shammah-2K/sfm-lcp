import 'dart:convert';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart';

import '../app/ports.dart';
import '../app/view_data.dart';
import 'codebook.dart';

/// The bundled model, written by `ml/train_categoriser.py`.
const String categoriserAsset = 'assets/models/categoriser.json';

/// JSON numbers arrive as int or double; the model needs doubles.
double _asDouble(Object? value) => switch (value) {
  final double d => d,
  final int i => i + 0.0,
  _ => throw FormatException('expected a number', value),
};

/// The on-device categoriser (FR3, Chapter 3 Models): TF-IDF over character
/// n-grams (scikit-learn's `char_wb`, 2–4) and multinomial logistic
/// regression, reproducing scikit-learn's `predict_proba` from the exported
/// JSON. Pure Dart, no ML packages; ported from the prototype, whose parity
/// test it keeps (`test/domain/categoriser_parity_test.dart`).
///
/// [suggest] restricts the answer to the entry's kind: the user has already
/// chosen Sale or Expense, so the other kind's classes are dropped before the
/// softmax.
class TfidfCategoriser implements CategoryPort {
  TfidfCategoriser._({
    required this.modelVersion,
    required this.classes,
    required this.confidenceCutoff,
    required int ngramMin,
    required int ngramMax,
    required bool sublinearTf,
    required Map<String, int> vocabulary,
    required Float64List idf,
    required List<Float64List> coef,
    required Float64List intercept,
  }) : _ngramMin = ngramMin,
       _ngramMax = ngramMax,
       _sublinearTf = sublinearTf,
       _vocabulary = vocabulary,
       _idf = idf,
       _coef = coef,
       _intercept = intercept,
       _kindOf = [
         for (final c in classes)
           codebook.where((k) => k.code == c).firstOrNull?.type,
       ];

  factory TfidfCategoriser.fromJson(Map<String, dynamic> json) {
    if (json['analyzer'] != 'char_wb' ||
        json['norm'] != 'l2' ||
        json['lowercase'] != true) {
      throw FormatException(
        'unsupported categoriser model configuration',
        json['model_version'],
      );
    }
    Float64List floats(Object? list) =>
        Float64List.fromList((list! as List<dynamic>).map(_asDouble).toList());
    return TfidfCategoriser._(
      modelVersion: json['model_version'] as String,
      classes: List<String>.unmodifiable(json['classes'] as List<dynamic>),
      confidenceCutoff: _asDouble(json['confidence_cutoff']),
      ngramMin: json['ngram_min'] as int,
      ngramMax: json['ngram_max'] as int,
      sublinearTf: json['sublinear_tf'] as bool,
      vocabulary: (json['vocabulary'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, v as int),
      ),
      idf: floats(json['idf']),
      coef: [for (final row in json['coef'] as List<dynamic>) floats(row)],
      intercept: floats(json['intercept']),
    );
  }

  /// Parses the bundled model off the UI isolate (about 1.5 MB of JSON).
  static Future<TfidfCategoriser> load(AssetBundle bundle) async {
    final source = await bundle.loadString(categoriserAsset);
    return Isolate.run(
      () =>
          TfidfCategoriser.fromJson(jsonDecode(source) as Map<String, dynamic>),
    );
  }

  /// Stored in `ledger_entry.model_version` beside each prediction.
  final String modelVersion;
  final List<String> classes;

  /// At or above this, the UI selects the top category for the user.
  final double confidenceCutoff;

  final int _ngramMin;
  final int _ngramMax;
  final bool _sublinearTf;
  final Map<String, int> _vocabulary;
  final Float64List _idf;
  final List<Float64List> _coef;
  final Float64List _intercept;
  final List<EntryType?> _kindOf;

  /// Time taken by the last [suggest], for researcher mode and the benchmark.
  int lastElapsedMicros = 0;

  static final RegExp _whitespace = RegExp(r'\s+');
  static const int _space = 0x20;

  /// scikit-learn's `char_wb` analyzer, on Unicode code points as Python does:
  /// lowercase; collapse whitespace; pad each word with one space; for each n,
  /// a padded word no longer than n is emitted once and longer n are skipped.
  List<String> analyze(String text) {
    final normalised = text.toLowerCase().replaceAll(_whitespace, ' ');
    final grams = <String>[];
    for (final word in normalised.split(' ')) {
      if (word.isEmpty) continue;
      final padded = [_space, ...word.runes, _space];
      for (var n = _ngramMin; n <= _ngramMax; n++) {
        if (padded.length <= n) {
          grams.add(String.fromCharCodes(padded));
          break;
        }
        for (var i = 0; i <= padded.length - n; i++) {
          grams.add(String.fromCharCodes(padded, i, i + n));
        }
      }
    }
    return grams;
  }

  /// Sparse L2-normalised TF-IDF vector: feature index -> weight.
  Map<int, double> _vectorise(String text) {
    final counts = <int, int>{};
    for (final gram in analyze(text)) {
      final index = _vocabulary[gram];
      if (index != null) counts[index] = (counts[index] ?? 0) + 1;
    }
    final weights = <int, double>{};
    var sumSquares = 0.0;
    counts.forEach((index, count) {
      final tf = _sublinearTf ? 1 + math.log(count) : count + 0.0;
      final w = tf * _idf[index];
      weights[index] = w;
      sumSquares += w * w;
    });
    if (sumSquares > 0) {
      final norm = math.sqrt(sumSquares);
      weights.updateAll((_, w) => w / norm);
    }
    return weights;
  }

  /// Softmax over the classes allowed by [allowed] (all when null), aligned
  /// with [classes]; the others get 0.
  List<double> _probabilities(String text, {bool Function(int)? allowed}) {
    final x = _vectorise(text);
    final logits = List<double>.filled(classes.length, double.negativeInfinity);
    var maxLogit = double.negativeInfinity;
    for (var c = 0; c < classes.length; c++) {
      if (allowed != null && !allowed(c)) continue;
      final row = _coef[c];
      var z = _intercept[c];
      x.forEach((i, w) => z += row[i] * w);
      logits[c] = z;
      if (z > maxLogit) maxLogit = z;
    }
    var total = 0.0;
    final probs = List<double>.filled(classes.length, 0);
    for (var c = 0; c < classes.length; c++) {
      if (logits[c] == double.negativeInfinity) continue;
      probs[c] = math.exp(logits[c] - maxLogit);
      total += probs[c];
    }
    for (var c = 0; c < classes.length; c++) {
      probs[c] /= total;
    }
    return probs;
  }

  /// Every class, no kind restriction: for the parity test against
  /// scikit-learn's `predict_proba`.
  List<double> probabilitiesUnrestricted(String description) =>
      _probabilities(description);

  @override
  Future<Suggestion?> suggest(String description, EntryType type) async =>
      suggestNow(description, type);

  /// Synchronous [suggest], for the benchmark.
  Suggestion? suggestNow(String description, EntryType type) {
    if (description.trim().isEmpty) return null;
    final stopwatch = Stopwatch()..start();
    final probs = _probabilities(
      description,
      allowed: (c) => _kindOf[c] == type,
    );
    final ranked = [
      for (var c = 0; c < classes.length; c++)
        if (_kindOf[c] == type) c,
    ]..sort((a, b) => probs[b].compareTo(probs[a]));
    stopwatch.stop();
    lastElapsedMicros = stopwatch.elapsedMicroseconds;
    if (ranked.isEmpty) return null;
    final top = [
      for (final c in ranked.take(3)) ScoredCategory(classes[c], probs[c]),
    ];
    return Suggestion(
      top: top,
      preselect: top.first.confidence >= confidenceCutoff,
      modelVersion: modelVersion,
      elapsedMicros: lastElapsedMicros,
    );
  }
}
