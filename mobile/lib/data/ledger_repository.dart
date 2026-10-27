import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../app/ports.dart';
import '../app/view_data.dart';
import '../domain/codebook.dart';
import '../domain/models.dart';
import 'database.dart';
import 'lusaka_time.dart';
import 'session_repository.dart';

/// The append-only ledger (FR1, FR2, FR4, FR12).
///
/// Every write happens inside one database transaction. The schema's triggers
/// queue the matching `sync_record` row inside that same transaction, so an
/// entry can never be saved without also being queued for sync.
class LedgerRepository implements LedgerPort {
  LedgerRepository(
    this._db,
    this._business, {
    AnomalyDetector detector = const NoAnomalyDetector(),
    DateTime Function()? clock,
  }) : _detector = detector,
       _now = clock ?? DateTime.now;

  final AppDatabase _db;
  final BusinessRef _business;
  final AnomalyDetector _detector;
  final DateTime Function() _now;
  static const Uuid _uuid = Uuid();

  /// How far back the anomaly detector looks.
  static const Duration historyWindow = Duration(days: 60);

  int _nowMs() => _now().toUtc().millisecondsSinceEpoch;

  // ---------------------------------------------------------------- reading

  /// Columns every list needs, plus whether a reversal cancels the entry.
  /// Reversal rows themselves (`reverses_id IS NOT NULL`) are never listed:
  /// the user sees the original marked "Cancelled" instead.
  static const String _entryColumns = '''
    e.id, e.entry_type, e.amount_ngwee, e.description, e.final_category,
    e.payment_method, e.occurred_at, e.anomaly_flag, e.anomaly_reviewed_at,
    EXISTS (SELECT 1 FROM ledger_entry r WHERE r.reverses_id = e.id) AS cancelled
  ''';

  EntryRow _toRow(QueryRow r) {
    final cancelled = r.read<bool>('cancelled');
    return EntryRow(
      id: r.read<String>('id'),
      type: r.read<String>('entry_type') == 'sale'
          ? EntryType.sale
          : EntryType.expense,
      amountNgwee: r.read<int>('amount_ngwee'),
      description: r.read<String>('description'),
      categoryCode: r.read<String>('final_category'),
      method: r.read<String>('payment_method') == 'cash'
          ? PaymentMethod.cash
          : PaymentMethod.mobileMoney,
      occurredAt: DateTime.fromMillisecondsSinceEpoch(
        r.read<int>('occurred_at'),
        isUtc: true,
      ),
      needsCheck:
          !cancelled &&
          r.read<int>('anomaly_flag') == 1 &&
          r.readNullable<int>('anomaly_reviewed_at') == null,
      cancelled: cancelled,
    );
  }

  @override
  Stream<List<EntryRow>> watchToday() async* {
    final business = await _business.idOrNull();
    if (business == null) {
      yield const [];
      return;
    }
    final day = lusakaDay(_now());
    yield* _db
        .customSelect(
          'SELECT $_entryColumns FROM ledger_entry e '
          'WHERE e.business_id = ? AND e.reverses_id IS NULL '
          'AND e.occurred_at >= ? AND e.occurred_at < ? '
          'ORDER BY e.occurred_at DESC, e.created_at DESC',
          variables: [
            Variable(business),
            Variable(day.startMs),
            Variable(day.endMs),
          ],
          readsFrom: {_db.ledgerEntry},
        )
        .watch()
        .map((rows) => rows.map(_toRow).toList());
  }

  @override
  Stream<EntryRow?> watchEntry(String id) => _db
      .customSelect(
        'SELECT $_entryColumns FROM ledger_entry e WHERE e.id = ?',
        variables: [Variable(id)],
        readsFrom: {_db.ledgerEntry},
      )
      .watch()
      .map((rows) => rows.isEmpty ? null : _toRow(rows.first));

