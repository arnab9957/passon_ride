import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class LocalStorageService {
  static const String _vehiclesKey = 'passon_vehicles_v1';
  static const String _toursKey = 'passon_tours_v1';
  static const String _bookingsKey = 'passon_bookings_v1';

  /// Save vehicles list to local SharedPreferences
  Future<void> saveVehicles(List<Vehicle> vehicles) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listJson = jsonEncode(vehicles.map((v) => v.toMap()).toList());
      await prefs.setString(_vehiclesKey, listJson);
    } catch (e) {
      print('Local Storage Save Vehicles Error: $e');
    }
  }

  /// Load vehicles list from local SharedPreferences
  Future<List<Vehicle>> loadVehicles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_vehiclesKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List decoded = jsonDecode(jsonStr);
        return decoded
            .map((item) => Vehicle.fromMap(Map<String, dynamic>.from(item)))
            .toList();
      }
    } catch (e) {
      print('Local Storage Load Vehicles Error: $e');
    }
    return [];
  }

  /// Save tours list to local SharedPreferences
  Future<void> saveTours(List<Tour> tours) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listJson = jsonEncode(tours.map((t) => t.toMap()).toList());
      await prefs.setString(_toursKey, listJson);
    } catch (e) {
      print('Local Storage Save Tours Error: $e');
    }
  }

  /// Load tours list from local SharedPreferences
  Future<List<Tour>> loadTours() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_toursKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List decoded = jsonDecode(jsonStr);
        return decoded
            .map((item) => Tour.fromMap(Map<String, dynamic>.from(item)))
            .toList();
      }
    } catch (e) {
      print('Local Storage Load Tours Error: $e');
    }
    return [];
  }

  /// Save bookings list to local SharedPreferences
  Future<void> saveBookings(List<Booking> bookings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listJson = jsonEncode(bookings.map((b) => b.toMap()).toList());
      await prefs.setString(_bookingsKey, listJson);
    } catch (e) {
      print('Local Storage Save Bookings Error: $e');
    }
  }

  /// Load bookings list from local SharedPreferences
  Future<List<Booking>> loadBookings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_bookingsKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List decoded = jsonDecode(jsonStr);
        return decoded
            .map((item) => Booking.fromMap(Map<String, dynamic>.from(item)))
            .toList();
      }
    } catch (e) {
      print('Local Storage Load Bookings Error: $e');
    }
    return [];
  }
}
