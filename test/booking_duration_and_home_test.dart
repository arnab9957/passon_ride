import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:passon_ride/providers/app_state.dart';
import 'package:passon_ride/models/models.dart';

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

  Vehicle createTestVehicle({double pricePerDay = 1200.0}) {
    return Vehicle.fromMap({
      'id': 'veh_test_1',
      'title': 'Royal Enfield Hunter 350',
      'category': 'Motorcycle',
      'type': 'Cruiser',
      'price_per_day': pricePerDay,
      'rating': 4.8,
      'review_count': 10,
      'image_url': 'https://example.com/bike.jpg',
      'location': 'Park Street',
      'host_name': 'Sovan Rajbanshi',
      'host_avatar': 'https://example.com/avatar.jpg',
      'host_trust_score': 98.0,
      'host_id': 'auth_uid_123',
      'owner_account_id': 'chd_1',
      'fuel_type': 'Petrol',
      'transmission': 'Manual',
      'seats': 2,
      'description': 'Clean bike',
      'iot_data': {'battery': 95},
    });
  }

  group('Default 1-Day Booking Duration Tests', () {
    test('AppState initializes default booking duration to exactly 1 day', () {
      final appState = AppState();

      // Check pickup is 1 day in the future at 10:00
      expect(appState.pickupDateTime.hour, 10);
      expect(appState.pickupDateTime.minute, 0);

      // Check dropoff is 1 day after pickup at 10:00
      expect(appState.dropoffDateTime.hour, 10);
      expect(appState.dropoffDateTime.minute, 0);

      final diff = appState.dropoffDateTime.difference(appState.pickupDateTime);
      expect(diff.inDays, 1);
      expect(diff.inHours, 24);
      expect(appState.rentalDaysCount, 1);
    });

    test('selectVehicle sets/maintains 1-day default booking duration', () {
      final appState = AppState();
      final testVehicle = createTestVehicle(pricePerDay: 850.0);

      appState.selectVehicle(testVehicle);

      expect(appState.selectedVehicle?.id, testVehicle.id);
      expect(appState.rentalDaysCount, 1);

      // Rental charge should be exactly 1 day base rate
      final calculatedPrice = testVehicle.calculateRentalPrice(
        appState.rentalStartDate,
        appState.rentalEndDate,
      );
      expect(calculatedPrice, 850.0);
    });

    test('setRentalDurationDays adjusts duration correctly', () {
      final appState = AppState();

      appState.setRentalDurationDays(1);
      expect(appState.rentalDaysCount, 1);

      appState.setRentalDurationDays(2);
      expect(appState.rentalDaysCount, 2);

      appState.setRentalDurationDays(3);
      expect(appState.rentalDaysCount, 3);

      // Resetting back to default 1-day
      appState.setDefaultRentalDates();
      expect(appState.rentalDaysCount, 1);
    });

    test('calculateRentalPrice for 1 day equals pricePerDay', () {
      final vehicle = createTestVehicle(pricePerDay: 1200.0);

      final now = DateTime.now();
      final pickup = DateTime(now.year, now.month, now.day + 1, 10, 0);
      final dropoff = DateTime(now.year, now.month, now.day + 2, 10, 0);

      final price = vehicle.calculateRentalPrice(pickup, dropoff);
      expect(price, 1200.0);
    });
  });
}
