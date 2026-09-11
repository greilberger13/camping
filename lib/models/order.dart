enum OrderCategory {
  bakery,
  foodAndDrinks,
  kiosk,
}

enum OrderStatus {
  open,
  completed,
}

class Order {
  const Order({
    this.id,
    required this.siteNumber,
    required this.description,
    required this.quantity,
    required this.category,
    this.productId,
    this.unitPrice,
    this.status = OrderStatus.open,
  });

  final String? id;
  final int siteNumber;
  final String description;
  final int quantity;
  final OrderCategory category;
  final String? productId;
  final double? unitPrice;
  final OrderStatus status;

  Order copyWith({String? id, OrderStatus? status}) {
    return Order(
      id: id ?? this.id,
      siteNumber: siteNumber,
      description: description,
      quantity: quantity,
      category: category,
      productId: productId,
      unitPrice: unitPrice,
      status: status ?? this.status,
    );
  }

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
