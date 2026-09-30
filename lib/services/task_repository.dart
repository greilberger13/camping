import '../models/order.dart';
import '../models/task.dart';

abstract interface class TaskRepository {
  List<CampingTask> get tasks;

  Future<List<CampingTask>> load();
  Future<CampingTask> create(CampingTask task);
  Future<CampingTask> update(CampingTask task);
  Future<List<CampingTask>> syncOrders(List<Order> orders);
  Future<void> complete(CampingTask task);
}
