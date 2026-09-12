import '../models/order.dart';
import '../models/order_batch.dart';
import '../models/order_product.dart';

abstract interface class OrderRepository {
  List<OrderProduct> get products;
  List<Order> get orders;

  Future<List<OrderProduct>> loadProducts();
  Future<List<Order>> loadOrders();
  Future<OrderProduct> createProduct(OrderProduct product);
  Future<OrderProduct> updateProduct(OrderProduct product);
  Future<void> deleteProduct(String productId);
  Future<Order> createOrder(Order order);
  Future<List<Order>> createOrderBatch(OrderBatch batch);
  Future<Order> updateOrder(Order order);
}
