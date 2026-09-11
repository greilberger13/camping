import 'package:flutter/material.dart';

import '../../models/booking.dart';
import '../../models/order.dart';
import '../../models/order_product.dart';
import '../../models/stay_note.dart';
import '../bookings/booking_dialog.dart';
import '../bookings/bookings_page.dart';
import '../calendar/calendar_page.dart';
import '../checkout/checkout_page.dart';
import '../dashboard/dashboard_page.dart';
import '../site_map/site_map_page.dart';
import '../statistics/statistics_page.dart';
import '../stays/stays_page.dart';
import '../tasks/tasks_page.dart';

class CampingHomePage extends StatefulWidget {
  const CampingHomePage({super.key});

  @override
  State<CampingHomePage> createState() => _CampingHomePageState();
}

class _CampingHomePageState extends State<CampingHomePage> {
  int selected = 0;
  final List<Booking> newBookings = [];
  final List<Order> orders = [
    const Order(
      siteNumber: 5,
      description: '5 Semmeln',
      quantity: 1,
      category: OrderCategory.bakery,
    ),
    const Order(
      siteNumber: 22,
      description: 'Kärntnernudel und Bier',
      quantity: 1,
      category: OrderCategory.foodAndDrinks,
    ),
  ];
  final List<OrderProduct> products = [
    const OrderProduct(
      id: 'semmel',
      name: 'Semmel',
      category: OrderCategory.bakery,
      unitPrice: 0.5,
    ),
    const OrderProduct(
      id: 'kornspitz',
      name: 'Kornspitz',
      category: OrderCategory.bakery,
      unitPrice: 0.8,
    ),
    const OrderProduct(
      id: 'bier',
      name: 'Bier',
      category: OrderCategory.foodAndDrinks,
      unitPrice: 3.5,
    ),
  ];
  final Map<int, bool> electricityBySite = {5: true, 22: false};
  final List<StayNote> notes = [];

  static const nav = [
    ('Heute', Icons.today_outlined),
    ('Buchungen', Icons.calendar_month_outlined),
    ('Platzplan', Icons.map_outlined),
    ('Aufenthalt', Icons.room_service_outlined),
    ('Abreise', Icons.logout_outlined),
    ('Aufgaben', Icons.checklist_outlined),
    ('Statistik', Icons.bar_chart_outlined),
    ('Kalender', Icons.event_note_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Peterbauer Camping'),
            actions: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 18),
                child: CircleAvatar(
                  radius: 17,
                  backgroundColor: Color(0xffd9ebe5),
                  child: Text('PB'),
                ),
              ),
            ],
          ),
          drawer: wide ? null : Drawer(child: _navigation(context)),
          body: Row(
            children: [
              if (wide) SizedBox(width: 224, child: _navigation(context)),
              Expanded(child: _page(context)),
            ],
          ),
          floatingActionButton: selected == 1
              ? FloatingActionButton.extended(
                  onPressed: _openBookingForm,
                  icon: const Icon(Icons.add),
                  label: const Text('Buchung'),
                )
              : null,
        );
      },
    );
  }

  Widget _navigation(BuildContext context) {
    return Material(
      color: const Color(0xffeaf1ed),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 24, 16, 22),
              child: Text(
                'BETREIBERBEREICH',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff47736b),
                ),
              ),
            ),
            for (var i = 0; i < nav.length; i++)
              ListTile(
                selected: i == selected,
                selectedTileColor: const Color(0xffcfe5dc),
                leading: Icon(nav[i].$2),
                title: Text(nav[i].$1),
                onTap: () {
                  setState(() => selected = i);
                  if (Scaffold.of(context).hasDrawer) {
                    Navigator.pop(context);
                  }
                },
              ),
            const Spacer(),
            const Divider(indent: 18, endIndent: 18),
            const ListTile(
              leading: Icon(Icons.settings_outlined),
              title: Text('Einstellungen'),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _page(BuildContext context) {
    switch (selected) {
      case 1:
        return BookingsPage(
          bookings: newBookings,
          onDelete: (booking) {
            setState(() => newBookings.remove(booking));
          },
          onEdit: _editBooking,
        );
      case 2:
        return SiteMapPage(bookings: newBookings);
      case 3:
        return StaysPage(
          bookings: newBookings,
          orders: orders,
          products: products,
          electricityBySite: electricityBySite,
          onOrderAdded: (order) => setState(() => orders.add(order)),
          onOrderUpdated: (updatedOrder) {
            setState(() {
              final index = orders.indexWhere(
                (order) =>
                    order.siteNumber == updatedOrder.siteNumber &&
                    order.description == updatedOrder.description &&
                    order.productId == updatedOrder.productId,
              );
              if (index != -1) {
                orders[index] = updatedOrder;
              }
            });
          },
          onProductAdded: (product) => setState(() => products.add(product)),
          onProductUpdated: (updatedProduct) {
            setState(() {
              final index = products.indexWhere(
                (product) => product.id == updatedProduct.id,
              );
              if (index != -1) {
                products[index] = updatedProduct;
              }
            });
          },
          onProductDeleted: (productId) {
            setState(() {
              products.removeWhere((product) => product.id == productId);
            });
          },
          notes: notes,
          onNoteAdded: (note) => setState(() => notes.add(note)),
          onNoteDeleted: (note) => setState(() => notes.remove(note)),
          onElectricityChanged: (siteNumber, enabled) {
            setState(() => electricityBySite[siteNumber] = enabled);
          },
        );
      case 4:
        return CheckoutPage(
          bookings: newBookings,
          orders: orders,
          electricityBySite: electricityBySite,
        );
      case 5:
        return TasksPage(orders: orders);
      case 6:
        return StatisticsPage(bookings: newBookings);
      case 7:
        return const CalendarPage();
      default:
        return DashboardPage(
          onMapTap: () => setState(() => selected = 2),
          onBookingTap: () => setState(() => selected = 1),
          onStayTap: () => setState(() => selected = 3),
          onCheckoutTap: () => setState(() => selected = 4),
          bookings: newBookings,
        );
    }
  }

  Future<void> _openBookingForm() async {
    final booking = await showDialog<Booking>(
      context: context,
      builder: (context) => BookingDialog(
        existingBookings: newBookings,
      ),
    );

    if (booking != null) {
      setState(() => newBookings.add(booking));
    }
  }

  Future<void> _editBooking(Booking booking) async {
    final editableBookings = newBookings
        .where((current) => !identical(current, booking))
        .toList();
    final updatedBooking = await showDialog<Booking>(
      context: context,
      builder: (context) => BookingDialog(
        existingBookings: editableBookings,
        initialBooking: booking,
      ),
    );

    if (updatedBooking == null) {
      return;
    }

    setState(() {
      final index = newBookings.indexOf(booking);
      if (index != -1) {
        newBookings[index] = updatedBooking;
      }
    });
  }
}
