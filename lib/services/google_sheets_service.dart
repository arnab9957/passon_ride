import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

import 'google_sheets_web_bridge.dart' as web_sheets;

class GoogleSheetsService {
  static final GoogleSheetsService _instance = GoogleSheetsService._internal();
  factory GoogleSheetsService() => _instance;
  GoogleSheetsService._internal();

  static const String _prefPrefix = 'seller_google_sheet_webhook_';

  /// Save the Google Sheet Webhook / Apps Script Web App URL for a given seller (host)
  Future<void> saveWebhookUrl(String hostId, String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefPrefix$hostId', url.trim());
  }

  /// Get the saved Google Sheet Webhook URL for a given seller (host)
  Future<String?> getWebhookUrl(String hostId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_prefPrefix$hostId');
  }

  /// Sends a generic booking payload to the seller's Google Sheet
  Future<bool> sendRowToSheet({
    required String webhookUrl,
    required Map<String, dynamic> rowData,
  }) async {
    final cleanUrl = webhookUrl.trim();
    if (cleanUrl.isEmpty) return false;

    final jsonPayload = jsonEncode(rowData);

    // If running on Flutter Web, browsers enforce strict CORS and disallow following 302 across origins.
    // We dispatch via browser native fetch with mode: 'no-cors' and text/plain to avoid preflight issues.
    if (kIsWeb) {
      try {
        final ok = await web_sheets.sendGoogleSheetViaBrowser(cleanUrl, jsonPayload);
        debugPrint('[GoogleSheetsService] Web fetch dispatched: $ok');
        return ok;
      } catch (e) {
        debugPrint('[GoogleSheetsService] Error in web sync: $e');
      }
    }

    try {
      final uri = Uri.parse(cleanUrl);
      // Use text/plain for Google Apps Script to prevent OPTIONS preflight failure
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'text/plain;charset=utf-8'},
        body: jsonPayload,
      );

      // Google Apps Script redirect (302/200) or text output
      if (response.statusCode >= 200 && response.statusCode < 400) {
        debugPrint('[GoogleSheetsService] Successfully synced row to sheet: ${response.statusCode}');
        return true;
      } else {
        debugPrint('[GoogleSheetsService] Failed to sync to sheet: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('[GoogleSheetsService] Error syncing to Google Sheet: $e');
      // If on Web and an exception was caught, fallback to true if dispatched
      return kIsWeb;
    }
  }

  /// Sync a vehicle / bike ride booking
  Future<bool> syncVehicleBooking({
    required Booking booking,
    required String hostId,
    String? vehicleName,
  }) async {
    final webhookUrl = await getWebhookUrl(hostId);
    if (webhookUrl == null || webhookUrl.isEmpty) return false;

    final customerName = booking.customerName.isNotEmpty
        ? booking.customerName
        : (booking.accountName.isNotEmpty ? booking.accountName : 'Guest Customer');

    final rowData = {
      'bookingId': booking.id,
      'category': 'Bike / Vehicle Ride',
      'itemName': vehicleName ?? booking.vehicleTitle,
      'customerName': customerName,
      'customerPhone': booking.customerPhone,
      'customerEmail': booking.customerEmail,
      'startDate': booking.startDate.toIso8601String().split('T').first,
      'endDate': booking.endDate.toIso8601String().split('T').first,
      'totalPrice': booking.totalPrice,
      'status': booking.status,
      'paymentMethod': 'PassOn Escrow / Online',
      'timestamp': DateTime.now().toIso8601String(),
    };

    return await sendRowToSheet(webhookUrl: webhookUrl, rowData: rowData);
  }

