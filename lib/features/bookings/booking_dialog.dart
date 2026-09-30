import 'package:flutter/material.dart';

import '../../core/camping_dates.dart';
import '../../models/booking.dart';
import '../../models/camp_site.dart';
import '../../models/vehicle_type.dart';
import '../../services/booking_availability.dart';
import '../site_map/site_picker_dialog.dart';
import 'birth_date_dialog.dart';

String _formatInitialDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
}

class BookingDialog extends StatefulWidget {
  const BookingDialog({
    required this.existingBookings,
    required this.sites,
    this.initialBooking,
    this.initialSiteNumber,
    super.key,
  });

  final List<Booking> existingBookings;
  final List<CampSite> sites;
  final Booking? initialBooking;
  final int? initialSiteNumber;

  @override
  State<BookingDialog> createState() => _BookingDialogState();
}

class _BookingDialogState extends State<BookingDialog> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final addressController = TextEditingController();
  final birthDateController = TextEditingController();
  final phoneController = TextEditingController();
  final arrivalController = TextEditingController(
    text: _formatInitialDate(CampingDates.defaultArrival),
  );
  final departureController = TextEditingController(
    text: _formatInitialDate(CampingDates.defaultDeparture),
  );
  bool dog = false;
  bool electricity = false;
  bool lateCheckout = false;
  int adults = 2;
  int children = 0;
  int? siteNumber;
  VehicleType vehicleType = VehicleType.motorhome;
  static const availability = BookingAvailability();

  @override
  void initState() {
    super.initState();
    final booking = widget.initialBooking;
    if (booking != null) {
      nameController.text = booking.guestName;
      addressController.text = booking.address ?? '';
      birthDateController.text = booking.birthDate ?? '';
      phoneController.text = booking.phone ?? '';
      arrivalController.text = booking.arrival;
      departureController.text = booking.departure;
      adults = booking.adults;
      children = booking.children;
      dog = booking.hasDog;
      electricity = booking.hasElectricity;
      lateCheckout = booking.lateCheckout;
      siteNumber = booking.siteNumber;
      vehicleType = booking.vehicleType;
    } else if (widget.initialSiteNumber != null) {
      siteNumber = widget.initialSiteNumber;
      final selectedSite = widget.sites.firstWhere(
        (site) => site.number == widget.initialSiteNumber,
        orElse: () => widget.sites.first,
      );
      vehicleType = _vehicleTypeFor(selectedSite);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    addressController.dispose();
    birthDateController.dispose();
    phoneController.dispose();
    arrivalController.dispose();
    departureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(
          widget.initialBooking == null
              ? 'Neue Buchung'
              : 'Buchung bearbeiten',
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.person_outline)),
                validator: (value) => value == null || value.trim().isEmpty ? 'Name eingeben' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Adresse (optional)',
                  prefixIcon: Icon(Icons.home_outlined),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: birthDateController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Geburtsdatum',
                        hintText: 'TT.MM.JJJJ',
                        suffixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      onTap: () => _pickBirthDate(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Telefon',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: arrivalController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Anreise',
                      suffixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    onTap: () => _pickStayDate(
                      controller: arrivalController,
                      initialDate: CampingDates.defaultArrival,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: departureController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Abreise',
                      suffixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    validator: (value) {
                      final departure = _parseDate(value);
                      final arrival = _parseDate(arrivalController.text);
                      if (departure == null || arrival == null) {
                        return 'Datum auswählen';
                      }
                      if (departure.isBefore(arrival)) {
                        return 'Vor der Anreise';
                      }
                      return null;
                    },
                    onTap: () => _pickStayDate(
                      controller: departureController,
                      initialDate: CampingDates.defaultDeparture,
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              _counter('Erwachsene', adults, 1, (value) {
                setState(() => adults = value);
              }),
              _counter('Kinder', children, 0, (value) {
                setState(() => children = value);
              }),
              DropdownButtonFormField<VehicleType>(
                initialValue: vehicleType,
                decoration: const InputDecoration(labelText: 'Fahrzeugart'),
                items: [
                  for (final value in VehicleType.values)
                    DropdownMenuItem(
                      value: value,
                      child: Text(value.label),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      vehicleType = value;
                      if (siteNumber != null &&
                          !_siteIsAvailable(siteNumber!)) {
                        siteNumber = null;
                      }
                    });
                  }
                },
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      key: ValueKey(siteNumber),
                      initialValue: siteNumber == null ? '' : 'Platz $siteNumber',
                      readOnly: true,
                      decoration: const InputDecoration(labelText: 'Stellplatz'),
                        validator: (_) => siteNumber == null
                          ? 'Stellplatz auswählen'
                          : !_siteIsAvailable(siteNumber!)
                            ? 'Stellplatz nicht verfügbar'
                            : null,
                    ),
                  ),
                  IconButton(
                    onPressed: _openSitePicker,
                    tooltip: 'Stellplatz im Platzplan auswählen',
                    icon: const Icon(Icons.map_outlined),
                  ),
                ],
              ),
              if (_lateCheckoutWarning)
                const Text('Achtung: Late-Check-Out am Anreisetag.'),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Hund'),
                value: dog,
                onChanged: (value) => setState(() => dog = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Strom'),
                value: electricity,
                onChanged: (value) => setState(() => electricity = value),
              ),
              if (widget.initialBooking != null)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Late-Check-Out'),
                  value: lateCheckout,
                  onChanged: (value) => setState(() => lateCheckout = value),
                ),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final booking = Booking(
                  guestName: nameController.text.trim(),
                  arrival: arrivalController.text.trim(),
                  departure: departureController.text.trim(),
                  adults: adults,
                  children: children,
                  hasDog: dog,
                  hasElectricity: electricity,
                  lateCheckout: lateCheckout,
                  siteNumber: siteNumber!,
                  vehicleType: vehicleType,
                  address: _optionalValue(addressController),
                  birthDate: _optionalValue(birthDateController),
                  phone: _optionalValue(phoneController),
                );
                Navigator.pop(context, booking);
              }
            },
            child: Text(
              widget.initialBooking == null
                  ? 'Buchung speichern'
                  : 'Änderungen speichern',
            ),
          ),
        ],
      );

  String? _optionalValue(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  Future<void> _pickBirthDate() async {
    final selectedDate = await showDialog<DateTime>(
      context: context,
      builder: (context) => const BirthDateDialog(),
    );

    if (selectedDate != null) {
      setState(() => birthDateController.text = _formatDate(selectedDate));
    }
  }

  Future<void> _pickStayDate({
    required TextEditingController controller,
    required DateTime initialDate,
  }) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _parseDate(controller.text) ?? initialDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2100),
      helpText: 'Datum auswählen',
    );

    if (selectedDate == null) {
      return;
    }

    setState(() {
      controller.text = _formatDate(selectedDate);
      if (siteNumber != null && !_siteIsAvailable(siteNumber!)) {
        siteNumber = null;
      }
    });
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }

  DateTime? _parseDate(String? value) {
    if (value == null) {
      return null;
    }

    final parts = value.split('.');
    if (parts.length != 3) {
      return null;
    }

    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) {
      return null;
    }

    final parsed = DateTime(year, month, day);
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      return null;
    }

    return parsed;
  }

  Widget _counter(
    String label,
    int value,
    int minimum,
    ValueChanged<int> onChanged,
  ) {
    return Row(
      children: [
        Text(label),
        const Spacer(),
        IconButton(
          onPressed: value > minimum ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Text('$value'),
        IconButton(
          onPressed: () => onChanged(value + 1),
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }

  Future<void> _openSitePicker() async {
    final arrival = _parseDate(arrivalController.text);
    final departure = _parseDate(departureController.text);
    if (arrival == null || departure == null || departure.isBefore(arrival)) {
      formKey.currentState?.validate();
      return;
    }
    final result = await showDialog<SiteSelection>(
      context: context,
      builder: (context) => SitePickerDialog(
        sites: widget.sites,
        bookings: widget.existingBookings,
        vehicleType: vehicleType,
        arrival: arrival,
        departure: departure,
        bookingId: widget.initialBooking?.id,
        initialSiteNumber: siteNumber,
      ),
    );
    if (result == null) return;
    setState(() {
      arrivalController.text = _formatDate(result.arrival);
      departureController.text = _formatDate(result.departure);
      siteNumber = result.siteNumber;
    });
  }

  bool get _lateCheckoutWarning => siteNumber != null &&
      availability.hasLateCheckoutWarning(
        _draft(siteNumber!),
        widget.existingBookings,
      );

  VehicleType _vehicleTypeFor(CampSite site) {
    switch (site.type) {
      case 'Auto / Van':
        return VehicleType.carVan;
      case 'Zelt':
        return VehicleType.tent;
      case 'Auto mit Anhänger':
        return VehicleType.carWithTrailer;
      default:
        return VehicleType.motorhome;
    }
  }

  Booking _draft(int number) {
    return Booking(
      id: widget.initialBooking?.id,
      guestName: '',
      arrival: arrivalController.text,
      departure: departureController.text,
      adults: adults,
      children: children,
      hasDog: dog,
      siteNumber: number,
      vehicleType: vehicleType,
    );
  }

  bool _siteIsAvailable(int number) {
    final sites = widget.sites.where((site) => site.number == number);
    return sites.isNotEmpty && availability.isAvailable(
      _draft(number),
      sites.first,
      [
        ...widget.existingBookings,
        if (widget.initialBooking != null) widget.initialBooking!,
      ],
      allowExistingBlocked: true,
    );
  }
}
