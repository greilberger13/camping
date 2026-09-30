import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../shared/widgets/page_frame.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({
    required this.tasks,
    required this.onTaskAdded,
    required this.onTaskCompleted,
    super.key,
  });

  final List<CampingTask> tasks;
  final ValueChanged<CampingTask> onTaskAdded;
  final ValueChanged<CampingTask> onTaskCompleted;

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: 'Aufgaben',
      subtitle: 'Bestellungen und Einkauf für den heutigen Betrieb',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _addTask,
              icon: const Icon(Icons.add),
              label: const Text('Aufgabe'),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                for (var index = 0; index < widget.tasks.length; index++)
                  _TaskTile(
                    task: widget.tasks[index],
                    onChanged: (value) {
                      if (value) {
                        widget.onTaskCompleted(widget.tasks[index]);
                      }
                    },
                  ),
                if (widget.tasks.isEmpty)
                  const ListTile(title: Text('Keine offenen Aufgaben')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addTask() async {
    final task = await showDialog<CampingTask>(
      context: context,
      builder: (context) => const _TaskDialog(),
    );

    if (task != null) {
      widget.onTaskAdded(task);
    }
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task, required this.onChanged});

  final CampingTask task;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: task.isDone,
      onChanged: (value) => onChanged(value ?? false),
      secondary: Icon(_categoryIcon),
      title: Text(
        task.title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          decoration: task.isDone ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Text('${task.quantity} · ${task.categoryLabel}'),
    );
  }

  IconData get _categoryIcon {
    switch (task.category) {
      case TaskCategory.bakery:
        return Icons.bakery_dining_outlined;
      case TaskCategory.kiosk:
        return Icons.local_drink_outlined;
      case TaskCategory.camping:
        return Icons.shopping_cart_outlined;
    }
  }
}

class _TaskDialog extends StatefulWidget {
  const _TaskDialog();

  @override
  State<_TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<_TaskDialog> {
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final quantityController = TextEditingController();
  TaskCategory category = TaskCategory.camping;

  @override
  void dispose() {
    titleController.dispose();
    quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Neue Aufgabe'),
      content: SingleChildScrollView(
        child: Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            TextFormField(
              controller: titleController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Aufgabe'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Bitte eine Aufgabe eingeben.'
                  : null,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: quantityController,
              decoration: const InputDecoration(
                labelText: 'Menge oder Zusatzinfo',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<TaskCategory>(
              initialValue: category,
              decoration: const InputDecoration(labelText: 'Kategorie'),
              items: [
                for (final value in TaskCategory.values)
                  DropdownMenuItem(
                    value: value,
                    child: Text(_labelFor(value)),
                  ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => category = value);
                }
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
          onPressed: () {
            if (!formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              CampingTask(
                title: titleController.text.trim(),
                quantity: quantityController.text.trim(),
                category: category,
              ),
            );
          },
          child: const Text('Speichern'),
        ),
      ],
    );
  }

  String _labelFor(TaskCategory value) {
    switch (value) {
      case TaskCategory.bakery:
        return 'Brötchenservice';
      case TaskCategory.kiosk:
        return 'Kiosk';
      case TaskCategory.camping:
        return 'Camping';
    }
  }
}
