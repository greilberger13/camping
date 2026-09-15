import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/camping_dates.dart';
import '../../models/booking.dart';
import '../../models/camp_site.dart';
import '../../models/site_plan_anchor.dart';
import '../../shared/widgets/page_frame.dart';

bool _bookingOccupiesToday(Booking booking) {
  final arrival = booking.arrivalDate;
  final departure = booking.departureDate;
  final today = CampingDates.operationalDay;
  if (arrival == null || departure == null) {
    return false;
  }
  return !today.isBefore(arrival) && today.isBefore(departure);
}

class SiteMapPage extends StatefulWidget {
  const SiteMapPage({required this.bookings, required this.sites, required this.onSiteTap, super.key});

  final List<Booking> bookings;
  final List<CampSite> sites;
  final ValueChanged<int> onSiteTap;

  @override
  State<SiteMapPage> createState() => _SiteMapPageState();
}

class _SiteMapPageState extends State<SiteMapPage> {
  bool calibrating = false;
  late final Map<int, Offset> anchors = {
    for (final anchor in SitePlanAnchor.defaults) anchor.siteNumber: anchor.position,
  };

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: 'Platzplan',
      subtitle: calibrating
          ? 'Ziehe die Punkte auf die passenden Zahlen im Plan'
          : 'Tippe auf einen Stellplatz für Details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Wrap(
                  spacing: 16,
                  children: [
                    _Legend(Color(0xff32866d), 'Frei'),
                    _Legend(Color(0xffd69b32), 'Reserviert'),
                    _Legend(Color(0xffc65b54), 'Belegt'),
                    _Legend(Color(0xff777f86), 'Gesperrt'),
                  ],
                ),
              ),
              if (calibrating)
                TextButton.icon(
                  onPressed: _copyCalibratedCode,
                  icon: const Icon(Icons.copy_outlined),
                  label: const Text('Code kopieren'),
                ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: () => setState(() => calibrating = !calibrating),
                icon: Icon(calibrating ? Icons.check : Icons.tune),
                label: Text(calibrating ? 'Fertig' : 'Kalibrieren'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _SitePlanImage(
                bookings: widget.bookings,
                sites: widget.sites,
                anchors: anchors,
                calibrating: calibrating,
                onSiteTap: widget.onSiteTap,
                onAnchorDragged: (siteNumber, position) {
                  setState(() => anchors[siteNumber] = position);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copyCalibratedCode() async {
    final sorted = anchors.keys.toList()..sort();
    final lines = [
      for (final number in sorted)
        '    SitePlanAnchor(siteNumber: $number, position: '
            'Offset(${anchors[number]!.dx.toStringAsFixed(3)}, '
            '${anchors[number]!.dy.toStringAsFixed(3)})),',
    ];
    final code = 'static const defaults = <SitePlanAnchor>[\n${lines.join('\n')}\n  ];';

    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Code kopiert · in site_plan_anchor.dart einfügen')),
    );
  }
}

class _SitePlanImage extends StatelessWidget {
  const _SitePlanImage({
    required this.bookings,
    required this.sites,
    required this.anchors,
    required this.calibrating,
    required this.onSiteTap,
    required this.onAnchorDragged,
  });

  final List<Booking> bookings;
  final List<CampSite> sites;
  final Map<int, Offset> anchors;
  final bool calibrating;
  final ValueChanged<int> onSiteTap;
  final void Function(int siteNumber, Offset position) onAnchorDragged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : availableWidth;
        final imageSize = availableWidth < availableHeight
            ? availableWidth
            : availableHeight;
        final horizontalOffset = (availableWidth - imageSize) / 2;
        final verticalOffset = (availableHeight - imageSize) / 2;
        return AspectRatio(
          aspectRatio: 1,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/Lageplan.jpg',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return _SiteGrid(
                    bookings: bookings,
                    sites: sites,
                    onSiteTap: onSiteTap,
                  );
                },
              ),
              for (final site in sites)
                _ImageSiteOverlay(
                  site: site,
                  booking: _bookingFor(site.number),
                  color: site.color,
                  disabled: _isDisabled(site, _bookingFor(site.number)),
                  position: anchors[site.number] ?? const Offset(0.5, 0.5),
                  imageSize: imageSize,
                  horizontalOffset: horizontalOffset,
                  verticalOffset: verticalOffset,
                  calibrating: calibrating,
                  onSiteTap: onSiteTap,
                  onDragged: (position) => onAnchorDragged(site.number, position),
                ),
            ],
          ),
        );
      },
    );
  }

  Booking? _bookingFor(int siteNumber) {
    for (final booking in bookings) {
      if (booking.siteNumber == siteNumber) {
        return booking;
      }
    }
    return null;
  }

  bool _isDisabled(CampSite site, Booking? booking) {
    if (booking != null && _bookingOccupiesToday(booking)) {
      return true;
    }
    return site.status == 'Belegt' || site.status == 'Gesperrt';
  }
}

