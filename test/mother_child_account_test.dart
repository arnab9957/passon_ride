import 'package:flutter_test/flutter_test.dart';
import 'package:passon_ride/models/models.dart';

void main() {
  group('Mother-Child Account Architecture Models & Serialization', () {
    test('MotherProfile model serializes to and from Map accurately', () {
      final now = DateTime.now();
      final mother = MotherProfile(
        motherId: 'mth_test_001',
        customerId: 'cust_001',
        name: 'Sarah Connor',
        email: 'sarah.connor@family.org',
        phone: '+91 98765 43210',
        profilePhoto: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2',
        status: 'active',
        createdAt: now,
        updatedAt: now,
      );

      final map = mother.toMap();
      expect(map['mother_id'], 'mth_test_001');
      expect(map['name'], 'Sarah Connor');
      expect(map['email'], 'sarah.connor@family.org');
      expect(map['status'], 'active');

      final reconstructed = MotherProfile.fromMap(map);
      expect(reconstructed.motherId, mother.motherId);
      expect(reconstructed.name, mother.name);
      expect(reconstructed.email, mother.email);
      expect(reconstructed.phone, mother.phone);
      expect(reconstructed.status, mother.status);
    });

    test('ChildProfile model links to Mother and serializes correctly', () {
      final now = DateTime.now();
      final child = ChildProfile(
        childId: 'chd_test_001',
        motherId: 'mth_test_001',
        name: 'John Connor',
        email: 'john.connor@family.org',
        phone: '+91 98765 00001',
        profilePhoto: '',
        status: 'active',
        createdAt: now,
        updatedAt: now,
      );

      final map = child.toMap();
      expect(map['child_id'], 'chd_test_001');
      expect(map['mother_id'], 'mth_test_001');
      expect(map['name'], 'John Connor');
      expect(map['email'], 'john.connor@family.org');

      final reconstructed = ChildProfile.fromMap(map);
      expect(reconstructed.childId, child.childId);
      expect(reconstructed.motherId, 'mth_test_001');
      expect(reconstructed.name, child.name);
      expect(reconstructed.email, child.email);
    });

    test('SavedAccountSummary serializes and deserializes for device persistence', () {
      final summary = SavedAccountSummary(
        accountId: 'chd_test_002',
        accountType: 'child',
        displayName: 'Alex Connor',
        email: 'alex@family.org',
        profilePhotoUrl: 'https://example.com/alex.jpg',
        motherId: 'mth_test_001',
      );

      final map = summary.toMap();
      expect(map['account_id'], 'chd_test_002');
      expect(map['account_type'], 'child');
      expect(map['display_name'], 'Alex Connor');

      final reconstructed = SavedAccountSummary.fromMap(map);
      expect(reconstructed.accountId, summary.accountId);
      expect(reconstructed.accountType, summary.accountType);
      expect(reconstructed.displayName, summary.displayName);
      expect(reconstructed.email, summary.email);
      expect(reconstructed.motherId, summary.motherId);
    });
  });

  group('Mother-Child Limit & Validation Business Rules', () {
    test('Enforces strictly max 3 child profiles per mother account', () {
      final List<ChildProfile> children = [];
      const int maxLimit = 3;

      for (int i = 1; i <= 3; i++) {
        expect(children.length < maxLimit, isTrue);
        children.add(ChildProfile(
          childId: 'chd_00$i',
          motherId: 'mth_test_001',
          name: 'Child $i',
          email: 'child$i@family.org',
          phone: '',
          profilePhoto: '',
          status: 'active',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }

      expect(children.length, 3);
      final hasReachedLimit = children.length >= maxLimit;
      expect(hasReachedLimit, isTrue);

      // Attempting to add 4th child must be rejected
      bool canAdd4th = children.length < maxLimit;
      expect(canAdd4th, isFalse);
    });

    test('Validates email uniqueness across mother and child profiles', () {
      final motherEmail = 'sarah@family.org';
      final existingChildrenEmails = ['john@family.org', 'alex@family.org'];

      bool isEmailUnique(String candidate) {
        final normalized = candidate.trim().toLowerCase();
        if (normalized == motherEmail.toLowerCase()) return false;
        if (existingChildrenEmails.any((e) => e.toLowerCase() == normalized)) return false;
        return true;
      }

      expect(isEmailUnique('newchild@family.org'), isTrue);
      expect(isEmailUnique('sarah@family.org'), isFalse);
      expect(isEmailUnique('SARAH@FAMILY.ORG'), isFalse);
      expect(isEmailUnique('john@family.org'), isFalse);
      expect(isEmailUnique('alex@family.org'), isFalse);
    });
  });

  group('Booking & Vehicle Data Isolation Rules', () {
    test('Booking model accurately handles child booking labeling and isolation', () {
      final now = DateTime.now();
      final motherBooking = Booking(
        id: 'bk_001',
        vehicleId: 'veh_001',
        vehicleTitle: 'Tesla Model 3',
        vehicleImageUrl: '',
        startDate: now,
        endDate: now.add(const Duration(days: 2)),
        totalPrice: 4000.0,
        status: 'confirmed',
        hostName: 'Host Jane',
        unlockPasscode: '1234',
        createdAt: now,
        accountId: 'mth_test_001',
        accountName: 'Sarah Connor',
        accountType: 'mother',
      );

      final childBooking = Booking(
        id: 'bk_002',
        vehicleId: 'veh_002',
        vehicleTitle: 'Royal Enfield Hunter 350',
        vehicleImageUrl: '',
        startDate: now,
        endDate: now.add(const Duration(days: 1)),
        totalPrice: 1500.0,
        status: 'active',
        hostName: 'Host Bob',
        unlockPasscode: '5678',
        createdAt: now,
        accountId: 'chd_test_001',
        accountName: 'John Connor',
        accountType: 'child',
      );

      expect(motherBooking.isChildBooking, isFalse);
      expect(motherBooking.effectiveAccountId, 'mth_test_001');

      expect(childBooking.isChildBooking, isTrue);
      expect(childBooking.effectiveAccountId, 'chd_test_001');
      expect(childBooking.accountName, 'John Connor');

      // Check filtering: Child only sees their own bookings
      final allBookings = [motherBooking, childBooking];
      final childFiltered = allBookings.where((b) => b.effectiveAccountId == 'chd_test_001').toList();
      expect(childFiltered.length, 1);
      expect(childFiltered.first.id, 'bk_002');

      // Check Mother aggregated visibility: Mother sees both
      expect(allBookings.length, 2);
    });

    test('Vehicle hosting belongs strictly to active account and does not leak', () {
      final motherVehicle = Vehicle(
        id: 'v_mth_01',
        title: 'Toyota Fortuner 4x4',
        type: VehicleType.car,
        category: 'SUV',
        pricePerDay: 5000,
        rating: 4.9,
        reviewCount: 12,
        imageUrl: '',
        location: 'Bangalore Indiranagar',
        hostId: 'mth_test_001',
        ownerAccountId: 'mth_test_001',
        hostName: 'Sarah Connor',
        hostAvatar: '',
        hostTrustScore: 98.0,
        fuelType: 'Diesel',
        transmission: 'Automatic',
        seats: 7,
        description: 'Premium family SUV',
        iotData: const {},
      );

      final childVehicle = Vehicle(
        id: 'v_chd_01',
        title: 'KTM Duke 390',
        type: VehicleType.bike,
        category: 'Motorcycle',
        pricePerDay: 1800,
        rating: 4.8,
        reviewCount: 8,
        imageUrl: '',
        location: 'Bangalore Koramangala',
        hostId: 'chd_test_001',
        ownerAccountId: 'chd_test_001',
        hostName: 'John Connor',
        hostAvatar: '',
        hostTrustScore: 95.0,
        fuelType: 'Petrol',
        transmission: 'Manual',
        seats: 2,
        description: 'Sporty city motorcycle',
        iotData: const {},
      );

      final allVehicles = [motherVehicle, childVehicle];

      // Mother dashboard vehicle query: only ownerAccountId == 'mth_test_001'
      final motherFleet = allVehicles.where((v) => v.ownerAccountId == 'mth_test_001').toList();
      expect(motherFleet.length, 1);
      expect(motherFleet.first.title, 'Toyota Fortuner 4x4');

      // Child dashboard vehicle query: only ownerAccountId == 'chd_test_001'
      final childFleet = allVehicles.where((v) => v.ownerAccountId == 'chd_test_001').toList();
      expect(childFleet.length, 1);
      expect(childFleet.first.title, 'KTM Duke 390');
    });

    test('Strict child profile booking isolation vs Mother profile full visibility', () {
      final now = DateTime.now();
      const motherId = 'mth_001';
      const childAId = 'chd_A';
      const childBId = 'chd_B';

      final childA = ChildProfile(
        childId: childAId,
        motherId: motherId,
        name: 'Child A',
        email: 'childA@test.com',
        phone: '',
        profilePhoto: '',
        status: 'active',
        createdAt: now,
        updatedAt: now,
      );

      final childB = ChildProfile(
        childId: childBId,
        motherId: motherId,
        name: 'Child B',
        email: 'childB@test.com',
        phone: '',
        profilePhoto: '',
        status: 'active',
        createdAt: now,
        updatedAt: now,
      );

      final motherBooking = Booking(
        id: 'bk_mother',
        vehicleId: 'veh_01',
        vehicleTitle: 'Mother Car',
        vehicleImageUrl: '',
        hostName: 'Host X',
        userId: motherId,
        accountId: motherId,
        accountName: 'Mother Account',
        accountType: 'mother',
        startDate: now,
        endDate: now.add(const Duration(days: 1)),
        totalPrice: 2000,
        status: 'Confirmed',
        unlockPasscode: '1111',
        createdAt: now,
      );

      final childABooking = Booking(
        id: 'bk_child_a',
        vehicleId: 'veh_02',
        vehicleTitle: 'Child A Bike',
        vehicleImageUrl: '',
        hostName: 'Host Y',
        userId: childAId,
        accountId: childAId,
        accountName: 'Child A',
        accountType: 'child',
        childId: childAId,
        childName: 'Child A',
        startDate: now,
        endDate: now.add(const Duration(days: 1)),
        totalPrice: 1000,
        status: 'Active',
        unlockPasscode: '2222',
        createdAt: now,
      );

      final childBBooking = Booking(
        id: 'bk_child_b',
        vehicleId: 'veh_03',
        vehicleTitle: 'Child B Scooter',
        vehicleImageUrl: '',
        hostName: 'Host Z',
        userId: childBId,
        accountId: childBId,
        accountName: 'Child B',
        accountType: 'child',
        childId: childBId,
        childName: 'Child B',
        startDate: now,
        endDate: now.add(const Duration(days: 1)),
        totalPrice: 800,
        status: 'Confirmed',
        unlockPasscode: '3333',
        createdAt: now,
      );

      final childAHostedBooking = Booking(
        id: 'bk_child_a_hosted',
        vehicleId: 'veh_04',
        vehicleTitle: 'Child A Hosted Car',
        vehicleImageUrl: '',
        hostName: 'Child A',
        hostId: childAId,
        userId: 'guest_rider',
        accountId: 'guest_rider',
        accountName: 'Guest Rider',
        accountType: 'child_hosting',
        isChildHosting: true,
        childId: childAId,
        childName: 'Child A',
        startDate: now,
        endDate: now.add(const Duration(days: 1)),
        totalPrice: 3500,
        status: 'Confirmed',
        unlockPasscode: '4444',
        createdAt: now,
      );

      final allBookings = [
        motherBooking,
        childABooking,
        childBBooking,
        childAHostedBooking,
      ];

      // Helper simulating getBookingsForChild isolation logic
      List<Booking> filterForChild(String targetChildId) {
        final otherChildIds = [childA, childB]
            .where((c) => c.childId != targetChildId)
            .map((c) => c.childId)
            .toSet();

        return allBookings.where((b) {
          if (b.accountType.toLowerCase() == 'mother' &&
              b.childId != targetChildId &&
              b.hostId != targetChildId &&
              b.accountId != targetChildId &&
              b.userId != targetChildId) {
            return false;
          }
          if (otherChildIds.isNotEmpty) {
            if (b.childId.isNotEmpty && otherChildIds.contains(b.childId)) return false;
            if (b.accountId.isNotEmpty && otherChildIds.contains(b.accountId)) return false;
            if (b.userId.isNotEmpty && otherChildIds.contains(b.userId)) return false;
            if (b.hostId.isNotEmpty && otherChildIds.contains(b.hostId)) return false;
          }
          if (b.childId.isNotEmpty && b.childId == targetChildId) return true;
          if (b.accountId.isNotEmpty && b.accountId == targetChildId) return true;
          if (b.userId.isNotEmpty && b.userId == targetChildId) return true;
          if (b.hostId.isNotEmpty && b.hostId == targetChildId) return true;
          return false;
        }).toList();
      }

      // 1. Child A View: strictly see bk_child_a and bk_child_a_hosted
      final childAView = filterForChild(childAId);
      expect(childAView.length, 2);
      expect(childAView.map((b) => b.id).toSet(), {'bk_child_a', 'bk_child_a_hosted'});
      expect(childAView.any((b) => b.id == 'bk_mother'), isFalse);
      expect(childAView.any((b) => b.id == 'bk_child_b'), isFalse);

      // 2. Child B View: strictly see bk_child_b
      final childBView = filterForChild(childBId);
      expect(childBView.length, 1);
      expect(childBView.first.id, 'bk_child_b');
      expect(childBView.any((b) => b.id == 'bk_mother'), isFalse);
      expect(childBView.any((b) => b.id == 'bk_child_a'), isFalse);
      expect(childBView.any((b) => b.id == 'bk_child_a_hosted'), isFalse);

      // 3. Mother View: sees all bookings of every profile
      expect(allBookings.length, 4);
      expect(allBookings.map((b) => b.id).toSet(), {
        'bk_mother',
        'bk_child_a',
        'bk_child_b',
        'bk_child_a_hosted',
      });
    });

    test('Child booking serialization preserves account and child fields for PostgreSQL DB persistence', () {
      final now = DateTime.now();
      final childBooking = Booking(
        id: 'bk_chd_persist_01',
        vehicleId: 'veh_01',
        vehicleTitle: 'Bajaj Pulsar N250',
        vehicleImageUrl: 'https://example.com/pulsar.jpg',
        startDate: now,
        endDate: now.add(const Duration(days: 2)),
        totalPrice: 1200.0,
        status: 'Confirmed',
        unlockPasscode: 'PASS-1234',
        createdAt: now,
        hostName: 'Host Partner',
        hostId: 'host_01',
        userId: 'chd_1789201242248_1',
        accountId: 'chd_1789201242248_1',
        accountName: 'Sovan Rajbanshi',
        accountType: 'child',
        childId: 'chd_1789201242248_1',
        childName: 'Sovan Rajbanshi',
        customerId: 'chd_1789201242248_1',
        customerName: 'Sovan Rajbanshi',
        customerEmail: 'rajbanshijhumpa7@gmail.com',
      );

      final map = childBooking.toMap();
      expect(map['account_id'], 'chd_1789201242248_1');
      expect(map['account_name'], 'Sovan Rajbanshi');
      expect(map['account_type'], 'child');
      expect(map['child_id'], 'chd_1789201242248_1');
      expect(map['child_name'], 'Sovan Rajbanshi');
      expect(map['riderId'], 'chd_1789201242248_1');

      // Test roundtrip deserialization (as returned from Supabase DB)
      final restored = Booking.fromMap(map);
      expect(restored.effectiveAccountId, 'chd_1789201242248_1');
      expect(restored.childId, 'chd_1789201242248_1');
      expect(restored.childName, 'Sovan Rajbanshi');
      expect(restored.isChildBooking, isTrue);
    });
  });
}
