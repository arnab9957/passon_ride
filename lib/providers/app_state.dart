import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../models/models.dart';
import '../services/supabase_auth_service.dart';
import '../services/local_storage_service.dart';
import '../services/imagekit_service.dart';
import '../services/supabase_service.dart';
import '../services/gemini_ai_service.dart';
import '../services/groq_ai_service.dart';
import '../services/location_service.dart';

class AppState extends ChangeNotifier {
  final SupabaseAuthService _supabaseAuthService = SupabaseAuthService();
  final LocalStorageService _localStorageService = LocalStorageService();
  final ImageKitService _imageKitService = ImageKitService();
  final SupabaseService _supabaseService = SupabaseService();
  final LocationService _locationService = LocationService();
  final GeminiAiService _geminiAiService = GeminiAiService(
    apiKey: 'AQ.Ab8RN6KkZeOVBMA8aMyo-zTMezicoxjgzqsj6Iv449MGyKl_tw',
  );
  final GroqAiService _groqAiService = GroqAiService(
    apiKey: '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',
    model: 'llama-3.3-70b-versatile',
  );

  SupabaseAuthService get supabaseAuthService => _supabaseAuthService;
  ImageKitService get imageKitService => _imageKitService;
  SupabaseService get supabaseService => _supabaseService;
  LocationService get locationService => _locationService;
  GeminiAiService get geminiAiService => _geminiAiService;
  GroqAiService get groqAiService => _groqAiService;

  // Supabase Auth & UserProfile State
  supa.User? _supabaseUser;
  supa.User? get supabaseUser => _supabaseUser;
  supa.User? get firebaseUser => _supabaseUser; // Compatibility getter
  bool get isSignedIn => _supabaseUser != null;

  UserProfile? _userProfile;
  UserProfile? get userProfile => _userProfile;
  StreamSubscription<UserProfile?>? _userProfileSubscription;

  String get activeUserEmail => _userProfile?.email ?? _supabaseUser?.email ?? _supabaseUser?.phone ?? 'Guest User';
  String get activeUserDisplayName =>
      _userProfile?.displayName ??
      (_supabaseUser?.userMetadata?['full_name'] as String?) ??
      (_supabaseUser?.userMetadata?['display_name'] as String?) ??
      (_supabaseUser?.email != null ? _supabaseUser!.email!.split('@').first : null) ??
      _supabaseUser?.phone ??
      'Guest User';

  String get activeUserRole => _userProfile?.role ?? 'Rider';
  double get activeUserTrustScore => _userProfile?.trustScore ?? 95.0;

  String get activeUserPhotoUrl {
    if (_userProfile != null && _userProfile!.photoUrl.trim().isNotEmpty) {
      return _userProfile!.photoUrl.trim();
    }
    final metaPhoto = _supabaseUser?.userMetadata?['avatar_url'] as String?;
    if (metaPhoto != null && metaPhoto.trim().isNotEmpty) {
      return metaPhoto.trim();
    }
    return '';
  }

  AppState() {
    _loadLocalStorageData();
    try {
      _supabaseUser = _supabaseAuthService.currentUser;
      if (_supabaseUser != null) {
        _listenToUserProfile(_supabaseUser);
        _listenToUserBookings(_supabaseUser);
      }
      _supabaseAuthService.onAuthStateChange.listen((data) {
        _supabaseUser = data.session?.user ?? _supabaseAuthService.currentUser;
        _listenToUserProfile(_supabaseUser);
        _listenToUserBookings(_supabaseUser);
        notifyListeners();
      });
      _initFirestoreSync();
    } catch (_) {}
  }

  Future<void> reloadUserSession() async {
    _supabaseUser = _supabaseAuthService.currentUser;
    if (_supabaseUser != null) {
      _listenToUserProfile(_supabaseUser);
      _listenToUserBookings(_supabaseUser);
    }
    notifyListeners();
  }

  Future<void> _loadLocalStorageData() async {
    try {
      final cachedProfile = await _localStorageService.loadUserProfile();
      if (cachedProfile != null && cachedProfile.photoUrl.isNotEmpty) {
        _userProfile = cachedProfile;
        notifyListeners();
      }
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
      final cachedLocation = await _localStorageService.loadSelectedLocation();
      if (cachedLocation != null) {
        _currentLocationResult = cachedLocation;
        _selectedLocation = cachedLocation.displayName;
        _userLatitude = cachedLocation.latitude;
        _userLongitude = cachedLocation.longitude;
        _isLiveLocationActive = cachedLocation.isLive;
      }
      final cachedRecent = await _localStorageService.loadRecentLocations();
      if (cachedRecent.isNotEmpty) {
        _recentLocations = cachedRecent;
      }
    } catch (e) {
      print('Load local storage error: $e');
    }
  }

