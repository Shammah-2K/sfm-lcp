import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../domain/categories.dart';
import '../domain/ledger.dart';
import '../ml/categoriser.dart';
import 'database.dart' hide LedgerEntry;

/// Writes and reads the append-only ledger for one business.
///
/// Validation of user input happens in the UI; the database constraints and triggers from the
/// dissertation schema are the final authority, so their errors surface unchanged.
class LedgerRepository {
  LedgerRepository(this._db, this.businessId, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final String businessId;
  final DateTime Function() _clock;
  static const Uuid _uuid = Uuid();

  Future<LedgerEntry> recordSale({
    required int amountNgwee,
    String description = '',
    required PaymentMethod method,
    String? finalCategory,
    Suggestion? suggestion,
  }) {
    return _insert(
      type: EntryType.sale,
      amountNgwee: amountNgwee,
      description: description,
      method: method,
      finalCategory: finalCategory ?? defaultSaleCategory,
      suggestion: suggestion,
    );
  }

  Future<LedgerEntry> recordExpense({
    required int amountNgwee,
    required String description,
    required PaymentMethod method,
    required String finalCategory,
    Suggestion? suggestion,
  }) {
    return _insert(
      type: EntryType.expense,
      amountNgwee: amountNgwee,
      description: description,
      method: method,
      finalCategory: finalCategory,
      suggestion: suggestion,
    );
  }

  Future<LedgerEntry> _insert({
    required EntryType type,
    required int amountNgwee,
    required String description,
    required PaymentMethod method,
    required String finalCategory,
    required Suggestion? suggestion,
  }) {
    final id = _uuid.v4();
    final now = _clock().toUtc().millisecondsSinceEpoch;
    final row = LedgerEntryCompanion.insert(
      id: Value(id),
      businessId: businessId,
      entryType: type.dbValue,
      amountNgwee: amountNgwee,
      description: Value(description),
      paymentMethod: Value(method.dbValue),
      predictedCategory: Value(suggestion?.categoryCode),
      categoryConfidence: Value(suggestion?.confidence),
      finalCategory: finalCategory,
      modelVersion: Value(suggestion?.modelVersion),
      occurredAt: now,
      createdAt: now,
      updatedAt: now,
    );
    return _db.transaction(() async {
      await _db.into(_db.ledgerEntry).insert(row);
      final saved = await (_db.select(
        _db.ledgerEntry,
      )..where((e) => e.id.equals(id))).getSingle();
      return _toDomain(saved);
    });
  }

  /// The newest [limit] entries, newest first, updating whenever the ledger changes.
  Stream<List<EntryView>> watchRecent({int limit = 50}) {
    final query = _db.select(_db.ledgerEntry)
      ..where((e) => e.businessId.equals(businessId))
      ..orderBy([
        (e) => OrderingTerm.desc(e.createdAt),
        (e) => OrderingTerm.desc(e.rowId),
      ])
      ..limit(limit);
    return query.watch().map(
      (rows) => [
        for (final row in rows)
          EntryView(_toDomain(row), categoryByCode[row.finalCategory]!),
      ],
    );
  }

  /// Number of outbox rows still waiting to be sent; the schema's triggers fill the outbox.
  Stream<int> watchPendingSyncCount() {
    final count = countAll();
    final query = _db.selectOnly(_db.syncRecord)
      ..addColumns([count])
      ..where(_db.syncRecord.status.equals('pending'));
    return query.map((row) => row.read(count)!).watchSingle();
  }

  static LedgerEntry _toDomain(LedgerEntryData row) => LedgerEntry(
    id: row.id!,
    businessId: row.businessId,
    entryType: EntryType.parse(row.entryType),
    amountNgwee: row.amountNgwee,
    description: row.description,
    paymentMethod: PaymentMethod.parse(row.paymentMethod),
    predictedCategory: row.predictedCategory,
    categoryConfidence: row.categoryConfidence,
    finalCategory: row.finalCategory,
    modelVersion: row.modelVersion,
    occurredAt: DateTime.fromMillisecondsSinceEpoch(
      row.occurredAt,
      isUtc: true,
    ),
  );
}
