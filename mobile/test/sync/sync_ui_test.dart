// Sync in the app: the code check during onboarding and the account sheet,
// on the real database with the in-memory server.
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sfm_lcp/app/app.dart';
import 'package:sfm_lcp/app/app_ports.dart';
import 'package:sfm_lcp/app/view_data.dart';
import 'package:sfm_lcp/data/database.dart';
import 'package:sfm_lcp/sync/sync_scheduler.dart';
import 'package:sfm_lcp/sync/sync_worker.dart';

import 'fake_server.dart';

void main() {
  late AppDatabase db;
  late FakeServer server;

  Finder byKey(String k) => find.byKey(Key(k), skipOffstage: false).last;

  Future<void> tap(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
    // Let database work started by the tap finish in real time.
    await tester.runAsync(() => Future<void>.delayed(Durations.short1));
    await tester.pumpAndSettle();
  }

  Future<void> launch(
    WidgetTester tester, {
    Future<void> Function(AppDatabase db)? before,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    db = AppDatabase(NativeDatabase.memory());
    server = FakeServer();
    // Not started: no timers in a widget test. "Sync now" runs it.
    final scheduler = SyncScheduler(db, SyncWorker(db, server));
    final ports = buildAppPorts(db, syncScheduler: scheduler);
    if (before != null) await tester.runAsync(() => before(db));
    await tester.pumpWidget(SfmApp(ports: ports));
    await tester.pumpAndSettle();
  }

  Future<void> finish(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
    await db.close();
  }

  testWidgets('a code not on the study list is caught during onboarding', (
    tester,
  ) async {
    await launch(tester);
    await tap(tester, byKey('consent-agree'));
    await tester.enterText(byKey('participant-field'), 'NOPE1');
    await tester.pump();
    await tap(tester, byKey('code-next'));

    expect(byKey('code-problem'), findsOneWidget);
    expect(
      find.textContaining('not on the study list', skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.text('What kind of business?', skipOffstage: false),
      findsNothing,
      reason: 'stays on the code step',
    );

    await tester.enterText(byKey('participant-field'), 'LSK01');
    await tester.pump();
    expect(
      find.byKey(const Key('code-problem'), skipOffstage: false),
      findsNothing,
      reason: 'the message clears on typing',
    );
    await tap(tester, byKey('code-next'));
    expect(find.text('What kind of business?'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('"Sync now" sends what is waiting and the sheet shows it', (
    tester,
  ) async {
    await launch(
      tester,
      before: (db) async {
        final ports = buildAppPorts(db);
        await ports.session.recordConsent();
        await ports.session.start('LSK01', BusinessType.shop);
        await ports.session.dismissHints();
        await ports.ledger.recordExpense(
          const ExpenseDraft(
            amountNgwee: 2500,
            description: 'Bus fare',
            categoryCode: 'transport',
            method: PaymentMethod.cash,
          ),
        );
      },
    );
    await tap(tester, find.byKey(const Key('sync-badge')).first);
    expect(find.text('2 records waiting to sync'), findsOneWidget);

    await tap(tester, byKey('sync-now'));
    await tester.runAsync(() => Future<void>.delayed(Durations.medium1));
    await tester.pumpAndSettle();
    expect(find.text('All records sent'), findsWidgets);
    expect(server.tables['ledger_entry'], hasLength(1));
    await finish(tester);
  });

  testWidgets('a server that refuses is explained, not shown as no network', (
    tester,
  ) async {
    await launch(
      tester,
      before: (db) async {
        final ports = buildAppPorts(db);
        await ports.session.recordConsent();
        await ports.session.start('LSK01', BusinessType.shop);
        await ports.session.dismissHints();
      },
    );
    server.anonymousSignInsDisabled = true;
    await tap(tester, find.byKey(const Key('sync-badge')).first);
    await tap(tester, byKey('sync-now'));
    await tester.runAsync(() => Future<void>.delayed(Durations.medium1));
    await tester.pumpAndSettle();
    expect(byKey('sync-trouble-server'), findsOneWidget);
    expect(find.textContaining("Can't reach the study server"), findsOneWidget);
    expect(byKey('sync-now'), findsOneWidget, reason: 'can try again');
    await finish(tester);
  });

  testWidgets('a blocked code is explained in the sheet', (tester) async {
    await launch(
      tester,
      before: (db) async {
        final ports = buildAppPorts(db);
        await ports.session.recordConsent();
        await ports.session.start('ZZZ999', BusinessType.shop);
        await ports.session.dismissHints();
      },
    );
    await tap(tester, find.byKey(const Key('sync-badge')).first);
    await tap(tester, byKey('sync-now'));
    await tester.runAsync(() => Future<void>.delayed(Durations.medium1));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Your code is not on the study list'),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('sync-now'), skipOffstage: false),
      findsNothing,
      reason: 'nothing to retry until the researcher fixes it',
    );
    await finish(tester);
  });
}
