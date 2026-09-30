class InvoiceLine {
  const InvoiceLine({
    required this.label,
    required this.quantity,
    required this.unitPrice,
  });

  final String label;
  final int quantity;
  final double unitPrice;

  double get total => quantity * unitPrice;
}

class Invoice {
  const Invoice({
    this.id,
    this.bookingId,
    required this.guestName,
    required this.siteNumber,
    required this.lines,
    this.isPaid = false,
    this.paymentMethod,
  });

  final String? id;
  final String? bookingId;
  final String guestName;
  final int siteNumber;
  final List<InvoiceLine> lines;
  final bool isPaid;
  final String? paymentMethod;

  double get total => lines.fold(0, (sum, line) => sum + line.total);
}
