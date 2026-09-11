enum TaskCategory {
  bakery,
  kiosk,
  camping,
}

class CampingTask {
  const CampingTask({
    this.id,
    required this.title,
    required this.quantity,
    required this.category,
    this.isDone = false,
  });

  final String? id;
  final String title;
  final String quantity;
  final TaskCategory category;
  final bool isDone;

  CampingTask copyWith({String? id, bool? isDone}) {
    return CampingTask(
      id: id ?? this.id,
      title: title,
      quantity: quantity,
      category: category,
      isDone: isDone ?? this.isDone,
    );
  }

  String get categoryLabel {
    switch (category) {
      case TaskCategory.bakery:
        return 'Brötchenservice';
      case TaskCategory.kiosk:
        return 'Kiosk';
      case TaskCategory.camping:
        return 'Camping';
    }
  }
}
