/// Fixed sample data so every screen can be run and reviewed before the real
/// data layer exists. This is a stand-in, not an implementation:
///
/// * totals are hand-written numbers matching the sample entries and do not
///   change when you record something;
/// * suggestions come from a lookup of two sample phrases (the values the
///   prototype's model produced for them), and nothing else is suggested;
/// * low-stock flags are part of the sample data and are not re-evaluated;
/// * nothing is saved: restarting the app restores the sample data.
///
/// Replace `previewPorts()` in main.dart with the real ports in the next phase.
library;

import 'dart:async';

import '../app/ports.dart';
import '../app/view_data.dart';

AppPorts previewPorts({String? participant}) {
  final ledger = _PreviewLedger();
  return AppPorts(
    session: _PreviewSession(participant),
    ledger: ledger,
    totals: _PreviewTotals(),
    categories: _PreviewCategories(),
    stock: _PreviewStock(),
    sync: _PreviewSync(),
  );
}

/// A value that replays its latest state to every new listener.
class _Live<T> {
  _Live(this._value);

  T _value;
  final _changes = StreamController<T>.broadcast();

  T get value => _value;

  set value(T v) {
    _value = v;
    _changes.add(v);
  }

  Stream<T> watch() async* {
    yield _value;
    yield* _changes.stream;
  }
}

DateTime _todayAt(int hour, int minute) {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day, hour, minute);
}

class _PreviewSession implements SessionPort {
  _PreviewSession(this._code);

  String? _code;

  @override
  Future<String?> currentParticipant() async => _code;

  @override
  Future<void> start(String code) async => _code = code;
}

class _PreviewLedger implements LedgerPort {
  _PreviewLedger()
    : _entries = _Live([
        EntryRow(
          id: 'e5',
          type: EntryType.expense,
          amountNgwee: 250000,
          description: 'MTN airtime',
          categoryCode: 'airtime',
          method: PaymentMethod.cash,
          occurredAt: _todayAt(14, 2),
          needsCheck: true,
        ),
        EntryRow(
          id: 'e4',
          type: EntryType.expense,
          amountNgwee: 2500,
          description: 'bus fare to Matero',
          categoryCode: 'transport',
          method: PaymentMethod.cash,
          occurredAt: _todayAt(8, 32),
        ),
        EntryRow(
          id: 'e3',
          type: EntryType.sale,
          amountNgwee: 5000,
          description: '',
          categoryCode: 'sales_goods',
          method: PaymentMethod.mobileMoney,
          occurredAt: _todayAt(8, 30),
        ),
        EntryRow(
          id: 'e2',
          type: EntryType.expense,
          amountNgwee: 12000,
          description: 'tomatoes from Soweto market',
          categoryCode: 'stock',
          method: PaymentMethod.cash,
          occurredAt: _todayAt(7, 55),
        ),
        EntryRow(
          id: 'e1',
          type: EntryType.sale,
          amountNgwee: 8000,
          description: 'hair braiding',
          categoryCode: 'sales_service',
          method: PaymentMethod.cash,
          occurredAt: _todayAt(7, 10),
        ),
      ]);

  final _Live<List<EntryRow>> _entries;
  int _next = 6;

  /// The sample "usual" amount the anomaly detector would report for e5.
  static const int _usualAirtime = 2000;

  @override
  Stream<List<EntryRow>> watchToday() => _entries.watch();

  @override
  Stream<UnusualEntry?> watchNeedsCheck() => _entries.watch().map((list) {
    for (final e in list.reversed) {
      if (e.needsCheck) {
        return UnusualEntry(entry: e, usualNgwee: _usualAirtime);
      }
    }
    return null;
  });

  @override
  Stream<EntryRow?> watchEntry(String id) =>
      _entries.watch().map((list) => list.where((e) => e.id == id).firstOrNull);

  EntryRow _add(
    EntryType type,
    int amount,
    String description,
    String category,
    PaymentMethod method,
  ) {
    final row = EntryRow(
      id: 'e${_next++}',
      type: type,
      amountNgwee: amount,
      description: description,
      categoryCode: category,
      method: method,
      occurredAt: DateTime.now(),
    );
    _entries.value = [row, ..._entries.value];
    return row;
  }

  @override
  Future<EntryRow> recordSale(SaleDraft d) async => _add(
    EntryType.sale,
    d.amountNgwee,
    d.description,
    d.categoryCode,
    d.method,
  );

  @override
  Future<EntryRow> recordExpense(ExpenseDraft d) async => _add(
    EntryType.expense,
    d.amountNgwee,
    d.description,
    d.categoryCode,
    d.method,
  );

  void _replace(String id, EntryRow Function(EntryRow) change) {
    _entries.value = [
      for (final e in _entries.value) e.id == id ? change(e) : e,
    ];
  }

  @override
  Future<void> cancelEntry(String id) async =>
      _replace(id, (e) => _copy(e, cancelled: true, needsCheck: false));

  @override
  Future<void> changeCategory(String id, String code) async =>
      _replace(id, (e) => _copy(e, categoryCode: code));

  @override
  Future<void> confirmUnusual(String id) async =>
      _replace(id, (e) => _copy(e, needsCheck: false));

  static EntryRow _copy(
    EntryRow e, {
    String? categoryCode,
    bool? cancelled,
    bool? needsCheck,
  }) => EntryRow(
    id: e.id,
    type: e.type,
    amountNgwee: e.amountNgwee,
    description: e.description,
    categoryCode: categoryCode ?? e.categoryCode,
    method: e.method,
    occurredAt: e.occurredAt,
    needsCheck: needsCheck ?? e.needsCheck,
    cancelled: cancelled ?? e.cancelled,
  );
}

