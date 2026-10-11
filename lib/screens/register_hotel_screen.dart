// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/app_state.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';

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
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _hostNameController = TextEditingController();
  final _hostPhoneController = TextEditingController();
  final _maxGuestsController = TextEditingController(text: '2');

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
        _priceController.text = h.pricePerNight.toStringAsFixed(0);
        _descriptionController.text = h.description;
        _hostNameController.text = h.hostName;
        _hostPhoneController.text = h.hostPhone;
        _maxGuestsController.text = h.maxGuests.toString();
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
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _hostNameController.dispose();
    _hostPhoneController.dispose();
    _maxGuestsController.dispose();
    super.dispose();
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

    setState(() => _isSubmitting = true);

    final appState = Provider.of<AppState>(context, listen: false);
    final price = double.tryParse(priceStr) ?? 500.0;
    final maxGuests = int.tryParse(_maxGuestsController.text.trim()) ?? 2;

    final hotelId = widget.existingHotel?.id ??
        'hotel_${DateTime.now().millisecondsSinceEpoch}';

    final hotel = Hotel(
      id: hotelId,
      name: name,
      location: location,
      address: _addressController.text.trim(),
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
      amenities: _selectedAmenities.toList(),
      isAvailable: true,
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
            _buildSectionHeader('1. Basic Details', Icons.home_outlined),
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
            const SizedBox(height: 12),
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
                labelText: 'Maximum Guests Allowed',
                hintText: '2',
                prefixIcon: Icon(Icons.group_outlined),
                border: OutlineInputBorder(),
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
}
