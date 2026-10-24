import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:passon_ride/models/models.dart';
import 'package:passon_ride/models/feedback_model.dart';
import 'package:passon_ride/providers/app_state.dart';
import 'package:passon_ride/irsargo/context_collector.dart';

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

  group('Phase 1 & 2: HotelRoom & BlockedRange Model Tests', () {
    test('HotelRoom serialization, defaults & weekend pricing calculation', () {
      final room = HotelRoom(
        id: 'room_101',
        hotelId: 'hotel_xyz',
        name: 'Deluxe Heritage Room',
        roomType: 'Private Room',
        basePrice: 600.0,
        weekendPrice: 750.0,
        capacity: 3,
        quantity: 4,
        amenities: ['Free Wi-Fi', 'Attached Bathroom'],
        status: RoomCleanStatus.clean,
      );

      // Friday rate test (weekend rate)
      final fridayDate = DateTime(2026, 10, 16); // Friday
      expect(fridayDate.weekday, DateTime.friday);
      expect(room.getPriceForDate(fridayDate), 750.0);

      // Wednesday rate test (base rate)
      final wednesdayDate = DateTime(2026, 10, 14); // Wednesday
      expect(room.getPriceForDate(wednesdayDate), 600.0);

      // Serialization
      final map = room.toMap();
      expect(map['id'], 'room_101');
      expect(map['status'], 'clean');
      expect(map['quantity'], 4);

      final deserialized = HotelRoom.fromMap(map);
      expect(deserialized.id, 'room_101');
      expect(deserialized.weekendPrice, 750.0);
      expect(deserialized.status, RoomCleanStatus.clean);
    });

    test('BlockedRange model serialization and date parsing', () {
      final start = DateTime(2026, 11, 1);
      final end = DateTime(2026, 11, 5);
      final block = BlockedRange(
        id: 'block_01',
        roomId: 'room_101',
        startDate: start,
        endDate: end,
        reason: 'Roof repair & painting',
      );

      final map = block.toMap();
      expect(map['room_id'], 'room_101');
      expect(map['start_date'], '2026-11-01');
      expect(map['end_date'], '2026-11-05');

      final deserialized = BlockedRange.fromMap(map);
      expect(deserialized.id, 'block_01');
      expect(deserialized.reason, 'Roof repair & painting');
      expect(deserialized.startDate.year, 2026);
      expect(deserialized.endDate.day, 5);
    });

    test('HotelBooking extended fields (roomId, roomCount, check-in/out timestamps)', () {
      final now = DateTime.now();
      final booking = HotelBooking(
        id: 'hb_999',
        bookingRef: 'STAY-999123',
        hotelId: 'hotel_xyz',
        hotelName: 'Green Homestay',
        guestName: 'Arnab Roy',
        checkInDate: now,
        checkOutDate: now.add(const Duration(days: 2)),
        roomId: 'room_101',
        roomCount: 2,
        pricePerNight: 600.0,
        totalPrice: 1200.0,
      );

      expect(booking.roomId, 'room_101');
      expect(booking.roomCount, 2);
      expect(booking.checkedInAt, isNull);

      final checkInTime = DateTime.now();
      final checkedInBooking = booking.copyWith(
        status: 'Active',
        checkedInAt: checkInTime,
      );
      expect(checkedInBooking.status, 'Active');
      expect(checkedInBooking.checkedInAt, checkInTime);

      final map = checkedInBooking.toMap();
      expect(map['room_id'], 'room_101');
      expect(map['room_count'], 2);
      expect(map['checked_in_at'], isNotNull);

      final deserialized = HotelBooking.fromMap(map);
      expect(deserialized.roomId, 'room_101');
      expect(deserialized.roomCount, 2);
      expect(deserialized.status, 'Active');
    });
  });

  group('Phase 2: AppState Front Desk & Rooms Management', () {
    test('AppState saves room, updates housekeeping status and processes check-in/out', () async {
      final appState = AppState();

      final room = HotelRoom(
        id: 'room_test_pms',
        hotelId: 'hotel_test_pms',
        name: 'Deluxe Room',
        basePrice: 550.0,
        status: RoomCleanStatus.clean,
      );

      await appState.saveHotelRoom(room);
      var rooms = appState.getRoomsForHotel('hotel_test_pms');
      expect(rooms.any((r) => r.id == 'room_test_pms'), true);

      // Toggle housekeeping to dirty
      await appState.updateRoomStatus('hotel_test_pms', 'room_test_pms', RoomCleanStatus.dirty);
      rooms = appState.getRoomsForHotel('hotel_test_pms');
      final updatedRoom = rooms.firstWhere((r) => r.id == 'room_test_pms');
      expect(updatedRoom.status, RoomCleanStatus.dirty);

      // Create booking and test check-in & check-out lifecycle
      final booking = HotelBooking(
        id: 'hb_lifecycle_1',
        bookingRef: 'STAY-888888',
        hotelId: 'hotel_test_pms',
        hotelName: 'PMS Test Stay',
        guestName: 'Guest John',
        checkInDate: DateTime.now(),
        checkOutDate: DateTime.now().add(const Duration(days: 1)),
        roomId: 'room_test_pms',
        pricePerNight: 550.0,
        totalPrice: 550.0,
        status: 'Confirmed',
      );

      await appState.createHotelBooking(booking);
      expect(appState.hotelBookings.any((b) => b.id == 'hb_lifecycle_1'), true);

      // Check-in guest
      await appState.checkInHotelGuest('hb_lifecycle_1');
      final activeBooking = appState.hotelBookings.firstWhere((b) => b.id == 'hb_lifecycle_1');
      expect(activeBooking.status, 'Active');
      expect(activeBooking.checkedInAt, isNotNull);

      // Check-out guest
      await appState.checkOutHotelGuest('hb_lifecycle_1');
      final completedBooking = appState.hotelBookings.firstWhere((b) => b.id == 'hb_lifecycle_1');
      expect(completedBooking.status, 'Completed');
      expect(completedBooking.checkedOutAt, isNotNull);
    });
  });

  group('Phase 4: Feedback Model with Hotel Ratings & Irsargo Concierge Context', () {
    test('TripAspectReview supports hotelId and location rating', () {
      final review = TripAspectReview(
        id: 'rev_hotel_1',
        hotelId: 'hotel_test_pms',
        riderId: 'rider_1',
        hostId: 'host_1',
        riderName: 'Priya Sen',
        riderAvatar: 'https://example.com/avatar.jpg',
        overallRating: 4.8,
        cleanlinessRating: 4.9,
        locationRating: 4.7,
        valueRating: 5.0,
        comment: 'Splendid authentic local hospitality, clean rooms and peaceful environment!',
      );

      final map = review.toMap();
      expect(map['hotel_id'], 'hotel_test_pms');
      expect(map['location_rating'], 4.7);

      final deserialized = TripAspectReview.fromMap(map);
      expect(deserialized.hotelId, 'hotel_test_pms');
      expect(deserialized.locationRating, 4.7);
      expect(deserialized.cleanlinessRating, 4.9);
    });

    test('IrsargoContextCollector incorporates active stay concierge info', () {
      final appState = AppState();
      final contextText = IrsargoContextCollector.collectPublicAppContext(appState);

      // Context string should collect without errors and provide valid information
      expect(contextText.isNotEmpty, true);
      expect(contextText.contains('Active Flutter Screen:'), true);
    });
  });
}
