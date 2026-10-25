import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Service responsible for launching WhatsApp conversations between hosts and customers.
class WhatsAppLauncherService {
  /// The official WhatsApp number for host-customer communication
  static const String hostCustomerWhatsAppNumber = '+917890738917';
  static const String hostCustomerWhatsAppDisplay = '+91 78907 38917';
  static const String cleanWhatsAppNumber = '917890738917';

  /// Generates the standard WhatsApp wa.me URL
  static Uri getWhatsAppUri({String? message, String? phoneNumber}) {
    final phone = (phoneNumber != null && phoneNumber.trim().isNotEmpty)
        ? phoneNumber.replaceAll(RegExp(r'[^0-9]'), '')
        : cleanWhatsAppNumber;

    final trimmedMsg = message?.trim();
    if (trimmedMsg != null && trimmedMsg.isNotEmpty) {
      return Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(trimmedMsg)}');
    }
    return Uri.parse('https://wa.me/$phone');
  }

  /// Launches WhatsApp with the given [message] and target [phoneNumber] (defaults to +917890738917).
  ///
  /// Uses [LaunchMode.externalApplication] so it opens native WhatsApp on iOS/Android/Desktop,
  /// or WhatsApp Web on desktop browsers / Linux.
  static Future<bool> launchWhatsApp({
    String? message,
    String? phoneNumber,
  }) async {
    final primaryUri = getWhatsAppUri(message: message, phoneNumber: phoneNumber);

    try {
      final launched = await launchUrl(
        primaryUri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) return true;

      // Fallback 1: Direct native scheme
      final phone = (phoneNumber != null && phoneNumber.trim().isNotEmpty)
          ? phoneNumber.replaceAll(RegExp(r'[^0-9]'), '')
          : cleanWhatsAppNumber;
      final query = (message != null && message.trim().isNotEmpty)
          ? '&text=${Uri.encodeComponent(message.trim())}'
          : '';
      final nativeUri = Uri.parse('whatsapp://send?phone=$phone$query');

      if (await canLaunchUrl(nativeUri)) {
        return await launchUrl(nativeUri, mode: LaunchMode.externalApplication);
      }

      // Fallback 2: api.whatsapp.com
      final apiUri = Uri.parse('https://api.whatsapp.com/send?phone=$phone$query');
      return await launchUrl(apiUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('[WhatsAppLauncherService] Failed to launch WhatsApp URL: $e');
      return false;
    }
  }
}

