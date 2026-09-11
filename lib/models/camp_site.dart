import 'package:flutter/material.dart';

class CampSite {
  const CampSite(this.number, this.type, this.status, this.color, {this.guest});

  final int number;
  final String type;
  final String status;
  final Color color;
  final String? guest;

  static const samples = [
    CampSite(1, 'Wohnmobil', 'Belegt', Color(0xffa9ed21), guest: 'Familie Huber · bis 14.06.'),
    CampSite(2, 'Wohnmobil', 'Reserviert', Color(0xffa9ed21), guest: 'Thomas Leitner · ab 15.06.'),
    CampSite(3, 'Wohnmobil', 'Frei', Color(0xffa9ed21)),
    CampSite(4, 'Wohnmobil', 'Frei', Color(0xffa9ed21)),
    CampSite(5, 'Wohnmobil', 'Belegt', Color(0xffa9ed21), guest: 'Anna Berger · bis 13.06.'),
    CampSite(6, 'Auto / Van', 'Reserviert', Color(0xff22d9ed), guest: 'Markus Wolf · ab 16.06.'),
    CampSite(7, 'Auto / Van', 'Frei', Color(0xff22d9ed)),
    CampSite(8, 'Zelt', 'Belegt', Color(0xffffbd21), guest: 'Lisa Moser · bis 12.06.'),
    CampSite(9, 'Wohnmobil', 'Frei', Color(0xffa9ed21)),
    CampSite(10, 'Wohnmobil', 'Frei', Color(0xffa9ed21)),
    CampSite(11, 'Wohnmobil', 'Belegt', Color(0xffa9ed21), guest: 'Robert Steiner · bis 15.06.'),
    CampSite(12, 'Wohnmobil', 'Frei', Color(0xffa9ed21)),
    CampSite(13, 'Wohnmobil', 'Frei', Color(0xffa9ed21)),
    CampSite(14, 'Wohnmobil', 'Frei', Color(0xffa9ed21)),
    CampSite(15, 'Wohnmobil', 'Reserviert', Color(0xffa9ed21), guest: 'Julia Maier · ab 18.06.'),
    CampSite(16, 'Wohnmobil', 'Frei', Color(0xffa9ed21)),
    CampSite(17, 'Zelt', 'Frei', Color(0xffffbd21)),
    CampSite(18, 'Auto mit Anhänger', 'Belegt', Color(0xffff6ba8), guest: 'Klaus Pichler · bis 16.06.'),
    CampSite(19, 'Auto mit Anhänger', 'Frei', Color(0xffff6ba8)),
    CampSite(20, 'Auto mit Anhänger', 'Reserviert', Color(0xffff6ba8), guest: 'Eva Gruber · ab 20.06.'),
    CampSite(21, 'Auto mit Anhänger', 'Frei', Color(0xffff6ba8)),
    CampSite(22, 'Auto mit Anhänger', 'Belegt', Color(0xffff6ba8), guest: 'Peter Bauer · bis 14.06.'),
    CampSite(23, 'Auto mit Anhänger', 'Frei', Color(0xffff6ba8)),
    CampSite(24, 'Wohnmobil', 'Frei', Color(0xffa9ed21)),
    CampSite(25, 'Wohnmobil', 'Frei', Color(0xffa9ed21)),
    CampSite(26, 'Wohnmobil', 'Reserviert', Color(0xffa9ed21), guest: 'Stefan Koch · ab 17.06.'),
  ];
}
