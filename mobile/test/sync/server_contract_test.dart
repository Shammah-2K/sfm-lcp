// The server SQL must accept exactly what the phone sends. These checks read
// backend/supabase/migrations/*.sql as text, so a column added on the phone
// (or a category changed) without the matching server change fails here.
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sfm_lcp/data/database.dart';
import 'package:sfm_lcp/domain/codebook.dart';

import 'sync_test_support.dart';

void main() {
  final sql = File(
    '../backend/supabase/migrations/20261027000000_sync.sql',
  ).readAsStringSync();

  /// Columns sync_push reads for [table]: the `as x(...)` list after
  /// `batch -> 'table'` in its insert.
  Set<String> pushColumns(String table) {
    final match = RegExp(
      "insert into $table \\(.*?batch -> '$table', '\\[\\]'\\)\\)\\s*"
      r'as x\((.*?)\)',
      dotAll: true,
    ).firstMatch(sql);
    expect(match, isNotNull, reason: 'sync_push has no insert for $table');
    return {
      for (final c in match!.group(1)!.split(','))
        c.trim().split(RegExp(r'\s+')).first,
    };
  }

  test(
    'sync_push reads every column the phone sends, for every table',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      for (final table in syncedTables) {
        final phone = {
          for (final r
              in await db.customSelect('PRAGMA table_info($table)').get())
            r.read<String>('name'),
        };
        expect(pushColumns(table), phone, reason: table);
      }
    },
  );

  test('the server codebook matches the app codebook', () {
    final rows = RegExp(
      r"\('(\w+)',\s*'([^']+)',\s*'(income|expense)'",
    ).allMatches(sql);
    final server = {
      for (final m in rows) m.group(1)!: (m.group(2)!, m.group(3)!),
    };
    final app = {
      for (final c in codebook)
        c.code: (c.name, c.type.name == 'sale' ? 'income' : 'expense'),
    };
    expect(server, app);
  });

  test(
    'the app may call only what it needs; release_code is researcher-only',
    () {
      expect(
        sql,
        contains('grant execute on function public.check_code(text) to anon'),
      );
      expect(
        sql,
        contains(
          'revoke all on function public.release_code(text) from public, anon, authenticated',
        ),
      );
      expect(
        sql,
        isNot(contains('grant execute on function public.release_code')),
      );
      for (final t in [...syncedTables, 'participant_code', 'category']) {
        expect(sql, contains('alter table public.$t'), reason: '$t has RLS on');
      }
    },
  );
}
