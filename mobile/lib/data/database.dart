import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../domain/codebook.dart';

part 'database.g.dart';

/// The on-device database: Chapter 3's schema (`schema.sql`), unchanged, with
/// every table, index, trigger and view. Drift generates typed classes for
/// each table from `schema.drift`.
///
/// Rules the schema enforces on its own, so no Dart code has to:
/// * ledger entries cannot be deleted or have their financial fields changed;
/// * a reversal must cancel its original exactly, and only once;
/// * a sale needs an income category and an expense an expense category;
/// * an expense needs a description;
/// * every insert or update is queued in `sync_record` in the same transaction.
@DriftDatabase(include: {'schema.drift', 'app_state.drift'})
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// The app's database file, `sfm_lcp.sqlite` in the app documents folder.
  factory AppDatabase.open() => AppDatabase(driftDatabase(name: 'sfm_lcp'));

  /// 1: Chapter 3's schema. 2: adds the local `app_state` table.
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await batch((b) {
        b.insertAll(category, [
          for (final c in codebook)
            CategoryCompanion.insert(
              code: Value(c.code),
              name: c.name,
              kind: c.kind,
              icon: c.icon,
              sortOrder: Value(c.sortOrder),
            ),
        ]);
      });
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) await m.createTable(appState);
    },
    // Foreign keys are off by default in SQLite and must be switched on
    // for every connection, outside any transaction.
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
