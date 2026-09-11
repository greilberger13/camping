import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/booking.dart';
import '../../models/guest_order_link.dart';
import '../../models/order.dart';
import '../../models/order_product.dart';
import '../../models/stay_note.dart';
import '../../shared/widgets/page_frame.dart';
import 'booking_order_dialog.dart';
import 'order_product_dialog.dart';
import 'stay_note_dialog.dart';

class StaysPage extends StatefulWidget {
  const StaysPage({
    required this.bookings,
    required this.orders,
    required this.products,
    required this.electricityBySite,
    required this.onOrderAdded,
    required this.onOrderUpdated,
    required this.onProductAdded,
    required this.onProductUpdated,
    required this.onProductDeleted,
    required this.notes,
    required this.onNoteAdded,
    required this.onNoteDeleted,
    required this.onElectricityChanged,
    super.key,
  });

  final List<Booking> bookings;
  final List<Order> orders;
  final List<OrderProduct> products;
  final Map<int, bool> electricityBySite;
  final ValueChanged<Order> onOrderAdded;
  final ValueChanged<Order> onOrderUpdated;
  final ValueChanged<OrderProduct> onProductAdded;
  final ValueChanged<OrderProduct> onProductUpdated;
  final ValueChanged<String> onProductDeleted;
  final List<StayNote> notes;
  final ValueChanged<StayNote> onNoteAdded;
  final ValueChanged<StayNote> onNoteDeleted;
  final void Function(int siteNumber, bool enabled) onElectricityChanged;

  @override
  State<StaysPage> createState() => _StaysPageState();
}

class _StaysPageState extends State<StaysPage> {
  @override
  Widget build(BuildContext context) {
    final activeBookings = _activeBookings;

    return PageFrame(
      title: 'Aufenthalt',
      subtitle: 'Aktive Gäste, Bestellungen und Notizen',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, 'Aktive Aufenthalte'),
          for (final booking in activeBookings)
            _StayCard(
              booking: booking,
              electricity: widget.electricityBySite[booking.siteNumber] ?? false,
              onElectricityChanged: (value) {
                widget.onElectricityChanged(booking.siteNumber, value);
              },
              onOrder: () => _addOrder(booking.siteNumber),
              onGuestLink: () => _showGuestLink(booking.siteNumber),
            ),
          const SizedBox(height: 28),
          _sectionTitle(context, 'Offene Bestellungen'),
          _OrderList(
            orders: widget.orders,
            onStatusChanged: (order, status) {
              widget.onOrderUpdated(order.copyWith(status: status));
            },
          ),
          const SizedBox(height: 28),
          _sectionTitle(context, 'Artikelkatalog'),
          _ProductCatalog(
            products: widget.products,
            onAdd: _addProduct,
            onEdit: _editProduct,
            onDelete: _deleteProduct,
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
    if (widget.bookings.isNotEmpty) {
      return widget.bookings;
    }

    return const [
      Booking(
        guestName: 'Anna Berger',
        arrival: '11.06.2026',
        departure: '13.06.2026',
        guests: 2,
        hasDog: false,
        siteNumber: 5,
      ),
      Booking(
        guestName: 'Peter Bauer',
        arrival: '10.06.2026',
        departure: '14.06.2026',
        guests: 2,
        hasDog: true,
        siteNumber: 22,
      ),
    ];
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

  Future<void> _addOrder(int siteNumber) async {
    final order = await showDialog<Order>(
      context: context,
      builder: (context) => BookingOrderDialog(
        siteNumber: siteNumber,
        products: widget.products,
      ),
    );

    if (order != null) {
      widget.onOrderAdded(order);
    }
  }

  Future<void> _addProduct() async {
    final product = await showDialog<OrderProduct>(
      context: context,
      builder: (context) => const OrderProductDialog(),
    );

    if (product != null) {
      widget.onProductAdded(product);
    }
  }

  Future<void> _editProduct(OrderProduct product) async {
    final updated = await showDialog<OrderProduct>(
      context: context,
      builder: (context) => OrderProductDialog(product: product),
    );

    if (updated != null) {
      widget.onProductUpdated(updated);
    }
  }

  Future<void> _deleteProduct(OrderProduct product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Artikel löschen?'),
        content: Text('„${product.name}“ aus dem Katalog entfernen?'),
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
      widget.onProductDeleted(product.id);
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
    required this.electricity,
    required this.onElectricityChanged,
    required this.onOrder,
    required this.onGuestLink,
  });

  final Booking booking;
  final bool electricity;
  final ValueChanged<bool> onElectricityChanged;
  final VoidCallback onOrder;
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
                '${booking.guests} Personen${booking.hasDog ? ' · Hund' : ''}',
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Strom'),
                    value: electricity,
                    onChanged: onElectricityChanged,
                  ),
                ),
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
              subtitle: Text(
                'Platz ${order.siteNumber} · ${order.categoryLabel}',
              ),
            ),
        ],
      ),
    );
  }
}

class _ProductCatalog extends StatelessWidget {
  const _ProductCatalog({
    required this.products,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final List<OrderProduct> products;
  final VoidCallback onAdd;
  final ValueChanged<OrderProduct> onEdit;
  final ValueChanged<OrderProduct> onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          for (final product in products)
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: Text(product.name),
              subtitle: Text(product.categoryLabel),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${product.unitPrice.toStringAsFixed(2)} €'),
                  IconButton(
                    onPressed: () => onEdit(product),
                    tooltip: 'Artikel bearbeiten',
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    onPressed: () => onDelete(product),
                    tooltip: 'Artikel löschen',
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 12, bottom: 12),
              child: OutlinedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Artikel anlegen'),
              ),
            ),
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
