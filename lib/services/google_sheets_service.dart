import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

/// Talks to the `google-sheets` edge function, which holds each host's Google connection.
class GoogleSheetsService {
  static final GoogleSheetsService _instance = GoogleSheetsService._internal();
  factory GoogleSheetsService() => _instance;
  GoogleSheetsService._internal();

  Future<Map<String, dynamic>?> _call(Map<String, dynamic> body) async {
    try {
      final response = await Supabase.instance.client.functions.invoke('google-sheets', body: body);
      return Map<String, dynamic>.from(response.data as Map);
    } catch (e) {
      debugPrint('[GoogleSheetsService] ${body['action']} error: $e');
      return null;
    }
  }

  Future<String?> getConnectUrl() async => (await _call({'action': 'auth_url'}))?['url']?.toString();

  /// Returns the connected sheet's URL, or null when not connected.
  Future<String?> getConnectedSheetUrl() async {
    final status = await _call({'action': 'status'});
    return status?['connected'] == true ? status!['url'].toString() : null;
  }

  Future<void> disconnect() => _call({'action': 'disconnect'});

  Future<bool> syncVehicleBooking({required Booking booking}) async {
    final result = await _call({'action': 'sync', 'kind': 'vehicle', 'bookingId': booking.id});
    return result?['synced'] == true;
  }

  Future<bool> syncHotelBooking({required HotelBooking booking}) async {
    final result = await _call({'action': 'sync', 'kind': 'hotel', 'bookingId': booking.id});
    return result?['synced'] == true;
  }

  Future<bool> syncTourBooking({
    required String tourId,
    required String customerName,
    required String customerPhone,
    required String customerEmail,
    required int spots,
    required double totalPrice,
    required String tourDate,
    required String bookingId,
  }) async {
    final result = await _call({
      'action': 'sync',
      'kind': 'tour',
      'tourId': tourId,
      'bookingId': bookingId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
      'spots': spots,
      'totalPrice': totalPrice,
      'tourDate': tourDate,
    });
    return result?['synced'] == true;
  }
}
