import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../models/order_product.dart';

class BookingOrderDialog extends StatefulWidget {
  const BookingOrderDialog({
    required this.siteNumber,
    required this.products,
    super.key,
  });

  final int siteNumber;
  final List<OrderProduct> products;

  @override
  State<BookingOrderDialog> createState() => _BookingOrderDialogState();
}

class _BookingOrderDialogState extends State<BookingOrderDialog> {
  int quantity = 1;
  String? productId;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Bestellung für Platz ${widget.siteNumber}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: productId,
              decoration: const InputDecoration(labelText: 'Artikel'),
              items: [
                for (final product in widget.products)
                  DropdownMenuItem(
                    value: product.id,
                    child: Text(
                      '${product.name} · ${product.unitPrice.toStringAsFixed(2)} €',
                    ),
                  ),
              ],
              onChanged: (value) {
                setState(() => productId = value);
              },
              validator: (value) => value == null ? 'Artikel auswählen' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Menge'),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    if (quantity > 1) {
                      setState(() => quantity--);
                    }
                  },
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text('$quantity'),
                IconButton(
                  onPressed: () => setState(() => quantity++),
                  icon: const Icon(Icons.add_circle_outline),
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
            final product = _selectedProduct;
            if (product == null) {
              return;
            }
            Navigator.pop(
              context,
              Order(
                siteNumber: widget.siteNumber,
                description: product.name,
                quantity: quantity,
                category: product.category,
                productId: product.id,
                unitPrice: product.unitPrice,
              ),
            );
          },
          child: const Text('Bestellung speichern'),
        ),
      ],
    );
  }

  OrderProduct? get _selectedProduct {
    for (final product in widget.products) {
      if (product.id == productId) {
        return product;
      }
    }
    return null;
  }
}