class _ImageSiteOverlay extends StatelessWidget {
  const _ImageSiteOverlay({
    required this.site,
    required this.booking,
    required this.color,
    required this.disabled,
    required this.position,
    required this.imageSize,
    required this.horizontalOffset,
    required this.verticalOffset,
    required this.calibrating,
    required this.onSiteTap,
    required this.onDragged,
  });

  final CampSite site;
  final Booking? booking;
  final Color color;
  final bool disabled;
  final Offset position;
  final double imageSize;
  final double horizontalOffset;
  final double verticalOffset;
  final bool calibrating;
  final ValueChanged<int> onSiteTap;
  final ValueChanged<Offset> onDragged;

  @override
  Widget build(BuildContext context) {
    final statusColor = booking != null
        ? const Color(0xffd69b32)
        : site.status == 'Belegt'
            ? const Color(0xffc65b54)
                : site.status == 'Reserviert'
                ? const Color(0xffd69b32)
                : site.status == 'Gesperrt'
                ? const Color(0xff777f86)
                : const Color(0xff32866d);

    final marker = DecoratedBox(
      decoration: BoxDecoration(
        color: calibrating
            ? const Color(0xff1f6f68).withValues(alpha: 0.35)
            : disabled
                ? const Color(0xffb8bec3).withValues(alpha: 0.6)
                : color.withValues(alpha: 0.22),
        border: Border.all(
          color: calibrating
              ? const Color(0xff1f6f68)
              : disabled
                  ? const Color(0xff777f86)
                  : statusColor,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      // The printed number on the plan stays visible through the marker.
      child: calibrating
          ? Center(
              child: Text(
                '${site.number}',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
              ),
            )
          : null,
    );

    return Positioned(
      left: horizontalOffset + position.dx * imageSize,
      top: verticalOffset + position.dy * imageSize,
      width: 42,
      height: 34,
      child: calibrating
          ? GestureDetector(
              onPanUpdate: (details) {
                final dx = position.dx + details.delta.dx / imageSize;
                final dy = position.dy + details.delta.dy / imageSize;
                onDragged(Offset(dx.clamp(0.0, 1.0), dy.clamp(0.0, 1.0)));
              },
              child: marker,
            )
          : InkWell(
              onTap: disabled ? null : () => onSiteTap(site.number),
              child: marker,
            ),
    );
  }
}

class _SiteGrid extends StatelessWidget {
  const _SiteGrid({
    required this.bookings,
    required this.sites,
    required this.onSiteTap,
  });

  final List<Booking> bookings;
  final List<CampSite> sites;
  final ValueChanged<int> onSiteTap;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 5,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: [
        for (final site in sites)
                _SiteTile(
            site: site,
            booking: _bookingFor(site.number),
            color: site.color,
            disabled: site.status == 'Belegt' ||
              site.status == 'Gesperrt' ||
              (_bookingFor(site.number) != null &&
                    _bookingOccupiesToday(_bookingFor(site.number)!)),
            onSiteTap: onSiteTap,
          ),
      ],
    );
  }

  Booking? _bookingFor(int siteNumber) {
    for (final booking in bookings) {
      if (booking.siteNumber == siteNumber) {
        return booking;
      }
    }
    return null;
  }
}

class _SiteTile extends StatelessWidget {
  const _SiteTile({
    required this.site,
    required this.booking,
    required this.color,
    required this.disabled,
    required this.onSiteTap,
  });

  final CampSite site;
  final Booking? booking;
  final Color color;
  final bool disabled;
  final ValueChanged<int> onSiteTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: disabled ? null : () => onSiteTap(site.number),
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        decoration: BoxDecoration(
          color: disabled ? const Color(0xffb8bec3) : color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _statusColor,
            width: 3,
          ),
        ),
        child: Center(
          child: Text(
            '${site.number}',
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  Color get _statusColor {
    if (booking != null) {
      return const Color(0xffd69b32);
    }
    if (site.status == 'Belegt') {
      return const Color(0xffc65b54);
    }
    if (site.status == 'Reserviert') {
      return const Color(0xffd69b32);
    }
    if (site.status == 'Gesperrt') {
      return const Color(0xff777f86);
    }
    return const Color(0xff32866d);
  }
}

class _Legend extends StatelessWidget {
  const _Legend(this.color, this.label);

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(radius: 5, backgroundColor: color),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}
