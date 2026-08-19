import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'location_service.dart';

class SupabaseService {
  final LocationService _locationService = LocationService();

  bool get isInitialized {
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  SupabaseClient? get client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Initialize Supabase Flutter Client
  Future<bool> initialize({required String url, required String anonKey}) async {
    if (url.isEmpty || anonKey.isEmpty || url.contains('your_supabase_project_id')) {
      return false;
    }
    try {
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
      );
      return true;
    } catch (e) {
      print('Supabase initialize info: $e');
      return isInitialized;
    }
  }

  // ==========================================
  // VEHICLE OPERATIONS
  // ==========================================

  Future<List<Vehicle>> getVehicles() async {
    if (client == null) return [];
    try {
      final List<dynamic> data = await client!.from('vehicles').select().order('updated_at', ascending: false);
      return data.map((map) => _mapToVehicle(map)).toList();
    } catch (e) {
      print('Supabase getVehicles error: $e');
      return [];
    }
  }

  /// Fetches available rental vehicles near customer location, connecting customer coordinates to host vehicle addresses sorted by proximity
  Future<List<Vehicle>> fetchAvailableVehiclesNearCustomerLocation({
    required double customerLat,
    required double customerLng,
    double maxRadiusKm = 100.0,
  }) async {
    if (client == null) return [];
    try {
      final List<dynamic> data = await client!
          .from('vehicles')
          .select()
          .neq('status', 'Maintenance');
      
      final vehicles = data.map((map) => _mapToVehicle(map)).toList();

      // Filter by radius & sort by host-to-customer proximity (nearest first)
      final nearbyAvailable = vehicles.where((v) {
        if (v.status == 'Maintenance' || v.status == 'Archived') return false;
        final dist = _locationService.calculateDistanceKm(
          customerLat,
          customerLng,
          v.latitude,
          v.longitude,
        );
        return dist <= maxRadiusKm;
      }).toList();

      nearbyAvailable.sort((a, b) {
        final distA = _locationService.calculateDistanceKm(customerLat, customerLng, a.latitude, a.longitude);
        final distB = _locationService.calculateDistanceKm(customerLat, customerLng, b.latitude, b.longitude);
        return distA.compareTo(distB);
      });

      return nearbyAvailable;
    } catch (e) {
      print('Supabase fetchAvailableVehiclesNearCustomerLocation error: $e');
      return [];
    }
  }

  Future<void> saveVehicle(Vehicle vehicle) async {
    if (client == null) return;
    try {
      final map = {
        'id': vehicle.id,
        'title': vehicle.title,
        'type': vehicle.type.name,
        'category': vehicle.category,
        'price_per_day': vehicle.pricePerDay,
        'rating': vehicle.rating,
        'review_count': vehicle.reviewCount,
        'image_url': vehicle.imageUrl,
        'images': vehicle.images,
        'location': vehicle.location,
        'latitude': vehicle.latitude,
        'longitude': vehicle.longitude,
        'status': vehicle.status,
        'host_name': vehicle.hostName,
        'host_avatar': vehicle.hostAvatar,
        'host_trust_score': vehicle.hostTrustScore,
        'host_id': vehicle.hostId,
        'is_instant_bookable': vehicle.isInstantBookable,
        'is_favorite': vehicle.isFavorite,
        'fuel_type': vehicle.fuelType,
        'transmission': vehicle.transmission,
        'seats': vehicle.seats,
        'description': vehicle.description,
        'iot_data': vehicle.iotData,
        'updated_at': DateTime.now().toIso8601String(),
      };
      await client!.from('vehicles').upsert(map);
    } catch (e) {
      print('Supabase saveVehicle error: $e');
    }
  }

  Future<void> updateVehicleStatus(String vehicleId, String status) async {
    if (client == null) return;
    try {
      await client!.from('vehicles').update({'status': status, 'updated_at': DateTime.now().toIso8601String()}).eq('id', vehicleId);
    } catch (e) {
      print('Supabase updateVehicleStatus error: $e');
    }
  }

  Future<void> deleteVehicle(String vehicleId) async {
    if (client == null) return;
    try {
      await client!.from('vehicles').delete().eq('id', vehicleId);
    } catch (e) {
      print('Supabase deleteVehicle error: $e');
    }
  }

