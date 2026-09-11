import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../models/order_product.dart';

class BookingOrderDialog extends StatefulWidget {
  const BookingOrderDialog({
    required this.siteNumber,
    required this.products,
    this.bookingId,
    super.key,
  });

  final int siteNumber;
  final List<OrderProduct> products;
  final String? bookingId;

  @override
  State<BookingOrderDialog> createState() => _BookingOrderDialogState();
}

class _BookingOrderDialogState extends State<BookingOrderDialog> {
  final quantities = <String, int>{};
  String? selectedProductId;

  @override
  Widget build(BuildContext context) {
    final selectedProducts = widget.products
        .where((product) => quantities.containsKey(product.id))
        .toList();

    return AlertDialog(
      title: Text('Bestellung für Platz ${widget.siteNumber}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: selectedProductId,
                    decoration: const InputDecoration(labelText: 'Artikel'),
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
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: selectedProducts.isEmpty ? null : _save,
          child: const Text('Bestellung speichern'),
        ),
      ],
    );
  }

  void _save() {
    final orders = [
      for (final product in widget.products)
        if (quantities.containsKey(product.id))
          Order(
            siteNumber: widget.siteNumber,
            bookingId: widget.bookingId,
            description: product.name,
            quantity: quantities[product.id] ?? 1,
            category: product.category,
            productId: product.id,
            unitPrice: product.unitPrice,
          ),
    ];
    Navigator.pop(context, orders);
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
