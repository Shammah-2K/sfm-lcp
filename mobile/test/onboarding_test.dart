// First launch and the account sheet, end to end on the real database.
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sfm_lcp/app/app.dart';
import 'package:sfm_lcp/app/app_ports.dart';
import 'package:sfm_lcp/data/database.dart';

void main() {
  late AppDatabase db;

  Finder byKey(String k) => find.byKey(Key(k), skipOffstage: false);

  Future<void> tap(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  bool enabled(WidgetTester tester, String key) =>
      tester
          .widget<ButtonStyleButton>(
            find
                .descendant(
                  of: byKey(key),
                  matching: find.bySubtype<ButtonStyleButton>(),
                )
                .first,
          )
          .onPressed !=
      null;

  Future<void> launch(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    db = AppDatabase(NativeDatabase.memory());
    await tester.pumpWidget(SfmApp(ports: buildAppPorts(db)));
    await tester.pumpAndSettle();
  }

  Future<void> finish(WidgetTester tester) async {
    // Unmount so live queries close before the database does.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
    await db.close();
  }

  testWidgets('consent → code → business type → Today, saved in the database', (
    tester,
  ) async {
    await launch(tester);
    expect(find.text('Welcome'), findsOneWidget);

    await tap(tester, byKey('consent-not-now'));
    expect(find.text('Come back when you are ready'), findsOneWidget);
    expect(
      await db.select(db.appState).get(),
      isEmpty,
      reason: 'nothing saved on "Not now"',
    );
    await tap(tester, byKey('consent-ready'));
    await tap(tester, byKey('consent-agree'));

    expect(find.text('Participant code'), findsOneWidget);
    expect(enabled(tester, 'code-next'), isFalse);
    await tester.enterText(byKey('participant-field'), 'lsk1');
    await tester.pump();
    expect(find.text('LSK1'), findsOneWidget, reason: 'auto-uppercased');
    final field = tester.widget<TextField>(byKey('participant-field'));
    expect((field.enableSuggestions, field.autocorrect), (false, false));
    await tap(tester, byKey('code-next'));

    expect(find.text('What kind of business?'), findsOneWidget);
    expect(enabled(tester, 'onboarding-start'), isFalse);
    await tap(tester, find.byIcon(Icons.arrow_back));
    expect(find.text('LSK1'), findsOneWidget, reason: 'back keeps the code');
    await tap(tester, byKey('code-next'));
    await tap(tester, byKey('business-shop'));
    await tap(tester, byKey('onboarding-start'));

    expect(byKey('new-sale'), findsOneWidget);
    final business = await db.select(db.business).getSingle();
    expect((business.participantCode, business.businessType), ('LSK1', 'shop'));
    await finish(tester);
  });

  testWidgets('the first-use hint shows until dismissed', (tester) async {
    await launch(tester);
    await tap(tester, byKey('consent-agree'));
    await tester.enterText(byKey('participant-field'), 'LSK01');
    await tester.pump();
    await tap(tester, byKey('code-next'));
    await tap(tester, byKey('business-market_stall'));
    await tap(tester, byKey('onboarding-start'));

    expect(byKey('first-use-hint'), findsOneWidget);
    await tap(tester, byKey('hint-dismiss'));
    expect(byKey('first-use-hint'), findsNothing);
    final names = [for (final s in await db.select(db.appState).get()) s.name];
    expect(names, containsAll(['consent_at', 'hints_dismissed_at']));
    await finish(tester);
  });

  testWidgets('stop taking part is confirmed, recorded and shown', (
    tester,
  ) async {
    await launch(tester);
    await tap(tester, byKey('consent-agree'));
    await tester.enterText(byKey('participant-field'), 'LSK01');
    await tester.pump();
    await tap(tester, byKey('code-next'));
    await tap(tester, byKey('business-service'));
    await tap(tester, byKey('onboarding-start'));

    await tap(tester, find.byKey(const Key('sync-badge')).first);
    await tap(tester, byKey('stop-taking-part'));
    expect(find.text('Stop taking part?'), findsOneWidget);
    await tap(tester, byKey('withdraw-cancel'));
    expect(
      await db.select(db.appState).get(),
      hasLength(1),
      reason: '"Keep going" changes nothing',
    );

    await tap(tester, byKey('stop-taking-part'));
    await tap(tester, byKey('withdraw-confirm'));
    await tap(tester, find.byKey(const Key('sync-badge')).first);
    expect(byKey('withdrawn-note'), findsOneWidget);
    expect(byKey('stop-taking-part'), findsNothing);
    await finish(tester);
  });

  testWidgets('a phone set up before the consent screen asks for consent only', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    db = AppDatabase(NativeDatabase.memory());
    // As the Phase 2 build left it: a participant, no consent recorded.
    await db.customStatement(
      "INSERT INTO business (id, participant_code, created_at) VALUES ('b1', 'LSK01', 1)",
    );
    await tester.pumpWidget(SfmApp(ports: buildAppPorts(db)));
    await tester.pumpAndSettle();

    expect(find.text('Welcome'), findsOneWidget);
    await tap(tester, byKey('consent-agree'));
    expect(byKey('new-sale'), findsOneWidget, reason: 'straight to Today');
    expect(find.text('LSK01'), findsOneWidget);
    await finish(tester);
  });
}
