import '../models/invoice.dart';
import 'invoice_repository.dart';

class InMemoryInvoiceRepository implements InvoiceRepository {
  final _cache = <Invoice>[];

  @override
  List<Invoice> get invoices => List.unmodifiable(_cache);

  @override
  Future<List<Invoice>> load() async => invoices;

  @override
  Future<Invoice> saveSnapshot(Invoice invoice) async {
    final bookingId = invoice.bookingId;
    if (bookingId == null) throw StateError('Buchungs-ID fehlt.');
    for (final stored in _cache) {
      if (stored.bookingId == bookingId) return stored;
    }
    final stored = Invoice(
      id: bookingId,
      bookingId: bookingId,
      guestName: invoice.guestName,
      siteNumber: invoice.siteNumber,
      lines: List.unmodifiable(invoice.lines),
    );
    _cache.add(stored);
    return stored;
  }

  @override
  Future<Invoice> markPaid(String bookingId, String paymentMethod) async {
    final index = _cache.indexWhere((item) => item.bookingId == bookingId);
    if (index < 0) throw StateError('Rechnung nicht gefunden.');
    final current = _cache[index];
    final paid = Invoice(
      id: current.id,
      bookingId: bookingId,
      guestName: current.guestName,
      siteNumber: current.siteNumber,
      lines: current.lines,
      isPaid: true,
      paymentMethod: paymentMethod,
    );
    _cache[index] = paid;
    return paid;
  }
}