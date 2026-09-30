import '../models/invoice.dart';

abstract interface class InvoiceRepository {
  List<Invoice> get invoices;

  Future<List<Invoice>> load();
  Future<Invoice> saveSnapshot(Invoice invoice);
  Future<Invoice> markPaid(String bookingId, String paymentMethod);
}