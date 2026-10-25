/// The contract between the UI and the rest of the app.
///
/// The UI depends only on these interfaces. The real implementations (Drift
/// ledger, totals from the schema's views, the on-device categoriser, the
/// anomaly detector and the sync outbox) belong to the data and domain layers
/// and are written by Shammah, per CLAUDE.md. Until then `lib/preview/`
/// supplies fixed sample data so every screen can be run and reviewed.
library;

import 'view_data.dart';

abstract interface class SessionPort {
  /// The participant code saved on this phone, or null on first launch.
  Future<String?> currentParticipant();

  /// Saves the participant code (FR11). [code] is already 4–12 capitals or digits.
  Future<void> start(String code);
}

abstract interface class LedgerPort {
  /// Today's entries, newest first.
  Stream<List<EntryRow>> watchToday();

  /// The oldest entry still waiting for the user's "Is this right?" answer.
  Stream<UnusualEntry?> watchNeedsCheck();

  Stream<EntryRow?> watchEntry(String id);

  Future<EntryRow> recordSale(SaleDraft draft);

  Future<EntryRow> recordExpense(ExpenseDraft draft);

  /// Adds a reversing entry (FR12). Entries are never edited or deleted.
  Future<void> cancelEntry(String id);

  /// The only field of a saved entry the user may change.
  Future<void> changeCategory(String id, String categoryCode);

  /// The user answered "Yes, keep it" to an unusual-entry check.
  Future<void> confirmUnusual(String id);
}

abstract interface class TotalsPort {
  Stream<PeriodTotals> watchDay(DateTime day);

  Stream<PeriodTotals> watchWeek(DateTime anyDayInWeek);
}

abstract interface class CategoryPort {
  /// Null when the description is blank or nothing can be suggested.
  Future<Suggestion?> suggest(String description, EntryType type);
}

abstract interface class StockPort {
  Stream<List<ProductRow>> watchProducts();

  Stream<ProductRow?> watchProduct(String id);

  Future<void> saveProduct(ProductDraft draft);

  Future<void> adjust(StockAdjustmentDraft draft);
}

abstract interface class SyncPort {
  Stream<SyncView> watch();
}

/// Everything the UI needs, handed down from the app root.
class AppPorts {
  const AppPorts({
    required this.session,
    required this.ledger,
    required this.totals,
    required this.categories,
    required this.stock,
    required this.sync,
  });

  final SessionPort session;
  final LedgerPort ledger;
  final TotalsPort totals;
  final CategoryPort categories;
  final StockPort stock;
  final SyncPort sync;
}
