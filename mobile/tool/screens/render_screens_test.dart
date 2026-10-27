// Renders every screen to docs/screens/ for review and for the dissertation.
//
//   flutter test --update-goldens tool/screens
//
// Uses the Roboto and Material icon fonts that ship with the Flutter SDK, so
// it runs offline. The images show the preview sample data.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sfm_lcp/app/app.dart';
import 'package:sfm_lcp/core/theme/tokens.dart';
import 'package:sfm_lcp/preview/preview_ports.dart';

const String _out = '../../../docs/screens';

Future<void> _loadFonts() async {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) throw StateError('FLUTTER_ROOT is not set');
  final dir = '$root/bin/cache/artifacts/material_fonts';
  Future<ByteData> file(String name) async =>
      ByteData.sublistView(await File('$dir/$name').readAsBytes());

  final roboto = FontLoader('Roboto')
    ..addFont(file('roboto-regular.ttf'))
    ..addFont(file('roboto-medium.ttf'))
    ..addFont(file('roboto-bold.ttf'));
  final icons = FontLoader('MaterialIcons')
    ..addFont(file('materialicons-regular.otf'));
  await Future.wait([roboto.load(), icons.load()]);
}

void main() {
  setUpAll(_loadFonts);

  Future<void> launch(
    WidgetTester tester, {
    String? participant = 'LSK01',
    double height = 844,
  }) async {
    tester.view.physicalSize = Size(390 * 2, height * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      SfmApp(ports: previewPorts(participant: participant)),
    );
    await tester.pumpAndSettle();
  }

  Finder byKey(String k) => find.byKey(Key(k), skipOffstage: false);

  Future<void> tap(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  Future<void> keys(WidgetTester tester, String digits) async {
    for (final d in digits.split('')) {
      await tap(tester, byKey('key-$d'));
    }
  }

  Future<void> describe(WidgetTester tester, String text) async {
    await tester.enterText(byKey('description'), text);
    await tester.pump(AppSizes.suggestionDebounce);
    await tester.pumpAndSettle();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
  }

  Future<void> shot(WidgetTester tester, String name) async {
    await tester.binding.setSurfaceSize(null);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('$_out/$name.png'),
    );
  }

  Future<void> top(WidgetTester tester) async {
    final list = find.byType(Scrollable).hitTestable();
    if (list.evaluate().isNotEmpty) {
      await tester.drag(list.first, const Offset(0, 3000));
      await tester.pumpAndSettle();
    }
  }

  testWidgets('S00 consent, S01 participant code, S01b business type', (
    tester,
  ) async {
    await launch(tester, participant: null);
    await shot(tester, 's00_consent');
    await tap(tester, byKey('consent-agree'));
    await tester.enterText(byKey('participant-field'), 'LSK01');
    await tester.pumpAndSettle();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await shot(tester, 's01_participant_code');
    await tap(tester, byKey('code-next'));
    await tap(tester, byKey('business-market_stall'));
    await shot(tester, 's01b_business_type');
  });

  testWidgets('S02 today with S08 check', (tester) async {
    await launch(tester, height: 1500);
    await shot(tester, 's02_today');
  });

  testWidgets('S03 sale by amount', (tester) async {
    await launch(tester, height: 1000);
    await tap(tester, byKey('new-sale'));
    await keys(tester, '50');
    await tap(tester, byKey('choice-PaymentMethod.mobileMoney'));
    await top(tester);
    await shot(tester, 's03_sale_amount');
  });

  testWidgets('S04 sale from products', (tester) async {
    await launch(tester, height: 1100);
    await tap(tester, byKey('new-sale'));
    await tap(tester, byKey('choice-_SaleMode.products'));
    for (var i = 0; i < 3; i++) {
      await tap(
        tester,
        find.descendant(of: byKey('qty-p1'), matching: find.byIcon(Icons.add)),
      );
    }
    await top(tester);
    await shot(tester, 's04_sale_products');
  });

  testWidgets('S05 expense, confident suggestion', (tester) async {
    await launch(tester, height: 1000);
    await tap(tester, byKey('new-expense'));
    await keys(tester, '25');
    await describe(tester, 'bus fare to Matero');
    await top(tester);
    await shot(tester, 's05_expense_confident');
  });

  testWidgets('S05b expense, unsure suggestion', (tester) async {
    await launch(tester, height: 1050);
    await tap(tester, byKey('new-expense'));
    await keys(tester, '15');
    await describe(tester, 'Repair of wheelbarrow');
    await top(tester);
    await shot(tester, 's05b_expense_unsure');
  });

  testWidgets('S05c stock purchase, S05d product bought', (tester) async {
    await launch(tester, height: 1250);
    await tap(tester, byKey('new-expense'));
    await tap(tester, byKey('category-other'));
    await tap(tester, byKey('category-stock').last);
    await tap(tester, byKey('add-bought'));
    await tap(tester, byKey('buy-p1'));
    for (var i = 0; i < 9; i++) {
      await tap(tester, find.byIcon(Icons.add).last);
    }
    for (final d in '20'.split('')) {
      await tap(tester, byKey('key-$d').last);
    }
    await shot(tester, 's05d_purchase_line');
    await tap(tester, byKey('primary-action').last);
    await top(tester);
    await shot(tester, 's05c_stock_purchase');
  });

  testWidgets('S06 all categories sheet', (tester) async {
    await launch(tester);
    await tap(tester, byKey('new-expense'));
    await keys(tester, '15');
    await describe(tester, 'Repair of wheelbarrow');
    await tap(tester, byKey('category-other'));
    await shot(tester, 's06_category_sheet');
  });

  testWidgets('S07 saved banner', (tester) async {
    await launch(tester, height: 1000);
    await tap(tester, byKey('new-expense'));
    await keys(tester, '25');
    await describe(tester, 'bus fare to Matero');
    await tap(tester, byKey('primary-action'));
    await top(tester);
    await shot(tester, 's07_saved');
    await tester.pump(AppSizes.savedBanner);
    await tester.pumpAndSettle();
  });

  testWidgets('S09 entry detail', (tester) async {
    await launch(tester);
    await tap(tester, byKey('entry-e4'));
    await shot(tester, 's09_entry_detail');
  });

  testWidgets('S10 confirm cancel', (tester) async {
    await launch(tester);
    await tap(tester, byKey('entry-e4'));
    await tap(tester, byKey('cancel-entry'));
    await shot(tester, 's10_confirm_cancel');
  });

  testWidgets('S11 totals, day and week', (tester) async {
    await launch(tester, height: 1250);
    await tap(tester, byKey('tab-totals'));
    await shot(tester, 's11_totals_day');
    await tap(tester, byKey('choice-_Period.week'));
    await shot(tester, 's11b_totals_week');
  });

  testWidgets('S12 stock', (tester) async {
    await launch(tester);
    await tap(tester, byKey('tab-stock'));
    await shot(tester, 's12_stock');
  });

  testWidgets('S13 new product', (tester) async {
    await launch(tester, height: 1100);
    await tap(tester, byKey('tab-stock'));
    await tap(tester, byKey('add-product'));
    await tester.enterText(byKey('product-name'), 'Bread');
    await tap(tester, byKey('edit-price'));
    await keys(tester, '25');
    FocusManager.instance.primaryFocus?.unfocus();
    await top(tester);
    await shot(tester, 's13_new_product');
  });

  testWidgets('S13b edit product, S13c stop selling', (tester) async {
    await launch(tester);
    await tap(tester, byKey('tab-stock'));
    await tap(tester, byKey('product-p1'));
    await tap(tester, byKey('edit-product'));
    await shot(tester, 's13b_edit_product');
    await tap(tester, byKey('stop-selling'));
    await shot(tester, 's13c_stop_selling');
  });

  testWidgets('S14 adjust stock', (tester) async {
    await launch(tester);
    await tap(tester, byKey('tab-stock'));
    await tap(tester, byKey('product-p1'));
    for (var i = 0; i < 6; i++) {
      await tap(
        tester,
        find.descendant(
          of: byKey('stock-delta'),
          matching: find.byIcon(Icons.add),
        ),
      );
    }
    await shot(tester, 's14_adjust_stock');
  });

  testWidgets('S15 sync sheet', (tester) async {
    await launch(tester);
    await tap(tester, find.byKey(const Key('sync-badge')).first);
    await shot(tester, 's15_sync_sheet');
  });
}
