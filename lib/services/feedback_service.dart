import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/feedback_model.dart';
import 'imagekit_service.dart';

class FeedbackService {
  static final FeedbackService _instance = FeedbackService._internal();
  factory FeedbackService() => _instance;
  FeedbackService._internal();

  final ImageKitService _imageKitService = ImageKitService();

  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  // Local fallback cache for smooth offline/in-memory experience
  final List<AppFeedbackReview> _appReviewsCache = [];
  final List<TripAspectReview> _tripReviewsCache = [];

  // ==========================================
  // APP & PLATFORM FEEDBACK OPERATIONS
  // ==========================================

  /// Submit App & Platform Experience Feedback or Bug Report
  Future<AppFeedbackReview?> submitAppFeedbackReview({
    required String userId,
    required String userName,
    required String userAvatar,
    required String category, // 'app_experience', 'bug_report', 'feature_request', 'platform_trust'
    required double rating,
    required String comment,
    bool isPublic = true,
    List<Uint8List>? rawImageBytes,
    Map<String, dynamic>? metadata,
  }) async {
    // 1. Upload screenshot/photo attachments if present
    final List<String> uploadedAttachmentUrls = [];
    if (rawImageBytes != null && rawImageBytes.isNotEmpty) {
      for (var i = 0; i < rawImageBytes.length; i++) {
        final fileName = 'feedback_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final url = await _imageKitService.uploadImage(
          bytes: rawImageBytes[i],
          fileName: fileName,
          folder: '/feedback',
        );
        if (url != null && url.isNotEmpty) {
          uploadedAttachmentUrls.add(url);
        }
      }
    }

    // 2. Perform AI Sentiment Analysis & Auto-tagging
    final aiResult = _analyzeFeedbackText(comment, rating, category);

    final review = AppFeedbackReview(
      id: 'fb_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
      category: category,
      rating: rating,
      comment: comment,
      isPublic: isPublic,
      attachmentUrls: uploadedAttachmentUrls,
      metadata: metadata ?? {},
      aiSentiment: aiResult['sentiment'] ?? 'positive',
      aiPriorityScore: (aiResult['priority'] as num?)?.toDouble() ?? 0.5,
      aiTags: List<String>.from(aiResult['tags'] ?? []),
      status: 'published',
      createdAt: DateTime.now(),
    );

    // Save to local cache first
    _appReviewsCache.insert(0, review);

    // Persist to Supabase if connected
    if (_client != null) {
      try {
        final res = await _client!
            .from('app_feedback_reviews')
            .insert(review.toMap())
            .select()
            .single();
        return AppFeedbackReview.fromMap(res);
      } catch (e) {
        if (kDebugMode) {
          print('Supabase app_feedback_reviews insert info: $e');
        }
        try {
          final fallbackMap = review.toMap()..remove('user_id');
          final res = await _client!
              .from('app_feedback_reviews')
              .insert(fallbackMap)
              .select()
              .single();
          return AppFeedbackReview.fromMap(res);
        } catch (_) {}
      }
    }

