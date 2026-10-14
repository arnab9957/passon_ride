import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:passon_ride/models/models.dart';
import 'package:passon_ride/providers/app_state.dart';
import 'package:passon_ride/services/document_ocr_service.dart';
import 'package:passon_ride/widgets/stay_document_viewer_dialog.dart';

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
      if (appState.hotels.isEmpty) {
        appState.addHotel(Hotel(
          id: 'h_test_near',
          name: 'Near Stay',
          location: 'Kolkata',
          latitude: 22.5726,
          longitude: 88.3639,
          pricePerNight: 500,
          description: 'Near stay',
          hostName: 'Host 1',
        ));
        appState.addHotel(Hotel(
          id: 'h_test_far',
          name: 'Far Stay',
          location: 'Darjeeling',
          latitude: 27.0410,
          longitude: 88.2663,
          pricePerNight: 800,
          description: 'Far stay',
          hostName: 'Host 2',
        ));
      }
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

  group('Multi-Person Hotel Booking & Aadhaar OCR Tests', () {
    test('HotelGuestDetail model serialization and copyWith', () {
      const guest = HotelGuestDetail(
        name: 'Rajesh Sharma',
        aadharNumber: '4921 7840 3165',
        mobileNumber: '9876543210',
        dob: '15/08/1990',
        address: 'Plot 42, Salt Lake, Kolkata',
      );

      final map = guest.toMap();
      expect(map['name'], 'Rajesh Sharma');
      expect(map['aadhar_number'], '4921 7840 3165');
      expect(map['mobile_number'], '9876543210');
      expect(map['dob'], '15/08/1990');
      expect(map['address'], 'Plot 42, Salt Lake, Kolkata');

      final fromMap = HotelGuestDetail.fromMap(map);
      expect(fromMap.name, 'Rajesh Sharma');
      expect(fromMap.aadharNumber, '4921 7840 3165');
      expect(fromMap.mobileNumber, '9876543210');
      expect(fromMap.dob, '15/08/1990');

      final updated = guest.copyWith(name: 'Rajesh K. Sharma');
      expect(updated.name, 'Rajesh K. Sharma');
      expect(updated.aadharNumber, '4921 7840 3165');
    });

    test('HotelBooking multi-person booking serialization and deserialization', () {
      final now = DateTime(2026, 10, 15);
      final guests = [
        const HotelGuestDetail(
          name: 'Rajesh Sharma',
          aadharNumber: '4921 7840 3165',
          mobileNumber: '9876543210',
          dob: '15/08/1990',
          address: 'Plot 42, Salt Lake, Kolkata',
        ),
        const HotelGuestDetail(
          name: 'Sunita Sharma',
          aadharNumber: '5566 7788 9900',
          mobileNumber: '9876543211',
          dob: '10/05/1992',
          address: 'Plot 42, Salt Lake, Kolkata',
        ),
        const HotelGuestDetail(
          name: 'Aarav Sharma',
          aadharNumber: '1122 3344 5566',
          mobileNumber: '9876543212',
          dob: '20/12/2015',
          address: 'Plot 42, Salt Lake, Kolkata',
        ),
      ];

      final booking = HotelBooking(
        id: 'hb_multi_1',
        bookingRef: 'STAY-MULTI-001',
        hotelId: 'h_darjeeling',
        hotelName: 'Himalayan Homestay',
        guestName: guests.first.name,
        guestPhone: guests.first.mobileNumber,
        guestIdProofType: 'Aadhaar Card',
        guestIdProofNumber: guests.first.aadharNumber,
        guests: guests,
        numGuests: 3,
        checkInDate: now,
        checkOutDate: now.add(const Duration(days: 2)),
        pricePerNight: 800,
        totalPrice: 1600,
      );

      final map = booking.toMap();
      expect(map['num_guests'], 3);
      expect(map['guests'], isA<List>());
      expect((map['guests'] as List).length, 3);
      expect((map['guests'] as List)[1]['name'], 'Sunita Sharma');
      expect((map['guests'] as List)[1]['aadhar_number'], '5566 7788 9900');

      final deserialized = HotelBooking.fromMap(map);
      expect(deserialized.numGuests, 3);
      expect(deserialized.guests.length, 3);
      expect(deserialized.guests[0].name, 'Rajesh Sharma');
      expect(deserialized.guests[0].aadharNumber, '4921 7840 3165');
      expect(deserialized.guests[1].name, 'Sunita Sharma');
      expect(deserialized.guests[2].name, 'Aarav Sharma');
    });

    test('HotelBooking backwards compatibility with legacy booking without guests array', () {
      final legacyMap = {
        'id': 'hb_legacy_1',
        'booking_ref': 'STAY-LEGACY',
        'hotel_id': 'h_legacy',
        'hotel_name': 'Heritage Stay',
        'guest_name': 'Alok Kumar',
        'guest_phone': '9870001111',
        'guest_id_proof_number': '1234 5678 9012',
        'check_in_date': '2026-10-15T12:00:00.000',
        'check_out_date': '2026-10-16T11:00:00.000',
        'price_per_night': 500.0,
        'total_price': 500.0,
      };

      final parsed = HotelBooking.fromMap(legacyMap);
      expect(parsed.guests.length, 1);
      expect(parsed.guests.first.name, 'Alok Kumar');
      expect(parsed.guests.first.mobileNumber, '9870001111');
      expect(parsed.guests.first.aadharNumber, '1234 5678 9012');
    });

    test('DocumentOcrService extracts Aadhaar card number, name, DOB, and address', () async {
      final sample = DocumentOcrService.getPresetSample('Aadhaar Card');
      expect(sample.docType, anyOf('Aadhaar Card', 'Aadhar Card'));
      expect(sample.holderName.isNotEmpty, true);
      expect(sample.documentNumber.contains('6742'), true);
      expect(sample.dob.isNotEmpty, true);
      expect(sample.address.contains('Kolkata'), true);

      // Verify text processing with sample Aadhaar content
      const rawAadhaarScan = '''
GOVERNMENT OF INDIA
Unique Identification Authority of India
Enrollment No: 1045/89012/34567
Name: Rajesh Sharma
Date of Birth: 15/08/1990
Gender: MALE
Aadhaar No: 4921 7840 3165
Address: Plot 42, Sector 14, Salt Lake, Kolkata, West Bengal - 700091
''';
      final result = await DocumentOcrService.processDocument(
        fileName: 'aadhaar_scan.jpg',
        selectedDocType: 'Aadhaar Card',
        bytes: rawAadhaarScan.codeUnits,
      );
      expect(result.documentNumber, '4921 7840 3165');
      expect(result.holderName, 'Rajesh Sharma');
      expect(result.dob, anyOf('1990-08-15', '15/08/1990'));
      expect(result.address.contains('Salt Lake'), true);
    });

    test('HotelGuestDetail preserves idProofUrl across serialization and copies', () {
      const guest = HotelGuestDetail(
        name: 'Sourav Roy',
        aadharNumber: '9988 7766 5544',
        mobileNumber: '9830112233',
        dob: '1992-06-21',
        address: 'Ballygunge, Kolkata',
        idProofUrl: 'https://ik.imagekit.io/hsqoovxu0/hotel_guest_aadhaar/guest1_aadhaar.jpg',
      );

      final map = guest.toMap();
      expect(map['id_proof_url'], 'https://ik.imagekit.io/hsqoovxu0/hotel_guest_aadhaar/guest1_aadhaar.jpg');

      final fromMap = HotelGuestDetail.fromMap(map);
      expect(fromMap.idProofUrl, 'https://ik.imagekit.io/hsqoovxu0/hotel_guest_aadhaar/guest1_aadhaar.jpg');
      expect(fromMap.name, 'Sourav Roy');
      expect(fromMap.aadharNumber, '9988 7766 5544');

      final updated = guest.copyWith(idProofUrl: 'data:image/jpeg;base64,samplebase64');
      expect(updated.idProofUrl, 'data:image/jpeg;base64,samplebase64');
      expect(updated.name, 'Sourav Roy');
    });

    test('canViewStayGuestDocuments strictly enforces customer and host-only access control', () async {
      final appState = AppState();
      final now = DateTime.now();

      final booking = HotelBooking(
        id: 'hb_secure_101',
        bookingRef: 'STAY-998877',
        hotelId: 'hotel_himalaya',
        hotelName: 'Himalayan Homestay',
        hotelLocation: 'Darjeeling',
        hotelImageUrl: 'https://example.com/hotel.jpg',
        roomType: 'Deluxe View Room',
        guestName: 'Priya Sen',
        userId: 'customer_acc_1',
        accountId: 'customer_acc_1',
        hostId: 'host_acc_42',
        hostName: 'Tenzing Norgay',
        checkInDate: now,
        checkOutDate: now.add(const Duration(days: 2)),
        pricePerNight: 1200,
        totalPrice: 2400,
        guests: const [
          HotelGuestDetail(
            name: 'Priya Sen',
            aadharNumber: '8877 6655 4433',
            mobileNumber: '9830001122',
            idProofUrl: 'https://example.com/priya_aadhaar.jpg',
          ),
        ],
      );

      // Scenario 1: Customer Account views their own booking
      await appState.switchAccount('customer_acc_1');
      expect(canViewStayGuestDocuments(appState: appState, booking: booking), isTrue);

      // Scenario 2: Hotel Owner Account views after booking is confirmed
      await appState.switchAccount('host_acc_42');
      expect(canViewStayGuestDocuments(appState: appState, booking: booking), isTrue);

      // Scenario 3: Unauthorized third-party user tries to access guest documents
      await appState.switchAccount('stranger_user_999');
      expect(canViewStayGuestDocuments(appState: appState, booking: booking), isFalse);

      // Scenario 4: Before booking is confirmed (no booking id or ref), host cannot view
      final unconfirmedBooking = HotelBooking(
        id: '',
        bookingRef: '',
        hotelId: 'hotel_himalaya',
        hotelName: 'Himalayan Homestay',
        hotelLocation: 'Darjeeling',
        hotelImageUrl: 'https://example.com/hotel.jpg',
        roomType: 'Deluxe View Room',
        guestName: 'Priya Sen',
        userId: 'customer_acc_1',
        hostId: 'host_acc_42',
        checkInDate: now,
        checkOutDate: now.add(const Duration(days: 1)),
        pricePerNight: 1200,
        totalPrice: 1200,
      );
      await appState.switchAccount('host_acc_42');
      expect(canViewStayGuestDocuments(appState: appState, booking: unconfirmedBooking), isFalse);
    });
  });
}


