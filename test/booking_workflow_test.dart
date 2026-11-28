// Hybrid booking workflow in the app: lifecycle grouping, which actions each
// side sees, and the WhatsApp copy-message fallback.
// ignore_for_file: depend_on_referenced_packages
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:passon_ride/models/booking_status.dart';
import 'package:passon_ride/models/models.dart';
import 'package:passon_ride/providers/app_state.dart';
import 'package:passon_ride/widgets/booking_workflow_actions.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class _FakeLauncher extends UrlLauncherPlatform with MockPlatformInterfaceMixin {
  _FakeLauncher({required this.canOpen});
  bool canOpen;
  final launched = <String>[];
  @override
  LinkDelegate? get linkDelegate => null;
  @override
  Future<bool> canLaunch(String url) async => canOpen;
  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launched.add(url);
    return canOpen;
  }
}

class _TestAppState extends AppState {
  _TestAppState(this._vehicleList);
  final List<Vehicle> _vehicleList;
  @override
  List<Vehicle> get vehicles => _vehicleList;
}

Vehicle _vehicle({String hostPhone = '+91 98000 11111'}) => Vehicle.fromMap({
      'id': 'veh_activa',
      'title': 'Honda Activa 6G',
      'category': 'Scooter',
      'type': 'Scooter',
      'price_per_day': 625.0,
      'image_url': '',
      'location': 'Hill Cart Road, Siliguri',
      'host_name': 'Blue Wave Rentals',
      'host_phone': hostPhone,
      'host_id': 'host_1',
      'status': 'Available',
    });

Booking _booking(String status, {String fee = 'NOT_REQUIRED', DateTime? start}) {
  final s = start ?? DateTime.now().add(const Duration(days: 2));
  return Booking(
    id: 'b_1',
    bookingReference: 'PR-7KQ2M9XA',
    vehicleId: 'veh_activa',
    vehicleTitle: 'Honda Activa 6G',
    vehicleImageUrl: '',
    hostName: 'Blue Wave Rentals',
    userId: 'rider_1',
    hostId: 'host_1',
    startDate: s,
    endDate: s.add(const Duration(hours: 8)),
    totalPrice: 1250,
    status: status,
    unlockPasscode: 'PASS-1234',
    createdAt: DateTime.now(),
    customerName: 'Rina Das',
    customerPhone: '+91 98300 12345',
    feePaymentStatus: fee,
  );
}

