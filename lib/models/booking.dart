import 'vehicle_type.dart';

class Booking {
  const Booking({
    this.id,
    required this.guestName,
    required this.arrival,
    required this.departure,
    int? guests,
    int? adults,
    this.children = 0,
    required this.hasDog,
    this.hasElectricity = false,
    this.lateCheckout = false,
    required this.siteNumber,
    this.vehicleType = VehicleType.motorhome,
    this.address,
    this.birthDate,
    this.phone,
  }) : adults = adults ?? guests ?? 1;

  final String? id;
  final String guestName;
  final String arrival;
  final String departure;
  final int adults;
  final int children;
  final bool hasDog;
  final bool hasElectricity;
  final bool lateCheckout;
  final int siteNumber;
  final VehicleType vehicleType;
  final String? address;
  final String? birthDate;
  final String? phone;

  int get guests => adults + children;

  Booking copyWith({String? id}) {
    return Booking(
      id: id ?? this.id,
      guestName: guestName,
      arrival: arrival,
      departure: departure,
      adults: adults,
      children: children,
      hasDog: hasDog,
      hasElectricity: hasElectricity,
      lateCheckout: lateCheckout,
      siteNumber: siteNumber,
      vehicleType: vehicleType,
      address: address,
      birthDate: birthDate,
      phone: phone,
    );
  }

  DateTime? get arrivalDate => _parseDate(arrival);

  DateTime? get departureDate => _parseDate(departure);

  bool conflictsWith(Booking other) {
    if (siteNumber != other.siteNumber ||
        (id != null && id == other.id)) {
      return false;
    }

    final currentArrival = arrivalDate;
    final currentDeparture = departureDate;
    final otherArrival = other.arrivalDate;
    final otherDeparture = other.departureDate;

    if (currentArrival == null ||
        currentDeparture == null ||
        otherArrival == null ||
        otherDeparture == null) {
      return false;
    }

    return currentArrival.isBefore(otherDeparture) &&
        otherArrival.isBefore(currentDeparture);
  }

  DateTime? _parseDate(String value) {
    final parts = value.split('.');
    if (parts.length != 3) {
      return null;
    }

    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) {
      return null;
    }

    final parsed = DateTime(year, month, day);
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      return null;
    }

    return parsed;
  }
}
