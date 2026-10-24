import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Service responsible for launching WhatsApp conversations between hosts and customers.
class WhatsAppLauncherService {
  // Default / Central Support Number
  static const String hostCustomerWhatsAppNumber = '+917890738917';
  static const String hostCustomerWhatsAppDisplay = '+91 78907 38917';
  static const String cleanWhatsAppNumber = '917890738917';

  // Puri Adventure Ride
  static const String puriAdventureWhatsAppNumber = '+919439139828';
  static const String puriAdventureWhatsAppDisplay = '+91 94391 39828';
  static const String cleanPuriAdventureWhatsAppNumber = '919439139828';

  // Bluewaves Rental
  static const String bluewavesWhatsAppNumber = '+919437942828';
  static const String bluewavesWhatsAppDisplay = '+91 94379 42828';
  static const String cleanBluewavesWhatsAppNumber = '919437942828';

  /// Resolves the specific host's WhatsApp phone number based on host/business name.
  /// Matches "Puri adventure ride" -> +919439139828
  /// Matches "Bluewaves rental" -> +919437942828
  /// Fallback -> +917890738917
  static String getWhatsAppNumberForHost(String? hostName, {String? defaultNumber}) {
    if (hostName != null && hostName.trim().isNotEmpty) {
      final lower = hostName.trim().toLowerCase();
      if (lower.contains('puri') || lower.contains('adventure')) {
        return puriAdventureWhatsAppNumber;
      }
      if (lower.contains('bluewave') || lower.contains('blue wave')) {
        return bluewavesWhatsAppNumber;
      }
    }
    return defaultNumber ?? hostCustomerWhatsAppNumber;
  }

  /// Formatted display string for UI (e.g. "+91 94391 39828", "+91 94379 42828")
  static String getWhatsAppDisplayForHost(String? hostName, {String? defaultDisplay}) {
    if (hostName != null && hostName.trim().isNotEmpty) {
      final lower = hostName.trim().toLowerCase();
      if (lower.contains('puri') || lower.contains('adventure')) {
        return puriAdventureWhatsAppDisplay;
      }
      if (lower.contains('bluewave') || lower.contains('blue wave')) {
        return bluewavesWhatsAppDisplay;
      }
    }
    return defaultDisplay ?? hostCustomerWhatsAppDisplay;
  }

  /// Clean digits string without "+" or spaces for wa.me URL
  static String getCleanWhatsAppNumberForHost(String? hostName, {String? defaultNumber}) {
    final raw = getWhatsAppNumberForHost(hostName, defaultNumber: defaultNumber);
    return raw.replaceAll(RegExp(r'[^0-9]'), '');
  }

  /// Generates the standard WhatsApp wa.me URL
  static Uri getWhatsAppUri({String? message, String? phoneNumber, String? hostName}) {
    final phone = (phoneNumber != null && phoneNumber.trim().isNotEmpty)
        ? phoneNumber.replaceAll(RegExp(r'[^0-9]'), '')
        : getCleanWhatsAppNumberForHost(hostName);

    final trimmedMsg = message?.trim();
    if (trimmedMsg != null && trimmedMsg.isNotEmpty) {
      return Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(trimmedMsg)}');
    }
    return Uri.parse('https://wa.me/$phone');
  }

  /// Launches WhatsApp with the given [message] and target [phoneNumber] or [hostName].
  ///
  /// Uses [LaunchMode.externalApplication] so it opens native WhatsApp on iOS/Android/Desktop,
  /// or WhatsApp Web on desktop browsers / Linux.
  static Future<bool> launchWhatsApp({
    String? message,
    String? phoneNumber,
    String? hostName,
  }) async {
    final primaryUri = getWhatsAppUri(message: message, phoneNumber: phoneNumber, hostName: hostName);

    try {
      final launched = await launchUrl(
        primaryUri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) return true;

      // Fallback 1: Direct native scheme
      final phone = (phoneNumber != null && phoneNumber.trim().isNotEmpty)
          ? phoneNumber.replaceAll(RegExp(r'[^0-9]'), '')
          : getCleanWhatsAppNumberForHost(hostName);
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
