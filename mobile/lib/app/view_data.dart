/// What the screens display and what they hand back when the user saves.
///
/// These are plain, immutable shapes. They carry no rules: totals, "usual"
/// amounts, low-stock decisions and suggestions arrive already worked out from
/// the ports in `ports.dart`, which the data and domain layers implement.
library;

enum EntryType { sale, expense }

enum PaymentMethod { cash, mobileMoney }

/// `business.business_type`, chosen with one tap during onboarding.
enum BusinessType {
  marketStall('market_stall'),
  shop('shop'),
  service('service'),
  other('other');

  const BusinessType(this.dbValue);

  final String dbValue;
}

/// How far first launch has got (FR11 and the ethics procedure).
class OnboardingState {
  const OnboardingState({
    required this.consented,
    required this.participantCode,
    required this.withdrawn,
    required this.hintsDismissed,
  });

  /// The participant agreed on the in-app consent screen.
  final bool consented;

  /// Null until the participant code and business type are saved.
  final String? participantCode;

  /// The participant chose "Stop taking part": nothing more is sent.
  final bool withdrawn;

  /// The first-use hints on Today have been dismissed.
  final bool hintsDismissed;

  bool get complete => consented && participantCode != null;
}

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

/// What the study server said about a participant code (decision D6).
enum CodeCheck {
  ok,

  /// Not on the researcher's list.
  unknown,

  /// Already used on another phone.
  taken,

  /// This code has stopped taking part.
  withdrawn,
}

/// How the last sync attempt failed.
enum SyncTrouble {
  /// No network, or no answer: normal for a trader; it retries by itself.
  noNetwork,

  /// The server answered but refused (e.g. sign-in switched off): needs the
  /// researcher.
  server,
}

class SyncView {
  const SyncView({
    required this.waiting,
    this.lastSyncedAt,
    this.withdrawn = false,
    this.enabled = true,
    this.problem,
    this.trouble,
  });

  /// Records saved on the phone and not yet sent (FR9).
  final int waiting;
  final DateTime? lastSyncedAt;

  /// The participant stopped taking part, so nothing will be sent.
  final bool withdrawn;

  /// False in a build made without the server's address: records stay on
  /// the phone only.
  final bool enabled;

  /// Why records cannot be sent: the code is not usable. Null when fine.
  final CodeCheck? problem;

  /// How the last attempt failed; null if it got through.
  final SyncTrouble? trouble;
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

/// One product bought on a stock-purchase expense (FR7).
class PurchaseLine {
  const PurchaseLine({
    required this.productId,
    required this.quantity,
    required this.unitCostNgwee,
  });

  final String productId;
  final int quantity;

  /// What the trader paid for one item; stored in `entry_item.unit_price_ngwee`.
  final int unitCostNgwee;

  int get totalNgwee => quantity * unitCostNgwee;
}

class ExpenseDraft {
  const ExpenseDraft({
    required this.amountNgwee,
    required this.description,
    required this.categoryCode,
    required this.method,
    this.suggestion,
    this.lines = const [],
  });

  /// The amount paid. With [lines] it defaults to their total, but the trader
  /// may overwrite it (a discount, a delivery fee).
  final int amountNgwee;
  final String description;
  final String categoryCode;
  final PaymentMethod method;
  final Suggestion? suggestion;

  /// Products bought; only on a "Stock purchase" expense. Empty otherwise.
  final List<PurchaseLine> lines;
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
