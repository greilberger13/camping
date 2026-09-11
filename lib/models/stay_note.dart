enum StayNoteCategory {
  bakery,
  foodAndDrinks,
  general,
}

class StayNote {
  const StayNote({
    required this.siteNumber,
    required this.text,
    required this.category,
  });

  final int siteNumber;
  final String text;
  final StayNoteCategory category;

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
