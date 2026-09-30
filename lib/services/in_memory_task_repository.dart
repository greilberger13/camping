import '../models/order.dart';
import '../models/task.dart';
import 'task_repository.dart';

class InMemoryTaskRepository implements TaskRepository {
  InMemoryTaskRepository({List<CampingTask> initial = const []})
      : _tasks = [
          for (var index = 0; index < initial.length; index++)
            initial[index].id == null
                ? initial[index].copyWith(id: 'seed-task-$index')
                : initial[index],
        ];

  final List<CampingTask> _tasks;

  @override
  List<CampingTask> get tasks => List.unmodifiable(_tasks);

  @override
  Future<List<CampingTask>> load() async => tasks;

  @override
  Future<CampingTask> create(CampingTask task) async {
    final stored = task.id == null
        ? task.copyWith(id: DateTime.now().microsecondsSinceEpoch.toString())
        : task;
    _tasks.add(stored);
    return stored;
  }

  @override
  Future<CampingTask> update(CampingTask task) async {
    final index = _tasks.indexWhere((item) => item.id == task.id);
    if (index == -1) throw StateError('Task not found: ${task.title}');
    _tasks[index] = task;
    return task;
  }

  @override
  Future<List<CampingTask>> syncOrders(List<Order> orders) async {
    final grouped = <String, List<Order>>{};
    for (final order in orders) {
      if (order.status != OrderStatus.open) continue;
      final key = order.productId == null
          ? 'order:${order.category.name}:${order.description}'
          : 'order:${order.productId}';
      grouped.putIfAbsent(key, () => []).add(order);
    }
    _tasks.removeWhere((task) => task.isAutomatic);
    for (final entry in grouped.entries) {
      final first = entry.value.first;
      final quantity = entry.value.fold<int>(
        0,
        (total, order) => total + order.quantity,
      );
      _tasks.add(
        CampingTask(
          id: entry.key,
          taskKey: entry.key,
          title: first.description,
          quantity: '$quantity',
          category: first.category == OrderCategory.bakery
              ? TaskCategory.bakery
              : TaskCategory.kiosk,
        ),
      );
    }
    return tasks;
  }

  @override
  Future<void> complete(CampingTask task) async {
    _tasks.removeWhere((item) => item.id == task.id);
  }
}
