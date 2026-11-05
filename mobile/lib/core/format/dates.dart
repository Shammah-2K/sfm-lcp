import 'package:intl/intl.dart';

final DateFormat _time = DateFormat('HH:mm');
final DateFormat _day = DateFormat('EEE d MMM');
final DateFormat _dayShort = DateFormat('d MMM');

/// `08:32`, in the phone's local time.
String formatTime(DateTime t) => _time.format(t.toLocal());

/// `Mon 12 Oct`.
String formatDay(DateTime t) => _day.format(t.toLocal());

/// `Mon 12 Oct, 08:32`.
String formatDayTime(DateTime t) => '${formatDay(t)}, ${formatTime(t)}';

/// `6 – 12 Oct` for the week that ends on [end].
String formatWeek(DateTime start, DateTime end) =>
    '${start.day} – ${_dayShort.format(end.toLocal())}';