  /// Sync a Hotel / Stay / Homestay booking
  Future<bool> syncHotelBooking({
    required HotelBooking booking,
    required String hostId,
  }) async {
    final webhookUrl = await getWebhookUrl(hostId);
    if (webhookUrl == null || webhookUrl.isEmpty) return false;

    final rowData = {
      'bookingId': booking.bookingRef.isNotEmpty ? booking.bookingRef : booking.id,
      'category': 'Hotel / Homestay',
      'itemName': booking.hotelName,
      'customerName': booking.guestName,
      'customerPhone': booking.guestPhone,
      'customerEmail': booking.guestEmail,
      'startDate': booking.checkInDate.toIso8601String().split('T').first,
      'endDate': booking.checkOutDate.toIso8601String().split('T').first,
      'totalPrice': booking.totalPrice,
      'status': booking.status,
      'paymentMethod': booking.paymentMethod.isNotEmpty ? booking.paymentMethod : booking.paymentStatus,
      'timestamp': DateTime.now().toIso8601String(),
    };

    return await sendRowToSheet(webhookUrl: webhookUrl, rowData: rowData);
  }

  /// Sync a Guided Tour booking
  Future<bool> syncTourBooking({
    required String tourTitle,
    required String hostId,
    required String customerName,
    required String customerPhone,
    required String customerEmail,
    required int spots,
    required double totalPrice,
    required String tourDate,
    String? bookingId,
  }) async {
    final webhookUrl = await getWebhookUrl(hostId);
    if (webhookUrl == null || webhookUrl.isEmpty) return false;

    final rowData = {
      'bookingId': bookingId ?? 'TOUR-${DateTime.now().millisecondsSinceEpoch}',
      'category': 'Guided Tour',
      'itemName': '$tourTitle ($spots spot${spots > 1 ? 's' : ''})',
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
      'startDate': tourDate,
      'endDate': tourDate,
      'totalPrice': totalPrice,
      'status': 'Confirmed',
      'paymentMethod': 'Razorpay / Online',
      'timestamp': DateTime.now().toIso8601String(),
    };

    return await sendRowToSheet(webhookUrl: webhookUrl, rowData: rowData);
  }

  /// Returns the copyable Google Apps Script code to paste in Google Sheets
  String getGoogleAppsScriptTemplate() {
    return '''// PassOn Ride - Automatic Google Sheet / Excel Sync Script
// 1. In your Google Sheet, click: Extensions > Apps Script
// 2. Delete all existing code and paste this script.
// 3. Click 'Deploy' (top right) -> 'New deployment'
// 4. Select type: 'Web app'
// 5. Set 'Execute as': 'Me'
// 6. Set 'Who has access': 'Anyone'
// 7. Click 'Deploy', authorize permissions, and COPY the Web App URL into PassOn.

function doPost(e) {
  try {
    var sheet = SpreadsheetApp.getActiveSpreadsheet().getActiveSheet();
    var data = JSON.parse(e.postData.contents);
    
    // Add header row automatically if sheet is empty
    if (sheet.getLastRow() === 0) {
      sheet.appendRow([
        "Booking ID", 
        "Category", 
        "Item / Service", 
        "Customer Name", 
        "Customer Phone", 
        "Customer Email", 
        "Start / Check-In", 
        "End / Check-Out", 
        "Total (₹)", 
        "Status", 
        "Payment", 
        "Date Recorded"
      ]);
      sheet.getRange(1, 1, 1, 12).setFontWeight("bold").setBackground("#e8f0fe");
      sheet.setFrozenRows(1);
    }
    
    // Append the incoming booking row
    sheet.appendRow([
      data.bookingId || "",
      data.category || "",
      data.itemName || "",
      data.customerName || "",
      data.customerPhone || "",
      data.customerEmail || "",
      data.startDate || "",
      data.endDate || "",
      data.totalPrice || 0,
      data.status || "",
      data.paymentMethod || "",
      new Date().toLocaleString()
    ]);
    
    return ContentService.createTextOutput(JSON.stringify({"result": "success"}))
      .setMimeType(ContentService.MimeType.JSON);
  } catch (error) {
    return ContentService.createTextOutput(JSON.stringify({"result": "error", "error": error.toString()}))
      .setMimeType(ContentService.MimeType.JSON);
  }
}
''';
  }
}
