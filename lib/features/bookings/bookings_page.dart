import 'package:flutter/material.dart';

import '../../core/camping_dates.dart';
import '../../integrations/feratel/feratel_gateway.dart';
import '../../models/booking.dart';
import '../../models/vehicle_type.dart';
import '../../shared/widgets/page_frame.dart';
import '../stays/guest_order_link_dialog.dart';

class BookingsPage extends StatefulWidget {
  const BookingsPage({
    required this.bookings,
    required this.onDelete,
    required this.onEdit,
    required this.onOrder,
    super.key,
  });

  final List<Booking> bookings;
  final ValueChanged<Booking> onDelete;
  final ValueChanged<Booking> onEdit;
  final ValueChanged<Booking> onOrder;

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  final searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredBookings = _filteredBookings;
    final occupiedSites = widget.bookings
      .map((booking) => booking.siteNumber)
      .toSet()
      .length;
    final pageSubtitle = '${CampingDates.monthName(CampingDates.operationalDay.month)} '
        '${CampingDates.operationalDay.year} · $occupiedSites eigene Stellplätze';

    return PageFrame(
      title: 'Buchungen',
      subtitle: pageSubtitle,
      child: Column(
        children: [
          _BookingWeek(bookings: filteredBookings),
          const SizedBox(height: 16),
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              labelText: 'Buchungen suchen',
              hintText: 'Name, Stellplatz, Fahrzeug oder Telefon',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        searchController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.clear),
                    ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                if (filteredBookings.isEmpty)
                  const ListTile(title: Text('Keine Buchungen gefunden')),
                for (final booking in filteredBookings)
                  _BookingListTile(
                    booking: booking,
                    onExport: () => _prepareFeratelReport(booking),
                    onDelete: () => _confirmDelete(context, booking),
                    onEdit: () => widget.onEdit(booking),
                    onOrder: () => widget.onOrder(booking),
                    onGuestLink: () => showGuestOrderLink(
                      context,
                      booking.siteNumber,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _prepareFeratelReport(Booking booking) async {
    final result = await const FeratelExportGateway().submitGuestReport(booking);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message ?? 'Export vorbereitet.')),
    );
  }

  List<Booking> get _filteredBookings {
    final query = searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return widget.bookings;
    }

    return widget.bookings.where((booking) {
      return booking.guestName.toLowerCase().contains(query) ||
          '${booking.siteNumber}'.contains(query) ||
          booking.vehicleType.label.toLowerCase().contains(query) ||
          (booking.phone?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  Future<void> _confirmDelete(BuildContext context, Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buchung löschen?'),
        content: Text('„${booking.guestName}“ wirklich entfernen?'),
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
      widget.onDelete(booking);
    }
  }
}

class _BookingWeek extends StatefulWidget {
  const _BookingWeek({required this.bookings});

  final List<Booking> bookings;

  @override
  State<_BookingWeek> createState() => _BookingWeekState();
}

class _BookingWeekState extends State<_BookingWeek> {
  DateTime weekStart = CampingDates.initialWeek;

  @override
  Widget build(BuildContext context) {
    final days = List.generate(7, (index) {
      return weekStart.add(Duration(days: index));
    });
    final arrivalCounts = _eventCounts(isArrival: true);
    final departureCounts = _eventCounts(isArrival: false);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _weekLabel(),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: () => _moveWeek(-7),
                  tooltip: 'Vorherige Woche',
                  icon: const Icon(Icons.chevron_left),
                ),
                IconButton(
                  onPressed: () => _moveWeek(7),
                  tooltip: 'Nächste Woche',
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var index = 0; index < days.length; index++)
                    _BookingDay(
                      label: _dayLabel(days[index]),
                      isToday: _isToday(days[index]),
                      arrivals: arrivalCounts[index],
                      departures: departureCounts[index],
                    ),
                ],
              ),
            ),
            if (widget.bookings.isNotEmpty) ...[
              const Divider(height: 28),
              Text(
                '${widget.bookings.length} eigene Buchung${widget.bookings.length == 1 ? '' : 'en'} geladen',
                style: const TextStyle(color: Color(0xff61716d)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _moveWeek(int days) {
    setState(() {
      weekStart = weekStart.add(Duration(days: days));
    });
  }

  String _dayLabel(DateTime date) {
    const names = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    return '${names[date.weekday - 1]} ${date.day.toString().padLeft(2, '0')}.';
  }

  String _weekLabel() {
    final weekEnd = weekStart.add(const Duration(days: 6));
    return '${weekStart.day}. ${_monthName(weekStart.month)} – '
        '${weekEnd.day}. ${_monthName(weekEnd.month)} ${weekEnd.year}';
  }

  String _monthName(int month) {
    const names = [
      'Jänner',
      'Februar',
      'März',
      'April',
      'Mai',
      'Juni',
      'Juli',
      'August',
      'September',
      'Oktober',
      'November',
      'Dezember',
    ];
    return names[month - 1];
  }

  bool _isToday(DateTime date) {
    return date == CampingDates.operationalDay;
  }

  List<int> _eventCounts({required bool isArrival}) {
    if (widget.bookings.isEmpty && weekStart == CampingDates.initialWeek) {
      return isArrival
          ? const [1, 0, 1, 2, 0, 1, 0]
          : const [0, 1, 0, 1, 1, 0, 1];
    }

    return [
      for (var index = 0; index < 7; index++)
        widget.bookings.where((booking) {
          final value = isArrival ? booking.arrival : booking.departure;
          return _parseDate(value) == weekStart.add(Duration(days: index));
        }).length,
    ];
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
}

class _BookingDay extends StatelessWidget {
  const _BookingDay({
    required this.label,
    required this.isToday,
    required this.arrivals,
    required this.departures,
  });

  final String label;
  final bool isToday;
  final int arrivals;
  final int departures;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isToday ? const Color(0xffcfe5dc) : const Color(0xfff5f7f4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isToday ? const Color(0xff32866d) : const Color(0xffd9e1dc),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.login, size: 15, color: Color(0xff32866d)),
              const SizedBox(width: 4),
              Text('$arrivals'),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.logout, size: 15, color: Color(0xffc47737)),
              const SizedBox(width: 4),
              Text('$departures'),
            ],
          ),
        ],
      ),
    );
  }
}

