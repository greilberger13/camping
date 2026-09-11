import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../models/task.dart';
import '../../shared/widgets/page_frame.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({
    required this.orders,
    required this.tasks,
    required this.onTaskAdded,
    required this.onTaskUpdated,
    required this.onOrderUpdated,
    super.key,
  });

  final List<Order> orders;
  final List<CampingTask> tasks;
  final ValueChanged<CampingTask> onTaskAdded;
  final ValueChanged<CampingTask> onTaskUpdated;
  final ValueChanged<Order> onOrderUpdated;

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
                      widget.onTaskUpdated(
                        widget.tasks[index].copyWith(isDone: value),
                      );
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
            _OrderSummary(
              orders: widget.orders,
              onOrderUpdated: widget.onOrderUpdated,
            ),
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
      widget.onTaskAdded(task);
    }
  }
}

class _OrderSummary extends StatelessWidget {
  const _OrderSummary({
    required this.orders,
    required this.onOrderUpdated,
  });

  final List<Order> orders;
  final ValueChanged<Order> onOrderUpdated;

  @override
  Widget build(BuildContext context) {
    final groupedOrders = <String, List<Order>>{};

    for (final order in orders.where(
      (order) => order.status == OrderStatus.open,
    )) {
      groupedOrders.putIfAbsent(order.description, () => []).add(order);
    }

    return Card(
      child: Column(
        children: [
          for (final entry in groupedOrders.entries)
            _OrderTaskTile(
              description: entry.key,
              orders: entry.value,
              onComplete: () {
                for (final order in entry.value) {
                  onOrderUpdated(order.copyWith(status: OrderStatus.completed));
                }
              },
            ),
          if (groupedOrders.isEmpty)
            const ListTile(
              leading: Icon(Icons.check_circle_outline),
              title: Text('Keine offenen Bestellungen'),
            ),
        ],
      ),
    );
  }
}

class _OrderTaskTile extends StatelessWidget {
  const _OrderTaskTile({
    required this.description,
    required this.orders,
    required this.onComplete,
  });

  final String description;
  final List<Order> orders;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final quantity = orders.fold<int>(
      0,
      (sum, order) => sum + order.quantity,
    );
    final category = orders.first.categoryLabel;

    return CheckboxListTile(
      value: false,
      onChanged: (_) => onComplete(),
      secondary: const Icon(Icons.shopping_basket_outlined),
      title: Text(description),
      subtitle: Text('$quantity × · $category'),
      controlAffinity: ListTileControlAffinity.trailing,
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
