import '../core/supabase_database.dart';
import '../models/booking.dart';
import '../models/vehicle_type.dart';
import 'booking_repository.dart';

class SupabaseBookingRepository implements BookingRepository {
  SupabaseBookingRepository(this.database);

  final SupabaseDatabase database;
  final cache = <Booking>[];

  @override
  List<Booking> get current => List.unmodifiable(cache);

  @override
  Future<List<Booking>> load() async {
    final rows = await database.client
        .from('bookings')
        .select('*, camp_sites!inner(site_number)')
        .neq('status', 'cancelled')
        .order('arrival_date');

    cache
      ..clear()
      ..addAll(rows.map(_fromRow));
    return current;
  }

  @override
  Future<Booking> create(Booking booking) async {
    final siteId = await _siteIdForNumber(booking.siteNumber);
    final row = await database.client
        .from('bookings')
        .insert(_toRow(booking, siteId: siteId))
        .select('*, camp_sites!inner(site_number)')
        .single();
    final stored = _fromRow(row);
    cache.add(stored);
    return stored;
  }

  @override
  Future<Booking> update(Booking booking) async {
    if (booking.id == null) {
      throw StateError('Cannot update a booking without an id.');
    }

    final siteId = await _siteIdForNumber(booking.siteNumber);
    final row = await database.client
        .from('bookings')
        .update(_toRow(booking, siteId: siteId))
        .eq('id', booking.id!)
        .select('*, camp_sites!inner(site_number)')
        .single();
    final updated = _fromRow(row);
    final index = cache.indexWhere((item) => item.id == updated.id);
    if (index == -1) {
      cache.add(updated);
    } else {
      cache[index] = updated;
    }
    return updated;
  }

  @override
  Future<void> delete(Booking booking) async {
    if (booking.id == null) {
      throw StateError('Cannot delete a booking without an id.');
    }

    await database.client.from('bookings').delete().eq('id', booking.id!);
    cache.removeWhere((item) => item.id == booking.id);
  }

  Future<String> _siteIdForNumber(int siteNumber) async {
    final row = await database.client
        .from('camp_sites')
        .select('id')
        .eq('site_number', siteNumber)
        .single();
    return row['id'] as String;
  }

  Map<String, dynamic> _toRow(Booking booking, {required String siteId}) {
    return {
      'guest_name': booking.guestName,
      'address': booking.address,
      'birth_date': booking.birthDate,
      'phone': booking.phone,
      'arrival_date': _dateValue(booking.arrivalDate),
      'departure_date': _dateValue(booking.departureDate),
      'guests': booking.guests,
      'has_dog': booking.hasDog,
      'vehicle_type': _vehicleValue(booking.vehicleType),
      'site_id': siteId,
      'status': 'open',
    };
  }

  Booking _fromRow(Map<String, dynamic> row) {
    final site = row['camp_sites'] as Map<String, dynamic>;
    return Booking(
      id: row['id'] as String,
      guestName: row['guest_name'] as String,
      address: row['address'] as String?,
      birthDate: row['birth_date'] as String?,
      phone: row['phone'] as String?,
      arrival: _displayDate(row['arrival_date'] as String),
      departure: _displayDate(row['departure_date'] as String),
      guests: row['guests'] as int,
      hasDog: row['has_dog'] as bool,
      vehicleType: _vehicleFromValue(row['vehicle_type'] as String),
      siteNumber: site['site_number'] as int,
    );
  }

  String _dateValue(DateTime? date) {
    if (date == null) {
      throw StateError('Booking contains an invalid date.');
    }
    return date.toIso8601String().split('T').first;
  }

  String _displayDate(String value) {
    final date = DateTime.parse(value);
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }

  String _vehicleValue(VehicleType value) {
    switch (value) {
      case VehicleType.motorhome:
        return 'motorhome';
      case VehicleType.carVan:
        return 'car_van';
      case VehicleType.tent:
        return 'tent';
      case VehicleType.carWithTrailer:
        return 'car_with_trailer';
      case VehicleType.other:
        return 'other';
    }
  }

  VehicleType _vehicleFromValue(String value) {
    switch (value) {
      case 'car_van':
        return VehicleType.carVan;
      case 'tent':
        return VehicleType.tent;
      case 'car_with_trailer':
        return VehicleType.carWithTrailer;
      case 'other':
        return VehicleType.other;
      default:
        return VehicleType.motorhome;
    }
  }
}
