enum CalendarEventCategory {
  wasteCollection,
  delivery,
  event,
  private,
}

enum CalendarEventRecurrence {
  none,
  weekly,
  monthly,
}

class CalendarEvent {
  const CalendarEvent({
    this.id,
    required this.title,
    required this.date,
    required this.time,
    required this.category,
    this.recurrence = CalendarEventRecurrence.none,
  });

  final String? id;
  final String title;
  final String date;
  final String time;
  final CalendarEventCategory category;
  final CalendarEventRecurrence recurrence;

  CalendarEvent copyWith({String? id}) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title,
      date: date,
      time: time,
      category: category,
      recurrence: recurrence,
    );
  }

  String get categoryLabel {
    switch (category) {
      case CalendarEventCategory.wasteCollection:
        return 'Müllabfuhr';
      case CalendarEventCategory.delivery:
        return 'Anlieferung';
      case CalendarEventCategory.event:
        return 'Veranstaltung';
      case CalendarEventCategory.private:
        return 'Privat';
    }
  }

  String get recurrenceLabel {
    switch (recurrence) {
      case CalendarEventRecurrence.none:
        return 'Einmalig';
      case CalendarEventRecurrence.weekly:
        return 'Wöchentlich';
      case CalendarEventRecurrence.monthly:
        return 'Monatlich';
    }
  }
}
