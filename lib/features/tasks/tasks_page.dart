import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../models/task.dart';
import '../../shared/widgets/page_frame.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({required this.orders, super.key});

  final List<Order> orders;

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  final tasks = <CampingTask>[
    const CampingTask(
      title: 'Brötchen besorgen',
      quantity: '7 Bestellungen',
      category: TaskCategory.bakery,
    ),
    const CampingTask(
      title: 'Getränke nachbestellen',
      quantity: '4 Artikel',
      category: TaskCategory.kiosk,
    ),
    const CampingTask(
      title: 'Müllsäcke einkaufen',
      quantity: 'Campingbedarf',
      category: TaskCategory.camping,
    ),
  ];

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
                for (var index = 0; index < tasks.length; index++)
                  _TaskTile(
                    task: tasks[index],
                    onChanged: (value) {
                      setState(() {
                        tasks[index] = tasks[index].copyWith(isDone: value);
                      });
                    },
                  ),
              ],
            ),
          ),
          if (widget.orders.isNotEmpty) ...[
            const SizedBox(height: 28),
            Text(
              'Bestellliste',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            _OrderSummary(orders: widget.orders),
          ],
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
      setState(() => tasks.add(task));
    }
  }
}

class _OrderSummary extends StatelessWidget {
  const _OrderSummary({required this.orders});

  final List<Order> orders;

  @override
  Widget build(BuildContext context) {
    final quantities = <String, int>{};
    final categories = <String, String>{};

    for (final order in orders.where(
      (order) => order.status == OrderStatus.open,
    )) {
      quantities.update(
        order.description,
        (quantity) => quantity + order.quantity,
        ifAbsent: () => order.quantity,
      );
      categories[order.description] = order.categoryLabel;
    }

    return Card(
      child: Column(
        children: [
          for (final entry in quantities.entries)
            ListTile(
              leading: const Icon(Icons.shopping_basket_outlined),
              title: Text(entry.key),
              subtitle: Text(categories[entry.key] ?? 'Bestellung'),
              trailing: Text(
                '${entry.value} ×',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Aufgabe'),
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
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: () {
            final title = titleController.text.trim();
            if (title.isEmpty) {
              return;
            }
            Navigator.pop(
              context,
              CampingTask(
                title: title,
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
