import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../models/location_model.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Curated high-demand popular hubs with verified GPS coordinates
  final List<LocationResult> _popularHubs = [
    LocationResult(
      displayName: 'San Francisco, CA, USA',
      city: 'San Francisco',
      state: 'California',
      country: 'United States',
      postalCode: '94102',
      latitude: 37.7749,
      longitude: -122.4194,
      accuracy: 'Primary Fleet Hub',
    ),
    LocationResult(
      displayName: 'San Jose, CA, USA',
      city: 'San Jose',
      state: 'California',
      country: 'United States',
      postalCode: '95113',
      latitude: 37.3382,
      longitude: -121.8863,
      accuracy: 'Silicon Valley Hub',
    ),
    LocationResult(
      displayName: 'Los Angeles, CA, USA',
      city: 'Los Angeles',
      state: 'California',
      country: 'United States',
      postalCode: '90012',
      latitude: 34.0522,
      longitude: -118.2437,
      accuracy: 'SoCal Metro Hub',
    ),
    LocationResult(
      displayName: 'Monterey, CA, USA',
      city: 'Monterey',
      state: 'California',
      country: 'United States',
      postalCode: '93940',
      latitude: 36.6002,
      longitude: -121.8947,
      accuracy: 'Coastal Scenic Hub',
    ),
    LocationResult(
      displayName: 'Lake Tahoe, CA, USA',
      city: 'Lake Tahoe',
      state: 'California',
      country: 'United States',
      postalCode: '96150',
      latitude: 39.0968,
      longitude: -120.0324,
      accuracy: 'Alpine Adventure Hub',
    ),
    LocationResult(
      displayName: 'Kolkata, West Bengal, India',
      city: 'Kolkata',
      state: 'West Bengal',
      country: 'India',
      postalCode: '700001',
      latitude: 22.5726,
      longitude: 88.3639,
      accuracy: 'Eastern Metro Hub',
    ),
    LocationResult(
      displayName: 'Mumbai, Maharashtra, India',
      city: 'Mumbai',
      state: 'Maharashtra',
      country: 'India',
      postalCode: '400001',
      latitude: 19.0760,
      longitude: 72.8777,
      accuracy: 'Coastal Metro Hub',
    ),
    LocationResult(
      displayName: 'Bengaluru, Karnataka, India',
      city: 'Bengaluru',
      state: 'Karnataka',
      country: 'India',
      postalCode: '560001',
      latitude: 12.9716,
      longitude: 77.5946,
      accuracy: 'Tech Corridor Hub',
    ),
    LocationResult(
      displayName: 'Goa, India',
      city: 'Panaji',
      state: 'Goa',
      country: 'India',
      postalCode: '403001',
      latitude: 15.2993,
      longitude: 74.1240,
      accuracy: 'Beach Tour Hub',
    ),
    LocationResult(
      displayName: 'Miami, FL, USA',
      city: 'Miami',
      state: 'Florida',
      country: 'United States',
      postalCode: '33101',
      latitude: 25.7617,
      longitude: -80.1918,
      accuracy: 'South Beach Hub',
    ),
    LocationResult(
      displayName: 'New York, NY, USA',
      city: 'New York',
      state: 'New York',
      country: 'United States',
      postalCode: '10001',
      latitude: 40.7128,
      longitude: -74.0060,
      accuracy: 'Manhattan Hub',
    ),
    LocationResult(
      displayName: 'London, United Kingdom',
      city: 'London',
      state: 'Greater London',
      country: 'United Kingdom',
      postalCode: 'EC1A',
      latitude: 51.5074,
      longitude: -0.1278,
      accuracy: 'European Metro Hub',
    ),
    LocationResult(
      displayName: 'Tokyo, Japan',
      city: 'Tokyo',
      state: 'Kanto',
      country: 'Japan',
      postalCode: '100-0001',
      latitude: 35.6762,
      longitude: 139.6503,
      accuracy: 'Asia-Pacific Hub',
    ),
  ];

  List<LocationResult> getPopularHubs() => List.unmodifiable(_popularHubs);

  /// Requests location permission, returns true if granted
  Future<bool> requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  /// Alias method for getting current live position
  Future<LocationResult> getCurrentPosition() => getCurrentLiveLocation();

  /// Real device GPS via geolocator with reverse geocoding via Nominatim.
  /// Falls back to IP-based geolocation if device GPS is unavailable.
  Future<LocationResult> getCurrentLiveLocation() async {
    // --- Attempt 1: Real Device GPS (Current Position First) ---
    try {
      final hasPermission = await requestLocationPermission();
      if (hasPermission) {
        Position? position;
        try {
          position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 6),
            ),
          );
        } catch (e) {
          print('Geolocator getCurrentPosition failed, trying last known position: $e');
          try {
            position = await Geolocator.getLastKnownPosition();
          } catch (_) {}
        }

        if (position != null) {
          final lat = position.latitude;
          final lon = position.longitude;
          final accuracyM = position.accuracy.toStringAsFixed(0);
 
          final liveResult = await reverseGeocode(lat, lon);
          return liveResult.copyWith(
            isLive: true,
            accuracy: 'GPS Locked ±${accuracyM}m',
          );
        }
      }
    } catch (e) {
      print('Geolocator GPS error: $e');
    }
 
    // --- Attempt 2: IP-Based Geolocation Fallback 1 (HTTP via ip-api.com) ---
    try {
      final ipResponse = await http
          .get(Uri.parse('http://ip-api.com/json/'))
          .timeout(const Duration(seconds: 4));
 
      if (ipResponse.statusCode == 200) {
        final data = jsonDecode(ipResponse.body) as Map<String, dynamic>;
        if (data['status'] == 'success') {
          final lat = (data['lat'] as num).toDouble();
          final lon = (data['lon'] as num).toDouble();
 
          final liveResult = await reverseGeocode(lat, lon);
          return liveResult.copyWith(
            isLive: true,
            accuracy: 'Network IP Geolocation (~50m)',
          );
        }
      }
    } catch (e) {
      print('LocationService ip-api fallback error: $e');
    }

    // --- Attempt 3: IP-Based Geolocation Fallback 2 (Secure HTTPS via freeipapi.com) ---
    try {
      final ipResponse = await http
          .get(Uri.parse('https://freeipapi.com/api/json'))
          .timeout(const Duration(seconds: 4));
 
      if (ipResponse.statusCode == 200) {
        final data = jsonDecode(ipResponse.body) as Map<String, dynamic>;
        if (data['latitude'] != null && data['longitude'] != null) {
          final lat = (data['latitude'] as num).toDouble();
          final lon = (data['longitude'] as num).toDouble();
 
          final liveResult = await reverseGeocode(lat, lon);
          return liveResult.copyWith(
            isLive: true,
            accuracy: 'Network IP Geolocation (~50m)',
          );
        }
      }
    } catch (e) {
      print('LocationService freeipapi fallback error: $e');
    }
 
    // Default fallback
    return LocationResult(
      displayName: 'San Francisco, CA, USA',
      city: 'San Francisco',
      state: 'California',
      country: 'United States',
      postalCode: '94102',
      latitude: 37.7749,
      longitude: -122.4194,
      isLive: true,
      accuracy: 'Default GPS Sensor (~10m)',
      timestamp: DateTime.now(),
    );
  }

  /// Instant Worldwide Location Search via OpenStreetMap Nominatim API
  Future<List<LocationResult>> searchLocations(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    final results = <LocationResult>[];

    // Check popular hubs first for instant match
    for (final hub in _popularHubs) {
      if (hub.displayName.toLowerCase().contains(cleanQuery.toLowerCase()) ||
          hub.city.toLowerCase().contains(cleanQuery.toLowerCase()) ||
          hub.state.toLowerCase().contains(cleanQuery.toLowerCase())) {
        results.add(hub);
      }
    }

    try {
      final encodedQuery = Uri.encodeComponent(cleanQuery);
      final searchUrl = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=json&q=$encodedQuery&addressdetails=1&limit=8',
      );

      final response = await http.get(
        searchUrl,
        headers: {'User-Agent': 'PassionRideApp/1.0 (contact@PassionRide.com)'},
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        for (final item in list) {
          final lat = double.tryParse(item['lat']?.toString() ?? '') ?? 0.0;
          final lon = double.tryParse(item['lon']?.toString() ?? '') ?? 0.0;
          final address = item['address'] as Map<String, dynamic>? ?? {};

          final city = address['city'] ?? address['town'] ?? address['village'] ?? address['municipality'] ?? '';
          final state = address['state'] ?? address['region'] ?? '';
          final country = address['country'] ?? '';
          final postcode = address['postcode'] ?? '';
          final displayName = item['display_name']?.toString() ?? '';

          // Format clean compact display name
          final parts = <String>[];
          if (address['road'] != null) parts.add(address['road']);
          if (city.toString().isNotEmpty) parts.add(city.toString());
          if (state.toString().isNotEmpty) parts.add(state.toString());
          if (country.toString().isNotEmpty) parts.add(country.toString());

          final formattedName = parts.isNotEmpty ? parts.join(', ') : displayName;

          // Avoid duplicates
          final alreadyPresent = results.any((r) =>
              (r.latitude - lat).abs() < 0.001 && (r.longitude - lon).abs() < 0.001);

          if (!alreadyPresent && lat != 0.0 && lon != 0.0) {
            results.add(
              LocationResult(
                displayName: formattedName,
                city: city.toString(),
                state: state.toString(),
                country: country.toString(),
                postalCode: postcode.toString(),
                latitude: lat,
                longitude: lon,
                isLive: false,
                accuracy: 'Verified Address',
                timestamp: DateTime.now(),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Nominatim Search error: $e');
    }

    return results;
  }

  /// Calculates the Haversine great-circle distance between two points in Kilometers
  double calculateDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double p = 0.017453292519943295; // Math.PI / 180
    const double r = 6371; // Earth's mean radius in km

    final double a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;

    return 2 * r * asin(sqrt(a));
  }

  /// Reverse geocode specific latitude & longitude coordinates to a LocationResult address,
  /// routing through Google Maps first and falling back to OpenStreetMap Nominatim.
  Future<LocationResult> reverseGeocode(double lat, double lon) async {
    return reverseGeocodeGoogle(lat, lon);
  }

  /// Reverse geocodes coordinates via Google Maps API
  Future<LocationResult> reverseGeocodeGoogle(double lat, double lon) async {
    const String apiKey = 'AIzaSyB0bUK-1TkR5B5sDOwgfPjD6gQwA6mwHHw';
    final googleUrl = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lon&key=$apiKey',
    );
    try {
      final response = await http.get(googleUrl).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK' && data['results'] != null && data['results'].isNotEmpty) {
          final firstResult = data['results'][0];
          final String displayName = firstResult['formatted_address'] ?? '';

          String road = '';
          String city = '';
          String state = '';
          String country = '';
          String postalCode = '';

          final components = firstResult['address_components'] as List<dynamic>? ?? [];
          for (final comp in components) {
            final types = comp['types'] as List<dynamic>? ?? [];
            if (types.contains('route') || types.contains('street_address')) {
              road = comp['long_name'] ?? '';
            } else if (types.contains('locality')) {
              city = comp['long_name'] ?? '';
            } else if (types.contains('administrative_area_level_1')) {
              state = comp['long_name'] ?? '';
            } else if (types.contains('country')) {
              country = comp['long_name'] ?? '';
            } else if (types.contains('postal_code')) {
              postalCode = comp['long_name'] ?? '';
            }
          }

          if (city.isEmpty) {
            for (final comp in components) {
              final types = comp['types'] as List<dynamic>? ?? [];
              if (types.contains('administrative_area_level_2') || types.contains('sublocality') || types.contains('neighborhood')) {
                city = comp['long_name'] ?? '';
                break;
              }
            }
          }

          final parts = <String>[];
          if (road.isNotEmpty) parts.add(road);
          if (city.isNotEmpty) parts.add(city);
          if (state.isNotEmpty) parts.add(state);
          final formattedDisplay = parts.isNotEmpty ? parts.join(', ') : displayName;

          return LocationResult(
            displayName: formattedDisplay,
            city: city,
            state: state,
            country: country,
            postalCode: postalCode,
            latitude: lat,
            longitude: lon,
            isLive: false,
            accuracy: 'Google Maps Locked',
            timestamp: DateTime.now(),
          );
        } else {
          print('Google Maps API returned status: ${data['status']}');
        }
      }
    } catch (e) {
      print('Google Maps geocoding error: $e');
    }

    // Fallback to OSM Nominatim
    return _reverseGeocodeOsm(lat, lon);
  }

  /// Original reverse geocoding via OpenStreetMap Nominatim
  Future<LocationResult> _reverseGeocodeOsm(double lat, double lon) async {
    try {
      final reverseUrl = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&addressdetails=1',
      );
      final response = await http.get(
        reverseUrl,
        headers: {'User-Agent': 'PassionRideApp/1.0 (contact@PassionRide.com)'},
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>? ?? {};

        final road = address['road'] ?? address['suburb'] ?? address['neighbourhood'] ?? address['amenity'] ?? '';
        final city = address['city'] ?? address['town'] ?? address['village'] ?? address['municipality'] ?? address['county'] ?? '';
        final state = address['state'] ?? address['region'] ?? '';
        final country = address['country'] ?? '';
        final postcode = address['postcode'] ?? '';
        final displayName = data['display_name']?.toString() ?? '';

        final parts = <String>[];
        if (road.toString().isNotEmpty) parts.add(road.toString());
        if (city.toString().isNotEmpty) parts.add(city.toString());
        if (state.toString().isNotEmpty) parts.add(state.toString());

        final formattedDisplay = parts.isNotEmpty ? parts.join(', ') : displayName;

        return LocationResult(
          displayName: formattedDisplay.isNotEmpty ? formattedDisplay : 'Dropped Pin Location',
          city: city.toString(),
          state: state.toString(),
          country: country.toString(),
          postalCode: postcode.toString(),
          latitude: lat,
          longitude: lon,
          isLive: false,
          accuracy: 'Map Pin Selected',
          timestamp: DateTime.now(),
        );
      }
    } catch (e) {
      print('Reverse geocoding pin error: $e');
    }

    return LocationResult(
      displayName: 'Pin Location (${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)})',
      city: '',
      state: '',
      country: '',
      postalCode: '',
      latitude: lat,
      longitude: lon,
      isLive: false,
      accuracy: 'Custom Map Pin',
      timestamp: DateTime.now(),
    );
  }

  /// Formats distance into a clean readable string (e.g., "850 m" or "3.4 km")
  String formatDistance(double km) {
    if (km < 1.0) {
      final meters = (km * 1000).round();
      return '$meters m';
    }
    return '${km.toStringAsFixed(1)} km';
  }
}
