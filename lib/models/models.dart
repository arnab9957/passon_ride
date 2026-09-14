import 'dart:convert';
import 'package:flutter/foundation.dart';
export 'location_model.dart';

double _parseDouble(dynamic value, double defaultValue) {
  if (value == null) return defaultValue;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? defaultValue;
  return defaultValue;
}

int _parseInt(dynamic value, int defaultValue) {
  if (value == null) return defaultValue;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? defaultValue;
  return defaultValue;
}

bool _parseBool(dynamic value, bool defaultValue) {
  if (value == null) return defaultValue;
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final lower = value.toLowerCase().trim();
    if (lower == 'true' || lower == '1' || lower == 'yes') return true;
    if (lower == 'false' || lower == '0' || lower == 'no') return false;
  }
  return defaultValue;
}

enum VehicleType { bike, car, scooter, electric }

class Vehicle {
  final String id;
  final String title;
  final VehicleType type;
  final String category;
  final double pricePerDay;
  final double rating;
  final int reviewCount;
  final String imageUrl;
  final String location;
  final double latitude;
  final double longitude;
  final String status; // 'Available', 'Booked', 'Maintenance'
  final String hostName;
  final String hostAvatar;
  final double hostTrustScore;
  final String hostId;
  final String ownerAccountId;
  String get hostAccountId => ownerAccountId.isNotEmpty ? ownerAccountId : hostId;
  final bool isInstantBookable;
  final bool isFavorite;
  final String fuelType;
  final String transmission;
  final int seats;
  final String description;
  final Map<String, dynamic> iotData;
  final List<String> images;

  Vehicle({
    required this.id,
    required this.title,
    required this.type,
    required this.category,
    required this.pricePerDay,
    required this.rating,
    required this.reviewCount,
    required this.imageUrl,
    required this.location,
    this.latitude = 37.7749,
    this.longitude = -122.4194,
    this.status = 'Available',
    required this.hostName,
    required this.hostAvatar,
    required this.hostTrustScore,
    this.hostId = '',
    String? ownerAccountId,
    this.isInstantBookable = true,
    this.isFavorite = false,
    required this.fuelType,
    required this.transmission,
    required this.seats,
    required this.description,
    required this.iotData,
    this.images = const [],
  }) : ownerAccountId = (ownerAccountId != null && ownerAccountId.isNotEmpty) ? ownerAccountId : hostId;

  Vehicle copyWith({
    String? title,
    VehicleType? type,
    String? category,
    double? pricePerDay,
    double? rating,
    int? reviewCount,
    String? imageUrl,
    String? location,
    double? latitude,
    double? longitude,
    String? status,
    String? hostName,
    String? hostAvatar,
    String? hostId,
    String? ownerAccountId,
    String? fuelType,
    String? transmission,
    int? seats,
    String? description,
    bool? isFavorite,
    Map<String, dynamic>? iotData,
    List<String>? images,
  }) {
    return Vehicle(
      id: id,
      title: title ?? this.title,
      type: type ?? this.type,
      category: category ?? this.category,
      pricePerDay: pricePerDay ?? this.pricePerDay,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      imageUrl: imageUrl ?? this.imageUrl,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      hostName: hostName ?? this.hostName,
      hostAvatar: hostAvatar ?? this.hostAvatar,
      hostTrustScore: hostTrustScore,
      hostId: hostId ?? this.hostId,
      ownerAccountId: ownerAccountId ?? this.ownerAccountId,
      isInstantBookable: isInstantBookable,
      isFavorite: isFavorite ?? this.isFavorite,
      fuelType: fuelType ?? this.fuelType,
      transmission: transmission ?? this.transmission,
      seats: seats ?? this.seats,
      description: description ?? this.description,
      iotData: iotData ?? this.iotData,
      images: images ?? this.images,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type.name,
      'category': category,
      'pricePerDay': pricePerDay,
      'rating': rating,
      'reviewCount': reviewCount,
      'imageUrl': imageUrl,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'hostName': hostName,
      'hostAvatar': hostAvatar,
      'hostTrustScore': hostTrustScore,
      'hostId': hostId,
      'ownerAccountId': ownerAccountId.isNotEmpty ? ownerAccountId : hostId,
      'owner_account_id': ownerAccountId.isNotEmpty ? ownerAccountId : hostId,
      'isInstantBookable': isInstantBookable,
      'isFavorite': isFavorite,
      'fuelType': fuelType,
      'transmission': transmission,
      'seats': seats,
      'description': description,
      'iotData': iotData,
      'images': images,
    };
  }

  factory Vehicle.fromMap(Map<String, dynamic> map) {
    final List<String> parsedImages = [];

    final String rawMain = (map['imageUrl'] ?? map['image_url'] ?? '').toString().trim();
    final String normMain = Tour._normalizeUrl(rawMain);
    if (normMain.isNotEmpty) {
      parsedImages.add(normMain);
    }

    final dynamic rawImages = map['images'];
    if (rawImages != null) {
      if (rawImages is List) {
        for (var item in rawImages) {
          final norm = Tour._normalizeUrl(item.toString());
          if (norm.isNotEmpty && !parsedImages.contains(norm)) {
            parsedImages.add(norm);
          }
        }
      } else if (rawImages is String && rawImages.trim().isNotEmpty) {
        final str = rawImages.trim();
        if (str.startsWith('[') && str.endsWith(']')) {
          try {
            final List decoded = jsonDecode(str);
            for (var item in decoded) {
              final norm = Tour._normalizeUrl(item.toString());
              if (norm.isNotEmpty && !parsedImages.contains(norm)) {
                parsedImages.add(norm);
              }
            }
          } catch (_) {}
        } else {
          for (var item in str.split(',')) {
            final norm = Tour._normalizeUrl(item.toString());
            if (norm.isNotEmpty && !parsedImages.contains(norm)) {
              parsedImages.add(norm);
            }
          }
        }
      }
    }

    if (parsedImages.isEmpty) {
      parsedImages.add('https://images.unsplash.com/photo-1558981403-c5f9899a28bc?w=800&q=80');
    }

    final String finalMainImg = parsedImages.first;

    return Vehicle(
      id: map['id'] ?? '',
      title: map['title'] ?? 'Untitled Vehicle',
      type: VehicleType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => VehicleType.car,
      ),
      category: map['category'] ?? 'General',
      pricePerDay: _parseDouble(map['pricePerDay'] ?? map['price_per_day'], 0.0),
      rating: _parseDouble(map['rating'], 5.0),
      reviewCount: _parseInt(map['reviewCount'] ?? map['review_count'], 0),
      imageUrl: finalMainImg,
      location: map['location'] ?? '',
      latitude: _parseDouble(map['latitude'], 37.7749),
      longitude: _parseDouble(map['longitude'], -122.4194),
      status: map['status'] ?? 'Available',
      hostName: map['hostName'] ?? map['host_name'] ?? 'Host',
      hostAvatar: Tour._normalizeUrl((map['hostAvatar'] ?? map['host_avatar'] ?? '').toString()),
      hostTrustScore: _parseDouble(map['hostTrustScore'] ?? map['host_trust_score'], 95.0),
      hostId: map['hostId'] ?? map['host_id'] ?? '',
      ownerAccountId: map['owner_account_id'] ?? map['ownerAccountId'] ?? map['host_id'] ?? map['hostId'] ?? '',
      isInstantBookable: _parseBool(map['isInstantBookable'] ?? map['is_instant_bookable'], true),
      isFavorite: _parseBool(map['isFavorite'] ?? map['is_favorite'], false),
      fuelType: map['fuelType'] ?? map['fuel_type'] ?? 'Gasoline',
      transmission: map['transmission'] ?? 'Automatic',
      seats: _parseInt(map['seats'], 2),
      description: map['description'] ?? '',
      iotData: map['iotData'] != null
          ? Map<String, dynamic>.from(map['iotData'])
          : (map['iot_data'] != null ? Map<String, dynamic>.from(map['iot_data']) : {}),
      images: parsedImages,
    );
  }
}

