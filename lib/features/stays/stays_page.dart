import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/booking.dart';
import '../../models/guest_order_link.dart';
import '../../models/order.dart';
import '../../models/order_batch.dart';
import '../../models/order_product.dart';
import '../../models/stay_note.dart';
import '../../shared/widgets/page_frame.dart';
import 'booking_order_dialog.dart';
import 'stay_note_dialog.dart';

class StaysPage extends StatefulWidget {
  const StaysPage({
    required this.bookings,
    required this.orders,
    required this.products,
    required this.onOrderBatchAdded,
    required this.onOrderUpdated,
    required this.notes,
    required this.onNoteAdded,
    required this.onNoteDeleted,
    super.key,
  });

  final List<Booking> bookings;
  final List<Order> orders;
  final List<OrderProduct> products;
  final ValueChanged<OrderBatch> onOrderBatchAdded;
  final ValueChanged<Order> onOrderUpdated;
  final List<StayNote> notes;
  final ValueChanged<StayNote> onNoteAdded;
  final ValueChanged<StayNote> onNoteDeleted;

  @override
  State<StaysPage> createState() => _StaysPageState();
}

class _StaysPageState extends State<StaysPage> {
  @override
  Widget build(BuildContext context) {
    final activeBookings = _activeBookings;
    final upcomingBookings = _upcomingBookings;

    return PageFrame(
      title: 'Aufenthalt',
      subtitle: 'Aktive Gäste, Bestellungen und Notizen',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, 'Aktive Aufenthalte'),
          if (activeBookings.isEmpty)
            const ListTile(title: Text('Keine aktiven Aufenthalte')),
          for (final booking in activeBookings)
            _StayCard(
              booking: booking,
              onOrder: booking.id == null ? null : () => _addOrder(booking),
              onGuestLink: () => _showGuestLink(booking.siteNumber),
            ),
          if (upcomingBookings.isNotEmpty) ...[
            const SizedBox(height: 28),
            _sectionTitle(context, 'Kommende Buchungen'),
            for (final booking in upcomingBookings)
              _StayCard(
                booking: booking,
                onOrder: () => _addOrder(booking),
                onGuestLink: () => _showGuestLink(booking.siteNumber),
              ),
          ],
          const SizedBox(height: 28),
          _sectionTitle(context, 'Offene Bestellungen'),
          _OrderList(
            orders: widget.orders,
            onStatusChanged: (order, status) {
              widget.onOrderUpdated(order.copyWith(status: status));
            },
          ),
          const SizedBox(height: 28),
          _sectionTitle(context, 'Notizen'),
          _NotesSection(
            notes: widget.notes,
            onAdd: _addNote,
            onDelete: widget.onNoteDeleted,
          ),
        ],
      ),
    );
  }

  List<Booking> get _activeBookings {
    final today = DateUtils.dateOnly(DateTime.now());
    return widget.bookings.where((booking) {
      final arrival = booking.arrivalDate;
      final departure = booking.departureDate;
      return arrival != null &&
          departure != null &&
          !today.isBefore(arrival) &&
            (today.isBefore(departure) ||
              (arrival == departure && today == arrival));
    }).toList();
  }

  List<Booking> get _upcomingBookings {
    final today = DateUtils.dateOnly(DateTime.now());
    return widget.bookings.where((booking) {
      final arrival = booking.arrivalDate;
      return arrival != null && arrival.isAfter(today);
    }).toList();
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }

  Future<void> _addOrder(Booking booking) async {
    final orderBatch = await showDialog<OrderBatch>(
      context: context,
      builder: (context) => BookingOrderDialog(
        booking: booking,
        products: widget.products,
      ),
    );

    if (orderBatch != null) {
      widget.onOrderBatchAdded(orderBatch);
    }
  }

  Future<void> _showGuestLink(int siteNumber) async {
    final link = GuestOrderLink.forSite(siteNumber);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Gastbestellung · Platz $siteNumber'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(
              data: link.url,
              size: 220,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 16),
            SelectableText(link.url),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: link.url));
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('Bestelllink kopiert.')),
                );
              }
            },
            icon: const Icon(Icons.copy_outlined),
            label: const Text('Link kopieren'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }

  Future<void> _addNote() async {
    final siteNumbers = _activeBookings
        .map((booking) => booking.siteNumber)
        .toList();
    final note = await showDialog<StayNote>(
      context: context,
      builder: (context) => StayNoteDialog(siteNumbers: siteNumbers),
    );

    if (note != null) {
      widget.onNoteAdded(note);
    }
  }
}

