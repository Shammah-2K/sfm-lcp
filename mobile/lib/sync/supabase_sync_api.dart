import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'sync_api.dart';

/// Where the study server is. Given at build time, never committed:
///
///   flutter run --dart-define-from-file=supabase.json
///
/// with `supabase.json` holding SUPABASE_URL and SUPABASE_ANON_KEY (see
/// `supabase.example.json`). The anon key is public by design; the database
/// functions decide what a caller may do. The service-role key never goes in
/// the app.
class SyncConfig {
  const SyncConfig({required this.url, required this.anonKey});

  final Uri url;
  final String anonKey;

  /// Null when the build was made without the two values: the app then
  /// works offline only and says that sync is not set up.
  static SyncConfig? fromEnvironment() {
    const url = String.fromEnvironment('SUPABASE_URL');
    const key = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (url.isEmpty || key.isEmpty) return null;
    return SyncConfig(url: Uri.parse(url), anonKey: key);
  }
}

/// [SyncApi] over Supabase's REST endpoints: Auth for the anonymous sign-in,
/// PostgREST `rpc/` for the functions in
/// `backend/supabase/migrations/20261027000000_sync.sql`.
class SupabaseSyncApi implements SyncApi {
  SupabaseSyncApi(
    this._config, {
    http.Client? client,
    DateTime Function()? clock,
  }) : _client = client ?? http.Client(),
       _now = clock ?? DateTime.now;

  final SyncConfig _config;
  final http.Client _client;
  final DateTime Function() _now;

  static const Duration _timeout = Duration(seconds: 20);

  Uri _at(String path) => _config.url.resolve(path);

  Map<String, String> _headers([String? bearer]) => {
    'apikey': _config.anonKey,
    'Authorization': 'Bearer ${bearer ?? _config.anonKey}',
    'Content-Type': 'application/json',
  };

  Future<Object?> _post(Uri uri, Object? body, {String? bearer}) async {
    final http.Response r;
    try {
      r = await _client
          .post(uri, headers: _headers(bearer), body: jsonEncode(body))
          .timeout(_timeout);
    } on TimeoutException {
      throw const SyncOfflineException('No answer from the server');
    } on http.ClientException catch (e) {
      throw SyncOfflineException(e.message);
    }
    if (r.statusCode == 401 || r.statusCode == 403) {
      throw SyncAuthException('${r.statusCode} ${r.body}');
    }
    if (r.statusCode >= 500) {
      throw SyncOfflineException('Server error ${r.statusCode}');
    }
    if (r.statusCode >= 400) {
      throw SyncServerException('${r.statusCode} ${r.body}');
    }
    return r.body.isEmpty ? null : jsonDecode(r.body);
  }

  AuthSession _session(Object? body) {
    final j = body! as Map<String, Object?>;
    final expiresIn = (j['expires_in']! as num).toInt();
    return AuthSession(
      accessToken: j['access_token']! as String,
      refreshToken: j['refresh_token']! as String,
      expiresAt: _now().toUtc().add(Duration(seconds: expiresIn)),
      userId: (j['user']! as Map<String, Object?>)['id']! as String,
    );
  }

  @override
  Future<AuthSession> signInAnonymously() async =>
      _session(await _post(_at('auth/v1/signup'), {'data': {}}));

  @override
  Future<AuthSession> refresh(String refreshToken) async {
    try {
      return _session(
        await _post(_at('auth/v1/token?grant_type=refresh_token'), {
          'refresh_token': refreshToken,
        }),
      );
    } on SyncServerException catch (e) {
      // Auth answers 400 for a refresh token it no longer accepts.
      throw SyncAuthException(e.message);
    }
  }

  @override
  Future<CodeStatus> checkCode(String code) async => CodeStatus.parse(
    (await _post(_at('rest/v1/rpc/check_code'), {'p_code': code}))! as String,
  );

  @override
  Future<CodeStatus> claimCode(AuthSession session, String code) async =>
      CodeStatus.parse(
        (await _post(_at('rest/v1/rpc/claim_code'), {
              'p_code': code,
            }, bearer: session.accessToken))!
            as String,
      );

  @override
  Future<void> push(AuthSession session, SyncBatch batch) async {
    await _post(_at('rest/v1/rpc/sync_push'), {
      'batch': batch,
    }, bearer: session.accessToken);
  }

  @override
  Future<void> withdraw(AuthSession session) async {
    await _post(
      _at('rest/v1/rpc/withdraw'),
      const <String, Object?>{},
      bearer: session.accessToken,
    );
  }
}