  /// The oldest flagged entry the user has not yet answered (FR4, UC6).
  @override
  Stream<UnusualEntry?> watchNeedsCheck() async* {
    final business = await _business.idOrNull();
    if (business == null) {
      yield null;
      return;
    }
    yield* _db
        .customSelect(
          'SELECT $_entryColumns FROM ledger_entry e '
          'WHERE e.business_id = ? AND e.reverses_id IS NULL '
          'AND e.anomaly_flag = 1 AND e.anomaly_reviewed_at IS NULL '
          'AND NOT EXISTS (SELECT 1 FROM ledger_entry r WHERE r.reverses_id = e.id) '
          'ORDER BY e.occurred_at ASC LIMIT 1',
          variables: [Variable(business)],
          readsFrom: {_db.ledgerEntry},
        )
        .watch()
        .asyncMap((rows) async {
          if (rows.isEmpty) return null;
          final entry = _toRow(rows.first);
          final history = await _history(
            business,
            before: entry.occurredAt.millisecondsSinceEpoch,
          );
          return UnusualEntry(
            entry: entry,
            usualNgwee: _detector.typicalNgwee(entry.categoryCode, history),
          );
        });
  }

  /// Recent non-reversed entries, newest first, for the anomaly detector.
  Future<List<HistoryItem>> _history(
    String business, {
    required int before,
  }) async {
    final since = before - historyWindow.inMilliseconds;
    final rows = await _db
        .customSelect(
          'SELECT entry_type, amount_ngwee, final_category, occurred_at FROM ledger_entry e '
          'WHERE e.business_id = ? AND e.reverses_id IS NULL '
          'AND NOT EXISTS (SELECT 1 FROM ledger_entry r WHERE r.reverses_id = e.id) '
          'AND e.occurred_at >= ? AND e.occurred_at < ? ORDER BY e.occurred_at DESC',
          variables: [Variable(business), Variable(since), Variable(before)],
        )
        .get();
    return [
      for (final r in rows)
        HistoryItem(
          type: r.read<String>('entry_type') == 'sale'
              ? EntryType.sale
              : EntryType.expense,
          amountNgwee: r.read<int>('amount_ngwee'),
          categoryCode: r.read<String>('final_category'),
          occurredAtMs: r.read<int>('occurred_at'),
        ),
    ];
  }

  // ---------------------------------------------------------------- writing

  /// UC2 and UC3. A quick sale (FR6) carries item lines: the ledger prices
  /// them from the products' current prices and the amount is their total,
  /// whatever the screen showed.
  @override
  Future<EntryRow> recordSale(SaleDraft d) async {
    if (d.lines.isEmpty) {
      return _record(
        type: EntryType.sale,
        amountNgwee: d.amountNgwee,
        description: d.description,
        categoryCode: d.categoryCode,
        method: d.method,
        suggestion: d.suggestion,
      );
    }
    final priced = await _priceLines(d.lines, selling: true);
    return _record(
      type: EntryType.sale,
      amountNgwee: priced.fold(
        0,
        (sum, l) => sum + l.quantity * l.unitPriceNgwee,
      ),
      description: d.description,
      categoryCode: d.categoryCode,
      method: d.method,
      suggestion: d.suggestion,
      lines: priced,
    );
  }

  /// UC4. A stock purchase (FR7) may list the products bought: each line adds
  /// its quantity to stock through `v_stock_level`. The amount is what the
  /// trader says they paid; it need not equal the lines' total (a discount or
  /// a delivery fee), so it is not recomputed here.
  @override
  Future<EntryRow> recordExpense(ExpenseDraft d) async {
    if (d.lines.isNotEmpty && d.categoryCode != stockPurchaseCategory) {
      throw ArgumentError.value(
        d.categoryCode,
        'categoryCode',
        'only a stock purchase can list products',
      );
    }
    final lines = d.lines.isEmpty
        ? const <_PricedLine>[]
        : await _checkPurchaseLines(d.lines);
    return _record(
      type: EntryType.expense,
      amountNgwee: d.amountNgwee,
      description: d.description,
      categoryCode: d.categoryCode,
      method: d.method,
      suggestion: d.suggestion,
      lines: lines,
    );
  }

  /// Each product once, a quantity above zero, a cost not below zero, and a
  /// product of this business.
  Future<List<_PricedLine>> _checkPurchaseLines(
    List<PurchaseLine> lines,
  ) async {
    final business = await _business.id();
    final seen = <String>{};
    final checked = <_PricedLine>[];
    for (final line in lines) {
      if (line.quantity <= 0) {
        throw ArgumentError.value(
          line.quantity,
          'quantity',
          'must be above zero',
        );
      }
      if (line.unitCostNgwee < 0) {
        throw ArgumentError.value(
          line.unitCostNgwee,
          'unitCostNgwee',
          'cannot be negative',
        );
      }
      if (!seen.add(line.productId)) {
        throw ArgumentError.value(line.productId, 'productId', 'listed twice');
      }
      final product =
          await (_db.select(_db.product)..where(
                (p) =>
                    p.id.equals(line.productId) & p.businessId.equals(business),
              ))
              .getSingleOrNull();
      if (product == null) {
        throw ArgumentError.value(
          line.productId,
          'productId',
          'no such product',
        );
      }
      checked.add(
        _PricedLine(line.productId, line.quantity, line.unitCostNgwee),
      );
    }
    return checked;
  }

