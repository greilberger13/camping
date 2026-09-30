class Pricing {
  const Pricing({
    required this.sitePerNight,
    required this.adultPerStay,
    required this.childPerStay,
  });

  static const initial = Pricing(
    sitePerNight: 21,
    adultPerStay: 8,
    childPerStay: 0,
  );

  final double sitePerNight;
  final double adultPerStay;
  final double childPerStay;

  bool get isValid => sitePerNight >= 0 &&
      adultPerStay >= 0 &&
      childPerStay >= 0 &&
      sitePerNight.isFinite &&
      adultPerStay.isFinite &&
      childPerStay.isFinite;
}