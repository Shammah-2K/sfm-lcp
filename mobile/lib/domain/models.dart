/// The two on-device models (Chapter 3, Structural Design). The ledger depends
/// on these interfaces, never on a concrete model, so the logistic-regression
/// categoriser or Isolation Forest can be swapped without touching the ledger.
///
/// Until the ML phase, the app uses [NoCategoriser] and [NoAnomalyDetector]:
/// no suggestions and no flags. The user then always picks the category
/// (FR3 falls back to manual), and no entry is ever marked unusual (FR4 off).
library;

import '../app/ports.dart';
import '../app/view_data.dart';

/// One past entry of the same business, for the anomaly detector's history.
class HistoryItem {
  const HistoryItem({
    required this.type,
    required this.amountNgwee,
    required this.categoryCode,
    required this.occurredAtMs,
  });

  final EntryType type;
  final int amountNgwee;
  final String categoryCode;
  final int occurredAtMs;
}

/// A new entry about to be saved, as the detector sees it.
class EntryCandidate {
  const EntryCandidate({
    required this.type,
    required this.amountNgwee,
    required this.categoryCode,
    required this.occurredAtMs,
  });

  final EntryType type;
  final int amountNgwee;
  final String categoryCode;
  final int occurredAtMs;
}

class AnomalyResult {
  const AnomalyResult({required this.score, required this.flagged});

  /// Stored in `ledger_entry.anomaly_score`.
  final double score;

  /// Stored in `ledger_entry.anomaly_flag`; shows the "Is this right?" check.
  final bool flagged;
}

abstract interface class AnomalyDetector {
  /// Scores [entry] against the business's recent [history] (FR4).
  /// Null means the detector has no opinion and nothing is stored.
  Future<AnomalyResult?> score(EntryCandidate entry, List<HistoryItem> history);

  /// The amount entries in [categoryCode] usually have, for "Usually about K…".
  /// Null when there is too little history to say.
  int? typicalNgwee(String categoryCode, List<HistoryItem> history);
}

/// No model yet: nothing is flagged.
class NoAnomalyDetector implements AnomalyDetector {
  const NoAnomalyDetector();

  @override
  Future<AnomalyResult?> score(
    EntryCandidate entry,
    List<HistoryItem> history,
  ) async => null;

  @override
  int? typicalNgwee(String categoryCode, List<HistoryItem> history) => null;
}

/// No model yet: no suggestion, so the user always picks the category.
class NoCategoriser implements CategoryPort {
  const NoCategoriser();

  @override
  Future<Suggestion?> suggest(String description, EntryType type) async => null;
}
