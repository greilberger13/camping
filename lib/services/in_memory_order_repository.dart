import '../models/order.dart';
import '../models/order_batch.dart';
import '../models/order_product.dart';
import 'order_repository.dart';

class InMemoryOrderRepository implements OrderRepository {
  InMemoryOrderRepository({
    List<OrderProduct> initialProducts = const [],
    List<Order> initialOrders = const [],
  })  : _products = List<OrderProduct>.of(initialProducts),
        _orders = [
          for (var index = 0; index < initialOrders.length; index++)
            initialOrders[index].id == null
                ? initialOrders[index].copyWith(id: 'seed-order-$index')
                : initialOrders[index],
        ];

  final List<OrderProduct> _products;
  final List<Order> _orders;

  @override
  List<OrderProduct> get products => List.unmodifiable(_products);

  @override
  List<Order> get orders => List.unmodifiable(_orders);

  @override
  Future<List<OrderProduct>> loadProducts() async => products;

  @override
  Future<List<Order>> loadOrders() async => orders;

  @override
  Future<OrderProduct> createProduct(OrderProduct product) async {
    _products.add(product);
    return product;
  }

  @override
  Future<OrderProduct> updateProduct(OrderProduct product) async {
    final index = _products.indexWhere((item) => item.id == product.id);
    if (index == -1) {
      throw StateError('Product not found: ${product.id}');
    }
    _products[index] = product;
    return product;
  }

  @override
  Future<void> deleteProduct(String productId) async {
    _products.removeWhere((product) => product.id == productId);
  }

  @override
  Future<Order> createOrder(Order order) async {
    final stored = order.id == null
        ? order.copyWith(id: _newId())
        : order;
    _orders.add(stored);
    return stored;
  }

  @override
  Future<List<Order>> createOrderBatch(OrderBatch batch) async {
    if (batch.bookingId == null || batch.items.isEmpty) {
      throw StateError('A batch requires a booking and products.');
    }
    final productIds = <String>{};
    for (final item in batch.items) {
      if (item.productId == null ||
          !productIds.add(item.productId!) ||
          !_products.any((product) => product.id == item.productId) ||
          item.quantity < 1 ||
          item.bookingId != batch.bookingId ||
          item.siteNumber != batch.siteNumber ||
          item.serviceDate != batch.serviceDate) {
        throw StateError('Invalid batch item.');
      }
    }

    final prefix = _newId();
    final stored = <Order>[
      for (var index = 0; index < batch.items.length; index++)
        batch.items[index].copyWith(id: '$prefix-$index'),
    ];
    _orders.addAll(stored);
    return stored;
  }

  @override
  Future<Order> updateOrder(Order order) async {
    final index = _orders.indexWhere((item) => item.id == order.id);
    if (index == -1) {
      throw StateError('Order not found: ${order.description}');
    }
    _orders[index] = order;
    return order;
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();
}
