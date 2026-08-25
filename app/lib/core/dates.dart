/// Date helpers. Day keys are 'YYYY-MM-DD' strings; ISO weekday 1=Mon..7=Sun
/// (matches [DateTime.weekday]).
typedef NowFn = DateTime Function();
typedef IdFn = String Function();

class Dates {
  Dates._();

  static String ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Calendar days in [from, toExclusive) whose weekday is in [daysOfWeek].
  /// DST-safe: steps by calendar day, not by 24h durations.
  static List<DateTime> scheduledDatesBetween({
    required Set<int> daysOfWeek,
    required DateTime from,
    required DateTime toExclusive,
  }) {
    final out = <DateTime>[];
    var d = dateOnly(from);
    final end = dateOnly(toExclusive);
    while (d.isBefore(end)) {
      if (daysOfWeek.contains(d.weekday)) out.add(d);
      d = DateTime(d.year, d.month, d.day + 1);
    }
    return out;
  }
}
