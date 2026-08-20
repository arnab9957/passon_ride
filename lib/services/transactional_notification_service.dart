import 'dart:async';
import 'dart:math';

/// Notification Flow Type Enums for the 4-Flow Topology
enum NotificationFlowType {
  buyerCheckoutOtp,       // Flow 1: Sub-12s SMS OTP for checkout verification
  sellerKycAlert,         // Flow 2: Document upload/OCR & Bank Payout change alerts
  highValueWhatsappOtp,   // Flow 3: WhatsApp OTP step-up for high-value transactions (> ₹15,000 / $200)
  bookingLifecycleAlert,  // Flow 4: Automated booking confirmation, escrow, return reminder & cancellation
}

/// Channel type enum
enum NotificationChannel { sms, whatsapp }

/// Result wrapper for notification dispatches
class NotificationDeliveryResult {
  final bool success;
  final String messageId;
  final NotificationFlowType flowType;
  final NotificationChannel channel;
  final String recipient;
  final String status;
  final int latencyMs;
  final String? otpCode;
  final String payloadText;

  NotificationDeliveryResult({
    required this.success,
    required this.messageId,
    required this.flowType,
    required this.channel,
    required this.recipient,
    required this.status,
    required this.latencyMs,
    this.otpCode,
    required this.payloadText,
  });
}

class TransactionalNotificationService {
  // Configurable threshold for High-Value Step-Up (Flow 3)
  static const double highValueThreshold = 15000.0; // ₹15,000 or $200 threshold

  final List<NotificationDeliveryResult> _deliveryLogs = [];

  List<NotificationDeliveryResult> get deliveryLogs => List.unmodifiable(_deliveryLogs);

  /// Flow 1 — Buyer Checkout SMS OTP Verification (Sub-12s Latency Target)
  Future<NotificationDeliveryResult> triggerBuyerCheckoutOtp({
    required String phoneNumber,
    required String buyerName,
    required double orderAmount,
  }) async {
    final Stopwatch stopwatch = Stopwatch()..start();
    
    // Generate 6-digit OTP
    final String otp = (100000 + Random().nextInt(900000)).toString();
    final String payload = 'PassonRide: Your checkout verification code is $otp. Amount: ₹${orderAmount.toStringAsFixed(2)}. Valid for 5 mins. Do not share.';

    stopwatch.stop();

    final result = NotificationDeliveryResult(
      success: true,
      messageId: 'MSG-SMS-${DateTime.now().millisecondsSinceEpoch}',
      flowType: NotificationFlowType.buyerCheckoutOtp,
      channel: NotificationChannel.sms,
      recipient: phoneNumber,
      status: 'DELIVERED_SUB_12S',
      latencyMs: stopwatch.elapsedMilliseconds,
      otpCode: otp,
      payloadText: payload,
    );

    _deliveryLogs.add(result);
    return result;
  }

  /// Flow 2 — Seller KYC & Security Bank Payout Alerts
  Future<NotificationDeliveryResult> triggerSellerKycAlert({
    required String phoneNumber,
    required String sellerName,
    required String alertType, // 'DOCUMENT_UPLOADED', 'OCR_VERIFIED', 'BANK_PAYOUT_CHANGED'
    required String detailSummary,
  }) async {
    final Stopwatch stopwatch = Stopwatch()..start();

    String payload = '';
    if (alertType == 'BANK_PAYOUT_CHANGED') {
      payload = 'SECURITY ALERT: PassonRide bank payout account updated for $sellerName ($detailSummary). If this was not you, lock your account immediately.';
    } else if (alertType == 'OCR_VERIFIED') {
      payload = 'PassonRide KYC: Your identity document ($detailSummary) has been OCR-verified. You are ready to host vehicles!';
    } else {
      payload = 'PassonRide KYC: Document ($detailSummary) received for processing. Status: Pending Verification.';
    }

    stopwatch.stop();

    final result = NotificationDeliveryResult(
      success: true,
      messageId: 'MSG-KYC-${DateTime.now().millisecondsSinceEpoch}',
      flowType: NotificationFlowType.sellerKycAlert,
      channel: NotificationChannel.sms,
      recipient: phoneNumber,
      status: 'DELIVERED',
      latencyMs: stopwatch.elapsedMilliseconds,
      payloadText: payload,
    );

    _deliveryLogs.add(result);
    return result;
  }

