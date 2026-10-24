// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/app_state.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';
import '../widgets/interactive_map_pin_picker.dart';
import '../services/location_service.dart';

class RegisterHotelScreen extends StatefulWidget {
  final Hotel? existingHotel;

  const RegisterHotelScreen({super.key, this.existingHotel});

  @override
  State<RegisterHotelScreen> createState() => _RegisterHotelScreenState();
}

class _RegisterHotelScreenState extends State<RegisterHotelScreen> {
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _addressController = TextEditingController();
  final _latitudeController = TextEditingController(text: '22.572600');
  final _longitudeController = TextEditingController(text: '88.363900');
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _hostNameController = TextEditingController();
  final _hostPhoneController = TextEditingController();
  final _maxGuestsController = TextEditingController(text: '2');
  final _totalRoomsController = TextEditingController(text: '1');
  final _availableRoomsController = TextEditingController(text: '1');

  double _stayLatitude = 22.5726;
  double _stayLongitude = 88.3639;
  bool _isFetchingLiveGps = false;

  String _selectedRoomType = 'Private Room';
  final List<String> _roomTypeOptions = [
    'Private Room',
    'Double Bed Room',
    'Family Room',
    'Entire Homestay',
    'Shared Dorm Bed',
  ];

  final List<String> _availableAmenities = [
    'Free Wi-Fi',
    'Hot Geyser Water',
    'Home-Cooked Food',
    'Bike & Car Parking',
    'Attached Bathroom',
    'Mountain / Nature View',
    'Bonfire Area',
    '24/7 Electricity / Inverter',
    'Drinking Water RO',
  ];
  final Set<String> _selectedAmenities = {
    'Free Wi-Fi',
    'Hot Geyser Water',
    'Bike & Car Parking',
  };

  final List<String> _presetStayImages = [
    'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',
    'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=800&q=80',
    'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800&q=80',
    'https://images.unsplash.com/photo-1590490360182-c33d57733427?w=800&q=80',
    'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=800&q=80',
  ];
  String _selectedImageUrl = 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80';
  final List<String> _customPhotos = [];

  final _picker = ImagePicker();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      if (widget.existingHotel != null) {
        final h = widget.existingHotel!;
        _nameController.text = h.name;
        _locationController.text = h.location;
        _addressController.text = h.address;
        _stayLatitude = h.latitude != 0.0 ? h.latitude : 22.5726;
        _stayLongitude = h.longitude != 0.0 ? h.longitude : 88.3639;
        _latitudeController.text = _stayLatitude.toStringAsFixed(6);
        _longitudeController.text = _stayLongitude.toStringAsFixed(6);
        _priceController.text = h.pricePerNight.toStringAsFixed(0);
        _descriptionController.text = h.description;
        _hostNameController.text = h.hostName;
        _hostPhoneController.text = h.hostPhone;
        _maxGuestsController.text = h.maxGuests.toString();
        _totalRoomsController.text = h.totalRooms.toString();
        _availableRoomsController.text = h.availableRooms.toString();
        _selectedRoomType = h.roomType;
        _selectedAmenities.clear();
        _selectedAmenities.addAll(h.amenities);
        _selectedImageUrl = h.imageUrl;
        _customPhotos.addAll(h.images);
      } else {
        _hostNameController.text = appState.activeUserDisplayName != 'Guest User'
            ? appState.activeUserDisplayName
            : '';
        _hostPhoneController.text = appState.userProfile?.phoneNumber ?? '';
        _priceController.text = '500';
        _totalRoomsController.text = '1';
        _availableRoomsController.text = '1';
        _latitudeController.text = _stayLatitude.toStringAsFixed(6);
        _longitudeController.text = _stayLongitude.toStringAsFixed(6);
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _hostNameController.dispose();
    _hostPhoneController.dispose();
    _maxGuestsController.dispose();
    _totalRoomsController.dispose();
    _availableRoomsController.dispose();
    super.dispose();
  }

