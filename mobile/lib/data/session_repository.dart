import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../app/ports.dart';
import '../app/view_data.dart';
import 'database.dart';

/// Names of the local settings kept in `app_state`.
abstract final class AppStateNames {
  /// Epoch ms when the participant tapped "I agree".
  static const String consentAt = 'consent_at';

  /// Epoch ms when the participant chose "Stop taking part".
  static const String withdrawnAt = 'withdrawn_at';

  /// Epoch ms when the first-use hints were dismissed.
  static const String hintsDismissedAt = 'hints_dismissed_at';

  // Sync (Phase 5). Written only by the sync worker.

  /// This install's anonymous sign-in, as JSON (`AuthSession`).
  static const String authSession = 'auth_session';

  /// The participant code the server has bound to this install.
  static const String claimedCode = 'claimed_code';

  /// Why sending is blocked: a `CodeStatus` name (`unknown`, `taken`,
  /// `withdrawn`). Absent when nothing is wrong.
  static const String codeProblem = 'code_problem';

  /// Epoch ms when the server confirmed the withdrawal and deleted its copy.
  static const String withdrawConfirmedAt = 'withdraw_confirmed_at';
}

/// First launch and the participant who owns this phone (FR11, ethics).
///
/// Order: consent → participant code and type of business → Today. The
/// `business` row is created only at the end, in one step, so a half-finished
/// onboarding leaves nothing behind but the consent time.
class SessionRepository implements SessionPort {
  SessionRepository(this._db, {DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _now;

  String _nowMs() => _now().toUtc().millisecondsSinceEpoch.toString();

  @override
  Future<OnboardingState> state() async {
    final business = await (_db.select(
      _db.business,
    )..limit(1)).getSingleOrNull();
    final settings = {
      for (final s in await _db.select(_db.appState).get()) s.name: s.value,
    };
    return OnboardingState(
      consented: settings.containsKey(AppStateNames.consentAt),
      participantCode: business?.participantCode,
      withdrawn: settings.containsKey(AppStateNames.withdrawnAt),
      hintsDismissed: settings.containsKey(AppStateNames.hintsDismissedAt),
    );
  }

  @override
  Future<void> recordConsent() => _setOnce(AppStateNames.consentAt);

  /// Creates the business row. The schema's CHECK enforces the code length and
  /// UNIQUE stops a second row with the same code; consent must come first.
  @override
  Future<void> start(String code, BusinessType type) async {
    if (!RegExp(r'^[A-Z0-9]{4,12}$').hasMatch(code)) {
      throw ArgumentError.value(
        code,
        'code',
        'must be 4–12 capitals or digits',
      );
    }
    final current = await state();
    if (!current.consented) {
      throw StateError('Consent comes before the participant code');
    }
    if (current.participantCode != null) {
      throw StateError(
        'This phone already belongs to ${current.participantCode}',
      );
    }
    await _db
        .into(_db.business)
        .insert(
          BusinessCompanion.insert(
            id: Value(const Uuid().v4()),
            participantCode: code,
            businessType: Value(type.dbValue),
            createdAt: _now().toUtc().millisecondsSinceEpoch,
          ),
        );
  }

  /// The app keeps working as the participant's own record book; the sync
  /// worker (Phase 5) stops sending and asks the server to delete its copy.
  @override
  Future<void> withdraw() => _setOnce(AppStateNames.withdrawnAt);

  @override
  Future<void> dismissHints() => _setOnce(AppStateNames.hintsDismissedAt);

  /// Records the first time only; later calls keep the original time.
  Future<void> _setOnce(String name) => _db
      .into(_db.appState)
      .insert(
        AppStateCompanion.insert(name: name, value: _nowMs()),
        mode: InsertMode.insertOrIgnore,
      );
}

/// Finds the business id once and remembers it. Every repository scopes its
/// queries to this id.
class BusinessRef {
  BusinessRef(this._db);

  final AppDatabase _db;
  String? _id;

  Future<String> id() async {
    final cached = _id;
    if (cached != null) return cached;
    final row = await (_db.select(_db.business)..limit(1)).getSingleOrNull();
    if (row == null) {
      throw StateError('No participant yet: finish onboarding first');
    }
    return _id = row.id!;
  }

  /// Like [id] but null before onboarding, for queries that may run early.
  Future<String?> idOrNull() async {
    try {
      return await id();
    } on StateError {
      return null;
    }
  }
}
