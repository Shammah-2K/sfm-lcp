// Editing a product and "Stop selling" from the Stock tab, on the real database.
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sfm_lcp/app/app.dart';
import 'package:sfm_lcp/app/app_ports.dart';
import 'package:sfm_lcp/app/ports.dart';
import 'package:sfm_lcp/app/view_data.dart';
import 'package:sfm_lcp/data/database.dart';

void main() {
  late AppDatabase db;
  late AppPorts ports;
  late String bread;

  // Screens stay mounted under the one on top; `.last` is the top one.
  Finder byKey(String k) => find.byKey(Key(k), skipOffstage: false).last;
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
    await tester.pumpWidget(SfmApp(ports: ports));
    await tester.pumpAndSettle();
    await tap(tester, byKey('tab-stock'));
    await tap(tester, byKey('product-$bread'));
    await tap(tester, byKey('edit-product'));
  }

  Future<void> finish(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
    await db.close();
  }

  testWidgets('edit a product: the form starts filled in and saves', (
    tester,
  ) async {
    await launch(tester);
    expect(anyText('Edit product'), findsOneWidget);
    expect(
      tester.widget<TextField>(byKey('product-name')).controller!.text,
      'Bread',
    );
    expect(
      find.byKey(const Key('opening-stock'), skipOffstage: false),
      findsNothing,
      reason: 'stock changes only through Adjust stock',
    );

    await tester.enterText(byKey('product-name'), 'Bread loaf');
    await tap(tester, byKey('primary-action'));
    expect(anyText('Bread loaf'), findsWidgets, reason: 'back on Adjust stock');
    final row = await (db.select(
      db.product,
    )..where((p) => p.id.equals(bread))).getSingle();
    expect(row.name, 'Bread loaf');
    await finish(tester);
  });

  testWidgets('a name already used is refused with a message', (tester) async {
    await launch(tester);
    await tester.enterText(byKey('product-name'), 'Sugar');
    await tap(tester, byKey('primary-action'));
    expect(
      // Every open screen's scaffold shows the snack bar.
      anyText('You already have Sugar. Use another name.'),
      findsWidgets,
    );
    expect(anyText('Edit product'), findsOneWidget, reason: 'still open');
    await finish(tester);
  });

  testWidgets('stop selling is confirmed, then the product leaves the list', (
    tester,
  ) async {
    await launch(tester);
    await tap(tester, byKey('stop-selling'));
    expect(anyText('Stop selling Bread?'), findsOneWidget);
    await tap(tester, byKey('stop-selling-cancel'));
    expect(
      anyText('Edit product'),
      findsOneWidget,
      reason: '"Keep it" changes nothing',
    );

    await tap(tester, byKey('stop-selling'));
    await tap(tester, byKey('stop-selling-confirm'));
    expect(byKey('add-product'), findsOneWidget, reason: 'back on Stock');
    expect(
      find.byKey(Key('product-$bread'), skipOffstage: false),
      findsNothing,
    );
    final row = await (db.select(
      db.product,
    )..where((p) => p.id.equals(bread))).getSingle();
    expect(row.isActive, 0, reason: 'hidden, not deleted');
    await finish(tester);
  });
}
