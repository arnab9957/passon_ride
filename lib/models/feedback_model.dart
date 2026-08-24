import 'dart:convert';

/// App & Platform Experience Feedback Model
class AppFeedbackReview {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final String category; // 'app_experience', 'bug_report', 'feature_request', 'platform_trust'
  final double rating;
  final String comment;
  final bool isPublic;
  final List<String> attachmentUrls;
  final Map<String, dynamic> metadata;
  final String aiSentiment; // 'positive', 'neutral', 'negative'
  final double aiPriorityScore;
  final List<String> aiTags;
  final String status; // 'published', 'under_review', 'resolved'
  final DateTime createdAt;

  AppFeedbackReview({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.category,
    required this.rating,
    required this.comment,
    this.isPublic = true,
    this.attachmentUrls = const [],
    this.metadata = const {},
    this.aiSentiment = 'positive',
    this.aiPriorityScore = 0.5,
    this.aiTags = const [],
    this.status = 'published',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  AppFeedbackReview copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatar,
    String? category,
    double? rating,
    String? comment,
    bool? isPublic,
    List<String>? attachmentUrls,
    Map<String, dynamic>? metadata,
    String? aiSentiment,
    double? aiPriorityScore,
    List<String>? aiTags,
    String? status,
    DateTime? createdAt,
  }) {
    return AppFeedbackReview(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      category: category ?? this.category,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      isPublic: isPublic ?? this.isPublic,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      metadata: metadata ?? this.metadata,
      aiSentiment: aiSentiment ?? this.aiSentiment,
      aiPriorityScore: aiPriorityScore ?? this.aiPriorityScore,
      aiTags: aiTags ?? this.aiTags,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    bool isValidUuid(String? str) {
      if (str == null || str.isEmpty) return false;
      return RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(str);
    }

    final map = <String, dynamic>{
      'user_name': userName,
      'user_avatar': userAvatar,
      'category': category,
      'rating': rating,
      'comment': comment,
      'is_public': isPublic,
      'attachment_urls': attachmentUrls,
      'metadata': metadata,
      'ai_sentiment': aiSentiment,
      'ai_priority_score': aiPriorityScore,
      'ai_tags': aiTags,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };

    if (isValidUuid(id)) map['id'] = id;
    if (isValidUuid(userId)) map['user_id'] = userId;

    return map;
  }

  factory AppFeedbackReview.fromMap(Map<String, dynamic> map) {
    List<String> parseStringList(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) return raw.map((e) => e.toString()).toList();
      if (raw is String && raw.trim().isNotEmpty) {
        try {
          final List decoded = jsonDecode(raw);
          return decoded.map((e) => e.toString()).toList();
        } catch (_) {
          return [raw];
        }
      }
      return [];
    }

    return AppFeedbackReview(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? map['userId']?.toString() ?? '',
      userName: map['user_name'] ?? map['userName'] ?? 'Rider',
      userAvatar: map['user_avatar'] ?? map['userAvatar'] ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&q=80',
      category: map['category'] ?? 'app_experience',
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
      comment: map['comment'] ?? '',
      isPublic: map['is_public'] ?? map['isPublic'] ?? true,
      attachmentUrls: parseStringList(map['attachment_urls'] ?? map['attachmentUrls']),
      metadata: map['metadata'] != null ? Map<String, dynamic>.from(map['metadata']) : {},
      aiSentiment: map['ai_sentiment'] ?? map['aiSentiment'] ?? 'positive',
      aiPriorityScore: (map['ai_priority_score'] ?? map['aiPriorityScore'] as num?)?.toDouble() ?? 0.5,
      aiTags: parseStringList(map['ai_tags'] ?? map['aiTags']),
      status: map['status'] ?? 'published',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : map['createdAt'] != null
              ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
              : DateTime.now(),
    );
  }
}

/// Detailed Trip & Aspect Ratings Model for Vehicles / Tours
class TripAspectReview {
  final String id;
  final String? bookingId;
  final String? vehicleId;
  final String? tourId;
  final String riderId;
  final String hostId;
  final String riderName;
  final String riderAvatar;
  final double overallRating;
  final double cleanlinessRating;
  final double performanceRating;
  final double communicationRating;
  final double valueRating;
  final String comment;
  final List<String> selectedTags;
  final List<String> photoUrls;
  final String aiSentiment;
  final String? aiSummary;
  final String? hostResponse;
  final DateTime? hostRespondedAt;
  final DateTime createdAt;

