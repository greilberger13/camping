import 'package:flutter/material.dart';

class SitePlanAnchor {
  const SitePlanAnchor({required this.siteNumber, required this.position});

  final int siteNumber;
  final Offset position;

static const defaults = <SitePlanAnchor>[
    SitePlanAnchor(siteNumber: 1, position: Offset(0.640, 0.656)),
    SitePlanAnchor(siteNumber: 2, position: Offset(0.587, 0.622)),
    SitePlanAnchor(siteNumber: 3, position: Offset(0.528, 0.586)),
    SitePlanAnchor(siteNumber: 4, position: Offset(0.469, 0.549)),
    SitePlanAnchor(siteNumber: 5, position: Offset(0.406, 0.514)),
    SitePlanAnchor(siteNumber: 6, position: Offset(0.784, 0.749)),
    SitePlanAnchor(siteNumber: 7, position: Offset(0.751, 0.803)),
    SitePlanAnchor(siteNumber: 8, position: Offset(0.706, 0.862)),
    SitePlanAnchor(siteNumber: 9, position: Offset(0.624, 0.820)),
    SitePlanAnchor(siteNumber: 10, position: Offset(0.561, 0.786)),
    SitePlanAnchor(siteNumber: 11, position: Offset(0.509, 0.747)),
    SitePlanAnchor(siteNumber: 12, position: Offset(0.445, 0.709)),
    SitePlanAnchor(siteNumber: 13, position: Offset(0.386, 0.672)),
    SitePlanAnchor(siteNumber: 14, position: Offset(0.329, 0.638)),
    SitePlanAnchor(siteNumber: 15, position: Offset(0.271, 0.598)),
    SitePlanAnchor(siteNumber: 16, position: Offset(0.209, 0.552)),
    SitePlanAnchor(siteNumber: 17, position: Offset(0.119, 0.463)),
    SitePlanAnchor(siteNumber: 18, position: Offset(0.181, 0.371)),
    SitePlanAnchor(siteNumber: 19, position: Offset(0.219, 0.311)),
    SitePlanAnchor(siteNumber: 20, position: Offset(0.275, 0.260)),
    SitePlanAnchor(siteNumber: 21, position: Offset(0.316, 0.193)),
    SitePlanAnchor(siteNumber: 22, position: Offset(0.369, 0.135)),
    SitePlanAnchor(siteNumber: 23, position: Offset(0.404, 0.084)),
    SitePlanAnchor(siteNumber: 24, position: Offset(0.593, 0.180)),
    SitePlanAnchor(siteNumber: 25, position: Offset(0.465, 0.354)),
    SitePlanAnchor(siteNumber: 26, position: Offset(0.427, 0.406)),
  ];
}
