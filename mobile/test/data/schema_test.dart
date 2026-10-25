// Chapter 3's schema tests (db/test_schema.py), run against the app's own
// database so the rules are proven where the app uses them.
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sfm_lcp/data/database.dart';

const int t = 1760000000000;

void main() {
  late AppDatabase db;

  Future<void> exec(String sql, [List<Object?> args = const []]) =>
      db.customStatement(sql, args);

  Future<List<QueryRow>> rows(String sql) => db.customSelect(sql).get();

  Matcher rejectedWith(String message) => throwsA(
    isA<SqliteException>().having(
      (e) => e.toString(),
      'message',
      contains(message),
    ),
  );

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await exec("INSERT INTO business VALUES ('b1', 'P0042', 'grocery', ?)", [
      t,
    ]);
    await exec(
      "INSERT INTO product VALUES ('p1', 'b1', 'Bread', 2500, 5, 1, ?, ?)",
      [t, t],
    );
    await exec(
      "INSERT INTO stock_adjustment VALUES ('a1', 'p1', 10, 'opening', ?)",
      [t],
    );
    // FR1: a sale of 3 loaves at K25.
    await exec(
      'INSERT INTO ledger_entry (id, business_id, entry_type, amount_ngwee, description, payment_method, '
      'final_category, occurred_at, created_at, updated_at) '
      "VALUES ('e1', 'b1', 'sale', 7500, '', 'cash', 'sales_goods', ?, ?, ?)",
      [t, t, t],
    );
    await exec("INSERT INTO entry_item VALUES ('i1', 'e1', 'p1', 3, 2500)");
    // FR2/FR3: an expense with a stored prediction.
    await exec(
      'INSERT INTO ledger_entry (id, business_id, entry_type, amount_ngwee, description, predicted_category, '
      'category_confidence, final_category, model_version, anomaly_score, anomaly_flag, occurred_at, created_at, updated_at) '
      "VALUES ('e2', 'b1', 'expense', 1000, 'airtime mtn', 'airtime', 0.91, 'airtime', 'lr-1.0', 0.42, 0, ?, ?, ?)",
      [t, t, t],
    );
  });

  tearDown(() => db.close());

  test('the codebook is seeded on creation', () async {
    expect(await rows('SELECT code FROM category'), hasLength(11));
  });

  test('stock is derived: 10 opening − 3 sold = 7', () async {
    final r = await rows('SELECT name, stock_qty FROM v_stock_level');
    expect(r.single.read<String>('name'), 'Bread');
    expect(r.single.read<int>('stock_qty'), 7);
  });

  test('daily summary: 7500 in, 1000 out, 6500 profit', () async {
    final r = (await rows('SELECT * FROM v_daily_summary')).single;
    expect(r.read<int>('income_ngwee'), 7500);
    expect(r.read<int>('expense_ngwee'), 1000);
    expect(r.read<int>('profit_ngwee'), 6500);
  });

  test('an expense needs a description', () async {
    await expectLater(
      exec(
        'INSERT INTO ledger_entry (id, business_id, entry_type, amount_ngwee, description, final_category, '
        "occurred_at, created_at, updated_at) VALUES ('x', 'b1', 'expense', 500, '  ', 'stock', 1, 1, 1)",
      ),
      rejectedWith('CHECK constraint failed'),
    );
  });

  test('an original entry cannot have a negative amount', () async {
    await expectLater(
      exec(
        'INSERT INTO ledger_entry (id, business_id, entry_type, amount_ngwee, final_category, occurred_at, '
        "created_at, updated_at) VALUES ('x', 'b1', 'sale', -5, 'sales_goods', 1, 1, 1)",
      ),
      rejectedWith('CHECK constraint failed'),
    );
  });

  test('a sale cannot use an expense category', () async {
    await expectLater(
      exec(
        'INSERT INTO ledger_entry (id, business_id, entry_type, amount_ngwee, final_category, occurred_at, '
        "created_at, updated_at) VALUES ('x', 'b1', 'sale', 500, 'airtime', 1, 1, 1)",
      ),
      rejectedWith('category kind does not match entry type'),
    );
  });

  test('a prediction is stored with its confidence or not at all', () async {
    await expectLater(
      exec(
        'INSERT INTO ledger_entry (id, business_id, entry_type, amount_ngwee, description, predicted_category, '
        "final_category, occurred_at, created_at, updated_at) VALUES ('x', 'b1', 'expense', 500, 'bus', 'stock', 'stock', 1, 1, 1)",
      ),
      rejectedWith('CHECK constraint failed'),
    );
  });

  test('ledger entries cannot be deleted', () async {
    await expectLater(
      exec("DELETE FROM ledger_entry WHERE id = 'e1'"),
      rejectedWith('append-only'),
    );
  });

  test('financial fields cannot be edited', () async {
    await expectLater(
      exec("UPDATE ledger_entry SET amount_ngwee = 1 WHERE id = 'e1'"),
      rejectedWith('financial fields are immutable'),
    );
  });

  group('reversal (FR12)', () {
    test('a reversal must cancel the original exactly', () async {
      await expectLater(
        exec(
          'INSERT INTO ledger_entry (id, business_id, entry_type, amount_ngwee, final_category, reverses_id, '
          "occurred_at, created_at, updated_at) VALUES ('r0', 'b1', 'sale', -100, 'sales_goods', 'e1', 1, 1, 1)",
        ),
        rejectedWith('reversal must cancel the original exactly'),
      );
    });

    test(
      'an exact reversal with its item lines restores stock, and only once',
      () async {
        await exec(
          'INSERT INTO ledger_entry (id, business_id, entry_type, amount_ngwee, final_category, reverses_id, '
          "occurred_at, created_at, updated_at) VALUES ('r1', 'b1', 'sale', -7500, 'sales_goods', 'e1', ?, ?, ?)",
          [t, t, t],
        );
        await exec(
          "INSERT INTO entry_item VALUES ('ri1', 'r1', 'p1', -3, 2500)",
        );
        expect(
          (await rows(
            'SELECT stock_qty FROM v_stock_level',
          )).single.read<int>('stock_qty'),
          10,
        );

        await expectLater(
          exec(
            'INSERT INTO ledger_entry (id, business_id, entry_type, amount_ngwee, final_category, reverses_id, '
            "occurred_at, created_at, updated_at) VALUES ('r2', 'b1', 'sale', -7500, 'sales_goods', 'e1', 1, 1, 1)",
          ),
          rejectedWith('UNIQUE constraint failed'),
        );
      },
    );
  });

  test('the category of a saved entry can be corrected', () async {
    await exec(
      "UPDATE ledger_entry SET final_category = 'stock', updated_at = ? WHERE id = 'e2'",
      [t + 1],
    );
    final r = await rows(
      "SELECT final_category FROM ledger_entry WHERE id = 'e2'",
    );
    expect(r.single.read<String>('final_category'), 'stock');
  });

  test('every change is queued in the outbox by the triggers', () async {
    await exec(
      "UPDATE ledger_entry SET final_category = 'stock', updated_at = ? WHERE id = 'e2'",
      [t + 1],
    );
    await exec(
      "UPDATE product SET unit_price_ngwee = 2700, updated_at = ? WHERE id = 'p1'",
      [t + 2],
    );
    final r = await rows(
      'SELECT entity_table, operation, COUNT(*) AS n FROM sync_record GROUP BY 1, 2 ORDER BY 1, 2',
    );
    expect(
      [
        for (final x in r)
          '${x.read<String>('entity_table')} ${x.read<String>('operation')} ${x.read<int>('n')}',
      ],
      [
        'business insert 1',
        'entry_item insert 1',
        'ledger_entry insert 2',
        'ledger_entry update 1',
        'product insert 1',
        'product update 1',
        'stock_adjustment insert 1',
      ],
    );
  });

  test('an outbox row cannot be acknowledged without a timestamp', () async {
    await expectLater(
      exec("UPDATE sync_record SET status = 'acked' WHERE id = 1"),
      rejectedWith('CHECK constraint failed'),
    );
  });
}
