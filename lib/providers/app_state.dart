import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';
import '../services/firestore_service.dart';
import '../services/firebase_auth_service.dart';

class AppState extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuthService _authService = FirebaseAuthService();
  FirestoreService get firestoreService => _firestoreService;
  FirebaseAuthService get authService => _authService;

  // Firebase Auth & UserProfile State (Section 1)
  User? _firebaseUser;
  User? get firebaseUser => _firebaseUser;
  bool get isSignedIn => _firebaseUser != null;

  UserProfile? _userProfile;
  UserProfile? get userProfile => _userProfile;
  StreamSubscription<UserProfile?>? _userProfileSubscription;

  String get activeUserEmail => _userProfile?.email ?? _firebaseUser?.email ?? _firebaseUser?.phoneNumber ?? 'Guest User';
  String get activeUserDisplayName =>
      _userProfile?.displayName ??
      _firebaseUser?.displayName ??
      (_firebaseUser?.email != null ? _firebaseUser!.email!.split('@').first : null) ??
      _firebaseUser?.phoneNumber ??
      'Guest User';

  String get activeUserRole => _userProfile?.role ?? 'Rider';
  double get activeUserTrustScore => _userProfile?.trustScore ?? 95.0;

  AppState() {
    try {
      FirebaseAuth.instance.authStateChanges().listen((user) {
        _firebaseUser = user;
        _listenToUserProfile(user);
        notifyListeners();
      });
      _initFirestoreSync();
    } catch (_) {}
  }

  void _listenToUserProfile(User? user) {
    _userProfileSubscription?.cancel();
    if (user != null) {
      _userProfileSubscription = _firestoreService.streamUserProfile(user.uid).listen((profile) {
        if (profile != null) {
          _userProfile = profile;
        } else {
          // Create initial fallback profile if missing
          _userProfile = UserProfile(
            uid: user.uid,
            email: user.email ?? '',
            displayName: user.displayName ?? (user.email != null ? user.email!.split('@').first : 'Rider User'),
            phoneNumber: user.phoneNumber ?? '',
            role: 'Rider',
          );
        }
        notifyListeners();
      });
    } else {
      _userProfile = null;
    }
  }

  Future<void> updateUserProfileDetails({
    String? displayName,
    String? phoneNumber,
    String? bio,
  }) async {
    // 1. Update local state immediately for fast UI response
    if (_userProfile != null) {
      _userProfile = _userProfile!.copyWith(
        displayName: displayName,
        phoneNumber: phoneNumber,
        bio: bio,
      );
      notifyListeners();
    } else if (_firebaseUser != null) {
      _userProfile = UserProfile(
        uid: _firebaseUser!.uid,
        email: activeUserEmail,
        displayName: displayName ?? activeUserDisplayName,
        phoneNumber: phoneNumber ?? '',
        bio: bio ?? '',
        role: activeUserRole,
      );
      notifyListeners();
    }

    // 2. Persist to Firestore backend & Firebase Auth user record
    if (_firebaseUser != null) {
      try {
        final updates = <String, dynamic>{};
        if (displayName != null) {
          updates['displayName'] = displayName;
          try {
            await _firebaseUser!.updateDisplayName(displayName);
          } catch (_) {}
        }
        if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
        if (bio != null) updates['bio'] = bio;

        await _firestoreService.saveUserProfile(_firebaseUser!.uid, updates);
      } catch (e) {
        print('Firestore Save Profile Warning: $e');
      }
    }
  }

  Future<void> toggleUserRole() async {
    if (_firebaseUser == null) return;
    final newRole = activeUserRole == 'Host' ? 'Rider' : 'Host';
    await _firestoreService.updateUserRole(_firebaseUser!.uid, newRole);
  }

  void _initFirestoreSync() async {
    try {
      // Seed sample vehicles & tours commented out (App starts from 0)
      // await _firestoreService.seedVehiclesIfEmpty(_vehicles);
      // await _firestoreService.seedToursIfEmpty(_tours);

      // Listen to real-time vehicles stream from Firestore
      _firestoreService.streamVehicles().listen((firestoreVehicles) {
        _vehicles = firestoreVehicles;
        notifyListeners();
      });

      // Listen to real-time tours stream from Firestore
      _firestoreService.streamTours().listen((firestoreTours) {
        _tours = firestoreTours;
        notifyListeners();
      });
    } catch (e) {
      print('Firestore Sync Init Warning: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
      _firebaseUser = null;
      _userProfile = null;
      _userProfileSubscription?.cancel();
      notifyListeners();
    } catch (_) {}
  }


  // Theme mode state
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  // Navigation Index
  int _currentNavIndex = 0;
  int get currentNavIndex => _currentNavIndex;

  void setNavIndex(int index) {
    _currentNavIndex = index;
    notifyListeners();
  }

  // Search Filter state
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  String _selectedLocation = 'San Francisco, CA';
  String get selectedLocation => _selectedLocation;

  String _selectedCategory = 'All';
  String get selectedCategory => _selectedCategory;

  void updateSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void updateLocation(String loc) {
    _selectedLocation = loc;
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  // Sample Vehicles Mock Data (Commented out to start from 0 for fresh user/seller onboarding)
  List<Vehicle> _vehicles = [
    /*
    Vehicle(
      id: 'v1',
      title: 'BMW R1250 GS Adventure',
      type: VehicleType.bike,
      category: 'Adventure Bike',
      pricePerDay: 129.00,
      rating: 4.95,
      reviewCount: 48,
      imageUrl: 'https://images.unsplash.com/photo-1558981403-c5f9899a28bc?w=800&q=80',
      location: 'San Francisco, CA',
      hostName: 'Alex Rivera',
      hostAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&q=80',
      hostTrustScore: 98.5,
      fuelType: 'Gasoline',
      transmission: 'Manual 6-Speed',
      seats: 2,
      description: 'Ultimate touring adventure motorcycle equipped with top-case, heated grips, cruise control, and dynamic ESA.',
      iotData: {
        'locked': true,
        'engineOn': false,
        'batteryLevel': 94,
        'odometer': 12480,
        'tirePressureFront': 36.2,
        'tirePressureRear': 41.5,
        'lat': 37.7749,
        'lng': -122.4194,
      },
    ),
    Vehicle(
      id: 'v2',
      title: 'Tesla Model 3 Performance',
      type: VehicleType.car,
      category: 'Electric Sedan',
      pricePerDay: 145.00,
      rating: 4.92,
      reviewCount: 86,
      imageUrl: 'https://images.unsplash.com/photo-1560958089-b8a1929cea89?w=800&q=80',
      location: 'San Jose, CA',
      hostName: 'Elena Rostova',
      hostAvatar: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=200&q=80',
      hostTrustScore: 99.0,
      fuelType: 'Electric 82kWh',
      transmission: 'Automatic Single-Speed',
      seats: 5,
      description: 'Dual motor AWD Tesla with Full Self-Driving preview, premium interior, and sub-3.1s 0-60 acceleration.',
      iotData: {
        'locked': true,
        'engineOn': false,
        'batteryLevel': 88,
        'odometer': 28400,
        'tirePressureFront': 42.0,
        'tirePressureRear': 42.1,
        'lat': 37.3382,
        'lng': -121.8863,
      },
    ),
    Vehicle(
      id: 'v3',
      title: 'Ducati Panigale V4 S',
      type: VehicleType.bike,
      category: 'Superbike',
      pricePerDay: 189.00,
      rating: 4.88,
      reviewCount: 32,
      imageUrl: 'https://images.unsplash.com/photo-1568772585407-9361f9bf3a87?w=800&q=80',
      location: 'Los Angeles, CA',
      hostName: 'Marco Rossi',
      hostAvatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&q=80',
      hostTrustScore: 97.2,
      fuelType: 'Gasoline (Premium)',
      transmission: 'Quickshift 6-Speed',
      seats: 1,
      description: 'Italian thoroughbred superbike delivering 214 HP. Öhlins electronic suspension, Brembo Stylema brakes.',
      iotData: {
        'locked': true,
        'engineOn': false,
        'batteryLevel': 90,
        'odometer': 6200,
        'tirePressureFront': 34.0,
        'tirePressureRear': 36.0,
        'lat': 34.0522,
        'lng': -118.2437,
      },
    ),
    Vehicle(
      id: 'v4',
      title: 'Vespa Elettrica 70km/h',
      type: VehicleType.scooter,
      category: 'Urban E-Scooter',
      pricePerDay: 49.00,
      rating: 4.97,
      reviewCount: 112,
      imageUrl: 'https://images.unsplash.com/photo-1558981806-ec527fa84c39?w=800&q=80',
      location: 'San Francisco, CA',
      hostName: 'Chloe Bennett',
      hostAvatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200&q=80',
      hostTrustScore: 99.5,
      fuelType: 'Electric',
      transmission: 'Automatic',
      seats: 2,
      description: 'Iconic Italian style meets silent electric mobility. Easy keyless startup, built-in storage helmet included.',
      iotData: {
        'locked': false,
        'engineOn': false,
        'batteryLevel': 99,
        'odometer': 3100,
        'tirePressureFront': 29.0,
        'tirePressureRear': 32.0,
        'lat': 37.7749,
        'lng': -122.4194,
      },
    ),
    Vehicle(
      id: 'v5',
      title: 'Porsche 911 Carrera S Convertible',
      type: VehicleType.car,
      category: 'Sports Convertible',
      pricePerDay: 295.00,
      rating: 4.98,
      reviewCount: 64,
      imageUrl: 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=800&q=80',
      location: 'Monterey, CA',
      hostName: 'Alex Rivera',
      hostAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&q=80',
      hostTrustScore: 98.5,
      fuelType: 'Gasoline Premium',
      transmission: 'PDK 8-Speed',
      seats: 4,
      description: 'The definitive sports car experience along Coast Highway 1. PDK dual-clutch, Sport Chrono package.',
      iotData: {
        'locked': true,
        'engineOn': false,
        'batteryLevel': 92,
        'odometer': 15200,
        'tirePressureFront': 33.5,
        'tirePressureRear': 38.0,
        'lat': 36.6002,
        'lng': -121.8947,
      },
    ),
    */
  ];

  List<Vehicle> get vehicles => _vehicles;

  List<Vehicle> get favoriteVehicles => _vehicles.where((v) => v.isFavorite).toList();

  void toggleFavoriteVehicle(String id) {
    final index = _vehicles.indexWhere((v) => v.id == id);
    if (index != -1) {
      _vehicles[index] = _vehicles[index].copyWith(isFavorite: !_vehicles[index].isFavorite);
      notifyListeners();
    }
  }

  // IoT Remote Controls
  void toggleIoTLock(String vehicleId) {
    final index = _vehicles.indexWhere((v) => v.id == vehicleId);
    if (index != -1) {
      final currentIot = Map<String, dynamic>.from(_vehicles[index].iotData);
      currentIot['locked'] = !(currentIot['locked'] as bool);
      _vehicles[index] = _vehicles[index].copyWith(iotData: currentIot);
      notifyListeners();

      // Sync to Firestore
      try {
        _firestoreService.updateVehicleIoTData(vehicleId, currentIot);
      } catch (_) {}
    }
  }

  void toggleIoTEngine(String vehicleId) {
    final index = _vehicles.indexWhere((v) => v.id == vehicleId);
    if (index != -1) {
      final currentIot = Map<String, dynamic>.from(_vehicles[index].iotData);
      currentIot['engineOn'] = !(currentIot['engineOn'] as bool);
      _vehicles[index] = _vehicles[index].copyWith(iotData: currentIot);
      notifyListeners();

      // Sync to Firestore
      try {
        _firestoreService.updateVehicleIoTData(vehicleId, currentIot);
      } catch (_) {}
    }
  }

  // Sample Tours (Commented out to start from 0)
  List<Tour> _tours = [
    /*
    Tour(
      id: 't1',
      title: 'Pacific Coast Highway Motorcycle Run',
      location: 'Big Sur to Monterey, CA',
      price: 199.00,
      duration: 'Full Day (6 hrs)',
      rating: 4.96,
      reviewCount: 54,
      imageUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=800&q=80',
      guideName: 'Alex Rivera',
      guideAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&q=80',
      waypoints: ['Bixby Creek Bridge', 'Nepenthe Overlook', 'Pfeiffer Beach', 'Carmel Valley'],
      includedGear: ['Full Face Helmet', 'Bluetooth Intercom', 'GoPro Mount', 'Roadside Assist'],
      description: 'Ride along dramatic ocean cliffs with an experienced local guide. Includes stops at scenic viewpoints and seaside cafe lunch.',
    ),
    Tour(
      id: 't2',
      title: 'Napa Valley Sunset Luxury Drive',
      location: 'Napa & Sonoma, CA',
      price: 249.00,
      duration: 'Half Day (4 hrs)',
      rating: 4.99,
      reviewCount: 39,
      imageUrl: 'https://images.unsplash.com/photo-1510812431401-41d2bd2722f3?w=800&q=80',
      guideName: 'Elena Rostova',
      guideAvatar: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=200&q=80',
      waypoints: ['St. Helena Highway', 'Silverado Trail', 'Castello di Amorosa', 'Yountville'],
      includedGear: ['VIP Vineyard Access', 'Private Sommelier Stop', 'EV Charging Support'],
      description: 'Experience rolling vineyard hills and world-class estate stops in a high-performance EV or classic convertible.',
    ),
    */
  ];

  List<Tour> get tours => _tours;

  void toggleFavoriteTour(String id) {
    final index = _tours.indexWhere((t) => t.id == id);
    if (index != -1) {
      _tours[index] = _tours[index].copyWith(isFavorite: !_tours[index].isFavorite);
      notifyListeners();
    }
  }

  // Chat Threads (Commented out to start from 0)
  List<ChatThread> _chatThreads = [
    /*
    ChatThread(
      id: 'c1',
      partnerName: 'Alex Rivera',
      partnerAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&q=80',
      lastMessage: 'Keyless unlock code generated for your BMW R1250 GS!',
      lastTime: DateTime.now().subtract(const Duration(minutes: 12)),
      unreadCount: 1,
      vehicleTitle: 'BMW R1250 GS Adventure',
      messages: [
        ChatMessage(id: 'm1', senderId: 'host', text: 'Hi! Ready for your trip today?', timestamp: DateTime.now().subtract(const Duration(hours: 2)), isUser: false),
        ChatMessage(id: 'm2', senderId: 'user', text: 'Yes! Arriving at pickup location in 15 mins.', timestamp: DateTime.now().subtract(const Duration(hours: 1)), isUser: true),
        ChatMessage(id: 'm3', senderId: 'host', text: 'Keyless unlock code generated for your BMW R1250 GS!', timestamp: DateTime.now().subtract(const Duration(minutes: 12)), isUser: false),
      ],
    ),
    ChatThread(
      id: 'c2',
      partnerName: 'Elena Rostova',
      partnerAvatar: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=200&q=80',
      lastMessage: 'Supercharger adapter is in the trunk container.',
      lastTime: DateTime.now().subtract(const Duration(hours: 5)),
      unreadCount: 0,
      vehicleTitle: 'Tesla Model 3 Performance',
      messages: [
        ChatMessage(id: 'm1', senderId: 'user', text: 'Where is the charging adapter?', timestamp: DateTime.now().subtract(const Duration(hours: 6)), isUser: true),
        ChatMessage(id: 'm2', senderId: 'host', text: 'Supercharger adapter is in the trunk container.', timestamp: DateTime.now().subtract(const Duration(hours: 5)), isUser: false),
      ],
    ),
    */
  ];

  List<ChatThread> get chatThreads => _chatThreads;

  void sendMessage(String threadId, String text) {
    final index = _chatThreads.indexWhere((t) => t.id == threadId);
    if (index != -1) {
      final newMessage = ChatMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        senderId: _firebaseUser?.uid ?? 'user',
        text: text,
        timestamp: DateTime.now(),
        isUser: true,
      );
      _chatThreads[index].messages.add(newMessage);
      notifyListeners();

      // Sync message to Firestore
      try {
        _firestoreService.sendChatMessage(threadId, newMessage);
      } catch (_) {}
    }
  }

  // Documents (Commented out to start from 0)
  List<ComplianceDocument> _documents = [
    /*
    ComplianceDocument(id: 'd1', title: 'Driver License Verification', status: 'Verified', expiryDate: DateTime(2028, 06, 15), type: 'ID'),
    ComplianceDocument(id: 'd2', title: 'Commercial Rental Insurance', status: 'Verified', expiryDate: DateTime(2027, 03, 10), type: 'Insurance'),
    ComplianceDocument(id: 'd3', title: 'Vehicle Safety Inspection', status: 'Verified', expiryDate: DateTime(2026, 12, 01), type: 'Inspection'),
    */
  ];

  List<ComplianceDocument> get documents => _documents;

  // ==========================================
  // REAL WORKFLOW INTEGRATION STATE & METHODS
  // ==========================================

  Vehicle? _selectedVehicle;
  Vehicle? get selectedVehicle => _selectedVehicle ?? (_vehicles.isNotEmpty ? _vehicles.first : null);

  void selectVehicle(Vehicle vehicle) {
    _selectedVehicle = vehicle;
    notifyListeners();
  }

  DateTime _pickupDateTime = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day + 1, 10, 0);
  DateTime _dropoffDateTime = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day + 3, 18, 0);

  DateTime get pickupDateTime => _pickupDateTime;
  DateTime get dropoffDateTime => _dropoffDateTime;

  DateTime get rentalStartDate => _pickupDateTime;
  DateTime get rentalEndDate => _dropoffDateTime;

  int get rentalDaysCount {
    final diff = _dropoffDateTime.difference(_pickupDateTime).inDays;
    return diff <= 0 ? 1 : diff;
  }

  void setRentalDates(DateTime start, DateTime end) {
    _pickupDateTime = start;
    _dropoffDateTime = end;
    notifyListeners();
  }

  void setPickupAndDropoff(DateTime pickup, DateTime dropoff) {
    _pickupDateTime = pickup;
    _dropoffDateTime = dropoff;
    notifyListeners();
  }

  // Active Bookings List (Commented out to start from 0)
  List<Booking> _activeBookings = [
    /*
    Booking(
      id: 'b101',
      vehicleId: 'v1',
      vehicleTitle: 'BMW R1250 GS Adventure',
      vehicleImageUrl: 'https://images.unsplash.com/photo-1558981403-c5f9899a28bc?w=800&q=80',
      hostName: 'Alex Rivera',
      startDate: DateTime.now().subtract(const Duration(days: 1)),
      endDate: DateTime.now().add(const Duration(days: 2)),
      totalPrice: 387.00,
      status: 'Active',
      unlockPasscode: 'PASS-8921',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    */
  ];

  List<Booking> get activeBookings => _activeBookings;

  /// Check if a vehicle is already booked during [start] to [end]
  bool isVehicleBookedDuring(String vehicleId, DateTime? start, DateTime? end) {
    final s = start ?? pickupDateTime;
    final e = end ?? dropoffDateTime;
    return _activeBookings.any((booking) {
      if (booking.vehicleId != vehicleId || booking.status == 'Cancelled') {
        return false;
      }
      final dynamic bStart = booking.startDate;
      final dynamic bEnd = booking.endDate;
      if (bStart is! DateTime || bEnd is! DateTime) return false;
      // Check date range overlap
      return s.isBefore(bEnd) && e.isAfter(bStart);
    });
  }

  /// Get the free-up DateTime when the vehicle will be available next
  DateTime? getVehicleFreeUpTime(String vehicleId) {
    final vehicleBookings = _activeBookings.where((b) {
      final dynamic bEnd = b.endDate;
      return b.vehicleId == vehicleId && b.status != 'Cancelled' && bEnd is DateTime;
    }).toList();
    if (vehicleBookings.isEmpty) return null;

    vehicleBookings.sort((a, b) => b.endDate.compareTo(a.endDate));
    return vehicleBookings.first.endDate;
  }

  // Total Earnings State (Initialized to 0 for fresh host onboarding)
  double _totalEarnings = 0.00;
  double get totalEarnings => _totalEarnings;

  void withdrawEarnings(double amount) {
    if (amount <= _totalEarnings) {
      _totalEarnings -= amount;
      notifyListeners();
    }
  }

  // AI Tour Draft Transfer
  Tour? _draftTourFromAi;
  Tour? get draftTourFromAi => _draftTourFromAi;

  void setDraftTourFromAi(Tour tour) {
    _draftTourFromAi = tour;
    notifyListeners();
  }

  void clearDraftTourFromAi() {
    _draftTourFromAi = null;
    notifyListeners();
  }

  // Add Vehicle Workflow (Host publishing listing)
  Future<void> addVehicle(Vehicle vehicle) async {
    _vehicles.insert(0, vehicle);
    notifyListeners();

    try {
      await _firestoreService.saveVehicle(vehicle);
    } catch (_) {}
  }

  // Update Vehicle (Host updating existing vehicle details)
  Future<void> updateVehicle(Vehicle updatedVehicle) async {
    final index = _vehicles.indexWhere((v) => v.id == updatedVehicle.id);
    if (index != -1) {
      _vehicles[index] = updatedVehicle;
      notifyListeners();
    }
    try {
      await _firestoreService.saveVehicle(updatedVehicle);
    } catch (e) {
      print('Update vehicle error: $e');
    }
  }

  // Delete Vehicle (Host removing listing permanently)
  Future<void> deleteVehicle(String vehicleId) async {
    _vehicles.removeWhere((v) => v.id == vehicleId);
    if (_selectedVehicle?.id == vehicleId) {
      _selectedVehicle = null;
    }
    notifyListeners();
    try {
      await _firestoreService.deleteVehicle(vehicleId);
    } catch (e) {
      print('Delete vehicle error: $e');
    }
  }

  // Add Tour Workflow (Publishing tour to marketplace)
  Future<void> addTour(Tour tour) async {
    _tours.insert(0, tour);
    notifyListeners();

    try {
      await _firestoreService.saveTour(tour);
    } catch (_) {}
  }

  // Update Tour (Guide editing tour details)
  Future<void> updateTour(Tour updatedTour) async {
    final index = _tours.indexWhere((t) => t.id == updatedTour.id);
    if (index != -1) {
      _tours[index] = updatedTour;
      notifyListeners();
    }
    try {
      await _firestoreService.saveTour(updatedTour);
    } catch (e) {
      print('Update tour error: $e');
    }
  }

  // Delete Tour (Guide deleting tour listing)
  Future<void> deleteTour(String tourId) async {
    _tours.removeWhere((t) => t.id == tourId);
    notifyListeners();
    try {
      await _firestoreService.deleteTour(tourId);
    } catch (e) {
      print('Delete tour error: $e');
    }
  }

  // Create Booking Workflow (Renter checkout completion)
  Future<Booking> createBooking({
    required Vehicle vehicle,
    required DateTime startDate,
    required DateTime endDate,
    required double totalPrice,
  }) async {
    final passcode = 'PASS-${1000 + (DateTime.now().millisecondsSinceEpoch % 8999)}';
    final bookingId = 'b_${DateTime.now().millisecondsSinceEpoch}';

    final newBooking = Booking(
      id: bookingId,
      vehicleId: vehicle.id,
      vehicleTitle: vehicle.title,
      vehicleImageUrl: vehicle.imageUrl,
      hostName: vehicle.hostName,
      startDate: startDate,
      endDate: endDate,
      totalPrice: totalPrice,
      status: 'Confirmed',
      unlockPasscode: passcode,
      createdAt: DateTime.now(),
    );

    _activeBookings.insert(0, newBooking);
    _totalEarnings += totalPrice;

    // Create or find chat thread with Host
    final threadId = 'c_${vehicle.hostName.toLowerCase().replaceAll(' ', '_')}';
    final existingThreadIndex = _chatThreads.indexWhere((t) => t.id == threadId);

    final passcodeMessage = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: 'system',
      text: '🔑 Booking confirmed for ${vehicle.title}! Your keyless unlock passcode is $passcode. Enjoy your ride!',
      timestamp: DateTime.now(),
      isUser: false,
    );

    if (existingThreadIndex != -1) {
      _chatThreads[existingThreadIndex].messages.add(passcodeMessage);
    } else {
      _chatThreads.insert(
        0,
        ChatThread(
          id: threadId,
          partnerName: vehicle.hostName,
          partnerAvatar: vehicle.hostAvatar,
          lastMessage: passcodeMessage.text,
          lastTime: DateTime.now(),
          unreadCount: 1,
          vehicleTitle: vehicle.title,
          messages: [passcodeMessage],
        ),
      );
    }

    notifyListeners();

    // Persist to Firestore
    try {
      await _firestoreService.createBooking(
        userId: _firebaseUser?.uid ?? 'guest_user',
        vehicleId: vehicle.id,
        startDate: startDate,
        endDate: endDate,
        totalPrice: totalPrice,
      );
      await _firestoreService.sendChatMessage(threadId, passcodeMessage);
    } catch (_) {}

    return newBooking;
  }
}
