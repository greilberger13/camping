import 'order.dart';

class OrderBatch {
  const OrderBatch({
    required this.siteNumber,
    required this.bookingId,
    required this.items,
  });

  final int siteNumber;
  final String? bookingId;
  final List<Order> items;
}
