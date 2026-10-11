import 'package:flutter_test/flutter_test.dart';
import 'package:passon_ride/models/models.dart';

void main() {
  group('Hotel Model & Coordinates Tests', () {
    test('Default coordinates when none provided', () {
      final hotel = Hotel(
        id: 'h1',
        name: 'Test Stay',
        location: 'Kolkata',
        address: 'Park Street',
        pricePerNight: 500,
        description: 'Nice place',
        roomType: 'Private Room',
        maxGuests: 2,
        rating: 4.8,
        reviewCount: 10,
        imageUrl: 'https://example.com/photo.jpg',
        hostName: 'Test Host',
        hostPhone: '9876543210',
        hostId: 'host123',
      );

      expect(hotel.latitude, 22.5726);
      expect(hotel.longitude, 88.3639);
    });

    test('Custom coordinates stored and serialized correctly', () {
      final hotel = Hotel(
        id: 'h2',
        name: 'Burdwan Heritage Homestay',
        location: 'Purba Burdwan, West Bengal',
        address: 'Near Station Road, Burdwan',
        latitude: 23.0800,
        longitude: 87.9000,
        pricePerNight: 450,
        description: 'Peaceful stay',
        roomType: 'Entire Homestay',
        maxGuests: 4,
        rating: 4.9,
        reviewCount: 15,
        imageUrl: 'https://example.com/burdwan.jpg',
        hostName: 'Ramesh Host',
        hostPhone: '9876500000',
        hostId: 'host_burdwan',
      );

      final map = hotel.toMap();
      expect(map['latitude'], 23.0800);
      expect(map['longitude'], 87.9000);

      final fromMap = Hotel.fromMap(map);
      expect(fromMap.latitude, 23.0800);
      expect(fromMap.longitude, 87.9000);
      expect(fromMap.name, 'Burdwan Heritage Homestay');
      expect(fromMap.address, 'Near Station Road, Burdwan');
    });

    test('copyWith updates coordinates properly', () {
      final hotel = Hotel(
        id: 'h3',
        name: 'Manali Pine Retreat',
        location: 'Old Manali',
        address: 'Club House Road',
        pricePerNight: 600,
        description: 'Mountain view',
        roomType: 'Double Bed Room',
        maxGuests: 2,
        rating: 4.9,
        reviewCount: 8,
        imageUrl: 'https://example.com/manali.jpg',
        hostName: 'Manali Host',
        hostPhone: '9876511111',
        hostId: 'host_manali',
      );

      final updated = hotel.copyWith(
        latitude: 32.2530,
        longitude: 77.1750,
      );

      expect(updated.latitude, 32.2530);
      expect(updated.longitude, 77.1750);
      expect(updated.name, 'Manali Pine Retreat');
    });
  });
}