    return review;
  }

  /// Get Public App & Platform Feedback Reviews
  Future<List<AppFeedbackReview>> getPublicAppFeedbackReviews({
    String? categoryFilter,
    int limit = 50,
  }) async {
    if (_client != null) {
      try {
        final List<dynamic> data = (categoryFilter != null && categoryFilter.isNotEmpty && categoryFilter != 'all')
            ? await _client!
                .from('app_feedback_reviews')
                .select()
                .eq('category', categoryFilter)
                .order('created_at', ascending: false)
                .limit(limit)
            : await _client!
                .from('app_feedback_reviews')
                .select()
                .order('created_at', ascending: false)
                .limit(limit);

        final fetched = data.map((map) => AppFeedbackReview.fromMap(map)).toList();
        final Map<String, AppFeedbackReview> allMap = {};
        for (var r in fetched) {
          if (r.id.isNotEmpty) allMap[r.id] = r;
        }
        for (var r in _appReviewsCache) {
          if (r.id.isNotEmpty && !allMap.containsKey(r.id)) {
            allMap[r.id] = r;
          }
        }
        return allMap.values.toList();
      } catch (e) {
        if (kDebugMode) {
          print('Supabase getPublicAppFeedbackReviews error: $e');
        }
      }
    }

    if (categoryFilter != null && categoryFilter.isNotEmpty && categoryFilter != 'all') {
      return _appReviewsCache.where((r) => r.category == categoryFilter).toList();
    }
    return List.from(_appReviewsCache);
  }

  // ==========================================
  // TRIP & ASPECT RATING OPERATIONS
  // ==========================================

  /// Submit Detailed Trip & Aspect Review for Vehicle or Tour
  Future<TripAspectReview?> submitTripAspectReview({
    String? bookingId,
    String? vehicleId,
    String? tourId,
    required String riderId,
    required String hostId,
    required String riderName,
    required String riderAvatar,
    required double overallRating,
    double cleanlinessRating = 5.0,
    double performanceRating = 5.0,
    double communicationRating = 5.0,
    double valueRating = 5.0,
    required String comment,
    List<String> selectedTags = const [],
    List<Uint8List>? rawPhotosBytes,
  }) async {
    // 1. Upload photos if attached
    final List<String> uploadedPhotoUrls = [];
    if (rawPhotosBytes != null && rawPhotosBytes.isNotEmpty) {
      for (var i = 0; i < rawPhotosBytes.length; i++) {
        final fileName = 'trip_review_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final url = await _imageKitService.uploadImage(
          bytes: rawPhotosBytes[i],
          fileName: fileName,
          folder: '/reviews',
        );
        if (url != null && url.isNotEmpty) {
          uploadedPhotoUrls.add(url);
        }
      }
    }

    // 2. Perform AI Sentiment Analysis
    final aiResult = _analyzeFeedbackText(comment, overallRating, 'trip_review');

    final review = TripAspectReview(
      id: 'rev_${DateTime.now().millisecondsSinceEpoch}',
      bookingId: bookingId,
      vehicleId: vehicleId,
      tourId: tourId,
      riderId: riderId,
      hostId: hostId,
      riderName: riderName,
      riderAvatar: riderAvatar,
      overallRating: overallRating,
      cleanlinessRating: cleanlinessRating,
      performanceRating: performanceRating,
      communicationRating: communicationRating,
      valueRating: valueRating,
      comment: comment,
      selectedTags: selectedTags,
      photoUrls: uploadedPhotoUrls,
      aiSentiment: aiResult['sentiment'] ?? 'positive',
      aiSummary: aiResult['summary'] ?? 'Rider appreciated overall vehicle cleanliness and host punctuality.',
      createdAt: DateTime.now(),
    );

    _tripReviewsCache.insert(0, review);

    if (_client != null) {
      try {
        final res = await _client!
            .from('trip_reviews_extended')
            .insert(review.toMap())
            .select()
            .single();
        return TripAspectReview.fromMap(res);
      } catch (e) {
        if (kDebugMode) {
          print('Supabase trip_reviews_extended insert info: $e');
        }
        try {
          final fallbackMap = review.toMap()
            ..remove('rider_id')
            ..remove('host_id');
          final res = await _client!
              .from('trip_reviews_extended')
              .insert(fallbackMap)
              .select()
              .single();
          return TripAspectReview.fromMap(res);
        } catch (_) {}
      }
    }

    return review;
  }

  /// Get Detailed Trip Reviews for a Vehicle
  Future<List<TripAspectReview>> getTripAspectReviewsForVehicle(String vehicleId) async {
    if (_client != null) {
      try {
        final List<dynamic> data = vehicleId.isNotEmpty
            ? await _client!
                .from('trip_reviews_extended')
                .select()
                .eq('vehicle_id', vehicleId)
                .order('created_at', ascending: false)
            : await _client!
                .from('trip_reviews_extended')
                .select()
                .order('created_at', ascending: false);

        final fetched = data.map((map) => TripAspectReview.fromMap(map)).toList();
        final Map<String, TripAspectReview> allMap = {};
        for (var r in fetched) {
          if (r.id.isNotEmpty) allMap[r.id] = r;
        }
        for (var r in _tripReviewsCache) {
          if (vehicleId.isEmpty || r.vehicleId == vehicleId) {
            if (r.id.isNotEmpty && !allMap.containsKey(r.id)) {
              allMap[r.id] = r;
            }
          }
        }
        return allMap.values.toList();
      } catch (e) {
        if (kDebugMode) {
          print('Supabase getTripAspectReviewsForVehicle error: $e');
        }
      }
    }

    return _tripReviewsCache.where((r) => vehicleId.isEmpty || r.vehicleId == vehicleId || r.vehicleId == null).toList();
  }

  /// Get Detailed Trip Reviews for a Tour
  Future<List<TripAspectReview>> getTripAspectReviewsForTour(String tourId) async {
    if (_client != null) {
      try {
        final List<dynamic> data = tourId.isNotEmpty
            ? await _client!
                .from('trip_reviews_extended')
                .select()
                .eq('tour_id', tourId)
                .order('created_at', ascending: false)
            : await _client!
                .from('trip_reviews_extended')
                .select()
                .order('created_at', ascending: false);

        final fetched = data.map((map) => TripAspectReview.fromMap(map)).toList();
        final Map<String, TripAspectReview> allMap = {};
        for (var r in fetched) {
          if (r.id.isNotEmpty) allMap[r.id] = r;
        }
        for (var r in _tripReviewsCache) {
          if (tourId.isEmpty || r.tourId == tourId) {
            if (r.id.isNotEmpty && !allMap.containsKey(r.id)) {
              allMap[r.id] = r;
            }
          }
        }
        return allMap.values.toList();
      } catch (e) {
        if (kDebugMode) {
          print('Supabase getTripAspectReviewsForTour error: $e');
        }
      }
    }

    return _tripReviewsCache.where((r) => tourId.isEmpty || r.tourId == tourId || r.tourId == null).toList();
  }

  /// Add Host Response to a review
  Future<bool> addHostResponse(String reviewId, String hostResponse) async {
    final idx = _tripReviewsCache.indexWhere((r) => r.id == reviewId);
    if (idx != -1) {
      final old = _tripReviewsCache[idx];
      _tripReviewsCache[idx] = TripAspectReview(
        id: old.id,
        bookingId: old.bookingId,
        vehicleId: old.vehicleId,
        tourId: old.tourId,
        riderId: old.riderId,
        hostId: old.hostId,
        riderName: old.riderName,
        riderAvatar: old.riderAvatar,
        overallRating: old.overallRating,
        cleanlinessRating: old.cleanlinessRating,
        performanceRating: old.performanceRating,
        communicationRating: old.communicationRating,
        valueRating: old.valueRating,
        comment: old.comment,
        selectedTags: old.selectedTags,
        photoUrls: old.photoUrls,
        aiSentiment: old.aiSentiment,
        aiSummary: old.aiSummary,
        hostResponse: hostResponse,
        hostRespondedAt: DateTime.now(),
        createdAt: old.createdAt,
      );
    }

    if (_client != null) {
      try {
        await _client!.from('trip_reviews_extended').update({
          'host_response': hostResponse,
          'host_responded_at': DateTime.now().toIso8601String(),
        }).eq('id', reviewId);
        return true;
      } catch (e) {
        if (kDebugMode) {
          print('Supabase addHostResponse error: $e');
        }
      }
    }

    return true;
  }

  // ==========================================
  // HELPER SENTIMENT & SEED DATA METHODS
  // ==========================================

  Map<String, dynamic> _analyzeFeedbackText(String text, double rating, String category) {
    final lower = text.toLowerCase();
    String sentiment = 'positive';
    double priority = 0.3;
    final List<String> tags = [];

    if (rating <= 2.5 || lower.contains('crash') || lower.contains('broken') || lower.contains('worst') || lower.contains('scam')) {
      sentiment = 'negative';
      priority = 0.9;
      tags.add('Urgent Review');
    } else if (rating <= 3.5 || lower.contains('okay') || lower.contains('average') || lower.contains('delay')) {
      sentiment = 'neutral';
      priority = 0.5;
      tags.add('Moderate Experience');
    } else {
      sentiment = 'positive';
      priority = 0.2;
      tags.add('High Rating');
    }

    if (lower.contains('app') || lower.contains('ui') || lower.contains('bug') || lower.contains('screen')) {
      tags.add('UX / App Functionality');
    }
    if (lower.contains('clean') || lower.contains('wash') || lower.contains('dust')) {
      tags.add('Cleanliness');
    }
    if (lower.contains('smooth') || lower.contains('battery') || lower.contains('speed') || lower.contains('brake')) {
      tags.add('Performance');
    }
    if (lower.contains('host') || lower.contains('keyless') || lower.contains('unlock') || lower.contains('pickup')) {
      tags.add('Handover Process');
    }

    return {
      'sentiment': sentiment,
      'priority': priority,
      'tags': tags,
      'summary': 'Extracted key highlights: ${tags.join(', ')}',
    };
  }
}
