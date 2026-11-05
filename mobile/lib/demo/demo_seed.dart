import 'dart:math';

import '../app/ports.dart';
import '../app/view_data.dart';

/// The participant code of the demo trader. Never on the study's code list.
const String demoParticipantCode = 'DEMO01';

/// Lets the seed put entries in the past: the repositories read the time from
/// [now], which follows [at] while seeding and the real clock afterwards.
class DemoClock {
  DateTime? at;

  DateTime now() => at ?? DateTime.now();
}

/// Three weeks of a Soweto market stall, written through the app's real
/// repositories (so every entry obeys the ledger's rules, gets a suggestion
/// and an anomaly score, and moves stock) for showing the app.
///
/// Past entries the detector flags are answered "Yes, keep it", as the trader
/// would have done that day, so only today's taxi waits for an answer.
///
/// Fills an empty database only. Returns how many past entries were flagged
/// (and answered), or null if the database already has a trader.
/// Seeded random numbers, so the same history every time relative to [today].
///
/// What a demo can show: Today with entries and an "Is this right?" check (a
/// K250 taxi when transport is usually about K25); a cancelled entry; Totals
/// for every day and week; stock purchases, a product running low and one
/// out of stock; suggestions on new descriptions.
Future<int?> seedDemo(
  AppPorts ports,
  DemoClock clock, {
  DateTime? today,
  int seed = 42,
}) async {
  if ((await ports.session.state()).participantCode != null) return null;
  var answered = 0;
  Future<void> answerIfFlagged(EntryRow e) async {
    if (!e.needsCheck) return;
    answered++;
    await ports.ledger.confirmUnusual(e.id);
  }

  final rng = Random(seed);
  final now = today ?? DateTime.now();
  final midnight = DateTime(now.year, now.month, now.day);
  const days = 21;
  DateTime at(int daysAgo, int hour, [int minute = 0]) => midnight
      .subtract(Duration(days: daysAgo))
      .add(Duration(hours: hour, minutes: minute));
  // Today's entries are placed before the moment the demo is opened, never
  // later, and never before midnight: [minutesAgo] counts back from now.
  DateTime earlierToday(int minutesAgo, int order) {
    final t = now.subtract(Duration(minutes: minutesAgo));
    final floor = midnight.add(Duration(minutes: order + 1));
    return t.isBefore(floor) ? floor : t;
  }

  try {
    clock.at = at(days, 6);
    await ports.session.recordConsent();
    await ports.session.start(demoParticipantCode, BusinessType.marketStall);
    await ports.session.dismissHints();

    // Name, price, reorder level, opening stock.
    const catalogue = [
      ('Tomatoes (heap)', 1000, 10, 60),
      ('Kapenta 500g', 6000, 3, 9),
      ('Cooking oil 2L', 9500, 5, 10),
      ('Mealie meal 25kg', 26000, 2, 6),
      ('Sugar 2kg', 5500, 4, 15),
      ('Bread', 2500, 6, 20),
      ('Soap', 1500, 5, 25),
    ];
    for (final (name, price, reorder, opening) in catalogue) {
      await ports.stock.saveProduct(
        ProductDraft(
          name: name,
          priceNgwee: price,
          reorderLevel: reorder,
          openingStock: opening,
        ),
      );
    }
    final products = {
      for (final p in await ports.stock.watchProducts().first) p.name: p,
    };
    final stock = {for (final (n, _, _, o) in catalogue) n: o};
    // Not restocked, so the demo shows one item low and one out of stock.
    const runDown = {'Cooking oil 2L', 'Kapenta 500g'};

    Future<void> expense(
      DateTime when,
      int ngwee,
      String what,
      String category, {
      PaymentMethod method = PaymentMethod.cash,
      List<PurchaseLine> lines = const [],
      bool leaveOpen = false,
    }) async {
      clock.at = when;
      final e = await ports.ledger.recordExpense(
        ExpenseDraft(
          amountNgwee: ngwee,
          description: what,
          categoryCode: category,
          method: method,
          suggestion: await ports.categories.suggest(what, EntryType.expense),
          lines: lines,
        ),
      );
      if (!leaveOpen) await answerIfFlagged(e);
    }

    Future<void> sales(
      int daysAgo,
      int count, {
      DateTime Function(int i)? when,
    }) async {
      for (var i = 0; i < count; i++) {
        clock.at = when != null
            ? when(i)
            : at(daysAgo, 8 + (i * 10 ~/ count), rng.nextInt(50));
        final method = rng.nextInt(4) == 0
            ? PaymentMethod.mobileMoney
            : PaymentMethod.cash;
        // Keep the last bottles of oil, so the demo has one item low but not out.
        int floor(String name) => name == 'Cooking oil 2L' ? 2 : 0;
        final inStock = [
          for (final e in stock.entries)
            if (e.value > floor(e.key)) e.key,
        ];
        if (rng.nextBool() && inStock.isNotEmpty) {
          final name = inStock[rng.nextInt(inStock.length)];
          final qty = min(stock[name]! - floor(name), 1 + rng.nextInt(3));
          stock[name] = stock[name]! - qty;
          await answerIfFlagged(
            await ports.ledger.recordSale(
              SaleDraft(
                amountNgwee: 0,
                description: '$qty × $name',
                categoryCode: 'sales_goods',
                method: method,
                lines: [SaleLine(productId: products[name]!.id, quantity: qty)],
              ),
            ),
          );
        } else {
          await answerIfFlagged(
            await ports.ledger.recordSale(
              SaleDraft(
                amountNgwee: (20 + rng.nextInt(160)) * 100,
                description: '',
                categoryCode: 'sales_goods',
                method: method,
              ),
            ),
          );
        }
      }
    }

    for (var d = days - 1; d >= 1; d--) {
      await expense(
        at(d, 6, 40),
        (20 + rng.nextInt(11)) * 100,
        'minibus to Soweto market',
        'transport',
      );
      await expense(
        at(d, 7, 5),
        500,
        'daily market fee at Soweto market',
        'rent_levy',
      );
      await sales(d, 4 + rng.nextInt(4));
      await expense(
        at(d, 12, 30),
        (20 + rng.nextInt(16)) * 100,
        'lunch',
        'food',
      );
      if (d % 3 == 0) {
        await expense(
          at(d, 13),
          2000,
          'MTN airtime',
          'airtime',
          method: PaymentMethod.mobileMoney,
        );
      }
      if (d % 4 == 0) {
        final lines = <PurchaseLine>[];
        for (final (name, price, reorder, _) in catalogue) {
          if (runDown.contains(name) || stock[name]! >= reorder * 2) continue;
          final qty = reorder * 3;
          stock[name] = stock[name]! + qty;
          lines.add(
            PurchaseLine(
              productId: products[name]!.id,
              quantity: qty,
              unitCostNgwee: price * 3 ~/ 4,
            ),
          );
        }
        if (lines.isNotEmpty) {
          await expense(
            at(d, 15),
            lines.fold(0, (s, l) => s + l.totalNgwee),
            'stock from the wholesaler',
            'stock',
            lines: lines,
          );
        }
      }
      if (d % 7 == 0) {
        await expense(at(d, 17), 30000, 'paid the helper', 'wages');
      }
      if (d == 15) {
        await expense(
          at(d, 16),
          15000,
          'ZESCO units',
          'utilities',
          method: PaymentMethod.mobileMoney,
        );
      }
      if (d == 9) {
        // Typed by mistake and cancelled, as FR12 allows.
        clock.at = at(d, 14);
        final wrong = await ports.ledger.recordExpense(
          const ExpenseDraft(
            amountNgwee: 3000,
            description: 'bus fare to town',
            categoryCode: 'transport',
            method: PaymentMethod.cash,
          ),
        );
        clock.at = at(d, 14, 5);
        await ports.ledger.cancelEntry(wrong.id);
      }
    }

    // Today, so far: the morning, then a taxi typed as K250 where transport is
    // usually about K25, for the "Is this right?" check.
    await expense(
      earlierToday(150, 0),
      2500,
      'minibus to Soweto market',
      'transport',
    );
    await expense(
      earlierToday(130, 1),
      500,
      'daily market fee at Soweto market',
      'rent_levy',
    );
    await sales(0, 3, when: (i) => earlierToday(110 - i * 25, 2 + i));
    await expense(
      earlierToday(15, 5),
      25000,
      'taxi with stock',
      'transport',
      leaveOpen: true,
    );
  } finally {
    clock.at = null;
  }
  return answered;
}
