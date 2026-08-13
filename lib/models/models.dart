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
  });

  Vehicle copyWith({bool? isFavorite, Map<String, dynamic>? iotData}) {
    return Vehicle(
      id: id,
      title: title,
      type: type,
      category: category,
      pricePerDay: pricePerDay,
      rating: rating,
      reviewCount: reviewCount,
      imageUrl: imageUrl,
      location: location,
      hostName: hostName,
      hostAvatar: hostAvatar,
      hostTrustScore: hostTrustScore,
      isInstantBookable: isInstantBookable,
      isFavorite: isFavorite ?? this.isFavorite,
      fuelType: fuelType,
      transmission: transmission,
      seats: seats,
      description: description,
      iotData: iotData ?? this.iotData,
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