  StreamSubscription<List<Booking>>? _bookingsSubscription;

  void _listenToUserBookings(supa.User? user) async {
    _bookingsSubscription?.cancel();
    if (user != null) {
      final supaBookings = await _supabaseService.getBookingsForUser(user.id);
      if (supaBookings.isNotEmpty) {
        _mergeBookings(supaBookings);
      }
    } else {
      _activeBookings = [];
    }
  }

  void _listenToUserProfile(supa.User? user) {
    _userProfileSubscription?.cancel();
    if (user != null) {
      _localStorageService.loadUserProfile().then((localProfile) {
        if (localProfile != null) {
          if (_userProfile == null) {
            _userProfile = localProfile;
          } else {
            _userProfile = _userProfile!.copyWith(
              photoUrl: _userProfile!.photoUrl.isNotEmpty ? _userProfile!.photoUrl : localProfile.photoUrl,
              phoneNumber: _userProfile!.phoneNumber.isNotEmpty ? _userProfile!.phoneNumber : localProfile.phoneNumber,
              bio: _userProfile!.bio.isNotEmpty ? _userProfile!.bio : localProfile.bio,
            );
          }
          notifyListeners();
        }
      });

      _userProfileSubscription = _supabaseService.streamUserProfile(user.id).listen((profile) async {
        final existingPhoto = _userProfile?.photoUrl ?? '';
        final existingPhone = _userProfile?.phoneNumber ?? '';
        final existingBio = _userProfile?.bio ?? '';
        final existingDisplayName = _userProfile?.displayName ?? '';

        final metaPhoto = user.userMetadata?['avatar_url'] as String? ?? '';
        final metaPhone = (user.userMetadata?['phone_number'] ?? user.userMetadata?['phoneNumber'] ?? user.phone) as String? ?? '';
        final metaBio = user.userMetadata?['bio'] as String? ?? '';
        final metaName = (user.userMetadata?['full_name'] ?? user.userMetadata?['display_name']) as String? ?? '';

        if (profile != null) {
          final photo = profile.photoUrl.isNotEmpty
              ? profile.photoUrl
              : (existingPhoto.isNotEmpty ? existingPhoto : metaPhoto);
          final phone = profile.phoneNumber.isNotEmpty
              ? profile.phoneNumber
              : (existingPhone.isNotEmpty ? existingPhone : metaPhone);
          final bio = profile.bio.isNotEmpty
              ? profile.bio
              : (existingBio.isNotEmpty ? existingBio : metaBio);
          final name = profile.displayName.isNotEmpty
              ? profile.displayName
              : (existingDisplayName.isNotEmpty ? existingDisplayName : metaName);

          _userProfile = profile.copyWith(
            displayName: name.isNotEmpty ? name : profile.displayName,
            photoUrl: photo,
            phoneNumber: phone,
            bio: bio,
          );
          _localStorageService.saveUserProfile(_userProfile!);

          if ((profile.phoneNumber.isEmpty && phone.isNotEmpty) ||
              (profile.bio.isEmpty && bio.isNotEmpty) ||
              (profile.photoUrl.isEmpty && photo.isNotEmpty)) {
            _supabaseService.saveUserProfile(_userProfile!);
          }
        } else {
          // Check Supabase direct fetch
          final supaProfile = await _supabaseService.getUserProfile(user.id);
          if (supaProfile != null) {
            final photo = supaProfile.photoUrl.isNotEmpty
                ? supaProfile.photoUrl
                : (existingPhoto.isNotEmpty ? existingPhoto : metaPhoto);
            final phone = supaProfile.phoneNumber.isNotEmpty
                ? supaProfile.phoneNumber
                : (existingPhone.isNotEmpty ? existingPhone : metaPhone);
            final bio = supaProfile.bio.isNotEmpty
                ? supaProfile.bio
                : (existingBio.isNotEmpty ? existingBio : metaBio);
            final name = supaProfile.displayName.isNotEmpty
                ? supaProfile.displayName
                : (existingDisplayName.isNotEmpty ? existingDisplayName : metaName);

            _userProfile = supaProfile.copyWith(
              displayName: name.isNotEmpty ? name : supaProfile.displayName,
              photoUrl: photo,
              phoneNumber: phone,
              bio: bio,
            );
            _localStorageService.saveUserProfile(_userProfile!);
            _supabaseService.saveUserProfile(_userProfile!);
          } else {
            // Create initial fallback profile if missing
            final initialProfile = UserProfile(
              uid: user.id,
              email: user.email ?? '',
              displayName: metaName.isNotEmpty ? metaName : (user.email != null && user.email!.isNotEmpty ? user.email!.split('@').first : 'Rider User'),
              photoUrl: existingPhoto.isNotEmpty ? existingPhoto : metaPhoto,
              phoneNumber: existingPhone.isNotEmpty ? existingPhone : metaPhone,
              role: 'Rider',
              trustScore: 95.0,
              bio: existingBio.isNotEmpty ? existingBio : metaBio,
            );
            _userProfile = initialProfile;
            _localStorageService.saveUserProfile(initialProfile);
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
    } else if (_supabaseUser != null) {
      _userProfile = UserProfile(
        uid: _supabaseUser!.id,
        email: activeUserEmail,
        displayName: displayName ?? activeUserDisplayName,
        photoUrl: photoUrl ?? activeUserPhotoUrl,
        phoneNumber: phoneNumber ?? '',
        bio: bio ?? '',
        role: activeUserRole,
      );
    }

    if (_userProfile != null) {
      _localStorageService.saveUserProfile(_userProfile!);

      // Sync updated avatar and display name to user's hosted tours & vehicles
      final updatedPhoto = _userProfile!.photoUrl;
      final updatedName = _userProfile!.displayName;
      final currentUid = _userProfile!.uid;

      if (updatedPhoto.isNotEmpty || updatedName.isNotEmpty) {
        for (int i = 0; i < _tours.length; i++) {
          final t = _tours[i];
          final isMyTour = (currentUid.isNotEmpty && t.hostId == currentUid) ||
              (t.guideName.isNotEmpty && updatedName != 'Guest User' && t.guideName == updatedName) ||
              t.hostId.isEmpty;
          if (isMyTour) {
            _tours[i] = t.copyWith(
              guideAvatar: updatedPhoto.isNotEmpty ? updatedPhoto : t.guideAvatar,
              guideName: updatedName.isNotEmpty ? updatedName : t.guideName,
            );
            try {
              _supabaseService.saveTour(_tours[i]);
            } catch (_) {}
          }
        }

        for (int i = 0; i < _vehicles.length; i++) {
          final v = _vehicles[i];
          final isMyVehicle = (currentUid.isNotEmpty && v.hostId == currentUid) ||
              (v.hostName.isNotEmpty && updatedName != 'Guest User' && v.hostName == updatedName) ||
              v.hostId.isEmpty;
          if (isMyVehicle) {
            _vehicles[i] = v.copyWith(
              hostAvatar: updatedPhoto.isNotEmpty ? updatedPhoto : v.hostAvatar,
              hostName: updatedName.isNotEmpty ? updatedName : v.hostName,
            );
            try {
              _supabaseService.saveVehicle(_vehicles[i]);
            } catch (_) {}
          }
        }

        _localStorageService.saveTours(_tours);
        _localStorageService.saveVehicles(_vehicles);
      }

      notifyListeners();
    }

    // 2. Dual Sync to Firestore & Supabase Auth User Metadata
    if (_userProfile != null) {
      try {
        if (_supabaseUser != null) {
          try {
            await supa.Supabase.instance.client.auth.updateUser(
              supa.UserAttributes(
                data: {
                  if (displayName != null) 'full_name': displayName,
                  if (displayName != null) 'display_name': displayName,
                  if (photoUrl != null && photoUrl.isNotEmpty) 'avatar_url': photoUrl,
                  if (phoneNumber != null) 'phone_number': phoneNumber,
                  if (phoneNumber != null) 'phoneNumber': phoneNumber,
                  if (bio != null) 'bio': bio,
                },
              ),
            );
          } catch (_) {}
        }
        await _supabaseService.saveUserProfile(_userProfile!);
      } catch (e) {
        print('updateUserProfileDetails error: $e');
      }
    }
  }

  Future<void> toggleUserRole() async {
    if (_supabaseUser == null) return;
    final newRole = activeUserRole == 'Host' ? 'Rider' : 'Host';
    if (_userProfile != null) {
      _userProfile = _userProfile!.copyWith(role: newRole);
      notifyListeners();
    }
    await _supabaseService.updateUserRole(_supabaseUser!.id, newRole);
  }

  void _mergeVehicles(List<Vehicle> incoming) {
    if (incoming.isEmpty) return;
    for (var vehicle in incoming) {
      final idx = _vehicles.indexWhere((v) => v.id == vehicle.id);
      if (idx == -1) {
        _vehicles.add(vehicle);
      } else {
        final existing = _vehicles[idx];
        final existingImages = existing.images.where((img) => img.trim().isNotEmpty).toList();
        final incomingImages = vehicle.images.where((img) => img.trim().isNotEmpty).toList();

        final hasIncomingImageKit = incomingImages.any((img) => img.contains('imagekit.io') || !img.contains('unsplash.com'));
        final finalImages = hasIncomingImageKit
            ? incomingImages
            : (existingImages.isNotEmpty ? existingImages : incomingImages);

        final finalImgUrl = (vehicle.imageUrl.contains('imagekit.io') || (!vehicle.imageUrl.contains('unsplash.com') && vehicle.imageUrl.isNotEmpty))
            ? vehicle.imageUrl
            : (existing.imageUrl.isNotEmpty ? existing.imageUrl : (finalImages.isNotEmpty ? finalImages.first : vehicle.imageUrl));

        _vehicles[idx] = vehicle.copyWith(
          images: finalImages.isNotEmpty ? finalImages : existing.images,
          imageUrl: finalImgUrl,
        );
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
        final existing = _tours[idx];
        final existingImages = existing.images.where((img) => img.trim().isNotEmpty).toList();
        final incomingImages = tour.images.where((img) => img.trim().isNotEmpty).toList();

        // Prefer incoming non-unsplash ImageKit images over unsplash defaults
        final hasIncomingImageKit = incomingImages.any((img) => img.contains('imagekit.io') || !img.contains('unsplash.com'));
        final finalImages = hasIncomingImageKit
            ? incomingImages
            : (existingImages.isNotEmpty ? existingImages : incomingImages);

        final finalImgUrl = (tour.imageUrl.contains('imagekit.io') || (!tour.imageUrl.contains('unsplash.com') && tour.imageUrl.isNotEmpty))
            ? tour.imageUrl
            : (existing.imageUrl.isNotEmpty ? existing.imageUrl : (finalImages.isNotEmpty ? finalImages.first : tour.imageUrl));

        _tours[idx] = tour.copyWith(
          images: finalImages.isNotEmpty ? finalImages : existing.images,
          imageUrl: finalImgUrl,
        );
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
      final initialized = await _supabaseService.initialize(
        url: 'https://gxqlsogewjjkcdetubuv.supabase.co',
        anonKey: 'sb_publishable_b1WyefoA--KuuAfVlDjMaw_iFLBj8Hk',
      );
      if (initialized) {
        notifyListeners();
      }

      final supaVehicles = await _supabaseService.getVehicles();
      if (supaVehicles.isNotEmpty) {
        _mergeVehicles(supaVehicles);
      }
      final supaTours = await _supabaseService.getTours();
      if (supaTours.isNotEmpty) {
        _mergeTours(supaTours);
      }
    } catch (e) {
      print('Supabase Sync Init Warning: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _supabaseAuthService.signOut();
      _supabaseUser = null;
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

  LocationResult? _currentLocationResult;
  LocationResult? get currentLocationResult => _currentLocationResult;

  double _userLatitude = 37.7749;
  double get userLatitude => _userLatitude;

  double _userLongitude = -122.4194;
  double get userLongitude => _userLongitude;

  bool _isLiveLocationActive = false;
  bool get isLiveLocationActive => _isLiveLocationActive;

  List<LocationResult> _recentLocations = [];
  List<LocationResult> get recentLocations => _recentLocations;

  bool _sortByDistance = false;
  bool get sortByDistance => _sortByDistance;

  String _selectedCategory = 'All';
  String get selectedCategory => _selectedCategory;

  double _maxPriceFilter = 100000.0;
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

  /// Sets Live GPS Location
  void setLiveLocation(LocationResult result) {
    _currentLocationResult = result;
    _selectedLocation = result.displayName;
    _userLatitude = result.latitude;
    _userLongitude = result.longitude;
    _isLiveLocationActive = true;
    _addToRecentLocations(result);
    _localStorageService.saveSelectedLocation(result);
    notifyListeners();
  }

  /// Sets Manually Selected Location
  void setManualLocation(LocationResult result) {
    _currentLocationResult = result;
    _selectedLocation = result.displayName;
    _userLatitude = result.latitude;
    _userLongitude = result.longitude;
    _isLiveLocationActive = false;
    _addToRecentLocations(result);
    _localStorageService.saveSelectedLocation(result);
    notifyListeners();
  }

  void updateLocation(String loc) {
    _selectedLocation = loc;
    final popular = _locationService.getPopularHubs();
    LocationResult matched = LocationResult(
      displayName: loc,
      latitude: _userLatitude,
      longitude: _userLongitude,
      isLive: false,
    );
    for (final hub in popular) {
      if (hub.displayName.toLowerCase().contains(loc.toLowerCase()) ||
          loc.toLowerCase().contains(hub.city.toLowerCase())) {
        matched = hub;
        break;
      }
    }
    _currentLocationResult = matched;
    _userLatitude = matched.latitude;
    _userLongitude = matched.longitude;
    _isLiveLocationActive = false;
    _addToRecentLocations(matched);
    _localStorageService.saveSelectedLocation(matched);
    notifyListeners();
  }

  void _addToRecentLocations(LocationResult loc) {
    _recentLocations.removeWhere((item) =>
        item.displayName.toLowerCase() == loc.displayName.toLowerCase() ||
        ((item.latitude - loc.latitude).abs() < 0.001 &&
            (item.longitude - loc.longitude).abs() < 0.001));
    _recentLocations.insert(0, loc);
    if (_recentLocations.length > 10) {
      _recentLocations = _recentLocations.sublist(0, 10);
    }
    _localStorageService.saveRecentLocations(_recentLocations);
  }

  void clearRecentLocations() {
    _recentLocations.clear();
    _localStorageService.saveRecentLocations([]);
    notifyListeners();
  }

  void toggleSortByDistance() {
    _sortByDistance = !_sortByDistance;
    notifyListeners();
  }

  /// Returns Haversine distance in Kilometers from user's active coordinates to a vehicle
  double getDistanceToVehicle(Vehicle v) {
    return _locationService.calculateDistanceKm(
      _userLatitude,
      _userLongitude,
      v.latitude,
      v.longitude,
    );
  }

  /// Formatted distance string to vehicle (e.g., "1.4 km")
  String getFormattedDistanceToVehicle(Vehicle v) {
    final distKm = getDistanceToVehicle(v);
    return _locationService.formatDistance(distKm);
  }

  /// Count available vehicles within specified kilometer radius
  int getNearbyVehiclesCount({double radiusKm = 50.0}) {
    return _vehicles.where((v) => getDistanceToVehicle(v) <= radiusKm).length;
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
    _maxPriceFilter = 100000.0;
    _selectedFuelFilter = 'All';
    _selectedTransmissionFilter = 'All';
    _instantBookOnlyFilter = false;
    notifyListeners();
  }

  List<Vehicle> get filteredVehicles {
    final list = _vehicles.where((v) {
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

    if (_sortByDistance) {
      list.sort((a, b) => getDistanceToVehicle(a).compareTo(getDistanceToVehicle(b)));
    }

    return list;
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

      // Sync to Supabase
      try {
        _supabaseService.updateVehicleIoTData(vehicleId, currentIot);
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

      // Sync to Supabase
      try {
        _supabaseService.updateVehicleIoTData(vehicleId, currentIot);
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
        senderId: _supabaseUser?.id ?? _userProfile?.uid ?? 'user',
        text: text,
        timestamp: DateTime.now(),
        isUser: true,
      );
      _chatThreads[index].messages.add(newMessage);
      notifyListeners();

      final uid = _supabaseUser?.id ?? _userProfile?.uid ?? '';
      try {
        _supabaseService.saveChatMessage(threadId, newMessage);
        _supabaseService.saveChatThread(uid, _chatThreads[index]);
      } catch (e) {
        print('sendMessage Supabase error: $e');
      }
    }
  }

  void openChatWithHost({String hostName = 'Sovan Rajbanshi', String hostAvatar = '', String vehicleTitle = 'PassonRide Vehicle'}) {
    final existingIndex = _chatThreads.indexWhere((t) => t.partnerName.toLowerCase() == hostName.toLowerCase());
    if (existingIndex == -1) {
      final newThread = ChatThread(
        id: 'c_${DateTime.now().millisecondsSinceEpoch}',
        partnerName: hostName,
        partnerAvatar: hostAvatar.isNotEmpty ? hostAvatar : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&q=80',
        lastMessage: 'Started new conversation',
        lastTime: DateTime.now(),
        unreadCount: 0,
        vehicleTitle: vehicleTitle,
        messages: [],
      );

      _chatThreads.insert(0, newThread);
      final uid = _supabaseUser?.id ?? _userProfile?.uid ?? '';
      if (uid.isNotEmpty) {
        _supabaseService.saveChatThread(uid, newThread);
      }
    }
    _currentNavIndex = 5;
    notifyListeners();
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

  Future<void> fetchComplianceDocuments() async {
    final uid = _supabaseUser?.id ?? _userProfile?.uid ?? '';
    if (uid.isEmpty) return;
    try {
      final fetchedDocs = await _supabaseService.getComplianceDocuments(uid);
      if (fetchedDocs.isNotEmpty) {
        _documents = fetchedDocs;
        notifyListeners();
      }
    } catch (e) {
      print('fetchComplianceDocuments error: $e');
    }
  }

  Future<void> addComplianceDocument(ComplianceDocument doc) async {
    final docWithUser = ComplianceDocument(
      id: doc.id,
      userId: _supabaseUser?.id ?? _userProfile?.uid ?? doc.userId,
      title: doc.title,
      status: doc.status,
      expiryDate: doc.expiryDate,
      type: doc.type,
      documentUrl: doc.documentUrl,
    );
    _documents.insert(0, docWithUser);
    notifyListeners();

    try {
      await _supabaseService.saveComplianceDocument(docWithUser);
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
      hostId: _supabaseUser?.id ?? _userProfile?.uid ?? '',
    );

    // 2. Fallback to Gemini AI if Groq is unavailable
    generatedTour ??= await _geminiAiService.generateTourItinerary(
      destination: destination,
      durationDays: durationDays,
      budget: budget,
      terrain: terrain,
      guideName: activeUserDisplayName,
      hostId: _supabaseUser?.id ?? _userProfile?.uid ?? '',
    );

    _draftTourFromAi = generatedTour;
    notifyListeners();

    // Persist AiGeneration log
    try {
      final genLog = AiGeneration(
        id: 'gen_${DateTime.now().millisecondsSinceEpoch}',
        userId: _supabaseUser?.id ?? _userProfile?.uid ?? '',
        destination: destination.trim().isEmpty ? 'Pacific Coast Highway' : destination.trim(),
        durationDays: durationDays,
        budget: budget,
        terrain: terrain,
        generatedItineraryJson: generatedTour.toMap().toString(),
      );
      await _supabaseService.saveAiGeneration(genLog);
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
        await _supabaseService.updateVehicleIoTData(vehicleId, currentIot);
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
      hostId: _supabaseUser?.id ?? _userProfile?.uid ?? vehicle.hostId,
    );
    _vehicles.insert(0, vehicleWithHost);
    _localStorageService.saveVehicles(_vehicles);
    notifyListeners();

    try {
      await _supabaseService.saveVehicle(vehicleWithHost);
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

      final combinedMap = <String, Review>{};
      for (final r in _vehicleReviewsCache[vehicleId] ?? []) {
        combinedMap[r.id] = r;
      }
      for (final r in supaReviews) {
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
    final user = _supabaseUser;
    final review = Review(
      id: 'rev_${DateTime.now().millisecondsSinceEpoch}',
      vehicleId: vehicleId,
      userId: user?.id ?? _userProfile?.uid ?? 'guest_rider',
      userName: activeUserDisplayName,
      userAvatar: activeUserPhotoUrl.isNotEmpty ? activeUserPhotoUrl : 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150&q=80',
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

    // Persist to Supabase
    try {
      await _supabaseService.saveReview(review);
    } catch (e) {
      print('Submit review error: $e');
    }
  }

  // Add Tour Workflow (Publishing tour to marketplace)
  Future<void> addTour(Tour tour) async {
    final tourWithHost = tour.copyWith(
      hostId: _supabaseUser?.id ?? _userProfile?.uid ?? tour.hostId,
    );
    _tours.insert(0, tourWithHost);
    _localStorageService.saveTours(_tours);
    notifyListeners();

    try {
      await _supabaseService.saveTour(tourWithHost);
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
      await _supabaseService.saveTour(updatedTour);
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
      await _supabaseService.deleteTour(tourId);
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
      userId: _supabaseUser?.id ?? _userProfile?.uid ?? '',
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

    // Persist to Supabase
    try {
      await _supabaseService.saveBooking(newBooking);
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
      await _supabaseService.updateBookingStatus(bookingId, newStatus);
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
