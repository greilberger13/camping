import 'package:flutter/material.dart';

import '../../models/stay_note.dart';

class StayNoteDialog extends StatefulWidget {
  const StayNoteDialog({required this.siteNumbers, super.key});

  final List<int> siteNumbers;

  @override
  State<StayNoteDialog> createState() => _StayNoteDialogState();
}

class _StayNoteDialogState extends State<StayNoteDialog> {
  final formKey = GlobalKey<FormState>();
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
        child: Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
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
              validator: (value) => value == null
                  ? 'Bitte einen Stellplatz auswählen.'
                  : null,
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
            TextFormField(
              controller: textController,
              autofocus: true,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notiz',
                hintText: 'z. B. 5 Semmeln bestellt',
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Bitte eine Notiz eingeben.'
                  : null,
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
          child: const Text('Speichern'),
        ),
      ],
    );
  }

  void _save() {
    if (!formKey.currentState!.validate()) return;
    final text = textController.text.trim();

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
