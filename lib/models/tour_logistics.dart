import 'package:flutter/material.dart' show DateUtils;

/// Operational details a tour agency needs to publish a guided tour:
/// transport, group size, schedule, meeting point, meals/stay, policies & licences.
class TourLogistics {
  static const transportOptions = [
    'AC Bus / Volvo',
    'Mini Bus',
    'Tempo Traveller',
    'SUV (Innova / Ertiga)',
    'Small Car (Hatchback / Sedan)',
    'Jeep / 4x4',
    'Motorcycle',
    'Scooty',
    'Bicycle',
    'Train',
    'Boat / Ferry',
    'Flight',
    'Trek / On Foot',
  ];
  static const difficultyOptions = ['Easy', 'Moderate', 'Challenging', 'Extreme'];
  static const stayOptions = ['No stay (day tour)', 'Hotel', 'Homestay', 'Camp / Tent', 'Resort'];
  static const mealOptions = ['Breakfast', 'Lunch', 'Dinner', 'Snacks & Tea', 'Bottled Water'];
  static const languageOptions = ['English', 'Hindi', 'Bengali', 'Nepali', 'Tamil', 'Telugu', 'Marathi', 'Kannada'];
  static const dayOptions = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const cancellationOptions = [
    'Flexible — full refund up to 24h before',
    'Moderate — full refund up to 3 days before',
    'Strict — 50% refund up to 7 days before',
    'Non-refundable',
  ];

  final List<String> transportModes;
  final String transportDetails; // e.g. "2 × Tempo Traveller, AC, 12 seats"
  final bool fuelIncluded;
  final bool driverIncluded;

  final int minGroupSize;
  final int maxGroupSize;
  final int minAge;
  final String difficulty;

  final DateTime? tourStartDate; // first day of the tour / batch
  final DateTime? tourEndDate; // last day of the tour / batch
  final String endTime; // "06:00 PM"
  final List<String> departureDays; // empty = on request
  final String startTime; // "06:30 AM"
  final String meetingPoint;
  final bool hotelPickup;

  final String accommodation;
  final List<String> meals;
  final List<String> languages;
  final List<String> exclusions;

  final double childPrice; // 0 = same as adult
  final String cancellationPolicy;
  final String thingsToCarry;
  final String emergencyContact;
  final String licenseNumber; // tourism dept / agency registration

  const TourLogistics({
    this.transportModes = const [],
    this.transportDetails = '',
    this.fuelIncluded = true,
    this.driverIncluded = true,
    this.minGroupSize = 1,
    this.maxGroupSize = 12,
    this.minAge = 0,
    this.difficulty = 'Easy',
    this.tourStartDate,
    this.tourEndDate,
    this.endTime = '',
    this.departureDays = const [],
    this.startTime = '',
    this.meetingPoint = '',
    this.hotelPickup = false,
    this.accommodation = 'No stay (day tour)',
    this.meals = const [],
    this.languages = const ['English', 'Hindi'],
    this.exclusions = const [],
    this.childPrice = 0,
    this.cancellationPolicy = 'Moderate — full refund up to 3 days before',
    this.thingsToCarry = '',
    this.emergencyContact = '',
    this.licenseNumber = '',
  });

  bool get isEmpty =>
      transportModes.isEmpty && meetingPoint.isEmpty && startTime.isEmpty && tourStartDate == null;

  /// Number of days covered by the start/end dates (inclusive), or null.
  int? get tourDays => (tourStartDate != null && tourEndDate != null)
      ? DateUtils.dateOnly(tourEndDate!).difference(DateUtils.dateOnly(tourStartDate!)).inDays + 1
      : null;

  /// Clears the dates (copyWith can't set them back to null).
  TourLogistics withoutDates() => TourLogistics.fromMap(
      toMap()..remove('tour_start_date')..remove('tour_end_date'));

