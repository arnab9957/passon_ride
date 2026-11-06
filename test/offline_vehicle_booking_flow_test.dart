// Drives the provider's "Onboard Offline / Walk-in Customer" dialog for a vehicle:
// receiving/returning date+time, Rent + Advance, then Next -> Overview -> Total -> Payment.
// The picker platform packages come in via image_picker; they're only needed to fake the camera.
// ignore_for_file: depend_on_referenced_packages
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:intl/intl.dart';
import 'package:passon_ride/models/models.dart';
import 'package:passon_ride/providers/app_state.dart';
import 'package:passon_ride/widgets/record_offline_booking_dialog.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 1x1 transparent PNG.
final _png = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, //
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);

/// Camera / gallery stand-in: every pick returns the 1x1 PNG.
class _FakeImagePicker extends ImagePickerPlatform with MockPlatformInterfaceMixin {
  @override
  Future<XFile?> getImageFromSource({required ImageSource source, ImagePickerOptions options = const ImagePickerOptions()}) async =>
      XFile.fromData(_png, name: 'photo.png', mimeType: 'image/png');
}

/// Captures what the dialog saves instead of uploading / writing to Supabase.
class _RecordingAppState extends AppState {
  Map<String, Object?>? saved;

  @override
  Future<void> createOfflineBooking({
    required String bookingType,
    required String itemId,
    required String itemTitle,
    required String itemImageUrl,
    required String customerName,
    required String customerPhone,
    String customerEmail = '',
    String customerIdNumber = '',
    required DateTime startDate,
    required DateTime endDate,
    required double totalPrice,
    double rentAmount = 0.0,
    double advanceAmount = 0.0,
    String notes = '',
    String stayRoomType = 'Standard Room',
    int guestCount = 1,
    String paymentMethod = 'Cash / Direct',
    Uint8List? renterPhotoBytes,
    Uint8List? idDocumentBytes,
    Uint8List? handoverPhotoBytes,
    Uint8List? idProofBytes,
    Uint8List? itemPhotoBytes,
  }) async {
    saved = {
      'bookingType': bookingType,
      'itemId': itemId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'startDate': startDate,
      'endDate': endDate,
      'totalPrice': totalPrice,
      'rentAmount': rentAmount,
      'advanceAmount': advanceAmount,
      'paymentMethod': paymentMethod,
      'renterPhoto': renterPhotoBytes != null,
      'idDocument': idDocumentBytes != null,
      'handoverPhoto': handoverPhotoBytes != null,
      'idProof': idProofBytes != null,
    };
  }
}

