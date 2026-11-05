import 'package:drift/drift.dart' show Variable;

import '../app/ports.dart';
import '../app/view_data.dart';
import '../sync/sync_api.dart';
import '../sync/sync_scheduler.dart';
import 'database.dart';
import 'session_repository.dart';

/// What the sync badge and account sheet show (FR9), and the two things the
/// UI can ask of sync: check a code during onboarding, and "Sync now".
///
/// [SyncView.waiting] counts *records the user would recognise* that still
/// have an unsent change: each entry, product, stock change or the
/// participant counts once, however many outbox rows it has. Item lines are
/// not counted separately because they travel with their sale or purchase,
/// and a record edited twice before syncing is still one record waiting.
/// Failed and in-flight rows count as waiting until the server acknowledges.
///
/// With no [SyncScheduler] (a build without the server's address, and most
/// tests) records stay on the phone and the view says sync is not set up.
class SyncStatusRepository implements SyncPort {
  SyncStatusRepository(this._db, {SyncScheduler? scheduler})
    : _scheduler = scheduler;

  final AppDatabase _db;
  final SyncScheduler? _scheduler;

  @override
  Stream<SyncView> watch() => _db
      .customSelect(
        'SELECT '
        "(SELECT COUNT(DISTINCT entity_table || ':' || entity_id) FROM sync_record "
        "  WHERE status <> 'acked' AND entity_table <> 'entry_item') AS waiting, "
        '(SELECT MAX(acked_at) FROM sync_record) AS last, '
        "EXISTS (SELECT 1 FROM app_state WHERE name = 'withdrawn_at') AS withdrawn, "
        '(SELECT value FROM app_state WHERE name = ?) AS problem, '
        '(SELECT value FROM app_state WHERE name = ?) AS trouble',
        variables: [
          Variable(AppStateNames.codeProblem),
          Variable(AppStateNames.syncTrouble),
        ],
        readsFrom: {_db.syncRecord, _db.appState},
      )
      .watchSingle()
      .map((r) {
        final last = r.readNullable<int>('last');
        final problem = r.readNullable<String>('problem');
        final trouble = r.readNullable<String>('trouble');
        return SyncView(
          waiting: r.read<int>('waiting'),
          withdrawn: r.read<bool>('withdrawn'),
          lastSyncedAt: last == null
              ? null
              : DateTime.fromMillisecondsSinceEpoch(last, isUtc: true),
          enabled: _scheduler != null,
          problem: problem == null ? null : CodeCheck.values.byName(problem),
          trouble: trouble == null ? null : SyncTrouble.values.byName(trouble),
        );
      });

  @override
  Future<CodeCheck?> checkCode(String code) async {
    final scheduler = _scheduler;
    if (scheduler == null) return null;
    try {
      return switch (await scheduler.worker.api.checkCode(code)) {
        CodeStatus.ok => CodeCheck.ok,
        CodeStatus.unknown => CodeCheck.unknown,
        CodeStatus.taken => CodeCheck.taken,
        CodeStatus.withdrawn => CodeCheck.withdrawn,
      };
    } on SyncOfflineException {
      return null;
    } on SyncServerException {
      return null;
    } on SyncAuthException {
      return null;
    }
  }

  @override
  Future<void> syncNow() async {
    await _scheduler?.runNow();
  }
}
