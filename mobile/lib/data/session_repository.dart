import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../app/ports.dart';
import 'database.dart';

/// The participant who owns this phone (FR11). One `business` row per install;
/// its id is the business id every ledger entry and product points at.
class SessionRepository implements SessionPort {
  SessionRepository(this._db, {DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _now;

  @override
  Future<String?> currentParticipant() async {
    final row = await (_db.select(_db.business)..limit(1)).getSingleOrNull();
    return row?.participantCode;
  }

  /// Creates the business row. Codes are 4–12 capitals or digits; the schema's
  /// CHECK enforces the length and UNIQUE stops a second row with the same code.
  @override
  Future<void> start(String code) async {
    if (!RegExp(r'^[A-Z0-9]{4,12}$').hasMatch(code)) {
      throw ArgumentError.value(
        code,
        'code',
        'must be 4–12 capitals or digits',
      );
    }
    final existing = await currentParticipant();
    if (existing != null) {
      throw StateError('This phone already belongs to $existing');
    }
    await _db
        .into(_db.business)
        .insert(
          BusinessCompanion.insert(
            id: Value(const Uuid().v4()),
            participantCode: code,
            createdAt: _now().toUtc().millisecondsSinceEpoch,
          ),
        );
  }
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
