// Upgrading a phone that already has the version-1 database.
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sfm_lcp/app/app_ports.dart';
import 'package:sfm_lcp/data/database.dart';

void main() {
  test('version 1 → 2 adds app_state and keeps the existing records', () async {
    final v1 = File('lib/data/schema.sql').readAsStringSync();
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          // A version-1 database as the Phase 2 build left it.
          raw.execute(v1);
          raw.execute(
            "INSERT INTO business VALUES ('b1', 'LSK01', NULL, 1792994400000)",
          );
          raw.execute(
            "INSERT INTO category VALUES ('sales_goods', 'Sales of goods', 'income', 'shopping_basket', 1)",
          );
          raw.userVersion = 1;
        },
      ),
    );
    final ports = buildAppPorts(db);

    final state = await ports.session.state();
    expect(state.participantCode, 'LSK01', reason: 'existing participant kept');
    expect(
      state.consented,
      isFalse,
      reason: 'no consent recorded before version 2',
    );

    await ports.session.recordConsent();
    expect((await ports.session.state()).consented, isTrue);
    await db.close();
  });
}
