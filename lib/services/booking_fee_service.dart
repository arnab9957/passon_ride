import 'dart:typed_data';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Server-defined ₹10 booking fee paid via UPI. Every state change happens in
/// the `upi-booking-fee` edge function; this client only reads and requests.
class BookingFeePayment {
  final String id;
  final String paymentRef;
  final String bookingKind;
  final String bookingId;
  final double amount;
  final String status; // PENDING | SUBMITTED | SUCCESS | FAILED | EXPIRED | REFUND_PENDING | REFUNDED
  final String payeeVpa;
  final String utr;
  final String failureReason;
  final String userId;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final String screenshotUrl; // admin only (signed URL)
  final String verificationMethod; // 'ocr_auto' | 'admin' | ''
  final List<ScreenshotCheck> checks;

  const BookingFeePayment({
    required this.id,
    required this.paymentRef,
    required this.bookingKind,
    required this.bookingId,
    required this.amount,
    required this.status,
    required this.payeeVpa,
    required this.utr,
    required this.failureReason,
    required this.userId,
    required this.createdAt,
    this.expiresAt,
    this.screenshotUrl = '',
    this.verificationMethod = '',
    this.checks = const [],
  });

  factory BookingFeePayment.fromMap(Map<String, dynamic> m) => BookingFeePayment(
        id: '${m['id']}',
        paymentRef: '${m['payment_ref'] ?? ''}',
        bookingKind: '${m['booking_kind'] ?? ''}',
        bookingId: '${m['booking_id'] ?? ''}',
        amount: double.tryParse('${m['amount']}') ?? 10,
        status: '${m['payment_status'] ?? 'PENDING'}',
        payeeVpa: '${m['payee_vpa'] ?? ''}',
        utr: '${m['utr'] ?? ''}',
        failureReason: '${m['failure_reason'] ?? ''}',
        userId: '${m['user_id'] ?? ''}',
        createdAt: DateTime.tryParse('${m['created_at']}') ?? DateTime.now(),
        expiresAt: DateTime.tryParse('${m['expires_at']}'),
        screenshotUrl: '${m['screenshot_url'] ?? ''}',
        verificationMethod: '${m['verification_method'] ?? ''}',
        checks: ScreenshotCheck.listFrom(m['verification']),
      );

  bool get isPaid => status == 'SUCCESS';
  bool get isFinal => const {'SUCCESS', 'REFUNDED'}.contains(status);
}

/// One rule checked against the OCR text of a payment screenshot.
class ScreenshotCheck {
  final String key;
  final String label;
  final bool ok;
  final String detail;
  const ScreenshotCheck({required this.key, required this.label, required this.ok, required this.detail});

  static List<ScreenshotCheck> listFrom(dynamic report) {
    final list = report is Map ? report['checks'] : null;
    if (list is! List) return const [];
    return [
      for (final c in list)
        if (c is Map)
          ScreenshotCheck(
            key: '${c['key'] ?? ''}',
            label: '${c['label'] ?? ''}',
            ok: c['ok'] == true,
            detail: '${c['detail'] ?? ''}',
          ),
    ];
  }
}

class BookingFeeService {
  BookingFeeService._();
  static final instance = BookingFeeService._();

  SupabaseClient get _db => Supabase.instance.client;

  Future<Map<String, dynamic>> _call(Map<String, dynamic> body) async {
    final res = await _db.functions.invoke('upi-booking-fee', body: body);
    final data = res.data is Map ? Map<String, dynamic>.from(res.data as Map) : <String, dynamic>{};
    if (res.status >= 400 || data['error'] != null) {
      throw Exception(data['error'] ?? 'Payment service error (${res.status})');
    }
    return data;
  }

  /// Creates (or reuses) the fee payment for a booking. Returns payment + upi:// URI.
  Future<(BookingFeePayment, String)> create({required String bookingKind, required String bookingId}) async {
    final d = await _call({'action': 'create', 'booking_kind': bookingKind, 'booking_id': bookingId});
    return (BookingFeePayment.fromMap(Map<String, dynamic>.from(d['payment'] as Map)), '${d['upi_uri']}');
  }

  Future<BookingFeePayment> submitUtr(String paymentId, String utr) async {
    final d = await _call({'action': 'submit_utr', 'payment_id': paymentId, 'utr': utr});
    return BookingFeePayment.fromMap(Map<String, dynamic>.from(d['payment'] as Map));
  }

  /// Uploads a payment screenshot; the server OCRs it and auto-confirms when every check passes.
  Future<(BookingFeePayment, List<ScreenshotCheck>)> submitScreenshot(
      String paymentId, Uint8List bytes, String mime) async {
    final d = await _call({
      'action': 'submit_screenshot',
      'payment_id': paymentId,
      'mime': mime,
      'image_base64': base64Encode(bytes),
    });
    return (
      BookingFeePayment.fromMap(Map<String, dynamic>.from(d['payment'] as Map)),
      ScreenshotCheck.listFrom(d['report']),
    );
  }

  Future<BookingFeePayment> status(String paymentId) async {
    final d = await _call({'action': 'status', 'payment_id': paymentId});
    return BookingFeePayment.fromMap(Map<String, dynamic>.from(d['payment'] as Map));
  }

  /// Live updates for one payment (falls back to [status] polling in the UI).
  Stream<BookingFeePayment> watch(String paymentId) => _db
      .from('booking_fee_payments')
      .stream(primaryKey: ['id'])
      .eq('id', paymentId)
      .where((rows) => rows.isNotEmpty)
      .map((rows) => BookingFeePayment.fromMap(rows.first));

  // ---------------- admin ----------------
  Future<List<BookingFeePayment>> pendingForReview() async {
    final d = await _call({'action': 'pending'});
    return [for (final m in (d['payments'] as List? ?? [])) BookingFeePayment.fromMap(Map<String, dynamic>.from(m as Map))];
  }

  Future<void> review(String paymentId, {required bool approve, String? reason}) =>
      _call({'action': 'review', 'payment_id': paymentId, 'decision': approve ? 'approve' : 'reject', 'reason': ?reason});

  Future<void> refund(String paymentId, {required String reason, String reference = ''}) =>
      _call({'action': 'refund', 'payment_id': paymentId, 'reason': reason, 'reference': reference});
}
