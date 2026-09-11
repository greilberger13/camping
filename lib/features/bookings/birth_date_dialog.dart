import 'package:flutter/material.dart';

class BirthDateDialog extends StatefulWidget {
  const BirthDateDialog({super.key});

  @override
  State<BirthDateDialog> createState() => _BirthDateDialogState();
}

class _BirthDateDialogState extends State<BirthDateDialog> {
  int? day;
  int? month;
  final yearController = TextEditingController();
  String? errorMessage;

  @override
  void dispose() {
    yearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Geburtsdatum'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: day,
                  decoration: const InputDecoration(labelText: 'Tag'),
                  items: [
                    for (var value = 1; value <= 31; value++)
                      DropdownMenuItem(value: value, child: Text('$value')),
                  ],
                  onChanged: (value) => setState(() => day = value),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<int>(
                  initialValue: month,
                  decoration: const InputDecoration(labelText: 'Monat'),
                  items: [
                    for (var value = 1; value <= 12; value++)
                      DropdownMenuItem(
                        value: value,
                        child: Text(_monthName(value)),
                      ),
                  ],
                  onChanged: (value) => setState(() => month = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: yearController,
            keyboardType: TextInputType.number,
            onChanged: (_) {
              if (errorMessage != null) {
                setState(() => errorMessage = null);
              }
            },
            decoration: const InputDecoration(
              labelText: 'Jahr',
              hintText: 'z. B. 1960',
            ),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                errorMessage!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Übernehmen'),
        ),
      ],
    );
  }

  void _save() {
    final yearText = yearController.text.trim();
    final year = int.tryParse(yearText);
    if (day == null || month == null || year == null) {
      setState(() => errorMessage = 'Tag, Monat und Jahr auswählen.');
      return;
    }

    if (yearText.length != 4 || year < 1900 || year > 2026) {
      setState(
        () => errorMessage =
            'Das Jahr muss vierstellig und zwischen 1900 und 2026 liegen.',
      );
      return;
    }

    final date = DateTime(year, month!, day!);
    if (date.year != year || date.month != month || date.day != day) {
      setState(() => errorMessage = 'Dieses Datum gibt es nicht.');
      return;
    }

    Navigator.pop(context, date);
  }

  String _monthName(int value) {
    const names = [
      'Jänner',
      'Februar',
      'März',
      'April',
      'Mai',
      'Juni',
      'Juli',
      'August',
      'September',
      'Oktober',
      'November',
      'Dezember',
    ];
    return names[value - 1];
  }
}
