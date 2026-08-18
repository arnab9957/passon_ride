class LocationResult {
  final String displayName;
  final String city;
  final String state;
  final String country;
  final String postalCode;
  final double latitude;
  final double longitude;
  final bool isLive;
  final String accuracy;
  final DateTime timestamp;

  LocationResult({
    required this.displayName,
    this.city = '',
    this.state = '',
    this.country = '',
    this.postalCode = '',
    required this.latitude,
    required this.longitude,
    this.isLive = false,
    this.accuracy = 'High Accuracy (~10m)',
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'city': city,
      'state': state,
      'country': country,
      'postalCode': postalCode,
      'latitude': latitude,
      'longitude': longitude,
      'isLive': isLive,
      'accuracy': accuracy,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory LocationResult.fromMap(Map<String, dynamic> map) {
    return LocationResult(
      displayName: map['displayName'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      country: map['country'] ?? '',
      postalCode: map['postalCode'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 37.7749,
      longitude: (map['longitude'] as num?)?.toDouble() ?? -122.4194,
      isLive: map['isLive'] ?? false,
      accuracy: map['accuracy'] ?? 'Calibrated',
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  LocationResult copyWith({
    String? displayName,
    String? city,
    String? state,
    String? country,
    String? postalCode,
    double? latitude,
    double? longitude,
    bool? isLive,
    String? accuracy,
    DateTime? timestamp,
  }) {
    return LocationResult(
      displayName: displayName ?? this.displayName,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      postalCode: postalCode ?? this.postalCode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isLive: isLive ?? this.isLive,
      accuracy: accuracy ?? this.accuracy,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() => '$displayName ($latitude, $longitude, live: $isLive)';
}
