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
        .from('order_items')
        .select(
          '*, order_groups!inner('
          'booking_id, service_date, camp_sites!inner(site_number))',
        )
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
    final date = order.serviceDate;
    if (date == null) {
      throw StateError('An order requires a service date.');
    }
    final stored = await createOrderBatch(
      OrderBatch(
        siteNumber: order.siteNumber,
        bookingId: order.bookingId,
        serviceDate: date,
        items: [order],
      ),
    );
    return stored.single;
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
          item.quantity < 1 ||
          item.siteNumber != batch.siteNumber ||
          item.bookingId != batch.bookingId) {
        throw StateError('Invalid batch item.');
      }
    }

    final rows = await database.client.rpc(
      'create_order_batch',
      params: {
        'p_booking_id': batch.bookingId,
        'p_site_number': batch.siteNumber,
        'p_service_date': batch.serviceDate.toIso8601String().split('T').first,
        'p_items': [
          for (final item in batch.items)
            {'product_id': item.productId, 'quantity': item.quantity},
        ],
      },
    ) as List<dynamic>;
    final stored = <Order>[
      for (final value in rows)
        _storedBatchItem(value as Map<String, dynamic>, batch),
    ];
    orderCache.addAll(stored);
    return stored;
  }

  Order _storedBatchItem(Map<String, dynamic> row, OrderBatch batch) {
    final productId = row['product_id'] as String;
    return Order(
      id: row['id'] as String,
      bookingId: batch.bookingId,
      siteNumber: batch.siteNumber,
      description: row['description'] as String,
      quantity: row['quantity'] as int,
      category: _categoryFromValue(row['category'] as String),
      productId: productId,
      unitPrice: (row['unit_price'] as num).toDouble(),
      serviceDate: batch.serviceDate,
      status: _statusFromValue(row['status'] as String),
    );
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
        .from('order_items')
        .update({'status': _statusValue(order.status)})
        .eq('id', existing.id!)
        .select(
          '*, order_groups!inner('
          'booking_id, service_date, camp_sites!inner(site_number))',
        )
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

  OrderProduct _productFromRow(Map<String, dynamic> row) {
    return OrderProduct(
      id: row['id'] as String,
      name: row['name'] as String,
      category: _categoryFromValue(row['category'] as String),
      unitPrice: (row['unit_price'] as num).toDouble(),
    );
  }

  Order _orderFromRow(Map<String, dynamic> row) {
    final group = row['order_groups'] as Map<String, dynamic>;
    final site = group['camp_sites'] as Map<String, dynamic>;
    return Order(
      id: row['id'] as String?,
      bookingId: group['booking_id'] as String?,
      siteNumber: site['site_number'] as int,
      description: row['description'] as String,
      quantity: row['quantity'] as int,
      category: _categoryFromValue(row['category'] as String),
      productId: row['product_id'] as String?,
      unitPrice: (row['unit_price'] as num).toDouble(),
      serviceDate: DateTime.parse(group['service_date'] as String),
      status: _statusFromValue(row['status'] as String),
    );
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
