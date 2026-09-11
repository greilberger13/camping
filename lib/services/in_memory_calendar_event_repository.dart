import '../models/calendar_event.dart';
import 'calendar_event_repository.dart';

class InMemoryCalendarEventRepository implements CalendarEventRepository {
  InMemoryCalendarEventRepository({List<CalendarEvent> initial = const []})
      : _events = [
        for (var index = 0; index < initial.length; index++)
        initial[index].id == null
          ? initial[index].copyWith(id: 'seed-event-$index')
          : initial[index],
      ];

  final List<CalendarEvent> _events;

  @override
  List<CalendarEvent> get events => List.unmodifiable(_events);

  @override
  Future<List<CalendarEvent>> load() async => events;

  @override
  Future<CalendarEvent> create(CalendarEvent event) async {
    final stored = event.id == null
        ? event.copyWith(id: _newId())
        : event;
    _events.add(stored);
    return stored;
  }

  @override
  Future<CalendarEvent> update(CalendarEvent event) async {
    final index = _events.indexWhere((item) => item.id == event.id);
    if (index == -1) {
      throw StateError('Calendar event not found.');
    }
    _events[index] = event;
    return event;
  }

  @override
  Future<void> delete(CalendarEvent event) async {
    _events.removeWhere((item) => item.id == event.id);
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();
}
