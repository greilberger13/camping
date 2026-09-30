import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/supabase_config.dart';
import '../../core/supabase_database.dart';
import '../../models/booking.dart';
import '../../models/camp_site.dart';
import '../../models/calendar_event.dart';
import '../../models/order.dart';
import '../../models/order_batch.dart';
import '../../models/order_product.dart';
import '../../models/stay_note.dart';
import '../../models/task.dart';
import '../../services/booking_repository.dart';
import '../../services/supabase_booking_repository.dart';
import '../../services/in_memory_booking_repository.dart';
import '../../services/in_memory_invoice_repository.dart';
import '../../services/in_memory_order_repository.dart';
import '../../services/in_memory_pricing_repository.dart';
import '../../services/invoice_repository.dart';
import '../../services/order_repository.dart';
import '../../services/pricing_repository.dart';
import '../../services/supabase_invoice_repository.dart';
import '../../services/supabase_order_repository.dart';
import '../../services/supabase_pricing_repository.dart';
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
import '../settings/settings_page.dart';
import '../site_map/site_map_page.dart';
import '../statistics/statistics_page.dart';
import '../stays/booking_order_dialog.dart';
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
  late PricingRepository pricingRepository;
  late InvoiceRepository invoiceRepository;
  String connectionStatus = 'Lokal';
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
    siteRepository = InMemorySiteRepository();
    bookingRepository = InMemoryBookingRepository(
      sites: () => siteRepository.sites,
    );
    orderRepository = localOrderRepository;
    pricingRepository = InMemoryPricingRepository();
    invoiceRepository = InMemoryInvoiceRepository();
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
    taskRepository = InMemoryTaskRepository(
      initial: const [
        CampingTask(title: 'Müllsäcke einkaufen', quantity: 'Campingbedarf', category: TaskCategory.camping),
      ],
    );
    unawaited(taskRepository.syncOrders(orders));
    unawaited(_initializeRemoteRepositories());
  }

  static const nav = [
    ('Heute', Icons.today_outlined),
    ('Buchungen', Icons.calendar_month_outlined),
    ('Platzplan', Icons.map_outlined),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Center(child: Text(connectionStatus)),
              ),
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
            drawer: wide
              ? null
              : Drawer(child: _navigation(context, inDrawer: true)),
          body: connectionStatus == 'Verbinde ...'
              ? const Center(
                  child: CircularProgressIndicator(
                    semanticsLabel: 'Datenbank wird verbunden',
                  ),
                )
              : Row(
                  children: [
                    if (wide)
                      SizedBox(
                        width: 224,
                        child: _navigation(context, inDrawer: false),
                      ),
                    Expanded(child: _page(context)),
                  ],
                ),
          floatingActionButton: selected == 1
              ? FloatingActionButton.extended(
                    onPressed: connectionStatus == 'Verbinde ...'
                      ? null
                      : () => unawaited(_perform(_openBookingForm)),
                  icon: const Icon(Icons.add),
                  label: const Text('Buchung'),
                )
              : null,
        );
      },
    );
  }

  Widget _navigation(BuildContext context, {required bool inDrawer}) {
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
                  if (inDrawer) {
                    Navigator.pop(context);
                  }
                },
              ),
            const Spacer(),
            const Divider(indent: 18, endIndent: 18),
            ListTile(
              selected: selected == 7,
              leading: Icon(Icons.settings_outlined),
              title: Text('Einstellungen'),
              onTap: () {
                setState(() => selected = 7);
                if (inDrawer) Navigator.pop(context);
              },
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
          onDelete: (booking) => unawaited(
            _perform(() => _deleteBooking(booking)),
          ),
          onEdit: (booking) => unawaited(
            _perform(() => _editBooking(booking)),
          ),
          onOrder: (booking) => unawaited(
            _perform(() => _openOrderForBooking(booking)),
          ),
        );
      case 2:
        return SiteMapPage(
          bookings: newBookings,
          sites: siteRepository.sites,
          onSiteTap: (number) => unawaited(
            _perform(() => _openBookingForSite(number)),
          ),
          onManageSite: (site) => unawaited(
            _perform(() => _manageSite(site)),
          ),
        );
      case 3:
        return CheckoutPage(
          bookings: newBookings,
          orders: orders,
          pricing: pricingRepository.current,
          invoiceRepository: invoiceRepository,
        );
      case 4:
        return TasksPage(
          tasks: taskRepository.tasks,
          onTaskAdded: (task) => unawaited(
            _perform(() => _addTask(task)),
          ),
          onTaskCompleted: (task) => unawaited(
            _perform(() => _completeTask(task)),
          ),
        );
      case 5:
        return StatisticsPage(bookings: newBookings);
      case 6:
        return CalendarPage(repository: calendarRepository);
      case 7:
        return SettingsPage(
          pricing: pricingRepository.current,
          products: products,
          onSavePricing: (pricing) async {
            await pricingRepository.save(pricing);
            if (mounted) setState(() {});
          },
          onCreateProduct: _addProduct,
          onUpdateProduct: _updateProduct,
          onDeleteProduct: _deleteProduct,
        );
      default:
        return DashboardPage(
          onMapTap: () => setState(() => selected = 2),
          onBookingTap: () => setState(() => selected = 1),
          onStayTap: () => setState(() => selected = 1),
          onCheckoutTap: () => setState(() => selected = 3),
          bookings: newBookings,
        );
    }
  }

  Future<void> _perform(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      if (!mounted) return;
      if (connectionStatus == 'Online') {
        setState(() => connectionStatus = 'Remote-Fehler');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Änderung nicht gespeichert: $error')),
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

  Future<void> _manageSite(CampSite site) async {
    final current = DateTime.now();
    final today = DateTime(current.year, current.month, current.day);
    final affected = newBookings.where(
      (booking) => booking.siteNumber == site.number &&
          booking.departureDate != null &&
          !booking.departureDate!.isBefore(today),
    ).toList();
    final blocked = site.status == 'Gesperrt';
    final decision = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Platz ${site.number}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Gesperrt'),
              value: blocked,
              onChanged: (_) => Navigator.pop(context, 'toggle'),
            ),
            if (!blocked && affected.isNotEmpty)
              Text(
                '${affected.length} bestehende Buchung(en) bleiben erhalten. '
                'Bitte bei Bedarf auf einen freien Stellplatz verlegen.',
              ),
            for (final booking in affected)
              ListTile(
                title: Text(booking.guestName),
                subtitle: Text('${booking.arrival} – ${booking.departure}'),
                trailing: const Icon(Icons.edit_outlined),
                onTap: () => Navigator.pop(context, booking.id),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
    if (decision == 'toggle') {
      await siteRepository.update(
        site.copyWith(status: blocked ? 'Frei' : 'Gesperrt'),
      );
      if (mounted) setState(() {});
    } else if (decision != null) {
      final matches = affected.where((booking) => booking.id == decision);
      if (matches.isNotEmpty && mounted) await _editBooking(matches.first);
    }
  }

  Future<void> _initializeRemoteRepositories() async {
    final config = SupabaseConfig.fromEnvironment();
    if (!config.isConfigured) {
      return;
    }

    if (mounted) setState(() => connectionStatus = 'Verbinde ...');

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
      final pricingRepository = SupabasePricingRepository(database);
      final invoiceRepository = SupabaseInvoiceRepository(database);
      await bookingRepository.load();
      await orderRepository.loadProducts();
      await orderRepository.loadOrders();
      await noteRepository.load();
      await calendarRepository.load();
      await siteRepository.load();
      await taskRepository.load();
      await pricingRepository.load();
      await invoiceRepository.load();
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
        this.pricingRepository = pricingRepository;
        this.invoiceRepository = invoiceRepository;
        connectionStatus = 'Online';
      });
    } catch (error) {
      if (mounted) {
        setState(() => connectionStatus = 'Offline · lokal');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Supabase nicht erreichbar: $error')),
        );
      }
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
        sites: siteRepository.sites,
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

  Future<void> _addOrderBatch(OrderBatch batch) async {
    await orderRepository.createOrderBatch(batch);
    await taskRepository.syncOrders(orders);
    if (mounted) setState(() {});
  }

  Future<void> _openOrderForBooking(Booking booking) async {
    if (booking.id == null) return;
    final batch = await showDialog<OrderBatch>(
      context: context,
      builder: (context) => BookingOrderDialog(
        booking: booking,
        products: products,
      ),
    );
    if (batch != null) await _addOrderBatch(batch);
  }

  Future<void> _updateOrder(Order order) async {
    await orderRepository.updateOrder(order);
    await taskRepository.syncOrders(orders);
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

  Future<void> _completeTask(CampingTask task) async {
    if (task.isAutomatic && taskRepository is InMemoryTaskRepository) {
      for (final order in orders.where((item) {
        final key = item.productId == null
            ? 'order:${item.category.name}:${item.description}'
            : 'order:${item.productId}';
        return key == task.taskKey && item.status == OrderStatus.open;
      }).toList()) {
        await orderRepository.updateOrder(
          order.copyWith(status: OrderStatus.completed),
        );
      }
    }
    await taskRepository.complete(task);
    if (task.isAutomatic) {
      await orderRepository.loadOrders();
      await taskRepository.syncOrders(orders);
    }
    if (mounted) setState(() {});
  }
}
