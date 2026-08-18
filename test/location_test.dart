import 'package:flutter_test/flutter_test.dart';
import 'package:passon_ride/models/location_model.dart';
import 'package:passon_ride/models/models.dart';
import 'package:passon_ride/services/location_service.dart';

void main() {
  group('LocationResult Model Tests', () {
    test('LocationResult creates with correct defaults and serialization', () {
      final loc = LocationResult(
        displayName: 'San Francisco, CA, USA',
        city: 'San Francisco',
        state: 'California',
        country: 'United States',
        postalCode: '94102',
        latitude: 37.7749,
        longitude: -122.4194,
        isLive: true,
        accuracy: 'GPS Signal Locked (~10m)',
      );

      expect(loc.displayName, 'San Francisco, CA, USA');
      expect(loc.city, 'San Francisco');
      expect(loc.latitude, 37.7749);
      expect(loc.longitude, -122.4194);
      expect(loc.isLive, true);

      final map = loc.toMap();
      expect(map['displayName'], 'San Francisco, CA, USA');
      expect(map['isLive'], true);
      expect(map['latitude'], 37.7749);

      final deserialized = LocationResult.fromMap(map);
      expect(deserialized.displayName, loc.displayName);
      expect(deserialized.city, loc.city);
      expect(deserialized.latitude, loc.latitude);
      expect(deserialized.longitude, loc.longitude);
      expect(deserialized.isLive, loc.isLive);
    });

    test('LocationResult copyWith updates fields correctly', () {
      final loc = LocationResult(
        displayName: 'Initial Place',
        latitude: 10.0,
        longitude: 20.0,
      );

      final updated = loc.copyWith(
        displayName: 'Updated Place',
        isLive: true,
      );

      expect(updated.displayName, 'Updated Place');
      expect(updated.latitude, 10.0);
      expect(updated.isLive, true);
    });
  });

  group('LocationService Tests', () {
    final service = LocationService();

    test('getPopularHubs contains valid fleet hubs', () {
      final hubs = service.getPopularHubs();
      expect(hubs.isNotEmpty, true);
      expect(hubs.any((h) => h.city == 'San Francisco'), true);
      expect(hubs.any((h) => h.city == 'Kolkata'), true);
      expect(hubs.any((h) => h.city == 'London'), true);
      expect(hubs.any((h) => h.city == 'Tokyo'), true);

      for (final hub in hubs) {
        expect(hub.displayName.isNotEmpty, true);
        expect(hub.latitude != 0.0, true);
        expect(hub.longitude != 0.0, true);
      }
    });

    test('calculateDistanceKm returns accurate Haversine distance', () {
      // SF coordinates: 37.7749, -122.4194
      // San Jose coordinates: 37.3382, -121.8863
      final distKm = service.calculateDistanceKm(37.7749, -122.4194, 37.3382, -121.8863);
      
      // Expected distance ~66 km
      expect(distKm, greaterThan(60.0));
      expect(distKm, lessThan(75.0));

      // Same location should be 0 km
      final zeroDist = service.calculateDistanceKm(37.7749, -122.4194, 37.7749, -122.4194);
      expect(zeroDist, closeTo(0.0, 0.001));
    });

    test('formatDistance formats meters and kilometers properly', () {
      expect(service.formatDistance(0.5), '500 m');
      expect(service.formatDistance(0.85), '850 m');
      expect(service.formatDistance(1.23), '1.2 km');
      expect(service.formatDistance(25.67), '25.7 km');
    });

    test('reverseGeocode handles pin coordinates properly', () async {
      final pinResult = await service.reverseGeocode(37.7749, -122.4194);
      expect(pinResult.displayName.isNotEmpty, true);
      expect(pinResult.latitude, 37.7749);
      expect(pinResult.longitude, -122.4194);
    });
  });
}
