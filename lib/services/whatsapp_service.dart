import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/booking_status.dart';
import '../models/models.dart';

/// Result of trying to open WhatsApp. Opening WhatsApp is not sending: the
/// user still has to press Send, so nothing here claims a message was delivered.
enum WhatsAppOpenResult {
  /// WhatsApp (app or web) was opened with the message pre-filled.
  opened,

  /// The recipient has no usable phone number on the booking.
  invalidPhone,

  /// The phone number is fine, but WhatsApp could not be opened on this device.
  unavailable,
}

/// Booking messages via WhatsApp Click-to-Chat (`https://wa.me/<number>?text=…`).
///
/// No WhatsApp Business API and no automatic sending: this only builds the link
/// and opens it. Booking details come from the [Booking] row loaded from Supabase.
class WhatsAppService {
  WhatsAppService({Future<bool> Function(Uri uri)? launcher}) : _launcher = launcher ?? _defaultLaunch;

  final Future<bool> Function(Uri uri) _launcher;

  static Future<bool> _defaultLaunch(Uri uri) => launchUrl(uri, mode: LaunchMode.externalApplication);

  // ---------------------------------------------------------------------------
  // Phone numbers
  // ---------------------------------------------------------------------------

  /// Digits-only international number for wa.me (no `+`), or null if unusable.
  ///
  /// 10-digit Indian mobiles get the 91 country code; a trunk `0` or an
  /// international `00` prefix is removed. Never falls back to another number.
  static String? normalizePhone(String? raw) {
    var digits = (raw ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('00')) digits = digits.substring(2);
    if (digits.length == 11 && digits.startsWith('0')) digits = digits.substring(1);
    if (digits.length == 10) {
      // Indian mobile numbers start with 6-9.
      if (!RegExp(r'^[6-9]').hasMatch(digits)) return null;
      digits = '91$digits';
    }
    if (digits.length == 12 && digits.startsWith('91') && !RegExp(r'^91[6-9]').hasMatch(digits)) {
      return null;
    }
    // E.164: at most 15 digits; shortest real international numbers are ~11.
    if (digits.length < 11 || digits.length > 15) return null;
    // Sample data used across the app.
    if (digits.endsWith('9876543210')) return null;
    return digits;
  }

  static Uri buildUri(String phoneDigits, String message) =>
      Uri.parse('https://wa.me/$phoneDigits?text=${Uri.encodeComponent(message)}');

  // ---------------------------------------------------------------------------
  // Formatting
  // ---------------------------------------------------------------------------

  /// Pickup / return times are shown in the vehicle's time zone. PassionRide
  /// vehicles are in India (vehicles.timezone defaults to Asia/Kolkata), so
  /// times are converted to IST regardless of the phone's own time zone.
  static DateTime toVehicleLocal(DateTime t) => t.toUtc().add(const Duration(hours: 5, minutes: 30));

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  static String formatDate(DateTime t) {
    final l = toVehicleLocal(t);
    return '${l.day.toString().padLeft(2, '0')} ${_months[l.month - 1]} ${l.year}';
  }

  static String formatTime(DateTime t) {
    final l = toVehicleLocal(t);
    final h = l.hour % 12 == 0 ? 12 : l.hour % 12;
    return '$h:${l.minute.toString().padLeft(2, '0')} ${l.hour < 12 ? 'AM' : 'PM'}';
  }

  static String formatDateTime(DateTime t) => '${formatDate(t)}, ${formatTime(t)}';

  static String formatAmount(double amount) {
    final whole = amount == amount.roundToDouble();
    final raw = whole ? amount.round().toString() : amount.toStringAsFixed(2);
    // Indian digit grouping: 1,23,456
    final parts = raw.split('.');
    var intPart = parts[0];
    if (intPart.length > 3) {
      final last3 = intPart.substring(intPart.length - 3);
      var rest = intPart.substring(0, intPart.length - 3);
      final groups = <String>[];
      while (rest.length > 2) {
        groups.insert(0, rest.substring(rest.length - 2));
        rest = rest.substring(0, rest.length - 2);
      }
      if (rest.isNotEmpty) groups.insert(0, rest);
      intPart = '${groups.join(',')},$last3';
    }
    return parts.length > 1 ? '$intPart.${parts[1]}' : intPart;
  }

  static String _orDash(String v) => v.trim().isEmpty ? 'Not provided' : v.trim();

  static String _location(Booking b) => _orDash(b.pickupLocation);

  // ---------------------------------------------------------------------------
  // Templates
  // ---------------------------------------------------------------------------

  /// A. New booking request, renter → owner.
  static String newRequestForOwner(Booking b) => '''
Hello! You have received a new booking request through PassionRide.

BOOKING DETAILS

Booking ID: ${b.displayReference}

Renter Name: ${_orDash(b.customerName)}
Renter Contact: ${_orDash(b.customerPhone)}

Vehicle: ${b.vehicleTitle}
Pickup Date: ${formatDate(b.startDate)}
Pickup Time: ${formatTime(b.startDate)}

Return Date: ${formatDate(b.endDate)}
Return Time: ${formatTime(b.endDate)}

Pickup Location: ${_location(b)}

Estimated Rental Amount: ₹${formatAmount(b.totalPrice)}

Status: PENDING APPROVAL

Please open your PassionRide dashboard to accept or reject this request.

Thank you!
Team PassionRide''';

