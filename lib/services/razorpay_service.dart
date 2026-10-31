import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RazorpayOrderResponse {
  final String orderId;
  final int amount; // in paise
  final String currency;
  final String receipt;
  final Map<String, dynamic> notes;

  RazorpayOrderResponse({
    required this.orderId,
    required this.amount,
    required this.currency,
    this.receipt = '',
    this.notes = const {},
  });
}

/// Razorpay client. The key secret lives only in Supabase Edge Functions
/// (create-razorpay-order / verify-razorpay-signature); the app only knows the public key id.
class RazorpayService {
  /// Public key id passed to Razorpay Checkout. Set with --dart-define=RAZORPAY_KEY_ID.
  final String keyId = const String.fromEnvironment('RAZORPAY_KEY_ID', defaultValue: 'rzp_test_TQuIDr91hSpnrx');

  bool get isTestMode => keyId.startsWith('rzp_test_');

  /// Creates an order on the server. Minimum amount: 100 paise (₹1.00).
  /// Throws if the order can't be created; never invents a local order id.
  Future<RazorpayOrderResponse> createOrder({
    required double amountInRupees,
    String? receipt,
    Map<String, dynamic>? notes,
  }) async {
    final int amountInPaise = (amountInRupees * 100).round();
    if (amountInPaise < 100) {
      throw Exception('Invalid amount: minimum 100 paise (₹1.00) required.');
    }

    final String orderReceipt = receipt ?? 'rcpt_${DateTime.now().millisecondsSinceEpoch}';
    final Map<String, dynamic> orderNotes = notes ?? {};

    final response = await Supabase.instance.client.functions.invoke(
      'create-razorpay-order',
      body: {
        'amount': amountInPaise,
        'currency': 'INR',
        'receipt': orderReceipt,
        'notes': orderNotes,
      },
    );

    final data = response.data is Map ? response.data as Map : jsonDecode(response.data.toString()) as Map;
    if (response.status != 200 || data['id'] == null) {
      throw Exception(data['error']?.toString() ?? 'Could not create payment order');
    }

    return RazorpayOrderResponse(
      orderId: data['id'].toString(),
      amount: (data['amount'] as num?)?.toInt() ?? amountInPaise,
      currency: data['currency']?.toString() ?? 'INR',
      receipt: data['receipt']?.toString() ?? orderReceipt,
      notes: orderNotes,
    );
  }

  /// Verifies the payment signature on the server and records the transaction.
  /// Returns false for missing fields, a bad signature, or any server error.
  Future<bool> verifyPayment({
    required String orderId,
    required String paymentId,
    required String razorpaySignature,
    String? bookingId,
    double? amount,
  }) async {
    if (orderId.isEmpty || paymentId.isEmpty || razorpaySignature.isEmpty) return false;
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'verify-razorpay-signature',
        body: {
          'order_id': orderId,
          'payment_id': paymentId,
          'signature': razorpaySignature,
          'booking_id': ?bookingId,
          'amount': ?amount,
        },
      );
      final data = response.data is Map ? response.data as Map : jsonDecode(response.data.toString()) as Map;
      return response.status == 200 && data['verified'] == true;
    } catch (e) {
      debugPrint('Razorpay verifyPayment error: $e');
      return false;
    }
  }
}
