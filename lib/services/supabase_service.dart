import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
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
    if (isInitialized) {
      return true;
    }
    if (url.isEmpty || anonKey.isEmpty || url.contains('your_supabase_project_id')) {
      return false;
    }
    try {
      await Supabase.initialize(
        url: url,
        publishableKey: anonKey,
      );
      return true;
    } catch (e) {
      debugPrint('Supabase initialize info: $e');
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
      debugPrint('Supabase getVehicles error: $e');
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
      debugPrint('Supabase fetchAvailableVehiclesNearCustomerLocation error: $e');
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
      debugPrint('Supabase saveVehicle error: $e');
    }
  }

  Future<void> updateVehicleStatus(String vehicleId, String status) async {
    if (client == null) return;
    try {
      await client!.from('vehicles').update({'status': status, 'updated_at': DateTime.now().toIso8601String()}).eq('id', vehicleId);
    } catch (e) {
      debugPrint('Supabase updateVehicleStatus error: $e');
    }
  }

  Future<void> deleteVehicle(String vehicleId) async {
    if (client == null) return;
    try {
      await client!.from('vehicles').delete().eq('id', vehicleId);
    } catch (e) {
      debugPrint('Supabase deleteVehicle error: $e');
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
      debugPrint('Supabase getBookingsForUser error: $e');
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
      debugPrint('Supabase saveBooking error: $e');
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
      debugPrint('Supabase getTours error: $e');
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
      debugPrint('Supabase saveTour error: $e');
    }
  }

  Future<void> deleteTour(String tourId) async {
    if (client == null) return;
    try {
      await client!.from('tours').delete().eq('id', tourId);
    } catch (e) {
      debugPrint('Supabase deleteTour error: $e');
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
      debugPrint('Supabase getUserProfile error: $e');
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
      debugPrint('Supabase saveUserProfile error: $e');
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
      debugPrint('Supabase saveReview error: $e');
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
      debugPrint('Supabase getReviewsForVehicle error: $e');
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
      debugPrint('Supabase Storage upload error: $e');
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
      debugPrint('Supabase updateVehicleIoTData error: $e');
    }
  }

  Future<void> updateUserRole(String userId, String role) async {
    if (client == null) return;
    try {
      await client!.from('profiles').update({'role': role}).eq('id', userId);
    } catch (e) {
      debugPrint('Supabase updateUserRole error: $e');
    }
  }

  Future<void> updateBookingStatus(String bookingId, String status) async {
    if (client == null) return;
    try {
      await client!.from('bookings').update({'status': status}).eq('id', bookingId);
    } catch (e) {
      debugPrint('Supabase updateBookingStatus error: $e');
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
    final effectiveUid = doc.userId.isNotEmpty ? doc.userId : (client?.auth.currentUser?.id ?? 'guest_user');
    
    final cleanMap = {
      'id': doc.id,
      'user_id': effectiveUid,
      'title': doc.title,
      'status': doc.status,
      'expiry_date': doc.expiryDate.toIso8601String(),
      'type': doc.type,
      'document_url': doc.documentUrl,
      'document_number': doc.documentNumber,
      'holder_name': doc.holderName,
      'license_type': doc.licenseType,
      'file_size_kb': doc.fileSizeKb,
      'file_name': doc.fileName,
      'file_extension': doc.fileExtension,
      'confidence_score': doc.confidenceScore,
      'issuing_authority': doc.issuingAuthority,
      'blood_group': doc.bloodGroup,
      'address': doc.address,
      'dob': doc.dob,
      'is_expiry_valid': doc.isExpiryValid,
      'updated_at': DateTime.now().toIso8601String(),
    };

    try {
      await client!.from('compliance_documents').upsert(cleanMap);
      debugPrint('Supabase saveComplianceDocument success for ID: ${doc.id}');
    } catch (e) {
      debugPrint('Supabase saveComplianceDocument full upsert info: $e');
      try {
        final coreMap = {
          'id': doc.id,
          'user_id': effectiveUid,
          'title': doc.title,
          'status': doc.status,
          'expiry_date': doc.expiryDate.toIso8601String(),
          'type': doc.type,
          'document_url': doc.documentUrl,
          'document_number': doc.documentNumber,
          'holder_name': doc.holderName,
          'license_type': doc.licenseType,
        };
        await client!.from('compliance_documents').upsert(coreMap);
        debugPrint('Supabase saveComplianceDocument core upsert success for ID: ${doc.id}');
      } catch (e2) {
        debugPrint('Supabase saveComplianceDocument core upsert error: $e2');
        try {
          final minimalMap = {
            'id': doc.id,
            'user_id': effectiveUid,
            'title': doc.title,
            'type': doc.type,
            'document_url': doc.documentUrl,
          };
          await client!.from('compliance_documents').upsert(minimalMap);
          debugPrint('Supabase saveComplianceDocument minimal upsert success for ID: ${doc.id}');
        } catch (e3) {
          debugPrint('Supabase saveComplianceDocument minimal upsert error: $e3');
        }
      }
    }
  }

  Future<void> deleteComplianceDocument(String docId) async {
    if (client == null || docId.isEmpty) return;
    try {
      await client!.from('compliance_documents').delete().eq('id', docId);
      debugPrint('Supabase deleteComplianceDocument success for ID: $docId');
    } catch (e) {
      debugPrint('Supabase deleteComplianceDocument error: $e');
    }
  }

  Future<List<ComplianceDocument>> getComplianceDocuments(String userId) async {
    if (client == null) return [];
    try {
      final response = await client!.from('compliance_documents').select();
      final docs = (response as List)
          .map((map) => ComplianceDocument.fromMap(Map<String, dynamic>.from(map)))
          .where((doc) => doc.documentUrl.isNotEmpty || doc.documentNumber.isNotEmpty || doc.holderName.isNotEmpty)
          .toList();
      return docs;
    } catch (e) {
      debugPrint('Supabase getComplianceDocuments error: $e');
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
      debugPrint('Supabase getTrustScore error: $e');
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
      debugPrint('Supabase saveTrustScore error: $e');
    }
  }

  Future<List<ChatThread>> getChatThreads(String userId) async {
    if (client == null || userId.isEmpty) return [];
    try {
      dynamic response;
      try {
        response = await client!
            .from('conversations')
            .select()
            .or('renter_id.eq.$userId,provider_id.eq.$userId')
            .order('updated_at', ascending: false);
      } catch (_) {
        response = await client!
            .from('chat_threads')
            .select()
            .eq('user_id', userId)
            .order('last_time', ascending: false);
      }
      final List<ChatThread> threads = [];
      for (final map in (response as List)) {
        final threadId = map['id'].toString();
        final msgs = await getChatMessages(threadId, currentUserId: userId);
        threads.add(ChatThread.fromMap(map, msgs, userId));
      }
      return threads;
    } catch (e) {
      debugPrint('Supabase getChatThreads error: $e');
      return [];
    }
  }

  Future<void> saveChatThread(String userId, ChatThread thread) async {
    if (client == null) return;
    try {
      try {
        final Map<String, dynamic> map = {
          'id': thread.id,
          'renter_id': thread.renterId ?? userId,
          'provider_id': thread.providerId ?? userId,
          'title': thread.vehicleTitle,
          'last_message': thread.lastMessage,
          'last_message_time': thread.lastTime.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };
        if (thread.bookingId != null && thread.bookingId!.isNotEmpty) {
          map['booking_id'] = thread.bookingId!;
        }
        if (thread.vehicleId != null && thread.vehicleId!.isNotEmpty) {
          map['vehicle_id'] = thread.vehicleId!;
        }
        await client!.from('conversations').upsert(map);
      } catch (_) {
        try {
          await client!.from('chat_threads').upsert(thread.toMap(userId));
        } catch (_) {}
      }
      for (final msg in thread.messages) {
        await saveChatMessage(thread.id, msg);
      }
    } catch (e) {
      debugPrint('Supabase saveChatThread error: $e');
    }
  }

  Future<List<ChatMessage>> getChatMessages(String threadId, {String? currentUserId}) async {
    if (client == null || threadId.isEmpty) return [];
    try {
      dynamic response;
      try {
        response = await client!
            .from('messages')
            .select()
            .eq('conversation_id', threadId)
            .order('created_at', ascending: true);
      } catch (_) {
        response = await client!
            .from('chat_messages')
            .select()
            .eq('thread_id', threadId)
            .order('timestamp', ascending: true);
      }
      return (response as List).map((map) => ChatMessage.fromMap(Map<String, dynamic>.from(map), currentUserId: currentUserId)).toList();
    } catch (e) {
      debugPrint('Supabase getChatMessages error: $e');
      return [];
    }
  }

  Future<void> saveChatMessage(String threadId, ChatMessage message) async {
    if (client == null) return;
    try {
      try {
        await client!.from('messages').upsert({
          'id': message.id,
          'conversation_id': threadId,
          'sender_id': message.senderId,
          'content': message.text,
          'status': message.status,
          'message_type': message.messageType,
          'attachment_url': message.attachmentUrl,
          'latitude': message.latitude,
          'longitude': message.longitude,
          'original_content': message.originalContent,
          'is_moderated': message.isModerated,
          'flagged_reasons': message.flaggedReasons,
          'is_read': message.isRead || message.status == 'read',
          'created_at': message.timestamp.toIso8601String(),
        });
      } catch (_) {
        try {
          await client!.from('chat_messages').upsert({
            'id': message.id,
            'thread_id': threadId,
            'sender_id': message.senderId,
            'text': message.text,
            'timestamp': message.timestamp.toIso8601String(),
            'is_user': message.isUser,
            'is_moderated': message.isModerated,
            'original_content': message.originalContent,
          });
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Supabase saveChatMessage error: $e');
    }
  }

  Future<void> markMessagesAsRead(String threadId, String userId) async {
    if (client == null || threadId.isEmpty || userId.isEmpty) return;
    try {
      await client!
          .from('messages')
          .update({'is_read': true, 'status': 'read'})
          .eq('conversation_id', threadId)
          .neq('sender_id', userId);
    } catch (e) {
      debugPrint('Supabase markMessagesAsRead error: $e');
    }
  }

  Future<void> updateMessageStatus(String messageId, String status) async {
    if (client == null || messageId.isEmpty) return;
    try {
      await client!
          .from('messages')
          .update({'status': status, 'is_read': status == 'read'})
          .eq('id', messageId);
    } catch (e) {
      debugPrint('Supabase updateMessageStatus error: $e');
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
      debugPrint('Supabase getHostEarnings error: $e');
    }
    return null;
  }

  Future<void> saveHostEarnings(HostEarnings earnings) async {
    if (client == null || earnings.hostId.isEmpty) return;
    try {
      await client!.from('host_earnings').upsert(earnings.toMap());
    } catch (e) {
      debugPrint('Supabase saveHostEarnings error: $e');
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
      debugPrint('Supabase saveAiGeneration error: $e');
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
      debugPrint('Supabase getAiGenerationsForUser error: $e');
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
            debugPrint('Supabase streamUserProfile realtime error handled: $error');
          },
        );
    } catch (e) {
      debugPrint('Supabase streamUserProfile error: $e');
      return Stream.value(null);
    }
  }

  Stream<List<ChatMessage>> streamChatMessages(String threadId, {String? currentUserId}) {
    if (client == null || threadId.isEmpty) return Stream.value([]);
    try {
      return client!
          .from('messages')
          .stream(primaryKey: ['id'])
          .eq('conversation_id', threadId)
          .order('created_at', ascending: true)
          .map((data) => data.map((map) => ChatMessage.fromMap(Map<String, dynamic>.from(map), currentUserId: currentUserId)).toList())
          .handleError((error) {
            debugPrint('Supabase streamChatMessages realtime fallback trigger: $error');
            try {
              return client!
                  .from('chat_messages')
                  .stream(primaryKey: ['id'])
                  .eq('thread_id', threadId)
                  .order('timestamp', ascending: true)
                  .map((data) => data.map((map) => ChatMessage.fromMap(Map<String, dynamic>.from(map), currentUserId: currentUserId)).toList());
            } catch (_) {
              return Stream.value(<ChatMessage>[]);
            }
          });
    } catch (e) {
      debugPrint('Supabase streamChatMessages error: $e');
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

  // ==========================================
  // NOTIFICATION OPERATIONS
  // ==========================================

  Future<List<AppNotification>> getNotificationsForUser(String userId) async {
    if (client == null || userId.isEmpty) return [];
    try {
      final List<dynamic> data = await client!
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('timestamp', ascending: false);
      return data.map((map) => _mapToNotification(map)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveNotification(AppNotification notification) async {
    if (client == null) return;
    try {
      final map = {
        'id': notification.id,
        'user_id': notification.userId,
        'title': notification.title,
        'message': notification.message,
        'type': notification.type.name,
        'timestamp': notification.timestamp.toIso8601String(),
        'is_read': notification.isRead,
        'related_id': notification.relatedId,
        'image_url': notification.imageUrl,
        'action_nav_index': notification.actionNavIndex,
        'metadata': notification.metadata,
      };
      await client!.from('notifications').upsert(map);
    } catch (e) {
      debugPrint('Supabase saveNotification info: $e');
    }
  }

  Future<void> markNotificationAsRead(String id) async {
    try {
      if (client == null) return;
      await client!.from('notifications').update({'is_read': true}).eq('id', id);
    } catch (e) {
      debugPrint('Supabase markNotificationAsRead info: $e');
    }
  }

  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      if (client == null) return;
      await client!.from('notifications').update({'is_read': true}).eq('user_id', userId);
    } catch (e) {
      debugPrint('Supabase markAllNotificationsAsRead info: $e');
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      if (client == null) return;
      await client!.from('notifications').delete().eq('id', id);
    } catch (e) {
      debugPrint('Supabase deleteNotification info: $e');
    }
  }

  Future<void> clearAllNotifications(String userId) async {
    try {
      if (client == null) return;
      await client!.from('notifications').delete().eq('user_id', userId);
    } catch (e) {
      debugPrint('Supabase clearAllNotifications info: $e');
    }
  }

    AppNotification _mapToNotification(Map<String, dynamic> map) {
    return AppNotification.fromMap(map);
  }

  // ==========================================
  // BLOG & SOCIAL HUB OPERATIONS
  // ==========================================
  bool useLocalBlogFallback = false;
  final List<BlogPost> _localBlogPosts = [];
  final List<BlogComment> _localBlogComments = [];

  void _initLocalBlogMockData() {
    if (_localBlogPosts.isNotEmpty) return;
    _localBlogPosts.addAll([
      BlogPost(
        id: 'mock-post-1',
        authorId: 'mock-author-1',
        authorName: 'Alex Mercer',
        authorAvatar: '',
        authorRole: 'Host',
        title: 'My Experience Hosting Guided Rides on PassonRide',
        content: 'Hosting trips around the canyon has been incredibly rewarding. We met riders from 5 different countries last month! Our next ride is scheduled for Saturday morning. Who is in?',
        postType: 'text',
        likesCount: 15,
        likedByUsers: const ['mock-user-2'],
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      BlogPost(
        id: 'mock-post-2',
        authorId: 'mock-author-2',
        authorName: 'Sophia Chen',
        authorAvatar: '',
        authorRole: 'Rider',
        title: 'PassonRide EV Scooter Review & Highway Testing!',
        content: 'Took the new electric scooter for a spin down the coastal highway. Performance, throttle response, and battery range were superb! Check out my quick test video below.',
        postType: 'social_embed',
        socialPlatform: 'youtube',
        socialHandle: '@sophiarides',
        embedUrl: 'https://www.youtube.com/embed/dQw4w9WgXcQ',
        likesCount: 32,
        likedByUsers: const [],
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      BlogPost(
        id: 'mock-post-3',
        authorId: 'mock-author-3',
        authorName: 'David Miller',
        authorAvatar: '',
        authorRole: 'Host',
        title: 'Sunset Beach Ride in Malibu',
        content: 'Captured this gorgeous view during our beach tour yesterday! The weather was perfect and the bikes handled the sand trail smoothly.',
        postType: 'social_embed',
        socialPlatform: 'instagram',
        socialHandle: '@david_malibu_tours',
        embedUrl: 'https://www.instagram.com/p/C-K84u-v3Y9/embed',
        likesCount: 24,
        likedByUsers: const [],
        createdAt: DateTime.now().subtract(const Duration(hours: 8)),
      ),
    ]);

    _localBlogComments.addAll([
      BlogComment(
        id: 'mock-comment-1',
        postId: 'mock-post-1',
        authorId: 'mock-author-host-1',
        authorName: 'Marcus Aurelius',
        authorAvatar: '',
        authorRole: 'Host',
        content: 'Count me in! I will bring the trail maps and some spare charging blocks.',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      BlogComment(
        id: 'mock-comment-2',
        postId: 'mock-post-1',
        authorId: 'mock-author-host-2',
        authorName: 'Clara Vance',
        authorAvatar: '',
        authorRole: 'Host',
        content: 'I will be joining too! Rented the Vespa yesterday. Looking forward to it.',
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
      ),
    ]);
  }

  Future<List<BlogPost>> getBlogPosts() async {
    if (useLocalBlogFallback || client == null) {
      _initLocalBlogMockData();
      return _localBlogPosts;
    }
    try {
      final List<dynamic> data = await client!.from('blog_posts').select().order('created_at', ascending: false);
      return data.map((map) => BlogPost.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Supabase getBlogPosts error: $e');
      if (e.toString().contains('relation') || e.toString().contains('42P01') || e.toString().contains('does not exist')) {
        useLocalBlogFallback = true;
        _initLocalBlogMockData();
        return _localBlogPosts;
      }
      return [];
    }
  }

  Future<void> saveBlogPost(BlogPost post) async {
    if (useLocalBlogFallback || client == null) {
      _localBlogPosts.insert(0, post);
      return;
    }
    try {
      await client!.from('blog_posts').upsert(post.toMap());
    } catch (e) {
      debugPrint('Supabase saveBlogPost error: $e');
      if (e.toString().contains('relation') || e.toString().contains('42P01') || e.toString().contains('does not exist')) {
        useLocalBlogFallback = true;
        _localBlogPosts.insert(0, post);
      }
    }
  }

  Future<void> deleteBlogPost(String postId) async {
    if (useLocalBlogFallback || client == null) {
      _localBlogPosts.removeWhere((p) => p.id == postId);
      _localBlogComments.removeWhere((c) => c.postId == postId);
      return;
    }
    try {
      await client!.from('blog_posts').delete().eq('id', postId);
    } catch (e) {
      debugPrint('Supabase deleteBlogPost error: $e');
    }
  }

  Future<List<BlogComment>> getBlogComments(String postId) async {
    if (useLocalBlogFallback || client == null) {
      _initLocalBlogMockData();
      return _localBlogComments.where((c) => c.postId == postId).toList();
    }
    try {
      final List<dynamic> data = await client!.from('blog_comments').select().eq('post_id', postId).order('created_at', ascending: true);
      return data.map((map) => BlogComment.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Supabase getBlogComments error: $e');
      if (e.toString().contains('relation') || e.toString().contains('42P01') || e.toString().contains('does not exist')) {
        useLocalBlogFallback = true;
        _initLocalBlogMockData();
        return _localBlogComments.where((c) => c.postId == postId).toList();
      }
      return [];
    }
  }

  Future<void> saveBlogComment(BlogComment comment) async {
    if (useLocalBlogFallback || client == null) {
      _localBlogComments.add(comment);
      return;
    }
    try {
      await client!.from('blog_comments').upsert(comment.toMap());
    } catch (e) {
      debugPrint('Supabase saveBlogComment error: $e');
      if (e.toString().contains('relation') || e.toString().contains('42P01') || e.toString().contains('does not exist')) {
        useLocalBlogFallback = true;
        _localBlogComments.add(comment);
      }
    }
  }

  Future<void> deleteBlogComment(String commentId) async {
    if (useLocalBlogFallback || client == null) {
      _localBlogComments.removeWhere((c) => c.id == commentId);
      return;
    }
    try {
      await client!.from('blog_comments').delete().eq('id', commentId);
    } catch (e) {
      debugPrint('Supabase deleteBlogComment error: $e');
    }
  }

  Future<void> likeBlogPost(String postId, String userId) async {
    if (useLocalBlogFallback || client == null) {
      final idx = _localBlogPosts.indexWhere((p) => p.id == postId);
      if (idx != -1) {
        final post = _localBlogPosts[idx];
        final list = List<String>.from(post.likedByUsers);
        int offset = 0;
        if (list.contains(userId)) {
          list.remove(userId);
          offset = -1;
        } else {
          list.add(userId);
          offset = 1;
        }
        _localBlogPosts[idx] = post.copyWith(
          likedByUsers: list,
          likesCount: post.likesCount + offset,
        );
      }
      return;
    }
    try {
      final List<dynamic> data = await client!.from('blog_posts').select('likes_count, liked_by_users').eq('id', postId);
      if (data.isNotEmpty) {
        final map = data.first;
        List<String> list = [];
        if (map['liked_by_users'] != null) {
          final raw = map['liked_by_users'];
          if (raw is List) {
            list = raw.map((e) => e.toString()).toList();
          } else if (raw is String) {
            final decoded = jsonDecode(raw);
            if (decoded is List) {
              list = decoded.map((e) => e.toString()).toList();
            }
          }
        }
        
        int count = map['likes_count'] ?? 0;
        if (list.contains(userId)) {
          list.remove(userId);
          count = count > 0 ? count - 1 : 0;
        } else {
          list.add(userId);
          count += 1;
        }

        await client!.from('blog_posts').update({
          'likes_count': count,
          'liked_by_users': list,
        }).eq('id', postId);
      }
    } catch (e) {
      debugPrint('Supabase likeBlogPost error: $e');
    }
  }
}

