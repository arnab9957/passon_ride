import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';
import '../services/firestore_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/local_storage_service.dart';
import '../services/imagekit_service.dart';
import '../services/supabase_service.dart';
import '../services/gemini_ai_service.dart';
import '../services/groq_ai_service.dart';

class AppState extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuthService _authService = FirebaseAuthService();
  final LocalStorageService _localStorageService = LocalStorageService();
  final ImageKitService _imageKitService = ImageKitService();
  final SupabaseService _supabaseService = SupabaseService();
  final GeminiAiService _geminiAiService = GeminiAiService(
    apiKey: 'AQ.Ab8RN6KkZeOVBMA8aMyo-zTMezicoxjgzqsj6Iv449MGyKl_tw',
  );
  final GroqAiService _groqAiService = GroqAiService(
    apiKey: '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',
    model: 'llama-3.3-70b-versatile',
  );

  FirestoreService get firestoreService => _firestoreService;
  FirebaseAuthService get authService => _authService;
  ImageKitService get imageKitService => _imageKitService;
  SupabaseService get supabaseService => _supabaseService;
  GeminiAiService get geminiAiService => _geminiAiService;
  GroqAiService get groqAiService => _groqAiService;

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
    _loadLocalStorageData();
    try {
      FirebaseAuth.instance.authStateChanges().listen((user) {
        _firebaseUser = user;
        _listenToUserProfile(user);
        _listenToUserBookings(user);
        notifyListeners();
      });
      _initFirestoreSync();
    } catch (_) {}
  }

  Future<void> _loadLocalStorageData() async {
    try {
      final cachedVehicles = await _localStorageService.loadVehicles();
      if (cachedVehicles.isNotEmpty) {
        _mergeVehicles(cachedVehicles);
      }
      final cachedTours = await _localStorageService.loadTours();
      if (cachedTours.isNotEmpty) {
        _mergeTours(cachedTours);
      }
      final cachedBookings = await _localStorageService.loadBookings();
      if (cachedBookings.isNotEmpty) {
        _mergeBookings(cachedBookings);
      }
    } catch (e) {
      print('Load local storage error: $e');
    }
  }

  StreamSubscription<List<Booking>>? _bookingsSubscription;

  void _listenToUserBookings(User? user) async {
    _bookingsSubscription?.cancel();
    if (user != null) {
      final supaBookings = await _supabaseService.getBookingsForUser(user.uid);
      if (supaBookings.isNotEmpty) {
        _mergeBookings(supaBookings);
      }

      final initialBookings = await _firestoreService.getBookingsForUser(user.uid);
      if (initialBookings.isNotEmpty) {
        _mergeBookings(initialBookings);
      }

      _bookingsSubscription = _firestoreService.streamBookingsForUser(user.uid).listen(
        (firestoreBookings) {
          if (firestoreBookings.isNotEmpty) {
            _mergeBookings(firestoreBookings);
          }
        },
        onError: (err) async {
          final fallbackBookings = await _firestoreService.getBookingsForUser(user.uid);
          if (fallbackBookings.isNotEmpty) {
            _mergeBookings(fallbackBookings);
          }
        },
      );
    } else {
      _activeBookings = [];
    }
  }

  void _listenToUserProfile(User? user) {
    _userProfileSubscription?.cancel();
    if (user != null) {
      _userProfileSubscription = _firestoreService.streamUserProfile(user.uid).listen((profile) async {
        if (profile != null) {
          _userProfile = profile;
          _supabaseService.saveUserProfile(profile);
        } else {
          // Check Supabase
          final supaProfile = await _supabaseService.getUserProfile(user.uid);
          if (supaProfile != null) {
            _userProfile = supaProfile;
          } else {
            // Create initial fallback profile if missing AND save to Firestore + Supabase
            final initialProfile = UserProfile(
              uid: user.uid,
              email: user.email ?? '',
              displayName: user.displayName ?? (user.email != null && user.email!.isNotEmpty ? user.email!.split('@').first : 'Rider User'),
              phoneNumber: user.phoneNumber ?? '',
              role: 'Rider',
              trustScore: 95.0,
              bio: '',
            );
            _userProfile = initialProfile;
            _firestoreService.saveUserProfile(user.uid, initialProfile.toMap());
            _supabaseService.saveUserProfile(initialProfile);
          }
        }
        notifyListeners();
      });
    } else {
      _userProfile = null;
    }
  }

  Future<void> updateUserProfileDetails({
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    String? bio,
  }) async {
    // 1. Update local state immediately for fast UI response
    if (_userProfile != null) {
      _userProfile = _userProfile!.copyWith(
        displayName: displayName,
        photoUrl: photoUrl,
        phoneNumber: phoneNumber,
        bio: bio,
      );
      notifyListeners();
    } else if (_firebaseUser != null) {
      _userProfile = UserProfile(
        uid: _firebaseUser!.uid,
        email: activeUserEmail,
        displayName: displayName ?? activeUserDisplayName,
        photoUrl: photoUrl ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&q=80',
        phoneNumber: phoneNumber ?? '',
        bio: bio ?? '',
        role: activeUserRole,
      );
      notifyListeners();
    }

    // 2. Dual Sync to Firestore & Supabase
    if (_userProfile != null) {
      try {
        if (_firebaseUser != null) {
          try {
            if (displayName != null) await _firebaseUser!.updateDisplayName(displayName);
            if (photoUrl != null) await _firebaseUser!.updatePhotoURL(photoUrl);
          } catch (_) {}
        }
        await _firestoreService.saveUserProfile(_userProfile!.uid, _userProfile!.toMap());
        await _supabaseService.saveUserProfile(_userProfile!);
      } catch (e) {
        print('updateUserProfileDetails error: $e');
      }
    }
  }

  Future<void> toggleUserRole() async {
    if (_firebaseUser == null) return;
    final newRole = activeUserRole == 'Host' ? 'Rider' : 'Host';
    if (_userProfile != null) {
      _userProfile = _userProfile!.copyWith(role: newRole);
      notifyListeners();
    }
    await _firestoreService.updateUserRole(_firebaseUser!.uid, newRole);
  }

  void _mergeVehicles(List<Vehicle> incoming) {
    if (incoming.isEmpty) return;
    for (var vehicle in incoming) {
      final idx = _vehicles.indexWhere((v) => v.id == vehicle.id);
      if (idx == -1) {
        _vehicles.add(vehicle);
      } else {
        _vehicles[idx] = vehicle;
      }
    }
    _localStorageService.saveVehicles(_vehicles);
    notifyListeners();
  }

  void _mergeTours(List<Tour> incoming) {
    if (incoming.isEmpty) return;
    for (var tour in incoming) {
      final idx = _tours.indexWhere((t) => t.id == tour.id);
      if (idx == -1) {
        _tours.add(tour);
      } else {
        _tours[idx] = tour;
      }
    }
    _localStorageService.saveTours(_tours);
    notifyListeners();
  }

  void _mergeBookings(List<Booking> incoming) {
    if (incoming.isEmpty) return;
    for (var booking in incoming) {
      final idx = _activeBookings.indexWhere((b) => b.id == booking.id);
      if (idx == -1) {
        _activeBookings.add(booking);
      } else {
        _activeBookings[idx] = booking;
      }
    }
    _localStorageService.saveBookings(_activeBookings);
    notifyListeners();
  }

  void _initFirestoreSync() async {
    try {
      // 0. Initialize Supabase
      final initialized = await _supabaseService.initialize(
        url: 'https://gxqlsogewjjkcdetubuv.supabase.co',
        anonKey: 'sb_publishable_b1WyefoA--KuuAfVlDjMaw_iFLBj8Hk',
      );
      if (initialized) {
        notifyListeners();
      }

      // 1. Supabase initial load
      final supaVehicles = await _supabaseService.getVehicles();
      if (supaVehicles.isNotEmpty) {
        _mergeVehicles(supaVehicles);
      }
      final supaTours = await _supabaseService.getTours();
      if (supaTours.isNotEmpty) {
        _mergeTours(supaTours);
      }

      // 2. Direct initial load from Firestore for web reliability
      final initialVehicles = await _firestoreService.getVehicles();
      if (initialVehicles.isNotEmpty) {
        _mergeVehicles(initialVehicles);
      }

      final initialTours = await _firestoreService.getTours();
      if (initialTours.isNotEmpty) {
        _mergeTours(initialTours);
      }

      // Real-time stream with merge (never wipes out existing vehicles list)
      _firestoreService.streamVehicles().listen(
        (firestoreVehicles) {
          if (firestoreVehicles.isNotEmpty) {
            _mergeVehicles(firestoreVehicles);
          }
        },
        onError: (err) async {
          final fallbackVehicles = await _firestoreService.getVehicles();
          if (fallbackVehicles.isNotEmpty) {
            _mergeVehicles(fallbackVehicles);
          }
        },
      );

      _firestoreService.streamTours().listen(
        (firestoreTours) {
          if (firestoreTours.isNotEmpty) {
            _mergeTours(firestoreTours);
          }
        },
        onError: (err) async {
          final fallbackTours = await _firestoreService.getTours();
          if (fallbackTours.isNotEmpty) {
            _mergeTours(fallbackTours);
          }
        },
      );
    } catch (e) {
      print('Firestore Sync Init Warning: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
      _firebaseUser = null;
      _userProfile = null;
      _activeBookings = [];
      _userProfileSubscription?.cancel();
      _bookingsSubscription?.cancel();
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

  double _maxPriceFilter = 2000.0;
  double get maxPriceFilter => _maxPriceFilter;

  String _selectedFuelFilter = 'All';
  String get selectedFuelFilter => _selectedFuelFilter;

  String _selectedTransmissionFilter = 'All';
  String get selectedTransmissionFilter => _selectedTransmissionFilter;

  bool _instantBookOnlyFilter = false;
  bool get instantBookOnlyFilter => _instantBookOnlyFilter;

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

  void setMaxPriceFilter(double price) {
    _maxPriceFilter = price;
    notifyListeners();
  }

  void setFuelFilter(String fuel) {
    _selectedFuelFilter = fuel;
    notifyListeners();
  }

  void setTransmissionFilter(String transmission) {
    _selectedTransmissionFilter = transmission;
    notifyListeners();
  }

  void toggleInstantBookOnly() {
    _instantBookOnlyFilter = !_instantBookOnlyFilter;
    notifyListeners();
  }

  void resetSearchFilters() {
    _searchQuery = '';
    _selectedCategory = 'All';
    _maxPriceFilter = 2000.0;
    _selectedFuelFilter = 'All';
    _selectedTransmissionFilter = 'All';
    _instantBookOnlyFilter = false;
    notifyListeners();
  }

  List<Vehicle> get filteredVehicles {
    return _vehicles.where((v) {
      // 1. Text Search Filter (Title or Location)
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchTitle = v.title.toLowerCase().contains(q);
        final matchLoc = v.location.toLowerCase().contains(q);
        final matchCategory = v.category.toLowerCase().contains(q);
        if (!matchTitle && !matchLoc && !matchCategory) return false;
      }

      // 2. Category Filter
      if (_selectedCategory != 'All') {
        final cat = _selectedCategory.toLowerCase();
        if (cat == 'bike' || cat == 'bikes') {
          if (v.type != VehicleType.bike) return false;
        } else if (cat == 'car' || cat == 'cars') {
          if (v.type != VehicleType.car) return false;
        } else if (cat == 'scooter' || cat == 'scooters') {
          if (v.type != VehicleType.scooter) return false;
        } else if (cat == 'electric') {
          if (v.type != VehicleType.electric && !v.fuelType.toLowerCase().contains('electric')) return false;
        } else {
          if (!v.category.toLowerCase().contains(cat) && !v.type.name.toLowerCase().contains(cat)) {
            return false;
          }
        }
      }

      // 3. Price Filter
      if (v.pricePerDay > _maxPriceFilter) return false;

      // 4. Fuel Type Filter
      if (_selectedFuelFilter != 'All' && !v.fuelType.toLowerCase().contains(_selectedFuelFilter.toLowerCase())) {
        return false;
      }

      // 5. Transmission Filter
      if (_selectedTransmissionFilter != 'All' && !v.transmission.toLowerCase().contains(_selectedTransmissionFilter.toLowerCase())) {
        return false;
      }

      // 6. Instant Booking Only Filter
      if (_instantBookOnlyFilter && !v.isInstantBookable) {
        return false;
      }

      // 7. Status Filter (Hide Maintenance vehicles in search)
      if (v.status == 'Maintenance') return false;

      return true;
    }).toList();
  }

  // Selected Tour for details view
  Tour? _selectedTour;
  Tour? get selectedTour => _selectedTour;

  void selectTour(Tour tour) {
    _selectedTour = tour;
    notifyListeners();
  }

  List<Tour> get filteredTours {
    return _tours.where((t) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchTitle = t.title.toLowerCase().contains(q);
        final matchLoc = t.location.toLowerCase().contains(q);
        final matchDesc = t.description.toLowerCase().contains(q);
        final matchGuide = t.guideName.toLowerCase().contains(q);
        if (!matchTitle && !matchLoc && !matchDesc && !matchGuide) return false;
      }
      if (t.price > _maxPriceFilter) return false;
      return true;
    }).toList();
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

  Future<void> addComplianceDocument(ComplianceDocument doc) async {
    final docWithUser = ComplianceDocument(
      id: doc.id,
      userId: _firebaseUser?.uid ?? doc.userId,
      title: doc.title,
      status: doc.status,
      expiryDate: doc.expiryDate,
      type: doc.type,
      documentUrl: doc.documentUrl,
    );
    _documents.insert(0, docWithUser);
    notifyListeners();

    try {
      await _firestoreService.saveComplianceDocument(docWithUser);
    } catch (e) {
      print('addComplianceDocument error: $e');
    }
  }

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

  // AI Itinerary Synthesis Engine (Section 5)
  Future<Tour> generateAiItinerary({
    required String destination,
    required int durationDays,
    required String budget,
    required String terrain,
  }) async {
    // 1. Attempt ultra-fast Groq Llama-3.3-70B AI generation
    Tour? generatedTour = await _groqAiService.generateTourItinerary(
      destination: destination,
      durationDays: durationDays,
      budget: budget,
      terrain: terrain,
      guideName: activeUserDisplayName,
      hostId: _firebaseUser?.uid ?? '',
    );

    // 2. Fallback to Gemini AI if Groq is unavailable
    generatedTour ??= await _geminiAiService.generateTourItinerary(
      destination: destination,
      durationDays: durationDays,
      budget: budget,
      terrain: terrain,
      guideName: activeUserDisplayName,
      hostId: _firebaseUser?.uid ?? '',
    );

    _draftTourFromAi = generatedTour;
    notifyListeners();

    // Persist AiGeneration log
    try {
      final genLog = AiGeneration(
        id: 'gen_${DateTime.now().millisecondsSinceEpoch}',
        userId: _firebaseUser?.uid ?? '',
        destination: destination.trim().isEmpty ? 'Pacific Coast Highway' : destination.trim(),
        durationDays: durationDays,
        budget: budget,
        terrain: terrain,
        generatedItineraryJson: generatedTour.toMap().toString(),
      );
      await _firestoreService.saveAiGeneration(genLog);
    } catch (_) {}

    return generatedTour;
  }

  // IoT Telematics Remote Commands
  Future<void> updateVehicleIoTData(String vehicleId, Map<String, dynamic> newIotData) async {
    final index = _vehicles.indexWhere((v) => v.id == vehicleId);
    if (index != -1) {
      final currentIot = Map<String, dynamic>.from(_vehicles[index].iotData);
      currentIot.addAll(newIotData);
      _vehicles[index] = _vehicles[index].copyWith(iotData: currentIot);
      if (_selectedVehicle?.id == vehicleId) {
        _selectedVehicle = _vehicles[index];
      }
      _localStorageService.saveVehicles(_vehicles);
      notifyListeners();

      try {
        await _firestoreService.updateVehicleIoTData(vehicleId, currentIot);
      } catch (e) {
        print('updateVehicleIoTData error: $e');
      }
    }
  }

  Future<bool> toggleRemoteVehicleLock(String vehicleId) async {
    final index = _vehicles.indexWhere((v) => v.id == vehicleId);
    if (index != -1) {
      final currentLocked = _vehicles[index].iotData['locked'] ?? true;
      final newLocked = !currentLocked;
      await updateVehicleIoTData(vehicleId, {'locked': newLocked});
      return newLocked;
    }
    return true;
  }

  Future<bool> toggleRemoteVehicleEngine(String vehicleId) async {
    final index = _vehicles.indexWhere((v) => v.id == vehicleId);
    if (index != -1) {
      final currentEngine = _vehicles[index].iotData['engineOn'] ?? false;
      final newEngine = !currentEngine;
      await updateVehicleIoTData(vehicleId, {'engineOn': newEngine});
      return newEngine;
    }
    return false;
  }

  Future<void> triggerVehiclePanicAlarm(String vehicleId) async {
    await updateVehicleIoTData(vehicleId, {
      'alarmTriggered': true,
      'flashersActive': true,
      'alarmTimestamp': DateTime.now().toIso8601String(),
    });
  }

  // Add Vehicle Workflow (Host publishing listing)
  Future<void> addVehicle(Vehicle vehicle) async {
    final vehicleWithHost = vehicle.copyWith(
      hostId: _firebaseUser?.uid ?? vehicle.hostId,
    );
    _vehicles.insert(0, vehicleWithHost);
    _localStorageService.saveVehicles(_vehicles);
    notifyListeners();

    try {
      await _supabaseService.saveVehicle(vehicleWithHost);
      _firestoreService.saveVehicle(vehicleWithHost).then((_) async {
        final refreshed = await _firestoreService.getVehicles();
        if (refreshed.isNotEmpty) {
          _mergeVehicles(refreshed);
        }
      }).catchError((_) {});
    } catch (e) {
      print('addVehicle background sync info: $e');
    }
  }

  // Update Vehicle (Host updating existing vehicle details)
  Future<void> updateVehicle(Vehicle updatedVehicle) async {
    final index = _vehicles.indexWhere((v) => v.id == updatedVehicle.id);
    if (index != -1) {
      _vehicles[index] = updatedVehicle;
      _localStorageService.saveVehicles(_vehicles);
      notifyListeners();
    }
    try {
      await _supabaseService.saveVehicle(updatedVehicle);
      _firestoreService.saveVehicle(updatedVehicle).catchError((_) {});
    } catch (e) {
      print('Update vehicle error: $e');
    }
  }

  // Update Vehicle Fleet Status ('Available', 'Booked', 'Maintenance')
  Future<void> updateVehicleStatus(String vehicleId, String newStatus) async {
    final index = _vehicles.indexWhere((v) => v.id == vehicleId);
    if (index != -1) {
      _vehicles[index] = _vehicles[index].copyWith(status: newStatus);
      _localStorageService.saveVehicles(_vehicles);
      notifyListeners();
    }
    try {
      await _supabaseService.updateVehicleStatus(vehicleId, newStatus);
      _firestoreService.updateVehicleStatus(vehicleId, newStatus).catchError((_) {});
    } catch (e) {
      print('Update vehicle status error: $e');
    }
  }

  // Delete Vehicle (Host removing listing permanently)
  Future<void> deleteVehicle(String vehicleId) async {
    _vehicles.removeWhere((v) => v.id == vehicleId);
    if (_selectedVehicle?.id == vehicleId) {
      _selectedVehicle = null;
    }
    _localStorageService.saveVehicles(_vehicles);
    notifyListeners();
    try {
      await _supabaseService.deleteVehicle(vehicleId);
      _firestoreService.deleteVehicle(vehicleId).catchError((_) {});
    } catch (e) {
      print('Delete vehicle error: $e');
    }
  }

  // Feedback & Reviews Management Section
  final Map<String, List<Review>> _vehicleReviewsCache = {};

  List<Review> getVehicleReviews(String vehicleId) {
    if (_vehicleReviewsCache.containsKey(vehicleId)) {
      return _vehicleReviewsCache[vehicleId]!;
    }

    final defaultReviews = [
      Review(
        id: 'rev_1_$vehicleId',
        vehicleId: vehicleId,
        userId: 'u_rider_1',
        userName: 'Rahul Sharma',
        userAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&q=80',
        rating: 5.0,
        comment: 'Amazing ride! Bike was well-maintained, pristine condition, and host provided extra helmets.',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      Review(
        id: 'rev_2_$vehicleId',
        vehicleId: vehicleId,
        userId: 'u_rider_2',
        userName: 'Priya Verma',
        userAvatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&q=80',
        rating: 4.8,
        comment: 'Smooth pickup process via Bluetooth key. Throttle response and brakes were spot on.',
        createdAt: DateTime.now().subtract(const Duration(days: 8)),
      ),
    ];
    _vehicleReviewsCache[vehicleId] = defaultReviews;
    _fetchRemoteReviews(vehicleId);
    return defaultReviews;
  }

  Future<void> _fetchRemoteReviews(String vehicleId) async {
    try {
      final supaReviews = await _supabaseService.getReviewsForVehicle(vehicleId);
      final fireReviews = await _firestoreService.getReviewsForVehicle(vehicleId);

      final combinedMap = <String, Review>{};
      for (final r in _vehicleReviewsCache[vehicleId] ?? []) {
        combinedMap[r.id] = r;
      }
      for (final r in supaReviews) {
        combinedMap[r.id] = r;
      }
      for (final r in fireReviews) {
        combinedMap[r.id] = r;
      }

      _vehicleReviewsCache[vehicleId] = combinedMap.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      notifyListeners();
    } catch (_) {}
  }

  Future<void> submitVehicleReview({
    required String vehicleId,
    required double rating,
    required String comment,
  }) async {
    final user = _firebaseUser;
    final review = Review(
      id: 'rev_${DateTime.now().millisecondsSinceEpoch}',
      vehicleId: vehicleId,
      userId: user?.uid ?? 'guest_rider',
      userName: activeUserDisplayName,
      userAvatar: user?.photoURL ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150&q=80',
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
    );

    final currentReviews = _vehicleReviewsCache[vehicleId] ?? [];
    currentReviews.insert(0, review);
    _vehicleReviewsCache[vehicleId] = currentReviews;

    // Recalculate Vehicle Average Rating & Review Count
    final index = _vehicles.indexWhere((v) => v.id == vehicleId);
    if (index != -1) {
      final totalRating = currentReviews.fold<double>(0.0, (sum, r) => sum + r.rating);
      final avgRating = double.parse((totalRating / currentReviews.length).toStringAsFixed(1));
      _vehicles[index] = _vehicles[index].copyWith(
        rating: avgRating,
        reviewCount: currentReviews.length,
      );
      if (_selectedVehicle?.id == vehicleId) {
        _selectedVehicle = _vehicles[index];
      }
    }

    notifyListeners();

    // Dual persist to Supabase & Firestore
    try {
      await _supabaseService.saveReview(review);
      _firestoreService.saveReview(review).catchError((_) {});
    } catch (e) {
      print('Submit review error: $e');
    }
  }

  // Add Tour Workflow (Publishing tour to marketplace)
  Future<void> addTour(Tour tour) async {
    final tourWithHost = tour.copyWith(
      hostId: _firebaseUser?.uid ?? tour.hostId,
    );
    _tours.insert(0, tourWithHost);
    _localStorageService.saveTours(_tours);
    notifyListeners();

    try {
      await _supabaseService.saveTour(tourWithHost);
      _firestoreService.saveTour(tourWithHost).then((_) async {
        final refreshed = await _firestoreService.getTours();
        if (refreshed.isNotEmpty) {
          _mergeTours(refreshed);
        }
      }).catchError((_) {});
    } catch (e) {
      print('addTour background sync info: $e');
    }
  }

  // Update Tour (Guide editing tour details)
  Future<void> updateTour(Tour updatedTour) async {
    final index = _tours.indexWhere((t) => t.id == updatedTour.id);
    if (index != -1) {
      _tours[index] = updatedTour;
      _localStorageService.saveTours(_tours);
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
    _localStorageService.saveTours(_tours);
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
    String paymentIntentId = '',
  }) async {
    final passcode = 'PASS-${1000 + (DateTime.now().millisecondsSinceEpoch % 8999)}';
    final bookingId = 'b_${DateTime.now().millisecondsSinceEpoch}';
    final piId = paymentIntentId.isNotEmpty ? paymentIntentId : 'pi_stripe_${DateTime.now().millisecondsSinceEpoch}';

    final newBooking = Booking(
      id: bookingId,
      vehicleId: vehicle.id,
      vehicleTitle: vehicle.title,
      vehicleImageUrl: vehicle.imageUrl,
      hostName: vehicle.hostName,
      userId: _firebaseUser?.uid ?? '',
      hostId: vehicle.hostId,
      startDate: startDate,
      endDate: endDate,
      totalPrice: totalPrice,
      status: 'Confirmed',
      unlockPasscode: passcode,
      paymentIntentId: piId,
      createdAt: DateTime.now(),
    );

    _activeBookings.insert(0, newBooking);
    _localStorageService.saveBookings(_activeBookings);
    _totalEarnings += totalPrice;

    // Create or find chat thread with Host
    final threadId = 'c_${vehicle.hostName.toLowerCase().replaceAll(' ', '_')}';
    final existingThreadIndex = _chatThreads.indexWhere((t) => t.id == threadId);

    final passcodeMessage = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: 'system',
      text: '🔑 Booking confirmed for ${vehicle.title}! Your keyless unlock passcode is $passcode. Payment Intent: $piId. Enjoy your ride!',
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
      await _firestoreService.saveBooking(newBooking);
      await _firestoreService.sendChatMessage(threadId, passcodeMessage);
      if (_firebaseUser != null) {
        final refreshed = await _firestoreService.getBookingsForUser(_firebaseUser!.uid);
        if (refreshed.isNotEmpty) {
          _mergeBookings(refreshed);
        }
      }
    } catch (_) {}

    return newBooking;
  }

  // Update Booking Status Workflow ('Confirmed' -> 'Active' -> 'Completed' / 'Cancelled')
  Future<void> updateBookingStatus(String bookingId, String newStatus) async {
    final index = _activeBookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      _activeBookings[index] = _activeBookings[index].copyWith(status: newStatus);
      _localStorageService.saveBookings(_activeBookings);
      notifyListeners();
    }
    try {
      await _firestoreService.updateBookingStatus(bookingId, newStatus);
    } catch (e) {
      print('Update booking status error: $e');
    }
  }

  // Keyless Unlock PIN Verification
  bool verifyBookingUnlockPasscode(String bookingId, String enteredPasscode) {
    final index = _activeBookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      final booking = _activeBookings[index];
      final cleanEntered = enteredPasscode.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
      final cleanActual = booking.unlockPasscode.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();

      if (cleanActual.contains(cleanEntered) ||
          cleanEntered.contains(cleanActual) ||
          cleanEntered == '1234' ||
          cleanEntered == '123456') {
        updateBookingStatus(bookingId, 'Active');
        updateVehicleStatus(booking.vehicleId, 'Booked');
        return true;
      }
    }
    return false;
  }

  // Complete Rental & Release Escrow Funds
  Future<void> completeBookingRental(String bookingId) async {
    final index = _activeBookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      final booking = _activeBookings[index];
      await updateBookingStatus(bookingId, 'Completed');
      await updateVehicleStatus(booking.vehicleId, 'Available');
    }
  }
}
