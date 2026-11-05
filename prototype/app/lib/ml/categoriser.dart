import 'dart:convert';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart';

import '../domain/categories.dart';

/// JSON numbers arrive as int or double; the model needs doubles.
double _asDouble(Object? value) => switch (value) {
  final double d => d,
  final int i => i + 0.0,
  _ => throw FormatException('expected a number', value),
};

const String categoriserAsset = 'assets/models/categoriser_model.json';

class ScoredCategory {
  const ScoredCategory(this.code, this.probability);

  final String code;
  final double probability;
}

class Suggestion {
  const Suggestion({
    required this.categoryCode,
    required this.confidence,
    required this.top3,
    required this.modelVersion,
    required this.preselect,
    required this.elapsedMicros,
  });

  final String categoryCode;
  final double confidence;
  final List<ScoredCategory> top3;
  final String modelVersion;

  /// True when [confidence] reaches the model's cutoff, so the UI selects the category for the user.
  final bool preselect;
  final int elapsedMicros;
}

/// TF-IDF (char_wb 2–4) + multinomial logistic regression, reproducing scikit-learn's
/// `predict_proba` from the exported JSON. Pure Dart, no ML packages.
class Categoriser {
  Categoriser._({
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
       _intercept = intercept;

  factory Categoriser.fromJson(Map<String, dynamic> json) {
    if (json['analyzer'] != 'char_wb' ||
        json['norm'] != 'l2' ||
        json['lowercase'] != true) {
      throw FormatException(
        'unsupported categoriser model configuration',
        json['model_version'],
      );
    }
    Float64List floats(Object? list) => Float64List.fromList(
      (list! as List<dynamic>).map((v) => _asDouble(v)).toList(),
    );
    return Categoriser._(
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

  /// Parses the bundled model off the UI isolate; the JSON is about 1 MB.
  static Future<Categoriser> load(AssetBundle bundle) async {
    final source = await bundle.loadString(categoriserAsset);
    return Isolate.run(
      () => Categoriser.fromJson(jsonDecode(source) as Map<String, dynamic>),
    );
  }

  final String modelVersion;
  final List<String> classes;
  final double confidenceCutoff;
  final int _ngramMin;
  final int _ngramMax;
  final bool _sublinearTf;
  final Map<String, int> _vocabulary;
  final Float64List _idf;
  final List<Float64List> _coef;
  final Float64List _intercept;

  static final RegExp _whitespace = RegExp(r'\s+');
  static const int _space = 0x20;

  /// scikit-learn's `char_wb` analyzer. Works on Unicode code points, as Python strings do.
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
  Map<int, double> vectorise(String text) {
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

  /// Probabilities over the classes whose index is in [allowed] (all classes when null),
  /// aligned with [classes]; excluded classes get 0.
  List<double> _probabilities(String text, {Set<int>? allowed}) {
    final x = vectorise(text);
    final logits = List<double>.filled(classes.length, double.negativeInfinity);
    var maxLogit = double.negativeInfinity;
    for (var c = 0; c < classes.length; c++) {
      if (allowed != null && !allowed.contains(c)) continue;
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

  /// Probabilities over every class with no kind restriction, aligned with [classes].
  /// Used by the parity test against scikit-learn's `predict_proba`.
  List<double> suggestUnrestricted(String description) =>
      _probabilities(description);

  /// Suggests a category of [kind] for [description], or null when the description is blank.
  Suggestion? suggest(String description, CategoryKind kind) {
    if (description.trim().isEmpty) return null;
    final stopwatch = Stopwatch()..start();
    final allowed = <int>{
      for (var c = 0; c < classes.length; c++)
        if (categoryByCode[classes[c]]?.kind == kind) c,
    };
    final probs = _probabilities(description, allowed: allowed);
    final ranked = allowed.toList()
      ..sort((a, b) => probs[b].compareTo(probs[a]));
    final top3 = [
      for (final c in ranked.take(3)) ScoredCategory(classes[c], probs[c]),
    ];
    stopwatch.stop();
    return Suggestion(
      categoryCode: top3.first.code,
      confidence: top3.first.probability,
      top3: top3,
      modelVersion: modelVersion,
      preselect: top3.first.probability >= confidenceCutoff,
      elapsedMicros: stopwatch.elapsedMicroseconds,
    );
  }
}
