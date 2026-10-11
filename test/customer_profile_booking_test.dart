import 'package:flutter_test/flutter_test.dart';
import 'package:passon_ride/models/models.dart';

void main() {
  group('Customer Profile and Booking Sanitization Tests', () {
    test('Booking.fromMap discards "Self" and fake fallbacks', () {
      final rawMap = {
        'id': 'b_123',
        'vehicleId': 'v_1',
        'vehicleTitle': 'Royal Enfield Classic 350',
        'vehicleImageUrl': 'https://example.com/bike.jpg',
        'hostName': 'Host John',
        'userId': 'mth_1e5a33ad-96b5-4abe-a3b9-cf4ad9842db5',
        'customerId': '1e5a33ad-96b5-4abe-a3b9-cf4ad9842db5',
        'customer_name': 'Self',
        'customer_email': 'verified.rider@passionride.com',
        'customer_phone': '+91 98765 43210',
        'customer_driving_license_number': 'DL-042023008914',
        'startDate': DateTime.now().toIso8601String(),
        'endDate': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
        'totalPrice': 1500.0,
        'status': 'confirmed',
        'createdAt': DateTime.now().toIso8601String(),
      };

      final booking = Booking.fromMap(rawMap);

      // Verify that "Self", fake email, and fake phone are discarded
      expect(booking.customerName, isEmpty);
      expect(booking.customerEmail, isEmpty);
      expect(booking.customerPhone, isEmpty);
    });

    test('Booking.fromMap retains genuine user profile details', () {
      final rawMap = {
        'id': 'b_456',
        'vehicleId': 'v_2',
        'vehicleTitle': 'KTM Duke 390',
        'vehicleImageUrl': 'https://example.com/ktm.jpg',
        'hostName': 'Host Alex',
        'userId': 'user_abc_123',
        'customerId': 'user_abc_123',
        'customer_name': 'Sovan Rajbanshi',
        'customer_email': 'sovan@example.com',
        'customer_phone': '+91 98111 22233',
        'customer_live_photo_url': 'https://example.com/selfie.jpg',
        'customer_live_photo_base64': 'data:image/jpeg;base64,/9j/4AAQSkZJRg==',
        'startDate': DateTime.now().toIso8601String(),
        'endDate': DateTime.now().add(const Duration(days: 2)).toIso8601String(),
        'totalPrice': 3000.0,
        'status': 'active',
        'createdAt': DateTime.now().toIso8601String(),
      };

      final booking = Booking.fromMap(rawMap);

      expect(booking.customerName, 'Sovan Rajbanshi');
      expect(booking.customerEmail, 'sovan@example.com');
      expect(booking.customerPhone, '+91 98111 22233');
      expect(booking.customerLivePhotoUrl, 'https://example.com/selfie.jpg');
      expect(booking.customerLivePhotoBase64, 'data:image/jpeg;base64,/9j/4AAQSkZJRg==');

      final serialized = booking.toMap();
      expect(serialized['customer_live_photo_base64'], 'data:image/jpeg;base64,/9j/4AAQSkZJRg==');
    });
  });
}
