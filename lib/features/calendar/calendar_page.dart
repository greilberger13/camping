import 'package:flutter/material.dart';

import '../../core/camping_dates.dart';
import '../../models/calendar_event.dart';
import '../../shared/widgets/page_frame.dart';

String _formatCalendarDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
}

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime selectedMonth = CampingDates.operationalDay;

  final events = <CalendarEvent>[
    const CalendarEvent(
      title: 'Müllabfuhr',
      date: '12.06.2026',
      time: '07:00',
      category: CalendarEventCategory.wasteCollection,
    ),
    const CalendarEvent(
      title: 'Getränke-Anlieferung',
      date: '13.06.2026',
      time: '10:30',
      category: CalendarEventCategory.delivery,
    ),
    const CalendarEvent(
      title: 'Sommerfest am See',
      date: '20.06.2026',
      time: '18:00',
      category: CalendarEventCategory.event,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final visibleEvents = _visibleEvents;

    return PageFrame(
      title: 'Kalender',
      subtitle: 'Termine, Lieferungen und Veranstaltungen',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CalendarToolbar(
            month: selectedMonth,
            onPrevious: () => _moveMonth(-1),
            onNext: () => _moveMonth(1),
            onAdd: _addEvent,
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                if (visibleEvents.isEmpty)
                  _EmptyCalendarState(onAdd: _addEvent)
                else
                  for (final displayEvent in visibleEvents)
                    _EventTile(
                      event: displayEvent.displayed,
                      isOccurrence: displayEvent.isOccurrence,
                      onEdit: () => _editEvent(displayEvent.source),
                      onDelete: () => _deleteEvent(displayEvent.source),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<_CalendarDisplayEvent> get _visibleEvents {
    final result = <_CalendarDisplayEvent>[];
    for (final event in events) {
      if (_isInSelectedMonth(event)) {
        result.add(_CalendarDisplayEvent(source: event, displayed: event));
      }
      for (final occurrence in _nextOccurrences(event)) {
        if (_isInSelectedMonth(occurrence)) {
          result.add(
            _CalendarDisplayEvent(
              source: event,
              displayed: occurrence,
              isOccurrence: true,
            ),
          );
        }
      }
    }
    return result;
  }

  bool _isInSelectedMonth(CalendarEvent event) {
    final date = _parseDate(event.date);
    return date != null &&
        date.year == selectedMonth.year &&
        date.month == selectedMonth.month;
  }

  void _moveMonth(int amount) {
    setState(() {
      selectedMonth = DateTime(
        selectedMonth.year,
        selectedMonth.month + amount,
      );
    });
  }

  List<CalendarEvent> _nextOccurrences(CalendarEvent event) {
    if (event.recurrence == CalendarEventRecurrence.none) {
      return [];
    }

    final baseDate = _parseDate(event.date);
    if (baseDate == null) {
      return [];
    }

    final occurrences = <CalendarEvent>[];
    var nextDate = baseDate;
    for (var index = 0; index < 3; index++) {
      nextDate = event.recurrence == CalendarEventRecurrence.weekly
          ? nextDate.add(const Duration(days: 7))
          : _addMonth(nextDate);
      occurrences.add(
        CalendarEvent(
          title: event.title,
          date: _formatDate(nextDate),
          time: event.time,
          category: event.category,
          recurrence: event.recurrence,
        ),
      );
    }
    return occurrences;
  }

  DateTime _addMonth(DateTime date) {
    final nextMonth = date.month == 12 ? 1 : date.month + 1;
    final nextYear = date.month == 12 ? date.year + 1 : date.year;
    final lastDay = DateTime(nextYear, nextMonth + 1, 0).day;
    return DateTime(nextYear, nextMonth, date.day.clamp(1, lastDay));
  }

  DateTime? _parseDate(String value) {
    final parts = value.split('.');
    if (parts.length != 3) {
      return null;
    }
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) {
      return null;
    }
    final parsed = DateTime(year, month, day);
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      return null;
    }

    return parsed;
  }

  String _formatDate(DateTime date) {
    return _formatCalendarDate(date);
  }

  Future<void> _addEvent() async {
    final event = await showDialog<CalendarEvent>(
      context: context,
      builder: (context) => const _CalendarEventDialog(),
    );

    if (event != null) {
      setState(() => events.add(event));
    }
  }

  Future<void> _editEvent(CalendarEvent event) async {
    final updated = await showDialog<CalendarEvent>(
      context: context,
      builder: (context) => _CalendarEventDialog(event: event),
    );

    if (updated != null) {
      setState(() {
        final index = events.indexOf(event);
        if (index != -1) {
          events[index] = updated;
        }
      });
    }
  }

  Future<void> _deleteEvent(CalendarEvent event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Termin löschen?'),
        content: Text('„${event.title}“ aus dem Kalender entfernen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => events.remove(event));
    }
  }
}

class _CalendarDisplayEvent {
  const _CalendarDisplayEvent({
    required this.source,
    required this.displayed,
    this.isOccurrence = false,
  });

  final CalendarEvent source;
  final CalendarEvent displayed;
  final bool isOccurrence;
}

class _EmptyCalendarState extends StatelessWidget {
  const _EmptyCalendarState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.event_busy_outlined, size: 36),
          const SizedBox(height: 8),
          const Text('Keine Termine in diesem Monat'),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Termin hinzufügen'),
          ),
        ],
      ),
    );
  }
}

