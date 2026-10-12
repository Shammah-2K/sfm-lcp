import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sfm_lcp_prototype/data/database.dart' hide LedgerEntry;
import 'package:sfm_lcp_prototype/data/ledger_repository.dart';
import 'package:sfm_lcp_prototype/data/session.dart';
import 'package:sfm_lcp_prototype/domain/ledger.dart';
import 'package:sfm_lcp_prototype/ml/categoriser.dart';

void main() {
  late AppDatabase db;
  late LedgerRepository repo;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    final business = await Session(db).start('TEST01');
    repo = LedgerRepository(db, business.businessId);
  });

  tearDown(() => db.close());

  const suggestion = Suggestion(
    categoryCode: 'transport',
    confidence: 0.87,
    top3: [ScoredCategory('transport', 0.87)],
    modelVersion: 'proto-lr-1',
    preselect: true,
    elapsedMicros: 2300,
  );

  test('seeds the 11 categories on creation', () async {
    expect(await db.select(db.category).get(), hasLength(11));
  });

  test(
    'an expense saves with prediction fields and creates exactly one pending sync_record',
    () async {
      final entry = await repo.recordExpense(
        amountNgwee: 2500,
        description: 'bus fare to Matero',
        method: PaymentMethod.cash,
        finalCategory: 'transport',
        suggestion: suggestion,
      );

      final row = await (db.select(
        db.ledgerEntry,
      )..where((e) => e.id.equals(entry.id))).getSingle();
      expect(row.entryType, 'expense');
      expect(row.amountNgwee, 2500);
      expect(row.predictedCategory, 'transport');
      expect(row.categoryConfidence, 0.87);
      expect(row.modelVersion, 'proto-lr-1');
      expect(row.finalCategory, 'transport');
      expect(row.occurredAt, row.createdAt);
      expect(row.createdAt, row.updatedAt);

      final queued = await (db.select(
        db.syncRecord,
      )..where((s) => s.entityId.equals(entry.id))).get();
      expect(queued, hasLength(1));
      expect(queued.single.entityTable, 'ledger_entry');
      expect(queued.single.operation, 'insert');
      expect(queued.single.status, 'pending');
    },
  );

  test(
    'an expense with a blank description is rejected by the database',
    () async {
      await expectLater(
        repo.recordExpense(
          amountNgwee: 1000,
          description: '   ',
          method: PaymentMethod.cash,
          finalCategory: 'food',
        ),
        throwsA(isA<SqliteException>()),
      );
      expect(await db.select(db.ledgerEntry).get(), isEmpty);
    },
  );

  test(
    'a sale with no description saves as sales_goods with no prediction',
    () async {
      final entry = await repo.recordSale(
        amountNgwee: 5000,
        method: PaymentMethod.mobileMoney,
      );
      expect(entry.finalCategory, 'sales_goods');
      expect(entry.description, '');
      expect(entry.paymentMethod, PaymentMethod.mobileMoney);
      expect(entry.predictedCategory, isNull);
      expect(entry.categoryConfidence, isNull);
      expect(entry.modelVersion, isNull);
    },
  );

  test('DELETE on ledger_entry throws (append-only trigger)', () async {
    await repo.recordSale(amountNgwee: 5000, method: PaymentMethod.cash);
    await expectLater(
      db.delete(db.ledgerEntry).go(),
      throwsA(
        isA<SqliteException>().having(
          (e) => e.message,
          'message',
          contains('append-only'),
        ),
      ),
    );
    expect(await db.select(db.ledgerEntry).get(), hasLength(1));
  });

  test(
    'a sale with an expense category is rejected (category-kind trigger)',
    () async {
      await expectLater(
        repo.recordSale(
          amountNgwee: 5000,
          method: PaymentMethod.cash,
          finalCategory: 'airtime',
        ),
        throwsA(
          isA<SqliteException>().having(
            (e) => e.message,
            'message',
            contains('category kind'),
          ),
        ),
      );
    },
  );

  test(
    'watchRecent lists newest first and watchPendingSyncCount follows the outbox',
    () async {
      var tick = DateTime.utc(2026, 10, 13, 8);
      repo = LedgerRepository(
        db,
        repo.businessId,
        clock: () => tick = tick.add(const Duration(minutes: 1)),
      );
      await repo.recordSale(amountNgwee: 100, method: PaymentMethod.cash);
      await repo.recordExpense(
        amountNgwee: 200,
        description: 'lunch',
        method: PaymentMethod.cash,
        finalCategory: 'food',
      );

      final recent = await repo.watchRecent().first;
      expect(recent.map((v) => v.entry.amountNgwee), [200, 100]);
      expect(recent.first.category.code, 'food');
      expect(recent.last.label, 'Sales of goods');
      // business row + two ledger entries
      expect(await repo.watchPendingSyncCount().first, 3);
    },
  );
}
