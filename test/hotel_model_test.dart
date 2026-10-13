import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:passon_ride/models/models.dart';
import 'package:passon_ride/providers/app_state.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    try {
      await Supabase.initialize(
        url: 'https://gxqlsogewjjkcdetubuv.supabase.co',
        publishableKey: 'sb_publishable_b1WyefoA--KuuAfVlDjMaw_iFLBj8Hk',
      );
    } catch (_) {}
  });
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

    test('Hotel serializes mother-child account isolation fields', () {
      final hotel = Hotel(
        id: 'h_child_1',
        name: 'Darjeeling Cloud Homestay',
        location: 'Darjeeling, WB',
        address: 'Mall Road',
        latitude: 27.0410,
        longitude: 88.2663,
        pricePerNight: 750,
        description: 'Cozy stay with Kanchenjunga view',
        hostName: 'Subhasish',
        hostId: 'c_subhasish',
        accountId: 'c_subhasish',
        accountName: 'Subhasish (Child)',
        accountType: 'child',
        isChildHosting: true,
        childId: 'c_subhasish',
        childName: 'Subhasish',
      );

      final map = hotel.toMap();
      expect(map['account_id'], 'c_subhasish');
      expect(map['account_type'], 'child');
      expect(map['is_child_hosting'], true);
      expect(map['child_id'], 'c_subhasish');

      final fromMap = Hotel.fromMap(map);
      expect(fromMap.accountId, 'c_subhasish');
      expect(fromMap.accountType, 'child');
      expect(fromMap.isChildHosting, true);
      expect(fromMap.childId, 'c_subhasish');
    });
  });

  group('HotelBooking Model & Supabase Schema Alignment Tests', () {
    test('HotelBooking serialization to and from Map', () {
      final now = DateTime(2026, 10, 15, 12, 0);
      final checkOut = DateTime(2026, 10, 18, 11, 0);

      final booking = HotelBooking(
        id: 'hb_101',
        bookingRef: 'STAY-9876543',
        hotelId: 'h2',
        hotelName: 'Burdwan Heritage Homestay',
        hotelLocation: 'Purba Burdwan, West Bengal',
        hotelImageUrl: 'https://example.com/burdwan.jpg',
        roomType: 'Entire Homestay',
        hostId: 'host_burdwan',
        hostName: 'Ramesh Host',
        hostPhone: '9876500000',
        userId: 'guest_456',
        guestName: 'Ananya Sharma',
        guestPhone: '9871122334',
        guestEmail: 'ananya@example.com',
        guestPhotoUrl: 'https://example.com/selfie.jpg',
        guestIdProofType: 'Driving Licence',
        guestIdProofNumber: 'WB-12-2023-1234567',
        guestIdProofUrl: 'https://example.com/dl.jpg',
        guestTrustScore: 98.5,
        accountId: 'm_mother_01',
        accountName: 'Ananya Mother Profile',
        accountType: 'mother',
        isChildBooking: false,
        checkInDate: now,
        checkOutDate: checkOut,
        nights: 3,
        numGuests: 2,
        pricePerNight: 450.0,
        totalPrice: 1350.0,
        platformFee: 0.0,
        status: 'Confirmed',
        paymentStatus: 'Pay at Check-in',
      );

      final map = booking.toMap();
      expect(map['id'], 'hb_101');
      expect(map['booking_ref'], 'STAY-9876543');
      expect(map['hotel_id'], 'h2');
      expect(map['hotel_name'], 'Burdwan Heritage Homestay');
      expect(map['nights'], 3);
      expect(map['total_price'], 1350.0);
      expect(map['platform_fee'], 0.0);
      expect(map['guest_name'], 'Ananya Sharma');
      expect(map['guest_id_proof_type'], 'Driving Licence');
      expect(map['guest_id_proof_number'], 'WB-12-2023-1234567');
      expect(map['guest_photo_url'], 'https://example.com/selfie.jpg');
      expect(map['account_type'], 'mother');

      final fromMap = HotelBooking.fromMap(map);
      expect(fromMap.id, 'hb_101');
      expect(fromMap.bookingRef, 'STAY-9876543');
      expect(fromMap.hotelName, 'Burdwan Heritage Homestay');
      expect(fromMap.nights, 3);
      expect(fromMap.totalPrice, 1350.0);
      expect(fromMap.guestName, 'Ananya Sharma');
      expect(fromMap.guestPhone, '9871122334');
      expect(fromMap.guestEmail, 'ananya@example.com');
      expect(fromMap.guestIdProofNumber, 'WB-12-2023-1234567');
      expect(fromMap.guestPhotoUrl, 'https://example.com/selfie.jpg');
      expect(fromMap.guestTrustScore, 98.5);
      expect(fromMap.status, 'Confirmed');
      expect(fromMap.paymentStatus, 'Pay at Check-in');
    });

    test('HotelBooking child account isolation serialization', () {
      final now = DateTime(2026, 10, 20, 14, 0);
      final checkOut = DateTime(2026, 10, 22, 11, 0);

      final childBooking = HotelBooking(
        id: 'hb_child_202',
        bookingRef: 'STAY-1122334',
        hotelId: 'h3',
        hotelName: 'Manali Pine Retreat',
        guestName: 'Rohit Roy',
        userId: 'c_rohit',
        accountId: 'c_rohit',
        accountName: 'Rohit (Child)',
        accountType: 'child',
        isChildBooking: true,
        childId: 'c_rohit',
        childName: 'Rohit Roy',
        checkInDate: now,
        checkOutDate: checkOut,
        nights: 2,
        pricePerNight: 600,
        totalPrice: 1200,
      );

      final map = childBooking.toMap();
      expect(map['is_child_booking'], true);
      expect(map['child_id'], 'c_rohit');
      expect(map['account_type'], 'child');

      final deserialized = HotelBooking.fromMap(map);
      expect(deserialized.isChildBooking, true);
      expect(deserialized.childId, 'c_rohit');
      expect(deserialized.accountType, 'child');
      expect(deserialized.totalPrice, 1200);
    });
  });

  group('AppState Hotels and Stays Proximity Tests', () {
    test('AppState calculates distance and sorts hotels by proximity', () {
      final appState = AppState();
      expect(appState.hotels.isNotEmpty, true);

      final available = appState.getAvailableHotelsNearCustomer();
      expect(available.isNotEmpty, true);

      for (int i = 0; i < available.length - 1; i++) {
        final d1 = appState.getDistanceToHotel(available[i]);
        final d2 = appState.getDistanceToHotel(available[i + 1]);
        expect(d1 <= d2, true);
      }

      final firstHotel = available.first;
      final formattedDist = appState.getFormattedDistanceToHotel(firstHotel);
      expect(formattedDist.isNotEmpty, true);
    });
  });
}

