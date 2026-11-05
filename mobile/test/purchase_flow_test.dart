// Recording a stock purchase on the expense screen, on the real database.
import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sfm_lcp/app/app.dart';
import 'package:sfm_lcp/app/app_ports.dart';
import 'package:sfm_lcp/app/ports.dart';
import 'package:sfm_lcp/app/view_data.dart';
import 'package:sfm_lcp/core/theme/tokens.dart';
import 'package:sfm_lcp/data/database.dart';

void main() {
  late AppDatabase db;
  late AppPorts ports;
  late String bread;

  // Screens stay mounted under the one on top; `.last` is the top one.
  Finder byKey(String k) => find.byKey(Key(k), skipOffstage: false).last;

  // The amount display may be scrolled out of view; it is still there.
  Finder anyText(String s) => find.text(s, skipOffstage: false);

  Future<void> tap(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
    // Let database reads started by the tap finish in real time.
    await tester.runAsync(() => Future<void>.delayed(Durations.short1));
    await tester.pumpAndSettle();
  }

  Future<void> keys(WidgetTester tester, String digits) async {
    for (final d in digits.split('')) {
      await tap(tester, byKey('key-$d'));
    }
  }

  bool saveEnabled(WidgetTester tester) =>
      tester.widget<ButtonStyleButton>(byKey('primary-action')).onPressed !=
      null;

  Future<void> launch(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    db = AppDatabase(NativeDatabase.memory());
    ports = buildAppPorts(db);
    await tester.runAsync(() async {
      await ports.session.recordConsent();
      await ports.session.start('LSK01', BusinessType.marketStall);
      await ports.session.dismissHints();
      await ports.stock.saveProduct(
        const ProductDraft(
          name: 'Bread',
          priceNgwee: 2500,
          reorderLevel: 2,
          openingStock: 4,
        ),
      );
      bread = (await ports.stock.watchProducts().first).single.id;
    });
    await tester.pumpWidget(SfmApp(ports: ports));
    await tester.pumpAndSettle();
    await tap(tester, byKey('new-expense'));
    await tap(tester, byKey('category-other'));
    await tap(tester, byKey('category-stock').last);
  }

  Future<void> finish(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
    await db.close();
  }

  // Read straight from the view, as the onboarding tests do: a real-async
  // read here would wait on the screens' live queries.
  Future<int> stockOf(String name) async =>
      (await db
              .customSelect(
                'SELECT stock_qty FROM v_stock_level WHERE name = ?',
                variables: [Variable(name)],
              )
              .getSingle())
          .read<int>('stock_qty');

  testWidgets('the amount follows the products bought until it is typed', (
    tester,
  ) async {
    await launch(tester);
    expect(saveEnabled(tester), isFalse);

    await tap(tester, byKey('add-bought'));
    await tap(tester, byKey('buy-$bread'));
    for (var i = 0; i < 9; i++) {
      await tap(tester, find.bySemanticsLabel('One more Bread'));
    }
    await keys(tester, '20');
    expect(byKey('bought-line-total'), findsOneWidget);
    await tap(tester, byKey('primary-action'));

    expect(anyText('10 × Bread'), findsOneWidget);
    expect(anyText('−K200'), findsOneWidget, reason: 'defaults to the lines');
    expect(saveEnabled(tester), isTrue, reason: 'no description needed');

    await keys(tester, '185');
    expect(anyText('−K185'), findsOneWidget, reason: 'the trader overwrote it');
    await tap(tester, byKey('use-bought-total'));
    expect(anyText('−K200'), findsOneWidget);
    await keys(tester, '185');

    await tap(tester, byKey('primary-action'));
    await tester.pump(AppSizes.savedBanner);
    await tester.pumpAndSettle();

    expect(await stockOf('Bread'), 14);
    final entry = await db.select(db.ledgerEntry).getSingle();
    expect((entry.amountNgwee, entry.description), (18500, '10 × Bread'));
    await finish(tester);
  });

  testWidgets(
    'a new product bought for the first time starts from the purchase',
    (tester) async {
      await launch(tester);
      await tap(tester, byKey('add-bought'));
      await tap(tester, byKey('buy-new-product'));

      expect(
        find.byKey(const Key('opening-stock'), skipOffstage: false),
        findsNothing,
        reason: 'no double counting',
      );
      await tester.enterText(byKey('product-name'), 'Sugar');
      await tap(tester, byKey('edit-price'));
      await keys(tester, '30');
      await tap(tester, byKey('primary-action'));

      expect(anyText('Sugar'), findsWidgets, reason: 'straight to the line');
      await keys(tester, '25');
      await tap(tester, byKey('primary-action'));
      await tap(tester, byKey('primary-action'));
      await tester.pump(AppSizes.savedBanner);
      await tester.pumpAndSettle();

      expect(await stockOf('Sugar'), 1);
      await finish(tester);
    },
  );
}
