import 'package:flutter/material.dart';

import '../../core/camping_dates.dart';
import '../../models/calendar_event.dart';
import '../../services/calendar_event_repository.dart';
import '../../shared/widgets/page_frame.dart';

String _formatCalendarDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
}

class CalendarPage extends StatefulWidget {
  const CalendarPage({required this.repository, super.key});

  final CalendarEventRepository repository;

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime selectedMonth = CampingDates.operationalDay;

  List<CalendarEvent> get events => widget.repository.events;

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
          _CalendarMonthGrid(
            month: selectedMonth,
            events: visibleEvents,
            onEventTap: (displayEvent) => _editEvent(displayEvent.source),
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
      for (final occurrence in _occurrencesInSelectedMonth(event)) {
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

  List<CalendarEvent> _occurrencesInSelectedMonth(CalendarEvent event) {
    if (event.recurrence == CalendarEventRecurrence.none) {
      return [];
    }

    final baseDate = _parseDate(event.date);
    if (baseDate == null) {
      return [];
    }

    final monthStart = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final monthEnd = DateTime(selectedMonth.year, selectedMonth.month + 1, 0);
    final occurrences = <CalendarEvent>[];

    if (event.recurrence == CalendarEventRecurrence.weekly) {
      var date = baseDate;
      if (date.isBefore(monthStart)) {
        final days = monthStart.difference(date).inDays;
        date = date.add(Duration(days: ((days + 6) ~/ 7) * 7));
      }
      while (!date.isAfter(monthEnd)) {
        if (!date.isBefore(monthStart)) {
          occurrences.add(_eventAtDate(event, date));
        }
        date = date.add(const Duration(days: 7));
      }
    } else {
      final date = _addMonthForYear(baseDate, selectedMonth.year, selectedMonth.month);
      if (date != null && !date.isBefore(monthStart) && !date.isAfter(monthEnd)) {
        occurrences.add(_eventAtDate(event, date));
      }
    }

    return occurrences;
  }

  CalendarEvent _eventAtDate(CalendarEvent event, DateTime date) {
    return CalendarEvent(
      title: event.title,
      date: _formatDate(date),
      time: event.time,
      category: event.category,
      recurrence: event.recurrence,
    );
  }

  DateTime? _addMonthForYear(DateTime base, int year, int month) {
    final targetMonth = DateTime(year, month, 1);
    if (targetMonth.isBefore(DateTime(base.year, base.month, 1))) {
      return null;
    }
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, base.day.clamp(1, lastDay).toInt());
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
      await widget.repository.create(event);
      setState(() {});
    }
  }

  Future<void> _editEvent(CalendarEvent event) async {
    final updated = await showDialog<CalendarEvent>(
      context: context,
      builder: (context) => _CalendarEventDialog(event: event),
    );

    if (updated != null) {
      if (event.id == null) {
        await widget.repository.create(updated);
      } else {
        await widget.repository.update(updated.copyWith(id: event.id));
      }
      setState(() {});
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
      if (event.id != null) {
        await widget.repository.delete(event);
      } else {
        return;
      }
      setState(() {});
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

class _CalendarMonthGrid extends StatelessWidget {
  const _CalendarMonthGrid({
    required this.month,
    required this.events,
    required this.onEventTap,
  });

  final DateTime month;
  final List<_CalendarDisplayEvent> events;
  final ValueChanged<_CalendarDisplayEvent> onEventTap;

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingDays = firstDay.weekday - 1;
    final totalCells = ((leadingDays + daysInMonth + 6) ~/ 7) * 7;
    const weekDays = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Row(
              children: [
                for (final day in weekDays)
                  Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: totalCells,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 0.9,
              ),
              itemBuilder: (context, index) {
                final dayNumber = index - leadingDays + 1;
                if (dayNumber < 1 || dayNumber > daysInMonth) {
                  return const SizedBox.shrink();
                }

                final date = DateTime(month.year, month.month, dayNumber);
                final dayEvents = events.where((event) {
                  final eventDate = _parseDate(event.displayed.date);
                  return eventDate?.year == date.year &&
                      eventDate?.month == date.month &&
                      eventDate?.day == date.day;
                }).toList();

                return Container(
                  margin: const EdgeInsets.all(2),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xffd9e1dc)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$dayNumber'),
                      for (final event in dayEvents.take(2))
                        GestureDetector(
                          onTap: () => onEventTap(event),
                          child: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(top: 3),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 3,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _eventColor(event.displayed.category),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              event.displayed.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                      if (dayEvents.length > 2)
                        Text(
                          '+${dayEvents.length - 2}',
                          style: const TextStyle(fontSize: 10),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  DateTime? _parseDate(String value) {
    final parts = value.split('.');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    final parsed = DateTime(year, month, day);
    return parsed.year == year && parsed.month == month && parsed.day == day
        ? parsed
        : null;
  }

  Color _eventColor(CalendarEventCategory category) {
    switch (category) {
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
