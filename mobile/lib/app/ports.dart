/// The contract between the UI and the rest of the app.
///
/// The UI depends only on these interfaces. The real implementations are in
/// `lib/data/` (assembled in `app_ports.dart`); `lib/preview/` supplies fixed
/// sample data for UI tests and screenshots.
library;

import 'view_data.dart';

abstract interface class SessionPort {
  /// Where first launch has got to; the app opens on Today once [OnboardingState.complete].
  Future<OnboardingState> state();

  /// The participant tapped "I agree" on the consent screen.
  Future<void> recordConsent();

  /// Saves the participant (FR11). [code] is already 4–12 capitals or digits.
  Future<void> start(String code, BusinessType type);

  /// "Stop taking part": the app keeps working, nothing more is sent.
  Future<void> withdraw();

  Future<void> dismissHints();
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

  /// Adds or edits a product. Adding a name the trader stopped selling brings
  /// that product back. Throws [DuplicateProductName] if another product in
  /// the list already has the name.
  Future<void> saveProduct(ProductDraft draft);

  Future<void> adjust(StockAdjustmentDraft draft);

  /// UC9: hides the product from the stock list and the sale screen. Nothing
  /// is deleted; past sales and purchases keep pointing at it.
  Future<void> stopSelling(String productId);
}

/// Product names are unique per business (`UNIQUE (business_id, name)`).
class DuplicateProductName implements Exception {
  const DuplicateProductName(this.name);

  final String name;

  @override
  String toString() => 'DuplicateProductName: $name';
}

abstract interface class SyncPort {
  Stream<SyncView> watch();

  /// Onboarding: can this participant code be used? Null when it cannot be
  /// checked now (no network, or sync not set up); the first sync checks it.
  Future<CodeCheck?> checkCode(String code);

  /// "Sync now" in the account sheet. Returns when the run has finished.
  Future<void> syncNow();
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