  // ==========================================
  // BOOKING OPERATIONS
  // ==========================================

  Future<List<Booking>> getBookingsForUser(String userId) async {
    if (client == null) return [];
    try {
      final List<dynamic> data = await client!.from('bookings').select().or('rider_id.eq.$userId,host_id.eq.$userId');
      return data.map((map) => _mapToBooking(map)).toList();
    } catch (e) {
      print('Supabase getBookingsForUser error: $e');
      return [];
    }
  }

  Future<void> saveBooking(Booking booking) async {
    if (client == null) return;
    try {
      final map = {
        'id': booking.id,
        'vehicle_id': booking.vehicleId,
        'vehicle_title': booking.vehicleTitle,
        'vehicle_image_url': booking.vehicleImageUrl,
        'host_name': booking.hostName,
        'rider_id': booking.riderId,
        'host_id': booking.hostId,
        'start_date': booking.startDate.toIso8601String(),
        'end_date': booking.endDate.toIso8601String(),
        'total_price': booking.totalPrice,
        'status': booking.status,
        'unlock_passcode': booking.unlockPasscode,
        'payment_intent_id': booking.paymentIntentId,
        'created_at': booking.createdAt.toIso8601String(),
      };
      await client!.from('bookings').upsert(map);
    } catch (e) {
      print('Supabase saveBooking error: $e');
    }
  }

  // ==========================================
  // TOUR OPERATIONS
  // ==========================================

  Future<List<Tour>> getTours() async {
    if (client == null) return [];
    try {
      final List<dynamic> data = await client!.from('tours').select().order('updated_at', ascending: false);
      return data.map((map) => _mapToTour(map)).toList();
    } catch (e) {
      print('Supabase getTours error: $e');
      return [];
    }
  }

