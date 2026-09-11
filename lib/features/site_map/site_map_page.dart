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
              child: _SiteGrid(
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
