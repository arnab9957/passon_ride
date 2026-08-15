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
    await _usersRef.doc(userId).update({
      'role': role,
      'updatedAt': FieldValue.serverTimestamp(),
    });
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
          hostName: data['hostName'] ?? 'Host',
          hostAvatar: data['hostAvatar'] ?? '',
          hostTrustScore: (data['hostTrustScore'] as num?)?.toDouble() ?? 95.0,
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
      'hostName': vehicle.hostName,
      'hostAvatar': vehicle.hostAvatar,
      'hostTrustScore': vehicle.hostTrustScore,
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

  /// Delete a vehicle document from Firestore
  Future<void> deleteVehicle(String vehicleId) async {
    await _vehiclesRef.doc(vehicleId).delete();
  }

  /// Real-time IoT telematics update (Lock/Unlock, Engine, Battery, Location)
  Future<void> updateVehicleIoTData(String vehicleId, Map<String, dynamic> iotData) async {
    await _vehiclesRef.doc(vehicleId).update({
      'iotData': iotData,
      'lastTelemetrySync': FieldValue.serverTimestamp(),
    });
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
      'waypoints': tour.waypoints,
      'includedGear': tour.includedGear,
      'description': tour.description,
      'isFavorite': tour.isFavorite,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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

  /// Create a vehicle rental booking
  Future<String> createBooking({
    required String userId,
    required String vehicleId,
    required DateTime startDate,
    required DateTime endDate,
    required double totalPrice,
  }) async {
    final docRef = await _bookingsRef.add({
      'userId': userId,
      'vehicleId': vehicleId,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'totalPrice': totalPrice,
      'status': 'Confirmed',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
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
          timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
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

  // Helper
  VehicleType _parseVehicleType(dynamic value) {
    if (value == null) return VehicleType.car;
    return VehicleType.values.firstWhere(
      (e) => e.name == value.toString(),
      orElse: () => VehicleType.car,
    );
  }
}
