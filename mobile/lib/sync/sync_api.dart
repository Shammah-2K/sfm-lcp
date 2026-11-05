/// The study server as the sync worker sees it (FR9, decision D6).
///
/// [SupabaseSyncApi] talks to Supabase; tests use an in-memory server with
/// the same rules, so the worker can be tested with no network.
library;

/// What the server says about a participant code.
enum CodeStatus {
  /// On the list and free, or already held by this install.
  ok,

  /// Not on the researcher's list.
  unknown,

  /// Held by another phone (or this install already holds another code).
  taken,

  /// The participant stopped taking part.
  withdrawn;

  static CodeStatus parse(String s) => switch (s) {
    'ok' => ok,
    'unknown' => unknown,
    'taken' => taken,
    'withdrawn' => withdrawn,
    _ => throw SyncServerException('Unexpected code status: $s'),
  };
}

/// An anonymous sign-in for this install. The refresh token keeps it alive,
/// so the install stays the same user and keeps its claimed code.
class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.userId,
  });

  factory AuthSession.fromJson(Map<String, Object?> j) => AuthSession(
    accessToken: j['access_token']! as String,
    refreshToken: j['refresh_token']! as String,
    expiresAt: DateTime.fromMillisecondsSinceEpoch(
      j['expires_at_ms']! as int,
      isUtc: true,
    ),
    userId: j['user_id']! as String,
  );

  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final String userId;

  Map<String, Object?> toJson() => {
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'expires_at_ms': expiresAt.millisecondsSinceEpoch,
    'user_id': userId,
  };
}

/// Rows to send, keyed by table name, each row with the phone's column names.
typedef SyncBatch = Map<String, List<Map<String, Object?>>>;

abstract interface class SyncApi {
  Future<AuthSession> signInAnonymously();

  /// Throws [SyncAuthException] if the refresh token is no longer valid.
  Future<AuthSession> refresh(String refreshToken);

  /// Before sign-in, during onboarding: can this code be used?
  Future<CodeStatus> checkCode(String code);

  /// Binds [code] to this install. Safe to repeat.
  Future<CodeStatus> claimCode(AuthSession session, String code);

  /// Applies a batch all or nothing. Sending the same batch twice is safe.
  Future<void> push(AuthSession session, SyncBatch batch);

  /// Deletes everything this install sent and marks the code withdrawn.
  Future<void> withdraw(AuthSession session);
}

/// No network, or the server did not answer. Try again later.
class SyncOfflineException implements Exception {
  const SyncOfflineException(this.message);

  final String message;

  @override
  String toString() => 'SyncOfflineException: $message';
}

/// The session is not accepted (expired or revoked).
class SyncAuthException implements Exception {
  const SyncAuthException(this.message);

  final String message;

  @override
  String toString() => 'SyncAuthException: $message';
}

/// The server answered but refused the request.
class SyncServerException implements Exception {
  const SyncServerException(this.message);

  final String message;

  @override
  String toString() => 'SyncServerException: $message';
}
