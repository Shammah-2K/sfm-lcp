import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../app/ports.dart';
import '../app/view_data.dart';
import 'database.dart';
import 'session_repository.dart';

/// Products and stock levels (FR6, FR7).
///
/// Stock is never stored: the schema's `v_stock_level` view derives it from
/// sale and purchase item lines plus stock adjustments, and `v_low_stock`
/// decides what is running low. This class only reads those views and writes
/// products and adjustments.
class StockRepository implements StockPort {
  StockRepository(this._db, this._business, {DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  final AppDatabase _db;
  final BusinessRef _business;
  final DateTime Function() _now;
  static const Uuid _uuid = Uuid();

  int _nowMs() => _now().toUtc().millisecondsSinceEpoch;

  static const String _columns = '''
    s.product_id, s.name, s.reorder_level, s.stock_qty, p.unit_price_ngwee,
    EXISTS (SELECT 1 FROM v_low_stock l WHERE l.product_id = s.product_id) AS is_low
  ''';

  ProductRow _toRow(QueryRow r) => ProductRow(
    id: r.read<String>('product_id'),
    name: r.read<String>('name'),
    priceNgwee: r.read<int>('unit_price_ngwee'),
    inStock: r.read<int>('stock_qty'),
    reorderLevel: r.read<int>('reorder_level'),
    isLow: r.read<bool>('is_low'),
  );

  Set<ResultSetImplementation<dynamic, dynamic>> get _sources => {
    _db.product,
    _db.entryItem,
    _db.stockAdjustment,
    _db.ledgerEntry,
  };

  @override
  Stream<List<ProductRow>> watchProducts() async* {
    final business = await _business.idOrNull();
    if (business == null) {
      yield const [];
      return;
    }
    yield* _db
        .customSelect(
          'SELECT $_columns FROM v_stock_level s JOIN product p ON p.id = s.product_id '
          'WHERE s.business_id = ? ORDER BY s.name COLLATE NOCASE',
          variables: [Variable(business)],
          readsFrom: _sources,
        )
        .watch()
        .map((rows) => rows.map(_toRow).toList());
  }

  Selectable<QueryRow> _product(String id) => _db.customSelect(
    'SELECT $_columns FROM v_stock_level s JOIN product p ON p.id = s.product_id '
    'WHERE s.product_id = ?',
    variables: [Variable(id)],
    readsFrom: _sources,
  );

  @override
  Stream<ProductRow?> watchProduct(String id) => _product(
    id,
  ).watch().map((rows) => rows.isEmpty ? null : _toRow(rows.first));

  /// Adds a product with its opening stock, or updates name, price and reorder
  /// level of an existing one (last writer wins via `updated_at`).
  @override
  Future<void> saveProduct(ProductDraft d) async {
    final name = d.name.trim();
    if (name.isEmpty) {
      throw ArgumentError.value(d.name, 'name', 'is required');
    }
    if (d.priceNgwee < 0) {
      throw ArgumentError.value(
        d.priceNgwee,
        'priceNgwee',
        'cannot be negative',
      );
    }
    if (d.reorderLevel < 0) {
      throw ArgumentError.value(
        d.reorderLevel,
        'reorderLevel',
        'cannot be negative',
      );
    }
    if (d.openingStock < 0) {
      throw ArgumentError.value(
        d.openingStock,
        'openingStock',
        'cannot be negative',
      );
    }
    final now = _nowMs();
    final business = await _business.id();

    await _db.transaction(() async {
      final existingId = d.id;
      if (existingId != null) {
        await (_db.update(
          _db.product,
        )..where((p) => p.id.equals(existingId))).write(
          ProductCompanion(
            name: Value(name),
            unitPriceNgwee: Value(d.priceNgwee),
            reorderLevel: Value(d.reorderLevel),
            updatedAt: Value(now),
          ),
        );
        return;
      }
      final id = _uuid.v4();
      await _db
          .into(_db.product)
          .insert(
            ProductCompanion.insert(
              id: Value(id),
              businessId: business,
              name: name,
              unitPriceNgwee: d.priceNgwee,
              reorderLevel: Value(d.reorderLevel),
              createdAt: now,
              updatedAt: now,
            ),
          );
      // Opening stock is an adjustment, so stock stays derived.
      if (d.openingStock > 0) {
        await _db
            .into(_db.stockAdjustment)
            .insert(
              StockAdjustmentCompanion.insert(
                id: Value(_uuid.v4()),
                productId: id,
                quantityDelta: d.openingStock,
                reason: 'opening',
                createdAt: now,
              ),
            );
      }
    });
  }

  /// A counted, damaged or other change. Stock may not go below zero.
  @override
  Future<void> adjust(StockAdjustmentDraft d) async {
    if (d.delta == 0) {
      throw ArgumentError.value(d.delta, 'delta', 'cannot be zero');
    }
    await _db.transaction(() async {
      // A one-off read: stream queries must not run inside a transaction.
      final rows = await _product(d.productId).get();
      if (rows.isEmpty) {
        throw StateError('No product ${d.productId}');
      }
      final current = _toRow(rows.first);
      if (current.inStock + d.delta < 0) {
        throw ArgumentError.value(
          d.delta,
          'delta',
          'would take stock below zero',
        );
      }
      await _db
          .into(_db.stockAdjustment)
          .insert(
            StockAdjustmentCompanion.insert(
              id: Value(_uuid.v4()),
              productId: d.productId,
              quantityDelta: d.delta,
              reason: switch (d.reason) {
                AdjustReason.count => 'count',
                AdjustReason.damage => 'damage',
                AdjustReason.other => 'other',
              },
              createdAt: _nowMs(),
            ),
          );
    });
  }
}
