import '../models/calendar_event.dart';

abstract interface class CalendarEventRepository {
  List<CalendarEvent> get events;

  Future<List<CalendarEvent>> load();
  Future<CalendarEvent> create(CalendarEvent event);
  Future<CalendarEvent> update(CalendarEvent event);
  Future<void> delete(CalendarEvent event);
}