  TripAspectReview({
    required this.id,
    this.bookingId,
    this.vehicleId,
    this.tourId,
    required this.riderId,
    required this.hostId,
    required this.riderName,
    required this.riderAvatar,
    required this.overallRating,
    this.cleanlinessRating = 5.0,
    this.performanceRating = 5.0,
    this.communicationRating = 5.0,
    this.valueRating = 5.0,
    required this.comment,
    this.selectedTags = const [],
    this.photoUrls = const [],
    this.aiSentiment = 'positive',
    this.aiSummary,
    this.hostResponse,
    this.hostRespondedAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    bool isValidUuid(String? str) {
      if (str == null || str.isEmpty) return false;
      return RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(str);
    }

    final map = <String, dynamic>{
      'rider_name': riderName,
      'rider_avatar': riderAvatar,
      'overall_rating': overallRating,
      'cleanliness_rating': cleanlinessRating,
      'performance_rating': performanceRating,
      'communication_rating': communicationRating,
      'value_rating': valueRating,
      'comment': comment,
      'selected_tags': selectedTags,
      'photo_urls': photoUrls,
      'ai_sentiment': aiSentiment,
      'ai_summary': aiSummary,
      'host_response': hostResponse,
      'host_responded_at': hostRespondedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };

    if (isValidUuid(id)) map['id'] = id;
    if (isValidUuid(bookingId)) map['booking_id'] = bookingId;
    if (isValidUuid(vehicleId)) map['vehicle_id'] = vehicleId;
    if (isValidUuid(tourId)) map['tour_id'] = tourId;
    if (isValidUuid(riderId)) map['rider_id'] = riderId;
    if (isValidUuid(hostId)) map['host_id'] = hostId;

    return map;
  }

  factory TripAspectReview.fromMap(Map<String, dynamic> map) {
    List<String> parseList(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) return raw.map((e) => e.toString()).toList();
      if (raw is String && raw.trim().isNotEmpty) {
        try {
          final List decoded = jsonDecode(raw);
          return decoded.map((e) => e.toString()).toList();
        } catch (_) {
          return [raw];
        }
      }
      return [];
    }

    return TripAspectReview(
      id: map['id']?.toString() ?? '',
      bookingId: map['booking_id']?.toString() ?? map['bookingId']?.toString(),
      vehicleId: map['vehicle_id']?.toString() ?? map['vehicleId']?.toString(),
      tourId: map['tour_id']?.toString() ?? map['tourId']?.toString(),
      riderId: map['rider_id']?.toString() ?? map['riderId']?.toString() ?? '',
      hostId: map['host_id']?.toString() ?? map['hostId']?.toString() ?? '',
      riderName: map['rider_name'] ?? map['riderName'] ?? map['user_name'] ?? 'Rider',
      riderAvatar: map['rider_avatar'] ?? map['riderAvatar'] ?? map['user_avatar'] ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&q=80',
      overallRating: (map['overall_rating'] ?? map['overallRating'] ?? map['rating'] as num?)?.toDouble() ?? 5.0,
      cleanlinessRating: (map['cleanliness_rating'] ?? map['cleanlinessRating'] as num?)?.toDouble() ?? 5.0,
      performanceRating: (map['performance_rating'] ?? map['performanceRating'] as num?)?.toDouble() ?? 5.0,
      communicationRating: (map['communication_rating'] ?? map['communicationRating'] as num?)?.toDouble() ?? 5.0,
      valueRating: (map['value_rating'] ?? map['valueRating'] as num?)?.toDouble() ?? 5.0,
      comment: map['comment'] ?? '',
      selectedTags: parseList(map['selected_tags'] ?? map['selectedTags']),
      photoUrls: parseList(map['photo_urls'] ?? map['photoUrls']),
      aiSentiment: map['ai_sentiment'] ?? map['aiSentiment'] ?? 'positive',
      aiSummary: map['ai_summary'] ?? map['aiSummary'],
      hostResponse: map['host_response'] ?? map['hostResponse'],
      hostRespondedAt: map['host_responded_at'] != null ? DateTime.tryParse(map['host_responded_at'].toString()) : null,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : map['createdAt'] != null
              ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
              : DateTime.now(),
    );
  }
}

/// Aggregated Aspect Ratings Summary
class AspectRatingSummary {
  final double averageOverall;
  final double averageCleanliness;
  final double averagePerformance;
  final double averageCommunication;
  final double averageValue;
  final int totalReviews;

  AspectRatingSummary({
    required this.averageOverall,
    required this.averageCleanliness,
    required this.averagePerformance,
    required this.averageCommunication,
    required this.averageValue,
    required this.totalReviews,
  });

  factory AspectRatingSummary.fromReviews(List<TripAspectReview> reviews) {
    if (reviews.isEmpty) {
      return AspectRatingSummary(
        averageOverall: 0.0,
        averageCleanliness: 0.0,
        averagePerformance: 0.0,
        averageCommunication: 0.0,
        averageValue: 0.0,
        totalReviews: 0,
      );
    }

    double overallSum = 0;
    double cleanlinessSum = 0;
    double performanceSum = 0;
    double communicationSum = 0;
    double valueSum = 0;

    for (var r in reviews) {
      overallSum += r.overallRating;
      cleanlinessSum += r.cleanlinessRating;
      performanceSum += r.performanceRating;
      communicationSum += r.communicationRating;
      valueSum += r.valueRating;
    }

    final count = reviews.length;
    return AspectRatingSummary(
      averageOverall: overallSum / count,
      averageCleanliness: cleanlinessSum / count,
      averagePerformance: performanceSum / count,
      averageCommunication: communicationSum / count,
      averageValue: valueSum / count,
      totalReviews: count,
    );
  }
}
