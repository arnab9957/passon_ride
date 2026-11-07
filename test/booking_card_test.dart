// Rider's booking card in My Bookings: payment status, pickup/return date+time,
// pickup location with directions, and Cancel / Message Host / Call Host.
// ignore_for_file: depend_on_referenced_packages
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passon_ride/i18n/strings.g.dart';
import 'package:passon_ride/models/models.dart';
import 'package:passon_ride/providers/app_state.dart';
import 'package:passon_ride/providers/language_provider.dart';
import 'package:passon_ride/screens/my_bookings_screen.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class _FakeLauncher extends UrlLauncherPlatform with MockPlatformInterfaceMixin {
  final launched = <String>[];
  @override
  LinkDelegate? get linkDelegate => null;
  @override
  Future<bool> canLaunch(String url) async => true;
  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launched.add(url);
    return true;
  }
}

class _TestAppState extends AppState {
  _TestAppState(this._bookings, this._vehicleList);
  final List<Booking> _bookings;
  final List<Vehicle> _vehicleList;
  @override
  List<Booking> get activeBookings => _bookings;
  @override
  List<Vehicle> get vehicles => _vehicleList;
}

Vehicle _vehicle() => Vehicle.fromMap({
      'id': 'veh_pulsar',
      'title': 'Bajaj Pulsar N25',
      'category': 'Motorcycle',
      'type': 'Sport',
      'price_per_day': 538.0,
      'rating': 4.8,
      'review_count': 10,
      'image_url': '',
      'location': 'Hill Cart Road, Siliguri',
      'latitude': 26.7271,
      'longitude': 88.3953,
      'host_name': 'Blue Wave Rental',
      'host_phone': '+91 98000 11111',
      'host_avatar': '',
      'host_trust_score': 98.0,
      'host_id': 'host_bluewave',
      'fuel_type': 'Petrol',
      'transmission': 'Manual',
      'seats': 2,
      'description': '',
      'iot_data': {},
    });

Booking _booking({required String paymentIntentId, String paymentMethod = ''}) {
  final start = DateTime.now().add(const Duration(days: 1));
  return Booking(
    id: 'bk_test_${paymentIntentId.hashCode}',
    vehicleId: 'veh_pulsar',
    vehicleTitle: 'Bajaj Pulsar N25',
    vehicleImageUrl: '',
    hostName: 'Blue Wave Rental',
    userId: 'rider_1',
    hostId: 'host_bluewave',
    accountId: 'rider_1',
    accountName: 'Rider',
    accountType: 'mother',
    startDate: DateTime(start.year, start.month, start.day, 10, 0),
    endDate: DateTime(start.year, start.month, start.day + 1, 18, 30),
    totalPrice: 538,
    status: 'Confirmed',
    unlockPasscode: 'PASS-7982',
    paymentIntentId: paymentIntentId,
    createdAt: DateTime.now(),
    paymentMethod: paymentMethod,
  );
}

/// Goldens were recorded on Linux with real Roboto/Material fonts. They are only
/// compared when those fonts load; otherwise text renders as boxes and the pixel
/// comparison fails for reasons unrelated to the UI.
bool _goldensEnabled = false;

Future<void> _loadFonts() async {
  // `flutter test` sets FLUTTER_ROOT on every machine (GitHub Actions, snap, Windows...).
  final flutterRoot =
      Platform.environment['FLUTTER_ROOT'] ?? '${Platform.environment['HOME']}/snap/flutter/common/flutter';
  final root = '$flutterRoot/bin/cache/artifacts/material_fonts';
  var found = 0;
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      final file = File('$root/$f');
      if (file.existsSync()) {
        loader.addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
        found++;
      }
    }
    await loader.load();
  }

  await load('Roboto', ['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf']);
  await load('MaterialIcons', ['MaterialIcons-Regular.otf']);
  _goldensEnabled = found == 4 && Platform.isLinux;
}

void main() {
  late _FakeLauncher launcher;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    // Supabase listens for deep links via app_links, which has no plugin in tests.
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final name in ['com.llfbandit.app_links/events', 'com.llfbandit.app_links/messages']) {
      messenger.setMockMethodCallHandler(MethodChannel(name), (_) async => null);
    }
    try {
      await Supabase.initialize(
        url: 'https://gxqlsogewjjkcdetubuv.supabase.co',
        publishableKey: 'sb_publishable_b1WyefoA--KuuAfVlDjMaw_iFLBj8Hk',
      );
    } catch (_) {}
    await _loadFonts();
  });

  setUp(() {
    launcher = _FakeLauncher();
    UrlLauncherPlatform.instance = launcher;
  });

  Future<void> pumpCard(WidgetTester tester, Booking booking) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final app = _TestAppState([booking], [_vehicle()]);
    await tester.pumpWidget(TranslationProvider(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<AppState>.value(value: app),
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ],
        child: MaterialApp(
          theme: ThemeData(fontFamily: 'Roboto'),
          home: const MyBookingsScreen(),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('pay-at-site booking card shows only payment, times, location, actions', (tester) async {
    final b = _booking(paymentIntentId: 'pay_at_site_1793824212026');
    await pumpCard(tester, b);

    // 1. Payment status
    expect(find.text('PAY AT SITE • ₹538'), findsOneWidget);
    expect(find.text('BOOKING SUCCESSFULLY DONE'), findsNothing);
    expect(find.text('₹538'), findsNothing, reason: 'separate price removed (amount is in the badge)');
    expect(find.byIcon(Icons.delete_outline), findsNothing, reason: 'delete icon removed');
    expect(find.textContaining('Host: '), findsNothing, reason: 'host line removed');

    // 2. Date with time
    expect(find.text('Pickup: '), findsOneWidget);
    expect(find.text('Return: '), findsOneWidget);
    expect(find.textContaining('10:00 AM'), findsOneWidget);
    expect(find.textContaining('06:30 PM'), findsOneWidget);

    // Pickup location + directions
    expect(find.text('Pickup location'), findsOneWidget);
    expect(find.text('Hill Cart Road, Siliguri'), findsOneWidget);

    // 3. Actions
    expect(find.text('Cancel Ride'), findsOneWidget);
    expect(find.text('Message Host'), findsOneWidget);
    expect(find.text('Call Host'), findsOneWidget);

    if (_goldensEnabled) {

      await expectLater(find.byType(Card).first, matchesGoldenFile('goldens/booking_card_pay_at_site.png'));

    }

    await tester.tap(find.text('Directions'));
    await tester.pump();
    expect(launcher.launched, ['https://www.google.com/maps/dir/?api=1&destination=26.7271,88.3953']);

    await tester.tap(find.text('Call Host'));
    await tester.pump();
    expect(launcher.launched.last, 'tel:+919800011111');
  });

  testWidgets('online-paid booking shows PAYMENT RECEIVED', (tester) async {
    await pumpCard(tester, _booking(paymentIntentId: 'pay_RZP123'));
    expect(find.text('PAYMENT RECEIVED • ₹538'), findsOneWidget);
    expect(find.textContaining('PAY AT SITE'), findsNothing);
  });

  testWidgets('offline "Pay at Return" booking shows PAY AT RETURN', (tester) async {
    await pumpCard(tester, _booking(paymentIntentId: 'OFFLINE-VEHICLE-1', paymentMethod: 'Pay at Return / Checkout'));
    expect(find.text('PAY AT RETURN • ₹538'), findsOneWidget);
  });
}
