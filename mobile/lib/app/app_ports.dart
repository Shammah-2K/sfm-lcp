import '../data/database.dart';
import '../data/ledger_repository.dart';
import '../data/session_repository.dart';
import '../data/stock_repository.dart';
import '../data/sync_status_repository.dart';
import '../data/totals_repository.dart';
import '../domain/models.dart';
import '../sync/sync_scheduler.dart';
import 'ports.dart';

/// The composition root: the real implementation of every port, built once
/// over one database. The ML phase replaces the two stand-in models here.
/// Without a [syncScheduler], records stay on the phone (sync not set up).
AppPorts buildAppPorts(
  AppDatabase db, {
  CategoryPort categoriser = const NoCategoriser(),
  AnomalyDetector detector = const NoAnomalyDetector(),
  SyncScheduler? syncScheduler,
  DateTime Function()? clock,
}) {
  final business = BusinessRef(db);
  return AppPorts(
    session: SessionRepository(db, clock: clock),
    ledger: LedgerRepository(db, business, detector: detector, clock: clock),
    totals: TotalsRepository(db, business),
    categories: categoriser,
    stock: StockRepository(db, business, clock: clock),
    sync: SyncStatusRepository(db, scheduler: syncScheduler),
  );
}
