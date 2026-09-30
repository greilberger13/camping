import 'dart:async';

import 'package:flutter/material.dart';

import '../../integrations/hellocash/hellocash_gateway.dart';
import '../../models/booking.dart';
import '../../models/invoice.dart';
import '../../models/order.dart';
import '../../models/payment.dart';
import '../../models/pricing.dart';
import '../../services/invoice_builder.dart';
import '../../services/invoice_repository.dart';
import '../../shared/widgets/page_frame.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({
    required this.bookings,
    required this.orders,
    required this.pricing,
    required this.invoiceRepository,
    super.key,
  });

  final List<Booking> bookings;
  final List<Order> orders;
  final Pricing pricing;
  final InvoiceRepository invoiceRepository;

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  static const invoiceBuilder = InvoiceBuilder();

  List<Invoice> get invoices {
    return [
      for (final booking in widget.bookings)
        if (widget.invoiceRepository.invoices.any(
          (invoice) => invoice.bookingId == booking.id,
        ))
          widget.invoiceRepository.invoices.firstWhere(
            (invoice) => invoice.bookingId == booking.id,
          )
        else
          invoiceBuilder.build(
            booking: booking,
            orders: widget.orders,
            pricing: widget.pricing,
          ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: 'Abreise',
      subtitle: 'Offene Abrechnungen und Check-out',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryRow(invoices: invoices),
          const SizedBox(height: 24),
          for (final invoice in invoices)
            _InvoiceCard(
              invoice: invoice,
              isPaid: invoice.isPaid,
              paymentMethod: switch (invoice.paymentMethod) {
                'cash' => PaymentMethod.cash,
                'card' => PaymentMethod.card,
                'bank_transfer' => PaymentMethod.bankTransfer,
                _ => null,
              },
              onPaymentMethodSelected: (method) =>
                  unawaited(_recordPayment(invoice, method)),
              onExport: () => _exportInvoice(invoice),
            ),
        ],
      ),
    );
  }

  Future<void> _recordPayment(Invoice invoice, PaymentMethod method) async {
    try {
      final stored = await widget.invoiceRepository.saveSnapshot(invoice);
      await widget.invoiceRepository.markPaid(
        stored.bookingId!,
        switch (method) {
          PaymentMethod.cash => 'cash',
          PaymentMethod.card => 'card',
          PaymentMethod.bankTransfer => 'bank_transfer',
        },
      );
      if (mounted) setState(() {});
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Zahlung nicht gespeichert: $error')),
        );
      }
    }
  }

  Future<void> _exportInvoice(Invoice invoice) async {
    try {
      final snapshot = await widget.invoiceRepository.saveSnapshot(invoice);
      final result = await const HelloCashExportGateway().submitInvoice(snapshot);
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Export vorbereitet.')),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export nicht vorbereitet: $error')),
        );
      }
    }
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.invoices});

  final List<Invoice> invoices;

  @override
  Widget build(BuildContext context) {
    final openInvoices = invoices
      .where((invoice) => !invoice.isPaid)
        .toList();
    final openTotal = openInvoices.fold<double>(
      0,
      (sum, invoice) => sum + invoice.total,
    );

    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: [
        _SummaryCard(
          label: 'Offene Abreisen',
          value: '${openInvoices.length}',
          icon: Icons.logout,
          color: const Color(0xffc47737),
        ),
        _SummaryCard(
          label: 'Offener Betrag',
          value: '${openTotal.toStringAsFixed(2)} €',
          icon: Icons.euro_outlined,
          color: const Color(0xff4269a4),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({
    required this.invoice,
    required this.isPaid,
    required this.paymentMethod,
    required this.onPaymentMethodSelected,
    required this.onExport,
  });

  final Invoice invoice;
  final bool isPaid;
  final PaymentMethod? paymentMethod;
  final ValueChanged<PaymentMethod> onPaymentMethodSelected;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: const Color(0xffffbd21),
                child: Text('${invoice.siteNumber}'),
              ),
              title: Text(
                invoice.guestName,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text('Stellplatz ${invoice.siteNumber}'),
              trailing: Chip(
                label: Text(paymentMethod?.label ?? (isPaid ? 'Bezahlt' : 'Offen')),
                backgroundColor: isPaid
                    ? const Color(0xffd9ebe5)
                    : const Color(0xffffead8),
              ),
            ),
            const Divider(),
            for (final line in invoice.lines)
              _InvoiceLineTile(line: line),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Gesamt',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  '${invoice.total.toStringAsFixed(2)} €',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
            if (!isPaid) ...[
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () => _choosePaymentMethod(context),
                  icon: const Icon(Icons.check),
                  label: const Text('Zahlung erfassen'),
                ),
              ),
            ],
            if (isPaid && paymentMethod != null)
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  paymentMethod!.label,
                  style: const TextStyle(color: Color(0xff32866d)),
                ),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onExport,
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('HelloCash vorbereiten'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _choosePaymentMethod(BuildContext context) async {
    final method = await showDialog<PaymentMethod>(
      context: context,
      builder: (context) => const _PaymentMethodDialog(),
    );

    if (method != null) {
      onPaymentMethodSelected(method);
    }
  }
}

class _PaymentMethodDialog extends StatelessWidget {
  const _PaymentMethodDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Zahlungsart'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final method in PaymentMethod.values)
            ListTile(
              leading: Icon(_iconFor(method)),
              title: Text(method.label),
              onTap: () => Navigator.pop(context, method),
            ),
        ],
      ),
    );
  }

  IconData _iconFor(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return Icons.payments_outlined;
      case PaymentMethod.card:
        return Icons.credit_card_outlined;
      case PaymentMethod.bankTransfer:
        return Icons.account_balance_outlined;
    }
  }
}

class _InvoiceLineTile extends StatelessWidget {
  const _InvoiceLineTile({required this.line});

  final InvoiceLine line;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(line.label),
      subtitle: Text('${line.quantity} × ${line.unitPrice.toStringAsFixed(2)} €'),
      trailing: Text('${line.total.toStringAsFixed(2)} €'),
    );
  }
}
