import '../core/supabase_database.dart';
import '../models/invoice.dart';
import 'invoice_repository.dart';

class SupabaseInvoiceRepository implements InvoiceRepository {
  SupabaseInvoiceRepository(this.database);

  final SupabaseDatabase database;
  final _cache = <Invoice>[];

  @override
  List<Invoice> get invoices => List.unmodifiable(_cache);

  @override
  Future<List<Invoice>> load() async {
    final rows = await database.client
        .from('invoices')
        .select('*, invoice_lines(label, quantity, unit_price)')
        .order('created_at');
    _cache
      ..clear()
      ..addAll(rows.map(_fromRow));
    return invoices;
  }

  @override
  Future<Invoice> saveSnapshot(Invoice invoice) async {
    if (invoice.bookingId == null) throw StateError('Buchungs-ID fehlt.');
    final existing = _cache.where(
      (stored) => stored.bookingId == invoice.bookingId,
    );
    if (existing.isNotEmpty) return existing.first;
    final id = await database.client.rpc(
      'save_invoice_snapshot',
      params: {
        'p_booking_id': invoice.bookingId,
        'p_lines': [
          for (final line in invoice.lines)
            {
              'label': line.label,
              'quantity': line.quantity,
              'unit_price': line.unitPrice,
            },
        ],
      },
    ) as String;
    final row = await database.client
        .from('invoices')
        .select('*, invoice_lines(label, quantity, unit_price)')
        .eq('id', id)
        .single();
    final stored = _fromRow(row);
    _cache.add(stored);
    return stored;
  }

  @override
  Future<Invoice> markPaid(String bookingId, String paymentMethod) async {
    final row = await database.client
        .from('invoices')
        .update({'status': 'paid', 'payment_method': paymentMethod})
        .eq('booking_id', bookingId)
        .select('*, invoice_lines(label, quantity, unit_price)')
        .single();
    final paid = _fromRow(row);
    final index = _cache.indexWhere((item) => item.bookingId == bookingId);
    if (index >= 0) {
      _cache[index] = paid;
    } else {
      _cache.add(paid);
    }
    return paid;
  }

  Invoice _fromRow(Map<String, dynamic> row) => Invoice(
        id: row['id'] as String,
        bookingId: row['booking_id'] as String,
        guestName: row['guest_name'] as String,
        siteNumber: row['site_number'] as int,
        isPaid: row['status'] == 'paid',
        paymentMethod: row['payment_method'] as String?,
        lines: [
          for (final line in row['invoice_lines'] as List<dynamic>)
            InvoiceLine(
              label: (line as Map<String, dynamic>)['label'] as String,
              quantity: line['quantity'] as int,
              unitPrice: (line['unit_price'] as num).toDouble(),
            ),
        ],
      );
}