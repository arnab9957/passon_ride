import 'dart:convert';
export 'location_model.dart';

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
    this.isInstantBookable = true,
    this.isFavorite = false,
    required this.fuelType,
    required this.transmission,
    required this.seats,
    required this.description,
    required this.iotData,
    this.images = const [],
  });

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
      pricePerDay: (map['pricePerDay'] ?? map['price_per_day'] as num?)?.toDouble() ?? 0.0,
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
      reviewCount: (map['reviewCount'] ?? map['review_count'] as num?)?.toInt() ?? 0,
      imageUrl: finalMainImg,
      location: map['location'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 37.7749,
      longitude: (map['longitude'] as num?)?.toDouble() ?? -122.4194,
      status: map['status'] ?? 'Available',
      hostName: map['hostName'] ?? map['host_name'] ?? 'Host',
      hostAvatar: Tour._normalizeUrl((map['hostAvatar'] ?? map['host_avatar'] ?? '').toString()),
      hostTrustScore: (map['hostTrustScore'] ?? map['host_trust_score'] as num?)?.toDouble() ?? 95.0,
      hostId: map['hostId'] ?? map['host_id'] ?? '',
      isInstantBookable: map['isInstantBookable'] ?? map['is_instant_bookable'] ?? true,
      isFavorite: map['isFavorite'] ?? map['is_favorite'] ?? false,
      fuelType: map['fuelType'] ?? map['fuel_type'] ?? 'Gasoline',
      transmission: map['transmission'] ?? 'Automatic',
      seats: (map['seats'] as num?)?.toInt() ?? 2,
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

  Tour({
    required this.id,
    required this.title,
    required this.location,
    required this.price,
    required this.duration,
    required this.rating,
    required this.reviewCount,
    required String imageUrl,
    this.images = const [],
    required this.guideName,
    required this.guideAvatar,
    this.hostId = '',
    required this.waypoints,
    required this.includedGear,
    required this.description,
    this.isFavorite = false,
  }) : _imageUrl = imageUrl;

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
  }) {
    return Tour(
      id: id,
      title: title ?? this.title,
      location: location ?? this.location,
      price: price ?? this.price,
      duration: duration ?? this.duration,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      imageUrl: imageUrl ?? this._imageUrl,
      images: images ?? this.images,
      guideName: guideName ?? this.guideName,
      guideAvatar: guideAvatar ?? this.guideAvatar,
      hostId: hostId ?? this.hostId,
      waypoints: waypoints,
      includedGear: includedGear,
      description: description ?? this.description,
      isFavorite: isFavorite ?? this.isFavorite,
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

    return Tour(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      location: map['location'] ?? '',
      price: (map['price'] ?? map['price_per_rider'] as num?)?.toDouble() ?? 0.0,
      duration: map['duration'] ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
      reviewCount: (map['reviewCount'] ?? map['review_count'] as num?)?.toInt() ?? 0,
      imageUrl: finalMainImg,
      images: parsedImages,
      guideName: map['guideName'] ?? map['guide_name'] ?? map['hostName'] ?? map['host_name'] ?? '',
      guideAvatar: _normalizeUrl((map['guideAvatar'] ?? map['guide_avatar'] ?? map['hostAvatar'] ?? map['host_avatar'] ?? '').toString()),
      hostId: map['hostId'] ?? map['host_id'] ?? map['guideId'] ?? map['guide_id'] ?? '',
      waypoints: List<String>.from(map['waypoints'] ?? []),
      includedGear: List<String>.from(map['includedGear'] ?? map['included_gear'] ?? []),
      description: map['description'] ?? '',
      isFavorite: map['isFavorite'] ?? map['is_favorite'] ?? false,
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
      durationDays: (map['durationDays'] ?? map['duration_days'] as num?)?.toInt() ?? 3,
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

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    required this.isUser,
  });

  Map<String, dynamic> toMap(String threadId) {
    return {
      'id': id,
      'thread_id': threadId,
      'threadId': threadId,
      'sender_id': senderId,
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'is_user': isUser,
      'isUser': isUser,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? map['sender_id'] ?? '',
      text: map['text'] ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isUser: map['isUser'] ?? map['is_user'] ?? true,
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

  ChatThread({
    required this.id,
    required this.partnerName,
    required this.partnerAvatar,
    required this.lastMessage,
    required this.lastTime,
    required this.unreadCount,
    required this.vehicleTitle,
    required this.messages,
  });

  Map<String, dynamic> toMap(String userId) {
    return {
      'id': id,
      'user_id': userId,
      'userId': userId,
      'partner_name': partnerName,
      'partnerName': partnerName,
      'partner_avatar': partnerAvatar,
      'partnerAvatar': partnerAvatar,
      'last_message': lastMessage,
      'lastMessage': lastMessage,
      'last_time': lastTime.toIso8601String(),
      'lastTime': lastTime.toIso8601String(),
      'unread_count': unreadCount,
      'unreadCount': unreadCount,
      'vehicle_title': vehicleTitle,
      'vehicleTitle': vehicleTitle,
    };
  }

  factory ChatThread.fromMap(Map<String, dynamic> map, [List<ChatMessage>? msgs]) {
    return ChatThread(
      id: map['id'] ?? '',
      partnerName: map['partnerName'] ?? map['partner_name'] ?? 'Passon Host',
      partnerAvatar: map['partnerAvatar'] ?? map['partner_avatar'] ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&q=80',
      lastMessage: map['lastMessage'] ?? map['last_message'] ?? '',
      lastTime: map['lastTime'] != null
          ? DateTime.tryParse(map['lastTime'].toString()) ?? DateTime.now()
          : map['last_time'] != null
              ? DateTime.tryParse(map['last_time'].toString()) ?? DateTime.now()
              : DateTime.now(),
      unreadCount: (map['unreadCount'] ?? map['unread_count'] as num?)?.toInt() ?? 0,
      vehicleTitle: map['vehicleTitle'] ?? map['vehicle_title'] ?? '',
      messages: msgs ?? [],
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
      totalEarnings: (map['totalEarnings'] ?? map['total_earnings'] as num?)?.toDouble() ?? 0.0,
      monthlyEarnings: (map['monthlyEarnings'] ?? map['monthly_earnings'] as num?)?.toDouble() ?? 0.0,
      completedTrips: (map['completedTrips'] ?? map['completed_trips'] as num?)?.toInt() ?? 0,
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

    return ComplianceDocument(
      id: map['id'] ?? '',
      userId: map['userId'] ?? map['user_id'] ?? '',
      title: map['title'] ?? 'Document',
      status: map['status'] ?? 'Verified',
      expiryDate: exp,
      type: map['type'] ?? 'ID',
      documentUrl: map['documentUrl'] ?? map['document_url'] ?? '',
      documentNumber: map['documentNumber'] ?? map['document_number'] ?? '',
      holderName: map['holderName'] ?? map['holder_name'] ?? '',
      licenseType: map['licenseType'] ?? map['license_type'] ?? 'LMV & MCWG',
      fileSizeKb: (map['fileSizeKb'] ?? map['file_size_kb'] as num?)?.toDouble() ?? 250.0,
      fileName: map['fileName'] ?? map['file_name'] ?? '',
      fileExtension: map['fileExtension'] ?? map['file_extension'] ?? 'PDF',
      confidenceScore: (map['confidenceScore'] ?? map['confidence_score'] as num?)?.toDouble() ?? 98.5,
      issuingAuthority: map['issuingAuthority'] ?? map['issuing_authority'] ?? 'Govt Transport Authority (RTO / UIDAI)',
      bloodGroup: map['bloodGroup'] ?? map['blood_group'] ?? 'O+',
      address: map['address'] ?? 'H.No 142/B, Indiranagar 100ft Road, Bangalore, KA',
      dob: map['dob'] ?? '1996-05-14',
      isExpiryValid: map['isExpiryValid'] ?? map['is_expiry_valid'] ?? exp.isAfter(DateTime.now()),
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
      trustScore: (map['trustScore'] ?? map['trust_score'] as num?)?.toDouble() ?? 95.0,
      trustBadges: map['trustBadges'] != null
          ? List<String>.from(map['trustBadges'])
          : map['trust_badges'] != null
              ? List<String>.from(map['trust_badges'])
              : ['Identity Verified', 'Clean Driving Record', 'High Rating Host'],
      telematicsScore: (map['telematicsScore'] ?? map['telematics_score'] as num?)?.toDouble() ?? 98.0,
      cancellationRate: (map['cancellationRate'] ?? map['cancellation_rate'] as num?)?.toDouble() ?? 0.0,
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

  Booking({
    required this.id,
    required this.vehicleId,
    required this.vehicleTitle,
    required this.vehicleImageUrl,
    required this.hostName,
    this.userId = '',
    this.hostId = '',
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
  });

  Booking copyWith({
    String? status,
    String? unlockPasscode,
    String? paymentIntentId,
    double? riderLatitude,
    double? riderLongitude,
    double? riderSpeed,
    double? riderHeading,
    DateTime? lastGpsUpdate,
    DateTime? rentalStartedAt,
    DateTime? rentalEndedAt,
  }) {
    return Booking(
      id: id,
      vehicleId: vehicleId,
      vehicleTitle: vehicleTitle,
      vehicleImageUrl: vehicleImageUrl,
      hostName: hostName,
      userId: userId,
      hostId: hostId,
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
      'hostId': hostId,
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
    };
  }

  factory Booking.fromMap(Map<String, dynamic> map) {
    return Booking(
      id: map['id'] ?? '',
      vehicleId: map['vehicleId'] ?? map['vehicle_id'] ?? '',
      vehicleTitle: map['vehicleTitle'] ?? map['vehicle_title'] ?? '',
      vehicleImageUrl: map['vehicleImageUrl'] ?? map['vehicle_image_url'] ?? '',
      hostName: map['hostName'] ?? map['host_name'] ?? '',
      userId: map['userId'] ?? map['user_id'] ?? map['riderId'] ?? map['rider_id'] ?? '',
      hostId: map['hostId'] ?? map['host_id'] ?? '',
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
      totalPrice: (map['totalPrice'] ?? map['total_price'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'Confirmed',
      unlockPasscode: map['unlockPasscode'] ?? map['unlock_passcode'] ?? '',
      paymentIntentId: map['paymentIntentId'] ?? map['payment_intent_id'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : map['created_at'] != null
              ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
              : DateTime.now(),
      riderLatitude: (map['riderLatitude'] ?? map['rider_latitude'] as num?)?.toDouble(),
      riderLongitude: (map['riderLongitude'] ?? map['rider_longitude'] as num?)?.toDouble(),
      riderSpeed: (map['riderSpeed'] ?? map['rider_speed'] as num?)?.toDouble() ?? 0.0,
      riderHeading: (map['riderHeading'] ?? map['rider_heading'] as num?)?.toDouble() ?? 0.0,
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
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl = '',
    this.phoneNumber = '',
    this.role = 'Rider',
    this.trustScore = 95.0,
    this.bio = '',
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
      trustScore: (map['trustScore'] ?? map['trust_score'] as num?)?.toDouble() ?? 95.0,
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
      trustScore: trustScore ?? this.trustScore,
      bio: bio ?? this.bio,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
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
      latitude: (map['latitude'] as num?)?.toDouble() ?? 37.7749,
      longitude: (map['longitude'] as num?)?.toDouble() ?? -122.4194,
      speed: (map['speed'] as num?)?.toDouble() ?? 0.0,
      batterySoc: (map['batterySoc'] as num?)?.toInt() ?? (map['batteryLevel'] as num?)?.toInt() ?? 90,
      fuelPercent: (map['fuelPercent'] as num?)?.toInt() ?? 85,
      tpmsFrontPsi: (map['tpmsFrontPsi'] as num?)?.toDouble() ?? (map['tirePressureFront'] as num?)?.toDouble() ?? 32.0,
      tpmsRearPsi: (map['tpmsRearPsi'] as num?)?.toDouble() ?? (map['tirePressureRear'] as num?)?.toDouble() ?? 35.0,
      obdDtcCodes: map['obdDtcCodes'] != null ? List<String>.from(map['obdDtcCodes']) : [],
      engineOn: map['engineOn'] ?? false,
      locked: map['locked'] ?? true,
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
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
      comment: map['comment'] ?? map['feedback'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : map['created_at'] != null
              ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
              : DateTime.now(),
    );
  }
}


