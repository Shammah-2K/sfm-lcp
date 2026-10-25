// What the sync badge counts, and that it updates live.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sfm_lcp/app/app_ports.dart';
import 'package:sfm_lcp/app/ports.dart';
import 'package:sfm_lcp/app/view_data.dart';
import 'package:sfm_lcp/data/database.dart';

void main() {
  late AppDatabase db;
  late AppPorts ports;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    ports = buildAppPorts(db);
    await ports.session.start('LSK01');
  });

  tearDown(() => db.close());

  Future<int> waiting() async => (await ports.sync.watch().first).waiting;

  const sale = SaleDraft(
    amountNgwee: 5000,
    description: '',
    categoryCode: 'sales_goods',
    method: PaymentMethod.cash,
  );

  test('the badge updates live when an entry is saved', () async {
    final seen = <int>[];
    final sub = ports.sync.watch().listen((s) => seen.add(s.waiting));
    await pumpEventQueue();
    await ports.ledger.recordSale(sale);
    await pumpEventQueue();
    await sub.cancel();
    expect(seen.last, seen.first + 1);
  });

  test('a quick sale of three products counts as one record', () async {
    for (final name in ['Bread', 'Sugar', 'Salt']) {
      await ports.stock.saveProduct(
        ProductDraft(
          name: name,
          priceNgwee: 1000,
          reorderLevel: 1,
          openingStock: 5,
        ),
      );
    }
    final ids = [for (final p in await ports.stock.watchProducts().first) p.id];
    final before = await waiting();
    await ports.ledger.recordSale(
      SaleDraft(
        amountNgwee: 0,
        description: '',
        categoryCode: 'sales_goods',
        method: PaymentMethod.cash,
        lines: [for (final id in ids) SaleLine(productId: id, quantity: 1)],
      ),
    );
    expect(await waiting(), before + 1);
  });

  test('changing an unsent entry twice still counts it once', () async {
    final e = await ports.ledger.recordExpense(
      const ExpenseDraft(
        amountNgwee: 2500,
        description: 'bus',
        categoryCode: 'transport',
        method: PaymentMethod.cash,
      ),
    );
    final before = await waiting();
    await ports.ledger.changeCategory(e.id, 'food');
    await ports.ledger.changeCategory(e.id, 'transport');
    expect(await waiting(), before);
  });

  test('acknowledged records are not counted; failed ones are', () async {
    await ports.ledger.recordSale(sale);
    final before = await waiting();
    final ids =
        (await db
                .customSelect(
                  "SELECT id FROM sync_record WHERE entity_table = 'ledger_entry'",
                )
                .get())
            .map((r) => r.read<int>('id'));
    // Written through Drift with `updates`, as the sync worker will, so live
    // queries are told the outbox changed.
    await db.customUpdate(
      "UPDATE sync_record SET status = 'acked', acked_at = 1792994400000 WHERE id IN (${ids.join(',')})",
      updates: {db.syncRecord},
    );
    expect(await waiting(), before - 1);
    final s = await ports.sync.watch().first;
    expect(
      s.lastSyncedAt,
      DateTime.fromMillisecondsSinceEpoch(1792994400000, isUtc: true),
    );

    await ports.ledger.recordSale(sale);
    await db.customUpdate(
      "UPDATE sync_record SET status = 'failed', attempts = 1 WHERE status = 'pending' AND entity_table = 'ledger_entry'",
      updates: {db.syncRecord},
    );
    expect(
      await waiting(),
      before,
      reason: 'a failed record is still waiting to be sent',
    );
  });

  test('the participant record counts until it is sent', () async {
    expect(await waiting(), 1);
  });
}