class _StayCard extends StatelessWidget {
  const _StayCard({
    required this.booking,
    required this.onOrder,
    required this.onGuestLink,
  });

  final Booking booking;
  final VoidCallback? onOrder;
  final VoidCallback onGuestLink;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: const Color(0xffa9ed21),
                child: Text('${booking.siteNumber}'),
              ),
              title: Text(
                booking.guestName,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                '${booking.arrival} – ${booking.departure} · '
                'Stellplatz ${booking.siteNumber} · '
                '${booking.adults} Erwachsene · ${booking.children} Kinder'
                '${booking.hasDog ? ' · Hund' : ''}'
                '${booking.hasElectricity ? ' · Strom' : ''}',
              ),
            ),
            Row(
              children: [
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: onOrder,
                  icon: const Icon(Icons.add_shopping_cart_outlined),
                  label: const Text('Bestellung'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onGuestLink,
                  tooltip: 'Gast-Bestelllink',
                  icon: const Icon(Icons.link_outlined),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  const _OrderList({required this.orders, required this.onStatusChanged});

  final List<Order> orders;
  final void Function(Order order, OrderStatus status) onStatusChanged;

  @override
  Widget build(BuildContext context) {
    String subtitleFor(Order order) {
      final location = 'Platz ${order.siteNumber} · ${order.categoryLabel}';
      final date = order.serviceDate;
      if (date == null) return location;
      return '$location · '
          '${MaterialLocalizations.of(context).formatMediumDate(date)}';
    }

    return Card(
      child: Column(
        children: [
          for (final order in orders)
            CheckboxListTile(
              value: order.status == OrderStatus.completed,
              onChanged: (value) {
                onStatusChanged(
                  order,
                  value == true ? OrderStatus.completed : OrderStatus.open,
                );
              },
              secondary: const Icon(Icons.receipt_long_outlined),
              title: Text('${order.quantity} × ${order.description}'),
              subtitle: Text(subtitleFor(order)),
            ),
        ],
      ),
    );
  }
}

class _NotesSection extends StatelessWidget {
  const _NotesSection({
    required this.notes,
    required this.onAdd,
    required this.onDelete,
  });

  final List<StayNote> notes;
  final VoidCallback onAdd;
  final ValueChanged<StayNote> onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          if (notes.isEmpty)
            const ListTile(
              leading: Icon(Icons.notes_outlined),
              title: Text('Noch keine Notizen'),
            ),
          for (final note in notes)
            ListTile(
              leading: Icon(_iconFor(note.category)),
              title: Text(note.text),
              subtitle: Text(
                'Stellplatz ${note.siteNumber} · ${note.categoryLabel}',
              ),
              trailing: IconButton(
                onPressed: () => onDelete(note),
                tooltip: 'Notiz löschen',
                icon: const Icon(Icons.delete_outline),
              ),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 12, bottom: 12),
              child: OutlinedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Notiz hinzufügen'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(StayNoteCategory category) {
    switch (category) {
      case StayNoteCategory.bakery:
        return Icons.bakery_dining_outlined;
      case StayNoteCategory.foodAndDrinks:
        return Icons.restaurant_outlined;
      case StayNoteCategory.general:
        return Icons.notes_outlined;
    }
  }
}
