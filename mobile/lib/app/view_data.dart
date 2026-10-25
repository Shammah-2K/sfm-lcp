/// What the screens display and what they hand back when the user saves.
///
/// These are plain, immutable shapes. They carry no rules: totals, "usual"
/// amounts, low-stock decisions and suggestions arrive already worked out from
/// the ports in `ports.dart`, which the data and domain layers implement.
library;

enum EntryType { sale, expense }

enum PaymentMethod { cash, mobileMoney }

/// One row of the ledger as the UI shows it.
class EntryRow {
  const EntryRow({
    required this.id,
    required this.type,
    required this.amountNgwee,
    required this.description,
    required this.categoryCode,
    required this.method,
    required this.occurredAt,
    this.needsCheck = false,
    this.cancelled = false,
  });

  final String id;
  final EntryType type;

  /// Always positive; [type] says which way the money moved.
  final int amountNgwee;
  final String description;
  final String categoryCode;
  final PaymentMethod method;
  final DateTime occurredAt;

  /// The anomaly detector flagged this entry and the user has not answered yet.
  final bool needsCheck;

  /// A reversing entry has cancelled this one.
  final bool cancelled;

  bool get isIncome => type == EntryType.sale;
}

/// An entry the anomaly detector asks the user to confirm (FR4).
class UnusualEntry {
  const UnusualEntry({required this.entry, required this.usualNgwee});

  final EntryRow entry;

  /// What this category usually costs, as decided by the detector; null when
  /// there is too little history to say.
  final int? usualNgwee;
}

class CategoryTotal {
  const CategoryTotal({
    required this.categoryCode,
    required this.amountNgwee,
    required this.count,
  });

  final String categoryCode;
  final int amountNgwee;
  final int count;
}

/// Totals for a day or a week (FR5).
class PeriodTotals {
  const PeriodTotals({
    required this.start,
    required this.end,
    required this.inNgwee,
    required this.outNgwee,
    required this.profitNgwee,
    required this.inCount,
    required this.outCount,
    required this.byCategory,
  });

  final DateTime start;
  final DateTime end;
  final int inNgwee;
  final int outNgwee;

  /// Signed: negative is a loss.
  final int profitNgwee;
  final int inCount;
  final int outCount;
  final List<CategoryTotal> byCategory;
}

class ScoredCategory {
  const ScoredCategory(this.categoryCode, this.confidence);

  final String categoryCode;

  /// 0–1.
  final double confidence;
}

/// The on-device categoriser's answer for a description (FR3).
class Suggestion {
  const Suggestion({
    required this.top,
    required this.preselect,
    required this.modelVersion,
  });

  /// Best first; at most three.
  final List<ScoredCategory> top;

  /// The model is confident enough for the UI to select [top.first] for the user.
  final bool preselect;

  /// Stored in `ledger_entry.model_version` beside the prediction.
  final String modelVersion;
}

class ProductRow {
  const ProductRow({
    required this.id,
    required this.name,
    required this.priceNgwee,
    required this.inStock,
    required this.reorderLevel,
    required this.isLow,
  });

  final String id;
  final String name;
  final int priceNgwee;
  final int inStock;
  final int reorderLevel;

  /// At or below the reorder level (FR7), as decided by the stock layer.
  final bool isLow;

  bool get isOut => inStock <= 0;
}

class SyncView {
  const SyncView({required this.waiting, this.lastSyncedAt});

  /// Records saved on the phone and not yet sent (FR9).
  final int waiting;
  final DateTime? lastSyncedAt;
}

/// A quantity of one product in a quick sale (FR6).
class SaleLine {
  const SaleLine({required this.productId, required this.quantity});

  final String productId;
  final int quantity;
}

class SaleDraft {
  const SaleDraft({
    required this.amountNgwee,
    required this.description,
    required this.categoryCode,
    required this.method,
    this.lines = const [],
    this.suggestion,
  });

  final int amountNgwee;
  final String description;
  final String categoryCode;
  final PaymentMethod method;

  /// Empty for an amount-only sale.
  final List<SaleLine> lines;

  /// What the categoriser proposed, stored beside the user's choice (FR3).
  final Suggestion? suggestion;
}

class ExpenseDraft {
  const ExpenseDraft({
    required this.amountNgwee,
    required this.description,
    required this.categoryCode,
    required this.method,
    this.suggestion,
  });

  final int amountNgwee;
  final String description;
  final String categoryCode;
  final PaymentMethod method;
  final Suggestion? suggestion;
}

class ProductDraft {
  const ProductDraft({
    this.id,
    required this.name,
    required this.priceNgwee,
    required this.reorderLevel,
    required this.openingStock,
  });

  /// Null for a new product.
  final String? id;
  final String name;
  final int priceNgwee;
  final int reorderLevel;
  final int openingStock;
}

enum AdjustReason { count, damage, other }

class StockAdjustmentDraft {
  const StockAdjustmentDraft({
    required this.productId,
    required this.delta,
    required this.reason,
  });

  final String productId;
  final int delta;
  final AdjustReason reason;
}
