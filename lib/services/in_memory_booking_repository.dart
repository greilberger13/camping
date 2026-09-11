import '../models/booking.dart';
import 'booking_repository.dart';

class InMemoryBookingRepository implements BookingRepository {
  InMemoryBookingRepository({List<Booking> initial = const []})
      : _bookings = List<Booking>.of(initial);

  final List<Booking> _bookings;

  @override
  List<Booking> get current => List.unmodifiable(_bookings);

  @override
  Future<List<Booking>> load() async => current;

  @override
  Future<Booking> create(Booking booking) async {
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
    _bookings[index] = booking;
    return booking;
  }

  @override
  Future<void> delete(Booking booking) async {
    _bookings.removeWhere((item) => item.id == booking.id);
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();
}
