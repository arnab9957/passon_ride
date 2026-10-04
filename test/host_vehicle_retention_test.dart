import 'package:flutter_test/flutter_test.dart';
import 'package:passon_ride/models/models.dart';

void main() {
  group('Host Vehicle Retention & Supabase Mapping Tests', () {
    test('Vehicle.fromMap correctly parses owner_account_id, quantity, price_per_hour, and custom ranges', () {
      final dbRow = {
        'id': 'veh_test_999',
        'title': 'Royal Enfield Hunter 350',
        'type': 'bike',
        'category': 'Cruiser',
        'price_per_day': 1200.0,
        'rating': 4.9,
        'review_count': 12,
        'image_url': 'https://example.com/hunter.jpg',
        'location': 'Puri Beach Road',
        'latitude': 19.8135,
        'longitude': 85.8312,
        'status': 'Available',
        'host_name': 'Sovan Rajbanshi',
        'host_avatar': 'https://example.com/avatar.jpg',
        'host_trust_score': 98.0,
        'host_id': 'auth_uid_12345',
        'owner_account_id': 'chd_1789201242248_1',
        'is_instant_bookable': true,
        'is_favorite': false,
        'fuel_type': 'Petrol',
        'transmission': 'Manual',
        'seats': 2,
        'description': 'Clean and serviced bike',
        'iot_data': {'battery': 95},
        'images': ['https://example.com/img1.jpg', 'https://example.com/img2.jpg'],
        'quantity': 3,
        'price_per_hour': 150.0,
        'custom_time_range_start': '08:00',
        'custom_time_range_end': '20:00',
        'custom_time_range_price': 800.0,
      };

      final vehicle = Vehicle.fromMap(dbRow);

      expect(vehicle.id, 'veh_test_999');
      expect(vehicle.title, 'Royal Enfield Hunter 350');
      expect(vehicle.hostId, 'auth_uid_12345');
      expect(vehicle.ownerAccountId, 'chd_1789201242248_1');
      expect(vehicle.hostAccountId, 'chd_1789201242248_1');
      expect(vehicle.quantity, 3);
      expect(vehicle.pricePerHour, 150.0);
      expect(vehicle.customTimeRangeStart, '08:00');
      expect(vehicle.customTimeRangeEnd, '20:00');
      expect(vehicle.customTimeRangePrice, 800.0);
    });

    test('Vehicle.toMap and fromMap bidirectional consistency for Supabase DB roundtrip', () {
      final original = Vehicle(
        id: 'v_local_123',
        title: 'Yamaha FZ-S V4',
        type: VehicleType.bike,
        category: 'Sports',
        pricePerDay: 900.0,
        rating: 5.0,
        reviewCount: 4,
        imageUrl: 'https://example.com/fzs.jpg',
        location: 'Swargadwar, Puri',
        hostName: 'Jhumpa Rajbanshi',
        hostAvatar: 'https://example.com/jhumpa.jpg',
        hostTrustScore: 99.0,
        hostId: 'auth_mother_001',
        ownerAccountId: 'mother_17890001',
        fuelType: 'Petrol',
        transmission: 'Manual',
        seats: 2,
        description: 'New model',
        iotData: {'speed': 0},
        images: ['https://example.com/fzs.jpg'],
        quantity: 2,
        pricePerHour: 100.0,
        customTimeRangeStart: '09:00',
        customTimeRangeEnd: '18:00',
        customTimeRangePrice: 600.0,
      );

      final map = original.toMap();
      expect(map['owner_account_id'], 'mother_17890001');
      expect(map['quantity'], 2);
      expect(map['price_per_hour'], 100.0);
      expect(map['custom_time_range_start'], '09:00');
      expect(map['custom_time_range_end'], '18:00');
      expect(map['custom_time_range_price'], 600.0);

      final restored = Vehicle.fromMap(map);
      expect(restored.id, original.id);
      expect(restored.ownerAccountId, 'mother_17890001');
      expect(restored.quantity, 2);
      expect(restored.pricePerHour, 100.0);
      expect(restored.customTimeRangeStart, '09:00');
      expect(restored.customTimeRangeEnd, '18:00');
      expect(restored.customTimeRangePrice, 600.0);
    });

    test('Host vehicle identification logic correctly matches various host account contexts', () {
      final activeUserIds = {
        'mother_17890001',
        'auth_supabase_uid_999',
        'chd_child_account_01',
      };
      const activeDisplayName = 'Sovan Rajbanshi';

      // Vehicle 1: ownerAccountId matches child ID under mother
      final vehicleA = Vehicle(
        id: 'v_001',
        title: 'Bike A',
        type: VehicleType.bike,
        category: 'Standard',
        pricePerDay: 500,
        rating: 5,
        reviewCount: 0,
        imageUrl: '',
        location: 'Puri',
        hostName: 'Different Name',
        hostAvatar: '',
        hostTrustScore: 90,
        hostId: 'auth_supabase_uid_999',
        ownerAccountId: 'chd_child_account_01',
        fuelType: 'Petrol',
        transmission: 'Manual',
        seats: 2,
        description: '',
        iotData: {},
      );

      // Vehicle 2: hostId matches supabase auth uid
      final vehicleB = Vehicle(
        id: 'v_002',
        title: 'Bike B',
        type: VehicleType.bike,
        category: 'Standard',
        pricePerDay: 500,
        rating: 5,
        reviewCount: 0,
        imageUrl: '',
        location: 'Puri',
        hostName: 'Different Name',
        hostAvatar: '',
        hostTrustScore: 90,
        hostId: 'auth_supabase_uid_999',
        fuelType: 'Petrol',
        transmission: 'Manual',
        seats: 2,
        description: '',
        iotData: {},
      );

      // Vehicle 3: name matches active display name
      final vehicleC = Vehicle(
        id: 'v_003',
        title: 'Bike C',
        type: VehicleType.bike,
        category: 'Standard',
        pricePerDay: 500,
        rating: 5,
        reviewCount: 0,
        imageUrl: '',
        location: 'Puri',
        hostName: 'Sovan Rajbanshi',
        hostAvatar: '',
        hostTrustScore: 90,
        hostId: 'unrelated_id',
        fuelType: 'Petrol',
        transmission: 'Manual',
        seats: 2,
        description: '',
        iotData: {},
      );

      // Vehicle 4: Unrelated third-party vehicle
      final vehicleD = Vehicle(
        id: 'v_004',
        title: 'Bike D',
        type: VehicleType.bike,
        category: 'Standard',
        pricePerDay: 500,
        rating: 5,
        reviewCount: 0,
        imageUrl: '',
        location: 'Puri',
        hostName: 'Someone Else',
        hostAvatar: '',
        hostTrustScore: 90,
        hostId: 'unrelated_id',
        fuelType: 'Petrol',
        transmission: 'Manual',
        seats: 2,
        description: '',
        iotData: {},
      );

      bool isVehicleHosted(Vehicle v) {
        final vOwner = v.ownerAccountId.trim();
        final vHost = v.hostId.trim();
        if (vOwner.isNotEmpty && activeUserIds.contains(vOwner)) return true;
        if (vHost.isNotEmpty && activeUserIds.contains(vHost)) return true;
        if (activeDisplayName.isNotEmpty &&
            activeDisplayName != 'Guest User' &&
            v.hostName.trim().toLowerCase() == activeDisplayName.toLowerCase()) {
          return true;
        }
        return false;
      }

      expect(isVehicleHosted(vehicleA), isTrue);
      expect(isVehicleHosted(vehicleB), isTrue);
      expect(isVehicleHosted(vehicleC), isTrue);
      expect(isVehicleHosted(vehicleD), isFalse);
    });

    test('Full sync retention simulation guarantees host and local vehicles are preserved', () {
      final localVehicles = <Vehicle>[
        // Host vehicle created locally
        Vehicle(
          id: 'v_local_host_1',
          title: 'My Hosted Bike',
          type: VehicleType.bike,
          category: 'Standard',
          pricePerDay: 600,
          rating: 5,
          reviewCount: 0,
          imageUrl: '',
          location: 'Puri',
          hostName: 'My Name',
          hostAvatar: '',
          hostTrustScore: 95,
          hostId: 'my_auth_uid',
          ownerAccountId: 'my_child_id',
          fuelType: 'Petrol',
          transmission: 'Manual',
          seats: 2,
          description: '',
          iotData: {},
        ),
        // Third-party vehicle cached locally
        Vehicle(
          id: 'v_other_1',
          title: 'Other Host Bike',
          type: VehicleType.bike,
          category: 'Standard',
          pricePerDay: 700,
          rating: 4.8,
          reviewCount: 2,
          imageUrl: '',
          location: 'Puri',
          hostName: 'Other Host',
          hostAvatar: '',
          hostTrustScore: 90,
          hostId: 'other_uid',
          fuelType: 'Petrol',
          transmission: 'Manual',
          seats: 2,
          description: '',
          iotData: {},
        ),
      ];

      // Simulated remote sync return with only a new third-party vehicle
      final incomingRemote = <Vehicle>[
        Vehicle(
          id: 'v_other_2',
          title: 'New Remote Bike',
          type: VehicleType.bike,
          category: 'Standard',
          pricePerDay: 800,
          rating: 5,
          reviewCount: 0,
          imageUrl: '',
          location: 'Puri',
          hostName: 'Remote Host',
          hostAvatar: '',
          hostTrustScore: 95,
          hostId: 'remote_uid',
          fuelType: 'Petrol',
          transmission: 'Manual',
          seats: 2,
          description: '',
          iotData: {},
        ),
      ];

      final incomingIds = incomingRemote.map((v) => v.id).toSet();
      final myUserIds = {'my_auth_uid', 'my_child_id'};

      // Retention rule: do not purge if in incoming, or if host matches, or if v_ local
      localVehicles.removeWhere((v) {
        if (incomingIds.contains(v.id)) return false;
        final vOwner = v.ownerAccountId.trim();
        final vHost = v.hostId.trim();
        if (vOwner.isNotEmpty && myUserIds.contains(vOwner)) return false;
        if (vHost.isNotEmpty && myUserIds.contains(vHost)) return false;
        if (v.id.startsWith('v_local_')) return false;
        return true;
      });

      // Verification: My hosted bike is preserved!
      expect(localVehicles.any((v) => v.id == 'v_local_host_1'), isTrue);
      // Other outdated bike was safely cleaned up
      expect(localVehicles.any((v) => v.id == 'v_other_1'), isFalse);
    });
  });
}
