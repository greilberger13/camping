class CampingDates {
  const CampingDates._();

  static final operationalDay = DateTime(2026, 6, 11);
  static final defaultArrival = DateTime(2026, 6, 11);
  static final defaultDeparture = DateTime(2026, 6, 14);
  static final initialWeek = DateTime(2026, 6, 8);

  static String formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    return '$day. ${monthName(date.month)} ${date.year}';
  }

  static String monthName(int month) {
    const names = [
      'Jänner',
      'Februar',
      'März',
      'April',
      'Mai',
      'Juni',
      'Juli',
      'August',
      'September',
      'Oktober',
      'November',
      'Dezember',
    ];
    return names[month - 1];
  }
}
