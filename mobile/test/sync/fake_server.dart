// An in-memory stand-in for the study server, with the same rules as
// backend/supabase/migrations/20261027000000_sync.sql, and ways to fail.
import 'dart:math';

import 'package:sfm_lcp/sync/sync_api.dart';

/// How the next call should go wrong.
enum Fault {
  none,

  /// No network: the request never reaches the server.
  offline,

  /// The server applies the request, then the reply is lost.
  lostReply,

  /// The access token has expired.
  expiredToken,
}

class FakeServer implements SyncApi {
  FakeServer({Iterable<String> codes = const ['LSK01', 'LSK02']})
    : _codes = {for (final c in codes) c: _Code()};

  final Map<String, _Code> _codes;
  final Map<String, Map<String, Map<String, Object?>>> tables = {
    for (final t in [
      'business',
      'product',
      'ledger_entry',
      'entry_item',
      'stock_adjustment',
    ])
      t: {},
  };

  int _users = 0;
  int _tokens = 0;
  final Map<String, String> _accessOwner = {};
  final Map<String, String> _refreshOwner = {};
  final Set<String> _expired = {};

  // Faults: either queued one by one, or random with a probability.
  final List<Fault> queued = [];
  Random? random;
  double faultRate = 0;

  int calls = 0;
  int signIns = 0;
  int claims = 0;
  int pushes = 0;

  /// Faults actually injected, by kind.
  final Map<Fault, int> injected = {};

  void addCode(String code) => _codes[code] = _Code();

  void releaseCode(String code) => _codes[code]!.claimedBy = null;

  String? claimedBy(String code) => _codes[code]?.claimedBy;

  bool withdrawn(String code) => _codes[code]?.withdrawn ?? false;

  Fault _nextFault() {
    calls++;
    final fault = _pickFault();
    if (fault != Fault.none) injected[fault] = (injected[fault] ?? 0) + 1;
    return fault;
  }

  Fault _pickFault() {
    if (queued.isNotEmpty) return queued.removeAt(0);
    final r = random;
    if (r == null || r.nextDouble() >= faultRate) return Fault.none;
    return const [Fault.offline, Fault.lostReply, Fault.expiredToken][r.nextInt(
      3,
    )];
  }

  /// Runs [apply] under the next fault. Auth and offline faults stop before
  /// the server does anything; a lost reply happens after.
  Future<T> _call<T>(AuthSession? s, T Function(String? owner) apply) async {
    final fault = _nextFault();
    if (fault == Fault.offline) {
      throw const SyncOfflineException('fake: offline');
    }
    String? owner;
    if (s != null) {
      if (fault == Fault.expiredToken) _expired.add(s.accessToken);
      if (_expired.contains(s.accessToken)) {
        throw const SyncAuthException('fake: token expired');
      }
      owner = _accessOwner[s.accessToken];
      if (owner == null) throw const SyncAuthException('fake: unknown token');
    }
    final result = apply(owner);
    if (fault == Fault.lostReply) {
      throw const SyncOfflineException('fake: reply lost');
    }
    return result;
  }

  AuthSession _issue(String user) {
    final access = 'a${_tokens++}';
    final refresh = 'r${_tokens++}';
    _accessOwner[access] = user;
    _refreshOwner[refresh] = user;
    return AuthSession(
      accessToken: access,
      refreshToken: refresh,
      expiresAt: DateTime.utc(2100),
      userId: user,
    );
  }

  /// As on a project where "Allow anonymous sign-ins" is off.
  bool anonymousSignInsDisabled = false;

  @override
  Future<AuthSession> signInAnonymously() => _call(null, (_) {
    if (anonymousSignInsDisabled) {
      throw const SyncServerException(
        '422 anonymous_provider_disabled: Anonymous sign-ins are disabled',
      );
    }
    signIns++;
    return _issue('user${_users++}');
  });

  @override
  Future<AuthSession> refresh(String refreshToken) => _call(null, (_) {
    final user = _refreshOwner[refreshToken];
    if (user == null) throw const SyncAuthException('fake: bad refresh');
    return _issue(user);
  });

  @override
  Future<CodeStatus> checkCode(String code) =>
      _call(null, (_) => _status(code, null));

  CodeStatus _status(String code, String? me) {
    final c = _codes[code];
    if (c == null) return CodeStatus.unknown;
    if (c.withdrawn) return CodeStatus.withdrawn;
    if (c.claimedBy != null && c.claimedBy != me) return CodeStatus.taken;
    return CodeStatus.ok;
  }

