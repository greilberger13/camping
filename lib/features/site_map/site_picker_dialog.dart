import 'package:flutter/material.dart';

import '../../models/booking.dart';
import '../../models/camp_site.dart';
import '../../models/site_plan_anchor.dart';
import '../../models/vehicle_type.dart';
import '../../services/booking_availability.dart';

class SiteSelection {
  const SiteSelection(this.siteNumber, this.arrival, this.departure);

  final int siteNumber;
  final DateTime arrival;
  final DateTime departure;
}

class SitePickerDialog extends StatefulWidget {
  const SitePickerDialog({
    required this.sites,
    required this.bookings,
    required this.vehicleType,
    required this.arrival,
    required this.departure,
    this.bookingId,
    this.initialSiteNumber,
    super.key,
  });

  final List<CampSite> sites;
  final List<Booking> bookings;
  final VehicleType vehicleType;
  final DateTime arrival;
  final DateTime departure;
  final String? bookingId;
  final int? initialSiteNumber;

  @override
  State<SitePickerDialog> createState() => _SitePickerDialogState();
}

class _SitePickerDialogState extends State<SitePickerDialog> {
  static const availability = BookingAvailability();
  late DateTime arrival = widget.arrival;
  late DateTime departure = widget.departure;
  late int? selected = widget.initialSiteNumber;

  @override
  void initState() {
    super.initState();
    final matches = widget.sites.where((site) => site.number == selected);
    if (matches.isEmpty || !_available(matches.first)) selected = null;
  }

  String _display(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.'
      '${date.month.toString().padLeft(2, '0')}.${date.year}';

  Booking _draft(int siteNumber) => Booking(
        id: widget.bookingId,
        guestName: '',
        arrival: _display(arrival),
        departure: _display(departure),
        adults: 1,
        hasDog: false,
        siteNumber: siteNumber,
        vehicleType: widget.vehicleType,
      );

  bool _available(CampSite site) =>
      availability.isAvailable(_draft(site.number), site, widget.bookings);

  Future<void> _changeDate(bool isArrival) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isArrival ? arrival : departure,
      firstDate: DateTime(2025),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    setState(() {
      if (isArrival) {
        arrival = date;
      } else {
        departure = date;
      }
      final matches = widget.sites.where((site) => site.number == selected);
      if (matches.isEmpty || !_available(matches.first)) selected = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final validDates = !departure.isBefore(arrival);
    final chosen = widget.sites.where((site) => site.number == selected);
    final warning = chosen.isNotEmpty &&
        availability.hasLateCheckoutWarning(
          _draft(chosen.first.number),
          widget.bookings,
        );
    return AlertDialog(
      title: const Text('Stellplatz wählen'),
      content: SizedBox(
        width: 640,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      key: ValueKey(('arrival', arrival)),
                      initialValue: _display(arrival),
                      readOnly: true,
                      onTap: () => _changeDate(true),
                      decoration: const InputDecoration(
                        labelText: 'Anreise',
                        suffixIcon: Icon(Icons.event_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      key: ValueKey(('departure', departure)),
                      initialValue: _display(departure),
                      readOnly: true,
                      onTap: () => _changeDate(false),
                      decoration: InputDecoration(
                        labelText: 'Abreise',
                        suffixIcon: const Icon(Icons.event_outlined),
                        errorText: validDates
                            ? null
                            : 'Vor der Anreise.',
                      ),
                    ),
                  ),
                ],
              ),
              AspectRatio(
                aspectRatio: 1,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size = constraints.maxWidth;
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset('assets/Lageplan.jpg', fit: BoxFit.contain),
                        for (final site in widget.sites)
                          if (SitePlanAnchor.defaults.any(
                            (anchor) => anchor.siteNumber == site.number,
                          ))
                            _marker(site, size, validDates),
                      ],
                    );
                  },
                ),
              ),
              if (selected != null) Text('Stellplatz $selected'),
              if (selected == null && validDates)
                const Text('Bitte einen freien Stellplatz auswählen.'),
              if (warning)
                const Text(
                  'Achtung: Am Anreisetag ist auf diesem Platz '
                  'ein Late-Check-Out vorgemerkt.',
                  style: TextStyle(
                    color: Color(0xffa65312),
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
            onPressed: selected == null ||
              !validDates ||
              chosen.isEmpty ||
              !_available(chosen.first)
              ? null
              : () => Navigator.pop(
                    context,
                    SiteSelection(selected!, arrival, departure),
                  ),
          child: const Text('Übernehmen'),
        ),
      ],
    );
  }

  Widget _marker(CampSite site, double size, bool validDates) {
    final position = SitePlanAnchor.defaults.firstWhere(
      (anchor) => anchor.siteNumber == site.number,
    ).position;
    final available = validDates && _available(site);
    return Positioned(
      left: position.dx * size,
      top: position.dy * size,
      width: 45,
      height: 37,
      child: Tooltip(
        message: 'Platz ${site.number}: '
            '${available ? 'frei' : 'nicht verfügbar'}',
        child: InkWell(
          onTap: available ? () => setState(() => selected = site.number) : null,
          child: DecoratedBox(
            decoration: BoxDecoration(
                color: site.status == 'Gesperrt'
                  ? Colors.black
                  : available
                    ? site.color.withValues(alpha: 0.2)
                    : const Color(0xffb8bec3).withValues(alpha: 0.6),
              border: Border.all(
                color: site.number == selected
                    ? const Color(0xff1f6f68)
                  : site.status == 'Gesperrt'
                    ? Colors.black
                    : available
                        ? const Color(0xff32866d)
                        : const Color(0xff777f86),
                width: site.number == selected ? 3 : 2,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ),
    );
  }
}