class Tour {
  final String id;
  final String title;
  final String location;
  final double price;
  final String duration;
  final double rating;
  final int reviewCount;
  final String _imageUrl;
  final List<String> images;
  String get imageUrl => (images.isNotEmpty && images.first.trim().isNotEmpty)
      ? images.first
      : (_imageUrl.trim().isNotEmpty ? _imageUrl : 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=800&q=80');
  final String guideName;
  final String guideAvatar;
  final String hostId;
  final List<String> waypoints;
  final List<String> includedGear;
  final String description;
  final bool isFavorite;
  final DateTime? expiryDate;

  bool get isExpired => expiryDate != null && DateTime.now().isAfter(expiryDate!);

  String get formattedExpiryDate {
    if (expiryDate == null) return 'No Expiry';
    final d = expiryDate!;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Tour({
    required this.id,
    required this.title,
    required this.location,
    required this.price,
    required this.duration,
    required this.rating,
    required this.reviewCount,
    required this._imageUrl,
    this.images = const [],
    required this.guideName,
    required this.guideAvatar,
    this.hostId = '',
    required this.waypoints,
    required this.includedGear,
    required this.description,
    this.isFavorite = false,
    this.expiryDate,
  });

  Tour copyWith({
    String? title,
    String? location,
    double? price,
    String? duration,
    double? rating,
    int? reviewCount,
    String? imageUrl,
    List<String>? images,
    String? guideName,
    String? guideAvatar,
    String? description,
    bool? isFavorite,
    String? hostId,
    DateTime? expiryDate,
  }) {
    return Tour(
      id: id,
      title: title ?? this.title,
      location: location ?? this.location,
      price: price ?? this.price,
      duration: duration ?? this.duration,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      imageUrl: imageUrl ?? _imageUrl,
      images: images ?? this.images,
      guideName: guideName ?? this.guideName,
      guideAvatar: guideAvatar ?? this.guideAvatar,
      hostId: hostId ?? this.hostId,
      waypoints: waypoints,
      includedGear: includedGear,
      description: description ?? this.description,
      isFavorite: isFavorite ?? this.isFavorite,
      expiryDate: expiryDate ?? this.expiryDate,
    );
  }

  Map<String, dynamic> toMap() {
    final validImages = images.where((img) => img.trim().isNotEmpty).toList();
    final mainImg = imageUrl.trim().isNotEmpty
        ? imageUrl
        : (validImages.isNotEmpty ? validImages.first : 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=800&q=80');

    return {
      'id': id,
      'title': title,
      'location': location,
      'price': price,
      'duration': duration,
      'rating': rating,
      'reviewCount': reviewCount,
      'imageUrl': mainImg,
      'images': validImages.isNotEmpty ? validImages : [mainImg],
      'guideName': guideName,
      'guideAvatar': guideAvatar,
      'hostId': hostId,
      'guideId': hostId,
      'waypoints': waypoints,
      'includedGear': includedGear,
      'description': description,
      'isFavorite': isFavorite,
      'expiryDate': expiryDate?.toIso8601String(),
      'expiry_date': expiryDate?.toIso8601String(),
    };
  }

  static String _normalizeUrl(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return '';
    if (s.startsWith('http://') || s.startsWith('https://') || s.startsWith('data:')) {
      return s;
    }
    final cleanPath = s.startsWith('/') ? s : '/$s';
    return 'https://ik.imagekit.io/hsqoovxu0$cleanPath';
  }

  factory Tour.fromMap(Map<String, dynamic> map) {
    final List<String> parsedImages = [];

    void addCandidate(dynamic raw) {
      if (raw == null) return;
      final str = raw.toString().trim();
      if (str.isEmpty) return;

      if (str.startsWith('[') && str.endsWith(']')) {
        try {
          final List decoded = jsonDecode(str);
          for (var item in decoded) {
            addCandidate(item);
          }
          return;
        } catch (_) {}
      }

      if (str.contains(',') && !str.startsWith('http') && !str.startsWith('data:')) {
        for (var part in str.split(',')) {
          addCandidate(part);
        }
        return;
      }

      final norm = _normalizeUrl(str);
      if (norm.isNotEmpty && !parsedImages.contains(norm)) {
        parsedImages.add(norm);
      }
    }

    // 1. Parse image_url / imageUrl / images
    addCandidate(map['imageUrl']);
    addCandidate(map['image_url']);
    addCandidate(map['images']);

    // 2. Prioritize ImageKit CDN URLs
    final ikImages = parsedImages.where((img) => img.contains('imagekit.io') || !img.contains('unsplash.com')).toList();

    final List<String> finalImagesList = ikImages.isNotEmpty
        ? [...ikImages, ...parsedImages.where((img) => !ikImages.contains(img))]
        : (parsedImages.isNotEmpty ? parsedImages : ['https://ik.imagekit.io/hsqoovxu0/tours/tour_1786900455239_aQc5pXYg77.jpg']);

    final String finalMainImg = finalImagesList.first;

    // Parse expiry date
    DateTime? parsedExpiry;
    final rawExpiry = map['expiryDate'] ?? map['expiry_date'] ?? map['expiresAt'] ?? map['expires_at'];
    if (rawExpiry != null && rawExpiry.toString().trim().isNotEmpty) {
      parsedExpiry = DateTime.tryParse(rawExpiry.toString().trim());
    }
    // Default fallback to 90 days from now if not specified
    parsedExpiry ??= DateTime.now().add(const Duration(days: 90));

    return Tour(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      location: map['location'] ?? '',
      price: _parseDouble(map['price'] ?? map['price_per_rider'], 0.0),
      duration: map['duration'] ?? '',
      rating: _parseDouble(map['rating'], 5.0),
      reviewCount: _parseInt(map['reviewCount'] ?? map['review_count'], 0),
      imageUrl: finalMainImg,
      images: parsedImages,
      guideName: map['guideName'] ?? map['guide_name'] ?? map['hostName'] ?? map['host_name'] ?? '',
      guideAvatar: _normalizeUrl((map['guideAvatar'] ?? map['guide_avatar'] ?? map['hostAvatar'] ?? map['host_avatar'] ?? '').toString()),
      hostId: map['hostId'] ?? map['host_id'] ?? map['guideId'] ?? map['guide_id'] ?? '',
      waypoints: List<String>.from(map['waypoints'] ?? []),
      includedGear: List<String>.from(map['includedGear'] ?? map['included_gear'] ?? []),
      description: map['description'] ?? '',
      isFavorite: _parseBool(map['isFavorite'] ?? map['is_favorite'], false),
      expiryDate: parsedExpiry,
    );
  }
}

class AiGeneration {
  final String id;
  final String userId;
  final String destination;
  final int durationDays;
  final String budget;
  final String terrain;
  final String generatedItineraryJson;
  final DateTime createdAt;

  AiGeneration({
    required this.id,
    required this.userId,
    required this.destination,
    required this.durationDays,
    required this.budget,
    required this.terrain,
    required this.generatedItineraryJson,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'destination': destination,
      'durationDays': durationDays,
      'budget': budget,
      'terrain': terrain,
      'generatedItineraryJson': generatedItineraryJson,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AiGeneration.fromMap(Map<String, dynamic> map) {
    return AiGeneration(
      id: map['id'] ?? '',
      userId: map['userId'] ?? map['user_id'] ?? '',
      destination: map['destination'] ?? '',
      durationDays: _parseInt(map['durationDays'] ?? map['duration_days'], 3),
      budget: map['budget'] ?? 'Standard',
      terrain: map['terrain'] ?? 'Scenic',
      generatedItineraryJson: map['generatedItineraryJson'] ?? map['generated_itinerary_json'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : map['created_at'] != null
              ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
              : DateTime.now(),
    );
  }
}

class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool isUser;
  final bool isModerated;
  final String? originalContent;
  final List<String> flaggedReasons;
  final String status; // 'sending', 'sent', 'delivered', 'read', 'failed'
  final String messageType; // 'text', 'image', 'location', 'document'
  final String? attachmentUrl;
  final double? latitude;
  final double? longitude;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    required this.isUser,
    this.isModerated = false,
    this.originalContent,
    this.flaggedReasons = const [],
    this.status = 'sent',
    this.messageType = 'text',
    this.attachmentUrl,
    this.latitude,
    this.longitude,
    this.isRead = false,
  });

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? text,
    DateTime? timestamp,
    bool? isUser,
    bool? isModerated,
    String? originalContent,
    List<String>? flaggedReasons,
    String? status,
    String? messageType,
    String? attachmentUrl,
    double? latitude,
    double? longitude,
    bool? isRead,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isUser: isUser ?? this.isUser,
      isModerated: isModerated ?? this.isModerated,
      originalContent: originalContent ?? this.originalContent,
      flaggedReasons: flaggedReasons ?? this.flaggedReasons,
      status: status ?? this.status,
      messageType: messageType ?? this.messageType,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toMap(String threadId) {
    return {
      'id': id,
      'conversation_id': threadId,
      'thread_id': threadId,
      'sender_id': senderId,
      'content': text,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'created_at': timestamp.toIso8601String(),
      'is_user': isUser,
      'is_moderated': isModerated,
      'original_content': originalContent,
      'flagged_reasons': flaggedReasons,
      'status': status,
      'message_type': messageType,
      'attachment_url': attachmentUrl,
      'latitude': latitude,
      'longitude': longitude,
      'is_read': isRead || status == 'read',
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map, {String? currentUserId}) {
    final sId = map['senderId'] ?? map['sender_id'] ?? '';
    final bool computedIsUser = currentUserId != null && currentUserId.isNotEmpty
        ? sId == currentUserId
        : (map['isUser'] ?? map['is_user'] ?? true);

    final rawStatus = map['status']?.toString().toLowerCase() ?? 'sent';
    final rawIsRead = map['is_read'] ?? map['isRead'] ?? (rawStatus == 'read');

    return ChatMessage(
      id: map['id']?.toString() ?? '',
      senderId: sId,
      text: map['text'] ?? map['content'] ?? map['message_text'] ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now()
          : map['created_at'] != null
              ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
              : DateTime.now(),
      isUser: computedIsUser,
      isModerated: _parseBool(map['isModerated'] ?? map['is_moderated'], false),
      originalContent: map['originalContent'] ?? map['original_content'],
      flaggedReasons: map['flaggedReasons'] != null
          ? List<String>.from(map['flaggedReasons'])
          : map['flagged_reasons'] != null
              ? List<String>.from(map['flagged_reasons'])
              : [],
      status: rawStatus,
      messageType: map['messageType'] ?? map['message_type'] ?? 'text',
      attachmentUrl: map['attachmentUrl'] ?? map['attachment_url'],
      latitude: map['latitude'] != null ? _parseDouble(map['latitude'], 0.0) : null,
      longitude: map['longitude'] != null ? _parseDouble(map['longitude'], 0.0) : null,
      isRead: rawIsRead == true,
    );
  }
}

class ChatThread {
  final String id;
  final String partnerName;
  final String partnerAvatar;
  final String lastMessage;
  final DateTime lastTime;
  final int unreadCount;
  final String vehicleTitle;
  final List<ChatMessage> messages;
  final String? bookingId;
  final String? vehicleId;
  final String? renterId;
  final String? providerId;
  final bool isPartnerOnline;
  final DateTime? partnerLastSeen;

  ChatThread({
    required this.id,
    required this.partnerName,
    required this.partnerAvatar,
    required this.lastMessage,
    required this.lastTime,
    required this.unreadCount,
    required this.vehicleTitle,
    required this.messages,
    this.bookingId,
    this.vehicleId,
    this.renterId,
    this.providerId,
    this.isPartnerOnline = false,
    this.partnerLastSeen,
  });

  ChatThread copyWith({
    String? id,
    String? partnerName,
    String? partnerAvatar,
    String? lastMessage,
    DateTime? lastTime,
    int? unreadCount,
    String? vehicleTitle,
    List<ChatMessage>? messages,
    String? bookingId,
    String? vehicleId,
    String? renterId,
    String? providerId,
    bool? isPartnerOnline,
    DateTime? partnerLastSeen,
  }) {
    return ChatThread(
      id: id ?? this.id,
      partnerName: partnerName ?? this.partnerName,
      partnerAvatar: partnerAvatar ?? this.partnerAvatar,
      lastMessage: lastMessage ?? this.lastMessage,
      lastTime: lastTime ?? this.lastTime,
      unreadCount: unreadCount ?? this.unreadCount,
      vehicleTitle: vehicleTitle ?? this.vehicleTitle,
      messages: messages ?? this.messages,
      bookingId: bookingId ?? this.bookingId,
      vehicleId: vehicleId ?? this.vehicleId,
      renterId: renterId ?? this.renterId,
      providerId: providerId ?? this.providerId,
      isPartnerOnline: isPartnerOnline ?? this.isPartnerOnline,
      partnerLastSeen: partnerLastSeen ?? this.partnerLastSeen,
    );
  }

  Map<String, dynamic> toMap(String userId) {
    return {
      'id': id,
      'user_id': userId,
      'partner_name': partnerName,
      'partner_avatar': partnerAvatar,
      'last_message': lastMessage,
      'last_time': lastTime.toIso8601String(),
      'last_message_time': lastTime.toIso8601String(),
      'unread_count': unreadCount,
      'vehicle_title': vehicleTitle,
      'title': vehicleTitle,
      'booking_id': bookingId,
      'vehicle_id': vehicleId,
      'renter_id': renterId ?? userId,
      'provider_id': providerId ?? userId,
    };
  }

  factory ChatThread.fromMap(Map<String, dynamic> map, [List<ChatMessage>? msgs, String? currentUserId]) {
    final String rId = map['renter_id']?.toString() ?? '';
    final String pId = map['provider_id']?.toString() ?? '';
    final bool isUserRenter = currentUserId != null && currentUserId == rId;

    final String name = map['partnerName'] ?? map['partner_name'] ?? (isUserRenter ? 'Rental Owner' : 'Customer');
    final String avatar = map['partnerAvatar'] ?? map['partner_avatar'] ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&q=80';

    return ChatThread(
      id: map['id']?.toString() ?? '',
      partnerName: name,
      partnerAvatar: avatar,
      lastMessage: map['lastMessage'] ?? map['last_message'] ?? '',
      lastTime: map['lastTime'] != null
          ? DateTime.tryParse(map['lastTime'].toString()) ?? DateTime.now()
          : map['last_message_time'] != null
              ? DateTime.tryParse(map['last_message_time'].toString()) ?? DateTime.now()
              : map['last_time'] != null
                  ? DateTime.tryParse(map['last_time'].toString()) ?? DateTime.now()
                  : DateTime.now(),
      unreadCount: _parseInt(map['unreadCount'] ?? map['unread_count'] ?? map['renter_unread_count'] ?? map['provider_unread_count'], 0),
      vehicleTitle: map['vehicleTitle'] ?? map['vehicle_title'] ?? map['title'] ?? 'Passon Rental',
      messages: msgs ?? [],
      bookingId: map['booking_id']?.toString() ?? map['bookingId']?.toString(),
      vehicleId: map['vehicle_id']?.toString() ?? map['vehicleId']?.toString(),
      renterId: rId,
      providerId: pId,
    );
  }
}

/// Polymorphic Identity Models: Single User Account with optional Renter & Provider Profiles
class RenterProfile {
  final String accountId;
  final String licenseNumber;
  final String licenseStatus; // 'Unverified', 'Pending', 'Verified'
  final String preferredPaymentMethod;
  final int totalTripsCompleted;

  RenterProfile({
    required this.accountId,
    this.licenseNumber = '',
    this.licenseStatus = 'Verified',
    this.preferredPaymentMethod = 'UPI / Razorpay',
    this.totalTripsCompleted = 12,
  });

  factory RenterProfile.fromMap(Map<String, dynamic> map) {
    return RenterProfile(
      accountId: map['accountId'] ?? map['account_id'] ?? '',
      licenseNumber: map['licenseNumber'] ?? map['license_number'] ?? '',
      licenseStatus: map['licenseStatus'] ?? map['license_status'] ?? 'Verified',
      preferredPaymentMethod: map['preferredPaymentMethod'] ?? map['preferred_payment_method'] ?? 'UPI / Razorpay',
      totalTripsCompleted: _parseInt(map['totalTripsCompleted'] ?? map['total_trips_completed'], 12),
    );
  }
}

class ProviderProfile {
  final String accountId;
  final String kycStatus; // 'Pending', 'In_Review', 'Verified'
  final String bankAccountLast4;
  final String payoutBankName;
  final bool instantBookingEnabled;
  final int totalRentalsHosted;

  ProviderProfile({
    required this.accountId,
    this.kycStatus = 'Verified',
    this.bankAccountLast4 = '4892',
    this.payoutBankName = 'HDFC Bank',
    this.instantBookingEnabled = true,
    this.totalRentalsHosted = 28,
  });

  factory ProviderProfile.fromMap(Map<String, dynamic> map) {
    return ProviderProfile(
      accountId: map['accountId'] ?? map['account_id'] ?? '',
      kycStatus: map['kycStatus'] ?? map['kyc_status'] ?? 'Verified',
      bankAccountLast4: map['bankAccountLast4'] ?? map['bank_account_last4'] ?? '4892',
      payoutBankName: map['payoutBankName'] ?? map['payout_bank_name'] ?? 'HDFC Bank',
      instantBookingEnabled: _parseBool(map['instantBookingEnabled'] ?? map['instant_booking_enabled'], true),
      totalRentalsHosted: _parseInt(map['totalRentalsHosted'] ?? map['total_rentals_hosted'], 28),
    );
  }
}

class UserAccount {
  final String id;
  final String email;
  final String phoneNumber;
  final String fullName;
  final String avatarUrl;
  final double trustScore;
  final bool isPhoneVerified;
  final bool isWhatsappEnabled;
  final RenterProfile? renterProfile;
  final ProviderProfile? providerProfile;

  UserAccount({
    required this.id,
    required this.email,
    required this.phoneNumber,
    required this.fullName,
    this.avatarUrl = '',
    this.trustScore = 96.5,
    this.isPhoneVerified = true,
    this.isWhatsappEnabled = true,
    this.renterProfile,
    this.providerProfile,
  });

  bool get isHost => providerProfile != null;
  bool get isRenter => renterProfile != null;

  factory UserAccount.fromMap(Map<String, dynamic> map) {
    return UserAccount(
      id: map['id'] ?? map['uid'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? map['phone_number'] ?? '',
      fullName: map['fullName'] ?? map['full_name'] ?? map['displayName'] ?? map['display_name'] ?? 'Passon User',
      avatarUrl: map['avatarUrl'] ?? map['avatar_url'] ?? map['photoUrl'] ?? map['photo_url'] ?? '',
      trustScore: _parseDouble(map['trustScore'] ?? map['trust_score'], 96.5),
      isPhoneVerified: _parseBool(map['isPhoneVerified'] ?? map['is_phone_verified'], true),
      isWhatsappEnabled: _parseBool(map['isWhatsappEnabled'] ?? map['is_whatsapp_enabled'], true),
      renterProfile: map['renter_profile'] != null ? RenterProfile.fromMap(Map<String, dynamic>.from(map['renter_profile'])) : null,
      providerProfile: map['provider_profile'] != null ? ProviderProfile.fromMap(Map<String, dynamic>.from(map['provider_profile'])) : null,
    );
  }
}

class HostEarnings {
  final String hostId;
  final double totalEarnings;
  final double monthlyEarnings;
  final int completedTrips;
  final List<String> payoutLogs;

  HostEarnings({
    required this.hostId,
    required this.totalEarnings,
    required this.monthlyEarnings,
    required this.completedTrips,
    required this.payoutLogs,
  });

  Map<String, dynamic> toMap() {
    return {
      'hostId': hostId,
      'host_id': hostId,
      'totalEarnings': totalEarnings,
      'total_earnings': totalEarnings,
      'monthlyEarnings': monthlyEarnings,
      'monthly_earnings': monthlyEarnings,
      'completedTrips': completedTrips,
      'completed_trips': completedTrips,
      'payoutLogs': payoutLogs,
      'payout_logs': payoutLogs,
    };
  }

  factory HostEarnings.fromMap(Map<String, dynamic> map) {
    return HostEarnings(
      hostId: map['hostId'] ?? map['host_id'] ?? '',
      totalEarnings: _parseDouble(map['totalEarnings'] ?? map['total_earnings'], 0.0),
      monthlyEarnings: _parseDouble(map['monthlyEarnings'] ?? map['monthly_earnings'], 0.0),
      completedTrips: _parseInt(map['completedTrips'] ?? map['completed_trips'], 0),
      payoutLogs: map['payoutLogs'] != null
          ? List<String>.from(map['payoutLogs'])
          : map['payout_logs'] != null
              ? List<String>.from(map['payout_logs'])
              : [],
    );
  }
}

class ComplianceDocument {
  final String id;
  final String userId;
  final String title;
  final String status; // 'Verified', 'Pending', 'Action Required'
  final DateTime expiryDate;
  final String type;
  final String documentUrl;
  final String documentNumber;
  final String holderName;
  final String licenseType;
  final double fileSizeKb;
  final String fileName;
  final String fileExtension;
  final double confidenceScore;
  final String issuingAuthority;
  final String bloodGroup;
  final String address;
  final String dob;
  final bool isExpiryValid;

  ComplianceDocument({
    required this.id,
    this.userId = '',
    required this.title,
    required this.status,
    required this.expiryDate,
    required this.type,
    this.documentUrl = '',
    this.documentNumber = '',
    this.holderName = '',
    this.licenseType = 'LMV & MCWG',
    this.fileSizeKb = 250.0,
    this.fileName = '',
    this.fileExtension = 'PDF',
    this.confidenceScore = 98.5,
    this.issuingAuthority = 'Govt Transport Authority (RTO / UIDAI)',
    this.bloodGroup = 'O+',
    this.address = 'H.No 142/B, Indiranagar 100ft Road, Bangalore, KA',
    this.dob = '1996-05-14',
    this.isExpiryValid = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'user_id': userId,
      'title': title,
      'status': status,
      'expiryDate': expiryDate.toIso8601String(),
      'expiry_date': expiryDate.toIso8601String(),
      'type': type,
      'documentUrl': documentUrl,
      'document_url': documentUrl,
      'documentNumber': documentNumber,
      'document_number': documentNumber,
      'holderName': holderName,
      'holder_name': holderName,
      'licenseType': licenseType,
      'license_type': licenseType,
      'fileSizeKb': fileSizeKb,
      'file_size_kb': fileSizeKb,
      'fileName': fileName,
      'file_name': fileName,
      'fileExtension': fileExtension,
      'file_extension': fileExtension,
      'confidenceScore': confidenceScore,
      'confidence_score': confidenceScore,
      'issuingAuthority': issuingAuthority,
      'issuing_authority': issuingAuthority,
      'bloodGroup': bloodGroup,
      'blood_group': bloodGroup,
      'address': address,
      'dob': dob,
      'isExpiryValid': isExpiryValid,
      'is_expiry_valid': isExpiryValid,
    };
  }

  factory ComplianceDocument.fromMap(Map<String, dynamic> map) {
    final exp = map['expiryDate'] != null
        ? DateTime.tryParse(map['expiryDate'].toString()) ?? DateTime.now().add(const Duration(days: 365))
        : map['expiry_date'] != null
            ? DateTime.tryParse(map['expiry_date'].toString()) ?? DateTime.now().add(const Duration(days: 365))
            : DateTime.now().add(const Duration(days: 365));

    final String url = map['documentUrl']?.toString() ??
        map['document_url']?.toString() ??
        map['url']?.toString() ??
        map['imagekit_url']?.toString() ??
        map['file_url']?.toString() ??
        '';

    return ComplianceDocument(
      id: map['id']?.toString() ?? '',
      userId: map['userId']?.toString() ?? map['user_id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Document',
      status: map['status']?.toString() ?? 'Verified',
      expiryDate: exp,
      type: map['type']?.toString() ?? 'ID',
      documentUrl: url,
      documentNumber: map['documentNumber']?.toString() ?? map['document_number']?.toString() ?? '',
      holderName: map['holderName']?.toString() ?? map['holder_name']?.toString() ?? '',
      licenseType: map['licenseType']?.toString() ?? map['license_type']?.toString() ?? 'LMV & MCWG',
      fileSizeKb: _parseDouble(map['fileSizeKb'] ?? map['file_size_kb'], 250.0),
      fileName: map['fileName']?.toString() ?? map['file_name']?.toString() ?? '',
      fileExtension: map['fileExtension']?.toString() ?? map['file_extension']?.toString() ?? 'PDF',
      confidenceScore: _parseDouble(map['confidenceScore'] ?? map['confidence_score'], 98.5),
      issuingAuthority: map['issuingAuthority']?.toString() ?? map['issuing_authority']?.toString() ?? 'Govt Transport Authority (RTO / UIDAI)',
      bloodGroup: map['bloodGroup']?.toString() ?? map['blood_group']?.toString() ?? 'O+',
      address: map['address']?.toString() ?? '',
      dob: map['dob']?.toString() ?? '',
      isExpiryValid: _parseBool(map['isExpiryValid'] ?? map['is_expiry_valid'], exp.isAfter(DateTime.now())),
    );
  }
}

class TrustScore {
  final String userId;
  final double trustScore;
  final List<String> trustBadges;
  final double telematicsScore;
  final double cancellationRate;

  TrustScore({
    required this.userId,
    required this.trustScore,
    required this.trustBadges,
    required this.telematicsScore,
    required this.cancellationRate,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'user_id': userId,
      'trustScore': trustScore,
      'trust_score': trustScore,
      'trustBadges': trustBadges,
      'trust_badges': trustBadges,
      'telematicsScore': telematicsScore,
      'telematics_score': telematicsScore,
      'cancellationRate': cancellationRate,
      'cancellation_rate': cancellationRate,
    };
  }

  factory TrustScore.fromMap(Map<String, dynamic> map) {
    return TrustScore(
      userId: map['userId'] ?? map['user_id'] ?? '',
      trustScore: _parseDouble(map['trustScore'] ?? map['trust_score'], 95.0),
      trustBadges: map['trustBadges'] != null
          ? List<String>.from(map['trustBadges'])
          : map['trust_badges'] != null
              ? List<String>.from(map['trust_badges'])
              : ['Identity Verified', 'Clean Driving Record', 'High Rating Host'],
      telematicsScore: _parseDouble(map['telematicsScore'] ?? map['telematics_score'], 98.0),
      cancellationRate: _parseDouble(map['cancellationRate'] ?? map['cancellation_rate'], 0.0),
    );
  }
}

class Booking {
  final String id;
  final String vehicleId;
  final String vehicleTitle;
  final String vehicleImageUrl;
  final String hostName;
  final String userId;
  String get riderId => userId;
  final String hostId;
  final String accountId;
  String get effectiveAccountId => accountId.isNotEmpty ? accountId : userId;
  final String accountName;
  final String accountType; // 'mother' or 'child'
  bool get isChildBooking => accountType.toLowerCase() == 'child';
  final DateTime startDate;
  final DateTime endDate;
  final double totalPrice;
  final String status; // 'Confirmed' (WAITING_FOR_PICKUP), 'Active' (ACTIVE_RENTAL), 'Completed' (BIKE_RETURNED), 'Cancelled'
  final String unlockPasscode;
  final String paymentIntentId;
  final DateTime createdAt;

  // Live GPS Telemetry & Rental Tracking
  final double? riderLatitude;
  final double? riderLongitude;
  final double riderSpeed; // km/h
  final double riderHeading; // degrees 0-360
  final DateTime? lastGpsUpdate;
  final DateTime? rentalStartedAt;
  final DateTime? rentalEndedAt;

  // Child Hosting & Customer Identity for Mother Oversight
  final bool isChildHosting;
  final String childId;
  final String childName;
  final String customerId;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String customerPhotoUrl;
  final double customerTrustScore;

  bool get hasCustomerDetails =>
      customerName.isNotEmpty ||
      customerEmail.isNotEmpty ||
      customerPhone.isNotEmpty;

  Booking({
    required this.id,
    required this.vehicleId,
    required this.vehicleTitle,
    required this.vehicleImageUrl,
    required this.hostName,
    this.userId = '',
    this.hostId = '',
    String? accountId,
    this.accountName = '',
    this.accountType = '',
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    required this.status,
    required this.unlockPasscode,
    this.paymentIntentId = '',
    required this.createdAt,
    this.riderLatitude,
    this.riderLongitude,
    this.riderSpeed = 0.0,
    this.riderHeading = 0.0,
    this.lastGpsUpdate,
    this.rentalStartedAt,
    this.rentalEndedAt,
    this.isChildHosting = false,
    this.childId = '',
    this.childName = '',
    this.customerId = '',
    this.customerName = '',
    this.customerEmail = '',
    this.customerPhone = '',
    this.customerPhotoUrl = '',
    this.customerTrustScore = 0.0,
  }) : accountId = (accountId != null && accountId.isNotEmpty)
            ? accountId
            : (userId.isNotEmpty ? userId : '');

  Booking copyWith({
    String? status,
    String? unlockPasscode,
    String? paymentIntentId,
    String? accountId,
    String? accountName,
    String? accountType,
    double? riderLatitude,
    double? riderLongitude,
    double? riderSpeed,
    double? riderHeading,
    DateTime? lastGpsUpdate,
    DateTime? rentalStartedAt,
    DateTime? rentalEndedAt,
    bool? isChildHosting,
    String? childId,
    String? childName,
    String? customerId,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    String? customerPhotoUrl,
    double? customerTrustScore,
  }) {
    return Booking(
      id: id,
      vehicleId: vehicleId,
      vehicleTitle: vehicleTitle,
      vehicleImageUrl: vehicleImageUrl,
      hostName: hostName,
      userId: userId,
      hostId: hostId,
      accountId: accountId ?? this.accountId,
      accountName: accountName ?? this.accountName,
      accountType: accountType ?? this.accountType,
      startDate: startDate,
      endDate: endDate,
      totalPrice: totalPrice,
      status: status ?? this.status,
      unlockPasscode: unlockPasscode ?? this.unlockPasscode,
      paymentIntentId: paymentIntentId ?? this.paymentIntentId,
      createdAt: createdAt,
      riderLatitude: riderLatitude ?? this.riderLatitude,
      riderLongitude: riderLongitude ?? this.riderLongitude,
      riderSpeed: riderSpeed ?? this.riderSpeed,
      riderHeading: riderHeading ?? this.riderHeading,
      lastGpsUpdate: lastGpsUpdate ?? this.lastGpsUpdate,
      rentalStartedAt: rentalStartedAt ?? this.rentalStartedAt,
      rentalEndedAt: rentalEndedAt ?? this.rentalEndedAt,
      isChildHosting: isChildHosting ?? this.isChildHosting,
      childId: childId ?? this.childId,
      childName: childName ?? this.childName,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      customerPhone: customerPhone ?? this.customerPhone,
      customerPhotoUrl: customerPhotoUrl ?? this.customerPhotoUrl,
      customerTrustScore: customerTrustScore ?? this.customerTrustScore,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'vehicleTitle': vehicleTitle,
      'vehicleImageUrl': vehicleImageUrl,
      'hostName': hostName,
      'userId': userId,
      'rider_id': userId,
      'riderId': userId,
      'hostId': hostId,
      'accountId': effectiveAccountId,
      'account_id': effectiveAccountId,
      'accountName': accountName,
      'account_name': accountName,
      'accountType': accountType,
      'account_type': accountType,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'totalPrice': totalPrice,
      'status': status,
      'unlockPasscode': unlockPasscode,
      'paymentIntentId': paymentIntentId,
      'createdAt': createdAt.toIso8601String(),
      'riderLatitude': riderLatitude,
      'riderLongitude': riderLongitude,
      'riderSpeed': riderSpeed,
      'riderHeading': riderHeading,
      'lastGpsUpdate': lastGpsUpdate?.toIso8601String(),
      'rentalStartedAt': rentalStartedAt?.toIso8601String(),
      'rentalEndedAt': rentalEndedAt?.toIso8601String(),
      'is_child_hosting': isChildHosting,
      'isChildHosting': isChildHosting,
      'child_id': childId,
      'childId': childId,
      'child_name': childName,
      'childName': childName,
      'customer_id': customerId,
      'customerId': customerId,
      'customer_name': customerName,
      'customerName': customerName,
      'customer_email': customerEmail,
      'customerEmail': customerEmail,
      'customer_phone': customerPhone,
      'customerPhone': customerPhone,
      'customer_photo': customerPhotoUrl,
      'customerPhotoUrl': customerPhotoUrl,
      'customer_trust_score': customerTrustScore,
      'customerTrustScore': customerTrustScore,
    };
  }

  factory Booking.fromMap(Map<String, dynamic> map) {
    final rawUserId = map['userId'] ?? map['user_id'] ?? map['riderId'] ?? map['rider_id'] ?? '';
    final rawAccountId = map['accountId'] ?? map['account_id'] ?? rawUserId;
    return Booking(
      id: map['id'] ?? '',
      vehicleId: map['vehicleId'] ?? map['vehicle_id'] ?? '',
      vehicleTitle: map['vehicleTitle'] ?? map['vehicle_title'] ?? '',
      vehicleImageUrl: map['vehicleImageUrl'] ?? map['vehicle_image_url'] ?? '',
      hostName: map['hostName'] ?? map['host_name'] ?? '',
      userId: rawUserId,
      hostId: map['hostId'] ?? map['host_id'] ?? '',
      accountId: rawAccountId,
      accountName: map['accountName'] ?? map['account_name'] ?? '',
      accountType: map['accountType'] ?? map['account_type'] ?? '',
      startDate: map['startDate'] != null
          ? DateTime.tryParse(map['startDate'].toString()) ?? DateTime.now()
          : map['start_date'] != null
              ? DateTime.tryParse(map['start_date'].toString()) ?? DateTime.now()
              : DateTime.now(),
      endDate: map['endDate'] != null
          ? DateTime.tryParse(map['endDate'].toString()) ?? DateTime.now()
          : map['end_date'] != null
              ? DateTime.tryParse(map['end_date'].toString()) ?? DateTime.now()
              : DateTime.now(),
      totalPrice: _parseDouble(map['totalPrice'] ?? map['total_price'], 0.0),
      status: map['status'] ?? 'Confirmed',
      unlockPasscode: map['unlockPasscode'] ?? map['unlock_passcode'] ?? '',
      paymentIntentId: map['paymentIntentId'] ?? map['payment_intent_id'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : map['created_at'] != null
              ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
              : DateTime.now(),
      riderLatitude: map['riderLatitude'] != null || map['rider_latitude'] != null ? _parseDouble(map['riderLatitude'] ?? map['rider_latitude'], 0.0) : null,
      riderLongitude: map['riderLongitude'] != null || map['rider_longitude'] != null ? _parseDouble(map['riderLongitude'] ?? map['rider_longitude'], 0.0) : null,
      riderSpeed: _parseDouble(map['riderSpeed'] ?? map['rider_speed'], 0.0),
      riderHeading: _parseDouble(map['riderHeading'] ?? map['rider_heading'], 0.0),
      lastGpsUpdate: map['lastGpsUpdate'] != null
          ? DateTime.tryParse(map['lastGpsUpdate'].toString())
          : map['last_gps_update'] != null
              ? DateTime.tryParse(map['last_gps_update'].toString())
              : null,
      rentalStartedAt: map['rentalStartedAt'] != null
          ? DateTime.tryParse(map['rentalStartedAt'].toString())
          : map['rental_started_at'] != null
              ? DateTime.tryParse(map['rental_started_at'].toString())
              : null,
      rentalEndedAt: map['rentalEndedAt'] != null
          ? DateTime.tryParse(map['rentalEndedAt'].toString())
          : map['rental_ended_at'] != null
              ? DateTime.tryParse(map['rental_ended_at'].toString())
              : null,
      isChildHosting: _parseBool(map['is_child_hosting'] ?? map['isChildHosting'], false),
      childId: map['child_id'] ?? map['childId'] ?? '',
      childName: map['child_name'] ?? map['childName'] ?? '',
      customerId: map['customer_id'] ?? map['customerId'] ?? map['rider_id'] ?? map['riderId'] ?? '',
      customerName: map['customer_name'] ?? map['customerName'] ?? map['rider_name'] ?? map['riderName'] ?? '',
      customerEmail: map['customer_email'] ?? map['customerEmail'] ?? map['rider_email'] ?? map['riderEmail'] ?? '',
      customerPhone: map['customer_phone'] ?? map['customerPhone'] ?? map['rider_phone'] ?? map['riderPhone'] ?? '',
      customerPhotoUrl: map['customer_photo'] ?? map['customer_photo_url'] ?? map['customerPhotoUrl'] ?? map['rider_photo'] ?? '',
      customerTrustScore: _parseDouble(map['customer_trust_score'] ?? map['customerTrustScore'] ?? map['trust_score'], 0.0),
    );
  }
}

class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final String photoUrl;
  final String phoneNumber;
  final String role; // 'Rider', 'Host', 'Admin'
  final double trustScore;
  final String bio;
  final bool isBanned;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get avatarUrl => photoUrl;

  UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl = '',
    this.phoneNumber = '',
    this.role = 'Rider',
    this.trustScore = 95.0,
    this.bio = '',
    this.isBanned = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'id': uid,
      'email': email,
      'displayName': displayName,
      'display_name': displayName,
      'photoUrl': photoUrl,
      'photo_url': photoUrl,
      'phoneNumber': phoneNumber,
      'phone_number': phoneNumber,
      'role': role,
      'is_banned': isBanned,
      'trustScore': trustScore,
      'trust_score': trustScore,
      'bio': bio,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map, [String? id]) {
    return UserProfile(
      uid: (id != null && id.isNotEmpty) ? id : (map['uid'] ?? map['id'] ?? ''),
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? map['display_name'] ?? '',
      photoUrl: (map['photoUrl'] != null && map['photoUrl'].toString().trim().isNotEmpty)
          ? map['photoUrl'].toString().trim()
          : ((map['photo_url'] != null && map['photo_url'].toString().trim().isNotEmpty)
              ? map['photo_url'].toString().trim()
              : ''),
      phoneNumber: map['phoneNumber'] ?? map['phone_number'] ?? '',
      role: map['role'] ?? 'Rider',
      isBanned: map['is_banned'] == true || map['isBanned'] == true,
      trustScore: _parseDouble(map['trust_score'] ?? map['trustScore'], 95.0),
      bio: map['bio'] ?? '',
      createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now() : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }

  UserProfile copyWith({
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    String? role,
    bool? isBanned,
    double? trustScore,
    String? bio,
  }) {
    return UserProfile(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      isBanned: isBanned ?? this.isBanned,
      trustScore: trustScore ?? this.trustScore,
      bio: bio ?? this.bio,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

class MotherProfile {
  final String motherId;
  final String customerId;
  final String name;
  final String email;
  final String phone;
  final String profilePhoto;
  final String status; // 'active', 'suspended', 'deactivated'
  final DateTime createdAt;
  final DateTime updatedAt;

  MotherProfile({
    required this.motherId,
    required this.customerId,
    required this.name,
    required this.email,
    this.phone = '',
    this.profilePhoto = '',
    this.status = 'active',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'mother_id': motherId,
      'motherId': motherId,
      'customer_id': customerId,
      'customerId': customerId,
      'name': name,
      'email': email,
      'phone': phone,
      'profile_photo': profilePhoto,
      'profilePhoto': profilePhoto,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory MotherProfile.fromMap(Map<String, dynamic> map, [String? id]) {
    return MotherProfile(
      motherId: (id != null && id.isNotEmpty)
          ? id
          : (map['mother_id'] ?? map['motherId'] ?? map['id'] ?? ''),
      customerId: (map['customer_id'] ?? map['customerId'] ?? map['user_id'] ?? '').toString(),
      name: (map['name'] ?? map['displayName'] ?? map['display_name'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      phone: (map['phone'] ?? map['phone_number'] ?? map['phoneNumber'] ?? '').toString(),
      profilePhoto: (map['profile_photo'] ?? map['profilePhoto'] ?? map['photo_url'] ?? map['photoUrl'] ?? '').toString(),
      status: (map['status'] ?? 'active').toString(),
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }

  MotherProfile copyWith({
    String? customerId,
    String? name,
    String? email,
    String? phone,
    String? profilePhoto,
    String? status,
  }) {
    return MotherProfile(
      motherId: motherId,
      customerId: customerId ?? this.customerId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

class ChildProfile {
  final String childId;
  final String motherId;
  final String name;
  final String email;
  final String phone;
  final String profilePhoto;
  final String status; // 'active', 'suspended', 'deactivated'
  final DateTime createdAt;
  final DateTime updatedAt;

  ChildProfile({
    required this.childId,
    required this.motherId,
    required this.name,
    required this.email,
    this.phone = '',
    this.profilePhoto = '',
    this.status = 'active',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'child_id': childId,
      'childId': childId,
      'mother_id': motherId,
      'motherId': motherId,
      'name': name,
      'email': email,
      'phone': phone,
      'profile_photo': profilePhoto,
      'profilePhoto': profilePhoto,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ChildProfile.fromMap(Map<String, dynamic> map, [String? id]) {
    return ChildProfile(
      childId: (id != null && id.isNotEmpty)
          ? id
          : (map['child_id'] ?? map['childId'] ?? map['id'] ?? ''),
      motherId: (map['mother_id'] ?? map['motherId'] ?? '').toString(),
      name: (map['name'] ?? map['displayName'] ?? map['display_name'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      phone: (map['phone'] ?? map['phone_number'] ?? map['phoneNumber'] ?? '').toString(),
      profilePhoto: (map['profile_photo'] ?? map['profilePhoto'] ?? map['photo_url'] ?? map['photoUrl'] ?? '').toString(),
      status: (map['status'] ?? 'active').toString(),
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }

  ChildProfile copyWith({
    String? motherId,
    String? name,
    String? email,
    String? phone,
    String? profilePhoto,
    String? status,
  }) {
    return ChildProfile(
      childId: childId,
      motherId: motherId ?? this.motherId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

class SavedAccountSummary {
  final String accountId;
  final String accountType; // 'mother' or 'child'
  final String displayName;
  final String email;
  final String profilePhotoUrl;
  final String motherId;
  final DateTime lastActiveAt;

  SavedAccountSummary({
    required this.accountId,
    required this.accountType,
    required this.displayName,
    required this.email,
    this.profilePhotoUrl = '',
    this.motherId = '',
    DateTime? lastActiveAt,
  }) : lastActiveAt = lastActiveAt ?? DateTime.now();

  bool get isMother => accountType == 'mother';
  bool get isChild => accountType == 'child';

  Map<String, dynamic> toMap() {
    return {
      'account_id': accountId,
      'accountId': accountId,
      'account_type': accountType,
      'accountType': accountType,
      'display_name': displayName,
      'displayName': displayName,
      'email': email,
      'profile_photo_url': profilePhotoUrl,
      'profilePhotoUrl': profilePhotoUrl,
      'mother_id': motherId,
      'motherId': motherId,
      'last_active_at': lastActiveAt.toIso8601String(),
      'lastActiveAt': lastActiveAt.toIso8601String(),
    };
  }

  factory SavedAccountSummary.fromMap(Map<String, dynamic> map) {
    return SavedAccountSummary(
      accountId: (map['account_id'] ?? map['accountId'] ?? map['id'] ?? '').toString(),
      accountType: (map['account_type'] ?? map['accountType'] ?? 'child').toString(),
      displayName: (map['display_name'] ?? map['displayName'] ?? map['name'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      profilePhotoUrl: (map['profile_photo_url'] ?? map['profilePhotoUrl'] ?? map['photo_url'] ?? map['photoUrl'] ?? '').toString(),
      motherId: (map['mother_id'] ?? map['motherId'] ?? '').toString(),
      lastActiveAt: map['last_active_at'] != null
          ? DateTime.tryParse(map['last_active_at'].toString()) ?? DateTime.now()
          : (map['lastActiveAt'] != null ? DateTime.tryParse(map['lastActiveAt'].toString()) ?? DateTime.now() : DateTime.now()),
    );
  }
}

class TelemetryLog {
  final String id;
  final String vehicleId;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final double speed;
  final int batterySoc;
  final int fuelPercent;
  final double tpmsFrontPsi;
  final double tpmsRearPsi;
  final List<String> obdDtcCodes;
  final bool engineOn;
  final bool locked;

  TelemetryLog({
    required this.id,
    required this.vehicleId,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.batterySoc,
    required this.fuelPercent,
    required this.tpmsFrontPsi,
    required this.tpmsRearPsi,
    required this.obdDtcCodes,
    required this.engineOn,
    required this.locked,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'timestamp': timestamp.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'speed': speed,
      'batterySoc': batterySoc,
      'fuelPercent': fuelPercent,
      'tpmsFrontPsi': tpmsFrontPsi,
      'tpmsRearPsi': tpmsRearPsi,
      'obdDtcCodes': obdDtcCodes,
      'engineOn': engineOn,
      'locked': locked,
    };
  }

  factory TelemetryLog.fromMap(Map<String, dynamic> map) {
    return TelemetryLog(
      id: map['id'] ?? '',
      vehicleId: map['vehicleId'] ?? '',
      timestamp: map['timestamp'] != null ? DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now() : DateTime.now(),
      latitude: _parseDouble(map['latitude'], 37.7749),
      longitude: _parseDouble(map['longitude'], -122.4194),
      speed: _parseDouble(map['speed'], 0.0),
      batterySoc: _parseInt(map['batterySoc'] ?? map['batteryLevel'], 90),
      fuelPercent: _parseInt(map['fuelPercent'], 85),
      tpmsFrontPsi: _parseDouble(map['tpmsFrontPsi'] ?? map['tirePressureFront'], 32.0),
      tpmsRearPsi: _parseDouble(map['tpmsRearPsi'] ?? map['tirePressureRear'], 35.0),
      obdDtcCodes: map['obdDtcCodes'] != null ? List<String>.from(map['obdDtcCodes']) : [],
      engineOn: _parseBool(map['engineOn'], false),
      locked: _parseBool(map['locked'], true),
    );
  }
}

class Review {
  final String id;
  final String vehicleId;
  final String userId;
  final String userName;
  final String userAvatar;
  final double rating;
  final String comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.vehicleId,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'vehicle_id': vehicleId,
      'userId': userId,
      'user_id': userId,
      'userName': userName,
      'user_name': userName,
      'userAvatar': userAvatar,
      'user_avatar': userAvatar,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      id: map['id'] ?? map['review_id'] ?? '',
      vehicleId: map['vehicleId'] ?? map['vehicle_id'] ?? '',
      userId: map['userId'] ?? map['user_id'] ?? '',
      userName: map['userName'] ?? map['user_name'] ?? map['user_display_name'] ?? 'Rider',
      userAvatar: map['userAvatar'] ?? map['user_avatar'] ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&q=80',
      rating: _parseDouble(map['rating'], 5.0),
      comment: map['comment'] ?? map['feedback'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : map['created_at'] != null
              ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
              : DateTime.now(),
    );
  }
}

enum NotificationType {
  bookingConfirmation,
  bookingReceivedHost,
  childBookingAlert,
  paymentSuccessUser,
  paymentReceivedHost,
  tourBookingConfirmation,
  tourBookingReceivedHost,
  telematicsAlert,
  documentVerified,
  general,
}

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final String? relatedId;
  final String? imageUrl;
  final int? actionNavIndex;
  final Map<String, dynamic>? metadata;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    DateTime? timestamp,
    this.isRead = false,
    this.relatedId,
    this.imageUrl,
    this.actionNavIndex,
    this.metadata,
  }) : timestamp = timestamp ?? DateTime.now();

  AppNotification copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    NotificationType? type,
    DateTime? timestamp,
    bool? isRead,
    String? relatedId,
    String? imageUrl,
    int? actionNavIndex,
    Map<String, dynamic>? metadata,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      relatedId: relatedId ?? this.relatedId,
      imageUrl: imageUrl ?? this.imageUrl,
      actionNavIndex: actionNavIndex ?? this.actionNavIndex,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'userId': userId,
      'title': title,
      'message': message,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
      'isRead': isRead,
      'related_id': relatedId,
      'relatedId': relatedId,
      'image_url': imageUrl,
      'imageUrl': imageUrl,
      'action_nav_index': actionNavIndex,
      'actionNavIndex': actionNavIndex,
      'metadata': metadata,
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    NotificationType parsedType = NotificationType.general;
    final rawType = map['type']?.toString() ?? '';
    for (var val in NotificationType.values) {
      if (val.name.toLowerCase() == rawType.toLowerCase() ||
          val.toString().toLowerCase().contains(rawType.toLowerCase())) {
        parsedType = val;
        break;
      }
    }

    return AppNotification(
      id: map['id'] ?? 'notif_${DateTime.now().millisecondsSinceEpoch}',
      userId: map['userId'] ?? map['user_id'] ?? '',
      title: map['title'] ?? 'Notification',
      message: map['message'] ?? map['body'] ?? '',
      type: parsedType,
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now()
          : (map['created_at'] != null
              ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
              : DateTime.now()),
      isRead: _parseBool(map['isRead'] ?? map['is_read'], false),
      relatedId: map['relatedId'] ?? map['related_id'],
      imageUrl: map['imageUrl'] ?? map['image_url'],
      actionNavIndex: map['actionNavIndex'] != null || map['action_nav_index'] != null ? _parseInt(map['actionNavIndex'] ?? map['action_nav_index'], 0) : null,
      metadata: map['metadata'] != null ? Map<String, dynamic>.from(map['metadata']) : null,
    );
  }
}

class BlogPost {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String authorRole;
  final String title;
  final String content;
  final String postType; // 'text', 'social_embed'
  final String? socialPlatform; // 'youtube', 'instagram', 'twitter', 'facebook'
  final String? socialHandle; // e.g. '@user'
  final String? embedUrl; // converted iframe src url
  final int likesCount;
  final List<String> likedByUsers; // List of user IDs who liked
  final DateTime createdAt;
  final DateTime updatedAt;

  BlogPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    this.authorRole = 'Rider',
    required this.title,
    required this.content,
    this.postType = 'text',
    this.socialPlatform,
    this.socialHandle,
    this.embedUrl,
    this.likesCount = 0,
    this.likedByUsers = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'author_id': authorId,
      'author_name': authorName,
      'author_avatar': authorAvatar,
      'author_role': authorRole,
      'title': title,
      'content': content,
      'post_type': postType,
      'social_platform': socialPlatform,
      'social_handle': socialHandle,
      'embed_url': embedUrl,
      'likes_count': likesCount,
      'liked_by_users': likedByUsers,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory BlogPost.fromMap(Map<String, dynamic> map) {
    List<String> parsedLikes = [];
    if (map['liked_by_users'] != null) {
      try {
        final rawLikes = map['liked_by_users'];
        if (rawLikes is List) {
          parsedLikes = rawLikes.map((e) => e.toString()).toList();
        } else if (rawLikes is String) {
          final decoded = jsonDecode(rawLikes);
          if (decoded is List) {
            parsedLikes = decoded.map((e) => e.toString()).toList();
          }
        }
      } catch (e) {
        debugPrint('Error parsing liked_by_users: $e');
      }
    }
    return BlogPost(
      id: map['id'] ?? '',
      authorId: map['author_id'] ?? map['authorId'] ?? '',
      authorName: map['author_name'] ?? map['authorName'] ?? 'Anonymous Rider',
      authorAvatar: map['author_avatar'] ?? map['authorAvatar'],
      authorRole: map['author_role'] ?? map['authorRole'] ?? 'Rider',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      postType: map['post_type'] ?? map['postType'] ?? 'text',
      socialPlatform: map['social_platform'] ?? map['socialPlatform'],
      socialHandle: map['social_handle'] ?? map['socialHandle'],
      embedUrl: map['embed_url'] ?? map['embedUrl'],
      likesCount: _parseInt(map['likes_count'] ?? map['likesCount'], 0),
      likedByUsers: parsedLikes,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }

  BlogPost copyWith({
    String? title,
    String? content,
    int? likesCount,
    List<String>? likedByUsers,
    String? authorName,
    String? authorAvatar,
  }) {
    return BlogPost(
      id: id,
      authorId: authorId,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      authorRole: authorRole,
      title: title ?? this.title,
      content: content ?? this.content,
      postType: postType,
      socialPlatform: socialPlatform,
      socialHandle: socialHandle,
      embedUrl: embedUrl,
      likesCount: likesCount ?? this.likesCount,
      likedByUsers: likedByUsers ?? this.likedByUsers,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

class BlogComment {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String authorRole;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  BlogComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    this.authorRole = 'Rider',
    required this.content,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'post_id': postId,
      'author_id': authorId,
      'author_name': authorName,
      'author_avatar': authorAvatar,
      'author_role': authorRole,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory BlogComment.fromMap(Map<String, dynamic> map) {
    return BlogComment(
      id: map['id'] ?? '',
      postId: map['post_id'] ?? map['postId'] ?? '',
      authorId: map['author_id'] ?? map['authorId'] ?? '',
      authorName: map['author_name'] ?? map['authorName'] ?? 'Anonymous Rider',
      authorAvatar: map['author_avatar'] ?? map['authorAvatar'],
      authorRole: map['author_role'] ?? map['authorRole'] ?? 'Rider',
      content: map['content'] ?? '',
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }

  BlogComment copyWith({
    String? content,
    String? authorName,
    String? authorAvatar,
  }) {
    return BlogComment(
      id: id,
      postId: postId,
      authorId: authorId,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      authorRole: authorRole,
      content: content ?? this.content,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

class HostProfile {
  final String id;
  final String userId;
  final String displayName;
  final String email;
  final String phoneNumber;
  final String photoUrl;
  final String bio;
  final String businessName;
  final String businessRegistrationNumber;
  final bool isVerified;
  final String verificationStatus; // 'pending', 'verified', 'rejected', 'action_required'
  final String verificationNotes;
  final DateTime? verifiedAt;
  final String verifiedBy;
  final String governmentIdType;
  final String governmentIdNumber;
  final String documentUrl;
  final int totalListingsCount;
  final double rating;
  final int reviewCount;
  final double trustScore;
  final DateTime createdAt;
  final DateTime updatedAt;

  HostProfile({
    required this.id,
    required this.userId,
    required this.displayName,
    this.email = '',
    this.phoneNumber = '',
    this.photoUrl = '',
    this.bio = '',
    this.businessName = '',
    this.businessRegistrationNumber = '',
    this.isVerified = false,
    this.verificationStatus = 'pending',
    this.verificationNotes = '',
    this.verifiedAt,
    this.verifiedBy = '',
    this.governmentIdType = '',
    this.governmentIdNumber = '',
    this.documentUrl = '',
    this.totalListingsCount = 0,
    this.rating = 5.0,
    this.reviewCount = 0,
    this.trustScore = 95.0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get isPending => verificationStatus.toLowerCase() == 'pending';
  bool get isVerifiedProvider => isVerified || verificationStatus.toLowerCase() == 'verified';
  bool get isRejected => verificationStatus.toLowerCase() == 'rejected';
  bool get needsAction => verificationStatus.toLowerCase() == 'action_required';

  String get verificationBadgeLabel {
    if (isVerifiedProvider) return 'Verified Provider';
    if (isPending) return 'Verification Pending';
    if (needsAction) return 'Action Required';
    if (isRejected) return 'Verification Rejected';
    return 'Unverified Host';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'display_name': displayName,
      'email': email,
      'phone_number': phoneNumber,
      'photo_url': photoUrl,
      'bio': bio,
      'business_name': businessName,
      'business_registration_number': businessRegistrationNumber,
      'is_verified': isVerified,
      'verification_status': verificationStatus,
      'verification_notes': verificationNotes,
      'verified_at': verifiedAt?.toIso8601String(),
      'verified_by': verifiedBy,
      'government_id_type': governmentIdType,
      'government_id_number': governmentIdNumber,
      'document_url': documentUrl,
      'total_listings_count': totalListingsCount,
      'rating': rating,
      'review_count': reviewCount,
      'trust_score': trustScore,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory HostProfile.fromMap(Map<String, dynamic> map, [String? fallbackId]) {
    return HostProfile(
      id: (map['id'] ?? map['id']?.toString() ?? fallbackId ?? '').toString(),
      userId: (map['user_id'] ?? map['userId'] ?? map['id'] ?? fallbackId ?? '').toString(),
      displayName: map['display_name'] ?? map['displayName'] ?? 'Host Provider',
      email: map['email'] ?? '',
      phoneNumber: map['phone_number'] ?? map['phoneNumber'] ?? '',
      photoUrl: map['photo_url'] ?? map['photoUrl'] ?? '',
      bio: map['bio'] ?? '',
      businessName: map['business_name'] ?? map['businessName'] ?? '',
      businessRegistrationNumber: map['business_registration_number'] ?? map['businessRegistrationNumber'] ?? '',
      isVerified: map['is_verified'] == true || map['isVerified'] == true,
      verificationStatus: map['verification_status'] ?? map['verificationStatus'] ?? 'pending',
      verificationNotes: map['verification_notes'] ?? map['verificationNotes'] ?? '',
      verifiedAt: map['verified_at'] != null ? DateTime.tryParse(map['verified_at'].toString()) : null,
      verifiedBy: map['verified_by'] ?? map['verifiedBy'] ?? '',
      governmentIdType: map['government_id_type'] ?? map['governmentIdType'] ?? '',
      governmentIdNumber: map['government_id_number'] ?? map['governmentIdNumber'] ?? '',
      documentUrl: map['document_url'] ?? map['documentUrl'] ?? '',
      totalListingsCount: (map['total_listings_count'] ?? map['totalListingsCount'] as num?)?.toInt() ?? 0,
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
      reviewCount: (map['review_count'] ?? map['reviewCount'] as num?)?.toInt() ?? 0,
      trustScore: (map['trust_score'] ?? map['trustScore'] as num?)?.toDouble() ?? 95.0,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }

  HostProfile copyWith({
    String? displayName,
    String? email,
    String? phoneNumber,
    String? photoUrl,
    String? bio,
    String? businessName,
    String? businessRegistrationNumber,
    bool? isVerified,
    String? verificationStatus,
    String? verificationNotes,
    DateTime? verifiedAt,
    String? verifiedBy,
    String? governmentIdType,
    String? governmentIdNumber,
    String? documentUrl,
    int? totalListingsCount,
    double? rating,
    int? reviewCount,
    double? trustScore,
  }) {
    return HostProfile(
      id: id,
      userId: userId,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      businessName: businessName ?? this.businessName,
      businessRegistrationNumber: businessRegistrationNumber ?? this.businessRegistrationNumber,
      isVerified: isVerified ?? this.isVerified,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      verificationNotes: verificationNotes ?? this.verificationNotes,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      governmentIdType: governmentIdType ?? this.governmentIdType,
      governmentIdNumber: governmentIdNumber ?? this.governmentIdNumber,
      documentUrl: documentUrl ?? this.documentUrl,
      totalListingsCount: totalListingsCount ?? this.totalListingsCount,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      trustScore: trustScore ?? this.trustScore,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

class PaymentTransaction {
  final String id;
  final String userId;
  final String bookingId;
  final String razorpayPaymentId;
  final String razorpayOrderId;
  final String razorpaySignature;
  final double amount; // Amount in INR
  final String currency; // 'INR'
  final String status; // 'created', 'authorized', 'captured', 'failed', 'refunded'
  final String paymentMethod; // 'razorpay', 'upi', 'card', 'wallet', 'stripe_escrow'
  final String escrowStatus; // 'held_in_escrow', 'released_to_host', 'refunded_deposit'
  final String receipt;
  final Map<String, dynamic> notes;
  final String? errorCode;
  final String? errorDescription;
  final DateTime createdAt;
  final DateTime? updatedAt;

  PaymentTransaction({
    required this.id,
    required this.userId,
    this.bookingId = '',
    required this.razorpayPaymentId,
    required this.razorpayOrderId,
    this.razorpaySignature = '',
    required this.amount,
    this.currency = 'INR',
    this.status = 'captured',
    this.paymentMethod = 'razorpay',
    this.escrowStatus = 'held_in_escrow',
    this.receipt = '',
    this.notes = const {},
    this.errorCode,
    this.errorDescription,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'booking_id': bookingId,
      'razorpay_payment_id': razorpayPaymentId,
      'razorpay_order_id': razorpayOrderId,
      'razorpay_signature': razorpaySignature,
      'amount': amount,
      'currency': currency,
      'status': status,
      'payment_method': paymentMethod,
      'escrow_status': escrowStatus,
      'receipt': receipt,
      'notes': notes,
      'error_code': errorCode,
      'error_description': errorDescription,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String() ?? createdAt.toIso8601String(),
    };
  }

  factory PaymentTransaction.fromMap(Map<String, dynamic> map, [String? docId]) {
    return PaymentTransaction(
      id: docId ?? (map['id']?.toString() ?? 'tx_${DateTime.now().millisecondsSinceEpoch}'),
      userId: map['user_id']?.toString() ?? (map['userId']?.toString() ?? ''),
      bookingId: map['booking_id']?.toString() ?? (map['bookingId']?.toString() ?? ''),
      razorpayPaymentId: map['razorpay_payment_id']?.toString() ?? (map['razorpayPaymentId']?.toString() ?? map['payment_id']?.toString() ?? ''),
      razorpayOrderId: map['razorpay_order_id']?.toString() ?? (map['razorpayOrderId']?.toString() ?? map['order_id']?.toString() ?? ''),
      razorpaySignature: map['razorpay_signature']?.toString() ?? (map['razorpaySignature']?.toString() ?? ''),
      amount: _parseDouble(map['amount'], 0.0),
      currency: map['currency']?.toString() ?? 'INR',
      status: map['status']?.toString() ?? 'captured',
      paymentMethod: map['payment_method']?.toString() ?? (map['paymentMethod']?.toString() ?? 'razorpay'),
      escrowStatus: map['escrow_status']?.toString() ?? (map['escrowStatus']?.toString() ?? 'held_in_escrow'),
      receipt: map['receipt']?.toString() ?? '',
      notes: map['notes'] != null && map['notes'] is Map
          ? Map<String, dynamic>.from(map['notes'])
          : {},
      errorCode: map['error_code']?.toString() ?? map['errorCode']?.toString(),
      errorDescription: map['error_description']?.toString() ?? map['errorDescription']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : (map['createdAt'] != null ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now() : DateTime.now()),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
          : (map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt'].toString()) : null),
    );
  }

  PaymentTransaction copyWith({
    String? status,
    String? escrowStatus,
    String? errorCode,
    String? errorDescription,
    DateTime? updatedAt,
  }) {
    return PaymentTransaction(
      id: id,
      userId: userId,
      bookingId: bookingId,
      razorpayPaymentId: razorpayPaymentId,
      razorpayOrderId: razorpayOrderId,
      razorpaySignature: razorpaySignature,
      amount: amount,
      currency: currency,
      status: status ?? this.status,
      paymentMethod: paymentMethod,
      escrowStatus: escrowStatus ?? this.escrowStatus,
      receipt: receipt,
      notes: notes,
      errorCode: errorCode ?? this.errorCode,
      errorDescription: errorDescription ?? this.errorDescription,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
