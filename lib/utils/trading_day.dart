/// India Standard Time has no daylight saving, so a fixed offset is exact.
const istOffset = Duration(hours: 5, minutes: 30);

/// NSE publishes the day's bhavcopy in the evening; from this IST hour on a
/// weekday we expect today's file to exist.
const bhavcopyReadyHourIst = 19;

/// The IST wall-clock time for [instant], expressed as a UTC [DateTime] whose
/// fields read as IST (so `.hour`, `.weekday` etc. are IST values).
DateTime toIst(DateTime instant) {
  final shifted = instant.toUtc().add(istOffset);
  return DateTime.utc(
    shifted.year,
    shifted.month,
    shifted.day,
    shifted.hour,
    shifted.minute,
    shifted.second,
  );
}

/// The IST calendar date of [instant], as a date-only UTC [DateTime].
DateTime istDate(DateTime instant) => dateOnly(toIst(instant));

DateTime dateOnly(DateTime d) => DateTime.utc(d.year, d.month, d.day);

bool isWeekend(DateTime d) =>
    d.weekday == DateTime.saturday || d.weekday == DateTime.sunday;

/// The weekday strictly before [day] (Monday → previous Friday).
DateTime previousWeekday(DateTime day) {
  var d = dateOnly(day).subtract(const Duration(days: 1));
  while (isWeekend(d)) {
    d = d.subtract(const Duration(days: 1));
  }
  return d;
}

/// The latest trading day whose bhavcopy should already be published at
/// [instant]: today if it is a weekday at or after 19:00 IST, otherwise the
/// previous weekday. Exchange holidays are handled by the caller's 404
/// fallback, not here.
DateTime expectedLatestTradingDay(DateTime instant) {
  final ist = toIst(instant);
  final today = dateOnly(ist);
  if (!isWeekend(today) && ist.hour >= bhavcopyReadyHourIst) return today;
  return previousWeekday(today);
}

String _two(int n) => n.toString().padLeft(2, '0');

/// `2026-10-21`: the storage format for trade dates (sorts as text).
String dateKey(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';

/// `20261021`: the format in the bhavcopy URL.
String yyyymmdd(DateTime d) => '${d.year}${_two(d.month)}${_two(d.day)}';

/// Parses `YYYY-MM-DD` into a date-only UTC [DateTime]; null if malformed.
DateTime? parseDateKey(String? s) {
  if (s == null) return null;
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(s.trim());
  if (m == null) return null;
  return DateTime.utc(
    int.parse(m.group(1)!),
    int.parse(m.group(2)!),
    int.parse(m.group(3)!),
  );
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// `21 Oct 2026`.
String formatDisplayDate(DateTime d) =>
    '${d.day} ${_months[d.month - 1]} ${d.year}';

/// `21 Oct, 20:05` in IST.
String formatIstTime(DateTime instant) {
  final ist = toIst(instant);
  return '${ist.day} ${_months[ist.month - 1]}, '
      '${_two(ist.hour)}:${_two(ist.minute)}:${_two(ist.second)}';
}
