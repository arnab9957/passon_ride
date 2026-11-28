import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';

/// A booking action the database refused, with a message fit to show the user.
class BookingException implements Exception {
  BookingException(this.code, this.message);

  /// Database error code such as `VEHICLE_UNAVAILABLE`, or `UNKNOWN`.
  final String code;
  final String message;

  @override
  String toString() => message;

  static const _messages = {
    'NOT_SIGNED_IN': 'Please sign in to continue.',
    'NOT_YOUR_ACCOUNT': 'You can only book for your own account.',
    'VEHICLE_NOT_FOUND': 'This vehicle is no longer listed.',
    'VEHICLE_INACTIVE': 'This vehicle is not available for booking right now.',
    'VEHICLE_HAS_NO_OWNER': 'This listing has no owner yet and cannot be booked.',
    'OWN_VEHICLE': 'This is your own vehicle. Use "Record offline booking" instead.',
    'OWNER_NOT_ACCEPTING': 'The owner is not accepting bookings at the moment.',
    'VEHICLE_UNAVAILABLE': 'This vehicle is already booked for part of that time. Please pick another slot.',
    'INVALID_PERIOD': 'The return time must be after the pickup time.',
    'PICKUP_IN_PAST': 'The pickup time has already passed.',
    'INVALID_AMOUNT': 'The rental amount is not valid.',
    'BOOKING_NOT_FOUND': 'This booking was not found.',
    'INVALID_TRANSITION': 'This booking can no longer be changed that way.',
    'BOOKING_FEE_UNPAID': 'The renter\'s ₹10 booking fee has not been verified yet.',
    'VERIFICATION_REQUIRED': 'Only verified owners can turn on automatic confirmation.',
    'NO_PROVIDER_PROFILE': 'Create your provider profile first.',
    'DUPLICATE_ID': 'Please try booking again.',
  };

  static BookingException from(Object error) {
    if (error is BookingException) return error;
    final text = error is PostgrestException ? '${error.message} ${error.details ?? ''}' : '$error';
    for (final code in _messages.keys) {
      if (text.contains(code)) return BookingException(code, _messages[code]!);
    }
    if (text.contains('bookings_no_overlapping_vehicle_rentals')) {
      return BookingException('VEHICLE_UNAVAILABLE', _messages['VEHICLE_UNAVAILABLE']!);
    }
    if (error is PostgrestException && error.code == '42501') {
      return BookingException('FORBIDDEN', 'You are not allowed to change this booking.');
    }
    debugPrint('[BookingService] unmapped error: $error');
    return BookingException('UNKNOWN', 'Something went wrong. Please check your connection and try again.');
  }
}

/// Owner settings stored on `host_profiles`.
class BookingPreferences {
  const BookingPreferences({
    required this.isVerified,
    required this.autoConfirm,
    required this.acceptingBookings,
  });

  final bool isVerified;
  final bool autoConfirm;
  final bool acceptingBookings;

  static const unknown = BookingPreferences(isVerified: false, autoConfirm: false, acceptingBookings: true);

  factory BookingPreferences.fromMap(Map<String, dynamic> m) => BookingPreferences(
        isVerified: m['is_verified'] == true,
        autoConfirm: m['auto_confirm_bookings'] == true,
        acceptingBookings: m['accepting_bookings'] != false,
      );
}

/// A period in which a vehicle is reserved (no personal data).
class BusySlot {
  const BusySlot(this.vehicleId, this.start, this.end);
  final String vehicleId;
  final DateTime start;
  final DateTime end;

  bool overlaps(DateTime s, DateTime e) => s.isBefore(end) && e.isAfter(start);
}

class BookingHistoryEntry {
  const BookingHistoryEntry({this.fromStatus, required this.toStatus, required this.note, required this.at});
  final String? fromStatus;
  final String toStatus;
  final String note;
  final DateTime at;