void main() {
  group('lifecycle', () {
    test('statuses fall into the five tabs, legacy spellings included', () {
      expect(_booking('Pending').category, BookingCategory.pending);
      expect(_booking('confirmed').category, BookingCategory.confirmed);
      expect(_booking('Active').category, BookingCategory.ongoing);
      expect(_booking('Completed').category, BookingCategory.completed);
      for (final s in ['Rejected', 'Cancelled', 'Expired']) {
        expect(_booking(s).category, BookingCategory.closed, reason: s);
      }
      expect(BookingStatus.label('Active'), 'Ongoing');
    });

    test('a pending booking is never treated as confirmed', () {
      final b = _booking('Pending');
      expect(b.canShareConfirmation, isFalse);
      expect(b.canMarkOngoing, isFalse);
      expect(b.ownerCanDecide, isTrue);
    });

    test('owner cannot accept until the booking fee is verified', () {
      expect(_booking('Pending', fee: 'SUBMITTED').ownerCanAccept, isFalse);
      expect(_booking('Pending', fee: 'PAID').ownerCanAccept, isTrue);
      expect(_booking('Pending').ownerCanAccept, isTrue);
    });

    test('renter cancels only before pickup; never once ongoing', () {
      final now = DateTime.now();
      expect(_booking('Confirmed').renterCanCancel(now), isTrue);
      expect(_booking('Confirmed', start: now.subtract(const Duration(hours: 1))).renterCanCancel(now), isFalse);
      expect(_booking('Active').renterCanCancel(now), isFalse);
      expect(_booking('Active').ownerCanCancel, isFalse);
    });

    test('closed bookings do not block availability', () {
      for (final s in ['Rejected', 'Cancelled', 'Expired', 'Completed']) {
        expect(BookingStatus.isClosed(s), isTrue, reason: s);
      }
      expect(BookingStatus.isClosed('Pending'), isFalse);
    });
  });

  group('actions widget', () {
    late _FakeLauncher launcher;

    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      try {
        await Supabase.initialize(url: 'https://example.supabase.co', publishableKey: 'test-anon-key');
      } catch (_) {}
    });

    setUp(() {
      launcher = _FakeLauncher(canOpen: true);
      UrlLauncherPlatform.instance = launcher;
    });

    Future<void> pump(WidgetTester tester, Booking b, {required bool isOwner, String hostPhone = '+91 98000 11111'}) async {
      tester.view.physicalSize = const Size(430, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ChangeNotifierProvider<AppState>.value(
        value: _TestAppState([_vehicle(hostPhone: hostPhone)]),
        child: MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: BookingWorkflowActions(booking: b, isOwner: isOwner))),
        ),
      ));
      await tester.pump();
    }

    testWidgets('owner, pending request: Accept and Reject', (tester) async {
      await pump(tester, _booking('Pending'), isOwner: true);
      expect(find.text('ACCEPT BOOKING'), findsOneWidget);
      expect(find.text('REJECT BOOKING'), findsOneWidget);
      expect(find.text('Notify Renter on WhatsApp'), findsNothing, reason: 'nothing decided yet');
      expect(find.text('Mark as Ongoing'), findsNothing);
      expect(find.text('This renter is waiting for your decision.'), findsOneWidget);
    });

    testWidgets('owner, fee not verified: Accept disabled with explanation', (tester) async {
      await pump(tester, _booking('Pending', fee: 'SUBMITTED'), isOwner: true);
      final accept = tester.widget<ElevatedButton>(find.ancestor(of: find.text('ACCEPT BOOKING'), matching: find.byWidgetPredicate((w) => w is ElevatedButton)));
      expect(accept.onPressed, isNull);
      expect(find.textContaining('booking fee is verified'), findsOneWidget);
    });

    testWidgets('owner, confirmed: lifecycle + notify renter + contact', (tester) async {
      await pump(tester, _booking('Confirmed'), isOwner: true);
      expect(find.text('ACCEPT BOOKING'), findsNothing);
      expect(find.text('Mark as Ongoing'), findsOneWidget);
      expect(find.text('Mark as Completed'), findsNothing);
      expect(find.text('Notify Renter on WhatsApp'), findsOneWidget);
      expect(find.text('Contact Renter'), findsOneWidget);
      expect(find.text('Booking History'), findsOneWidget);
    });

    testWidgets('owner, ongoing: Mark as Completed', (tester) async {
      await pump(tester, _booking('Active'), isOwner: true);
      expect(find.text('Mark as Completed'), findsOneWidget);
      expect(find.text('Mark as Ongoing'), findsNothing);
    });

    testWidgets('owner, rejected: can tell the renter, nothing else to do', (tester) async {
      await pump(tester, _booking('Rejected'), isOwner: true);
      expect(find.text('Notify Renter on WhatsApp'), findsOneWidget);
      expect(find.text('Contact Renter'), findsNothing);
      expect(find.text('ACCEPT BOOKING'), findsNothing);
    });

    testWidgets('renter, pending: share request with owner, no accept buttons', (tester) async {
      await pump(tester, _booking('Pending'), isOwner: false);
      expect(find.text('Share with Owner on WhatsApp'), findsOneWidget);
      expect(find.text('ACCEPT BOOKING'), findsNothing);
      expect(find.text('Contact Owner'), findsOneWidget);
      expect(find.textContaining('not a confirmed booking yet'), findsOneWidget);
    });

    testWidgets('renter shares with owner: wa.me opens with the request', (tester) async {
      await pump(tester, _booking('Pending'), isOwner: false);
      await tester.tap(find.text('Share with Owner on WhatsApp'));
      await tester.pumpAndSettle();
      expect(launcher.launched, hasLength(1));
      final uri = Uri.parse(launcher.launched.single);
      expect(uri.host, 'wa.me');
      expect(uri.path, '/919800011111');
      expect(uri.queryParameters['text'], contains('PR-7KQ2M9XA'));
      expect(uri.queryParameters['text'], contains('PENDING APPROVAL'));
    });

    testWidgets('WhatsApp unavailable: copy-message fallback', (tester) async {
      launcher.canOpen = false;
      await pump(tester, _booking('Confirmed'), isOwner: false);
      await tester.tap(find.text('Share with Owner on WhatsApp'));
      await tester.pumpAndSettle();
      expect(find.text('Copy booking details'), findsOneWidget);
      expect(find.textContaining('could not be opened'), findsOneWidget);
      expect(find.text('Copy message'), findsOneWidget);
    });

    testWidgets('owner has no phone: fallback without opening WhatsApp', (tester) async {
      await pump(tester, _booking('Confirmed'), isOwner: false, hostPhone: '');
      await tester.tap(find.text('Share with Owner on WhatsApp'));
      await tester.pumpAndSettle();
      expect(launcher.launched, isEmpty);
      expect(find.textContaining('No valid WhatsApp number'), findsOneWidget);
    });
  });
}
