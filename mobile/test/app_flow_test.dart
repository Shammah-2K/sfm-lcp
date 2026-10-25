import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sfm_lcp/app/app.dart';
import 'package:sfm_lcp/core/theme/tokens.dart';
import 'package:sfm_lcp/preview/preview_ports.dart';

/// Drives the UI through each flow on the preview data.
void main() {
  Future<void> launch(
    WidgetTester tester, {
    String? participant = 'LSK01',
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
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

  Future<void> typeAmount(WidgetTester tester, String digits) async {
    for (final d in digits.split('')) {
      await tap(tester, byKey('key-$d'));
    }
  }

  bool enabled(WidgetTester tester) =>
      tester.widget<ButtonStyleButton>(byKey('primary-action')).onPressed !=
      null;

  testWidgets('first launch asks for a participant code, then shows Today', (
    tester,
  ) async {
    await launch(tester, participant: null);
    expect(find.text('Participant code'), findsOneWidget);
    expect(enabled(tester), isFalse);

    await tester.enterText(byKey('participant-field'), 'lsk1');
    await tester.pump();
    expect(find.text('LSK1'), findsOneWidget, reason: 'auto-uppercased');
    expect(enabled(tester), isTrue);

    await tap(tester, byKey('primary-action'));
    expect(find.text('Today'), findsWidgets);
    expect(find.text('LSK1'), findsOneWidget);
  });

  testWidgets(
    'Today shows totals, the unusual-entry check and recent entries',
    (tester) async {
      await launch(tester);
      expect(find.text('+K130.00'), findsOneWidget);
      expect(find.text('−K2,645.00'), findsOneWidget);
      expect(find.text('−K2,515.00'), findsOneWidget);
      expect(byKey('unusual-card'), findsOneWidget);
      expect(find.text('Usually about K20.00'), findsOneWidget);

      await tap(tester, byKey('unusual-keep'));
      expect(byKey('unusual-card'), findsNothing);
      expect(
        find.text('bus fare to Matero', skipOffstage: false),
        findsOneWidget,
      );
    },
  );

  testWidgets('an expense with a confident suggestion saves in one pass', (
    tester,
  ) async {
    await launch(tester);
    await tap(tester, byKey('new-expense'));
    expect(enabled(tester), isFalse);

    await typeAmount(tester, '25');
    await tester.enterText(byKey('description'), 'bus fare to Matero');
    await tester.pump(AppSizes.suggestionDebounce);
    await tester.pumpAndSettle();
    expect(find.text('Suggested on this phone · 99% sure'), findsOneWidget);
    expect(find.text('Save expense (−K25.00)'), findsOneWidget);
    expect(enabled(tester), isTrue, reason: 'Transport is preselected');

    await tap(tester, byKey('primary-action'));
    expect(find.text('Saved K25.00'), findsOneWidget);
    await tester.pump(AppSizes.savedBanner);
    await tester.pumpAndSettle();
    expect(byKey('new-expense'), findsOneWidget, reason: 'back on Today');
    expect(
      find.text('bus fare to Matero', skipOffstage: false),
      findsNWidgets(2),
    );
  });

  testWidgets(
    'an unsure suggestion offers three categories and waits for a pick',
    (tester) async {
      await launch(tester);
      await tap(tester, byKey('new-expense'));
      await typeAmount(tester, '15');
      await tester.enterText(byKey('description'), 'Repair of wheelbarrow');
      await tester.pump(AppSizes.suggestionDebounce);
      await tester.pumpAndSettle();

      expect(byKey('category-other_expense'), findsOneWidget);
      expect(byKey('category-stock'), findsOneWidget);
      expect(byKey('category-utilities'), findsOneWidget);
      expect(enabled(tester), isFalse);

      await tap(tester, byKey('category-other'));
      expect(find.text('Select category'), findsOneWidget);
      await tap(tester, find.text('Wages'));
      expect(
        find.text('Select category'),
        findsNothing,
        reason: 'one tap closes the sheet',
      );
      expect(enabled(tester), isTrue);
    },
  );

  testWidgets('a sale from products totals the items (T1: 3 loaves at K25)', (
    tester,
  ) async {
    await launch(tester);
    await tap(tester, byKey('new-sale'));
    await tap(tester, byKey('choice-_SaleMode.products'));
    for (var i = 0; i < 3; i++) {
      await tap(
        tester,
        find.descendant(of: byKey('qty-p1'), matching: find.byIcon(Icons.add)),
      );
    }
    expect(tester.widget<Text>(byKey('products-total')).data, 'K75.00');
    expect(find.text('3 items'), findsOneWidget);
    expect(find.text('Save sale (K75.00)'), findsOneWidget);
    expect(find.text('Out of stock', skipOffstage: false), findsOneWidget);
  });

  testWidgets('a sale with no description saves as Sales of goods', (
    tester,
  ) async {
    await launch(tester);
    await tap(tester, byKey('new-sale'));
    expect(byKey('category-sales_goods'), findsOneWidget);
    expect(enabled(tester), isFalse);
    await typeAmount(tester, '50');
    expect(enabled(tester), isTrue);
  });

  testWidgets('an entry is cancelled only after confirmation', (tester) async {
    await launch(tester);
    await tap(tester, byKey('entry-e4'));
    expect(find.text('Entry'), findsOneWidget);
    await tap(tester, byKey('cancel-entry'));
    expect(find.text('Cancel this K25.00 expense?'), findsOneWidget);

    await tap(tester, byKey('keep-entry'));
    expect(
      byKey('cancel-entry'),
      findsOneWidget,
      reason: 'Keep it changes nothing',
    );

    await tap(tester, byKey('cancel-entry'));
    await tap(tester, byKey('confirm-cancel'));
    expect(find.text('Cancelled', skipOffstage: false), findsOneWidget);
  });

  testWidgets('Totals switches between day and week', (tester) async {
    await launch(tester);
    await tap(tester, byKey('tab-totals'));
    expect(find.text('Profit'), findsOneWidget);
    expect(find.text('Loss'), findsOneWidget);
    expect(
      tester
          .widget<ButtonStyleButton>(
            find.descendant(
              of: byKey('period-next'),
              matching: find.byType(OutlinedButton),
            ),
          )
          .onPressed,
      isNull,
    );

    await tap(tester, byKey('choice-_Period.week'));
    expect(find.text('−K1,535.00'), findsOneWidget);
  });

  testWidgets('Stock flags low items and adjusts a count', (tester) async {
    await launch(tester);
    await tap(tester, byKey('tab-stock'));
    expect(find.text('2 items running low'), findsOneWidget);

    await tap(tester, byKey('product-p1'));
    expect(find.text('12 in stock'), findsOneWidget);
    await tap(
      tester,
      find.descendant(
        of: byKey('stock-delta'),
        matching: find.byIcon(Icons.add),
      ),
    );
    expect(find.text('New stock: 13'), findsOneWidget);
    await tap(tester, byKey('primary-action'));
    expect(
      find.text('2 items running low'),
      findsOneWidget,
      reason: 'back on Stock',
    );
  });

  group('no overflow on a 360×640 phone at 1.3× text', () {
    /// Scrolls the visible list to the end so every row is laid out.
    Future<void> scrollThrough(WidgetTester tester) async {
      final list = find.byType(Scrollable).hitTestable();
      for (var i = 0; i < 12; i++) {
        if (list.evaluate().isEmpty) return;
        await tester.drag(list.first, const Offset(0, -200));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    }

    Future<void> small(WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        SfmApp(ports: previewPorts(participant: 'ABCDEFGHIJKL')),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('Today, Totals, Stock', (tester) async {
      await small(tester);
      await scrollThrough(tester);
      await tap(tester, byKey('tab-totals'));
      await tap(tester, byKey('choice-_Period.week'));
      await scrollThrough(tester);
      await tap(tester, byKey('tab-stock'));
      await scrollThrough(tester);
    });

    testWidgets('Expense with suggestion', (tester) async {
      await small(tester);
      await tap(tester, byKey('new-expense'));
      await typeAmount(tester, '1000000');
      await tester.enterText(byKey('description'), 'Repair of wheelbarrow');
      await tester.pump(AppSizes.suggestionDebounce);
      await tester.pumpAndSettle();
      await scrollThrough(tester);
    });

    testWidgets('Sale products, entry detail, new product', (tester) async {
      await small(tester);
      await tap(tester, byKey('new-sale'));
      await tap(tester, byKey('choice-_SaleMode.products'));
      await scrollThrough(tester);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tap(tester, byKey('entry-e5'));
      await scrollThrough(tester);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tap(tester, byKey('tab-stock'));
      await tap(tester, byKey('add-product'));
      await tap(tester, byKey('edit-price'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Participant code', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(SfmApp(ports: previewPorts()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
