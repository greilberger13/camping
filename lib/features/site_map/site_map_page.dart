import 'package:flutter/material.dart';

import '../../models/booking.dart';
import '../../models/camp_site.dart';
import '../../shared/widgets/page_frame.dart';

class SiteMapPage extends StatefulWidget {
  const SiteMapPage({required this.bookings, super.key});

  final List<Booking> bookings;

  @override
  State<SiteMapPage> createState() => _SiteMapPageState();
}

class _SiteMapPageState extends State<SiteMapPage> {
  final siteColors = <int, Color>{};

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
                siteColors: siteColors,
                onColorChanged: (siteNumber, color) {
                  setState(() => siteColors[siteNumber] = color);
                },
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
    required this.siteColors,
    required this.onColorChanged,
  });

  final List<Booking> bookings;
  final Map<int, Color> siteColors;
  final void Function(int siteNumber, Color color) onColorChanged;

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
                    siteColors: siteColors,
                    onColorChanged: onColorChanged,
                  );
                },
              ),
              for (final site in CampSite.samples)
                _ImageSiteOverlay(
                  site: site,
                  booking: _bookingFor(site.number),
                  color: siteColors[site.number] ?? site.color,
                  position: _positionFor(site.number),
                  imageSize: imageSize,
                  horizontalOffset: horizontalOffset,
                  verticalOffset: verticalOffset,
                  onColorChanged: onColorChanged,
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
    required this.position,
    required this.imageSize,
    required this.horizontalOffset,
    required this.verticalOffset,
    required this.onColorChanged,
  });

  final CampSite site;
  final Booking? booking;
  final Color color;
  final Offset position;
  final double imageSize;
  final double horizontalOffset;
  final double verticalOffset;
  final void Function(int siteNumber, Color color) onColorChanged;

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
        onTap: () => showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (context) => _SiteDetails(
            site: site,
            booking: booking,
            color: color,
            onColorChanged: onColorChanged,
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.22),
            border: Border.all(color: statusColor, width: 2),
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
    required this.siteColors,
    required this.onColorChanged,
  });

  final List<Booking> bookings;
  final Map<int, Color> siteColors;
  final void Function(int siteNumber, Color color) onColorChanged;

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
        for (final site in CampSite.samples)
          _SiteTile(
            site: site,
            booking: _bookingFor(site.number),
            color: siteColors[site.number] ?? site.color,
            onColorChanged: onColorChanged,
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
    required this.onColorChanged,
  });

  final CampSite site;
  final Booking? booking;
  final Color color;
  final void Function(int siteNumber, Color color) onColorChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (context) => _SiteDetails(
          site: site,
          booking: booking,
          color: color,
          onColorChanged: onColorChanged,
        ),
      ),
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        decoration: BoxDecoration(
          color: color,
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

class _SiteDetails extends StatelessWidget {
  const _SiteDetails({
    required this.site,
    required this.booking,
    required this.color,
    required this.onColorChanged,
  });

  final CampSite site;
  final Booking? booking;
  final Color color;
  final void Function(int siteNumber, Color color) onColorChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stellplatz ${site.number}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          Text(
            site.type,
            style: const TextStyle(color: Color(0xff61716d)),
          ),
          const SizedBox(height: 16),
          Text(
            booking == null
                ? site.status
                : '${booking!.guestName} · ${booking!.arrival} – ${booking!.departure}',
          ),
          if (booking != null)
            Text(
              '${booking!.guests} Personen${booking!.hasDog ? ' · Hund' : ''}',
            ),
          const SizedBox(height: 18),
          const Text(
            'Farbe des Stellplatzes',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: [
              for (final option in _siteColorOptions)
                InkWell(
                  onTap: () {
                    onColorChanged(site.number, option);
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: option,
                    child: option == color
                        ? const Icon(Icons.check, color: Colors.black54)
                        : null,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static const _siteColorOptions = [
    Color(0xffa9ed21),
    Color(0xff22d9ed),
    Color(0xffffbd21),
    Color(0xffff6ba8),
    Color(0xffd7dce2),
  ];
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