class _PreviewTotals implements TotalsPort {
  @override
  Stream<PeriodTotals> watchDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final isToday =
        start ==
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    return Stream.value(
      isToday
          ? PeriodTotals(
              start: start,
              end: start,
              inNgwee: 13000,
              outNgwee: 264500,
              profitNgwee: -251500,
              inCount: 2,
              outCount: 3,
              byCategory: const [
                CategoryTotal(
                  categoryCode: 'airtime',
                  amountNgwee: 250000,
                  count: 1,
                ),
                CategoryTotal(
                  categoryCode: 'stock',
                  amountNgwee: 12000,
                  count: 1,
                ),
                CategoryTotal(
                  categoryCode: 'sales_service',
                  amountNgwee: 8000,
                  count: 1,
                ),
                CategoryTotal(
                  categoryCode: 'sales_goods',
                  amountNgwee: 5000,
                  count: 1,
                ),
                CategoryTotal(
                  categoryCode: 'transport',
                  amountNgwee: 2500,
                  count: 1,
                ),
              ],
            )
          : PeriodTotals(
              start: start,
              end: start,
              inNgwee: 0,
              outNgwee: 0,
              profitNgwee: 0,
              inCount: 0,
              outCount: 0,
              byCategory: const [],
            ),
    );
  }

  @override
  Stream<PeriodTotals> watchWeek(DateTime anyDayInWeek) {
    final day = DateTime(
      anyDayInWeek.year,
      anyDayInWeek.month,
      anyDayInWeek.day,
    );
    final start = day.subtract(Duration(days: day.weekday - 1));
    return Stream.value(
      PeriodTotals(
        start: start,
        end: start.add(const Duration(days: 6)),
        inNgwee: 148500,
        outNgwee: 302000,
        profitNgwee: -153500,
        inCount: 14,
        outCount: 9,
        byCategory: const [
          CategoryTotal(categoryCode: 'airtime', amountNgwee: 251000, count: 2),
          CategoryTotal(
            categoryCode: 'sales_goods',
            amountNgwee: 112500,
            count: 11,
          ),
          CategoryTotal(categoryCode: 'stock', amountNgwee: 38000, count: 3),
          CategoryTotal(
            categoryCode: 'sales_service',
            amountNgwee: 36000,
            count: 3,
          ),
          CategoryTotal(categoryCode: 'transport', amountNgwee: 9000, count: 3),
          CategoryTotal(categoryCode: 'rent_levy', amountNgwee: 4000, count: 1),
        ],
      ),
    );
  }
}

class _PreviewCategories implements CategoryPort {
  /// Two sample phrases with the scores the prototype's model gave them.
  static const Map<String, Suggestion> _samples = {
    'bus fare to matero': Suggestion(
      top: [ScoredCategory('transport', 0.99)],
      preselect: true,
      modelVersion: 'preview',
    ),
    'repair of wheelbarrow': Suggestion(
      top: [
        ScoredCategory('other_expense', 0.45),
        ScoredCategory('stock', 0.29),
        ScoredCategory('utilities', 0.07),
      ],
      preselect: false,
      modelVersion: 'preview',
    ),
  };

  @override
  Future<Suggestion?> suggest(String description, EntryType type) async {
    if (type != EntryType.expense) return null;
    return _samples[description.trim().toLowerCase()];
  }
}

class _PreviewStock implements StockPort {
  final _products = _Live(const [
    ProductRow(
      id: 'p1',
      name: 'Bread',
      priceNgwee: 2500,
      inStock: 12,
      reorderLevel: 5,
      isLow: false,
    ),
    ProductRow(
      id: 'p2',
      name: 'Sugar 1kg',
      priceNgwee: 3200,
      inStock: 6,
      reorderLevel: 3,
      isLow: false,
    ),
    ProductRow(
      id: 'p3',
      name: 'Cooking oil 2L',
      priceNgwee: 9500,
      inStock: 3,
      reorderLevel: 5,
      isLow: true,
    ),
    ProductRow(
      id: 'p4',
      name: 'Kapenta 500g',
      priceNgwee: 6000,
      inStock: 0,
      reorderLevel: 2,
      isLow: true,
    ),
  ]);
  int _next = 5;

  @override
  Stream<List<ProductRow>> watchProducts() => _products.watch();

  @override
  Stream<ProductRow?> watchProduct(String id) => _products.watch().map(
    (list) => list.where((p) => p.id == id).firstOrNull,
  );

  @override
  Future<void> saveProduct(ProductDraft d) async {
    _products.value = [
      ..._products.value,
      ProductRow(
        id: 'p${_next++}',
        name: d.name,
        priceNgwee: d.priceNgwee,
        inStock: d.openingStock,
        reorderLevel: d.reorderLevel,
        isLow: false,
      ),
    ];
  }

  @override
  Future<void> adjust(StockAdjustmentDraft d) async {
    _products.value = [
      for (final p in _products.value)
        p.id == d.productId
            ? ProductRow(
                id: p.id,
                name: p.name,
                priceNgwee: p.priceNgwee,
                inStock: p.inStock + d.delta,
                reorderLevel: p.reorderLevel,
                isLow: p.isLow,
              )
            : p,
    ];
  }
}

class _PreviewSync implements SyncPort {
  @override
  Stream<SyncView> watch() => Stream.value(const SyncView(waiting: 5));
}
