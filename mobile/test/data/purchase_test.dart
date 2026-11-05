// Stock bought on an expense (FR7, decision D2).
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sfm_lcp/app/app_ports.dart';
import 'package:sfm_lcp/app/ports.dart';
import 'package:sfm_lcp/app/view_data.dart';
import 'package:sfm_lcp/data/database.dart';

void main() {
  late AppDatabase db;
  late AppPorts ports;
  late String bread;
  late String sugar;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    ports = buildAppPorts(db);
    await ports.session.recordConsent();
    await ports.session.start('LSK01', BusinessType.marketStall);
    for (final name in ['Bread', 'Sugar']) {
      await ports.stock.saveProduct(
        ProductDraft(
          name: name,
          priceNgwee: 2500,
          reorderLevel: 2,
          openingStock: 4,
        ),
      );
    }
    final products = await ports.stock.watchProducts().first;
    bread = products.firstWhere((p) => p.name == 'Bread').id;
    sugar = products.firstWhere((p) => p.name == 'Sugar').id;
  });

  tearDown(() => db.close());

  Future<int> stockOf(String id) async =>
      (await ports.stock.watchProduct(id).first)!.inStock;

  ExpenseDraft purchase(
    List<PurchaseLine> lines, {
    int? amount,
    String category = 'stock',
  }) => ExpenseDraft(
    amountNgwee: amount ?? lines.fold(0, (s, l) => s + l.totalNgwee),
    description: 'Stock from the wholesaler',
    categoryCode: category,
    method: PaymentMethod.cash,
    lines: lines,
  );

  test('buying stock raises stock by the quantities bought', () async {
    await ports.ledger.recordExpense(
      purchase([
        PurchaseLine(productId: bread, quantity: 10, unitCostNgwee: 2000),
        PurchaseLine(productId: sugar, quantity: 3, unitCostNgwee: 2800),
      ]),
    );
    expect(await stockOf(bread), 14);
    expect(await stockOf(sugar), 7);
  });

  test('the price paid per item is kept on each line', () async {
    final e = await ports.ledger.recordExpense(
      purchase([
        PurchaseLine(productId: bread, quantity: 10, unitCostNgwee: 2000),
      ]),
    );
    final line = await (db.select(
      db.entryItem,
    )..where((i) => i.entryId.equals(e.id))).getSingle();
    expect((line.quantity, line.unitPriceNgwee), (10, 2000));
    expect(e.amountNgwee, 20000);
  });

  test(
    'the trader may pay a different total than the lines add up to',
    () async {
      final e = await ports.ledger.recordExpense(
        purchase([
          PurchaseLine(productId: bread, quantity: 10, unitCostNgwee: 2000),
        ], amount: 18500),
      );
      expect(
        e.amountNgwee,
        18500,
        reason: 'a discount; the stock still rises by 10',
      );
      expect(await stockOf(bread), 14);
    },
  );

  test('only a stock purchase can list products', () async {
    await expectLater(
      ports.ledger.recordExpense(
        purchase([
          PurchaseLine(productId: bread, quantity: 1, unitCostNgwee: 2000),
        ], category: 'transport'),
      ),
      throwsArgumentError,
    );
  });

  test('bad lines are refused', () async {
    await expectLater(
      ports.ledger.recordExpense(
        purchase([
          PurchaseLine(productId: bread, quantity: 0, unitCostNgwee: 2000),
        ], amount: 1),
      ),
      throwsArgumentError,
    );
    await expectLater(
      ports.ledger.recordExpense(
        purchase([
          PurchaseLine(productId: bread, quantity: 1, unitCostNgwee: -1),
        ], amount: 1),
      ),
      throwsArgumentError,
    );
    await expectLater(
      ports.ledger.recordExpense(
        purchase([
          PurchaseLine(productId: bread, quantity: 1, unitCostNgwee: 100),
          PurchaseLine(productId: bread, quantity: 2, unitCostNgwee: 100),
        ]),
      ),
      throwsArgumentError,
    );
    await expectLater(
      ports.ledger.recordExpense(
        purchase([
          PurchaseLine(productId: 'nope', quantity: 1, unitCostNgwee: 100),
        ]),
      ),
      throwsArgumentError,
    );
    expect(await stockOf(bread), 4, reason: 'nothing was saved');
  });

  test(
    'a stock purchase without products is still an ordinary expense',
    () async {
      final e = await ports.ledger.recordExpense(
        purchase(const [], amount: 5000),
      );
      expect(e.amountNgwee, 5000);
      expect(await stockOf(bread), 4);
    },
  );

  test('cancelling a purchase takes the stock back out', () async {
    final e = await ports.ledger.recordExpense(
      purchase([
        PurchaseLine(productId: bread, quantity: 10, unitCostNgwee: 2000),
      ]),
    );
    await ports.ledger.cancelEntry(e.id);
    expect(await stockOf(bread), 4);
  });

  test(
    'a purchase whose stock has since been sold cannot be cancelled',
    () async {
      final e = await ports.ledger.recordExpense(
        purchase([
          PurchaseLine(productId: bread, quantity: 10, unitCostNgwee: 2000),
        ]),
      );
      await ports.ledger.recordSale(
        SaleDraft(
          amountNgwee: 0,
          description: '',
          categoryCode: 'sales_goods',
          method: PaymentMethod.cash,
          lines: [SaleLine(productId: bread, quantity: 8)],
        ),
      );
      expect(await stockOf(bread), 6);
      await expectLater(ports.ledger.cancelEntry(e.id), throwsStateError);
      expect(await stockOf(bread), 6, reason: 'nothing changed');
    },
  );

  test('totals count the purchase as money out', () async {
    await ports.ledger.recordExpense(
      purchase([
        PurchaseLine(productId: bread, quantity: 10, unitCostNgwee: 2000),
      ], amount: 18500),
    );
    final t = await ports.totals.watchDay(DateTime.now()).first;
    expect(t.outNgwee, 18500);
    expect(t.byCategory.single.categoryCode, 'stock');
  });
}