  /// B. Booking confirmation, owner → renter (or renter's own copy).
  static String confirmationForRenter(Booking b, {required String ownerPhone}) => '''
Your PassionRide booking is confirmed!

BOOKING DETAILS

Booking ID: ${b.displayReference}

Vehicle: ${b.vehicleTitle}
Owner: ${_orDash(b.hostName)}
Owner Contact: ${_orDash(ownerPhone)}

Pickup Date: ${formatDate(b.startDate)}
Pickup Time: ${formatTime(b.startDate)}

Return Date: ${formatDate(b.endDate)}
Return Time: ${formatTime(b.endDate)}

Pickup Location: ${_location(b)}

Total Rental Amount: ₹${formatAmount(b.totalPrice)}

Status: CONFIRMED

Please coordinate with the vehicle owner for pickup arrangements.

Enjoy your ride!

Team PassionRide''';

  /// C. Booking confirmation, renter → owner.
  static String confirmationForOwner(Booking b) => '''
A booking has been confirmed on PassionRide.

Booking ID: ${b.displayReference}

Renter: ${_orDash(b.customerName)}
Contact: ${_orDash(b.customerPhone)}

Vehicle: ${b.vehicleTitle}

Pickup: ${formatDateTime(b.startDate)}
Return: ${formatDateTime(b.endDate)}

Rental Amount: ₹${formatAmount(b.totalPrice)}

Status: CONFIRMED

Please prepare the vehicle for the scheduled pickup.

Team PassionRide''';

  /// D. Booking rejection, owner → renter.
  static String rejectionForRenter(Booking b) => '''
Your booking request on PassionRide could not be confirmed.

Booking ID: ${b.displayReference}

Vehicle: ${b.vehicleTitle}

Requested Pickup: ${formatDateTime(b.startDate)}

Requested Return: ${formatDateTime(b.endDate)}

Status: REJECTED

You can explore other available vehicles on PassionRide.

Thank you for your understanding.

Team PassionRide''';

  /// E. Cancellation, either side.
  static String cancellation(Booking b) {
    final by = b.cancelledBy == 'host'
        ? 'the vehicle owner'
        : b.cancelledBy == 'customer'
            ? 'the renter'
            : 'PassionRide';
    final reason = b.cancellationReason.trim();
    return '''
A PassionRide booking has been cancelled.

Booking ID: ${b.displayReference}

Vehicle: ${b.vehicleTitle}

Pickup: ${formatDateTime(b.startDate)}
Return: ${formatDateTime(b.endDate)}

Cancelled by: $by${reason.isEmpty ? '' : '\nReason: $reason'}

Status: CANCELLED

Team PassionRide''';
  }

  /// The right message for the renter, based on the booking's current status.
  static String? messageForRenter(Booking b, {required String ownerPhone}) {
    switch (b.normalizedStatus) {
      case BookingStatus.confirmed:
      case BookingStatus.active:
        return confirmationForRenter(b, ownerPhone: ownerPhone);
      case BookingStatus.rejected:
        return rejectionForRenter(b);
      case BookingStatus.cancelled:
        return cancellation(b);
      default:
        return null;
    }
  }

  /// The right message for the owner, based on the booking's current status.
  static String? messageForOwner(Booking b) {
    switch (b.normalizedStatus) {
      case BookingStatus.pending:
        return newRequestForOwner(b);
      case BookingStatus.confirmed:
      case BookingStatus.active:
        return confirmationForOwner(b);
      case BookingStatus.cancelled:
        return cancellation(b);
      default:
        return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Opening WhatsApp
  // ---------------------------------------------------------------------------

  Future<WhatsAppOpenResult> open({required String? phone, required String message}) async {
    final digits = normalizePhone(phone);
    if (digits == null) return WhatsAppOpenResult.invalidPhone;
    try {
      final ok = await _launcher(buildUri(digits, message));
      return ok ? WhatsAppOpenResult.opened : WhatsAppOpenResult.unavailable;
    } catch (e) {
      debugPrint('[WhatsAppService] could not open WhatsApp: $e');
      return WhatsAppOpenResult.unavailable;
    }
  }

  Future<WhatsAppOpenResult> shareBookingWithOwner(Booking b, {required String? ownerPhone}) =>
      open(phone: ownerPhone, message: messageForOwner(b) ?? newRequestForOwner(b));

  Future<WhatsAppOpenResult> shareBookingWithRenter(Booking b, {required String ownerPhone}) =>
      open(phone: b.customerPhone, message: messageForRenter(b, ownerPhone: ownerPhone) ?? confirmationForRenter(b, ownerPhone: ownerPhone));

  Future<WhatsAppOpenResult> shareBookingConfirmation(Booking b, {required String ownerPhone}) =>
      open(phone: b.customerPhone, message: confirmationForRenter(b, ownerPhone: ownerPhone));

  Future<WhatsAppOpenResult> shareBookingRejection(Booking b) =>
      open(phone: b.customerPhone, message: rejectionForRenter(b));

  Future<WhatsAppOpenResult> shareCancellationDetails(Booking b, {required String? recipientPhone}) =>
      open(phone: recipientPhone, message: cancellation(b));
}