  Future<void> saveTour(Tour tour) async {
    if (client == null) return;
    try {
      final validImages = tour.images.where((img) => img.trim().isNotEmpty).toList();
      final ikImages = validImages.where((img) => img.contains('imagekit.io') || !img.contains('unsplash.com')).toList();
      final mainImage = ikImages.isNotEmpty
          ? ikImages.first
          : (tour.imageUrl.trim().isNotEmpty
              ? tour.imageUrl
              : (validImages.isNotEmpty ? validImages.first : 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=800&q=80'));

      final String storedImageUrl = validImages.length > 1
          ? jsonEncode(validImages)
          : mainImage;

      final map = {
        'id': tour.id,
        'title': tour.title,
        'location': tour.location,
        'price': tour.price,
        'duration': tour.duration,
        'rating': tour.rating,
        'review_count': tour.reviewCount,
        'image_url': storedImageUrl,
        'guide_name': tour.guideName,
        'guide_avatar': tour.guideAvatar,
        'host_id': tour.hostId,
        'waypoints': tour.waypoints,
        'included_gear': tour.includedGear,
        'description': tour.description,
        'is_favorite': tour.isFavorite,
        'updated_at': DateTime.now().toIso8601String(),
      };
      await client!.from('tours').upsert(map);
    } catch (e) {
      print('Supabase saveTour error: $e');
    }
  }

  Future<void> deleteTour(String tourId) async {
    if (client == null) return;
    try {
      await client!.from('tours').delete().eq('id', tourId);
    } catch (e) {
      print('Supabase deleteTour error: $e');
    }
  }

  // ==========================================
  // PROFILE OPERATIONS
  // ==========================================

  Future<UserProfile?> getUserProfile(String userId) async {
    if (client == null || userId.isEmpty) return null;
    try {
      final List<dynamic> data = await client!.from('profiles').select().eq('id', userId);
      if (data.isNotEmpty) {
        final map = data.first;
        return UserProfile(
          uid: map['id'] ?? userId,
          email: map['email'] ?? '',
          displayName: map['display_name'] ?? map['displayName'] ?? '',
          photoUrl: (map['photo_url'] ?? map['photoUrl'] ?? '').toString(),
          phoneNumber: map['phone_number'] ?? map['phoneNumber'] ?? '',
          role: map['role'] ?? 'Rider',
          trustScore: (map['trust_score'] ?? map['trustScore'] as num?)?.toDouble() ?? 95.0,
          bio: map['bio'] ?? '',
        );
      }
      return null;
    } catch (e) {
      print('Supabase getUserProfile error: $e');
      return null;
    }
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    if (client == null || profile.uid.isEmpty) return;
    try {
      final map = {
        'id': profile.uid,
        'email': profile.email,
        'display_name': profile.displayName,
        'photo_url': profile.photoUrl,
        'phone_number': profile.phoneNumber,
        'role': profile.role,
        'trust_score': profile.trustScore,
        'bio': profile.bio,
        'updated_at': DateTime.now().toIso8601String(),
      };
      await client!.from('profiles').upsert(map);
    } catch (e) {
      print('Supabase saveUserProfile error: $e');
    }
  }

  Future<void> saveReview(Review review) async {
    if (client == null) return;
    try {
      final map = {
        'id': review.id,
        'vehicle_id': review.vehicleId,
        'user_id': review.userId,
        'user_name': review.userName,
        'user_avatar': review.userAvatar,
        'rating': review.rating,
        'comment': review.comment,
        'created_at': review.createdAt.toIso8601String(),
      };
      await client!.from('reviews').upsert(map);
    } catch (e) {
      print('Supabase saveReview error: $e');
    }
  }

  Future<List<Review>> getReviewsForVehicle(String vehicleId) async {
    if (client == null || vehicleId.isEmpty) return [];
    try {
      final response = await client!
          .from('reviews')
          .select()
          .eq('vehicle_id', vehicleId)
          .order('created_at', ascending: false);
      return (response as List).map((map) => Review.fromMap(map)).toList();
    } catch (e) {
      print('Supabase getReviewsForVehicle error: $e');
      return [];
    }
  }

  /// Upload image directly to Supabase Storage bucket ('vehicles')
  Future<String?> uploadImageToSupabaseStorage({
    required Uint8List bytes,
    required String fileName,
    String bucket = 'vehicles',
  }) async {
    if (client == null) return null;
    try {
      final path = 'public/$fileName';
      await client!.storage.from(bucket).uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(upsert: true),
      );
      final publicUrl = client!.storage.from(bucket).getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      print('Supabase Storage upload error: $e');
      return null;
    }
  }

  // ==========================================
  // EXTRA SYNC & STREAM OPERATIONS
  // ==========================================

  Future<void> updateVehicleIoTData(String vehicleId, Map<String, dynamic> iotData) async {
    if (client == null) return;
    try {
      await client!.from('vehicles').update({'iot_data': iotData}).eq('id', vehicleId);
    } catch (e) {
      print('Supabase updateVehicleIoTData error: $e');
    }
  }

  Future<void> updateUserRole(String userId, String role) async {
    if (client == null) return;
    try {
      await client!.from('profiles').update({'role': role}).eq('id', userId);
    } catch (e) {
      print('Supabase updateUserRole error: $e');
    }
  }

  Future<void> updateBookingStatus(String bookingId, String status) async {
    if (client == null) return;
    try {
      await client!.from('bookings').update({'status': status}).eq('id', bookingId);
    } catch (e) {
      print('Supabase updateBookingStatus error: $e');
    }
  }

  Future<void> updateBookingRiderLocation({
    required String bookingId,
    required double latitude,
    required double longitude,
    required double speed,
    required double heading,
  }) async {
    if (client == null) return;
    try {
      await client!.from('bookings').update({
        'rider_latitude': latitude,
        'rider_longitude': longitude,
        'rider_speed': speed,
        'rider_heading': heading,
        'last_gps_update': DateTime.now().toIso8601String(),
      }).eq('id', bookingId);
    } catch (_) {}
  }

  Future<void> saveComplianceDocument(ComplianceDocument doc) async {
    if (client == null) return;
    try {
      final map = doc.toMap();
      await client!.from('compliance_documents').upsert(map);
      print('Supabase saveComplianceDocument success for ID: ${doc.id}');
    } catch (e) {
      print('Supabase saveComplianceDocument error: $e');
    }
  }

  Future<void> deleteComplianceDocument(String docId) async {
    if (client == null || docId.isEmpty) return;
    try {
      await client!.from('compliance_documents').delete().eq('id', docId);
      print('Supabase deleteComplianceDocument success for ID: $docId');
    } catch (e) {
      print('Supabase deleteComplianceDocument error: $e');
    }
  }

  Future<List<ComplianceDocument>> getComplianceDocuments(String userId) async {
    if (client == null || userId.isEmpty) return [];
    try {
      final response = await client!
          .from('compliance_documents')
          .select()
          .eq('user_id', userId);
      return (response as List).map((map) => ComplianceDocument.fromMap(map)).toList();
    } catch (e) {
      print('Supabase getComplianceDocuments error: $e');
      return [];
    }
  }

  Future<TrustScore?> getTrustScore(String userId) async {
    if (client == null || userId.isEmpty) return null;
    try {
      final response = await client!
          .from('trust_scores')
          .select()
          .eq('user_id', userId);
      if ((response as List).isNotEmpty) {
        return TrustScore.fromMap(response.first);
      }
    } catch (e) {
      print('Supabase getTrustScore error: $e');
    }
    return null;
  }

  Future<void> saveTrustScore(TrustScore score) async {
    if (client == null || score.userId.isEmpty) return;
    try {
      await client!.from('trust_scores').upsert({
        'user_id': score.userId,
        'trust_score': score.trustScore,
        'trust_badges': score.trustBadges,
        'telematics_score': score.telematicsScore,
        'cancellation_rate': score.cancellationRate,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Supabase saveTrustScore error: $e');
    }
  }

  Future<List<ChatThread>> getChatThreads(String userId) async {
    if (client == null || userId.isEmpty) return [];
    try {
      final response = await client!
          .from('chat_threads')
          .select()
          .eq('user_id', userId)
          .order('last_time', ascending: false);
      final List<ChatThread> threads = [];
      for (final map in (response as List)) {
        final threadId = map['id'].toString();
        final msgs = await getChatMessages(threadId);
        threads.add(ChatThread.fromMap(map, msgs));
      }
      return threads;
    } catch (e) {
      print('Supabase getChatThreads error: $e');
      return [];
    }
  }

  Future<void> saveChatThread(String userId, ChatThread thread) async {
    if (client == null) return;
    try {
      await client!.from('chat_threads').upsert(thread.toMap(userId));
      for (final msg in thread.messages) {
        await saveChatMessage(thread.id, msg);
      }
    } catch (e) {
      print('Supabase saveChatThread error: $e');
    }
  }

  Future<List<ChatMessage>> getChatMessages(String threadId) async {
    if (client == null || threadId.isEmpty) return [];
    try {
      final response = await client!
          .from('chat_messages')
          .select()
          .eq('thread_id', threadId)
          .order('timestamp', ascending: true);
      return (response as List).map((map) => ChatMessage.fromMap(map)).toList();
    } catch (e) {
      print('Supabase getChatMessages error: $e');
      return [];
    }
  }

  Future<void> saveChatMessage(String threadId, ChatMessage message) async {
    if (client == null) return;
    try {
      await client!.from('chat_messages').upsert(message.toMap(threadId));
    } catch (e) {
      print('Supabase saveChatMessage error: $e');
    }
  }

  Future<HostEarnings?> getHostEarnings(String hostId) async {
    if (client == null || hostId.isEmpty) return null;
    try {
      final response = await client!
          .from('host_earnings')
          .select()
          .eq('host_id', hostId);
      if ((response as List).isNotEmpty) {
        return HostEarnings.fromMap(response.first);
      }
    } catch (e) {
      print('Supabase getHostEarnings error: $e');
    }
    return null;
  }

  Future<void> saveHostEarnings(HostEarnings earnings) async {
    if (client == null || earnings.hostId.isEmpty) return;
    try {
      await client!.from('host_earnings').upsert(earnings.toMap());
    } catch (e) {
      print('Supabase saveHostEarnings error: $e');
    }
  }

  Future<void> saveAiGeneration(AiGeneration gen) async {
    if (client == null) return;
    try {
      await client!.from('ai_generations').upsert({
        'id': gen.id,
        'user_id': gen.userId,
        'destination': gen.destination,
        'duration_days': gen.durationDays,
        'budget': gen.budget,
        'terrain': gen.terrain,
        'generated_itinerary_json': gen.generatedItineraryJson,
        'created_at': gen.createdAt.toIso8601String(),
      });
    } catch (e) {
      print('Supabase saveAiGeneration error: $e');
    }
  }

  Future<List<AiGeneration>> getAiGenerationsForUser(String userId) async {
    if (client == null || userId.isEmpty) return [];
    try {
      final response = await client!
          .from('ai_generations')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return (response as List).map((map) => AiGeneration.fromMap(map)).toList();
    } catch (e) {
      print('Supabase getAiGenerationsForUser error: $e');
      return [];
    }
  }

  Stream<UserProfile?> streamUserProfile(String userId) {
    if (client == null || userId.isEmpty) return Stream.value(null);
    try {
      return client!
          .from('profiles')
          .stream(primaryKey: ['id'])
          .eq('id', userId)
          .map((data) {
            if (data.isNotEmpty) {
              return UserProfile.fromMap(Map<String, dynamic>.from(data.first));
            }
            return null;
          })
          .handleError((error) {
            print('Supabase streamUserProfile realtime error handled: $error');
            return null;
          });
    } catch (e) {
      print('Supabase streamUserProfile error: $e');
      return Stream.value(null);
    }
  }

  Stream<List<ChatMessage>> streamChatMessages(String threadId) {
    if (client == null || threadId.isEmpty) return Stream.value([]);
    try {
      return client!
          .from('chat_messages')
          .stream(primaryKey: ['id'])
          .eq('thread_id', threadId)
          .order('timestamp', ascending: true)
          .map((data) => data.map((map) => ChatMessage.fromMap(Map<String, dynamic>.from(map))).toList())
          .handleError((error) {
            print('Supabase streamChatMessages realtime error handled: $error');
            return <ChatMessage>[];
          });
    } catch (e) {
      print('Supabase streamChatMessages error: $e');
      return Stream.value([]);
    }
  }

  // Helper Mappers
  Vehicle _mapToVehicle(Map<String, dynamic> map) {
    return Vehicle(
      id: map['id'] ?? '',
      title: map['title'] ?? 'Untitled Vehicle',
      type: VehicleType.values.firstWhere((e) => e.name == map['type'], orElse: () => VehicleType.car),
      category: map['category'] ?? 'General',
      pricePerDay: (map['price_per_day'] as num?)?.toDouble() ?? 0.0,
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
      reviewCount: (map['review_count'] as num?)?.toInt() ?? 0,
      imageUrl: map['image_url'] ?? '',
      location: map['location'] ?? 'San Francisco, CA',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 37.7749,
      longitude: (map['longitude'] as num?)?.toDouble() ?? -122.4194,
      status: map['status'] ?? 'Available',
      hostName: map['host_name'] ?? 'Host',
      hostAvatar: map['host_avatar'] ?? '',
      hostTrustScore: (map['host_trust_score'] as num?)?.toDouble() ?? 95.0,
      hostId: map['host_id'] ?? '',
      isInstantBookable: map['is_instant_bookable'] ?? true,
      isFavorite: map['is_favorite'] ?? false,
      fuelType: map['fuel_type'] ?? 'Gasoline',
      transmission: map['transmission'] ?? 'Automatic',
      seats: (map['seats'] as num?)?.toInt() ?? 2,
      description: map['description'] ?? '',
      iotData: map['iot_data'] != null ? Map<String, dynamic>.from(map['iot_data']) : {},
      images: map['images'] != null ? List<String>.from(map['images']) : [],
    );
  }

  Booking _mapToBooking(Map<String, dynamic> map) {
    return Booking(
      id: map['id'] ?? '',
      vehicleId: map['vehicle_id'] ?? '',
      vehicleTitle: map['vehicle_title'] ?? '',
      vehicleImageUrl: map['vehicle_image_url'] ?? '',
      hostName: map['host_name'] ?? '',
      userId: map['rider_id'] ?? map['user_id'] ?? '',
      hostId: map['host_id'] ?? '',
      startDate: DateTime.tryParse(map['start_date'] ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(map['end_date'] ?? '') ?? DateTime.now(),
      totalPrice: (map['total_price'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'Confirmed',
      unlockPasscode: map['unlock_passcode'] ?? '',
      paymentIntentId: map['payment_intent_id'] ?? '',
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Tour _mapToTour(Map<String, dynamic> map) {
    return Tour.fromMap(map);
  }
}
