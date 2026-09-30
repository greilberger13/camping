import '../models/calendar_event.dart';

class CalendarOccurrence {
  const CalendarOccurrence({
    required this.source,
    required this.displayed,
    required this.isOccurrence,
  });

  final CalendarEvent source;
  final CalendarEvent displayed;
  final bool isOccurrence;
}

class CalendarRecurrenceService {
  const CalendarRecurrenceService();

  List<CalendarOccurrence> inMonth(
    List<CalendarEvent> events,
    DateTime month,
  ) {
    final first = DateTime.utc(month.year, month.month);
    final last = DateTime.utc(month.year, month.month + 1, 0);
    final result = <CalendarOccurrence>[];

    for (final event in events) {
      final start = _parse(event.date);
      if (start == null) continue;
      if (start.year == month.year && start.month == month.month) {
        result.add(CalendarOccurrence(
          source: event,
          displayed: event,
          isOccurrence: false,
        ));
      }
      if (event.recurrence == CalendarEventRecurrence.weekly) {
        var date = start;
        if (date.isBefore(first)) {
          final days = first.difference(date).inDays;
          date = date.add(Duration(days: ((days + 6) ~/ 7) * 7));
        }
        while (!date.isAfter(last)) {
          if (date.isAfter(start)) result.add(_occurrence(event, date));
          date = date.add(const Duration(days: 7));
        }
      } else if (event.recurrence == CalendarEventRecurrence.monthly &&
          event.monthlyWeek != null &&
          event.monthlyWeekday != null) {
        final date = _monthlyDate(
          first,
          event.monthlyWeek!,
          event.monthlyWeekday!,
        );
        if (date != null && !date.isBefore(start)) {
          if (date.isAfter(start)) result.add(_occurrence(event, date));
        }
      }
    }
    result.sort((left, right) {
      final dateOrder = _parse(left.displayed.date)!.compareTo(
        _parse(right.displayed.date)!,
      );
      return dateOrder != 0
          ? dateOrder
          : left.displayed.time.compareTo(right.displayed.time);
    });
    return result;
  }

  CalendarOccurrence _occurrence(CalendarEvent event, DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return CalendarOccurrence(
      source: event,
      displayed: CalendarEvent(
        id: event.id,
        title: event.title,
        date: '$day.$month.${date.year}',
        time: event.time,
        category: event.category,
        recurrence: event.recurrence,
        monthlyWeek: event.monthlyWeek,
        monthlyWeekday: event.monthlyWeekday,
      ),
      isOccurrence: true,
    );
  }

  DateTime? _monthlyDate(DateTime first, int week, int weekday) {
    if (weekday < 1 || weekday > 7 || (week != -1 && (week < 1 || week > 5))) {
      return null;
    }
    final last = DateTime.utc(first.year, first.month + 1, 0);
    if (week == -1) {
      return last.subtract(Duration(days: (last.weekday - weekday + 7) % 7));
    }
    final offset = (weekday - first.weekday + 7) % 7;
    final day = 1 + offset + (week - 1) * 7;
    return day > last.day ? null : DateTime.utc(first.year, first.month, day);
  }

  DateTime? _parse(String value) {
    final parts = value.split('.');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    final date = DateTime.utc(year, month, day);
    return date.year == year && date.month == month && date.day == day
        ? date
        : null;
  }
}