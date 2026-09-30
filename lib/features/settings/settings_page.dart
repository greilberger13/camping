import 'package:flutter/material.dart';

import '../../models/order_product.dart';
import '../../models/pricing.dart';
import '../../shared/widgets/page_frame.dart';
import '../stays/order_product_dialog.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    required this.pricing,
    required this.products,
    required this.onSavePricing,
    required this.onCreateProduct,
    required this.onUpdateProduct,
    required this.onDeleteProduct,
    super.key,
  });

  final Pricing pricing;
  final List<OrderProduct> products;
  final Future<void> Function(Pricing) onSavePricing;
  final Future<void> Function(OrderProduct) onCreateProduct;
  final Future<void> Function(OrderProduct) onUpdateProduct;
  final Future<void> Function(String) onDeleteProduct;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final formKey = GlobalKey<FormState>();
  final siteController = TextEditingController();
  final adultController = TextEditingController();
  final childController = TextEditingController();
  bool saving = false;

  @override
  void initState() {
    super.initState();
    _setPricing(widget.pricing);
  }

  @override
  void didUpdateWidget(SettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.pricing, widget.pricing)) {
      _setPricing(widget.pricing);
    }
  }

  void _setPricing(Pricing pricing) {
    siteController.text = pricing.sitePerNight.toStringAsFixed(2);
    adultController.text = pricing.adultPerStay.toStringAsFixed(2);
    childController.text = pricing.childPerStay.toStringAsFixed(2);
  }

  @override
  void dispose() {
    siteController.dispose();
    adultController.dispose();
    childController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!formKey.currentState!.validate()) return;
    double? value(TextEditingController controller) =>
        double.tryParse(controller.text.trim().replaceAll(',', '.'));
    final pricing = Pricing(
      sitePerNight: value(siteController)!,
      adultPerStay: value(adultController)!,
      childPerStay: value(childController)!,
    );
    setState(() => saving = true);
    try {
      await widget.onSavePricing(pricing);
      if (mounted) _message('Tarife gespeichert.');
    } catch (error) {
      if (mounted) _message('Tarife konnten nicht gespeichert werden: $error');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _editProduct([OrderProduct? existing]) async {
    final product = await showDialog<OrderProduct>(
      context: context,
      builder: (context) => OrderProductDialog(product: existing),
    );
    if (product == null) return;
    try {
      if (existing == null) {
        await widget.onCreateProduct(product);
      } else {
        await widget.onUpdateProduct(product);
      }
    } catch (error) {
      if (mounted) _message('Artikel konnte nicht gespeichert werden: $error');
    }
  }

  Future<void> _deleteProduct(OrderProduct product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Artikel löschen?'),
        content: Text(product.name),
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
    if (confirmed != true) return;
    try {
      await widget.onDeleteProduct(product.id);
    } catch (error) {
      if (mounted) _message('Artikel konnte nicht gelöscht werden: $error');
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) => PageFrame(
        title: 'Einstellungen',
        subtitle: 'Tarife und Artikel',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tarife', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Form(
              key: formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _priceField('Stellplatz pro Nacht', siteController),
                  _priceField('Erwachsene pro Aufenthalt', adultController),
                  _priceField('Kinder pro Aufenthalt', childController),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: saving ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Tarife speichern'),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: Text('Artikelkatalog',
                      style: Theme.of(context).textTheme.titleLarge),
                ),
                IconButton(
                  onPressed: () => _editProduct(),
                  icon: const Icon(Icons.add),
                  tooltip: 'Artikel hinzufügen',
                ),
              ],
            ),
            for (final product in widget.products)
              ListTile(
                title: Text(product.name),
                subtitle: Text(product.categoryLabel),
                leading: const Icon(Icons.inventory_2_outlined),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${product.unitPrice.toStringAsFixed(2)} €'),
                    IconButton(
                      onPressed: () => _editProduct(product),
                      tooltip: 'Artikel bearbeiten',
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      onPressed: () => _deleteProduct(product),
                      tooltip: 'Artikel löschen',
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );

  Widget _priceField(String label, TextEditingController controller) =>
      SizedBox(
        width: 230,
        child: TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: label, suffixText: '€'),
          validator: (input) {
            final value = double.tryParse(
              (input ?? '').trim().replaceAll(',', '.'),
            );
            if (value == null || !value.isFinite) {
              return 'Bitte eine gültige Zahl eingeben.';
            }
            if (value < 0) return 'Der Preis darf nicht negativ sein.';
            return null;
          },
        ),
      );
}