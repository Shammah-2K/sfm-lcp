import 'dart:async';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:flutter/widgets.dart';

import '../data/database.dart';
import 'sync_worker.dart';

/// When to run the [SyncWorker] (UC11) while the app is open:
///
/// * on start and whenever the app comes back to the front;
/// * a few seconds after something is saved (a new outbox row), so a burst
///   of entries goes in one request;
/// * every few minutes, to catch the network coming back.
///
/// After a failed or offline run, automatic runs wait longer each time
/// (30 s, 1 min, 2 min … up to 15 min). "Sync now" always runs at once.
/// Runs never overlap: a request during a run starts one more run after it.
class SyncScheduler {
  SyncScheduler(
    this._db,
    this.worker, {
    this.period = const Duration(minutes: 5),
    this.debounce = const Duration(seconds: 3),
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now;

  final AppDatabase _db;
  final SyncWorker worker;
  final Duration period;
  final Duration debounce;
  final DateTime Function() _now;

  StreamSubscription<Set<TableUpdate>>? _saves;
  Timer? _periodic;
  Timer? _debounced;
  AppLifecycleListener? _lifecycle;

  Future<SyncOutcome>? _running;
  bool _again = false;
  int _failures = 0;
  DateTime? _notBefore;

  void start() {
    _saves = _db
        .tableUpdates(
          TableUpdateQuery.onTable(
            _db.syncRecord,
            limitUpdateKind: UpdateKind.insert,
          ),
        )
        .listen((_) {
          _debounced?.cancel();
          _debounced = Timer(debounce, _automatic);
        });
    _periodic = Timer.periodic(period, (_) => _automatic());
    _lifecycle = AppLifecycleListener(onResume: _automatic);
    _automatic();
  }

  void dispose() {
    _saves?.cancel();
    _periodic?.cancel();
    _debounced?.cancel();
    _lifecycle?.dispose();
  }

  void _automatic() {
    final wait = _notBefore;
    if (wait != null && _now().isBefore(wait)) return;
    unawaited(runNow());
  }

  /// Runs now, or joins the run already going.
  Future<SyncOutcome> runNow() async {
    final current = _running;
    if (current != null) {
      _again = true;
      return current;
    }
    final run = _runUntilQuiet();
    _running = run;
    try {
      return await run;
    } finally {
      _running = null;
    }
  }

  Future<SyncOutcome> _runUntilQuiet() async {
    SyncOutcome outcome;
    do {
      _again = false;
      try {
        outcome = await worker.runOnce();
      } catch (e, s) {
        // A bug or a database error: keep the app running and try later.
        debugPrint('Sync run failed: $e\n$s');
        outcome = SyncOutcome.failed;
      }
    } while (_again);
    _backOff(outcome);
    return outcome;
  }

  void _backOff(SyncOutcome outcome) {
    if (outcome == SyncOutcome.offline || outcome == SyncOutcome.failed) {
      _failures++;
      final seconds = min(30 * pow(2, _failures - 1).toInt(), 15 * 60);
      _notBefore = _now().add(Duration(seconds: seconds));
    } else {
      _failures = 0;
      _notBefore = null;
    }
  }
}
