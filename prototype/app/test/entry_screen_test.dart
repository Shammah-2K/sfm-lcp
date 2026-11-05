import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sfm_lcp_prototype/data/database.dart' hide LedgerEntry;
import 'package:sfm_lcp_prototype/data/ledger_repository.dart';
import 'package:sfm_lcp_prototype/domain/ledger.dart';
import 'package:sfm_lcp_prototype/ml/categoriser.dart';
import 'package:sfm_lcp_prototype/theme.dart';
import 'package:sfm_lcp_prototype/ui/screens/entry_screen.dart';
import 'package:sfm_lcp_prototype/ui/screens/home_screen.dart';

void main() {
  final categoriser = Categoriser.fromJson(
    jsonDecode(File(categoriserAsset).readAsStringSync())
        as Map<String, dynamic>,
  );
  late AppDatabase db;
  late LedgerRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = LedgerRepository(db, 'not-used-until-save');
  });

  tearDown(() => db.close());

  Widget host(Widget child, {double textScale = 1}) => MaterialApp(
    theme: buildTheme(),
    home: MediaQuery.withClampedTextScaling(
      minScaleFactor: textScale,
      maxScaleFactor: textScale,
      child: child,
    ),
  );

  bool saveEnabled(WidgetTester tester) =>
      tester
          .widget<ButtonStyleButton>(
            find.byKey(const Key('save'), skipOffstage: false),
          )
          .onPressed !=
      null;

  Future<void> tapKeys(WidgetTester tester, String keys) async {
    for (final k in keys.split('')) {
      final key = find.byKey(Key('key-$k'), skipOffstage: false);
      await tester.ensureVisible(key);
      await tester.tap(key);
      await tester.pump();
    }
  }

  testWidgets(
    'expense Save stays disabled until amount, description and category are valid',
    (tester) async {
      await tester.pumpWidget(
        host(
          EntryScreen(
            type: EntryType.expense,
            repository: repository,
            categoriser: categoriser,
          ),
        ),
      );
      expect(saveEnabled(tester), isFalse, reason: 'nothing entered');

      await tapKeys(tester, '25');
      expect(find.text('K25', skipOffstage: false), findsOneWidget);
      expect(saveEnabled(tester), isFalse, reason: 'amount only');

      await tester.enterText(
        find.byKey(const Key('description'), skipOffstage: false),
        'qqqq zzzz',
      );
      await tester.pump(AppSizes.debounce);
      final suggestion = categoriser.suggest(
        'qqqq zzzz',
        EntryType.expense.categoryKind,
      )!;
      expect(
        suggestion.preselect,
        isFalse,
        reason: 'fixture text must not be confidently categorised',
      );
      expect(
        saveEnabled(tester),
        isFalse,
        reason: 'amount and description, no category',
      );
      expect(
        find.byKey(const Key('suggestion-caption'), skipOffstage: false),
        findsOneWidget,
      );

      final chip = find.byKey(
        Key('category-${suggestion.top3.first.code}'),
        skipOffstage: false,
      );
      await tester.ensureVisible(chip);
      await tester.tap(chip);
      await tester.pump();
      expect(
        saveEnabled(tester),
        isTrue,
        reason: 'amount, description and category',
      );

      await tester.enterText(
        find.byKey(const Key('description'), skipOffstage: false),
        '   ',
      );
      await tester.pump(AppSizes.debounce);
      expect(saveEnabled(tester), isFalse, reason: 'blank description');

      await tester.enterText(
        find.byKey(const Key('description'), skipOffstage: false),
        'lunch',
      );
      await tester.pump(AppSizes.debounce);
      await tapKeys(tester, '⌫⌫');
      expect(saveEnabled(tester), isFalse, reason: 'amount cleared');

      await tapKeys(tester, '0');
      expect(saveEnabled(tester), isFalse, reason: 'zero amount');
    },
  );

  testWidgets('a confident suggestion is preselected', (tester) async {
    const text = 'bus fare to Matero';
    final suggestion = categoriser.suggest(
      text,
      EntryType.expense.categoryKind,
    )!;
    await tester.pumpWidget(
      host(
        EntryScreen(
          type: EntryType.expense,
          repository: repository,
          categoriser: categoriser,
        ),
      ),
    );
    await tapKeys(tester, '5');
    await tester.enterText(
      find.byKey(const Key('description'), skipOffstage: false),
      text,
    );
    await tester.pump(AppSizes.debounce);
    expect(saveEnabled(tester), suggestion.preselect);
  });

  testWidgets('a sale with no description can be saved as Sales of goods', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        EntryScreen(
          type: EntryType.sale,
          repository: repository,
          categoriser: categoriser,
        ),
      ),
    );
    expect(
      find.byKey(const Key('category-sales_goods'), skipOffstage: false),
      findsOneWidget,
    );
    expect(saveEnabled(tester), isFalse);
    await tapKeys(tester, '10');
    expect(saveEnabled(tester), isTrue);
  });

  for (final type in EntryType.values) {
    testWidgets(
      '${type.name} screen has no overflow at 1.3x text on a 360x640 phone',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          host(
            EntryScreen(
              type: type,
              repository: repository,
              categoriser: categoriser,
            ),
            textScale: 1.3,
          ),
        );
        await tapKeys(tester, '1000000');
        await tester.enterText(
          find.byKey(const Key('description'), skipOffstage: false),
          'airtime for business phone',
        );
        await tester.pump(AppSizes.debounce);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('home screen has no overflow at 1.3x text on a 360x640 phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      host(
        HomeScreen(
          participantCode: 'ABCDEFGHIJKL',
          repository: repository,
          categoriser: categoriser,
        ),
        textScale: 1.3,
      ),
    );
    await tester.pump();
    expect(
      find.byKey(const Key('new-sale'), skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('new-expense'), skipOffstage: false),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    // Dispose the stream queries, then let drift's zero-delay cleanup timer fire.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  });
}
