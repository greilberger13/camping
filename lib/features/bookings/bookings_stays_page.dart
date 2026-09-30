import 'package:flutter/material.dart';

class BookingsStaysPage extends StatelessWidget {
  const BookingsStaysPage({
    required this.bookings,
    required this.stays,
    super.key,
  });

  final Widget bookings;
  final Widget stays;

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Buchungen', icon: Icon(Icons.calendar_month_outlined)),
                Tab(text: 'Aufenthalt', icon: Icon(Icons.room_service_outlined)),
              ],
            ),
            Expanded(
              child: TabBarView(children: [bookings, stays]),
            ),
          ],
        ),
      );
}