import 'package:flutter_test/flutter_test.dart';
import 'package:physio_app/core/dates.dart';

void main() {
  test('ymd formats with zero padding', () {
    expect(Dates.ymd(DateTime(2026, 8, 25)), '2026-08-25');
    expect(Dates.ymd(DateTime(2026, 1, 3)), '2026-01-03');
  });

  test('dateOnly strips time', () {
    expect(Dates.dateOnly(DateTime(2026, 8, 25, 23, 59)), DateTime(2026, 8, 25));
  });

  test('scheduledDatesBetween picks matching weekdays in half-open range', () {
    // 2026-08-17 is a Monday.
    final dates = Dates.scheduledDatesBetween(
      daysOfWeek: {1, 3, 5},
      from: DateTime(2026, 8, 17),
      toExclusive: DateTime(2026, 8, 24),
    );
    expect(dates, [DateTime(2026, 8, 17), DateTime(2026, 8, 19), DateTime(2026, 8, 21)]);
  });

  test('scheduledDatesBetween empty when from == toExclusive', () {
    final dates = Dates.scheduledDatesBetween(
      daysOfWeek: {1, 2, 3, 4, 5, 6, 7},
      from: DateTime(2026, 8, 25),
      toExclusive: DateTime(2026, 8, 25),
    );
    expect(dates, isEmpty);
  });

  test('scheduledDatesBetween steps calendar days across the October DST fall-back', () {
    // Europe/Zagreb leaves DST on 2026-10-25. Duration-based iteration would
    // repeat or shift a day; calendar stepping must yield each date exactly once.
    final dates = Dates.scheduledDatesBetween(
      daysOfWeek: {1, 2, 3, 4, 5, 6, 7},
      from: DateTime(2026, 10, 23),
      toExclusive: DateTime(2026, 10, 28),
    );
    expect(dates.map(Dates.ymd), ['2026-10-23', '2026-10-24', '2026-10-25', '2026-10-26', '2026-10-27']);
  });

  test('scheduledDatesBetween steps calendar days across the March spring-forward', () {
    final dates = Dates.scheduledDatesBetween(
      daysOfWeek: {1, 2, 3, 4, 5, 6, 7},
      from: DateTime(2026, 3, 28),
      toExclusive: DateTime(2026, 3, 31),
    );
    expect(dates.map(Dates.ymd), ['2026-03-28', '2026-03-29', '2026-03-30']);
  });

  test('scheduledDatesBetween ignores time-of-day on bounds', () {
    final dates = Dates.scheduledDatesBetween(
      daysOfWeek: {1, 2, 3, 4, 5, 6, 7},
      from: DateTime(2026, 8, 24, 18, 30),
      toExclusive: DateTime(2026, 8, 25, 9, 0),
    );
    expect(dates, [DateTime(2026, 8, 24)]);
  });
}
