// The sync worker against an in-memory server (FR9, UC11, decision D6).
import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:sfm_lcp/app/view_data.dart';
import 'package:sfm_lcp/data/sync_status_repository.dart';
import 'package:sfm_lcp/sync/sync_scheduler.dart';
import 'package:sfm_lcp/sync/sync_worker.dart';

import 'fake_server.dart';
import 'sync_test_support.dart';

void main() {
  late Phone phone;
  late FakeServer server;
  late SyncWorker worker;

  setUp(() async {
    phone = await Phone.onboarded();
    server = FakeServer();
    worker = SyncWorker(phone.db, server);
    final bread = await phone.addProduct('Bread');
    await phone.sale(5000);
    await phone.expense(2500);
    await phone.ports.ledger.recordSale(
      SaleDraft(
        amountNgwee: 0,
        description: '',
        categoryCode: 'sales_goods',
        method: PaymentMethod.cash,
        lines: [SaleLine(productId: bread, quantity: 2)],
      ),
    );
  });

  tearDown(() => phone.close());

  Future<CopyCheck> check() async =>
      CopyCheck(await phone.records(), serverRecords(server));

  test('sends everything, then the badge shows nothing waiting', () async {
    expect(await phone.waiting(), greaterThan(0));
    expect(await worker.runOnce(), SyncOutcome.sent);
    expect((await check()).identical, isTrue, reason: '${await check()}');
    expect(await phone.waiting(), 0);
    expect(await phone.outboxByStatus(), {'acked': isPositive});
  });

  test('signs in and claims the code once per install', () async {
    await worker.runOnce();
    await phone.expense(100, 'Airtime');
    await worker.runOnce();
    expect((server.signIns, server.claims), (1, 1));
    expect(server.claimedBy('LSK01'), isNotNull);
  });

  test('with nothing waiting, the network is not used', () async {
    await worker.runOnce();
    final calls = server.calls;
    expect(await worker.runOnce(), SyncOutcome.idle);
    expect(server.calls, calls);
  });

  test('a later change is sent as the latest state', () async {
    await worker.runOnce();
    final e = await phone.expense(3000, 'Lunch');
    await worker.runOnce();
    await phone.ports.ledger.changeCategory(e.id, 'food');
    await worker.runOnce();
    final copy = server.tables['ledger_entry']![e.id]!;
    expect((copy['final_category'], copy['amount_ngwee']), ('food', 3000));
    expect((await check()).identical, isTrue);
  });

  test('a cancelled entry arrives with its reversal', () async {
    final e = await phone.expense(1500, 'Water');
    await phone.ports.ledger.cancelEntry(e.id);
    await worker.runOnce();
    final reversal = server.tables['ledger_entry']!.values.singleWhere(
      (r) => r['reverses_id'] == e.id,
    );
    expect(reversal['amount_ngwee'], -1500);
  });

  test('no network: nothing is lost, and it is sent next time', () async {
    server.queued.addAll([Fault.none, Fault.none, Fault.offline]);
    expect(await worker.runOnce(), SyncOutcome.offline);
    expect(server.tables['ledger_entry'], isEmpty);
    expect((await phone.outboxByStatus()).keys, ['failed']);
    expect(await phone.waiting(), greaterThan(0));

    expect(await worker.runOnce(), SyncOutcome.sent);
    expect((await check()).identical, isTrue);
  });

  test('a lost reply: the batch is sent again and nothing doubles', () async {
    server.queued.addAll([Fault.none, Fault.none, Fault.lostReply]);
    expect(await worker.runOnce(), SyncOutcome.offline);
    final stored = server.tables['ledger_entry']!.length;
    expect(stored, greaterThan(0), reason: 'the server did apply it');

    expect(await worker.runOnce(), SyncOutcome.sent);
    expect(server.tables['ledger_entry']!.length, stored);
    expect((await check()).identical, isTrue);
  });

  test('a run cut off mid-batch (app killed) is picked up again', () async {
    await phone.db.customUpdate(
      "UPDATE sync_record SET status = 'in_flight'",
      updates: {phone.db.syncRecord},
    );
    expect(await worker.runOnce(), SyncOutcome.sent);
    expect((await check()).identical, isTrue);
    expect(await phone.waiting(), 0);
  });

  test('an expired token is refreshed without a new sign-in', () async {
    server.queued.addAll([Fault.none, Fault.none, Fault.expiredToken]);
    expect(await worker.runOnce(), SyncOutcome.sent);
    expect(server.signIns, 1);
    expect((await check()).identical, isTrue);
  });

  test('small batches still arrive in a valid order', () async {
    worker = SyncWorker(phone.db, server, batchSize: 1);
    final e = await phone.expense(700, 'Bus');
    await phone.ports.ledger.cancelEntry(e.id);
    expect(await worker.runOnce(), SyncOutcome.sent);
    expect((await check()).identical, isTrue);
  });

  test('a code not on the list stops sending and says why', () async {
    await phone.close();
    phone = await Phone.onboarded(code: 'ZZZ999');
    worker = SyncWorker(phone.db, server);
    await phone.sale(100);

    expect(await worker.runOnce(), SyncOutcome.blocked);
    expect((await phone.ports.sync.watch().first).problem, CodeCheck.unknown);
    expect(server.tables['business'], isEmpty);

    // The researcher adds the code; the next run goes through by itself.
    server.addCode('ZZZ999');
    expect(await worker.runOnce(), SyncOutcome.sent);
    expect((await phone.ports.sync.watch().first).problem, isNull);
  });

  test('a code already used on another phone is refused', () async {
    final other = await server.signInAnonymously();
    await server.claimCode(other, 'LSK01');
    expect(await worker.runOnce(), SyncOutcome.blocked);
    expect((await phone.ports.sync.watch().first).problem, CodeCheck.taken);

    server.releaseCode('LSK01');
    expect(await worker.runOnce(), SyncOutcome.sent);
  });

  group('stop taking part', () {
    test('the server deletes its copy and nothing more is sent', () async {
      await worker.runOnce();
      expect(server.tables['ledger_entry'], isNotEmpty);

      await phone.ports.session.withdraw();
      await phone.sale(900); // the app keeps working as a record book
      expect(await worker.runOnce(), SyncOutcome.withdrawn);
      for (final t in syncedTables) {
        expect(server.tables[t], isEmpty, reason: t);
      }
      expect(server.withdrawn('LSK01'), isTrue);

      final calls = server.calls;
      expect(await worker.runOnce(), SyncOutcome.withdrawn);
      expect(server.calls, calls, reason: 'asked once only');
    });

    test('before anything was sent, there is nothing to delete', () async {
      await phone.ports.session.withdraw();
      expect(await worker.runOnce(), SyncOutcome.withdrawn);
      expect(server.calls, 0);
    });

    test('with no network the request is kept and sent later', () async {
      await worker.runOnce();
      await phone.ports.session.withdraw();
      server.queued.add(Fault.offline);
      await worker.runOnce();
      expect(server.tables['ledger_entry'], isNotEmpty);
      await worker.runOnce();
      expect(server.tables['ledger_entry'], isEmpty);
    });
  });

  group('onboarding code check', () {
    late SyncStatusRepository sync;

    setUp(() {
      sync = SyncStatusRepository(
        phone.db,
        scheduler: SyncScheduler(phone.db, worker),
      );
    });

    test('says whether a code can be used', () async {
      expect(await sync.checkCode('LSK02'), CodeCheck.ok);
      expect(await sync.checkCode('NOPE1'), CodeCheck.unknown);
    });

    test('says nothing when offline, so onboarding can go on', () async {
      server.queued.add(Fault.offline);
      expect(await sync.checkCode('LSK02'), isNull);
    });

    test('a build without the server never checks', () async {
      expect(await phone.ports.sync.checkCode('LSK02'), isNull);
      expect((await phone.ports.sync.watch().first).enabled, isFalse);
    });
  });

  test('failed rows keep the error and the number of attempts', () async {
    server.queued.addAll([Fault.none, Fault.none, Fault.offline]);
    await worker.runOnce();
    final r = await phone.db
        .customSelect(
          'SELECT attempts, last_error FROM sync_record WHERE status = ? LIMIT 1',
          variables: [Variable('failed')],
        )
        .getSingle();
    expect(r.read<int>('attempts'), 1);
    expect(r.read<String>('last_error'), contains('offline'));
  });
}
