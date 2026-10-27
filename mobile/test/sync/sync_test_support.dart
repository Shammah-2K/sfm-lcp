// Shared set-up for the sync tests: a phone (database + ports) and how to
// compare its records with the server's copy.
import 'package:drift/native.dart';
import 'package:sfm_lcp/app/app_ports.dart';
import 'package:sfm_lcp/app/ports.dart';
import 'package:sfm_lcp/app/view_data.dart';
import 'package:sfm_lcp/data/database.dart';

import 'fake_server.dart';

const List<String> syncedTables = [
  'business',
  'product',
  'ledger_entry',
  'entry_item',
  'stock_adjustment',
];

class Phone {
  Phone._(this.db, this.ports);

  static Future<Phone> onboarded({String code = 'LSK01'}) async {
    final db = AppDatabase(NativeDatabase.memory());
    final ports = buildAppPorts(db);
    await ports.session.recordConsent();
    await ports.session.start(code, BusinessType.marketStall);
    return Phone._(db, ports);
  }

  final AppDatabase db;
  final AppPorts ports;

  Future<void> close() => db.close();

  /// Every synced table as `{id: row}`, rows as stored on the phone.
  Future<Map<String, Map<String, Map<String, Object?>>>> records() async => {
    for (final t in syncedTables)
      t: {
        for (final r in await db.customSelect('SELECT * FROM $t').get())
          r.data['id']! as String: r.data,
      },
  };

  Future<int> waiting() async => (await ports.sync.watch().first).waiting;

  Future<Map<String, int>> outboxByStatus() async => {
    for (final r
        in await db
            .customSelect(
              'SELECT status, COUNT(*) AS n FROM sync_record GROUP BY status',
            )
            .get())
      r.read<String>('status'): r.read<int>('n'),
  };

  Future<String> addProduct(String name, {int stock = 10}) async {
    await ports.stock.saveProduct(
      ProductDraft(
        name: name,
        priceNgwee: 2500,
        reorderLevel: 2,
        openingStock: stock,
      ),
    );
    return (await ports.stock.watchProducts().first)
        .firstWhere((p) => p.name == name)
        .id;
  }

  Future<EntryRow> sale(int ngwee) => ports.ledger.recordSale(
    SaleDraft(
      amountNgwee: ngwee,
      description: '',
      categoryCode: 'sales_goods',
      method: PaymentMethod.cash,
    ),
  );

  Future<EntryRow> expense(int ngwee, [String what = 'Bus fare']) =>
      ports.ledger.recordExpense(
        ExpenseDraft(
          amountNgwee: ngwee,
          description: what,
          categoryCode: 'transport',
          method: PaymentMethod.mobileMoney,
        ),
      );
}

/// The server's copy in the same shape as [Phone.records], without the
/// server-only `owner` column.
Map<String, Map<String, Map<String, Object?>>> serverRecords(FakeServer s) => {
  for (final t in syncedTables)
    t: {
      for (final e in s.tables[t]!.entries)
        e.key: {...e.value}..remove('owner'),
    },
};

/// How the server's copy differs from the phone's.
class CopyCheck {
  CopyCheck(
    Map<String, Map<String, Map<String, Object?>>> phone,
    Map<String, Map<String, Map<String, Object?>>> server,
  ) {
    for (final t in syncedTables) {
      final p = phone[t]!;
      final s = server[t]!;
      records += p.length;
      for (final id in p.keys) {
        final copy = s[id];
        if (copy == null) {
          missing.add('$t/$id');
        } else if (!_same(p[id]!, copy)) {
          stale.add('$t/$id');
        }
      }
      for (final id in s.keys) {
        if (!p.containsKey(id)) extra.add('$t/$id');
      }
    }
  }

  int records = 0;

  /// On the phone, not on the server: lost.
  final List<String> missing = [];

  /// On the server, not on the phone: duplicated or invented.
  final List<String> extra = [];

  /// On both, but the server has an older version.
  final List<String> stale = [];

  bool get identical => missing.isEmpty && extra.isEmpty && stale.isEmpty;

  static bool _same(Map<String, Object?> a, Map<String, Object?> b) =>
      a.length == b.length && a.keys.every((k) => a[k] == b[k]);

  @override
  String toString() =>
      'records $records, missing ${missing.length}, extra ${extra.length}, '
      'stale ${stale.length}';
}