  /// UC2 / UC4: validate, score for anomalies, then insert in one transaction.
  Future<EntryRow> _record({
    required EntryType type,
    required int amountNgwee,
    required String description,
    required String categoryCode,
    required PaymentMethod method,
    required Suggestion? suggestion,
    List<_PricedLine> lines = const [],
  }) async {
    // UC4 step 2. The schema rejects these too; checking first gives a clear
    // error instead of a raw SQLite one.
    if (amountNgwee <= 0) {
      throw ArgumentError.value(
        amountNgwee,
        'amountNgwee',
        'must be above zero',
      );
    }
    final text = description.trim();
    if (type == EntryType.expense && text.isEmpty) {
      throw ArgumentError.value(
        description,
        'description',
        'an expense needs a description',
      );
    }
    _checkCategoryKind(categoryCode, type);

    final business = await _business.id();
    final now = _nowMs();
    final id = _uuid.v4();

    // UC4 step 5: score before saving, against the history before this entry.
    final result = await _detector.score(
      EntryCandidate(
        type: type,
        amountNgwee: amountNgwee,
        categoryCode: categoryCode,
        occurredAtMs: now,
      ),
      await _history(business, before: now),
    );

    // UC5 postcondition: the prediction is stored beside the user's choice.
    final predicted = suggestion?.top.firstOrNull;

    await _db.transaction(() async {
      await _db
          .into(_db.ledgerEntry)
          .insert(
            LedgerEntryCompanion.insert(
              id: Value(id),
              businessId: business,
              entryType: type == EntryType.sale ? 'sale' : 'expense',
              amountNgwee: amountNgwee,
              description: Value(text),
              paymentMethod: Value(
                method == PaymentMethod.cash ? 'cash' : 'mobile_money',
              ),
              predictedCategory: Value(predicted?.categoryCode),
              categoryConfidence: Value(predicted?.confidence),
              modelVersion: Value(
                predicted == null ? null : suggestion!.modelVersion,
              ),
              finalCategory: categoryCode,
              anomalyScore: Value(result?.score),
              anomalyFlag: Value(result != null && result.flagged ? 1 : 0),
              occurredAt: now,
              createdAt: now,
              updatedAt: now,
            ),
          );
      // Item lines go in the same transaction; v_stock_level then lowers
      // stock for sales (and raises it for purchases) on its own.
      for (final line in lines) {
        await _db
            .into(_db.entryItem)
            .insert(
              EntryItemCompanion.insert(
                id: Value(_uuid.v4()),
                entryId: id,
                productId: line.productId,
                quantity: line.quantity,
                unitPriceNgwee: line.unitPriceNgwee,
              ),
            );
      }
    });
    return (await watchEntry(id).first)!;
  }

