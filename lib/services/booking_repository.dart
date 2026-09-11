import '../models/booking.dart';

abstract interface class BookingRepository {
  List<Booking> get current;

  Future<List<Booking>> load();

  Future<Booking> create(Booking booking);

  Future<Booking> update(Booking booking);

  Future<void> delete(Booking booking);
}
