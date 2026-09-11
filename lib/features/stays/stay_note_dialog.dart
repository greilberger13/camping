import 'package:flutter/material.dart';

import '../../models/stay_note.dart';

class StayNoteDialog extends StatefulWidget {
  const StayNoteDialog({required this.siteNumbers, super.key});

  final List<int> siteNumbers;

  @override
  State<StayNoteDialog> createState() => _StayNoteDialogState();
}

class _StayNoteDialogState extends State<StayNoteDialog> {
  final textController = TextEditingController();
  StayNoteCategory category = StayNoteCategory.general;
  int? siteNumber;

  @override
  void initState() {
    super.initState();
    siteNumber = widget.siteNumbers.isEmpty ? null : widget.siteNumbers.first;
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Neue Notiz'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<StayNoteCategory>(
              initialValue: category,
              decoration: const InputDecoration(labelText: 'Rubrik'),
              items: [
                for (final value in StayNoteCategory.values)
                  DropdownMenuItem(
                    value: value,
                    child: Text(_categoryLabel(value)),
                  ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => category = value);
                }
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: siteNumber,
              decoration: const InputDecoration(labelText: 'Stellplatz'),
              items: [
                for (final number in widget.siteNumbers)
                  DropdownMenuItem(
                    value: number,
                    child: Text('Stellplatz $number'),
                  ),
              ],
              onChanged: (value) => setState(() => siteNumber = value),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              autofocus: true,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notiz',
                hintText: 'z. B. 5 Semmeln bestellt',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Speichern'),
        ),
      ],
    );
  }

  void _save() {
    final text = textController.text.trim();
    if (text.isEmpty || siteNumber == null) {
      return;
    }

    Navigator.pop(
      context,
      StayNote(
        siteNumber: siteNumber!,
        text: text,
        category: category,
      ),
    );
  }

  String _categoryLabel(StayNoteCategory value) {
    switch (value) {
      case StayNoteCategory.bakery:
        return 'Brötchenservice';
      case StayNoteCategory.foodAndDrinks:
        return 'Essen & Getränke';
      case StayNoteCategory.general:
        return 'Allgemein';
    }
  }
}
