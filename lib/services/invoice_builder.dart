import '../models/booking.dart';
import '../models/invoice.dart';
import '../models/order.dart';

class InvoiceBuilder {
  const InvoiceBuilder();

  Invoice build({
    required Booking booking,
    required List<Order> orders,
    required bool electricity,
  }) {
    final nights = _numberOfNights(booking);
    final lines = <InvoiceLine>[
      InvoiceLine(
        label: 'Stellplatz · $nights ${nights == 1 ? 'Nacht' : 'Nächte'}',
        quantity: 1,
        unitPrice: nights * 21,
      ),
      InvoiceLine(
        label: 'Personen · ${booking.guests} Gäste',
        quantity: booking.guests,
        unitPrice: 8,
      ),
      if (electricity)
        const InvoiceLine(
          label: 'Strom',
          quantity: 1,
          unitPrice: 6,
        ),
      for (final order in orders.where(
        (order) =>
            order.siteNumber == booking.siteNumber &&
            order.status == OrderStatus.completed,
      ))
        InvoiceLine(
          label: order.description,
          quantity: order.quantity,
          unitPrice: order.unitPrice ?? _unitPriceFor(order.category),
        ),
    ];

    return Invoice(
      guestName: booking.guestName,
      siteNumber: booking.siteNumber,
      lines: lines,
    );
  }

  int _numberOfNights(Booking booking) {
    final arrival = booking.arrivalDate;
    final departure = booking.departureDate;
    if (arrival == null || departure == null) {
      return 1;
    }

    final nights = departure.difference(arrival).inDays;
    return nights < 1 ? 1 : nights;
  }

  double _unitPriceFor(OrderCategory category) {
    switch (category) {
      case OrderCategory.bakery:
        return 1.2;
      case OrderCategory.foodAndDrinks:
        return 6;
      case OrderCategory.kiosk:
        return 4;
    }
  }
}
