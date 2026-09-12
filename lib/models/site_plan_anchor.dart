import 'package:flutter/material.dart';

class SitePlanAnchor {
  const SitePlanAnchor({required this.siteNumber, required this.position});

  final int siteNumber;
  final Offset position;

  static const defaults = <SitePlanAnchor>[
    SitePlanAnchor(siteNumber: 1, position: Offset(0.85, 0.60)),
    SitePlanAnchor(siteNumber: 2, position: Offset(0.78, 0.56)),
    SitePlanAnchor(siteNumber: 3, position: Offset(0.70, 0.52)),
    SitePlanAnchor(siteNumber: 4, position: Offset(0.62, 0.48)),
    SitePlanAnchor(siteNumber: 5, position: Offset(0.55, 0.44)),
    SitePlanAnchor(siteNumber: 6, position: Offset(0.78, 0.73)),
    SitePlanAnchor(siteNumber: 7, position: Offset(0.78, 0.81)),
    SitePlanAnchor(siteNumber: 8, position: Offset(0.69, 0.85)),
    SitePlanAnchor(siteNumber: 9, position: Offset(0.34, 0.62)),
    SitePlanAnchor(siteNumber: 10, position: Offset(0.41, 0.665)),
    SitePlanAnchor(siteNumber: 11, position: Offset(0.49, 0.71)),
    SitePlanAnchor(siteNumber: 12, position: Offset(0.56, 0.755)),
    SitePlanAnchor(siteNumber: 13, position: Offset(0.64, 0.80)),
    SitePlanAnchor(siteNumber: 14, position: Offset(0.71, 0.845)),
    SitePlanAnchor(siteNumber: 15, position: Offset(0.79, 0.89)),
    SitePlanAnchor(siteNumber: 16, position: Offset(0.86, 0.935)),
    SitePlanAnchor(siteNumber: 17, position: Offset(0.05, 0.45)),
    SitePlanAnchor(siteNumber: 18, position: Offset(0.13, 0.08)),
    SitePlanAnchor(siteNumber: 19, position: Offset(0.215, 0.155)),
    SitePlanAnchor(siteNumber: 20, position: Offset(0.30, 0.23)),
    SitePlanAnchor(siteNumber: 21, position: Offset(0.385, 0.305)),
    SitePlanAnchor(siteNumber: 22, position: Offset(0.47, 0.38)),
    SitePlanAnchor(siteNumber: 23, position: Offset(0.555, 0.455)),
    SitePlanAnchor(siteNumber: 24, position: Offset(0.48, 0.30)),
    SitePlanAnchor(siteNumber: 25, position: Offset(0.56, 0.38)),
    SitePlanAnchor(siteNumber: 26, position: Offset(0.64, 0.46)),
  ];
}