  TourLogistics copyWith({
    List<String>? transportModes,
    String? transportDetails,
    bool? fuelIncluded,
    bool? driverIncluded,
    int? minGroupSize,
    int? maxGroupSize,
    int? minAge,
    String? difficulty,
    DateTime? tourStartDate,
    DateTime? tourEndDate,
    String? endTime,
    List<String>? departureDays,
    String? startTime,
    String? meetingPoint,
    bool? hotelPickup,
    String? accommodation,
    List<String>? meals,
    List<String>? languages,
    List<String>? exclusions,
    double? childPrice,
    String? cancellationPolicy,
    String? thingsToCarry,
    String? emergencyContact,
    String? licenseNumber,
  }) =>
      TourLogistics(
        transportModes: transportModes ?? this.transportModes,
        transportDetails: transportDetails ?? this.transportDetails,
        fuelIncluded: fuelIncluded ?? this.fuelIncluded,
        driverIncluded: driverIncluded ?? this.driverIncluded,
        minGroupSize: minGroupSize ?? this.minGroupSize,
        maxGroupSize: maxGroupSize ?? this.maxGroupSize,
        minAge: minAge ?? this.minAge,
        difficulty: difficulty ?? this.difficulty,
        tourStartDate: tourStartDate ?? this.tourStartDate,
        tourEndDate: tourEndDate ?? this.tourEndDate,
        endTime: endTime ?? this.endTime,
        departureDays: departureDays ?? this.departureDays,
        startTime: startTime ?? this.startTime,
        meetingPoint: meetingPoint ?? this.meetingPoint,
        hotelPickup: hotelPickup ?? this.hotelPickup,
        accommodation: accommodation ?? this.accommodation,
        meals: meals ?? this.meals,
        languages: languages ?? this.languages,
        exclusions: exclusions ?? this.exclusions,
        childPrice: childPrice ?? this.childPrice,
        cancellationPolicy: cancellationPolicy ?? this.cancellationPolicy,
        thingsToCarry: thingsToCarry ?? this.thingsToCarry,
        emergencyContact: emergencyContact ?? this.emergencyContact,
        licenseNumber: licenseNumber ?? this.licenseNumber,
      );

  Map<String, dynamic> toMap() => {
        'transport_modes': transportModes,
        'transport_details': transportDetails,
        'fuel_included': fuelIncluded,
        'driver_included': driverIncluded,
        'min_group_size': minGroupSize,
        'max_group_size': maxGroupSize,
        'min_age': minAge,
        'difficulty': difficulty,
        'tour_start_date': tourStartDate?.toIso8601String(),
        'tour_end_date': tourEndDate?.toIso8601String(),
        'end_time': endTime,
        'departure_days': departureDays,
        'start_time': startTime,
        'meeting_point': meetingPoint,
        'hotel_pickup': hotelPickup,
        'accommodation': accommodation,
        'meals': meals,
        'languages': languages,
        'exclusions': exclusions,
        'child_price': childPrice,
        'cancellation_policy': cancellationPolicy,
        'things_to_carry': thingsToCarry,
        'emergency_contact': emergencyContact,
        'license_number': licenseNumber,
      };

  factory TourLogistics.fromMap(dynamic raw) {
    if (raw is! Map) return const TourLogistics();
    final m = Map<String, dynamic>.from(raw);
    List<String> list(String k, [List<String> d = const []]) =>
        m[k] is List ? List<String>.from((m[k] as List).map((e) => e.toString())) : d;
    int i(String k, int d) => int.tryParse('${m[k] ?? ''}') ?? d;
    String s(String k, String d) => (m[k] ?? d).toString();
    bool b(String k, bool d) => m[k] is bool ? m[k] as bool : d;
    const def = TourLogistics();
    return TourLogistics(
      transportModes: list('transport_modes'),
      transportDetails: s('transport_details', ''),
      fuelIncluded: b('fuel_included', def.fuelIncluded),
      driverIncluded: b('driver_included', def.driverIncluded),
      minGroupSize: i('min_group_size', def.minGroupSize),
      maxGroupSize: i('max_group_size', def.maxGroupSize),
      minAge: i('min_age', 0),
      difficulty: s('difficulty', def.difficulty),
      tourStartDate: DateTime.tryParse('${m['tour_start_date'] ?? ''}'),
      tourEndDate: DateTime.tryParse('${m['tour_end_date'] ?? ''}'),
      endTime: s('end_time', ''),
      departureDays: list('departure_days'),
      startTime: s('start_time', ''),
      meetingPoint: s('meeting_point', ''),
      hotelPickup: b('hotel_pickup', false),
      accommodation: s('accommodation', def.accommodation),
      meals: list('meals'),
      languages: list('languages', def.languages),
      exclusions: list('exclusions'),
      childPrice: double.tryParse('${m['child_price'] ?? ''}') ?? 0,
      cancellationPolicy: s('cancellation_policy', def.cancellationPolicy),
      thingsToCarry: s('things_to_carry', ''),
      emergencyContact: s('emergency_contact', ''),
      licenseNumber: s('license_number', ''),
    );
  }
}
