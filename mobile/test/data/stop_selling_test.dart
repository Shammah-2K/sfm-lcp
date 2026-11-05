// Editing a product and "Stop selling" (UC9, data dictionary: product.is_active).
import 'package:drift/drift.dart' show Variable;
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
          openingStock: 6,
        ),
      );
    }
    bread = (await ports.stock.watchProducts().first)
        .firstWhere((p) => p.name == 'Bread')
        .id;
  });

  tearDown(() => db.close());

  Future<List<String>> names() async => [
    for (final p in await ports.stock.watchProducts().first) p.name,
  ];

  SaleDraft sale(String id) => SaleDraft(
    amountNgwee: 0,
    description: '',
    categoryCode: 'sales_goods',
    method: PaymentMethod.cash,
    lines: [SaleLine(productId: id, quantity: 1)],
  );

  ExpenseDraft purchase(String id) => ExpenseDraft(
    amountNgwee: 2000,
    description: 'Stock',
    categoryCode: 'stock',
    method: PaymentMethod.cash,
    lines: [PurchaseLine(productId: id, quantity: 1, unitCostNgwee: 2000)],
  );

  test('editing changes name, price and reorder level but not stock', () async {
    await ports.stock.saveProduct(
      ProductDraft(
        id: bread,
        name: 'Bread loaf',
        priceNgwee: 2800,
        reorderLevel: 4,
        openingStock: 0,
      ),
    );
    final p = (await ports.stock.watchProduct(bread).first)!;
    expect(
      (p.name, p.priceNgwee, p.reorderLevel, p.inStock),
      ('Bread loaf', 2800, 4, 6),
    );
  });

  test('a new price applies to new sales only', () async {
    final before = await ports.ledger.recordSale(sale(bread));
    await ports.stock.saveProduct(
      ProductDraft(
        id: bread,
        name: 'Bread',
        priceNgwee: 3000,
        reorderLevel: 2,
        openingStock: 0,
      ),
    );
    final after = await ports.ledger.recordSale(sale(bread));
    expect((before.amountNgwee, after.amountNgwee), (2500, 3000));
  });

  test('a name already in the list is refused, on add and on edit', () async {
    await expectLater(
      ports.stock.saveProduct(
        const ProductDraft(
          name: 'Sugar',
          priceNgwee: 100,
          reorderLevel: 0,
          openingStock: 0,
        ),
      ),
      throwsA(isA<DuplicateProductName>()),
    );
    await expectLater(
      ports.stock.saveProduct(
        ProductDraft(
          id: bread,
          name: 'Sugar',
          priceNgwee: 100,
          reorderLevel: 0,
          openingStock: 0,
        ),
      ),
      throwsA(isA<DuplicateProductName>()),
    );
  });

  test('stop selling hides the product and deletes nothing', () async {
    await ports.ledger.recordSale(sale(bread));
    await ports.stock.stopSelling(bread);

    expect(await names(), ['Sugar']);
    expect(await ports.stock.watchProduct(bread).first, isNull);
    final row = await (db.select(
      db.product,
    )..where((p) => p.id.equals(bread))).getSingle();
    expect(row.isActive, 0);
    expect(
      await db.select(db.entryItem).get(),
      hasLength(1),
      reason: 'the sale still points at it',
    );
    expect(
      (await ports.ledger.watchToday().first),
      hasLength(1),
      reason: 'the sale still shows on Today',
    );
  });

  test('a stopped product cannot be sold or bought', () async {
    await ports.stock.stopSelling(bread);
    await expectLater(
      ports.ledger.recordSale(sale(bread)),
      throwsArgumentError,
    );
    await expectLater(
      ports.ledger.recordExpense(purchase(bread)),
      throwsArgumentError,
    );
  });

  test('stopping is sent with the next sync', () async {
    await ports.stock.stopSelling(bread);
    final pending = await db
        .customSelect(
          "SELECT COUNT(*) AS n FROM sync_record WHERE entity_table = 'product' "
          "AND entity_id = ? AND operation = 'update'",
          variables: [Variable(bread)],
        )
        .getSingle();
    expect(pending.read<int>('n'), 1);
  });

  test(
    'a purchase of a product since stopped can still be cancelled',
    () async {
      final e = await ports.ledger.recordExpense(purchase(bread));
      await ports.stock.stopSelling(bread);
      await ports.ledger.cancelEntry(e.id);
      final today = await ports.ledger.watchToday().first;
      expect(today.single.cancelled, isTrue);
    },
  );

  test(
    'adding the same name again brings it back with the count given',
    () async {
      await ports.ledger.recordSale(sale(bread));
      await ports.stock.stopSelling(bread);
      await ports.stock.saveProduct(
        const ProductDraft(
          name: 'Bread',
          priceNgwee: 2700,
          reorderLevel: 3,
          openingStock: 10,
        ),
      );
      final p = (await ports.stock.watchProduct(bread).first)!;
      expect((p.priceNgwee, p.reorderLevel, p.inStock), (2700, 3, 10));
      expect(await names(), ['Bread', 'Sugar']);
    },
  );
}
