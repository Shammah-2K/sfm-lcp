import 'dart:convert';

import 'package:drift/drift.dart';

import '../data/database.dart';
import '../data/session_repository.dart';
import 'sync_api.dart';

/// How one sync run ended.
enum SyncOutcome {
  /// Nothing was waiting.
  idle,

  /// Everything waiting was sent and acknowledged.
  sent,

  /// No network or no answer; the rows wait for the next run.
  offline,

  /// The server refused; the rows wait, and the error is kept on them.
  failed,

  /// The participant code is not usable (see `code_problem`).
  blocked,

  /// The participant stopped taking part; nothing is sent.
  withdrawn,
}

/// Sends the outbox to the study server (FR9, UC11, NFR4).
///
/// The outbox is `sync_record`, filled by the schema's triggers in the same
/// transaction as every change, so nothing can be saved without being queued.
/// One run:
///
/// 1. Rows left `in_flight` by a run that never finished (app killed, phone
///    off) go back to `pending`. The server may or may not have them; sending
///    again is safe because every row keeps its phone-made UUID.
/// 2. If the participant withdrew, ask the server once to delete its copy,
///    then stop. Nothing else is ever sent.
/// 3. Sign in (once per install) and claim the participant code (once).
/// 4. Take the oldest waiting rows, mark them `in_flight`, send the *current*
///    state of each record they point at, and mark them `acked` only after
///    the server confirms. Repeat until nothing is waiting.
///
/// A failure leaves the rows `failed` with the error and an attempt count;
/// they are sent again on the next run. Rows are taken in outbox order, so a
/// sale's item lines never arrive before the sale or its products.
class SyncWorker {
  SyncWorker(
    this._db,
    this.api, {
    DateTime Function()? clock,
    this.batchSize = 100,
  }) : _now = clock ?? DateTime.now;

  final AppDatabase _db;
  final SyncApi api;
  final DateTime Function() _now;

  /// Outbox rows per request. Small enough for a slow connection.
  final int batchSize;

  int _nowMs() => _now().toUtc().millisecondsSinceEpoch;

  /// Tables in the order the server must apply them.
  static const List<String> _tables = [
    'business',
    'product',
    'ledger_entry',
    'entry_item',
    'stock_adjustment',
  ];

  Future<SyncOutcome> runOnce() async {
    await _releaseInFlight();
    final settings = await _settings();
    if (settings.containsKey(AppStateNames.withdrawnAt)) {
      return _withdraw(settings);
    }
    final code = await _participantCode();
    if (code == null || !await _hasWaiting()) return SyncOutcome.idle;

    try {
      var session = await _session(settings);
      if (settings[AppStateNames.claimedCode] != code) {
        final status = await _withAuth(
          session,
          (s) => api.claimCode(s, code),
          (s) => session = s,
        );
        if (status != CodeStatus.ok) {
          // The server answered; the code problem says what is wrong.
          await _clearTrouble();
          await _set(AppStateNames.codeProblem, status.name);
          return SyncOutcome.blocked;
        }
        await _set(AppStateNames.claimedCode, code);
        await _clear(AppStateNames.codeProblem);
      }
      while (true) {
        final rows = await _takeBatch();
        if (rows.isEmpty) {
          await _clearTrouble();
          return SyncOutcome.sent;
        }
        try {
          final batch = await _batchFor(rows);
          await _withAuth(
            session,
            (s) => api.push(s, batch),
            (s) => session = s,
          );
        } catch (e) {
          await _markFailed(rows, e);
          rethrow;
        }
        await _markAcked(rows);
      }
    } on SyncOfflineException catch (e) {
      await _setTrouble('noNetwork', e);
      return SyncOutcome.offline;
    } on SyncServerException catch (e) {
      // e.g. anonymous sign-ins switched off, or a batch refused
      await _setTrouble('server', e);
      return SyncOutcome.failed;
    } on SyncAuthException catch (e) {
      await _setTrouble('server', e);
      return SyncOutcome.failed;
    }
  }

  /// Remembers how this run failed, for the account sheet.
  Future<void> _setTrouble(String kind, Object error) async {
    await _set(AppStateNames.syncTrouble, kind);
    final detail = '$error';
    await _set(
      AppStateNames.syncTroubleDetail,
      detail.length > 500 ? detail.substring(0, 500) : detail,
    );
  }

  Future<void> _clearTrouble() async {
    await _clear(AppStateNames.syncTrouble);
    await _clear(AppStateNames.syncTroubleDetail);
  }

  // ------------------------------------------------------------- withdrawal

  Future<SyncOutcome> _withdraw(Map<String, String> settings) async {
    if (settings.containsKey(AppStateNames.withdrawConfirmedAt)) {
      return SyncOutcome.withdrawn;
    }
    // Never claimed a code: the server holds nothing from this phone.
    if (!settings.containsKey(AppStateNames.claimedCode)) {
      await _set(AppStateNames.withdrawConfirmedAt, '${_nowMs()}');
      return SyncOutcome.withdrawn;
    }
    try {
      final session = await _session(settings);
      await _withAuth(session, api.withdraw, (_) {});
      await _set(AppStateNames.withdrawConfirmedAt, '${_nowMs()}');
    } on SyncOfflineException {
      // Asked again on the next run.
    } on SyncServerException {
      // Asked again on the next run.
    } on SyncAuthException {
      // Asked again on the next run.
    }
    return SyncOutcome.withdrawn;
  }

