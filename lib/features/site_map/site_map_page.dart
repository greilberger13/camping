import 'package:flutter/material.dart';

import '../../core/camping_dates.dart';
import '../../models/booking.dart';
import '../../models/camp_site.dart';
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
  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: 'Platzplan',
      subtitle: 'Tippe auf einen Stellplatz für Details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Wrap(
            spacing: 16,
            children: [
              _Legend(Color(0xff32866d), 'Frei'),
              _Legend(Color(0xffd69b32), 'Reserviert'),
              _Legend(Color(0xffc65b54), 'Belegt'),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _SitePlanImage(
                bookings: widget.bookings,
                sites: widget.sites,
                onSiteTap: widget.onSiteTap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SitePlanImage extends StatelessWidget {
  const _SitePlanImage({
    required this.bookings,
    required this.sites,
    required this.onSiteTap,
  });

  final List<Booking> bookings;
  final List<CampSite> sites;
  final ValueChanged<int> onSiteTap;

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
                  position: _positionFor(site.number),
                  imageSize: imageSize,
                  horizontalOffset: horizontalOffset,
                  verticalOffset: verticalOffset,
                  onSiteTap: onSiteTap,
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
    return site.status != 'Frei';
  }

  Offset _positionFor(int number) {
    if (number >= 18 && number <= 23) {
      return Offset(0.13 + (number - 18) * 0.085, 0.08 + (number - 18) * 0.075);
    }
    if (number >= 9 && number <= 16) {
      return Offset(0.34 + (number - 9) * 0.075, 0.62 + (number - 9) * 0.045);
    }
    if (number >= 1 && number <= 5) {
      return Offset(0.55 + (5 - number) * 0.075, 0.60 - (5 - number) * 0.045);
    }
    if (number == 6 || number == 7) {
      return Offset(0.78, 0.73 + (number - 6) * 0.08);
    }
    if (number == 8) {
      return const Offset(0.69, 0.85);
    }
    if (number == 17) {
      return const Offset(0.05, 0.45);
    }
    if (number >= 24 && number <= 26) {
      return Offset(0.48 + (number - 24) * 0.08, 0.30 + (number - 24) * 0.08);
    }
    return const Offset(0.5, 0.5);
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
    required this.onSiteTap,
  });

  final CampSite site;
  final Booking? booking;
  final Color color;
  final bool disabled;
  final Offset position;
  final double imageSize;
  final double horizontalOffset;
  final double verticalOffset;
  final ValueChanged<int> onSiteTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = booking != null
        ? const Color(0xffd69b32)
        : site.status == 'Belegt'
            ? const Color(0xffc65b54)
            : site.status == 'Reserviert'
                ? const Color(0xffd69b32)
                : const Color(0xff32866d);

    return Positioned(
      left: horizontalOffset + position.dx * imageSize,
      top: verticalOffset + position.dy * imageSize,
      width: 42,
      height: 34,
      child: InkWell(
        onTap: disabled ? null : () => onSiteTap(site.number),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: disabled
                ? const Color(0xffb8bec3).withValues(alpha: 0.6)
                : color.withValues(alpha: 0.22),
            border: Border.all(
              color: disabled ? const Color(0xff777f86) : statusColor,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              '${site.number}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
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
            disabled: site.status != 'Frei' ||
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
