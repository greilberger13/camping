import 'package:flutter/material.dart';

import '../../core/camping_dates.dart';
import '../../models/booking.dart';
import '../../shared/widgets/page_frame.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    required this.onMapTap,
    required this.onBookingTap,
    required this.onStayTap,
    required this.onCheckoutTap,
    required this.bookings,
    super.key,
  });

  final VoidCallback onMapTap;
  final VoidCallback onBookingTap;
  final VoidCallback onStayTap;
  final VoidCallback onCheckoutTap;
  final List<Booking> bookings;

  @override
  Widget build(BuildContext context) {
    final metrics = _DashboardMetrics(bookings);

    return PageFrame(
      title: 'Guten Morgen',
      subtitle: CampingDates.formatDate(CampingDates.operationalDay),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _Metric(
                'Ankünfte heute',
                '${metrics.arrivals}',
                '${metrics.arrivals} geplant',
                Icons.login,
                Color(0xff32866d),
              ),
              _Metric(
                'Abreisen heute',
                '${metrics.departures}',
                '${metrics.departures} geplant',
                Icons.logout,
                Color(0xffc47737),
              ),
              _Metric(
                'Auslastung',
                '${metrics.occupancy} %',
                '${metrics.occupiedSites} von 26 Plätzen',
                Icons.pie_chart_outline,
                Color(0xff4269a4),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'Schnellzugriff',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _Action('Platzplan öffnen', Icons.map_outlined, onMapTap),
              _Action(
                'Buchung anlegen',
                Icons.add_circle_outline,
                onBookingTap,
              ),
              _Action(
                'Aufenthalt öffnen',
                Icons.room_service_outlined,
                onStayTap,
              ),
              _Action(
                'Abreisen prüfen',
                Icons.receipt_long_outlined,
                onCheckoutTap,
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'Heute im Überblick',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          const _Info(
            'Anlieferung Getränke',
            'Heute · 10:30 Uhr · Zufahrt freihalten',
            Icons.local_shipping_outlined,
          ),
          const _Info(
            'Brötchenliste',
            '7 Bestellungen für morgen früh',
            Icons.bakery_dining_outlined,
          ),
        ],
      ),
    );
  }
}

class _DashboardMetrics {
  _DashboardMetrics(this.bookings);

  final List<Booking> bookings;

  static final today = CampingDates.operationalDay;

  int get arrivals {
    if (bookings.isEmpty) {
      return 4;
    }
    return bookings.where((booking) => booking.arrivalDate == today).length;
  }

  int get departures {
    if (bookings.isEmpty) {
      return 3;
    }
    return bookings.where((booking) => booking.departureDate == today).length;
  }

  int get occupiedSites {
    if (bookings.isEmpty) {
      return 18;
    }
    return bookings.map((booking) => booking.siteNumber).toSet().length;
  }

  int get occupancy {
    return (occupiedSites / 26 * 100).round();
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value, this.detail, this.icon, this.color);

  final String label;
  final String value;
  final String detail;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: Color(0xff61716d)),
                  ),
                  Icon(icon, color: color),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                detail,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action(this.label, this.icon, [this.onTap]);

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info(this.title, this.detail, this.icon);

  final String title;
  final String detail;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xffd9ebe5),
          child: Icon(icon, color: const Color(0xff1f6f68)),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(detail),
      ),
    );
  }
}