  // ---------------------------------------------------------------- session

  /// The saved sign-in, refreshed when close to expiry; a first sign-in if
  /// there is none.
  Future<AuthSession> _session(Map<String, String> settings) async {
    final saved = settings[AppStateNames.authSession];
    if (saved == null) {
      return _saveSession(await api.signInAnonymously());
    }
    final session = AuthSession.fromJson(
      jsonDecode(saved) as Map<String, Object?>,
    );
    final soon = _now().toUtc().add(const Duration(minutes: 1));
    if (session.expiresAt.isAfter(soon)) return session;
    return _saveSession(await api.refresh(session.refreshToken));
  }

  /// Runs [call]; if the server rejects the token, refreshes once and retries.
  Future<T> _withAuth<T>(
    AuthSession session,
    Future<T> Function(AuthSession) call,
    void Function(AuthSession) onRefreshed,
  ) async {
    try {
      return await call(session);
    } on SyncAuthException {
      final fresh = await _saveSession(await api.refresh(session.refreshToken));
      onRefreshed(fresh);
      return call(fresh);
    }
  }

  Future<AuthSession> _saveSession(AuthSession s) async {
    await _set(AppStateNames.authSession, jsonEncode(s.toJson()));
    return s;
  }

  // ----------------------------------------------------------------- outbox

  Future<void> _releaseInFlight() => _db.customUpdate(
    "UPDATE sync_record SET status = 'pending' WHERE status = 'in_flight'",
    updates: {_db.syncRecord},
    // Updates, not inserts: the scheduler starts a run only on new rows.
    updateKind: UpdateKind.update,
  );

  Future<bool> _hasWaiting() async =>
      (await _db
              .customSelect(
                "SELECT EXISTS (SELECT 1 FROM sync_record WHERE status <> 'acked') AS w",
              )
              .getSingle())
          .read<bool>('w');

  /// The oldest waiting outbox rows, marked `in_flight`.
  Future<List<_OutboxRow>> _takeBatch() => _db.transaction(() async {
    final rows = await _db
        .customSelect(
          'SELECT id, entity_table, entity_id FROM sync_record '
          "WHERE status IN ('pending', 'failed') ORDER BY id LIMIT ?",
          variables: [Variable(batchSize)],
        )
        .get();
    final taken = [
      for (final r in rows)
        _OutboxRow(
          r.read<int>('id'),
          r.read<String>('entity_table'),
          r.read<String>('entity_id'),
        ),
    ];
    if (taken.isNotEmpty) {
      await _db.customUpdate(
        "UPDATE sync_record SET status = 'in_flight', last_attempt_at = ? "
        'WHERE id IN (${List.filled(taken.length, '?').join(', ')})',
        variables: [Variable(_nowMs()), for (final t in taken) Variable(t.id)],
        updates: {_db.syncRecord},
        updateKind: UpdateKind.update,
      );
    }
    return taken;
  });

  /// The current state of every record the rows point at, once each.
  Future<SyncBatch> _batchFor(List<_OutboxRow> rows) async {
    final batch = <String, List<Map<String, Object?>>>{};
    for (final table in _tables) {
      final ids = {
        for (final r in rows)
          if (r.table == table) r.entityId,
      }.toList();
      if (ids.isEmpty) continue;
      final found = await _db
          .customSelect(
            'SELECT * FROM $table '
            'WHERE id IN (${List.filled(ids.length, '?').join(', ')})',
            variables: [for (final id in ids) Variable(id)],
          )
          .get();
      batch[table] = [for (final r in found) r.data];
    }
    return batch;
  }

  Future<void> _markAcked(List<_OutboxRow> rows) => _db.customUpdate(
    "UPDATE sync_record SET status = 'acked', acked_at = ?, last_error = NULL "
    'WHERE id IN (${List.filled(rows.length, '?').join(', ')})',
    variables: [Variable(_nowMs()), for (final r in rows) Variable(r.id)],
    updates: {_db.syncRecord},
    updateKind: UpdateKind.update,
  );

  Future<void> _markFailed(List<_OutboxRow> rows, Object error) {
    final message = '$error';
    return _db.customUpdate(
      "UPDATE sync_record SET status = 'failed', attempts = attempts + 1, "
      'last_error = ? '
      'WHERE id IN (${List.filled(rows.length, '?').join(', ')})',
      variables: [
        Variable(message.length > 500 ? message.substring(0, 500) : message),
        for (final r in rows) Variable(r.id),
      ],
      updates: {_db.syncRecord},
      updateKind: UpdateKind.update,
    );
  }

  // --------------------------------------------------------------- settings

  Future<String?> _participantCode() async => (await (_db.select(
    _db.business,
  )..limit(1)).getSingleOrNull())?.participantCode;

  Future<Map<String, String>> _settings() async => {
    for (final s in await _db.select(_db.appState).get()) s.name: s.value,
  };

  Future<void> _set(String name, String value) => _db
      .into(_db.appState)
      .insertOnConflictUpdate(
        AppStateCompanion.insert(name: name, value: value),
      );

  Future<void> _clear(String name) =>
      (_db.delete(_db.appState)..where((s) => s.name.equals(name))).go();
}

class _OutboxRow {
  const _OutboxRow(this.id, this.table, this.entityId);

  final int id;
  final String table;
  final String entityId;
}
