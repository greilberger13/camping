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
    required this.siteNumber,
    required this.description,
    required this.quantity,
    required this.category,
    this.productId,
    this.unitPrice,
    this.status = OrderStatus.open,
  });

  final int siteNumber;
  final String description;
  final int quantity;
  final OrderCategory category;
  final String? productId;
  final double? unitPrice;
  final OrderStatus status;

  Order copyWith({OrderStatus? status}) {
    return Order(
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
