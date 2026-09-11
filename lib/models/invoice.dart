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
    required this.guestName,
    required this.siteNumber,
    required this.lines,
  });

  final String guestName;
  final int siteNumber;
  final List<InvoiceLine> lines;

  double get total => lines.fold(0, (sum, line) => sum + line.total);
}
