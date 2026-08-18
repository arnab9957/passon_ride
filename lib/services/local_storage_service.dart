import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class LocalStorageService {
  static const String _vehiclesKey = 'passon_vehicles_v1';
  static const String _toursKey = 'passon_tours_v1';
  static const String _bookingsKey = 'passon_bookings_v1';
  static const String _userProfileKey = 'passon_user_profile_v1';
  static const String _documentsKey = 'passon_compliance_documents_v1';

  /// Save user profile to local SharedPreferences
  Future<void> saveUserProfile(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userProfileKey, jsonEncode(profile.toMap()));
    } catch (e) {
      print('Local Storage Save Profile Error: $e');
    }
  }

  /// Load user profile from local SharedPreferences
  Future<UserProfile?> loadUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_userProfileKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
        return UserProfile.fromMap(decoded, decoded['uid']?.toString());
      }
    } catch (e) {
      print('Local Storage Load Profile Error: $e');
    }
    return null;
  }

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

  static const String _selectedLocationKey = 'passon_selected_location_v1';
  static const String _recentLocationsKey = 'passon_recent_locations_v1';

  /// Save selected location to local SharedPreferences
  Future<void> saveSelectedLocation(LocationResult location) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_selectedLocationKey, jsonEncode(location.toMap()));
    } catch (e) {
      print('Local Storage Save Location Error: $e');
    }
  }

  /// Load selected location from local SharedPreferences
  Future<LocationResult?> loadSelectedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_selectedLocationKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
        return LocationResult.fromMap(decoded);
      }
    } catch (e) {
      print('Local Storage Load Location Error: $e');
    }
    return null;
  }

  /// Save recent locations list to local SharedPreferences
  Future<void> saveRecentLocations(List<LocationResult> locations) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listJson = jsonEncode(locations.map((l) => l.toMap()).toList());
      await prefs.setString(_recentLocationsKey, listJson);
    } catch (e) {
      print('Local Storage Save Recent Locations Error: $e');
    }
  }

  /// Load recent locations list from local SharedPreferences
  Future<List<LocationResult>> loadRecentLocations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_recentLocationsKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List decoded = jsonDecode(jsonStr);
        return decoded
            .map((item) => LocationResult.fromMap(Map<String, dynamic>.from(item)))
            .toList();
      }
    } catch (e) {
      print('Local Storage Load Recent Locations Error: $e');
    }
    return [];
  }

  /// Save compliance documents list to local SharedPreferences
  Future<void> saveComplianceDocuments(List<ComplianceDocument> docs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listJson = jsonEncode(docs.map((d) => d.toMap()).toList());
      await prefs.setString(_documentsKey, listJson);
    } catch (e) {
      print('Local Storage Save Compliance Documents Error: $e');
    }
  }

  /// Load compliance documents list from local SharedPreferences
  Future<List<ComplianceDocument>> loadComplianceDocuments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_documentsKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List decoded = jsonDecode(jsonStr);
        return decoded
            .map((item) => ComplianceDocument.fromMap(Map<String, dynamic>.from(item)))
            .toList();
      }
    } catch (e) {
      print('Local Storage Load Compliance Documents Error: $e');
    }
    return [];
  }
}
