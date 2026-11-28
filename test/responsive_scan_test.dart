// Responsive layout scan: renders the main screens at phone, tablet and desktop
// sizes and fails on layout errors (RenderFlex overflow, unbounded constraints...).
// Network/image failures are ignored: only layout problems count.
//
//   flutter test test/responsive_scan_test.dart
// ignore_for_file: depend_on_referenced_packages
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:passon_ride/i18n/strings.g.dart';
import 'package:passon_ride/models/models.dart';
import 'package:passon_ride/providers/app_state.dart';
import 'package:passon_ride/providers/language_provider.dart';
import 'package:passon_ride/screens/admin/admin_layout_screen.dart';
import 'package:passon_ride/screens/admin_dashboard_screen.dart';
import 'package:passon_ride/screens/admin_booking_fee_review_screen.dart';
import 'package:passon_ride/screens/feedback_dashboard_screen.dart';
import 'package:passon_ride/screens/technical_documentation_screen.dart';
import 'package:passon_ride/screens/reset_password_screen.dart';
import 'package:passon_ride/screens/update_password_screen.dart';
import 'package:passon_ride/screens/ai_tour_generator_screen.dart';
import 'package:passon_ride/screens/admin/bookings_management_screen.dart';
import 'package:passon_ride/screens/admin/dashboard_overview_screen.dart';
import 'package:passon_ride/screens/admin/financials_screen.dart';
import 'package:passon_ride/screens/admin/provider_payouts_screen.dart';
import 'package:passon_ride/screens/admin/users_management_screen.dart';
import 'package:passon_ride/screens/admin/vehicles_management_screen.dart';
import 'package:passon_ride/screens/ai_trip_planner_screen.dart';
import 'package:passon_ride/screens/blog_screen.dart';
import 'package:passon_ride/screens/booking_verification_screen.dart';
import 'package:passon_ride/screens/chat_screen.dart';
import 'package:passon_ride/screens/discovery_screen.dart';
import 'package:passon_ride/screens/documents_compliance_screen.dart';
import 'package:passon_ride/screens/earnings_screen.dart';
import 'package:passon_ride/screens/favorites_screen.dart';
import 'package:passon_ride/screens/home_screen.dart';
import 'package:passon_ride/screens/kinetic_trust_screen.dart';
import 'package:passon_ride/screens/main_navigation_screen.dart';
import 'package:passon_ride/screens/message_list_screen.dart';
import 'package:passon_ride/screens/my_bookings_screen.dart';
import 'package:passon_ride/screens/owner_bookings_screen.dart';
import 'package:passon_ride/screens/payment_checkout_screen.dart';
import 'package:passon_ride/screens/profile_screen.dart';
import 'package:passon_ride/screens/provider_dashboard_screen.dart';
import 'package:passon_ride/screens/register_hotel_screen.dart';
import 'package:passon_ride/screens/register_tour_screen.dart';
import 'package:passon_ride/screens/register_vehicle_screen.dart';
import 'package:passon_ride/screens/telematics_hub_screen.dart';
import 'package:passon_ride/screens/vehicle_detail_screen.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class _FakeLauncher extends UrlLauncherPlatform with MockPlatformInterfaceMixin {
  @override
  LinkDelegate? get linkDelegate => null;
  @override
  Future<bool> canLaunch(String url) async => true;
  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async => true;
}

Vehicle _vehicle(String id, String title, double price) => Vehicle.fromMap({
      'id': id,
      'title': title,
      'category': 'Scooter',
      'type': 'Scooter',
      'price_per_day': price,
      'price_per_hour': price / 8,
      'rating': 4.7,
      'review_count': 128,
      'image_url': '',
      'location': 'Hill Cart Road, Siliguri, West Bengal',
      'latitude': 26.7271,
      'longitude': 88.3953,
      'host_name': 'Blue Wave Two-Wheeler Rentals',
      'host_phone': '+91 98000 11111',
      'host_id': 'host_1',
      'status': 'Available',
      'quantity': 2,
      'description': 'Well maintained, helmet included. Fuel not included.',
    });

final _vehicles = [
  _vehicle('v1', 'Royal Enfield Himalayan 450 Adventure Tourer', 1499),
  _vehicle('v2', 'Honda Activa 6G', 450),
];

Booking _booking(String id, String status, int dayOffset) {
  final s = DateTime.now().add(Duration(days: dayOffset));
  return Booking(
    id: id,
    bookingReference: 'PR-${id.toUpperCase().padRight(8, 'X').substring(0, 8)}',
    vehicleId: 'v1',
    vehicleTitle: 'Royal Enfield Himalayan 450 Adventure Tourer',
    vehicleImageUrl: '',
    hostName: 'Blue Wave Two-Wheeler Rentals',
    userId: 'rider_1',
    hostId: 'host_1',
    startDate: DateTime(s.year, s.month, s.day, 10),
    endDate: DateTime(s.year, s.month, s.day + 2, 18, 30),
    totalPrice: 12499,
    status: status,
    unlockPasscode: 'PASS-7982',
    createdAt: DateTime.now(),
    customerName: 'Rina Chatterjee Mukherjee',
    customerPhone: '+91 98300 12345',
    pickupLocation: 'Hill Cart Road, Siliguri',
  );
}

class _ScanAppState extends AppState {
  final _bookings = [
    _booking('b_pend', 'Pending', 3),
    _booking('b_conf', 'Confirmed', 5),
    _booking('b_actv', 'Active', 0),
    _booking('b_done', 'Completed', -6),
    _booking('b_rej', 'Rejected', 8),
  ];
  @override
  List<Booking> get activeBookings => _bookings;
  @override
  List<Vehicle> get vehicles => _vehicles;
  @override
  Vehicle? get selectedVehicle => _vehicles.first;
}

