import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../models/order_product.dart';

class OrderProductDialog extends StatefulWidget {
  const OrderProductDialog({this.product, super.key});

  final OrderProduct? product;

  @override
  State<OrderProductDialog> createState() => _OrderProductDialogState();
}

class _OrderProductDialogState extends State<OrderProductDialog> {
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  OrderCategory category = OrderCategory.bakery;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    if (product != null) {
      nameController.text = product.name;
      priceController.text = product.unitPrice.toStringAsFixed(2);
      category = product.category;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.product == null ? 'Artikel anlegen' : 'Artikel bearbeiten',
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Artikelname'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<OrderCategory>(
            initialValue: category,
            decoration: const InputDecoration(labelText: 'Kategorie'),
            items: [
              for (final value in OrderCategory.values)
                DropdownMenuItem(
                  value: value,
                  child: Text(_categoryLabel(value)),
                ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => category = value);
              }
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Preis pro Einheit',
              suffixText: '€',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(
            widget.product == null
                ? 'Artikel speichern'
                : 'Änderungen speichern',
          ),
        ),
      ],
    );
  }

  void _save() {
    final name = nameController.text.trim();
    final price = double.tryParse(priceController.text.trim().replaceAll(',', '.'));
    if (name.isEmpty || price == null || price < 0) {
      return;
    }

    Navigator.pop(
      context,
      OrderProduct(
        id: widget.product?.id ?? '${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        category: category,
        unitPrice: price,
      ),
    );
  }

  String _categoryLabel(OrderCategory value) {
    switch (value) {
      case OrderCategory.bakery:
        return 'Brötchenservice';
      case OrderCategory.foodAndDrinks:
        return 'Essen & Getränke';
      case OrderCategory.kiosk:
        return 'Kiosk';
    }
  }
}
