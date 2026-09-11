import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/camping_dates.dart';
import '../../models/booking.dart';
import '../../models/vehicle_type.dart';
import '../../shared/widgets/page_frame.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({required this.bookings, super.key});

  final List<Booking> bookings;

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

enum _StatisticsPeriod {
  day,
  month,
  year,
}

class _StatisticsPageState extends State<StatisticsPage> {
  _StatisticsPeriod period = _StatisticsPeriod.month;

  @override
  Widget build(BuildContext context) {
    final bookings = _filteredBookings;
    final guests = bookings.fold<int>(
      0,
      (sum, booking) => sum + booking.guests,
    );
    final nights = bookings.fold<int>(
      0,
      (sum, booking) => sum + _nightsFor(booking),
    );
    final occupiedSites = bookings.map((booking) => booking.siteNumber).toSet();
    final occupancy = occupiedSites.length / 26 * 100;

    return PageFrame(
      title: 'Statistik',
      subtitle: '${_periodLabel} · Auslastung und Gäste',
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 8,
              children: [
                SegmentedButton<_StatisticsPeriod>(
                  segments: const [
                    ButtonSegment(
                      value: _StatisticsPeriod.day,
                      label: Text('Tag'),
                    ),
                    ButtonSegment(
                      value: _StatisticsPeriod.month,
                      label: Text('Monat'),
                    ),
                    ButtonSegment(
                      value: _StatisticsPeriod.year,
                      label: Text('Jahr'),
                    ),
                  ],
                  selected: {period},
                  onSelectionChanged: (selection) {
                    setState(() => period = selection.first);
                  },
                ),
                OutlinedButton.icon(
                  onPressed: _copyCsv,
                  icon: const Icon(Icons.copy_outlined),
                  label: const Text('CSV kopieren'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Auslastung · $_periodLabel',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 150,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        for (final value in _chartValues)
                          Bar(value),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: StatValue('Gäste', '$guests')),
                      Expanded(child: StatValue('Übernachtungen', '$nights')),
                      Expanded(
                        child: StatValue(
                          'Ø Auslastung',
                          '${occupancy.toStringAsFixed(0)} %',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _StatisticsNote(
            bookings: bookings,
            occupiedSites: occupiedSites.length,
          ),
          const SizedBox(height: 16),
          _VehicleBreakdown(bookings: bookings),
        ],
      ),
    );
  }

  int _nightsFor(Booking booking) {
    final arrival = booking.arrivalDate;
    final departure = booking.departureDate;
    if (arrival == null || departure == null) {
      return 0;
    }
    return departure.difference(arrival).inDays;
  }

  String get _periodLabel {
    switch (period) {
      case _StatisticsPeriod.day:
        return CampingDates.formatDate(CampingDates.operationalDay);
      case _StatisticsPeriod.month:
        return CampingDates.monthName(CampingDates.operationalDay.month);
      case _StatisticsPeriod.year:
        return 'Jahr ${CampingDates.operationalDay.year}';
    }
  }

  List<Booking> get _filteredBookings {
    if (widget.bookings.isEmpty) {
      return widget.bookings;
    }

    final reference = CampingDates.operationalDay;
    return widget.bookings.where((booking) {
      final arrival = booking.arrivalDate;
      if (arrival == null) {
        return false;
      }

      switch (period) {
        case _StatisticsPeriod.day:
          return arrival.year == reference.year &&
              arrival.month == reference.month &&
              arrival.day == reference.day;
        case _StatisticsPeriod.month:
          return arrival.year == reference.year &&
              arrival.month == reference.month;
        case _StatisticsPeriod.year:
          return arrival.year == reference.year;
      }
    }).toList();
  }

  List<double> get _chartValues {
    final source = _filteredBookings;
    if (source.isEmpty) {
      final count = period == _StatisticsPeriod.year ? 12 : 7;
      return List<double>.filled(count, 24);
    }

    if (period == _StatisticsPeriod.year) {
      return [
        for (var month = 1; month <= 12; month++)
          _chartValueFor(
            source.where((booking) => booking.arrivalDate?.month == month),
          ),
      ];
    }

    return [
      for (var day = 1; day <= 7; day++)
        _chartValueFor(
          source.where((booking) => booking.arrivalDate?.day == day),
        ),
    ];
  }

  double _chartValueFor(Iterable<Booking> matchingBookings) {
    final count = matchingBookings.length;
    return (count * 28 + 24).clamp(24, 130).toDouble();
  }

  Future<void> _copyCsv() async {
    final counts = <VehicleType, int>{};
    for (final booking in _filteredBookings) {
      counts.update(
        booking.vehicleType,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }

    final lines = [
      'Kennzahl;Wert',
      'Zeitraum;$_periodLabel',
      'Gäste;${_filteredBookings.fold<int>(0, (sum, booking) => sum + booking.guests)}',
      'Übernachtungen;${_filteredBookings.fold<int>(0, (sum, booking) => sum + _nightsFor(booking))}',
      'Fahrzeugart;Anzahl',
      for (final type in VehicleType.values) '${type.label};${counts[type] ?? 0}',
    ];

    await Clipboard.setData(ClipboardData(text: lines.join('\n')));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('CSV-Daten kopiert.')),
    );
  }
}

class _StatisticsNote extends StatelessWidget {
  const _StatisticsNote({
    required this.bookings,
    required this.occupiedSites,
  });

  final List<Booking> bookings;
  final int occupiedSites;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.insights_outlined),
        title: Text('$occupiedSites von 26 Stellplätzen belegt'),
        subtitle: Text(
          bookings.isEmpty
              ? 'Noch keine eigenen Buchungen erfasst.'
              : 'Berechnung basiert auf den aktuellen Buchungen.',
        ),
      ),
    );
  }
}

class _VehicleBreakdown extends StatelessWidget {
  const _VehicleBreakdown({required this.bookings});

  final List<Booking> bookings;

  @override
  Widget build(BuildContext context) {
    final counts = <VehicleType, int>{};
    for (final booking in bookings) {
      counts.update(
        booking.vehicleType,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }

    if (counts.isEmpty) {
      for (final type in VehicleType.values) {
        counts[type] = 0;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fahrzeuge und Stellplatztypen',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            for (final type in VehicleType.values)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(_iconFor(type)),
                title: Text(type.label),
                trailing: Text(
                  '${counts[type] ?? 0}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(VehicleType type) {
    switch (type) {
      case VehicleType.motorhome:
        return Icons.rv_hookup_outlined;
      case VehicleType.carVan:
        return Icons.directions_car_outlined;
      case VehicleType.tent:
        return Icons.park_outlined;
      case VehicleType.carWithTrailer:
        return Icons.local_shipping_outlined;
      case VehicleType.other:
        return Icons.more_horiz;
    }
  }
}

class Bar extends StatelessWidget {
  const Bar(this.height, {super.key});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xff5fa994),
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}

class StatValue extends StatelessWidget {
  const StatValue(this.label, this.value, {super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xff61716d))),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}
