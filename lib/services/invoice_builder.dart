import '../models/booking.dart';
import '../models/invoice.dart';
import '../models/order.dart';
import '../models/pricing.dart';

class InvoiceBuilder {
  const InvoiceBuilder();

  Invoice build({
    required Booking booking,
    required List<Order> orders,
    Pricing pricing = Pricing.initial,
  }) {
    final nights = _numberOfNights(booking);
    final lines = <InvoiceLine>[
      InvoiceLine(
        label: 'Stellplatz · $nights ${nights == 1 ? 'Nacht' : 'Nächte'}',
        quantity: 1,
        unitPrice: nights * pricing.sitePerNight,
      ),
      InvoiceLine(
        label: 'Erwachsene',
        quantity: booking.adults,
        unitPrice: pricing.adultPerStay,
      ),
      if (booking.children > 0)
        InvoiceLine(
          label: 'Kinder',
          quantity: booking.children,
          unitPrice: pricing.childPerStay,
        ),
      if (booking.hasElectricity)
        const InvoiceLine(
          label: 'Strom',
          quantity: 1,
          unitPrice: 6,
        ),
      for (final order in orders.where(
        (order) =>
            booking.id != null &&
            order.bookingId == booking.id &&
            order.status == OrderStatus.completed,
      ))
        InvoiceLine(
          label: order.description,
          quantity: order.quantity,
          unitPrice: order.unitPrice ?? 0,
        ),
    ];

    return Invoice(
      bookingId: booking.id,
      guestName: booking.guestName,
      siteNumber: booking.siteNumber,
      lines: lines,
    );
  }

  int _numberOfNights(Booking booking) {
    final arrival = booking.arrivalDate;
    final departure = booking.departureDate;
    if (arrival == null || departure == null) {
      throw StateError('Ungültiger Buchungszeitraum.');
    }

    final arrivalDay = DateTime.utc(arrival.year, arrival.month, arrival.day);
    final departureDay = DateTime.utc(
      departure.year,
      departure.month,
      departure.day,
    );
    final nights = departureDay.difference(arrivalDay).inDays;
    return nights < 0 ? 0 : nights;
  }
}
