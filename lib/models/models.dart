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
      hostName: hostName,
      hostAvatar: hostAvatar,
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
    final List<String> parsedImages = map['images'] != null && (map['images'] as List).isNotEmpty
        ? List<String>.from(map['images'])
        : (map['imageUrl'] != null && (map['imageUrl'] as String).trim().isNotEmpty
            ? <String>[(map['imageUrl'] as String).trim()]
            : <String>['https://images.unsplash.com/photo-1558981403-c5f9899a28bc?w=800&q=80']);

    final String mainImg = (map['imageUrl'] != null && (map['imageUrl'] as String).trim().isNotEmpty)
        ? (map['imageUrl'] as String).trim()
        : parsedImages.first;

    return Vehicle(
      id: map['id'] ?? '',
      title: map['title'] ?? 'Untitled Vehicle',
      type: VehicleType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => VehicleType.car,
      ),
      category: map['category'] ?? 'General',
      pricePerDay: (map['pricePerDay'] as num?)?.toDouble() ?? 0.0,
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
      reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 0,
      imageUrl: mainImg,
      location: map['location'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 37.7749,
      longitude: (map['longitude'] as num?)?.toDouble() ?? -122.4194,
      status: map['status'] ?? 'Available',
      hostName: map['hostName'] ?? 'Host',
      hostAvatar: map['hostAvatar'] ?? '',
      hostTrustScore: (map['hostTrustScore'] as num?)?.toDouble() ?? 95.0,
      hostId: map['hostId'] ?? '',
      isInstantBookable: map['isInstantBookable'] ?? true,
      isFavorite: map['isFavorite'] ?? false,
      fuelType: map['fuelType'] ?? 'Gasoline',
      transmission: map['transmission'] ?? 'Automatic',
      seats: (map['seats'] as num?)?.toInt() ?? 2,
      description: map['description'] ?? '',
      iotData: map['iotData'] != null ? Map<String, dynamic>.from(map['iotData']) : {},
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
      guideName: guideName,
      guideAvatar: guideAvatar,
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

  factory Tour.fromMap(Map<String, dynamic> map) {
    final List<String> rawImages = map['images'] != null && (map['images'] as List).isNotEmpty
        ? List<String>.from(map['images']).where((img) => img.trim().isNotEmpty).toList()
        : (map['imageUrl'] != null && (map['imageUrl'] as String).trim().isNotEmpty
            ? <String>[(map['imageUrl'] as String).trim()]
            : <String>['https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=800&q=80']);

    final String mainImg = (map['imageUrl'] != null && (map['imageUrl'] as String).trim().isNotEmpty)
        ? (map['imageUrl'] as String).trim()
        : rawImages.first;

    return Tour(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      location: map['location'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      duration: map['duration'] ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
      reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 0,
      imageUrl: mainImg,
      images: rawImages,
      guideName: map['guideName'] ?? map['hostName'] ?? '',
      guideAvatar: map['guideAvatar'] ?? map['hostAvatar'] ?? '',
      hostId: map['hostId'] ?? map['guideId'] ?? '',
      waypoints: List<String>.from(map['waypoints'] ?? []),
      includedGear: List<String>.from(map['includedGear'] ?? []),
      description: map['description'] ?? '',
      isFavorite: map['isFavorite'] ?? false,
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
      userId: map['userId'] ?? '',
      destination: map['destination'] ?? '',
      durationDays: (map['durationDays'] as num?)?.toInt() ?? 3,
      budget: map['budget'] ?? 'Standard',
      terrain: map['terrain'] ?? 'Scenic',
      generatedItineraryJson: map['generatedItineraryJson'] ?? '',
      createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now() : DateTime.now(),
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
}

class ComplianceDocument {
  final String id;
  final String userId;
  final String title;
  final String status; // 'Verified', 'Pending', 'Action Required'
  final DateTime expiryDate;
  final String type;
  final String documentUrl;

  ComplianceDocument({
    required this.id,
    this.userId = '',
    required this.title,
    required this.status,
    required this.expiryDate,
    required this.type,
    this.documentUrl = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'status': status,
      'expiryDate': expiryDate.toIso8601String(),
      'type': type,
      'documentUrl': documentUrl,
    };
  }

  factory ComplianceDocument.fromMap(Map<String, dynamic> map) {
    return ComplianceDocument(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? 'Document',
      status: map['status'] ?? 'Verified',
      expiryDate: map['expiryDate'] != null ? DateTime.tryParse(map['expiryDate'].toString()) ?? DateTime.now().add(const Duration(days: 365)) : DateTime.now().add(const Duration(days: 365)),
      type: map['type'] ?? 'ID',
      documentUrl: map['documentUrl'] ?? '',
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
  final String status; // 'Confirmed', 'Active', 'Completed', 'Cancelled'
  final String unlockPasscode;
  final String paymentIntentId;
  final DateTime createdAt;

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
  });

  Booking copyWith({
    String? status,
    String? unlockPasscode,
    String? paymentIntentId,
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
    };
  }

  factory Booking.fromMap(Map<String, dynamic> map) {
    return Booking(
      id: map['id'] ?? '',
      vehicleId: map['vehicleId'] ?? '',
      vehicleTitle: map['vehicleTitle'] ?? '',
      vehicleImageUrl: map['vehicleImageUrl'] ?? '',
      hostName: map['hostName'] ?? '',
      userId: map['userId'] ?? map['riderId'] ?? '',
      hostId: map['hostId'] ?? '',
      startDate: map['startDate'] != null ? DateTime.tryParse(map['startDate'].toString()) ?? DateTime.now() : DateTime.now(),
      endDate: map['endDate'] != null ? DateTime.tryParse(map['endDate'].toString()) ?? DateTime.now() : DateTime.now(),
      totalPrice: (map['totalPrice'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'Confirmed',
      unlockPasscode: map['unlockPasscode'] ?? '',
      paymentIntentId: map['paymentIntentId'] ?? '',
      createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now() : DateTime.now(),
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
    this.photoUrl = 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&q=80',
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
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'role': role,
      'trustScore': trustScore,
      'bio': bio,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(String id, Map<String, dynamic> map) {
    return UserProfile(
      uid: id.isNotEmpty ? id : (map['uid'] ?? ''),
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      photoUrl: map['photoUrl'] ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&q=80',
      phoneNumber: map['phoneNumber'] ?? '',
      role: map['role'] ?? 'Rider',
      trustScore: (map['trustScore'] as num?)?.toDouble() ?? 95.0,
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


