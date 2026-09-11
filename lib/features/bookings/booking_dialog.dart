import 'package:flutter/material.dart';

import '../../core/camping_dates.dart';
import '../../models/booking.dart';
import '../../models/camp_site.dart';
import '../../models/vehicle_type.dart';
import 'birth_date_dialog.dart';

String _formatInitialDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
}

class BookingDialog extends StatefulWidget {
  const BookingDialog({
    required this.existingBookings,
    this.initialBooking,
    super.key,
  });

  final List<Booking> existingBookings;
  final Booking? initialBooking;

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
  int guests = 2;
  int? siteNumber;
  VehicleType vehicleType = VehicleType.motorhome;

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
      guests = booking.guests;
      dog = booking.hasDog;
      siteNumber = booking.siteNumber;
      vehicleType = booking.vehicleType;
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
              Row(children: [
                const Text('Personen'),
                const Spacer(),
                IconButton(onPressed: () => setState(() => guests = guests > 1 ? guests - 1 : 1), icon: const Icon(Icons.remove_circle_outline)),
                Text('$guests'),
                IconButton(onPressed: () => setState(() => guests++), icon: const Icon(Icons.add_circle_outline)),
              ]),
              DropdownButtonFormField<int>(
                initialValue: siteNumber,
                decoration: const InputDecoration(labelText: 'Stellplatz'),
                items: [
                  for (final site in _availableSites)
                    DropdownMenuItem(
                      value: site.number,
                      child: Text('${site.number} · ${site.type}'),
                    ),
                ],
                onChanged: (value) => setState(() => siteNumber = value),
                validator: (value) => value == null ? 'Stellplatz auswählen' : null,
              ),
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
                    setState(() => vehicleType = value);
                  }
                },
              ),
              SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Hund'), value: dog, onChanged: (value) => setState(() => dog = value)),
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
                  guests: guests,
                  hasDog: dog,
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
      initialDate: initialDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2035),
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

  List<CampSite> get _availableSites {
    return CampSite.samples
        .where(
          (site) => site.status == 'Frei' && _siteIsAvailable(site.number),
        )
        .toList();
  }

  bool _siteIsAvailable(int number) {
    final arrival = _parseDate(arrivalController.text);
    final departure = _parseDate(departureController.text);
    if (arrival == null || departure == null) {
      return false;
    }

    final draft = Booking(
      guestName: '',
      arrival: arrivalController.text,
      departure: departureController.text,
      guests: guests,
      hasDog: dog,
      siteNumber: number,
    );

    return widget.existingBookings.every(
      (booking) => !draft.conflictsWith(booking),
    );
  }
}
