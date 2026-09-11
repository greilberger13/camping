enum StayNoteCategory {
  bakery,
  foodAndDrinks,
  general,
}

class StayNote {
  const StayNote({
    this.id,
    required this.siteNumber,
    required this.text,
    required this.category,
  });

  final String? id;
  final int siteNumber;
  final String text;
  final StayNoteCategory category;

  StayNote copyWith({String? id}) {
    return StayNote(
      id: id ?? this.id,
      siteNumber: siteNumber,
      text: text,
      category: category,
    );
  }

  String get categoryLabel {
    switch (category) {
      case StayNoteCategory.bakery:
        return 'Brötchenservice';
      case StayNoteCategory.foodAndDrinks:
        return 'Essen & Getränke';
      case StayNoteCategory.general:
        return 'Allgemein';
    }
  }
}
