import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'whatsapp_launcher_service.dart';

/// Automated WhatsApp messaging service for PassionRide.
///
/// Features:
/// 1. Server-side automated notifications via Supabase Edge Function (`send-whatsapp-notification`)
///    using the official Meta WhatsApp Cloud API.
/// 2. Client-side fallback to native WhatsApp URL launcher if API token is pending or unreachable.
class WhatsAppAutomationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Sends automated booking confirmation to the renter via Meta Cloud API.
  Future<bool> sendBookingConfirmation({
    required String recipientPhone,
    required String renterName,
    required String vehicleName,
    required String bookingId,
    required double totalAmount,
    required String pickupDate,
    required String hostContact,
  }) async {
    final cleanPhone = WhatsAppLauncherService.formatCleanPhone(recipientPhone);

    try {
      final response = await _supabase.functions.invoke(
        'send-whatsapp-notification',
        body: {
          'recipientPhone': cleanPhone,
          'templateName': 'booking_confirmation_v1',
          'templateLanguage': 'en_US',
          'parameters': [
            renterName,
            vehicleName,
            bookingId,
            totalAmount.toStringAsFixed(0),
            pickupDate,
            hostContact,
          ],
        },
      );

      final data = response.data;
      if (response.status == 200 && data != null && data['success'] == true) {
        debugPrint('[WhatsAppAutomation] Booking confirmation sent to $cleanPhone (ID: ${data['messageId']})');
        return true;
      } else {
        debugPrint('[WhatsAppAutomation] Cloud API warning: ${data?['error']}');
      }
    } catch (e) {
      debugPrint('[WhatsAppAutomation] Edge function invocation error: $e');
    }

    return false;
  }

  /// Sends alert to Host when their vehicle receives a new booking.
  Future<bool> sendHostNewBookingAlert({
    required String hostPhone,
    required String hostName,
    required String renterName,
    required String vehicleName,
    required String pickupDate,
    required double earnings,
  }) async {
    final cleanPhone = WhatsAppLauncherService.formatCleanPhone(hostPhone);

    try {
      final response = await _supabase.functions.invoke(
        'send-whatsapp-notification',
        body: {
          'recipientPhone': cleanPhone,
          'templateName': 'host_new_booking_alert',
          'templateLanguage': 'en_US',
          'parameters': [
            hostName,
            renterName,
            vehicleName,
            pickupDate,
            earnings.toStringAsFixed(0),
          ],
        },
      );

      final data = response.data;
      return response.status == 200 && data != null && data['success'] == true;
    } catch (e) {
      debugPrint('[WhatsAppAutomation] Error sending host alert: $e');
      return false;
    }
  }

  /// Fallback helper: opens WhatsApp chat directly with a pre-filled message on device
  Future<bool> openWhatsAppDirectFallback({
    required String recipientPhone,
    required String message,
  }) async {
    return await WhatsAppLauncherService.launchWhatsApp(
      phoneNumber: recipientPhone,
      message: message,
    );
  }
}
