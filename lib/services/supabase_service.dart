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
    final currentAuthUid = client?.auth.currentUser?.id;

    final map = {
      'id': booking.id,
      'vehicle_id': booking.vehicleId,
      'vehicle_title': booking.vehicleTitle,
      'vehicle_image_url': booking.vehicleImageUrl,
      'host_name': booking.hostName,
      'rider_id': booking.riderId,
      'host_id': booking.hostId,
      'account_id': booking.effectiveAccountId,
      'account_name': booking.accountName,
      'account_type': booking.accountType,
      'is_child_hosting': booking.isChildHosting,
      'child_id': booking.childId,
      'child_name': booking.childName,
      'customer_id': booking.customerId,
      'customer_name': booking.customerName,
      'customer_email': booking.customerEmail,
      'customer_phone': booking.customerPhone,
      'customer_photo': booking.customerPhotoUrl,
      'customer_trust_score': booking.customerTrustScore,
      'start_date': booking.startDate.toIso8601String(),
      'end_date': booking.endDate.toIso8601String(),
      'total_price': booking.totalPrice,
      'status': booking.status,
      'unlock_passcode': booking.unlockPasscode,
      'payment_intent_id': booking.paymentIntentId,
      'created_at': booking.createdAt.toIso8601String(),
    };

    try {
      await client!.from('bookings').upsert(map);
    } catch (upsertErr) {
      final errStr = upsertErr.toString();
      debugPrint('Supabase saveBooking initial attempt: $errStr');

      // If error is 42501 (RLS violation) and user is authenticated,
      // the existing remote RLS policy may require auth.uid() == rider_id.
      // Retry with authenticated Supabase UID in rider_id while preserving account_id & child_id.
      if (errStr.contains('42501') &&
          currentAuthUid != null &&
          currentAuthUid.isNotEmpty &&
          booking.riderId != currentAuthUid) {
        try {
          final rlsMap = Map<String, dynamic>.from(map);
          rlsMap['rider_id'] = currentAuthUid;
          await client!.from('bookings').upsert(rlsMap);
          return;
        } catch (rlsErr) {
          debugPrint('Supabase saveBooking RLS retry error: $rlsErr');
        }
      }

      // Fallback: If table has not yet migrated newly added columns, save core fields
      try {
        final coreMap = {
          'id': booking.id,
          'vehicle_id': booking.vehicleId,
          'vehicle_title': booking.vehicleTitle,
          'vehicle_image_url': booking.vehicleImageUrl,
          'host_name': booking.hostName,
          'rider_id': (currentAuthUid != null && currentAuthUid.isNotEmpty)
              ? currentAuthUid
              : booking.riderId,
          'host_id': booking.hostId,
          'start_date': booking.startDate.toIso8601String(),
          'end_date': booking.endDate.toIso8601String(),
          'total_price': booking.totalPrice,
          'status': booking.status,
          'unlock_passcode': booking.unlockPasscode,
          'payment_intent_id': booking.paymentIntentId,
          'created_at': booking.createdAt.toIso8601String(),
        };
        await client!.from('bookings').upsert(coreMap);
      } catch (coreErr) {
        debugPrint('Supabase saveBooking core fallback error: $coreErr');
      }
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

  // ==========================================
  // HOST / PROVIDER SEPARATED PROFILE OPERATIONS
  // ==========================================

  Future<HostProfile?> getHostProfile(String userId) async {
    if (client == null || userId.isEmpty) return null;
    try {
      final List<dynamic> data = await client!.from('host_profiles').select().eq('id', userId);
      if (data.isNotEmpty) {
        return HostProfile.fromMap(Map<String, dynamic>.from(data.first), userId);
      }
      return null;
    } catch (e) {
      debugPrint('Supabase getHostProfile error: $e');
      return null;
    }
  }

  Stream<HostProfile?> streamHostProfile(String userId) {
    if (client == null || userId.isEmpty) return Stream.value(null);
    try {
      return client!
          .from('host_profiles')
          .stream(primaryKey: ['id'])
          .eq('id', userId)
          .map((data) {
            if (data.isNotEmpty) {
              return HostProfile.fromMap(Map<String, dynamic>.from(data.first), userId);
            }
            return null;
          })
          .handleError((error) {
            debugPrint('Supabase streamHostProfile realtime error: $error');
            return null;
          });
    } catch (e) {
      debugPrint('Supabase streamHostProfile error: $e');
      return Stream.value(null);
    }
  }

  Future<void> saveHostProfile(HostProfile profile) async {
    if (client == null || profile.id.isEmpty) return;
    try {
      await client!.from('host_profiles').upsert(profile.toMap());
    } catch (e) {
      debugPrint('Supabase saveHostProfile error: $e');
    }
  }

  Future<HostProfile?> createOrEnsureHostProfile(
    String userId, {
    String? displayName,
    String? email,
    String? phoneNumber,
    String? photoUrl,
    String? bio,
    String? businessName,
    String? governmentIdType,
    String? governmentIdNumber,
    String? documentUrl,
  }) async {
    if (client == null || userId.isEmpty) return null;
    try {
      final existing = await getHostProfile(userId);
      final userProf = await getUserProfile(userId);

      final newProfile = HostProfile(
        id: userId,
        userId: userId,
        displayName: displayName ?? userProf?.displayName ?? existing?.displayName ?? 'Host Provider',
        email: email ?? userProf?.email ?? existing?.email ?? '',
        phoneNumber: phoneNumber ?? userProf?.phoneNumber ?? existing?.phoneNumber ?? '',
        photoUrl: photoUrl ?? userProf?.photoUrl ?? existing?.photoUrl ?? '',
        bio: bio ?? userProf?.bio ?? existing?.bio ?? '',
        businessName: businessName ?? existing?.businessName ?? '',
        governmentIdType: governmentIdType ?? existing?.governmentIdType ?? '',
        governmentIdNumber: governmentIdNumber ?? existing?.governmentIdNumber ?? '',
        documentUrl: documentUrl ?? existing?.documentUrl ?? '',
        isVerified: existing?.isVerified ?? false,
        verificationStatus: existing?.verificationStatus ?? 'pending',
        totalListingsCount: (existing?.totalListingsCount ?? 0) + (existing == null ? 1 : 0),
        rating: existing?.rating ?? 5.0,
        reviewCount: existing?.reviewCount ?? 0,
        trustScore: existing?.trustScore ?? 95.0,
      );

      await saveHostProfile(newProfile);

      // Also ensure role in main profiles table is updated to 'Host'
      if (userProf != null && userProf.role != 'Host') {
        await saveUserProfile(userProf.copyWith(role: 'Host'));
      }
      return newProfile;
    } catch (e) {
      debugPrint('Supabase createOrEnsureHostProfile error: $e');
      return null;
    }
  }

  Future<List<HostProfile>> getPendingProvidersForVerification() async {
    if (client == null) return [];
    try {
      final List<dynamic> data = await client!
          .from('host_profiles')
          .select()
          .order('created_at', ascending: false);
      return data
          .map((item) => HostProfile.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      debugPrint('Supabase getPendingProvidersForVerification error: $e');
      return [];
    }
  }

  Future<void> updateProviderVerificationStatus(
    String userId, {
    required String status,
    required bool isVerified,
    String? notes,
    String? verifiedBy,
  }) async {
    if (client == null || userId.isEmpty) return;
    try {
      final updates = {
        'verification_status': status,
        'is_verified': isVerified,
        'verification_notes': notes ?? '',
        'verified_by': verifiedBy ?? 'Platform Admin',
        'verified_at': isVerified ? DateTime.now().toIso8601String() : null,
        'updated_at': DateTime.now().toIso8601String(),
      };
      await client!.from('host_profiles').update(updates).eq('id', userId);
    } catch (e) {
      debugPrint('Supabase updateProviderVerificationStatus error: $e');
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

  bool _isUuid(String? str) {
    if (str == null || str.isEmpty) return false;
    final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
    return uuidRegex.hasMatch(str.trim());
  }

  Future<List<ChatMessage>> getChatMessages(String threadId, {String? currentUserId}) async {
    if (client == null || threadId.isEmpty) return [];
    try {
      dynamic response;
      if (_isUuid(threadId)) {
        try {
          response = await client!
              .from('messages')
              .select()
              .eq('conversation_id', threadId)
              .order('created_at', ascending: true);
        } catch (_) {}
      }
      if (response == null) {
        try {
          response = await client!
              .from('chat_messages')
              .select()
              .eq('thread_id', threadId)
              .order('timestamp', ascending: true);
        } catch (_) {}
      }
      if (response == null) return [];
      return (response as List).map((map) => ChatMessage.fromMap(Map<String, dynamic>.from(map), currentUserId: currentUserId)).toList();
    } catch (e) {
      debugPrint('Supabase getChatMessages error: $e');
      return [];
    }
  }

  Future<void> saveChatMessage(String threadId, ChatMessage message) async {
    if (client == null) return;
    try {
      if (_isUuid(threadId)) {
        try {
          final msgMap = <String, dynamic>{
            'conversation_id': threadId,
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
          };
          if (_isUuid(message.id)) msgMap['id'] = message.id;
          if (_isUuid(message.senderId)) msgMap['sender_id'] = message.senderId;

          await client!.from('messages').upsert(msgMap);
          return;
        } catch (_) {}
      }
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
      if (_isUuid(threadId)) {
        return client!
            .from('messages')
            .stream(primaryKey: ['id'])
            .eq('conversation_id', threadId)
            .order('created_at', ascending: true)
            .map((data) => data.map((map) => ChatMessage.fromMap(Map<String, dynamic>.from(map), currentUserId: currentUserId)).toList())
            .handleError((error) {
              debugPrint('Supabase streamChatMessages (messages) realtime handled: $error');
            });
      } else {
        return client!
            .from('chat_messages')
            .stream(primaryKey: ['id'])
            .eq('thread_id', threadId)
            .order('timestamp', ascending: true)
            .map((data) => data.map((map) => ChatMessage.fromMap(Map<String, dynamic>.from(map), currentUserId: currentUserId)).toList())
            .handleError((error) {
              debugPrint('Supabase streamChatMessages (chat_messages) realtime handled: $error');
            });
      }
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
    return Booking.fromMap(map);
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
      if (data.isEmpty) {
        _initLocalBlogMockData();
        return _localBlogPosts;
      }
      return data.map((map) => BlogPost.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Supabase getBlogPosts error: $e');
      useLocalBlogFallback = true;
      _initLocalBlogMockData();
      return _localBlogPosts;
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
      useLocalBlogFallback = true;
      _localBlogPosts.insert(0, post);
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
      useLocalBlogFallback = true;
      _initLocalBlogMockData();
      return _localBlogComments.where((c) => c.postId == postId).toList();
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
      useLocalBlogFallback = true;
      _localBlogComments.add(comment);
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

  // ==========================================
  // MOTHER - CHILD ARCHITECTURE OPERATIONS
  // ==========================================

  /// Fetch mother profile by motherId or customerId
  Future<MotherProfile?> getMotherProfile(String motherId) async {
    if (client == null || motherId.isEmpty) return null;
    try {
      final List<dynamic> data = await client!
          .from('mother_profile')
          .select()
          .or('mother_id.eq.$motherId,customer_id.eq.$motherId')
          .limit(1);

      if (data.isNotEmpty) {
        return MotherProfile.fromMap(Map<String, dynamic>.from(data.first));
      }
    } catch (e) {
      debugPrint('Supabase getMotherProfile info: $e');
    }
    return null;
  }

  /// Upsert a mother profile
  Future<void> saveMotherProfile(MotherProfile profile) async {
    if (client == null || profile.motherId.isEmpty) return;
    try {
      final map = {
        'mother_id': profile.motherId,
        'customer_id': profile.customerId,
        'name': profile.name,
        'email': profile.email.toLowerCase().trim(),
        'phone': profile.phone,
        'profile_photo': profile.profilePhoto,
        'status': profile.status,
        'updated_at': DateTime.now().toIso8601String(),
      };
      await client!.from('mother_profile').upsert(map);
    } catch (e) {
      debugPrint('Supabase saveMotherProfile info: $e');
    }
  }

  /// Fetch all child profiles linked to a given motherId (Max 3)
  Future<List<ChildProfile>> getChildProfilesForMother(String motherId) async {
    if (client == null || motherId.isEmpty) return [];
    try {
      final List<dynamic> data = await client!
          .from('child_profile')
          .select()
          .eq('mother_id', motherId)
          .order('created_at', ascending: true);

      return data
          .map((item) => ChildProfile.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      debugPrint('Supabase getChildProfilesForMother info: $e');
      return [];
    }
  }

  /// Fetch single child profile by childId
  Future<ChildProfile?> getChildProfile(String childId) async {
    if (client == null || childId.isEmpty) return null;
    try {
      final List<dynamic> data = await client!
          .from('child_profile')
          .select()
          .eq('child_id', childId)
          .limit(1);

      if (data.isNotEmpty) {
        return ChildProfile.fromMap(Map<String, dynamic>.from(data.first));
      }
    } catch (e) {
      debugPrint('Supabase getChildProfile info: $e');
    }
    return null;
  }

  /// Save or update child profile
  Future<void> saveChildProfile(ChildProfile profile) async {
    if (client == null || profile.childId.isEmpty) return;
    try {
      final map = {
        'child_id': profile.childId,
        'mother_id': profile.motherId,
        'name': profile.name,
        'email': profile.email.toLowerCase().trim(),
        'phone': profile.phone,
        'profile_photo': profile.profilePhoto,
        'status': profile.status,
        'updated_at': DateTime.now().toIso8601String(),
      };
      await client!.from('child_profile').upsert(map);
    } catch (e) {
      debugPrint('Supabase saveChildProfile info: $e');
    }
  }

  /// Check if an email is already associated with any Mother or Child account
  Future<bool> isEmailAvailable(String email, {String? excludeAccountId}) async {
    final cleanEmail = email.toLowerCase().trim();
    if (cleanEmail.isEmpty) return false;
    if (client == null) return true;

    try {
      // Check mother_profile
      final List<dynamic> motherRes = await client!
          .from('mother_profile')
          .select('mother_id')
          .eq('email', cleanEmail);

      final matchingMothers = motherRes
          .where((m) => excludeAccountId == null || m['mother_id'] != excludeAccountId)
          .toList();
      if (matchingMothers.isNotEmpty) return false;

      // Check child_profile
      final List<dynamic> childRes = await client!
          .from('child_profile')
          .select('child_id')
          .eq('email', cleanEmail);

      final matchingChildren = childRes
          .where((c) => excludeAccountId == null || c['child_id'] != excludeAccountId)
          .toList();
      if (matchingChildren.isNotEmpty) return false;

      // Check profiles
      final List<dynamic> profileRes = await client!
          .from('profiles')
          .select('id')
          .eq('email', cleanEmail);

      final matchingProfiles = profileRes
          .where((p) => excludeAccountId == null || p['id'] != excludeAccountId)
          .toList();
      if (matchingProfiles.isNotEmpty) return false;

      return true;
    } catch (e) {
      debugPrint('Supabase isEmailAvailable check info: $e');
      return true;
    }
  }

  /// Ensures mother profile record exists in Supabase DB to satisfy foreign key constraint
  Future<void> _ensureMotherRecordInDb(String motherId) async {
    if (client == null || motherId.isEmpty) return;
    try {
      final List<dynamic> motherRes = await client!
          .from('mother_profile')
          .select('mother_id')
          .eq('mother_id', motherId)
          .limit(1);

      if (motherRes.isEmpty) {
        final rawUid = motherId.startsWith('mth_') ? motherId.substring(4) : motherId;
        final List<dynamic> profileRes = await client!
            .from('profiles')
            .select()
            .eq('id', rawUid)
            .limit(1);

        final profileData = profileRes.isNotEmpty ? profileRes.first : null;
        await client!.from('mother_profile').upsert({
          'mother_id': motherId,
          'customer_id': rawUid,
          'name': profileData != null && (profileData['display_name'] ?? '').toString().isNotEmpty
              ? profileData['display_name']
              : 'Mother Account',
          'email': profileData != null && (profileData['email'] ?? '').toString().isNotEmpty
              ? profileData['email']
              : 'mother@example.com',
          'phone': profileData != null ? (profileData['phone_number'] ?? '') : '',
          'profile_photo': profileData != null ? (profileData['photo_url'] ?? '') : '',
          'status': 'active',
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('Supabase _ensureMotherRecordInDb notice: $e');
    }
  }

  /// Authoritatively creates a new child account profile under the Mother ID
  Future<({bool success, String? error, ChildProfile? profile})> createChildProfile({
    required String motherId,
    required String name,
    required String email,
    required String phone,
    String profilePhoto = '',
    String? customChildId,
  }) async {
    final cleanEmail = email.toLowerCase().trim();
    if (cleanEmail.isEmpty) {
      return (success: false, error: 'Email cannot be empty.', profile: null);
    }

    if (client != null) {
      try {
        // Guarantee the mother profile exists in mother_profile table to satisfy FK constraint
        await _ensureMotherRecordInDb(motherId);

        // 1. Authoritative check on 3-child limit
        final List<dynamic> existingChildren = await client!
            .from('child_profile')
            .select('child_id')
            .eq('mother_id', motherId);

        if (existingChildren.length >= 3) {
          return (
            success: false,
            error: 'You have reached the maximum limit of 3 child accounts.',
            profile: null
          );
        }

        // 2. Authoritative check on email uniqueness
        final available = await isEmailAvailable(cleanEmail);
        if (!available) {
          return (
            success: false,
            error:
                'This email address is already associated with another account. Please use a different email address.',
            profile: null
          );
        }

        final childId = customChildId ??
            'chd_${DateTime.now().millisecondsSinceEpoch}_${existingChildren.length + 1}';

        final childProfile = ChildProfile(
          childId: childId,
          motherId: motherId,
          name: name.trim(),
          email: cleanEmail,
          phone: phone.trim(),
          profilePhoto: profilePhoto,
          status: 'active',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final map = {
          'child_id': childProfile.childId,
          'mother_id': childProfile.motherId,
          'name': childProfile.name,
          'email': childProfile.email,
          'phone': childProfile.phone,
          'profile_photo': childProfile.profilePhoto,
          'status': childProfile.status,
          'created_at': childProfile.createdAt.toIso8601String(),
          'updated_at': childProfile.updatedAt.toIso8601String(),
        };

        await client!.from('child_profile').insert(map);

        // Also ensure child has an entry in profiles for generic lookup
        try {
          await client!.from('profiles').upsert({
            'id': childProfile.childId,
            'email': childProfile.email,
            'display_name': childProfile.name,
            'phone_number': childProfile.phone,
            'photo_url': childProfile.profilePhoto,
            'role': 'Rider',
            'trust_score': 95.0,
            'updated_at': DateTime.now().toIso8601String(),
          });
        } catch (_) {}

        return (success: true, error: null, profile: childProfile);
      } catch (e) {
        debugPrint('Supabase createChildProfile error: $e');
        final errStr = e.toString();
        // If the table is not in the schema cache or missing on remote Supabase (PGRST205),
        // gracefully fall back to local profile creation so the user is not blocked
        if (errStr.contains('PGRST205') ||
            errStr.contains('Could not find the table') ||
            errStr.contains('schema cache')) {
          debugPrint('Notice: Remote child_profile table not found in schema cache. Falling back to local offline profile.');
          final fallbackChildId = customChildId ??
              'chd_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
          final fallbackProfile = ChildProfile(
            childId: fallbackChildId,
            motherId: motherId,
            name: name.trim(),
            email: cleanEmail,
            phone: phone.trim(),
            profilePhoto: profilePhoto,
            status: 'active',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          return (success: true, error: null, profile: fallbackProfile);
        }

        final cleanError = errStr.contains('maximum limit of 3')
            ? 'You have reached the maximum limit of 3 child accounts.'
            : (errStr.contains('already associated')
                ? 'This email address is already associated with another account. Please use a different email address.'
                : (errStr.contains('child_profile_mother_id_fkey') || errStr.contains('23503')
                    ? 'Mother profile is not registered in the database. Please reload and try again.'
                    : (errStr.contains('message: ')
                        ? errStr.split('message: ').last.split(', code:').first
                        : 'Failed to create child profile: $e')));

        return (
          success: false,
          error: cleanError,
          profile: null
        );
      }
    }

    // Offline / local fallback
    final childId = customChildId ?? 'chd_${DateTime.now().millisecondsSinceEpoch}';
    final fallbackProfile = ChildProfile(
      childId: childId,
      motherId: motherId,
      name: name.trim(),
      email: cleanEmail,
      phone: phone.trim(),
      profilePhoto: profilePhoto,
      status: 'active',
    );
    return (success: true, error: null, profile: fallbackProfile);
  }

  /// Links an existing independent user account as a child under the Mother account
  Future<({bool success, String? error, ChildProfile? profile})> linkExistingAccountAsChild({
    required String motherId,
    required String childEmail,
    required String childId,
    String childName = '',
    String childPhone = '',
    String childPhoto = '',
  }) async {
    final cleanEmail = childEmail.toLowerCase().trim();
    if (client != null) {
      try {
        // Guarantee the mother profile exists in mother_profile table to satisfy FK constraint
        await _ensureMotherRecordInDb(motherId);

        // 1. Authoritative check on child limit
        final List<dynamic> existingChildren = await client!
            .from('child_profile')
            .select('child_id, mother_id')
            .eq('mother_id', motherId);

        if (existingChildren.length >= 3) {
          return (
            success: false,
            error: 'You have reached the maximum limit of 3 child accounts.',
            profile: null
          );
        }

        // 2. Check if already linked to another mother
        final List<dynamic> existingLink = await client!
            .from('child_profile')
            .select('child_id, mother_id')
            .eq('child_id', childId);

        if (existingLink.isNotEmpty) {
          final currentMother = existingLink.first['mother_id'];
          if (currentMother != motherId) {
            return (
              success: false,
              error: 'This account is already linked to another Mother Profile.',
              profile: null
            );
          }
        }

        final linkedProfile = ChildProfile(
          childId: childId,
          motherId: motherId,
          name: childName.isNotEmpty ? childName : cleanEmail.split('@').first,
          email: cleanEmail,
          phone: childPhone,
          profilePhoto: childPhoto,
          status: 'active',
          updatedAt: DateTime.now(),
        );

        await client!.from('child_profile').upsert({
          'child_id': linkedProfile.childId,
          'mother_id': linkedProfile.motherId,
          'name': linkedProfile.name,
          'email': linkedProfile.email,
          'phone': linkedProfile.phone,
          'profile_photo': linkedProfile.profilePhoto,
          'status': linkedProfile.status,
          'updated_at': DateTime.now().toIso8601String(),
        });

        // Ensure bookings and vehicles stay intact with account_id populated
        try {
          await client!
              .from('bookings')
              .update({'account_id': childId})
              .eq('rider_id', childId);
          await client!
              .from('vehicles')
              .update({'owner_account_id': childId})
              .eq('host_id', childId);
        } catch (_) {}

        return (success: true, error: null, profile: linkedProfile);
      } catch (e) {
        debugPrint('Supabase linkExistingAccountAsChild error: $e');
        final errStr = e.toString();
        if (errStr.contains('PGRST205') ||
            errStr.contains('Could not find the table') ||
            errStr.contains('schema cache')) {
          final fallback = ChildProfile(
            childId: childId,
            motherId: motherId,
            name: childName.isNotEmpty ? childName : cleanEmail.split('@').first,
            email: cleanEmail,
            phone: childPhone,
            profilePhoto: childPhoto,
            status: 'active',
            updatedAt: DateTime.now(),
          );
          return (success: true, error: null, profile: fallback);
        }
        return (success: false, error: 'Failed to link account: $e', profile: null);
      }
    }

    final fallback = ChildProfile(
      childId: childId,
      motherId: motherId,
      name: childName.isNotEmpty ? childName : cleanEmail.split('@').first,
      email: cleanEmail,
      phone: childPhone,
      profilePhoto: childPhoto,
    );
    return (success: true, error: null, profile: fallback);
  }

  /// Deletes or unlinks a child profile from Supabase child_profile table
  Future<({bool success, String? error})> deleteChildProfile(String childId) async {
    if (childId.isEmpty) {
      return (success: false, error: 'Invalid child ID.');
    }
    if (client != null) {
      try {
        await client!.from('child_profile').delete().eq('child_id', childId);
        return (success: true, error: null);
      } catch (e) {
        debugPrint('Supabase deleteChildProfile error: $e');
        final errStr = e.toString();
        return (
          success: false,
          error: errStr.contains('message: ')
              ? errStr.split('message: ').last.split(', code:').first
              : 'Failed to remove child account: $e'
        );
      }
    }
    return (success: true, error: null);
  }

  /// Mother Profile aggregated bookings:
  /// Queries bookings for Mother + all linked Child accounts (both child rentals & child hosted fleet).
  /// Returns sanitized booking details labeled with account ownership and customer dossiers.
  Future<List<Booking>> getMotherAggregatedBookings(String motherId) async {
    if (client == null || motherId.isEmpty) return [];
    try {
      // 1. Try secure Postgres RPC if installed
      try {
        final List<dynamic> rpcData = await client!
            .rpc('get_mother_aggregated_bookings', params: {'p_mother_id': motherId});
        if (rpcData.isNotEmpty) {
          return rpcData.map((map) {
            return Booking.fromMap(Map<String, dynamic>.from(map));
          }).toList();
        }
      } catch (rpcErr) {
        debugPrint('RPC get_mother_aggregated_bookings not available, falling back to direct query: $rpcErr');
      }

      // 2. Direct Query Fallback
      final motherBookingsData = await client!
          .from('bookings')
          .select()
          .or('rider_id.eq.$motherId,account_id.eq.$motherId');

      final List<Booking> results = motherBookingsData.map((m) {
        final b = _mapToBooking(m);
        return b.copyWith(
          accountId: motherId,
          accountName: 'Mother Account',
          accountType: 'mother',
        );
      }).toList();

      // Fetch linked children
      final List<ChildProfile> children = await getChildProfilesForMother(motherId);
      for (final child in children) {
        // Fetch vehicles hosted by child
        List<String> childVehicleIds = [];
        try {
          final List<dynamic> childVehicles = await client!
              .from('vehicles')
              .select('id')
              .or('host_id.eq.${child.childId},owner_account_id.eq.${child.childId}');
          childVehicleIds = childVehicles.map((v) => v['id'].toString()).toList();
        } catch (_) {}

        var queryFilter = 'rider_id.eq.${child.childId},account_id.eq.${child.childId},host_id.eq.${child.childId}';
        if (childVehicleIds.isNotEmpty) {
          queryFilter += ',vehicle_id.in.(${childVehicleIds.join(',')})';
        }

        final List<dynamic> childBookingsData = await client!
            .from('bookings')
            .select()
            .or(queryFilter);

        for (final cm in childBookingsData) {
          final map = Map<String, dynamic>.from(cm);
          final isHostedByChild = map['host_id'] == child.childId ||
              (map['vehicle_id'] != null && childVehicleIds.contains(map['vehicle_id'].toString()));
          final isChildRenter = map['rider_id'] == child.childId;
          final isChildHosting = isHostedByChild && !isChildRenter;

          String customerName = 'Customer Rider';
          String customerEmail = '';
          String customerPhone = '';
          String customerPhoto = '';
          double customerTrustScore = 95.0;

          if (isChildHosting && map['rider_id'] != null && map['rider_id'].toString().isNotEmpty) {
            try {
              final profileData = await client!
                  .from('profiles')
                  .select('display_name, email, phone_number, photo_url, trust_score')
                  .eq('id', map['rider_id'].toString())
                  .maybeSingle();
              if (profileData != null) {
                customerName = profileData['display_name'] ?? 'Customer';
                customerEmail = profileData['email'] ?? '';
                customerPhone = profileData['phone_number'] ?? '';
                customerPhoto = profileData['photo_url'] ?? '';
                customerTrustScore = (profileData['trust_score'] as num?)?.toDouble() ?? 95.0;
              }
            } catch (_) {}
          }

          results.add(Booking.fromMap(map).copyWith(
            accountId: child.childId,
            accountName: child.name,
            accountType: isChildHosting ? 'child_hosting' : 'child',
            isChildHosting: isChildHosting,
            childId: child.childId,
            childName: child.name,
            customerId: isChildHosting ? (map['rider_id'] ?? '') : child.childId,
            customerName: isChildHosting ? customerName : child.name,
            customerEmail: isChildHosting ? customerEmail : child.email,
            customerPhone: isChildHosting ? customerPhone : child.phone,
            customerPhotoUrl: isChildHosting ? customerPhoto : child.profilePhoto,
            customerTrustScore: isChildHosting ? customerTrustScore : 100.0,
          ));
        }
      }

      results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return results;
    } catch (e) {
      debugPrint('Supabase getMotherAggregatedBookings error: $e');
      return [];
    }
  }

  /// Query bookings strictly for a specific account (strict data isolation for Child accounts)
  Future<List<Booking>> getBookingsForAccount(String accountId) async {
    if (client == null || accountId.isEmpty) return [];
    try {
      try {
        final List<dynamic> data = await client!
            .from('bookings')
            .select()
            .or('account_id.eq.$accountId,rider_id.eq.$accountId,host_id.eq.$accountId,child_id.eq.$accountId')
            .order('created_at', ascending: false);

        return data.map((map) => _mapToBooking(map)).toList();
      } catch (colErr) {
        // Fallback for core schema if extended columns do not exist
        final List<dynamic> fallbackData = await client!
            .from('bookings')
            .select()
            .or('rider_id.eq.$accountId,host_id.eq.$accountId')
            .order('created_at', ascending: false);

        return fallbackData.map((map) => _mapToBooking(map)).toList();
      }
    } catch (e) {
      debugPrint('Supabase getBookingsForAccount error: $e');
      return [];
    }
  }

  /// Query vehicles strictly owned/hosted by a specific account (strict hosting separation)
  Future<List<Vehicle>> getVehiclesForAccount(String accountId) async {
    if (client == null || accountId.isEmpty) return [];
    try {
      final List<dynamic> data = await client!
          .from('vehicles')
          .select()
          .or('owner_account_id.eq.$accountId,host_id.eq.$accountId')
          .order('updated_at', ascending: false);

      return data.map((map) => _mapToVehicle(map)).toList();
    } catch (e) {
      debugPrint('Supabase getVehiclesForAccount error: $e');
      return [];
    }
  }
}

  // ==========================================
  // PAYMENT & ESCROW TRANSACTIONS
  // ==========================================

  final List<PaymentTransaction> _localPaymentTransactions = [];

  Future<bool> recordPaymentTransaction(PaymentTransaction transaction) async {
    _localPaymentTransactions.insert(0, transaction);

    if (client == null) {
      return true;
    }

    try {
      final map = transaction.toMap();
      // If user_id is empty or not a valid UUID format, remove to let DB default or NULL
      if (transaction.userId.isEmpty || !transaction.userId.contains('-')) {
        map.remove('user_id');
      }
      await client!.from('payment_transactions').insert(map);
      debugPrint('Supabase payment transaction recorded: ${transaction.razorpayPaymentId}');
      return true;
    } catch (e) {
      debugPrint('Supabase recordPaymentTransaction error: $e');
      return true; // Return true as local record exists
    }
  }

  Future<List<PaymentTransaction>> getPaymentTransactions({
    String? userId,
    String? bookingId,
  }) async {
    if (client == null) {
      var filtered = List<PaymentTransaction>.from(_localPaymentTransactions);
      if (userId != null && userId.isNotEmpty) {
        filtered = filtered.where((t) => t.userId == userId).toList();
      }
      if (bookingId != null && bookingId.isNotEmpty) {
        filtered = filtered.where((t) => t.bookingId == bookingId).toList();
      }
      return filtered;
    }

    try {
      var query = client!.from('payment_transactions').select();
      if (userId != null && userId.isNotEmpty) {
        query = query.eq('user_id', userId);
      }
      if (bookingId != null && bookingId.isNotEmpty) {
        query = query.eq('booking_id', bookingId);
      }
      final List<dynamic> data = await query.order('created_at', ascending: false);
      return data.map((map) => PaymentTransaction.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Supabase getPaymentTransactions error: $e');
      return _localPaymentTransactions;
    }
  }
}