class _CalendarToolbar extends StatelessWidget {
  const _CalendarToolbar({
    required this.month,
    required this.onPrevious,
    required this.onNext,
    required this.onAdd,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '${_monthName(month.month)} ${month.year}',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ),
        IconButton(
          onPressed: onPrevious,
          tooltip: 'Vorheriger Monat',
          icon: const Icon(Icons.chevron_left),
        ),
        IconButton(
          onPressed: onNext,
          tooltip: 'Nächster Monat',
          icon: const Icon(Icons.chevron_right),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text('Termin'),
        ),
      ],
    );
  }

  String _monthName(int month) {
    return CampingDates.monthName(month);
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({
    required this.event,
    required this.onEdit,
    required this.onDelete,
    this.isOccurrence = false,
  });

  final CalendarEvent event;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isOccurrence;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: isOccurrence ? 16 : null,
        backgroundColor: _categoryColor,
        child: Icon(_categoryIcon, color: Colors.white),
      ),
      title: Text(
        isOccurrence ? '${event.title} · Wiederholung' : event.title,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text('${event.date} · ${event.time} Uhr'),
      onTap: onEdit,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Chip(label: Text(event.categoryLabel)),
          if (event.recurrence != CalendarEventRecurrence.none)
            Chip(label: Text(event.recurrenceLabel)),
          IconButton(
            onPressed: onDelete,
            tooltip: 'Termin löschen',
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }

  Color get _categoryColor {
    switch (event.category) {
      case CalendarEventCategory.wasteCollection:
        return const Color(0xff61716d);
      case CalendarEventCategory.delivery:
        return const Color(0xff4269a4);
      case CalendarEventCategory.event:
        return const Color(0xffc47737);
      case CalendarEventCategory.private:
        return const Color(0xff7b6498);
    }
  }

  IconData get _categoryIcon {
    switch (event.category) {
      case CalendarEventCategory.wasteCollection:
        return Icons.delete_outline;
      case CalendarEventCategory.delivery:
        return Icons.local_shipping_outlined;
      case CalendarEventCategory.event:
        return Icons.celebration_outlined;
      case CalendarEventCategory.private:
        return Icons.person_outline;
    }
  }
}

class _CalendarEventDialog extends StatefulWidget {
  const _CalendarEventDialog({this.event});

  final CalendarEvent? event;

  @override
  State<_CalendarEventDialog> createState() => _CalendarEventDialogState();
}

class _CalendarEventDialogState extends State<_CalendarEventDialog> {
  final titleController = TextEditingController();
  final dateController = TextEditingController(
    text: _formatCalendarDate(CampingDates.operationalDay),
  );
  final timeController = TextEditingController(text: '10:00');
  CalendarEventCategory category = CalendarEventCategory.event;
  CalendarEventRecurrence recurrence = CalendarEventRecurrence.none;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    if (event != null) {
      titleController.text = event.title;
      dateController.text = event.date;
      timeController.text = event.time;
      category = event.category;
      recurrence = event.recurrence;
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    dateController.dispose();
    timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.event == null ? 'Neuer Termin' : 'Termin bearbeiten'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Titel'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<CalendarEventCategory>(
              initialValue: category,
              decoration: const InputDecoration(labelText: 'Kategorie'),
              items: [
                for (final value in CalendarEventCategory.values)
                  DropdownMenuItem(
                    value: value,
                    child: Text(_labelFor(value)),
                  ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => category = value);
                }
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<CalendarEventRecurrence>(
              initialValue: recurrence,
              decoration: const InputDecoration(labelText: 'Wiederholung'),
              items: [
                for (final value in CalendarEventRecurrence.values)
                  DropdownMenuItem(
                    value: value,
                    child: Text(_recurrenceLabel(value)),
                  ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => recurrence = value);
                }
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: dateController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Datum',
                      suffixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: timeController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Uhrzeit',
                      suffixIcon: Icon(Icons.schedule_outlined),
                    ),
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: () {
            final title = titleController.text.trim();
            if (title.isEmpty) {
              return;
            }
            Navigator.pop(
              context,
              CalendarEvent(
                title: title,
                date: dateController.text.trim(),
                time: timeController.text.trim(),
                category: category,
                recurrence: recurrence,
              ),
            );
          },
          child: Text(
            widget.event == null ? 'Termin speichern' : 'Änderungen speichern',
          ),
        ),
      ],
    );
  }

  String _labelFor(CalendarEventCategory value) {
    switch (value) {
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

  String _recurrenceLabel(CalendarEventRecurrence value) {
    switch (value) {
      case CalendarEventRecurrence.none:
        return 'Einmalig';
      case CalendarEventRecurrence.weekly:
        return 'Wöchentlich';
      case CalendarEventRecurrence.monthly:
        return 'Monatlich';
    }
  }

  Future<void> _pickDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _parseDate(dateController.text) ?? CampingDates.operationalDay,
      firstDate: DateTime(2025),
      lastDate: DateTime(2035),
      helpText: 'Termindatum auswählen',
    );

    if (selectedDate != null) {
      dateController.text = _formatDate(selectedDate);
    }
  }

  Future<void> _pickTime() async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: _parseTime(timeController.text),
      helpText: 'Uhrzeit auswählen',
    );

    if (selectedTime != null) {
      final hour = selectedTime.hour.toString().padLeft(2, '0');
      final minute = selectedTime.minute.toString().padLeft(2, '0');
      timeController.text = '$hour:$minute';
    }
  }

  DateTime? _parseDate(String value) {
    final parts = value.split('.');
    if (parts.length != 3) {
      return null;
    }

    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) {
      return null;
    }

    final parsed = DateTime(year, month, day);
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      return null;
    }

    return parsed;
  }

  TimeOfDay _parseTime(String value) {
    final parts = value.split(':');
    final hour = int.tryParse(parts.first) ?? 10;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return TimeOfDay(
      hour: hour.clamp(0, 23).toInt(),
      minute: minute.clamp(0, 59).toInt(),
    );
  }

  String _formatDate(DateTime date) {
    return _formatCalendarDate(date);
  }
}
