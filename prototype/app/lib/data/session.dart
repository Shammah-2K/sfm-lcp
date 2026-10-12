import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'database.dart';

final RegExp participantCodePattern = RegExp(r'^[A-Z0-9]{4,12}$');

/// Normalises typed input into a participant code: uppercase, letters and digits only.
String normaliseParticipantCode(String input) =>
    input.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

/// The participant who owns this device's ledger.
class Participant {
  const Participant({required this.businessId, required this.code});

  final String businessId;
  final String code;
}

/// The device's single owner (FR11). The user counts as logged in once a `business` row exists.
class Session {
  Session(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _clock;

  Future<Participant?> current() async {
    final row = await (_db.select(_db.business)..limit(1)).getSingleOrNull();
    return row == null
        ? null
        : Participant(businessId: row.id!, code: row.participantCode);
  }

  Future<Participant> start(String participantCode) async {
    final code = normaliseParticipantCode(participantCode);
    if (!participantCodePattern.hasMatch(code)) {
      throw ArgumentError.value(
        participantCode,
        'participantCode',
        'must be 4–12 letters or digits',
      );
    }
    final id = const Uuid().v4();
    await _db
        .into(_db.business)
        .insert(
          BusinessCompanion.insert(
            id: Value(id),
            participantCode: code,
            createdAt: _clock().toUtc().millisecondsSinceEpoch,
          ),
        );
    return Participant(businessId: id, code: code);
  }
}