Future<void> _loadFonts() async {
  final root = '${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts';
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      final file = File('$root/$f');
      if (file.existsSync()) loader.addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
    }
    await loader.load();
  }

  await load('Roboto', ['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf']);
  await load('MaterialIcons', ['MaterialIcons-Regular.otf']);
}

const _sizes = {
  'phone-360': Size(360, 740),
  'phone-414': Size(414, 896),
  'tablet-768': Size(768, 1024),
  'desktop-1280': Size(1280, 800),
};

final Map<String, Widget Function()> _screens = {
  'MainNavigation': () => const MainNavigationScreen(),
  'Home': () => const HomeScreen(),
  'Discovery': () => const DiscoveryScreen(),
  'VehicleDetail': () => const VehicleDetailScreen(),
  'PaymentCheckout': () => const PaymentCheckoutScreen(),
  'BookingVerification': () => const BookingVerificationScreen(),
  'MyBookings': () => const MyBookingsScreen(),
  'OwnerBookings': () => const OwnerBookingsScreen(),
  'ProviderDashboard': () => const ProviderDashboardScreen(),
  'Earnings': () => const EarningsScreen(),
  'Profile': () => const ProfileScreen(),
  'Favorites': () => const FavoritesScreen(),
  'MessageList': () => const MessageListScreen(),
  'Chat': () => const ChatScreen(),
  'Documents': () => const DocumentsComplianceScreen(),
  'KineticTrust': () => const KineticTrustScreen(),
  'TelematicsHub': () => const TelematicsHubScreen(),
  'RegisterVehicle': () => const RegisterVehicleScreen(),
  'RegisterTour': () => const RegisterTourScreen(),
  'RegisterHotel': () => const RegisterHotelScreen(),
  'Blog': () => const BlogScreen(),
  'AiTripPlanner': () => const AiTripPlannerScreen(),
  'AdminLayout': () => const AdminLayoutScreen(),
  'AdminDashboard': () => const AdminDashboardScreen(),
  'AdminFeeReview': () => const AdminBookingFeeReviewScreen(),
  'FeedbackDashboard': () => const FeedbackDashboardScreen(),
  'TechDocs': () => const TechnicalDocumentationScreen(),
  'ResetPassword': () => const ResetPasswordScreen(),
  'UpdatePassword': () => const UpdatePasswordScreen(),
  'AiTourGenerator': () => const AiTourGeneratorScreen(),
  'AdminBookings': () => const BookingsManagementScreen(),
  'AdminOverview': () => const DashboardOverviewScreen(),
  'AdminFinancials': () => const FinancialsScreen(),
  'AdminPayouts': () => const ProviderPayoutsScreen(),
  'AdminUsers': () => const UsersManagementScreen(),
  'AdminVehicles': () => const VehiclesManagementScreen(),
};

bool _isLayoutError(FlutterErrorDetails d) {
  final s = '${d.exception}';
  if (s.contains('HTTP request failed') || s.contains('NetworkImage') || s.contains('SocketException') ||
      s.contains('Connection') || s.contains('PostgrestException') || s.contains('AuthException')) {
    return false;
  }
  return s.contains('overflowed') ||
      s.contains('unbounded') ||
      s.contains('BoxConstraints') ||
      s.contains('RenderBox was not laid out') ||
      s.contains('Incorrect use of ParentDataWidget') ||
      s.contains('has no size');
}

String _summary(FlutterErrorDetails d) {
  final s = '${d.exception}'.split('\n').first;
  // The overflow report names the widget's source location; keep it.
  final where = RegExp(r'lib/([\w/]+\.dart):(\d+)').firstMatch(d.toString());
  return where == null ? s : '$s  @ lib/${where.group(1)}:${where.group(2)}';
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    UrlLauncherPlatform.instance = _FakeLauncher();
    await _loadFonts();
    try {
      await Supabase.initialize(url: 'https://example.supabase.co', publishableKey: 'test-key');
    } catch (_) {}
  });

  for (final screen in _screens.entries) {
    for (final size in _sizes.entries) {
      testWidgets('${screen.key} @ ${size.key}', (tester) async {
        tester.view.physicalSize = size.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final problems = <String>{};
        final previous = FlutterError.onError;
        FlutterError.onError = (d) {
          if (_isLayoutError(d)) problems.add(_summary(d));
        };
        try {
          await tester.pumpWidget(TranslationProvider(
            child: MultiProvider(
              providers: [
                ChangeNotifierProvider<AppState>(create: (_) => _ScanAppState()),
                ChangeNotifierProvider(create: (_) => LanguageProvider()),
              ],
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: ThemeData(fontFamily: 'Roboto', useMaterial3: true),
                home: Scaffold(body: screen.value()),
              ),
            ),
          ));
          for (var i = 0; i < 4; i++) {
            await tester.pump(const Duration(milliseconds: 250));
          }
          // Exceptions thrown outside FlutterError.onError (e.g. during build).
          final ex = tester.takeException();
          if (ex != null && '$ex'.contains('overflow')) problems.add('$ex'.split('\n').first);
        } finally {
          FlutterError.onError = previous;
          await tester.pumpWidget(const SizedBox());
        }
        if (problems.isNotEmpty) {
          // ignore: avoid_print
          print('LAYOUT ${screen.key} @ ${size.key}:\n  - ${problems.join('\n  - ')}');
        }
        expect(problems, isEmpty, reason: problems.join('\n'));
      });
    }
  }
}
