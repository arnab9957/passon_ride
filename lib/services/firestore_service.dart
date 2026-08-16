import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collection References
  CollectionReference get _vehiclesRef => _db.collection('vehicles');
  CollectionReference get _toursRef => _db.collection('tours');
  CollectionReference get _bookingsRef => _db.collection('bookings');
  CollectionReference get _chatThreadsRef => _db.collection('chat_threads');
  CollectionReference get _usersRef => _db.collection('users');

  // ==========================================
  // USER PROFILE & AUTH OPERATIONS (SECTION 1)
  // ==========================================

  /// Save or update user profile document in Firestore
  Future<void> saveUserProfile(String userId, Map<String, dynamic> data) async {
    await _usersRef.doc(userId).set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Get user profile document from Firestore
  Future<UserProfile?> getUserProfile(String userId) async {
    final doc = await _usersRef.doc(userId).get();
    if (doc.exists && doc.data() != null) {
      return UserProfile.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  /// Stream user profile real-time changes
  Stream<UserProfile?> streamUserProfile(String userId) {
    return _usersRef.doc(userId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserProfile.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  /// Update user role (e.g. 'Rider' -> 'Host' / 'Provider')
  Future<void> updateUserRole(String userId, String role) async {
    await _usersRef.doc(userId).set({
      'role': role,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ==========================================
  // VEHICLE OPERATIONS
  // ==========================================

  /// Stream real-time list of all vehicles
  Stream<List<Vehicle>> streamVehicles() {
    return _vehiclesRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Vehicle(
          id: doc.id,
          title: data['title'] ?? 'Untitled Vehicle',
          type: _parseVehicleType(data['type']),
          category: data['category'] ?? 'General',
          pricePerDay: (data['pricePerDay'] as num?)?.toDouble() ?? 0.0,
          rating: (data['rating'] as num?)?.toDouble() ?? 5.0,
          reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,
          imageUrl: data['imageUrl'] ?? '',
          location: data['location'] ?? 'San Francisco, CA',
          latitude: (data['latitude'] as num?)?.toDouble() ?? 37.7749,
          longitude: (data['longitude'] as num?)?.toDouble() ?? -122.4194,
          status: data['status'] ?? 'Available',
          hostName: data['hostName'] ?? 'Host',
          hostAvatar: data['hostAvatar'] ?? '',
          hostTrustScore: (data['hostTrustScore'] as num?)?.toDouble() ?? 95.0,
          hostId: data['hostId'] ?? '',
          isInstantBookable: data['isInstantBookable'] ?? true,
          isFavorite: data['isFavorite'] ?? false,
          fuelType: data['fuelType'] ?? 'Gasoline',
          transmission: data['transmission'] ?? 'Automatic',
          seats: (data['seats'] as num?)?.toInt() ?? 2,
          description: data['description'] ?? '',
          iotData: data['iotData'] != null ? Map<String, dynamic>.from(data['iotData']) : {},
          images: data['images'] != null
              ? List<String>.from(data['images'])
              : (data['imageUrl'] != null && (data['imageUrl'] as String).isNotEmpty ? [data['imageUrl']] : []),
        );
      }).toList();
    });
  }

  /// Add or save a vehicle to Firestore
  Future<void> saveVehicle(Vehicle vehicle) async {
    await _vehiclesRef.doc(vehicle.id).set({
      'title': vehicle.title,
      'type': vehicle.type.name,
      'category': vehicle.category,
      'pricePerDay': vehicle.pricePerDay,
      'rating': vehicle.rating,
      'reviewCount': vehicle.reviewCount,
      'imageUrl': vehicle.imageUrl,
      'images': vehicle.images,
      'location': vehicle.location,
      'latitude': vehicle.latitude,
      'longitude': vehicle.longitude,
      'status': vehicle.status,
      'hostName': vehicle.hostName,
      'hostAvatar': vehicle.hostAvatar,
      'hostTrustScore': vehicle.hostTrustScore,
      'hostId': vehicle.hostId,
      'isInstantBookable': vehicle.isInstantBookable,
      'isFavorite': vehicle.isFavorite,
      'fuelType': vehicle.fuelType,
      'transmission': vehicle.transmission,
      'seats': vehicle.seats,
      'description': vehicle.description,
      'iotData': vehicle.iotData,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Update fleet status of a vehicle ('Available', 'Booked', 'Maintenance')
  Future<void> updateVehicleStatus(String vehicleId, String status) async {
    await _vehiclesRef.doc(vehicleId).set({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Delete a vehicle document from Firestore
  Future<void> deleteVehicle(String vehicleId) async {
    await _vehiclesRef.doc(vehicleId).delete();
  }

  /// Real-time IoT telematics update (Lock/Unlock, Engine, Battery, Location, TPMS)
  Future<void> updateVehicleIoTData(String vehicleId, Map<String, dynamic> iotData) async {
    await _vehiclesRef.doc(vehicleId).set({
      'iotData': iotData,
      'lastTelemetrySync': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    try {
      final logId = 'log_${DateTime.now().millisecondsSinceEpoch}';
      await _db.collection('telemetry_logs').doc(logId).set({
        'id': logId,
        'vehicleId': vehicleId,
        'timestamp': FieldValue.serverTimestamp(),
        'lat': iotData['lat'] ?? 37.7749,
        'lng': iotData['lng'] ?? -122.4194,
        'speed': iotData['speed'] ?? 0.0,
        'batterySoc': iotData['batterySoc'] ?? iotData['batteryLevel'] ?? 90,
        'fuelPercent': iotData['fuelPercent'] ?? 85,
        'tpmsFrontPsi': iotData['tpmsFrontPsi'] ?? iotData['tirePressureFront'] ?? 32.0,
        'tpmsRearPsi': iotData['tpmsRearPsi'] ?? iotData['tirePressureRear'] ?? 35.0,
        'obdDtcCodes': iotData['obdDtcCodes'] ?? [],
        'engineOn': iotData['engineOn'] ?? false,
        'locked': iotData['locked'] ?? true,
      });
    } catch (_) {}
  }

  /// Seed initial sample vehicles to Firestore if collection is empty
  Future<void> seedVehiclesIfEmpty(List<Vehicle> sampleVehicles) async {
    final snapshot = await _vehiclesRef.limit(1).get();
    if (snapshot.docs.isEmpty) {
      for (var vehicle in sampleVehicles) {
        await saveVehicle(vehicle);
      }
    }
  }

  // ==========================================
  // TOUR OPERATIONS
  // ==========================================

  /// Stream real-time list of guided tours
  Stream<List<Tour>> streamTours() {
    return _toursRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Tour(
          id: doc.id,
          title: data['title'] ?? '',
          location: data['location'] ?? '',
          price: (data['price'] as num?)?.toDouble() ?? 0.0,
          duration: data['duration'] ?? '',
          rating: (data['rating'] as num?)?.toDouble() ?? 5.0,
          reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,
          imageUrl: data['imageUrl'] ?? '',
          guideName: data['guideName'] ?? '',
          guideAvatar: data['guideAvatar'] ?? '',
          hostId: data['hostId'] ?? '',
          waypoints: List<String>.from(data['waypoints'] ?? []),
          includedGear: List<String>.from(data['includedGear'] ?? []),
          description: data['description'] ?? '',
          isFavorite: data['isFavorite'] ?? false,
        );
      }).toList();
    });
  }

  /// Add or update a tour in Firestore
  Future<void> saveTour(Tour tour) async {
    await _toursRef.doc(tour.id).set({
      'title': tour.title,
      'location': tour.location,
      'price': tour.price,
      'duration': tour.duration,
      'rating': tour.rating,
      'reviewCount': tour.reviewCount,
      'imageUrl': tour.imageUrl,
      'guideName': tour.guideName,
      'guideAvatar': tour.guideAvatar,
      'hostId': tour.hostId,
      'guideId': tour.hostId,
      'waypoints': tour.waypoints,
      'includedGear': tour.includedGear,
      'description': tour.description,
      'isFavorite': tour.isFavorite,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Save AI Itinerary generation log to Firestore
  Future<void> saveAiGeneration(AiGeneration gen) async {
    try {
      await _db.collection('ai_generations').doc(gen.id).set({
        'id': gen.id,
        'userId': gen.userId,
        'destination': gen.destination,
        'durationDays': gen.durationDays,
        'budget': gen.budget,
        'terrain': gen.terrain,
        'generatedItineraryJson': gen.generatedItineraryJson,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('saveAiGeneration error: $e');
    }
  }

  /// Delete a tour document from Firestore
  Future<void> deleteTour(String tourId) async {
    await _toursRef.doc(tourId).delete();
  }

  /// Seed sample tours if collection is empty
  Future<void> seedToursIfEmpty(List<Tour> sampleTours) async {
    final snapshot = await _toursRef.limit(1).get();
    if (snapshot.docs.isEmpty) {
      for (var tour in sampleTours) {
        await saveTour(tour);
      }
    }
  }

  // ==========================================
  // BOOKINGS & CHAT OPERATIONS
  // ==========================================

  /// Save booking to Firestore
  Future<void> saveBooking(Booking booking) async {
    await _bookingsRef.doc(booking.id).set({
      'id': booking.id,
      'userId': booking.userId,
      'riderId': booking.userId,
      'hostId': booking.hostId,
      'vehicleId': booking.vehicleId,
      'vehicleTitle': booking.vehicleTitle,
      'vehicleImageUrl': booking.vehicleImageUrl,
      'hostName': booking.hostName,
      'startDate': Timestamp.fromDate(booking.startDate),
      'endDate': Timestamp.fromDate(booking.endDate),
      'totalPrice': booking.totalPrice,
      'status': booking.status,
      'unlockPasscode': booking.unlockPasscode,
      'paymentIntentId': booking.paymentIntentId,
      'createdAt': Timestamp.fromDate(booking.createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Update booking status ('Confirmed', 'Active', 'Completed', 'Cancelled')
  Future<void> updateBookingStatus(String bookingId, String newStatus) async {
    await _bookingsRef.doc(bookingId).set({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Direct fetch of vehicles via get() for web compatibility
  Future<List<Vehicle>> getVehicles() async {
    try {
      final snapshot = await _vehiclesRef.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Vehicle(
          id: doc.id,
          title: data['title'] ?? 'Untitled Vehicle',
          type: _parseVehicleType(data['type']),
          category: data['category'] ?? 'General',
          pricePerDay: (data['pricePerDay'] as num?)?.toDouble() ?? 0.0,
          rating: (data['rating'] as num?)?.toDouble() ?? 5.0,
          reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,
          imageUrl: data['imageUrl'] ?? '',
          location: data['location'] ?? 'San Francisco, CA',
          latitude: (data['latitude'] as num?)?.toDouble() ?? 37.7749,
          longitude: (data['longitude'] as num?)?.toDouble() ?? -122.4194,
          status: data['status'] ?? 'Available',
          hostName: data['hostName'] ?? 'Host',
          hostAvatar: data['hostAvatar'] ?? '',
          hostTrustScore: (data['hostTrustScore'] as num?)?.toDouble() ?? 95.0,
          hostId: data['hostId'] ?? '',
          isInstantBookable: data['isInstantBookable'] ?? true,
          isFavorite: data['isFavorite'] ?? false,
          fuelType: data['fuelType'] ?? 'Gasoline',
          transmission: data['transmission'] ?? 'Automatic',
          seats: (data['seats'] as num?)?.toInt() ?? 2,
          description: data['description'] ?? '',
          iotData: data['iotData'] != null ? Map<String, dynamic>.from(data['iotData']) : {},
          images: data['images'] != null
              ? List<String>.from(data['images'])
              : (data['imageUrl'] != null && (data['imageUrl'] as String).isNotEmpty ? [data['imageUrl']] : []),
        );
      }).toList();
    } catch (e) {
      print('getVehicles error: $e');
      return [];
    }
  }

  /// Direct fetch of tours via get() for web compatibility
  Future<List<Tour>> getTours() async {
    try {
      final snapshot = await _toursRef.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Tour(
          id: doc.id,
          title: data['title'] ?? '',
          location: data['location'] ?? '',
          price: (data['price'] as num?)?.toDouble() ?? 0.0,
          duration: data['duration'] ?? '',
          rating: (data['rating'] as num?)?.toDouble() ?? 5.0,
          reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,
          imageUrl: data['imageUrl'] ?? '',
          guideName: data['guideName'] ?? '',
          guideAvatar: data['guideAvatar'] ?? '',
          hostId: data['hostId'] ?? '',
          waypoints: List<String>.from(data['waypoints'] ?? []),
          includedGear: List<String>.from(data['includedGear'] ?? []),
          description: data['description'] ?? '',
          isFavorite: data['isFavorite'] ?? false,
        );
      }).toList();
    } catch (e) {
      print('getTours error: $e');
      return [];
    }
  }

  /// Direct fetch of user bookings via get() for web compatibility
  Future<List<Booking>> getBookingsForUser(String userId) async {
    try {
      final snapshot = await _bookingsRef.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Booking(
          id: doc.id,
          vehicleId: data['vehicleId'] ?? '',
          vehicleTitle: data['vehicleTitle'] ?? '',
          vehicleImageUrl: data['vehicleImageUrl'] ?? '',
          hostName: data['hostName'] ?? '',
          userId: data['userId'] ?? data['riderId'] ?? '',
          hostId: data['hostId'] ?? '',
          startDate: _parseTimestamp(data['startDate']),
          endDate: _parseTimestamp(data['endDate']),
          totalPrice: (data['totalPrice'] as num?)?.toDouble() ?? 0.0,
          status: data['status'] ?? 'Confirmed',
          unlockPasscode: data['unlockPasscode'] ?? '',
          paymentIntentId: data['paymentIntentId'] ?? '',
          createdAt: _parseTimestamp(data['createdAt']),
        );
      }).where((b) => b.userId == userId || b.hostId == userId || b.userId.isEmpty).toList();
    } catch (e) {
      print('getBookingsForUser error: $e');
      return [];
    }
  }

  /// Stream bookings for a specific user or host
  Stream<List<Booking>> streamBookingsForUser(String userId) {
    return _bookingsRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Booking(
          id: doc.id,
          vehicleId: data['vehicleId'] ?? '',
          vehicleTitle: data['vehicleTitle'] ?? '',
          vehicleImageUrl: data['vehicleImageUrl'] ?? '',
          hostName: data['hostName'] ?? '',
          userId: data['userId'] ?? data['riderId'] ?? '',
          hostId: data['hostId'] ?? '',
          startDate: _parseTimestamp(data['startDate']),
          endDate: _parseTimestamp(data['endDate']),
          totalPrice: (data['totalPrice'] as num?)?.toDouble() ?? 0.0,
          status: data['status'] ?? 'Confirmed',
          unlockPasscode: data['unlockPasscode'] ?? '',
          paymentIntentId: data['paymentIntentId'] ?? '',
          createdAt: _parseTimestamp(data['createdAt']),
        );
      }).where((b) => b.userId == userId || b.hostId == userId || b.userId.isEmpty).toList();
    });
  }

  /// Stream live messages for a chat thread
  Stream<List<ChatMessage>> streamChatMessages(String threadId) {
    return _chatThreadsRef
        .doc(threadId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ChatMessage(
          id: doc.id,
          senderId: data['senderId'] ?? '',
          text: data['text'] ?? '',
          timestamp: _parseTimestamp(data['timestamp']),
          isUser: data['isUser'] ?? false,
        );
      }).toList();
    });
  }

  /// Send message to chat thread
  Future<void> sendChatMessage(String threadId, ChatMessage message) async {
    await _chatThreadsRef.doc(threadId).collection('messages').doc(message.id).set({
      'senderId': message.senderId,
      'text': message.text,
      'timestamp': Timestamp.fromDate(message.timestamp),
      'isUser': message.isUser,
    });

    await _chatThreadsRef.doc(threadId).set({
      'lastMessage': message.text,
      'lastTime': Timestamp.fromDate(message.timestamp),
    }, SetOptions(merge: true));
  }

  /// Save or upload compliance document log to Firestore
  Future<void> saveComplianceDocument(ComplianceDocument doc) async {
    try {
      await _db.collection('compliance_documents').doc(doc.id).set({
        'id': doc.id,
        'userId': doc.userId,
        'title': doc.title,
        'type': doc.type,
        'status': doc.status,
        'expiryDate': Timestamp.fromDate(doc.expiryDate),
        'documentUrl': doc.documentUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('saveComplianceDocument error: $e');
    }
  }

  /// Get user compliance verification documents
  Future<List<ComplianceDocument>> getComplianceDocumentsForUser(String userId) async {
    try {
      final snapshot = await _db.collection('compliance_documents').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ComplianceDocument(
          id: doc.id,
          userId: data['userId'] ?? '',
          title: data['title'] ?? '',
          status: data['status'] ?? 'Verified',
          expiryDate: _parseTimestamp(data['expiryDate']),
          type: data['type'] ?? 'ID',
          documentUrl: data['documentUrl'] ?? '',
        );
      }).where((d) => d.userId == userId || d.userId.isEmpty).toList();
    } catch (e) {
      print('getComplianceDocumentsForUser error: $e');
      return [];
    }
  }

  static DateTime _parseTimestamp(dynamic val) {
    if (val is Timestamp) return val.toDate();
    if (val is DateTime) return val;
    if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
    return DateTime.now();
  }

  // Helper
  VehicleType _parseVehicleType(dynamic value) {
    if (value == null) return VehicleType.car;
    return VehicleType.values.firstWhere(
      (e) => e.name == value.toString(),
      orElse: () => VehicleType.car,
    );
  }
}
