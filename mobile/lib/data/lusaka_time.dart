/// Day and week boundaries in Lusaka time.
///
/// Zambia is UTC+2 all year with no daylight saving, the same assumption as
/// the schema's `v_daily_summary` view (`'+2 hours'`). Timestamps are stored as
/// epoch milliseconds in UTC; a "day" is midnight to midnight in Lusaka.
library;

const Duration lusakaOffset = Duration(hours: 2);

/// A half-open window of time, [startMs, endMs), in epoch milliseconds.
class TimeWindow {
  const TimeWindow(this.startMs, this.endMs);

  final int startMs;
  final int endMs;

  DateTime get start =>
      DateTime.fromMillisecondsSinceEpoch(startMs, isUtc: true);

  /// The last instant inside the window.
  DateTime get last =>
      DateTime.fromMillisecondsSinceEpoch(endMs - 1, isUtc: true);
}

/// The Lusaka calendar day containing [instant].
TimeWindow lusakaDay(DateTime instant) {
  final local = instant.toUtc().add(lusakaOffset);
  final midnight = DateTime.utc(
    local.year,
    local.month,
    local.day,
  ).subtract(lusakaOffset);
  return TimeWindow(
    midnight.millisecondsSinceEpoch,
    midnight.add(const Duration(days: 1)).millisecondsSinceEpoch,
  );
}

/// The Monday-to-Sunday Lusaka week containing [instant].
TimeWindow lusakaWeek(DateTime instant) {
  final day = lusakaDay(instant);
  final local = instant.toUtc().add(lusakaOffset);
  final monday = day.start.subtract(
    Duration(days: local.weekday - DateTime.monday),
  );
  return TimeWindow(
    monday.millisecondsSinceEpoch,
    monday.add(const Duration(days: 7)).millisecondsSinceEpoch,
  );
}

/// The `YYYY-MM-DD` Lusaka date of [window]'s start, as `v_daily_summary` writes it.
String lusakaDateKey(TimeWindow window) {
  final d = window.start.add(lusakaOffset);
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year}-${two(d.month)}-${two(d.day)}';
}