  void _openMapPinPicker(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.teal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.holiday_village, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '📍 Pin Homestay Location On Map',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            Expanded(
              child: InteractiveMapPinPicker(
                initialLat: _stayLatitude,
                initialLng: _stayLongitude,
                onLocationPicked: (LocationResult result) {
                  setState(() {
                    if (result.city.isNotEmpty) {
                      _locationController.text = result.state.isNotEmpty
                          ? '${result.city}, ${result.state}'
                          : result.city;
                    } else if (_locationController.text.trim().isEmpty) {
                      _locationController.text = result.displayName;
                    }
                    _addressController.text = result.displayName;
                    _stayLatitude = result.latitude;
                    _stayLongitude = result.longitude;
                    _latitudeController.text = result.latitude.toStringAsFixed(6);
                    _longitudeController.text = result.longitude.toStringAsFixed(6);
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🏡 Homestay pinned: ${result.displayName}'),
                      backgroundColor: Colors.teal.shade700,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchCurrentLiveGps() async {
    setState(() => _isFetchingLiveGps = true);
    try {
      final live = await LocationService().getCurrentLiveLocation();
      setState(() {
        if (live.city.isNotEmpty) {
          _locationController.text = live.state.isNotEmpty
              ? '${live.city}, ${live.state}'
              : live.city;
        } else if (_locationController.text.trim().isEmpty) {
          _locationController.text = live.displayName;
        }
        _addressController.text = live.displayName;
        _stayLatitude = live.latitude;
        _stayLongitude = live.longitude;
        _latitudeController.text = live.latitude.toStringAsFixed(6);
        _longitudeController.text = live.longitude.toStringAsFixed(6);
        _isFetchingLiveGps = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📍 Live GPS fetched: ${live.displayName}'),
            backgroundColor: Colors.teal.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _isFetchingLiveGps = false);
      _showToast('Unable to fetch live GPS. You can pick on map or enter manually.');
    }
  }

  void _openPasteCoordinatesDialog(BuildContext context) {
    final pasteController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.content_paste, color: Colors.teal, size: 20),
            SizedBox(width: 8),
            Text('Paste Coordinates', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste comma-separated coordinates from Google Maps, WhatsApp, or GPS device (e.g. "23.080000, 87.900000"):',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pasteController,
              decoration: const InputDecoration(
                labelText: 'Latitude, Longitude',
                hintText: 'e.g. 23.080000, 87.900000',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            onPressed: () {
              final text = pasteController.text.trim();
              final parts = text.split(RegExp(r'[,;\s]+'));
              if (parts.length >= 2) {
                final lat = double.tryParse(parts[0].replaceAll(RegExp(r'[^\d.-]'), ''));
                final lng = double.tryParse(parts[1].replaceAll(RegExp(r'[^\d.-]'), ''));
                if (lat != null && lng != null && lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180) {
                  setState(() {
                    _stayLatitude = lat;
                    _stayLongitude = lng;
                    _latitudeController.text = lat.toStringAsFixed(6);
                    _longitudeController.text = lng.toStringAsFixed(6);
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Coordinates updated: $lat, $lng'),
                      backgroundColor: Colors.teal.shade700,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
              }
              _showToast('Invalid format. Please use "latitude, longitude"');
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _applyPresetLocation(String location, String address, double lat, double lng) {
    setState(() {
      _locationController.text = location;
      _addressController.text = address;
      _stayLatitude = lat;
      _stayLongitude = lng;
      _latitudeController.text = lat.toStringAsFixed(6);
      _longitudeController.text = lng.toStringAsFixed(6);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Loaded location: $location ($lat, $lng)'),
        backgroundColor: Colors.teal.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
      if (image != null) {
        setState(() {
          _selectedImageUrl = image.path;
          _customPhotos.add(image.path);
        });
      }
    } catch (e) {
      debugPrint('Pick image error: $e');
    }
  }

  Future<void> _submitListing() async {
    final name = _nameController.text.trim();
    final location = _locationController.text.trim();
    final priceStr = _priceController.text.trim();

    if (name.isEmpty) {
      _showToast('Please enter your Homestay or Hotel name');
      return;
    }
    if (location.isEmpty) {
      _showToast('Please enter your City, Town, or Village location');
      return;
    }
    if (priceStr.isEmpty || double.tryParse(priceStr) == null) {
      _showToast('Please enter a valid price per night');
      return;
    }

    // Validate manual coordinates if entered
    double finalLat = _stayLatitude;
    double finalLng = _stayLongitude;
    if (_latitudeController.text.trim().isNotEmpty) {
      final lat = double.tryParse(_latitudeController.text.trim());
      if (lat == null || lat < -90.0 || lat > 90.0) {
        _showToast('Please enter a valid Latitude between -90.0 and 90.0');
        return;
      }
      finalLat = lat;
    }
    if (_longitudeController.text.trim().isNotEmpty) {
      final lng = double.tryParse(_longitudeController.text.trim());
      if (lng == null || lng < -180.0 || lng > 180.0) {
        _showToast('Please enter a valid Longitude between -180.0 and 180.0');
        return;
      }
      finalLng = lng;
    }

    setState(() => _isSubmitting = true);

    final appState = Provider.of<AppState>(context, listen: false);
    final price = double.tryParse(priceStr) ?? 500.0;
    final maxGuests = int.tryParse(_maxGuestsController.text.trim()) ?? 2;
    final totalRooms = int.tryParse(_totalRoomsController.text.trim()) ?? 1;
    final availableRooms = int.tryParse(_availableRoomsController.text.trim()) ?? totalRooms;

    if (totalRooms < 1) {
      _showToast('Total rooms must be at least 1.');
      setState(() => _isSubmitting = false);
      return;
    }
    if (availableRooms < 0 || availableRooms > totalRooms) {
      _showToast('Available rooms must be between 0 and total rooms ($totalRooms).');
      setState(() => _isSubmitting = false);
      return;
    }

    final hotelId = widget.existingHotel?.id ??
        'hotel_${DateTime.now().millisecondsSinceEpoch}';

    final hotel = Hotel(
      id: hotelId,
      name: name,
      location: location,
      address: _addressController.text.trim(),
      latitude: finalLat,
      longitude: finalLng,
      pricePerNight: price,
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : 'Cozy and clean budget accommodation welcoming travelers and riders.',
      roomType: _selectedRoomType,
      maxGuests: maxGuests,
      rating: widget.existingHotel?.rating ?? 4.9,
      reviewCount: widget.existingHotel?.reviewCount ?? 1,
      imageUrl: _selectedImageUrl,
      images: _customPhotos.isNotEmpty ? _customPhotos : [_selectedImageUrl],
      hostName: _hostNameController.text.trim().isNotEmpty
          ? _hostNameController.text.trim()
          : appState.activeUserDisplayName,
      hostPhone: _hostPhoneController.text.trim(),
      hostAvatar: appState.activeUserPhotoUrl,
      hostId: appState.activeAccountId,
      accountId: appState.activeAccountId,
      accountName: appState.activeUserDisplayName,
      accountType: appState.isChildAccount ? 'child' : 'mother',
      isChildHosting: appState.isChildAccount,
      childId: appState.activeChildProfile?.childId ?? '',
      childName: appState.activeChildProfile?.name ?? '',
      amenities: _selectedAmenities.toList(),
      isAvailable: availableRooms > 0,
      totalRooms: totalRooms,
      availableRooms: availableRooms,
    );

    if (widget.existingHotel != null) {
      await appState.updateHotel(hotel);
    } else {
      await appState.addHotel(hotel);
    }

    setState(() => _isSubmitting = false);

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 8),
              Text('Listing Published!'),
            ],
          ),
          content: Text(
            '"$name" is now live on the platform! Travelers looking for budget stays in $location can discover and contact you directly with 0% platform commission.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                appState.setNavIndex(8); // Navigate to Provider Dashboard
              },
              child: const Text('Go to Host Dashboard'),
            ),
          ],
        ),
      );
    }
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingHotel != null ? 'Edit Local Stay' : 'Host Local Hotel & Stay',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => appState.setNavIndex(8), // Back to Host Dashboard
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Empowerment Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [Colors.teal.shade900.withOpacity(0.5), Colors.blueGrey.shade900.withOpacity(0.4)]
                      : [Colors.teal.shade50, Colors.green.shade50],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.teal.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.holiday_village, color: Colors.teal, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Empowering Local & Budget Homestays',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Host your house, spare room, or budget lodge with zero listing fee and direct customer contact.',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Step 1: Stay Name & Location
            _buildSectionHeader('1. Basic Details & Location', Icons.home_outlined),
            const SizedBox(height: 10),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Homestay or Hotel Name *',
                hintText: 'e.g. Green Valley Homestay / Sharma Guest House',
                prefixIcon: Icon(Icons.home_work_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),

            // Location Picker Options (Built-in Map & Live GPS)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? Colors.teal.shade900.withOpacity(0.2) : Colors.teal.shade50.withOpacity(0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.teal.withOpacity(0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.teal.shade700, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Homestay Location & Map Pin',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'MAP & GPS',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.teal.shade700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Pick your stay location directly on our built-in interactive map, use live GPS, or enter manual listing coordinates.',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),

                  // Action Buttons: Pick on Map, Live GPS, Paste Coords
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.map_outlined, size: 16),
                        label: const Text('Pick on Built-in Map', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _openMapPinPicker(context),
                      ),
                      OutlinedButton.icon(
                        icon: _isFetchingLiveGps
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.teal),
                              )
                            : const Icon(Icons.my_location, size: 16, color: Colors.teal),
                        label: Text(
                          _isFetchingLiveGps ? 'Locating...' : 'Use Live GPS',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.teal.withOpacity(0.6)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isFetchingLiveGps ? null : _fetchCurrentLiveGps,
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.content_paste, size: 15, color: Colors.teal),
                        label: const Text('Paste Coords', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.teal)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        onPressed: () => _openPasteCoordinatesDialog(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),
                  // Popular Hub Quick Chips
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Quick Hubs: ',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildHubChip('Burdwan', 'Purba Burdwan, West Bengal', 'Near Station Road, Burdwan', 23.0800, 87.9000),
                              const SizedBox(width: 6),
                              _buildHubChip('Manali', 'Old Manali, Himachal Pradesh', 'Near Club House, Old Manali', 32.2530, 77.1750),
                              const SizedBox(width: 6),
                              _buildHubChip('Rishikesh', 'Tapovan, Rishikesh, Uttarakhand', 'Near Lakshman Jhula', 30.1330, 78.3250),
                              const SizedBox(width: 6),
                              _buildHubChip('Kolkata', 'Kolkata, West Bengal', 'Salt Lake Sector V', 22.5726, 88.3639),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Manual Listing Address Details
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'City / Town / Village *',
                hintText: 'e.g. Purba Burdwan / Old Manali / Rishikesh',
                prefixIcon: Icon(Icons.location_city_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Local Address / Landmark',
                hintText: 'e.g. Near Gotan High School, Raina-II',
                prefixIcon: Icon(Icons.pin_drop_outlined),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 14),

            // Integrated Latitude & Longitude Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.blueGrey.shade900.withOpacity(0.3) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? Colors.blueGrey.shade700 : Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.explore_outlined, size: 18, color: Colors.teal),
                      const SizedBox(width: 8),
                      const Text(
                        'Geographic Coordinates (GPS)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 4),
                            const Text('Active', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Precision coordinates ensure travelers navigate directly to your door without getting lost.',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = constraints.maxWidth < 360;
                      final latField = TextField(
                        controller: _latitudeController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        decoration: const InputDecoration(
                          labelText: 'Latitude (°N/°S) *',
                          hintText: 'e.g. 23.080000',
                          prefixIcon: Icon(Icons.north_east, size: 16),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        ),
                        onChanged: (val) {
                          final d = double.tryParse(val.trim());
                          if (d != null && d >= -90.0 && d <= 90.0) {
                            setState(() => _stayLatitude = d);
                          }
                        },
                      );

                      final lngField = TextField(
                        controller: _longitudeController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        decoration: const InputDecoration(
                          labelText: 'Longitude (°E/°W) *',
                          hintText: 'e.g. 87.900000',
                          prefixIcon: Icon(Icons.south_east, size: 16),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        ),
                        onChanged: (val) {
                          final d = double.tryParse(val.trim());
                          if (d != null && d >= -180.0 && d <= 180.0) {
                            setState(() => _stayLongitude = d);
                          }
                        },
                      );

                      if (isCompact) {
                        return Column(
                          children: [
                            latField,
                            const SizedBox(height: 10),
                            lngField,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: latField),
                          const SizedBox(width: 10),
                          Expanded(child: lngField),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.check_circle_outline, size: 14, color: Colors.teal),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Pinned: ${_stayLatitude.toStringAsFixed(6)}, ${_stayLongitude.toStringAsFixed(6)}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.teal.shade200 : Colors.teal.shade800,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.remove_red_eye_outlined, size: 14, color: Colors.teal),
                        label: const Text('Preview Pin', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => _openMapPinPicker(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // Step 2: Pricing & Room Type
            _buildSectionHeader('2. Pricing & Capacity', Icons.currency_rupee),
            const SizedBox(height: 10),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Price Per Night (₹) *',
                hintText: 'e.g. 450',
                prefixIcon: Icon(Icons.currency_rupee),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            // Quick Price Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [350, 450, 600, 750, 1000].map((p) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text('₹$p / night'),
                      onPressed: () {
                        setState(() => _priceController.text = p.toString());
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 14),

            // Room Type Selector
            DropdownButtonFormField<String>(
              value: _selectedRoomType,
              decoration: const InputDecoration(
                labelText: 'Room Type',
                prefixIcon: Icon(Icons.bedroom_parent_outlined),
                border: OutlineInputBorder(),
              ),
              items: _roomTypeOptions.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedRoomType = val);
              },
            ),

            const SizedBox(height: 12),
            TextField(
              controller: _maxGuestsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Maximum Guests Allowed Per Room',
                hintText: '2',
                prefixIcon: Icon(Icons.group_outlined),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 14),

            // Number of Hotel Rooms Available to Rent
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? Colors.teal.shade900.withOpacity(0.18) : Colors.teal.shade50.withOpacity(0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.teal.withOpacity(0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.meeting_room, color: Colors.teal, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Rooms Available to Rent *',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'INVENTORY',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.teal.shade700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Specify how many rooms you have open and available for travelers to rent/book.',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = constraints.maxWidth < 360;
                      final availField = TextField(
                        controller: _availableRoomsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Available to Rent *',
                          hintText: 'e.g. 5',
                          prefixIcon: Icon(Icons.door_front_door_outlined),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        ),
                        onChanged: (val) {
                          final avail = int.tryParse(val.trim());
                          final tot = int.tryParse(_totalRoomsController.text.trim()) ?? 1;
                          if (avail != null && avail > tot) {
                            _totalRoomsController.text = avail.toString();
                          }
                        },
                      );

                      final totField = TextField(
                        controller: _totalRoomsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Total Property Rooms',
                          hintText: 'e.g. 5',
                          prefixIcon: Icon(Icons.domain_outlined),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        ),
                      );

                      if (isCompact) {
                        return Column(
                          children: [
                            availField,
                            const SizedBox(height: 10),
                            totField,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: availField),
                          const SizedBox(width: 10),
                          Expanded(child: totField),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  // Quick Room Count Stepper / Chips
                  Row(
                    children: [
                      const Text(
                        'Quick Select: ',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [1, 2, 3, 5, 8, 10, 15, 20].map((count) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ActionChip(
                                  label: Text('$count room${count == 1 ? '' : 's'}'),
                                  onPressed: () {
                                    setState(() {
                                      _availableRoomsController.text = count.toString();
                                      final tot = int.tryParse(_totalRoomsController.text.trim()) ?? 1;
                                      if (count > tot) {
                                        _totalRoomsController.text = count.toString();
                                      }
                                    });
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // Step 3: Amenities
            _buildSectionHeader('3. Amenities & Facilities', Icons.check_circle_outline),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableAmenities.map((amenity) {
                final isSelected = _selectedAmenities.contains(amenity);
                return FilterChip(
                  label: Text(amenity),
                  selected: isSelected,
                  selectedColor: AppColors.primary.withOpacity(0.2),
                  checkmarkColor: AppColors.primary,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedAmenities.add(amenity);
                      } else {
                        _selectedAmenities.remove(amenity);
                      }
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 22),

            // Step 4: Photos
            _buildSectionHeader('4. Stay Photos', Icons.photo_library_outlined),
            const SizedBox(height: 8),
            const Text(
              'Select one of our high quality ready presets or upload your own pictures:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 10),

            // Preset Photo Selector
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _presetStayImages.length,
                itemBuilder: (ctx, idx) {
                  final url = _presetStayImages[idx];
                  final isSelected = _selectedImageUrl == url;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedImageUrl = url),
                    child: Container(
                      width: 120,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(url, fit: BoxFit.cover),
                            if (isSelected)
                              Container(
                                color: AppColors.primary.withOpacity(0.3),
                                child: const Icon(Icons.check, color: Colors.white, size: 28),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('Upload Photo from Device / Camera'),
            ),

            const SizedBox(height: 22),

            // Step 5: Host Contact
            _buildSectionHeader('5. Host Contact Details', Icons.contact_phone_outlined),
            const SizedBox(height: 10),
            TextField(
              controller: _hostNameController,
              decoration: const InputDecoration(
                labelText: 'Host Contact Name *',
                hintText: 'e.g. Ramesh Kumar',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _hostPhoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Mobile Phone / WhatsApp Number *',
                hintText: 'e.g. +91 98765 43210',
                prefixIcon: Icon(Icons.phone_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description & House Rules',
                hintText: 'Describe your home, surroundings, meals provided, check-in rules...',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 28),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitListing,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.publish),
                label: Text(
                  _isSubmitting
                      ? 'Publishing Listing...'
                      : (widget.existingHotel != null ? 'Update Stay Listing' : 'Publish Local Stay Now'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildHubChip(String label, String location, String address, double lat, double lng) {
    return InkWell(
      onTap: () => _applyPresetLocation(location, address, lat, lng),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.teal.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.teal.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.place, size: 11, color: Colors.teal),
            const SizedBox(width: 3),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.teal)),
          ],
        ),
      ),
    );
  }
}
