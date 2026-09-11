import 'order.dart';

class OrderProduct {
  const OrderProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.unitPrice,
  });

  final String id;
  final String name;
  final OrderCategory category;
  final double unitPrice;

  String get categoryLabel {
    switch (category) {
      case OrderCategory.bakery:
        return 'Brötchenservice';
      case OrderCategory.foodAndDrinks:
        return 'Essen & Getränke';
      case OrderCategory.kiosk:
        return 'Kiosk';
    }
  }
}
