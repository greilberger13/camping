import 'package:flutter/material.dart';

class BirthDateDialog extends StatefulWidget {
  const BirthDateDialog({super.key});

  @override
  State<BirthDateDialog> createState() => _BirthDateDialogState();
}

class _BirthDateDialogState extends State<BirthDateDialog> {
  final formKey = GlobalKey<FormState>();
  int? day;
  int? month;
  final yearController = TextEditingController();

  @override
  void dispose() {
    yearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Geburtsdatum'),
      content: SingleChildScrollView(
        child: Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: day,
                    decoration: const InputDecoration(labelText: 'Tag'),
                    validator: (value) => value == null
                        ? 'Tag auswählen.'
                        : null,
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
                    validator: (value) => value == null
                        ? 'Monat auswählen.'
                        : null,
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
            TextFormField(
              controller: yearController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Jahr',
                hintText: 'z. B. 1960',
              ),
              validator: (input) {
                final text = (input ?? '').trim();
                final year = int.tryParse(text);
                if (year == null || text.length != 4 ||
                    year < 1900 || year > DateTime.now().year) {
                  return 'Vierstelliges Jahr ab 1900 eingeben.';
                }
                if (day != null && month != null) {
                  final date = DateTime(year, month!, day!);
                  if (date.year != year ||
                      date.month != month || date.day != day) {
                    return 'Dieses Datum gibt es nicht.';
                  }
                }
                return null;
              },
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
          onPressed: _save,
          child: const Text('Übernehmen'),
        ),
      ],
    );
  }

  void _save() {
    if (!formKey.currentState!.validate()) return;
    final date = DateTime(int.parse(yearController.text.trim()), month!, day!);
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