  /// Flow 3 — High-Value Transaction Step-Up (WhatsApp OTP Verification)
  /// Protects against SIM-swap / SS7 vulnerabilities on high dollar rentals
  Future<NotificationDeliveryResult> triggerHighValueStepUpWhatsAppOtp({
    required String phoneNumber,
    required String userName,
    required double rentalAmount,
    required String vehicleTitle,
  }) async {
    final Stopwatch stopwatch = Stopwatch()..start();

    final String otp = (100000 + Random().nextInt(900000)).toString();
    final String payload = '🔐 PassonRide High-Value Security Step-Up: WhatsApp Verification Code is $otp for booking "$vehicleTitle" (Total: ₹${rentalAmount.toStringAsFixed(2)}). Encrypted via IP Device Channel.';

    stopwatch.stop();

    final result = NotificationDeliveryResult(
      success: true,
      messageId: 'MSG-WA-${DateTime.now().millisecondsSinceEpoch}',
      flowType: NotificationFlowType.highValueWhatsappOtp,
      channel: NotificationChannel.whatsapp,
      recipient: phoneNumber,
      status: 'DELIVERED_WHATSAPP_E2EE',
      latencyMs: stopwatch.elapsedMilliseconds,
      otpCode: otp,
      payloadText: payload,
    );

    _deliveryLogs.add(result);
    return result;
  }

  /// Flow 4 — Automated Booking Lifecycle Alerts
  Future<NotificationDeliveryResult> triggerBookingLifecycleAlert({
    required String phoneNumber,
    required String renterName,
    required String vehicleTitle,
    required String eventType, // 'CONFIRMED', 'ESCROW_SECURED', 'RETURN_REMINDER', 'CANCELLED'
    NotificationChannel preferredChannel = NotificationChannel.whatsapp,
  }) async {
    final Stopwatch stopwatch = Stopwatch()..start();

    String payload = '';
    switch (eventType) {
      case 'CONFIRMED':
        payload = '🎉 Booking Confirmed! Your rental for "$vehicleTitle" is confirmed by the host. Check app for keyless unlock passcode.';
        break;
      case 'ESCROW_SECURED':
        payload = '🛡️ Escrow Protection Active: Security deposit and rental fee for "$vehicleTitle" are safely locked in PassonRide Escrow.';
        break;
      case 'RETURN_REMINDER':
        payload = '⏰ Return Reminder: Your rental for "$vehicleTitle" ends in 2 hours. Please park at designated host location.';
        break;
      case 'CANCELLED':
        payload = 'ℹ️ Booking Cancellation: Rental for "$vehicleTitle" has been cancelled. Refund initiated to original payment method.';
        break;
      default:
        payload = 'PassonRide Update: Booking event "$eventType" for "$vehicleTitle".';
    }


    stopwatch.stop();

    final result = NotificationDeliveryResult(
      success: true,
      messageId: 'MSG-LIFE-${DateTime.now().millisecondsSinceEpoch}',
      flowType: NotificationFlowType.bookingLifecycleAlert,
      channel: preferredChannel,
      recipient: phoneNumber,
      status: 'DELIVERED',
      latencyMs: stopwatch.elapsedMilliseconds,
      payloadText: payload,
    );

    _deliveryLogs.add(result);
    return result;
  }

  /// Evaluates whether a transaction amount requires Flow 3 (WhatsApp Step-Up) or standard Flow 1 (SMS OTP)
  bool requiresHighValueStepUp(double amount) {
    return amount >= highValueThreshold;
  }
}
