import '../models/booking.dart';
import '../models/camp_site.dart';
import 'booking_availability.dart';
import 'booking_repository.dart';

class InMemoryBookingRepository implements BookingRepository {
  InMemoryBookingRepository({
    List<Booking> initial = const [],
    List<CampSite> Function()? sites,
  })  : _bookings = List<Booking>.of(initial),
        _sites = sites ?? (() => CampSite.samples);

  final List<Booking> _bookings;
  final List<CampSite> Function() _sites;
  static const availability = BookingAvailability();

  @override
  List<Booking> get current => List.unmodifiable(_bookings);

  @override
  Future<List<Booking>> load() async => current;

  @override
  Future<Booking> create(Booking booking) async {
    _validate(booking);
    final stored = booking.id == null
        ? booking.copyWith(id: _newId())
        : booking;
    _bookings.add(stored);
    return stored;
  }

  @override
  Future<Booking> update(Booking booking) async {
    final index = _bookings.indexWhere((item) => item.id == booking.id);
    if (index == -1) {
      throw StateError('Booking not found: ${booking.id}');
    }
    _validate(booking);
    _bookings[index] = booking;
    return booking;
  }

  @override
  Future<void> delete(Booking booking) async {
    _bookings.removeWhere((item) => item.id == booking.id);
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  void _validate(Booking booking) {
    final matches = _sites().where((site) => site.number == booking.siteNumber);
    if (matches.isEmpty ||
        !availability.isAvailable(
          booking,
          matches.first,
          _bookings,
          allowExistingBlocked: true,
        )) {
      throw StateError('Stellplatz oder Buchungszeitraum ist nicht verfügbar.');
    }
  }
}