Vehicle _vehicle() => Vehicle.fromMap({
      'id': 'veh_test_1',
      'title': 'Royal Enfield Hunter 350',
      'category': 'Motorcycle',
      'type': 'Cruiser',
      'price_per_day': 1200.0,
      'rating': 4.8,
      'review_count': 10,
      'image_url': '',
      'location': 'Park Street',
      'host_name': 'Test Host',
      'host_avatar': '',
      'host_trust_score': 98.0,
      'host_id': 'host_1',
      'fuel_type': 'Petrol',
      'transmission': 'Manual',
      'seats': 2,
      'description': 'Clean bike',
      'iot_data': {'battery': 95},
    });

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    try {
      await Supabase.initialize(
        url: 'https://gxqlsogewjjkcdetubuv.supabase.co',
        publishableKey: 'sb_publishable_b1WyefoA--KuuAfVlDjMaw_iFLBj8Hk',
      );
    } catch (_) {}
    ImagePickerPlatform.instance = _FakeImagePicker();
  });

  Future<void> tapVisible(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  testWidgets('vehicle walk-in booking: date+time, rent/advance, overview, total, payment', (tester) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final appState = _RecordingAppState();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (ctx) => Center(
            child: ElevatedButton(
              onPressed: () => RecordOfflineBookingDialog.show(ctx, appState, vehicles: [_vehicle()], hotels: [], tours: []),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // ---- 1. Receiving / returning date + time ----
    expect(find.text('RECEIVING & RETURNING'), findsOneWidget);
    expect(find.text('Receiving'), findsOneWidget);
    expect(find.text('Returning'), findsOneWidget);
    // Old single "Total ₹" box is gone for vehicles.
    expect(find.text('Total ₹ *'), findsNothing);
    // Each tile shows a time (hh:mm AM/PM).
    expect(find.textContaining(RegExp(r'^\d{2}:\d{2} (AM|PM)$')), findsNWidgets(2));

    // Pick the vehicle -> rent auto-fills for 1 day.
    await tapVisible(tester, find.text('Select your vehicle'));
    await tapVisible(tester, find.textContaining('Royal Enfield Hunter 350').last);
    final rentField = find.widgetWithText(TextFormField, 'Rent *');
    final advanceField = find.widgetWithText(TextFormField, 'Advance');
    expect(rentField, findsOneWidget, reason: 'Rent field present');
    expect(advanceField, findsOneWidget, reason: 'Advance field present');
    expect(tester.widget<TextFormField>(rentField).controller!.text, '1200');

    // Move the return date one day later via the picker: date picker, then time picker.
    final returnTileDate = find.text(DateFormat('dd MMM yyyy').format(DateTime.now().add(const Duration(days: 1))));
    await tapVisible(tester, returnTileDate);
    expect(find.byType(DatePickerDialog), findsOneWidget, reason: 'date picker opens');
    final newReturn = DateTime.now().add(const Duration(days: 2));
    await tester.tap(find.byIcon(Icons.edit_outlined).evaluate().isNotEmpty ? find.byIcon(Icons.edit_outlined) : find.byIcon(Icons.edit));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, DateFormat('MM/dd/yyyy').format(newReturn));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.byType(TimePickerDialog), findsOneWidget, reason: 'time picker opens after the date');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text(DateFormat('dd MMM yyyy').format(newReturn)), findsOneWidget);
    expect(tester.widget<TextFormField>(rentField).controller!.text, '2400', reason: 'rent recalculated for 2 days');
    expect(find.textContaining('billed as 2 days'), findsOneWidget);

    // ---- 2. Advance ----
    await tester.enterText(advanceField, '500');
    await tester.pumpAndSettle();

    // ---- 3. Next is blocked until required details + documents are in ----
    await tapVisible(tester, find.text('Next'));
    expect(find.text('BOOKING OVERVIEW'), findsNothing, reason: 'missing name/phone keeps us on Details');

    await tester.enterText(find.widgetWithText(TextFormField, 'Customer Full Name *'), 'Asha Roy');
    await tester.enterText(find.widgetWithText(TextFormField, 'Phone Number *'), '9800000000');
    await tester.pumpAndSettle();

    await tapVisible(tester, find.text('Next'));
    expect(find.text('BOOKING OVERVIEW'), findsNothing, reason: 'missing documents keeps us on Details');
    expect(find.text("Please take the renter's current photo"), findsOneWidget);
    ScaffoldMessenger.of(tester.element(find.byType(RecordOfflineBookingDialog))).clearSnackBars();
    await tester.pumpAndSettle();

    // Documents section is connected: renter photo, DL, Aadhaar/passport, renter with vehicle.
    expect(find.text('Renter Documents & Photo'), findsOneWidget);
    for (var i = 0; i < 4; i++) {
      await tapVisible(tester, find.text('Camera').first);
    }
    expect(find.text('Camera'), findsNothing);
    expect(find.text('Retake'), findsNWidgets(4));

    // Overview
    await tapVisible(tester, find.text('Next'));
    expect(find.text('BOOKING OVERVIEW'), findsOneWidget);
    expect(find.text('Royal Enfield Hunter 350'), findsOneWidget);
    expect(find.text('Asha Roy'), findsOneWidget);
    expect(find.text('Receiving & Returning'), findsOneWidget);
    expect(find.text('₹2,400'), findsOneWidget, reason: 'rent');
    expect(find.text('₹500'), findsOneWidget, reason: 'advance');
    expect(find.text('₹2,900'), findsOneWidget, reason: 'total');
    expect(find.text('Documents & Photos'), findsOneWidget);

    // Total payable
    await tapVisible(tester, find.text('Next'));
    expect(find.text('TOTAL PAYABLE AMOUNT'), findsOneWidget);
    expect(find.text('₹2,900'), findsNWidgets(2), reason: 'big display + breakdown');

    // Back works, then forward again.
    await tapVisible(tester, find.text('Back'));
    expect(find.text('BOOKING OVERVIEW'), findsOneWidget);
    await tapVisible(tester, find.text('Next'));

    // Payment method
    await tapVisible(tester, find.text('Choose Payment Method'));
    expect(find.text('SELECT PAYMENT METHOD'), findsOneWidget);
    for (final m in ['Cash', 'UPI', 'Card (POS)', 'Bank Transfer', 'Pay at Return']) {
      expect(find.text(m), findsOneWidget, reason: 'payment option $m');
    }
    await tapVisible(tester, find.text('UPI'));
    await tapVisible(tester, find.text('Confirm Booking'));

    // ---- What was saved ----
    final s = appState.saved;
    expect(s, isNotNull, reason: 'booking was saved');
    expect(s!['bookingType'], 'vehicle');
    expect(s['itemId'], 'veh_test_1');
    expect(s['rentAmount'], 2400.0);
    expect(s['advanceAmount'], 500.0);
    expect(s['totalPrice'], 2900.0);
    expect(s['paymentMethod'], 'UPI / GPay / PhonePe');
    final start = s['startDate'] as DateTime, end = s['endDate'] as DateTime;
    expect(end.isAfter(start), isTrue);
    expect(DateTime(end.year, end.month, end.day), DateTime(newReturn.year, newReturn.month, newReturn.day));
    expect(start.second, 0, reason: 'times are stored to the minute');
    expect([s['renterPhoto'], s['idDocument'], s['handoverPhoto'], s['idProof']], everyElement(isTrue));
    expect(find.byType(RecordOfflineBookingDialog), findsNothing, reason: 'dialog closes after confirm');
  });

  test('Booking keeps rent, advance and payment method through toMap/fromMap', () {
    final b = Booking(
      id: 'bk_1',
      vehicleId: 'v1',
      vehicleTitle: 'Bike',
      vehicleImageUrl: '',
      hostName: 'Host',
      userId: 'u1',
      hostId: 'h1',
      accountId: 'u1',
      accountName: 'Host',
      accountType: 'host',
      startDate: DateTime(2026, 11, 5, 10, 30),
      endDate: DateTime(2026, 11, 7, 18, 15),
      totalPrice: 2900,
      status: 'Active',
      unlockPasscode: '',
      paymentIntentId: '',
      createdAt: DateTime(2026, 11, 5),
      rentAmount: 2400,
      advanceAmount: 500,
      paymentMethod: 'Cash',
    );
    final r = Booking.fromMap(b.toMap());
    expect(r.rentAmount, 2400);
    expect(r.advanceAmount, 500);
    expect(r.paymentMethod, 'Cash');
    expect(r.startDate, DateTime(2026, 11, 5, 10, 30));
    expect(r.endDate, DateTime(2026, 11, 7, 18, 15));
  });
}
