import '../core/supabase_database.dart';
import '../models/task.dart';
import 'task_repository.dart';

class SupabaseTaskRepository implements TaskRepository {
  SupabaseTaskRepository(this.database);

  final SupabaseDatabase database;
  final cache = <CampingTask>[];

  @override
  List<CampingTask> get tasks => List.unmodifiable(cache);

  @override
  Future<List<CampingTask>> load() async {
    final rows = await database.client
        .from('tasks')
        .select()
        .order('created_at');
    cache
      ..clear()
      ..addAll(rows.map(_fromRow));
    return tasks;
  }

  @override
  Future<CampingTask> create(CampingTask task) async {
    final row = await database.client
        .from('tasks')
        .insert(_toRow(task))
        .select()
        .single();
    final stored = _fromRow(row);
    cache.add(stored);
    return stored;
  }

  @override
  Future<CampingTask> update(CampingTask task) async {
    if (task.id == null) throw StateError('Task has no id.');
    final row = await database.client
        .from('tasks')
        .update({
          'title': task.title,
          'quantity_text': task.quantity,
          'category': _categoryValue(task.category),
          'status': task.isDone ? 'completed' : 'open',
        })
        .eq('id', task.id!)
        .select()
        .single();
    final updated = _fromRow(row);
    final index = cache.indexWhere((item) => item.id == task.id);
    if (index != -1) cache[index] = updated;
    return updated;
  }

  Map<String, dynamic> _toRow(CampingTask task) {
    return {
      'task_key': task.id ?? '${task.category.name}:${task.title}',
      'title': task.title,
      'quantity_text': task.quantity,
      'category': _categoryValue(task.category),
      'status': task.isDone ? 'completed' : 'open',
    };
  }

  CampingTask _fromRow(Map<String, dynamic> row) {
    return CampingTask(
      id: row['id'] as String?,
      title: row['title'] as String,
      quantity: row['quantity_text'] as String? ?? '',
      category: _categoryFromValue(row['category'] as String),
      isDone: row['status'] == 'completed',
    );
  }

  String _categoryValue(TaskCategory category) {
    switch (category) {
      case TaskCategory.bakery:
        return 'bakery';
      case TaskCategory.kiosk:
        return 'kiosk';
      case TaskCategory.camping:
        return 'camping';
    }
  }

  TaskCategory _categoryFromValue(String value) {
    switch (value) {
      case 'bakery':
        return TaskCategory.bakery;
      case 'kiosk':
        return TaskCategory.kiosk;
      default:
        return TaskCategory.camping;
    }
  }
}
