class CampingDates {
  const CampingDates._();

  static DateTime get operationalDay => DateTime.now();
  static DateTime get defaultArrival => operationalDay;
  static DateTime get defaultDeparture => operationalDay.add(
        const Duration(days: 1),
      );
  static DateTime get initialWeek => operationalDay.subtract(
        Duration(days: operationalDay.weekday - 1),
      );

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
