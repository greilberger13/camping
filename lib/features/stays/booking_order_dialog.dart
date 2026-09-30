import 'package:flutter/material.dart';

import '../../models/booking.dart';
import '../../models/order.dart';
import '../../models/order_batch.dart';
import '../../models/order_product.dart';

class BookingOrderDialog extends StatefulWidget {
  const BookingOrderDialog({
    required this.booking,
    required this.products,
    super.key,
  });

  final Booking booking;
  final List<OrderProduct> products;

  @override
  State<BookingOrderDialog> createState() => _BookingOrderDialogState();
}

class _BookingOrderDialogState extends State<BookingOrderDialog> {
  final formKey = GlobalKey<FormState>();
  final quantities = <String, int>{};
  String? selectedProductId;
  DateTime? serviceDate;

  @override
  void initState() {
    super.initState();
    final arrival = widget.booking.arrivalDate;
    final departure = widget.booking.departureDate;
    final today = DateUtils.dateOnly(DateTime.now());
    if (arrival != null && departure != null) {
      serviceDate = today.isBefore(arrival)
          ? arrival
          : today.isAfter(departure)
              ? departure
              : today;
    }
  }

  Future<void> _chooseDate() async {
    final arrival = widget.booking.arrivalDate;
    final departure = widget.booking.departureDate;
    if (arrival == null || departure == null || serviceDate == null) {
      return;
    }
    final chosen = await showDatePicker(
      context: context,
      initialDate: serviceDate!,
      firstDate: arrival,
      lastDate: departure,
    );
    if (chosen != null) {
      setState(() => serviceDate = chosen);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedProducts = widget.products
        .where((product) => quantities.containsKey(product.id))
        .toList();

    return AlertDialog(
      title: Text('Bestellung für Platz ${widget.booking.siteNumber}'),
      content: SingleChildScrollView(
        child: Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            TextFormField(
              key: ValueKey(serviceDate),
              initialValue: serviceDate == null
                  ? ''
                  : MaterialLocalizations.of(context).formatMediumDate(
                      serviceDate!,
                    ),
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Bereitstellung',
                suffixIcon: Icon(Icons.event_outlined),
              ),
              onTap: serviceDate == null ? null : _chooseDate,
              validator: (_) => serviceDate == null
                  ? 'Kein gültiger Buchungszeitraum.'
                  : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: selectedProductId,
                    decoration: const InputDecoration(labelText: 'Artikel'),
                    validator: (_) => quantities.isEmpty
                        ? 'Bitte mindestens einen Artikel hinzufügen.'
                        : null,
                    items: [
                      for (final product in widget.products)
                        DropdownMenuItem(
                          value: product.id,
                          child: Text(product.name),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        selectedProductId = value;
                        quantities.putIfAbsent(value, () => 1);
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: selectedProductId == null
                      ? null
                      : () => setState(() => selectedProductId = null),
                  tooltip: 'Auswahl leeren',
                  icon: const Icon(Icons.clear),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (selectedProducts.isEmpty)
              const Text('Noch keine Artikel hinzugefügt.'),
            for (final product in selectedProducts)
              _ProductQuantityRow(
                product: product,
                quantity: quantities[product.id] ?? 1,
                onChanged: (quantity) {
                  setState(() => quantities[product.id] = quantity);
                },
                onRemove: () {
                  setState(() => quantities.remove(product.id));
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Bestellung speichern'),
        ),
      ],
    );
  }

  void _save() {
    if (!formKey.currentState!.validate()) return;
    if (widget.booking.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Buchung zuerst speichern.')),
      );
      return;
    }
    final date = serviceDate!;
    final orders = [
      for (final product in widget.products)
        if (quantities.containsKey(product.id))
          Order(
            siteNumber: widget.booking.siteNumber,
            bookingId: widget.booking.id,
            description: product.name,
            quantity: quantities[product.id] ?? 1,
            category: product.category,
            productId: product.id,
            unitPrice: product.unitPrice,
            serviceDate: date,
          ),
    ];
    Navigator.pop(
      context,
      OrderBatch(
        siteNumber: widget.booking.siteNumber,
        bookingId: widget.booking.id,
        serviceDate: date,
        items: orders,
      ),
    );
  }
}

class _ProductQuantityRow extends StatelessWidget {
  const _ProductQuantityRow({
    required this.product,
    required this.quantity,
    required this.onChanged,
    required this.onRemove,
  });

  final OrderProduct product;
  final int quantity;
  final ValueChanged<int> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(product.name),
      subtitle: Text('${product.unitPrice.toStringAsFixed(2)} € pro Einheit'),
      leading: IconButton(
        onPressed: onRemove,
        tooltip: 'Artikel entfernen',
        icon: const Icon(Icons.remove_circle_outline),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: quantity > 1 ? () => onChanged(quantity - 1) : null,
            icon: const Icon(Icons.remove),
          ),
          Text('$quantity'),
          IconButton(
            onPressed: () => onChanged(quantity + 1),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
