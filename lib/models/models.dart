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
  final String hostName;
  final String hostAvatar;
  final double hostTrustScore;
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
    required this.hostName,
    required this.hostAvatar,
    required this.hostTrustScore,
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
    String? imageUrl,
    String? location,
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
      rating: rating,
      reviewCount: reviewCount,
      imageUrl: imageUrl ?? this.imageUrl,
      location: location ?? this.location,
      hostName: hostName,
      hostAvatar: hostAvatar,
      hostTrustScore: hostTrustScore,
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
}

class Tour {
  final String id;
  final String title;
  final String location;
  final double price;
  final String duration;
  final double rating;
  final int reviewCount;
  final String imageUrl;
  final String guideName;
  final String guideAvatar;
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
    required this.imageUrl,
    required this.guideName,
    required this.guideAvatar,
    required this.waypoints,
    required this.includedGear,
    required this.description,
    this.isFavorite = false,
  });

  Tour copyWith({bool? isFavorite}) {
    return Tour(
      id: id,
      title: title,
      location: location,
      price: price,
      duration: duration,
      rating: rating,
      reviewCount: reviewCount,
      imageUrl: imageUrl,
      guideName: guideName,
      guideAvatar: guideAvatar,
      waypoints: waypoints,
      includedGear: includedGear,
      description: description,
      isFavorite: isFavorite ?? this.isFavorite,
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
  final String title;
  final String status; // 'Verified', 'Pending', 'Action Required'
  final DateTime expiryDate;
  final String type;

  ComplianceDocument({
    required this.id,
    required this.title,
    required this.status,
    required this.expiryDate,
    required this.type,
  });
}

class Booking {
  final String id;
  final String vehicleId;
  final String vehicleTitle;
  final String vehicleImageUrl;
  final String hostName;
  final DateTime startDate;
  final DateTime endDate;
  final double totalPrice;
  final String status; // 'Confirmed', 'Active', 'Completed', 'Cancelled'
  final String unlockPasscode;
  final DateTime createdAt;

  Booking({
    required this.id,
    required this.vehicleId,
    required this.vehicleTitle,
    required this.vehicleImageUrl,
    required this.hostName,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    required this.status,
    required this.unlockPasscode,
    required this.createdAt,
  });
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

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    try {
      // Handles cloud_firestore Timestamp dynamically via toDate()
      return (value as dynamic).toDate();
    } catch (_) {}
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return DateTime.now();
  }

  factory UserProfile.fromMap(String id, Map<String, dynamic> map) {
    return UserProfile(
      uid: id,
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      role: map['role'] ?? 'Rider',
      trustScore: (map['trustScore'] as num?)?.toDouble() ?? 95.0,
      bio: map['bio'] ?? '',
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
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

