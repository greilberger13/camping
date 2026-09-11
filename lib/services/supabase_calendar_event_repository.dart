import '../core/supabase_database.dart';
import '../models/calendar_event.dart';
import 'calendar_event_repository.dart';

class SupabaseCalendarEventRepository implements CalendarEventRepository {
  SupabaseCalendarEventRepository(this.database);

  final SupabaseDatabase database;
  final cache = <CalendarEvent>[];

  @override
  List<CalendarEvent> get events => List.unmodifiable(cache);

  @override
  Future<List<CalendarEvent>> load() async {
    final rows = await database.client
        .from('calendar_events')
        .select()
        .order('event_date')
        .order('event_time');
    cache
      ..clear()
      ..addAll(rows.map(_fromRow));
    return events;
  }

  @override
  Future<CalendarEvent> create(CalendarEvent event) async {
    final row = await database.client
        .from('calendar_events')
        .insert(_toRow(event))
        .select()
        .single();
    final stored = _fromRow(row);
    cache.add(stored);
    return stored;
  }

  @override
  Future<CalendarEvent> update(CalendarEvent event) async {
    if (event.id == null) throw StateError('Calendar event has no id.');
    final row = await database.client
        .from('calendar_events')
        .update(_toRow(event))
        .eq('id', event.id!)
        .select()
        .single();
    final updated = _fromRow(row);
    final index = cache.indexWhere((item) => item.id == event.id);
    if (index != -1) cache[index] = updated;
    return updated;
  }

  @override
  Future<void> delete(CalendarEvent event) async {
    if (event.id == null) throw StateError('Calendar event has no id.');
    await database.client.from('calendar_events').delete().eq('id', event.id!);
    cache.removeWhere((item) => item.id == event.id);
  }

  Map<String, dynamic> _toRow(CalendarEvent event) {
    final date = _parseDate(event.date);
    return {
      'title': event.title,
      'event_date': date.toIso8601String().split('T').first,
      'event_time': '${event.time}:00',
      'category': _categoryValue(event.category),
      'recurrence': _recurrenceValue(event.recurrence),
    };
  }

  CalendarEvent _fromRow(Map<String, dynamic> row) {
    final date = DateTime.parse(row['event_date'] as String);
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final time = (row['event_time'] as String).substring(0, 5);
    return CalendarEvent(
      id: row['id'] as String?,
      title: row['title'] as String,
      date: '$day.$month.${date.year}',
      time: time,
      category: _categoryFromValue(row['category'] as String),
      recurrence: _recurrenceFromValue(row['recurrence'] as String),
    );
  }

  DateTime _parseDate(String value) {
    final parts = value.split('.');
    return DateTime(
      int.parse(parts[2]),
      int.parse(parts[1]),
      int.parse(parts[0]),
    );
  }

  String _categoryValue(CalendarEventCategory category) {
    switch (category) {
      case CalendarEventCategory.wasteCollection:
        return 'waste_collection';
      case CalendarEventCategory.delivery:
        return 'delivery';
      case CalendarEventCategory.event:
        return 'event';
      case CalendarEventCategory.private:
        return 'private';
    }
  }

  CalendarEventCategory _categoryFromValue(String value) {
    switch (value) {
      case 'waste_collection':
        return CalendarEventCategory.wasteCollection;
      case 'delivery':
        return CalendarEventCategory.delivery;
      case 'private':
        return CalendarEventCategory.private;
      default:
        return CalendarEventCategory.event;
    }
  }

  String _recurrenceValue(CalendarEventRecurrence recurrence) {
    switch (recurrence) {
      case CalendarEventRecurrence.none:
        return 'none';
      case CalendarEventRecurrence.weekly:
        return 'weekly';
      case CalendarEventRecurrence.monthly:
        return 'monthly';
    }
  }

  CalendarEventRecurrence _recurrenceFromValue(String value) {
    switch (value) {
      case 'weekly':
        return CalendarEventRecurrence.weekly;
      case 'monthly':
        return CalendarEventRecurrence.monthly;
      default:
        return CalendarEventRecurrence.none;
    }
  }
}
