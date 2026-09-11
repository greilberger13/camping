class GuestOrderLink {
  const GuestOrderLink({required this.siteNumber, required this.token});

  final int siteNumber;
  final String token;

  String get url {
    return 'https://bestellung.peterbauer.at/platz/$siteNumber?token=$token';
  }

  factory GuestOrderLink.forSite(int siteNumber) {
    final token = 'PB-${siteNumber.toString().padLeft(2, '0')}-ORDER';
    return GuestOrderLink(siteNumber: siteNumber, token: token);
  }
}
