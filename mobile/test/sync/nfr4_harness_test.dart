// NFR4 (fault tolerance): "No lost or duplicated records across N
// interrupted-sync trials."
//
// Each trial is one phone used at random — sales, expenses, purchases,
// cancellations, category changes, products, stock changes, stop selling —
// with sync runs in between. A share of server calls go wrong (no network,
// the reply lost after the server applied it, an expired token) and the app
// is sometimes "killed" mid-run, leaving rows in flight. At the end the
// network comes back, and the server's copy must equal the phone's records:
// nothing missing (lost), nothing extra (duplicated), nothing out of date.
//
// Run with more trials:  flutter test test/sync/nfr4_harness_test.dart
//                          --dart-define=NFR4_TRIALS=200
// The summary line is printed for the evaluation chapter. The server here is
// the in-memory stand-in (fake_server.dart); its rules follow the SQL.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sfm_lcp/app/view_data.dart';
import 'package:sfm_lcp/sync/sync_worker.dart';

import 'fake_server.dart';
import 'sync_test_support.dart';

const int trials = int.fromEnvironment('NFR4_TRIALS', defaultValue: 50);
const int stepsPerTrial = 40;
const double faultRate = 0.3;

void main() {
  test(
    'NFR4: $trials interrupted-sync trials, nothing lost or doubled',
    () async {
      var records = 0;
      var calls = 0;
      final faults = <Fault, int>{};
      var kills = 0;
      var runs = 0;
      final failures = <String>[];

      for (var trial = 0; trial < trials; trial++) {
        final rng = Random(trial);
        final phone = await Phone.onboarded();
        final server = FakeServer()
          ..random = rng
          ..faultRate = faultRate;
        final worker = SyncWorker(
          phone.db,
          server,
          batchSize: 1 + rng.nextInt(8),
        );
        final use = _RandomUse(phone, rng);

        for (var step = 0; step < stepsPerTrial; step++) {
          await use.step();
          final roll = rng.nextDouble();
          if (roll < 0.3) {
            runs++;
            await worker.runOnce();
          } else if (roll < 0.4) {
            // Killed after taking a batch, before hearing back.
            kills++;
            await phone.db.customUpdate(
              "UPDATE sync_record SET status = 'in_flight' "
              "WHERE status IN ('pending', 'failed')",
              updates: {phone.db.syncRecord},
            );
          }
        }
        // The network comes back.
        server.faultRate = 0;
        var outcome = SyncOutcome.idle;
        for (var i = 0; i < 3 && outcome != SyncOutcome.sent; i++) {
          outcome = await worker.runOnce();
          runs++;
        }
        for (final e in server.injected.entries) {
          faults[e.key] = (faults[e.key] ?? 0) + e.value;
        }
        calls += server.calls;

        final check = CopyCheck(await phone.records(), serverRecords(server));
        records += check.records;
        if (!check.identical || await phone.waiting() != 0) {
          failures.add('trial $trial: $check, last outcome $outcome');
        }
        await phone.close();
      }

      // ignore: avoid_print
      print(
        'NFR4 harness: $trials trials, $records records, $runs sync runs, '
        '$calls server calls, faults injected: '
        '${faults[Fault.offline] ?? 0} no network, '
        '${faults[Fault.lostReply] ?? 0} lost replies, '
        '${faults[Fault.expiredToken] ?? 0} expired tokens; '
        '$kills simulated kills; trials with lost, extra or stale '
        'records: ${failures.length}',
      );
      expect(failures, isEmpty);
    },
  );
}

/// One random thing a trader might do.
class _RandomUse {
  _RandomUse(this.phone, this.rng);

  final Phone phone;
  final Random rng;
  final List<String> _entries = [];
  int _names = 0;

  Future<List<ProductRow>> _products() =>
      phone.ports.stock.watchProducts().first;

  Future<void> step() async {
    final ledger = phone.ports.ledger;
    try {
      switch (rng.nextInt(9)) {
        case 0:
          await phone.addProduct('P${_names++}', stock: rng.nextInt(20));
        case 1 || 2:
          _entries.add((await phone.sale(100 + rng.nextInt(50000))).id);
        case 3:
          _entries.add((await phone.expense(100 + rng.nextInt(20000))).id);
        case 4:
          final inStock = (await _products()).where((p) => p.inStock > 0);
          if (inStock.isEmpty) return;
          final p = inStock.elementAt(rng.nextInt(inStock.length));
          final sale = await ledger.recordSale(
            SaleDraft(
              amountNgwee: 0,
              description: '',
              categoryCode: 'sales_goods',
              method: PaymentMethod.cash,
              lines: [SaleLine(productId: p.id, quantity: 1)],
            ),
          );
          _entries.add(sale.id);
        case 5:
          final products = await _products();
          if (products.isEmpty) return;
          final p = products[rng.nextInt(products.length)];
          final cost = 50 + rng.nextInt(3000);
          final qty = 1 + rng.nextInt(5);
          final buy = await ledger.recordExpense(
            ExpenseDraft(
              amountNgwee: cost * qty,
              description: 'Stock',
              categoryCode: 'stock',
              method: PaymentMethod.cash,
              lines: [
                PurchaseLine(
                  productId: p.id,
                  quantity: qty,
                  unitCostNgwee: cost,
                ),
              ],
            ),
          );
          _entries.add(buy.id);
        case 6:
          if (_entries.isEmpty) return;
          await ledger.cancelEntry(
            _entries.removeAt(rng.nextInt(_entries.length)),
          );
        case 7:
          if (_entries.isEmpty) return;
          final id = _entries[rng.nextInt(_entries.length)];
          final e = await ledger.watchEntry(id).first;
          if (e == null) return;
          await ledger.changeCategory(
            id,
            e.isIncome ? 'other_income' : 'other_expense',
          );
        case 8:
          final products = await _products();
          if (products.isEmpty) return;
          final p = products[rng.nextInt(products.length)];
          if (rng.nextBool()) {
            await phone.ports.stock.adjust(
              StockAdjustmentDraft(
                productId: p.id,
                delta: 1 + rng.nextInt(4),
                reason: AdjustReason.count,
              ),
            );
          } else {
            await phone.ports.stock.stopSelling(p.id);
          }
      }
    } on ArgumentError {
      // A rule refused it (e.g. not enough stock), as it would in the app.
    } on StateError {
      // e.g. cancelling a purchase whose stock was sold: refused, as in the app.
    }
  }
}
