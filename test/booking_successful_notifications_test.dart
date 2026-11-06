// Pay-at-site and offline (walk-in) bookings must say "Booking Successful",
// never "Payment Successful" / "Payment Received", because nothing was paid online.
import 'package:flutter_test/flutter_test.dart';
import 'package:passon_ride/models/models.dart';
import 'package:passon_ride/providers/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _Sent {
  final String? userId;
  final String title;
  final String message;
  final NotificationType type;
  final Map<String, dynamic>? metadata;
  _Sent(this.userId, this.title, this.message, this.type, this.metadata);
}

/// Records notifications instead of saving them.
class _CapturingAppState extends AppState {
  final sent = <_Sent>[];

  @override
  Future<void> addNotification({
    required String title,
    required String message,
    required NotificationType type,
    String? userId,
    String? relatedId,
    String? imageUrl,
    int? actionNavIndex,
    Map<String, dynamic>? metadata,
  }) async {
    sent.add(_Sent(userId, title, message, type, metadata));
  }
}

Tour _tour() => Tour.fromMap({
      'id': 'tour_1',
      'title': 'Darjeeling Heritage Walk',
      'location': 'Chowrasta',
      'price': 750.0,
      'duration': '3 hours',
      'guide_name': 'Test Guide',
      'host_id': 'guide_1',
      'image_url': '',
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
  });

  bool mentionsPayment(_Sent n) =>
      n.title.contains('Payment Successful') || n.title.contains('Payment Received') || n.title.contains('Payout Received');

  test('offline vehicle booking -> provider gets "Booking Successful" with times, rent, advance, method', () async {
    final app = _CapturingAppState();
    await app.createOfflineBooking(
      bookingType: 'vehicle',
      itemId: 'veh_1',
      itemTitle: 'Bajaj Pulsar N25',
      itemImageUrl: '',
      customerName: 'Asha Roy',
      customerPhone: '9800000000',
      startDate: DateTime(2026, 11, 6, 9, 30),
      endDate: DateTime(2026, 11, 7, 18, 0),
      totalPrice: 2900,
      rentAmount: 2400,
      advanceAmount: 500,
      paymentMethod: 'Cash',
    );

    expect(app.sent, hasLength(1));
    final n = app.sent.single;
    expect(n.title, 'Booking Successful ✅');
    expect(n.metadata?['booking_successful'], isTrue);
    expect(n.metadata?['offline'], isTrue);
    expect(n.message, contains('Asha Roy'));
    expect(n.message, contains('Bajaj Pulsar N25'));
    expect(n.message, contains('6/11 09:30 AM to 7/11 06:00 PM'));
    expect(n.message, contains('Total ₹2900.00 (Rent ₹2400.00 + Advance ₹500.00)'));
    expect(n.message, contains('Paid via Cash.'));
  });

  test('offline booking with "Pay at Return" says payment is due', () async {
    final app = _CapturingAppState();
    await app.createOfflineBooking(
      bookingType: 'vehicle',
      itemId: 'veh_1',
      itemTitle: 'Bajaj Pulsar N25',
      itemImageUrl: '',
      customerName: 'Asha Roy',
      customerPhone: '9800000000',
      startDate: DateTime(2026, 11, 6, 9, 30),
      endDate: DateTime(2026, 11, 7, 9, 30),
      totalPrice: 1200,
      rentAmount: 1200,
      paymentMethod: 'Pay at Return / Checkout',
    );
    expect(app.sent.single.message, contains('Payment due at return.'));
    expect(app.sent.single.message, isNot(contains('Paid via')));
  });

  test('pay-at-site tour booking -> "Booking Successful", no payment notifications', () async {
    final app = _CapturingAppState();
    await app.createTourBooking(
      tour: _tour(),
      participantCount: 1,
      totalPrice: 750,
      paymentIntentId: 'pay_at_site_123',
      paymentMethod: 'pay_at_site',
    );

    expect(app.sent.where(mentionsPayment), isEmpty, reason: app.sent.map((n) => n.title).join(' | '));
    final successful = app.sent.where((n) => n.metadata?['booking_successful'] == true).toList();
    expect(successful.map((n) => n.title), containsAll(['Booking Successful ✅', 'Booking Successful: Darjeeling Heritage Walk ✅']));
    expect(successful.first.message, contains('Please pay ₹750.00 at the meeting point'));
  });

  test('online-paid tour booking still sends the payment notifications', () async {
    final app = _CapturingAppState();
    await app.createTourBooking(
      tour: _tour(),
      participantCount: 1,
      totalPrice: 750,
      paymentIntentId: 'pay_razorpay_123',
      paymentMethod: 'razorpay',
    );
    expect(app.sent.map((n) => n.title), contains('Tour Payment Successful 💳'));
    expect(app.sent.where((n) => n.metadata?['booking_successful'] == true), isEmpty);
  });
}
