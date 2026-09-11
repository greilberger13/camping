enum VehicleType {
  motorhome,
  carVan,
  tent,
  carWithTrailer,
  other,
}

extension VehicleTypeLabel on VehicleType {
  String get label {
    switch (this) {
      case VehicleType.motorhome:
        return 'Wohnmobil';
      case VehicleType.carVan:
        return 'Auto / Van';
      case VehicleType.tent:
        return 'Zelt';
      case VehicleType.carWithTrailer:
        return 'Auto mit Anhänger';
      case VehicleType.other:
        return 'Sonstiges';
    }
  }
}
