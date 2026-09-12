import '../core/supabase_database.dart';
import '../models/order.dart';
import '../models/order_batch.dart';
import '../models/order_product.dart';
import 'order_repository.dart';

class SupabaseOrderRepository implements OrderRepository {
  SupabaseOrderRepository(this.database);

  final SupabaseDatabase database;
  final productCache = <OrderProduct>[];
  final orderCache = <Order>[];

  @override
  List<OrderProduct> get products => List.unmodifiable(productCache);

  @override
  List<Order> get orders => List.unmodifiable(orderCache);

  @override
  Future<List<OrderProduct>> loadProducts() async {
    final rows = await database.client
        .from('order_products')
        .select()
        .eq('is_active', true)
        .order('name');
    productCache
      ..clear()
      ..addAll(rows.map(_productFromRow));
    return products;
  }

  @override
  Future<List<Order>> loadOrders() async {
    final rows = await database.client
        .from('orders')
      .select('*, camp_sites!inner(site_number)')
        .order('created_at');
    orderCache
      ..clear()
      ..addAll(rows.map(_orderFromRow));
    return orders;
  }

  @override
  Future<OrderProduct> createProduct(OrderProduct product) async {
    final row = await database.client
        .from('order_products')
        .insert(_productToRow(product))
        .select()
        .single();
    final stored = _productFromRow(row);
    productCache.add(stored);
    return stored;
  }

  @override
  Future<OrderProduct> updateProduct(OrderProduct product) async {
    final row = await database.client
        .from('order_products')
        .update(_productToRow(product))
        .eq('id', product.id)
        .select()
        .single();
    final updated = _productFromRow(row);
    final index = productCache.indexWhere((item) => item.id == product.id);
    if (index != -1) productCache[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteProduct(String productId) async {
    await database.client
        .from('order_products')
        .update({'is_active': false})
        .eq('id', productId);
    productCache.removeWhere((product) => product.id == productId);
  }

  @override
  Future<Order> createOrder(Order order) async {
    final siteId = await _siteIdForNumber(order.siteNumber);
    final row = await database.client
        .from('orders')
        .insert(_orderToRow(order, siteId: siteId))
      .select('*, camp_sites!inner(site_number)')
        .single();
    final stored = _orderFromRow(row);
    orderCache.add(stored);
    return stored;
  }

  @override
  Future<List<Order>> createOrderBatch(OrderBatch batch) async {
    final stored = <Order>[];
    for (final item in batch.items) {
      stored.add(await createOrder(item));
    }
    return stored;
  }

  @override
  Future<Order> updateOrder(Order order) async {
    final matchIndex = orderCache.indexWhere((item) => item.id == order.id);
    if (matchIndex == -1) {
      throw StateError('Order not found: ${order.description}');
    }

    final existing = orderCache[matchIndex];
    if (existing.id == null) {
      throw StateError('Order has no database id: ${order.description}');
    }

    final row = await database.client
        .from('orders')
        .update({'status': _statusValue(order.status)})
        .eq('id', existing.id!)
        .select('*, camp_sites!inner(site_number)')
        .single();
    final updated = _orderFromRow(row);
    orderCache[matchIndex] = updated;
    return updated;
  }

  Map<String, dynamic> _productToRow(OrderProduct product) {
    return {
      'name': product.name,
      'category': _categoryValue(product.category),
      'unit_price': product.unitPrice,
      'is_active': true,
    };
  }

  Map<String, dynamic> _orderToRow(
    Order order, {
    required String siteId,
  }) {
    return {
      'site_id': siteId,
      'booking_id': order.bookingId,
      'product_id': order.productId,
      'description': order.description,
      'quantity': order.quantity,
      'unit_price': order.unitPrice ?? 0,
      'category': _categoryValue(order.category),
      'status': _statusValue(order.status),
    };
  }

  OrderProduct _productFromRow(Map<String, dynamic> row) {
    return OrderProduct(
      id: row['id'] as String,
      name: row['name'] as String,
      category: _categoryFromValue(row['category'] as String),
      unitPrice: (row['unit_price'] as num).toDouble(),
    );
  }

  Order _orderFromRow(Map<String, dynamic> row) {
    final site = row['camp_sites'] as Map<String, dynamic>;
    return Order(
      id: row['id'] as String?,
      bookingId: row['booking_id'] as String?,
      siteNumber: site['site_number'] as int,
      description: row['description'] as String,
      quantity: row['quantity'] as int,
      category: _categoryFromValue(row['category'] as String),
      productId: row['product_id'] as String?,
      unitPrice: (row['unit_price'] as num).toDouble(),
      status: _statusFromValue(row['status'] as String),
    );
  }

  Future<String> _siteIdForNumber(int siteNumber) async {
    final row = await database.client
        .from('camp_sites')
        .select('id')
        .eq('site_number', siteNumber)
        .single();
    return row['id'] as String;
  }

  String _categoryValue(OrderCategory category) {
    switch (category) {
      case OrderCategory.bakery:
        return 'bakery';
      case OrderCategory.foodAndDrinks:
        return 'food_and_drinks';
      case OrderCategory.kiosk:
        return 'kiosk';
    }
  }

  OrderCategory _categoryFromValue(String value) {
    switch (value) {
      case 'food_and_drinks':
        return OrderCategory.foodAndDrinks;
      case 'kiosk':
        return OrderCategory.kiosk;
      default:
        return OrderCategory.bakery;
    }
  }

  String _statusValue(OrderStatus status) {
    return status == OrderStatus.completed ? 'completed' : 'open';
  }

  OrderStatus _statusFromValue(String value) {
    return value == 'completed' ? OrderStatus.completed : OrderStatus.open;
  }
}
