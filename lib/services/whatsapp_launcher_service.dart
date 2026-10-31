import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Service responsible for launching WhatsApp conversations between hosts and customers.
class WhatsAppLauncherService {
  /// Default platform fallback WhatsApp number when host hasn't registered a phone number yet
  static const String defaultPlatformWhatsAppNumber = '+917890738917';
  static const String defaultPlatformWhatsAppDisplay = '+91 78907 38917';
  static const String defaultPlatformCleanWhatsApp = '917890738917';

  // Backward compatibility aliases
  static const String hostCustomerWhatsAppNumber = defaultPlatformWhatsAppNumber;
  static const String hostCustomerWhatsAppDisplay = defaultPlatformWhatsAppDisplay;
  static const String cleanWhatsAppNumber = defaultPlatformCleanWhatsApp;

  /// True when [rawPhone] is a real contact number rather than blank or sample data.
  static bool isUsablePhone(String? rawPhone) {
    final digits = (rawPhone ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length >= 10 && !digits.endsWith('9876543210');
  }

  /// Cleans and formats any user phone number to standard international dial without symbols
  static String formatCleanPhone(String? rawPhone) {
    if (rawPhone == null) return defaultPlatformCleanWhatsApp;
    String digits = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return defaultPlatformCleanWhatsApp;
    // If standard 10-digit Indian mobile number, add 91 country prefix
    if (digits.length == 10) {
      digits = '91$digits';
    }
    return digits;
  }

  /// Formats phone number into user-friendly display string (e.g. +91 98765 43210)
  static String formatDisplayPhone(String? rawPhone) {
    if (rawPhone != null && !isUsablePhone(rawPhone)) return 'Number not shared yet';
    final clean = formatCleanPhone(rawPhone);
    if (clean.length == 12 && clean.startsWith('91')) {
      final code = clean.substring(0, 2);
      final p1 = clean.substring(2, 7);
      final p2 = clean.substring(7);
      return '+$code $p1 $p2';
    } else if (clean.length == 10) {
      return '+91 ${clean.substring(0, 5)} ${clean.substring(5)}';
    }
    return rawPhone?.trim().isNotEmpty == true ? rawPhone!.trim() : defaultPlatformWhatsAppDisplay;
  }

  /// Generates the standard WhatsApp wa.me URL
  static Uri getWhatsAppUri({String? message, String? phoneNumber}) {
    final phone = formatCleanPhone(phoneNumber);
    final trimmedMsg = message?.trim();
    if (trimmedMsg != null && trimmedMsg.isNotEmpty) {
      return Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(trimmedMsg)}');
    }
    return Uri.parse('https://wa.me/$phone');
  }

  /// Launches WhatsApp with the given [message] and target [phoneNumber] (seller's mobile number).
  ///
  /// Uses [LaunchMode.externalApplication] so it opens native WhatsApp on iOS/Android/Desktop,
  /// or WhatsApp Web on desktop browsers / Linux.
  ///
  /// A null [phoneNumber] means platform support. A blank one means the person has no
  /// number, so this returns false rather than messaging support by mistake.
  static Future<bool> launchWhatsApp({
    String? message,
    String? phoneNumber,
  }) async {
    if (phoneNumber != null && !isUsablePhone(phoneNumber)) return false;

    final primaryUri = getWhatsAppUri(message: message, phoneNumber: phoneNumber);
    final phone = formatCleanPhone(phoneNumber);
    final query = (message != null && message.trim().isNotEmpty)
        ? '&text=${Uri.encodeComponent(message.trim())}'
        : '';

    try {
      final launched = await launchUrl(
        primaryUri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) return true;

      // Fallback 1: Direct native scheme
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