  factory BookingHistoryEntry.fromMap(Map<String, dynamic> m) => BookingHistoryEntry(
        fromStatus: m['from_status'] as String?,
        toStatus: '${m['to_status']}',
        note: '${m['note'] ?? ''}',
        at: DateTime.tryParse('${m['created_at']}')?.toLocal() ?? DateTime.now(),
      );
}

/// Booking operations that must be decided by the database (see migration
/// 20261125000000_hybrid_booking_management.sql). The client never sets a
/// booking's status, owner or reference itself.
class BookingService {
  BookingService(this._client);

  final SupabaseClient? _client;

  SupabaseClient get _db {
    final c = _client;
    if (c == null || c.auth.currentUser == null) {
      throw BookingException('NOT_SIGNED_IN', 'Please sign in to continue.');
    }
    return c;
  }

  /// Creates a vehicle booking. The database picks the owner, status
  /// (Confirmed for automatic-confirmation owners, otherwise Pending),
  /// confirmation type and PR- reference, and refuses overlapping periods.
  /// Retrying with the same `id` returns the same booking.
  Future<Booking> createVehicleBooking(Map<String, dynamic> row, {bool awaitingBookingFee = false}) async {
    try {
      final res = await _db.rpc('create_vehicle_booking', params: {
        'p_booking': row,
        'p_awaiting_fee': awaitingBookingFee,
      });
      return Booking.fromMap(Map<String, dynamic>.from(res as Map));
    } catch (e) {
      throw BookingException.from(e);
    }
  }

  /// Moves a booking to [toStatus] (`Confirmed`, `Rejected`, `Active`,
  /// `Completed`, `Cancelled`). The database checks who may do this.
  Future<Booking> transition(String bookingId, String toStatus, {String note = ''}) async {
    try {
      final res = await _db.rpc('transition_booking', params: {
        'p_booking_id': bookingId,
        'p_to_status': toStatus,
        'p_note': note,
      });
      return Booking.fromMap(Map<String, dynamic>.from(res as Map));
    } catch (e) {
      throw BookingException.from(e);
    }
  }

  Future<BookingPreferences> fetchPreferences() async {
    try {
      final uid = _db.auth.currentUser!.id;
      final res = await _db
          .from('host_profiles')
          .select('is_verified, auto_confirm_bookings, accepting_bookings')
          .eq('id', uid)
          .maybeSingle();
      return res == null ? BookingPreferences.unknown : BookingPreferences.fromMap(res);
    } catch (e) {
      throw BookingException.from(e);
    }
  }

  Future<BookingPreferences> setPreferences({bool? autoConfirm, bool? acceptingBookings}) async {
    try {
      final res = await _db.rpc('set_booking_preferences', params: {
        'p_auto_confirm': autoConfirm,
        'p_accepting': acceptingBookings,
      });
      return BookingPreferences.fromMap(Map<String, dynamic>.from(res as Map));
    } catch (e) {
      throw BookingException.from(e);
    }
  }

  /// Reserved periods of every vehicle (or one), for availability checks in the UI.
  Future<List<BusySlot>> fetchBusySlots({String? vehicleId}) async {
    final c = _client;
    if (c == null) return const [];
    try {
      final res = await c.rpc('get_vehicle_busy_slots', params: {'p_vehicle_id': vehicleId});
      return [
        for (final r in (res as List).cast<Map>())
          BusySlot('${r['vehicle_id']}', DateTime.parse('${r['start_date']}'), DateTime.parse('${r['end_date']}')),
      ];
    } catch (e) {
      debugPrint('[BookingService] busy slots unavailable: $e');
      return const [];
    }
  }

  Future<List<BookingHistoryEntry>> fetchHistory(String bookingId) async {
    try {
      final res = await _db
          .from('booking_status_history')
          .select('from_status, to_status, note, created_at')
          .eq('booking_id', bookingId)
          .order('created_at');
      return [for (final r in res) BookingHistoryEntry.fromMap(r)];
    } catch (e) {
      throw BookingException.from(e);
    }
  }
}
