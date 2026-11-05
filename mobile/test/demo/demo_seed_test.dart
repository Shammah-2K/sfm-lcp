// The demo seed, on a real database with the bundled models.
import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sfm_lcp/app/app_ports.dart';
import 'package:sfm_lcp/app/ports.dart';
import 'package:sfm_lcp/data/database.dart';
import 'package:sfm_lcp/demo/demo_seed.dart';
import 'package:sfm_lcp/domain/isolation_forest_detector.dart';
import 'package:sfm_lcp/domain/tfidf_categoriser.dart';

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void main() {
  late AppDatabase db;
  late AppPorts ports;
  late DemoClock clock;
  int? flaggedInHistory;
  final today = DateTime(2026, 11, 10, 14);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    clock = DemoClock();
    ports = buildAppPorts(
      db,
      categoriser: TfidfCategoriser.fromJson(_json(categoriserAsset)),
      detector: IsolationForestDetector.fromJson(_json(detectorAsset)),
      // "Now" is fixed at the demo's today once seeding is over.
      clock: () => clock.at ?? today,
    );
    flaggedInHistory = await seedDemo(ports, clock, today: today);
    expect(flaggedInHistory, isNotNull);
  });

  tearDown(() => db.close());

  test('the demo trader is DEMO01, consented, with hints dismissed', () async {
    final s = await ports.session.state();
    expect(
      (s.participantCode, s.consented, s.hintsDismissed),
      (demoParticipantCode, true, true),
    );
  });

  test('seeding again does nothing', () async {
    final before = await db.select(db.ledgerEntry).get();
    expect(await seedDemo(ports, clock, today: today), isNull);
    expect(await db.select(db.ledgerEntry).get(), hasLength(before.length));
  });

  test('three weeks of entries, every day with sales and expenses', () async {
    for (var d = 0; d < 21; d++) {
      final t = await ports.totals
          .watchDay(today.subtract(Duration(days: d)))
          .first;
      expect(t.inNgwee, greaterThan(0), reason: '$d days ago: sales');
      expect(t.outNgwee, greaterThan(0), reason: '$d days ago: expenses');
    }
  });

  test(
    'today shows entries and an "Is this right?" check on the K250 taxi',
    () async {
      expect(await ports.ledger.watchToday().first, isNotEmpty);
      final check = await ports.ledger.watchNeedsCheck().first;
      expect(check, isNotNull);
      expect(
        (check!.entry.description, check.entry.amountNgwee),
        ('taxi with stock', 25000),
      );
      expect(check.usualNgwee, isNotNull);
      // ignore: avoid_print
      print(
        'past entries the detector flagged (answered by the seed): '
        '$flaggedInHistory',
      );
    },
  );

  test("today's entries are all earlier than now, and today", () async {
    for (final e in await ports.ledger.watchToday().first) {
      expect(e.occurredAt.isAfter(today), isFalse, reason: e.description);
      expect(e.occurredAt.day, today.day, reason: e.description);
    }
  });

  test('opened just after midnight, today still holds only today', () async {
    final early = DateTime(2026, 11, 10, 0, 20);
    final db2 = AppDatabase(NativeDatabase.memory());
    addTearDown(db2.close);
    final c2 = DemoClock();
    final p2 = buildAppPorts(db2, clock: () => c2.at ?? early);
    await seedDemo(p2, c2, today: early);
    final todays = await p2.ledger.watchToday().first;
    expect(todays, isNotEmpty);
    for (final e in todays) {
      expect(e.occurredAt.isAfter(early), isFalse, reason: e.description);
    }
  });

  test('one entry was cancelled', () async {
    final reversals = await (db.select(
      db.ledgerEntry,
    )..where((e) => e.reversesId.isNotNull())).get();
    expect(reversals, hasLength(1));
  });

  test('stock: one product out, one low, the rest fine', () async {
    final products = {
      for (final p in await ports.stock.watchProducts().first) p.name: p,
    };
    expect(products, hasLength(7));
    expect(products['Kapenta 500g']!.isOut, isTrue);
    expect(products['Cooking oil 2L']!.isLow, isTrue);
    expect(products['Cooking oil 2L']!.isOut, isFalse);
    final fine = products.values.where((p) => !p.isLow).length;
    expect(fine, greaterThanOrEqualTo(3), reason: 'mostly well stocked');
  });

  test(
    'expenses carry the categoriser prediction, as typed entries do',
    () async {
      final predicted = await (db.select(
        db.ledgerEntry,
      )..where((e) => e.predictedCategory.isNotNull())).get();
      expect(predicted, isNotEmpty);
    },
  );

  test('nothing about the study server is set up', () async {
    final names = {for (final s in await db.select(db.appState).get()) s.name};
    expect(names, isNot(contains('auth_session')));
    expect(names, isNot(contains('claimed_code')));
    expect((await ports.sync.watch().first).enabled, isFalse);
  });
}
