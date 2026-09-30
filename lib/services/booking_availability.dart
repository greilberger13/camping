import '../models/booking.dart';
import '../models/camp_site.dart';

class BookingAvailability {
  const BookingAvailability();

  bool isAvailable(
    Booking draft,
    CampSite site,
    List<Booking> existing, {
    bool allowExistingBlocked = false,
  }) {
    final arrival = draft.arrivalDate;
    final departure = draft.departureDate;
    final alreadyOnSite = allowExistingBlocked && draft.id != null &&
        existing.any((booking) =>
            booking.id == draft.id && booking.siteNumber == site.number);
    final current = DateTime.now();
    final today = DateTime(current.year, current.month, current.day);
    final occupiesToday = arrival != null && departure != null &&
      !today.isBefore(arrival) && today.isBefore(departure);
    if (arrival == null ||
        departure == null ||
        departure.isBefore(arrival) ||
        draft.adults < 1 ||
        draft.children < 0 ||
        draft.siteNumber != site.number ||
        (site.status == 'Gesperrt' && !alreadyOnSite) ||
        (site.status == 'Belegt' && occupiesToday && !alreadyOnSite) ||
        !site.supportsVehicleType(draft.vehicleType)) {
      return false;
    }
    return existing.every((booking) => !draft.conflictsWith(booking));
  }

  bool hasLateCheckoutWarning(
    Booking draft,
    List<Booking> existing,
  ) {
    final arrival = draft.arrivalDate;
    if (arrival == null) return false;
    return existing.any((booking) {
      return booking.siteNumber == draft.siteNumber &&
          booking.id != draft.id &&
          booking.lateCheckout &&
          booking.departureDate == arrival;
    });
  }
}