  @override
  Future<CodeStatus> claimCode(AuthSession session, String code) =>
      _call(session, (me) {
        claims++;
        final status = _status(code, me);
        if (status != CodeStatus.ok) return status;
        final holds = _codes.entries.any(
          (e) => e.value.claimedBy == me && e.key != code,
        );
        if (holds) return CodeStatus.taken;
        _codes[code]!.claimedBy = me;
        return CodeStatus.ok;
      });

  @override
  Future<void> push(AuthSession session, SyncBatch batch) => _call(session, (
    me,
  ) {
    pushes++;
    final code = _codes.entries
        .where((e) => e.value.claimedBy == me && !e.value.withdrawn)
        .map((e) => e.key)
        .firstOrNull;
    if (code == null) {
      throw const SyncAuthException('fake: no participant code claimed');
    }
    // Check everything first: all or nothing, as in one transaction.
    final staged = {
      for (final e in tables.entries)
        e.key: {
          for (final r in e.value.entries) r.key: {...r.value},
        },
    };
    void insert(String table, Map<String, Object?> row) {
      staged[table]![row['id']! as String] = {...row, 'owner': me};
    }

    Map<String, Object?>? mine(String table, Object? id) {
      final r = staged[table]![id];
      return r != null && r['owner'] == me ? r : null;
    }

    for (final b in batch['business'] ?? const <Map<String, Object?>>[]) {
      if (b['participant_code'] != code) {
        throw const SyncServerException('fake: wrong code');
      }
      if (!staged['business']!.containsKey(b['id'])) insert('business', b);
    }
    final myBiz = staged['business']!.values
        .where((b) => b['owner'] == me)
        .map((b) => b['id'])
        .firstOrNull;
    for (final p in batch['product'] ?? const <Map<String, Object?>>[]) {
      if (p['business_id'] != myBiz) {
        throw const SyncServerException('fake: product for another business');
      }
      final old = staged['product']![p['id']];
      if (old == null) {
        insert('product', p);
      } else if (old['owner'] == me &&
          (p['updated_at']! as int) > (old['updated_at']! as int)) {
        staged['product']![p['id']! as String] = {...p, 'owner': me};
      }
    }
    final entries = [...?batch['ledger_entry']]
      ..sort(
        (a, b) => (a['reverses_id'] == null ? 0 : 1).compareTo(
          b['reverses_id'] == null ? 0 : 1,
        ),
      );
    for (final e in entries) {
      if (e['business_id'] != myBiz) {
        throw const SyncServerException('fake: entry for another business');
      }
      final reverses = e['reverses_id'];
      if (reverses != null && staged['ledger_entry']![reverses] == null) {
        throw const SyncServerException('fake: reversal before original');
      }
      final old = staged['ledger_entry']![e['id']];
      if (old == null) {
        insert('ledger_entry', e);
      } else if (old['owner'] == me &&
          (e['updated_at']! as int) > (old['updated_at']! as int)) {
        // Only the fields the phone may change after saving.
        for (final f in [
          'final_category',
          'anomaly_reviewed_at',
          'updated_at',
        ]) {
          old[f] = e[f];
        }
      }
    }
    for (final i in batch['entry_item'] ?? const <Map<String, Object?>>[]) {
      if (mine('ledger_entry', i['entry_id']) == null ||
          staged['product']![i['product_id']] == null) {
        throw const SyncServerException('fake: item before its entry');
      }
      if (!staged['entry_item']!.containsKey(i['id'])) {
        insert('entry_item', i);
      }
    }
    for (final a
        in batch['stock_adjustment'] ?? const <Map<String, Object?>>[]) {
      if (mine('product', a['product_id']) == null) {
        throw const SyncServerException('fake: change before its product');
      }
      if (!staged['stock_adjustment']!.containsKey(a['id'])) {
        insert('stock_adjustment', a);
      }
    }
    for (final e in staged.entries) {
      tables[e.key] = e.value;
    }
  });

  @override
  Future<void> withdraw(AuthSession session) => _call(session, (me) {
    for (final t in tables.values) {
      t.removeWhere((_, r) => r['owner'] == me);
    }
    for (final c in _codes.values) {
      if (c.claimedBy == me) c.withdrawn = true;
    }
  });
}

class _Code {
  String? claimedBy;
  bool withdrawn = false;
}
