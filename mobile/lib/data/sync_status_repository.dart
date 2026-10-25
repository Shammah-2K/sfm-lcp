import '../app/ports.dart';
import '../app/view_data.dart';
import 'database.dart';

/// What the sync badge shows (FR9).
///
/// [SyncView.waiting] counts *records the user would recognise* that still
/// have an unsent change: each entry, product, stock change or the
/// participant counts once, however many outbox rows it has. Item lines are
/// not counted separately because they travel with their sale or purchase,
/// and a record edited twice before syncing is still one record waiting.
/// Failed and in-flight rows count as waiting until the server acknowledges.
///
/// Read-only; the sync worker (Phase 5) moves rows through
/// pending → in_flight → acked/failed.
class SyncStatusRepository implements SyncPort {
  SyncStatusRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<SyncView> watch() => _db
      .customSelect(
        'SELECT '
        "(SELECT COUNT(DISTINCT entity_table || ':' || entity_id) FROM sync_record "
        "  WHERE status <> 'acked' AND entity_table <> 'entry_item') AS waiting, "
        '(SELECT MAX(acked_at) FROM sync_record) AS last',
        readsFrom: {_db.syncRecord},
      )
      .watchSingle()
      .map((r) {
        final last = r.readNullable<int>('last');
        return SyncView(
          waiting: r.read<int>('waiting'),
          lastSyncedAt: last == null
              ? null
              : DateTime.fromMillisecondsSinceEpoch(last, isUtc: true),
        );
      });
}
