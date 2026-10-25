import '../app/ports.dart';
import '../app/view_data.dart';
import 'database.dart';

/// What the sync badge shows: outbox rows not yet acknowledged by the server,
/// and when the last one was. Read-only; the sync worker (Phase 5) moves rows
/// through pending → in_flight → acked/failed.
class SyncStatusRepository implements SyncPort {
  SyncStatusRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<SyncView> watch() => _db
      .customSelect(
        "SELECT COALESCE(SUM(CASE WHEN status <> 'acked' THEN 1 END), 0) AS waiting, "
        'MAX(acked_at) AS last FROM sync_record',
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