  /// FR12: cancel by posting an exact reversal. The original is never edited.
  ///
  /// The reversal takes the original's `occurred_at`, so cancelling a mistake
  /// corrects the day the mistake was made, not the day it was noticed.
  @override
  Future<void> cancelEntry(String id) async {
    final now = _nowMs();
    await _db.transaction(() async {
      final original = await (_db.select(
        _db.ledgerEntry,
      )..where((e) => e.id.equals(id))).getSingleOrNull();
      if (original == null) {
        throw StateError('No entry $id');
      }
      if (original.reversesId != null) {
        throw StateError('A reversal cannot itself be cancelled');
      }
      // The UNIQUE index on reverses_id would also stop a second reversal.
      final reversalId = _uuid.v4();
      await _db
          .into(_db.ledgerEntry)
          .insert(
            LedgerEntryCompanion.insert(
              id: Value(reversalId),
              businessId: original.businessId,
              entryType: original.entryType,
              amountNgwee: -original.amountNgwee,
              // The schema requires a description on every expense row,
              // reversals included, so the reversal repeats the original's.
              description: Value(original.description),
              paymentMethod: Value(original.paymentMethod),
              finalCategory: original.finalCategory,
              reversesId: Value(id),
              occurredAt: original.occurredAt,
              createdAt: now,
              updatedAt: now,
            ),
          );
      // Item lines are reversed too, so stock returns to where it was.
      final items = await (_db.select(
        _db.entryItem,
      )..where((i) => i.entryId.equals(id))).get();
      // Cancelling a purchase takes its stock back out. If some of it has been
      // sold since, that would leave stock below zero, so it is refused: the
      // trader corrects the count with "Adjust stock" instead.
      if (original.entryType == 'expense') {
        for (final item in items) {
          final r = await _db
              .customSelect(
                'SELECT stock_qty FROM v_stock_level WHERE product_id = ?',
                variables: [Variable(item.productId)],
              )
              .getSingle();
          if (r.read<int>('stock_qty') - item.quantity < 0) {
            throw StateError(
              'Some of this stock has already been sold; adjust the stock instead',
            );
          }
        }
      }
      for (final item in items) {
        await _db
            .into(_db.entryItem)
            .insert(
              EntryItemCompanion.insert(
                id: Value(_uuid.v4()),
                entryId: reversalId,
                productId: item.productId,
                quantity: -item.quantity,
                unitPriceNgwee: item.unitPriceNgwee,
              ),
            );
      }
    });
  }

  /// The only change allowed to a saved entry. The schema checks the category
  /// kind only on INSERT, so it is checked here for updates.
  @override
  Future<void> changeCategory(String id, String categoryCode) async {
    await _db.transaction(() async {
      final entry = await (_db.select(
        _db.ledgerEntry,
      )..where((e) => e.id.equals(id))).getSingle();
      _checkCategoryKind(
        categoryCode,
        entry.entryType == 'sale' ? EntryType.sale : EntryType.expense,
      );
      await (_db.update(_db.ledgerEntry)..where((e) => e.id.equals(id))).write(
        LedgerEntryCompanion(
          finalCategory: Value(categoryCode),
          updatedAt: Value(_nowMs()),
        ),
      );
    });
  }

  /// UC6: the user answered "Yes, keep it".
  @override
  Future<void> confirmUnusual(String id) async {
    final now = _nowMs();
    await (_db.update(_db.ledgerEntry)..where((e) => e.id.equals(id))).write(
      LedgerEntryCompanion(
        anomalyReviewedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  /// Looks up each product's current price and stock. A sale may not sell
  /// more than is in stock; each product may appear once (the schema's
  /// UNIQUE (entry_id, product_id)).
  Future<List<_PricedLine>> _priceLines(
    List<SaleLine> lines, {
    required bool selling,
  }) async {
    final business = await _business.id();
    final seen = <String>{};
    final priced = <_PricedLine>[];
    for (final line in lines) {
      if (line.quantity <= 0) {
        throw ArgumentError.value(
          line.quantity,
          'quantity',
          'must be above zero',
        );
      }
      if (!seen.add(line.productId)) {
        throw ArgumentError.value(line.productId, 'productId', 'listed twice');
      }
      final r = await _db
          .customSelect(
            'SELECT p.unit_price_ngwee, s.stock_qty FROM product p '
            'JOIN v_stock_level s ON s.product_id = p.id '
            'WHERE p.id = ? AND p.business_id = ? AND p.is_active = 1',
            variables: [Variable(line.productId), Variable(business)],
          )
          .getSingleOrNull();
      if (r == null) {
        throw ArgumentError.value(
          line.productId,
          'productId',
          'no such product',
        );
      }
      if (selling && line.quantity > r.read<int>('stock_qty')) {
        throw ArgumentError.value(
          line.quantity,
          'quantity',
          'more than is in stock',
        );
      }
      priced.add(
        _PricedLine(
          line.productId,
          line.quantity,
          r.read<int>('unit_price_ngwee'),
        ),
      );
    }
    return priced;
  }

  static void _checkCategoryKind(String code, EntryType type) {
    final category = codebook.where((c) => c.code == code).firstOrNull;
    if (category == null) {
      throw ArgumentError.value(code, 'categoryCode', 'not in the codebook');
    }
    if (category.type != type) {
      throw ArgumentError.value(
        code,
        'categoryCode',
        'is not a ${type.name} category',
      );
    }
  }
}

class _PricedLine {
  const _PricedLine(this.productId, this.quantity, this.unitPriceNgwee);

  final String productId;
  final int quantity;
  final int unitPriceNgwee;
}
