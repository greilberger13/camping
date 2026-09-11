import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/supabase_config.dart';
import '../../core/supabase_database.dart';
import '../../models/booking.dart';
import '../../models/calendar_event.dart';
import '../../models/order.dart';
import '../../models/order_product.dart';
import '../../models/stay_note.dart';
import '../../models/task.dart';
import '../../services/booking_repository.dart';
import '../../services/supabase_booking_repository.dart';
import '../../services/in_memory_booking_repository.dart';
import '../../services/in_memory_order_repository.dart';
import '../../services/order_repository.dart';
import '../../services/supabase_order_repository.dart';
import '../../services/in_memory_stay_note_repository.dart';
import '../../services/stay_note_repository.dart';
import '../../services/supabase_stay_note_repository.dart';
import '../../services/task_repository.dart';
import '../../services/in_memory_task_repository.dart';
import '../../services/supabase_task_repository.dart';
import '../../services/site_repository.dart';
import '../../services/in_memory_site_repository.dart';
import '../../services/supabase_site_repository.dart';
import '../../services/calendar_event_repository.dart';
import '../../services/in_memory_calendar_event_repository.dart';
import '../../services/supabase_calendar_event_repository.dart';
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
  late BookingRepository bookingRepository;
  late OrderRepository orderRepository;
  final localOrderRepository = InMemoryOrderRepository(
    initialOrders: const [
      Order(
        siteNumber: 5,
        description: '5 Semmeln',
        quantity: 1,
        category: OrderCategory.bakery,
      ),
      Order(
        siteNumber: 22,
        description: 'Kärntnernudel und Bier',
        quantity: 1,
        category: OrderCategory.foodAndDrinks,
      ),
    ],
    initialProducts: const [
      OrderProduct(
        id: 'semmel',
        name: 'Semmel',
        category: OrderCategory.bakery,
        unitPrice: 0.5,
      ),
      OrderProduct(
        id: 'kornspitz',
        name: 'Kornspitz',
        category: OrderCategory.bakery,
        unitPrice: 0.8,
      ),
      OrderProduct(
        id: 'bier',
        name: 'Bier',
        category: OrderCategory.foodAndDrinks,
        unitPrice: 3.5,
      ),
    ],
  );
  final Map<int, bool> electricityBySite = {5: true, 22: false};
  late StayNoteRepository noteRepository;
  late CalendarEventRepository calendarRepository;
  late SiteRepository siteRepository;
  late TaskRepository taskRepository;

  List<Booking> get newBookings => bookingRepository.current;
  List<Order> get orders => orderRepository.orders;
  List<OrderProduct> get products => orderRepository.products;
  List<StayNote> get notes => noteRepository.notes;

  @override
  void initState() {
    super.initState();
    bookingRepository = InMemoryBookingRepository();
    orderRepository = localOrderRepository;
    noteRepository = InMemoryStayNoteRepository();
    calendarRepository = InMemoryCalendarEventRepository(
      initial: const [
        CalendarEvent(
          title: 'Müllabfuhr',
          date: '12.06.2026',
          time: '07:00',
          category: CalendarEventCategory.wasteCollection,
        ),
        CalendarEvent(
          title: 'Getränke-Anlieferung',
          date: '13.06.2026',
          time: '10:30',
          category: CalendarEventCategory.delivery,
        ),
        CalendarEvent(
          title: 'Sommerfest am See',
          date: '20.06.2026',
          time: '18:00',
          category: CalendarEventCategory.event,
        ),
      ],
    );
    siteRepository = InMemorySiteRepository();
    taskRepository = InMemoryTaskRepository(
      initial: const [
        CampingTask(title: 'Müllsäcke einkaufen', quantity: 'Campingbedarf', category: TaskCategory.camping),
      ],
    );
    unawaited(_initializeRemoteRepositories());
  }

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
            unawaited(_deleteBooking(booking));
          },
          onEdit: _editBooking,
        );
      case 2:
        return SiteMapPage(
          bookings: newBookings,
          sites: siteRepository.sites,
          onSiteTap: _openBookingForSite,
        );
      case 3:
        return StaysPage(
          bookings: newBookings,
          orders: orders,
          products: products,
          electricityBySite: electricityBySite,
          onOrdersAdded: (orders) => unawaited(_addOrders(orders)),
          onOrderUpdated: (order) => unawaited(_updateOrder(order)),
          onProductAdded: (product) => unawaited(_addProduct(product)),
          onProductUpdated: (product) => unawaited(_updateProduct(product)),
          onProductDeleted: (productId) => unawaited(_deleteProduct(productId)),
          notes: notes,
          onNoteAdded: (note) => unawaited(_addNote(note)),
          onNoteDeleted: (note) => unawaited(_deleteNote(note)),
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
        return TasksPage(
          orders: orders,
          tasks: taskRepository.tasks,
          onTaskAdded: (task) => unawaited(_addTask(task)),
          onTaskUpdated: (task) => unawaited(_updateTask(task)),
          onOrderUpdated: (order) => unawaited(_updateOrder(order)),
        );
      case 6:
        return StatisticsPage(bookings: newBookings);
      case 7:
        return CalendarPage(repository: calendarRepository);
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
        sites: siteRepository.sites,
      ),
    );

    if (booking != null) {
      await bookingRepository.create(booking);
      setState(() {});
    }
  }

  Future<void> _openBookingForSite(int siteNumber) async {
    final booking = await showDialog<Booking>(
      context: context,
      builder: (context) => BookingDialog(
        existingBookings: newBookings,
        sites: siteRepository.sites,
        initialSiteNumber: siteNumber,
      ),
    );

    if (booking != null) {
      await bookingRepository.create(booking);
      if (mounted) setState(() {});
    }
  }

  Future<void> _initializeRemoteRepositories() async {
    final config = SupabaseConfig.fromEnvironment();
    if (!config.isConfigured) {
      return;
    }

    try {
      final database = await SupabaseDatabase.connect(config: config);
      if (database == null) {
        return;
      }

      final bookingRepository = SupabaseBookingRepository(database);
      final orderRepository = SupabaseOrderRepository(database);
      final noteRepository = SupabaseStayNoteRepository(database);
      final calendarRepository = SupabaseCalendarEventRepository(database);
      final siteRepository = SupabaseSiteRepository(database);
      final taskRepository = SupabaseTaskRepository(database);
      await bookingRepository.load();
      await orderRepository.loadProducts();
      await orderRepository.loadOrders();
      await noteRepository.load();
      await calendarRepository.load();
      await siteRepository.load();
      await taskRepository.load();
      if (!mounted) {
        return;
      }
      setState(() {
        this.bookingRepository = bookingRepository;
        this.orderRepository = orderRepository;
        this.noteRepository = noteRepository;
        this.calendarRepository = calendarRepository;
        this.siteRepository = siteRepository;
        this.taskRepository = taskRepository;
      });
    } catch (_) {
      // Keep the local fallback when the remote database is not reachable.
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

    await bookingRepository.update(updatedBooking.copyWith(id: booking.id));
    setState(() {});
  }

  Future<void> _deleteBooking(Booking booking) async {
    await bookingRepository.delete(booking);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _addNote(StayNote note) async {
    await noteRepository.create(note);
    if (mounted) setState(() {});
  }

  Future<void> _deleteNote(StayNote note) async {
    await noteRepository.delete(note);
    if (mounted) setState(() {});
  }

  Future<void> _addOrders(List<Order> orders) async {
    for (final order in orders) {
      await orderRepository.createOrder(order);
    }
    if (mounted) setState(() {});
  }

  Future<void> _updateOrder(Order order) async {
    await orderRepository.updateOrder(order);
    if (mounted) setState(() {});
  }

  Future<void> _addProduct(OrderProduct product) async {
    await orderRepository.createProduct(product);
    if (mounted) setState(() {});
  }

  Future<void> _updateProduct(OrderProduct product) async {
    await orderRepository.updateProduct(product);
    if (mounted) setState(() {});
  }

  Future<void> _deleteProduct(String productId) async {
    await orderRepository.deleteProduct(productId);
    if (mounted) setState(() {});
  }

  Future<void> _addTask(CampingTask task) async {
    await taskRepository.create(task);
    if (mounted) setState(() {});
  }

  Future<void> _updateTask(CampingTask task) async {
    await taskRepository.update(task);
    if (mounted) setState(() {});
  }
}
