// The rules of the data layer, one named test each. Every test runs against
// the real schema in an in-memory database with a controllable clock.
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sfm_lcp/app/app_ports.dart';
import 'package:sfm_lcp/app/ports.dart';
import 'package:sfm_lcp/app/view_data.dart';
import 'package:sfm_lcp/data/database.dart';
import 'package:sfm_lcp/data/lusaka_time.dart';
import 'package:sfm_lcp/domain/models.dart';

/// Flags any expense above K100 and says airtime usually costs K20.
class FakeDetector implements AnomalyDetector {
  final List<List<HistoryItem>> seenHistories = [];

  @override
  Future<AnomalyResult?> score(
    EntryCandidate entry,
    List<HistoryItem> history,
  ) async {
    seenHistories.add(history);
    return AnomalyResult(
      score: entry.amountNgwee / 10000,
      flagged: entry.amountNgwee > 10000,
    );
  }

  @override
  int? typicalNgwee(String categoryCode, List<HistoryItem> history) =>
      categoryCode == 'airtime' ? 2000 : null;
}

void main() {
  late AppDatabase db;
  late AppPorts ports;
  late FakeDetector detector;
  // 08:00 in Lusaka on Monday 26 October 2026.
  var now = DateTime.utc(2026, 10, 26, 6);

  setUp(() async {
    now = DateTime.utc(2026, 10, 26, 6);
    db = AppDatabase(NativeDatabase.memory());
    detector = FakeDetector();
    ports = buildAppPorts(db, detector: detector, clock: () => now);
    await ports.session.start('LSK01');
  });

  tearDown(() => db.close());

  Future<int> count(String sql) async =>
      (await db.customSelect(sql).getSingle()).read<int>('n');

  ExpenseDraft expense(
    int ngwee,
    String text,
    String category, {
    Suggestion? s,
  }) => ExpenseDraft(
    amountNgwee: ngwee,
    description: text,
    categoryCode: category,
    method: PaymentMethod.cash,
    suggestion: s,
  );

  SaleDraft sale(
    int ngwee, {
    String category = 'sales_goods',
    String text = '',
  }) => SaleDraft(
    amountNgwee: ngwee,
    description: text,
    categoryCode: category,
    method: PaymentMethod.mobileMoney,
  );

  group('session (FR11)', () {
    test('the participant code is saved and read back', () async {
      expect(await ports.session.currentParticipant(), 'LSK01');
    });

    test('a phone has one participant only', () async {
      await expectLater(ports.session.start('OTHER1'), throwsStateError);
    });

    test('a malformed code is refused', () async {
      final fresh = buildAppPorts(AppDatabase(NativeDatabase.memory()));
      await expectLater(fresh.session.start('ab'), throwsArgumentError);
      await expectLater(fresh.session.start('lsk01'), throwsArgumentError);
    });
  });

  group('recording (FR1, FR2, FR3)', () {
    test(
      'an expense is saved with its prediction and queued for sync once',
      () async {
        const s = Suggestion(
          top: [
            ScoredCategory('transport', 0.97),
            ScoredCategory('food', 0.02),
          ],
          preselect: true,
          modelVersion: 'lr-1',
        );
        final e = await ports.ledger.recordExpense(
          expense(2500, ' bus fare ', 'transport', s: s),
        );

        final row = await (db.select(
          db.ledgerEntry,
        )..where((x) => x.id.equals(e.id))).getSingle();
        expect(row.description, 'bus fare', reason: 'trimmed');
        expect(row.predictedCategory, 'transport');
        expect(row.categoryConfidence, 0.97);
        expect(row.modelVersion, 'lr-1');
        expect(row.finalCategory, 'transport');
        expect(
          await count(
            "SELECT COUNT(*) AS n FROM sync_record WHERE entity_id = '${e.id}' AND status = 'pending'",
          ),
          1,
        );
      },
    );

    test('without a suggestion no prediction is stored', () async {
      final e = await ports.ledger.recordSale(sale(5000));
      final row = await (db.select(
        db.ledgerEntry,
      )..where((x) => x.id.equals(e.id))).getSingle();
      expect(row.predictedCategory, isNull);
      expect(row.categoryConfidence, isNull);
      expect(row.modelVersion, isNull);
      expect(row.paymentMethod, 'mobile_money');
    });

    test('an expense needs a description', () async {
      await expectLater(
        ports.ledger.recordExpense(expense(500, '  ', 'food')),
        throwsArgumentError,
      );
      expect(await count('SELECT COUNT(*) AS n FROM ledger_entry'), 0);
    });

    test('the amount must be above zero', () async {
      await expectLater(ports.ledger.recordSale(sale(0)), throwsArgumentError);
    });

    test(
      'a sale cannot take an expense category, nor an expense an income one',
      () async {
        await expectLater(
          ports.ledger.recordSale(sale(500, category: 'airtime')),
          throwsArgumentError,
        );
        await expectLater(
          ports.ledger.recordExpense(expense(500, 'x', 'sales_goods')),
          throwsArgumentError,
        );
      },
    );
  });

  group('today (FR1, FR2)', () {
    test('lists only today in Lusaka time, newest first', () async {
      now = DateTime.utc(2026, 10, 25, 21, 30); // 23:30 Sunday in Lusaka
      await ports.ledger.recordSale(sale(100));
      now = DateTime.utc(2026, 10, 25, 22, 30); // 00:30 Monday in Lusaka
      await ports.ledger.recordSale(sale(200));
      now = DateTime.utc(2026, 10, 26, 6);
      await ports.ledger.recordSale(sale(300));

      final today = await ports.ledger.watchToday().first;
      expect(today.map((e) => e.amountNgwee), [300, 200]);
    });

    test('updates when an entry is saved', () async {
      final stream = ports.ledger.watchToday();
      final seen = <int>[];
      final sub = stream.listen((l) => seen.add(l.length));
      await pumpEventQueue();
      await ports.ledger.recordSale(sale(100));
      await pumpEventQueue();
      await sub.cancel();
      expect(seen, [0, 1]);
    });
  });

  group('cancelling (FR12)', () {
    test(
      'posts an exact reversal on the original day and marks the original cancelled',
      () async {
        final e = await ports.ledger.recordExpense(
          expense(2500, 'bus', 'transport'),
        );
        now = now.add(const Duration(hours: 3));
        await ports.ledger.cancelEntry(e.id);

        final reversal = await (db.select(
          db.ledgerEntry,
        )..where((x) => x.reversesId.equals(e.id))).getSingle();
        expect(reversal.amountNgwee, -2500);
        expect(reversal.entryType, 'expense');
        expect(
          reversal.occurredAt,
          e.occurredAt.millisecondsSinceEpoch,
          reason: 'corrects the original day',
        );

        final today = await ports.ledger.watchToday().first;
        expect(
          today,
          hasLength(1),
          reason: 'the reversal row itself is not listed',
        );
        expect(today.single.cancelled, isTrue);
      },
    );

    test('an entry can be cancelled only once, and a reversal never', () async {
      final e = await ports.ledger.recordSale(sale(100));
      await ports.ledger.cancelEntry(e.id);
      await expectLater(ports.ledger.cancelEntry(e.id), throwsA(anything));
      final reversalId = (await (db.select(
        db.ledgerEntry,
      )..where((x) => x.reversesId.equals(e.id))).getSingle()).id!;
      await expectLater(ports.ledger.cancelEntry(reversalId), throwsStateError);
    });

    test(
      'nothing is deleted: both rows stay and both are queued for sync',
      () async {
        final e = await ports.ledger.recordSale(sale(100));
        await ports.ledger.cancelEntry(e.id);
        expect(await count('SELECT COUNT(*) AS n FROM ledger_entry'), 2);
        expect(
          await count(
            "SELECT COUNT(*) AS n FROM sync_record WHERE entity_table = 'ledger_entry'",
          ),
          2,
        );
      },
    );
  });

  group('changing the category (FR3)', () {
    test('is allowed within the same kind and queued as an update', () async {
      final e = await ports.ledger.recordExpense(
        expense(2500, 'bus', 'transport'),
      );
      await ports.ledger.changeCategory(e.id, 'food');
      expect((await ports.ledger.watchEntry(e.id).first)!.categoryCode, 'food');
      expect(
        await count(
          "SELECT COUNT(*) AS n FROM sync_record WHERE operation = 'update'",
        ),
        1,
      );
    });

    test(
      'is refused across kinds (the schema only checks this on insert)',
      () async {
        final e = await ports.ledger.recordSale(sale(100));
        await expectLater(
          ports.ledger.changeCategory(e.id, 'airtime'),
          throwsArgumentError,
        );
      },
    );
  });

  group('unusual entries (FR4)', () {
    test(
      'a flagged entry asks "Is this right?" with the usual amount, until answered',
      () async {
        await ports.ledger.recordExpense(expense(2000, 'MTN', 'airtime'));
        final big = await ports.ledger.recordExpense(
          expense(250000, 'MTN airtime', 'airtime'),
        );

        final check = await ports.ledger.watchNeedsCheck().first;
        expect(check!.entry.id, big.id);
        expect(check.usualNgwee, 2000);
        expect(
          (await ports.ledger.watchEntry(big.id).first)!.needsCheck,
          isTrue,
        );

        await ports.ledger.confirmUnusual(big.id);
        expect(await ports.ledger.watchNeedsCheck().first, isNull);
      },
    );

    test('a cancelled entry no longer needs checking', () async {
      final big = await ports.ledger.recordExpense(
        expense(250000, 'MTN airtime', 'airtime'),
      );
      await ports.ledger.cancelEntry(big.id);
      expect(await ports.ledger.watchNeedsCheck().first, isNull);
    });

    test('the detector sees earlier entries but not cancelled ones', () async {
      final a = await ports.ledger.recordSale(sale(100));
      await ports.ledger.recordSale(sale(200));
      await ports.ledger.cancelEntry(a.id);
      now = now.add(const Duration(minutes: 1));
      await ports.ledger.recordSale(sale(300));
      expect(detector.seenHistories.last.map((h) => h.amountNgwee), [200]);
    });

    test('with no model nothing is flagged', () async {
      final plain = buildAppPorts(db, clock: () => now);
      await plain.ledger.recordExpense(expense(999999, 'big', 'stock'));
      expect(await plain.ledger.watchNeedsCheck().first, isNull);
    });
  });

  group('totals (FR5)', () {
    test(
      'day totals are net of cancellations and match v_daily_summary',
      () async {
        await ports.ledger.recordSale(
          sale(8000, category: 'sales_service', text: 'braiding'),
        );
        await ports.ledger.recordSale(sale(5000));
        final wrong = await ports.ledger.recordExpense(
          expense(12000, 'tomatoes', 'stock'),
        );
        await ports.ledger.recordExpense(expense(2500, 'bus', 'transport'));
        await ports.ledger.cancelEntry(wrong.id);

        final t = await ports.totals.watchDay(now).first;
        expect(t.inNgwee, 13000);
        expect(t.outNgwee, 2500);
        expect(t.profitNgwee, 10500);
        expect(t.inCount, 2);
        expect(t.outCount, 1, reason: 'the cancelled expense is not counted');
        expect(
          {
            for (final c in t.byCategory)
              c.categoryCode: (c.amountNgwee, c.count),
          },
          {
            'sales_service': (8000, 1),
            'sales_goods': (5000, 1),
            'transport': (2500, 1),
          },
        );

        final view = await db
            .customSelect(
              'SELECT income_ngwee, expense_ngwee, profit_ngwee FROM v_daily_summary WHERE day = ?',
              variables: [Variable(lusakaDateKey(lusakaDay(now)))],
            )
            .getSingle();
        expect(
          [
            view.read<int>('income_ngwee'),
            view.read<int>('expense_ngwee'),
            view.read<int>('profit_ngwee'),
          ],
          [t.inNgwee, t.outNgwee, t.profitNgwee],
        );
      },
    );

    test('a week runs Monday to Sunday in Lusaka', () async {
      now = DateTime.utc(2026, 10, 25, 21, 30); // Sunday 23:30, previous week
      await ports.ledger.recordSale(sale(100));
      now = DateTime.utc(2026, 10, 26, 6); // Monday
      await ports.ledger.recordSale(sale(200));
      now = DateTime.utc(2026, 11, 1, 21); // Sunday 23:00, same week
      await ports.ledger.recordSale(sale(300));
      now = DateTime.utc(2026, 11, 1, 22); // Monday 00:00, next week
      await ports.ledger.recordSale(sale(400));

      final week = await ports.totals
          .watchWeek(DateTime.utc(2026, 10, 28))
          .first;
      expect(week.inNgwee, 500);
      expect(week.start, DateTime.utc(2026, 10, 25, 22));
    });

    test('an empty day is all zeros', () async {
      final t = await ports.totals.watchDay(DateTime.utc(2026, 1, 1)).first;
      expect(
        [t.inNgwee, t.outNgwee, t.profitNgwee, t.byCategory.length],
        [0, 0, 0, 0],
      );
    });
  });

  group('stock (FR7)', () {
    test(
      'a new product starts with its opening stock and low-stock comes from v_low_stock',
      () async {
        await ports.stock.saveProduct(
          const ProductDraft(
            name: 'Bread',
            priceNgwee: 2500,
            reorderLevel: 5,
            openingStock: 12,
          ),
        );
        await ports.stock.saveProduct(
          const ProductDraft(
            name: 'Cooking oil 2L',
            priceNgwee: 9500,
            reorderLevel: 5,
            openingStock: 3,
          ),
        );
        final products = await ports.stock.watchProducts().first;
        expect(products.map((p) => (p.name, p.inStock, p.isLow)), [
          ('Bread', 12, false),
          ('Cooking oil 2L', 3, true),
        ]);
      },
    );

    test('adjustments change stock but never below zero', () async {
      await ports.stock.saveProduct(
        const ProductDraft(
          name: 'Bread',
          priceNgwee: 2500,
          reorderLevel: 5,
          openingStock: 12,
        ),
      );
      final bread = (await ports.stock.watchProducts().first).single;
      await ports.stock.adjust(
        StockAdjustmentDraft(
          productId: bread.id,
          delta: 6,
          reason: AdjustReason.count,
        ),
      );
      expect((await ports.stock.watchProduct(bread.id).first)!.inStock, 18);
      await expectLater(
        ports.stock.adjust(
          StockAdjustmentDraft(
            productId: bread.id,
            delta: -19,
            reason: AdjustReason.damage,
          ),
        ),
        throwsArgumentError,
      );
    });

    test(
      'editing a product keeps its stock and is queued as an update',
      () async {
        await ports.stock.saveProduct(
          const ProductDraft(
            name: 'Bread',
            priceNgwee: 2500,
            reorderLevel: 5,
            openingStock: 12,
          ),
        );
        final bread = (await ports.stock.watchProducts().first).single;
        await ports.stock.saveProduct(
          ProductDraft(
            id: bread.id,
            name: 'Bread',
            priceNgwee: 2700,
            reorderLevel: 5,
            openingStock: 0,
          ),
        );
        final after = (await ports.stock.watchProducts().first).single;
        expect((after.priceNgwee, after.inStock), (2700, 12));
        expect(
          await count(
            "SELECT COUNT(*) AS n FROM sync_record WHERE entity_table = 'product' AND operation = 'update'",
          ),
          1,
        );
      },
    );
  });

  group('quick sale (FR6)', () {
    Future<String> bread() async {
      await ports.stock.saveProduct(
        const ProductDraft(
          name: 'Bread',
          priceNgwee: 2500,
          reorderLevel: 5,
          openingStock: 12,
        ),
      );
      return (await ports.stock.watchProducts().first).single.id;
    }

    test(
      '3 loaves at K25: the ledger prices the lines and stock drops by 3 (T1)',
      () async {
        final id = await bread();
        final e = await ports.ledger.recordSale(
          SaleDraft(
            amountNgwee:
                1, // whatever the screen sent, the ledger prices the lines
            description: '3 × Bread',
            categoryCode: 'sales_goods',
            method: PaymentMethod.cash,
            lines: [SaleLine(productId: id, quantity: 3)],
          ),
        );
        expect(e.amountNgwee, 7500);
        expect((await ports.stock.watchProduct(id).first)!.inStock, 9);
      },
    );

    test('cancelling a quick sale puts the stock back', () async {
      final id = await bread();
      final e = await ports.ledger.recordSale(
        SaleDraft(
          amountNgwee: 7500,
          description: '',
          categoryCode: 'sales_goods',
          method: PaymentMethod.cash,
          lines: [SaleLine(productId: id, quantity: 3)],
        ),
      );
      await ports.ledger.cancelEntry(e.id);
      expect((await ports.stock.watchProduct(id).first)!.inStock, 12);
    });

    test('cannot sell more than is in stock', () async {
      final id = await bread();
      await expectLater(
        ports.ledger.recordSale(
          SaleDraft(
            amountNgwee: 0,
            description: '',
            categoryCode: 'sales_goods',
            method: PaymentMethod.cash,
            lines: [SaleLine(productId: id, quantity: 13)],
          ),
        ),
        throwsArgumentError,
      );
    });
  });

  test('the sync badge counts everything not yet acknowledged (FR9)', () async {
    await ports.ledger.recordSale(sale(100));
    final s = await ports.sync.watch().first;
    expect(s.waiting, 2, reason: 'the business row and the sale');
    expect(s.lastSyncedAt, isNull);
  });
}