class _BookingListTile extends StatelessWidget {
  const _BookingListTile({
    required this.booking,
    required this.onExport,
    required this.onDelete,
    required this.onEdit,
    required this.onOrder,
    required this.onGuestLink,
  });

  final Booking booking;
  final VoidCallback onExport;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onOrder;
  final VoidCallback onGuestLink;

  @override
  Widget build(BuildContext context) {
    final guestDetails = [
      'Stellplatz ${booking.siteNumber}',
      booking.vehicleType.label,
      '${booking.adults} Erwachsene, ${booking.children} Kinder',
      if (booking.hasDog) 'Hund',
      if (booking.hasElectricity) 'Strom',
      if (booking.lateCheckout) 'Late-Check-Out',
      if (booking.phone != null) booking.phone!,
    ].join(' · ');

    final actions = <Widget>[
          IconButton(
            onPressed: booking.id == null ? null : onOrder,
            tooltip: 'Bestellung für diese Buchung erstellen',
            icon: const Icon(Icons.add_shopping_cart_outlined),
          ),
          IconButton(
            onPressed: onGuestLink,
            tooltip: 'Gast-Bestelllink',
            icon: const Icon(Icons.link_outlined),
          ),
          IconButton(
            onPressed: onEdit,
            tooltip: 'Buchung bearbeiten',
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            onPressed: onExport,
            tooltip: 'Feratel vorbereiten',
            icon: const Icon(Icons.upload_file_outlined),
          ),
          IconButton(
            onPressed: onDelete,
            tooltip: 'Buchung löschen',
            icon: const Icon(Icons.delete_outline),
          ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 680;
        final details = ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xffa9ed21),
            child: Text('${booking.siteNumber}'),
          ),
          title: Text(
            '${booking.guestName} · ${booking.arrival} – ${booking.departure}',
          ),
          subtitle: Text(guestDetails),
          trailing: compact
              ? null
              : Row(mainAxisSize: MainAxisSize.min, children: actions),
        );
        if (!compact) return details;
        return Column(
          children: [
            details,
            Align(
              alignment: Alignment.centerRight,
              child: Row(mainAxisSize: MainAxisSize.min, children: actions),
            ),
          ],
        );
      },
    );
  }
}

