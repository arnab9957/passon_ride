import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';
import 'location_screen.dart';

class RegisterVehicleScreen extends StatefulWidget {
  const RegisterVehicleScreen({super.key});

  @override
  State<RegisterVehicleScreen> createState() => _RegisterVehicleScreenState();
}

class _RegisterVehicleScreenState extends State<RegisterVehicleScreen> {
  final _titleController = TextEditingController(text: 'Bajaj Pulsar N250');
  final _priceController = TextEditingController(text: '500.00');
  final _vinController = TextEditingController(text: 'WB11442A');
  final _locationController = TextEditingController(text: 'Kolkata, West Bengal');
  final _descriptionController = TextEditingController(
    text: 'Well-maintained street motorcycle available for daily or weekly rentals. Equipped with dual-channel ABS and helmet.',
  );
  final _urlInputController = TextEditingController();

  String _selectedCategory = 'Motorcycle';
  String _selectedFuelType = 'Petrol';
  String _selectedTransmission = 'Manual';
  int _seats = 2;
  bool _instantBook = true;
  bool _isSubmitting = false;

  // Multiple Vehicle Photos Gallery State
  final List<String> _vehiclePhotos = [
    'https://images.unsplash.com/photo-1558981403-c5f9899a28bc?w=800&q=80',
  ];
  final ImagePicker _picker = ImagePicker();

  // Preset sample vehicle photo choices
  final List<Map<String, String>> _presetPhotos = [
    {
      'title': 'Adventure Bike',
      'url': 'https://images.unsplash.com/photo-1558981403-c5f9899a28bc?w=800&q=80',
    },
    {
      'title': 'Sedan / SUV',
      'url': 'https://images.unsplash.com/photo-1560958089-b8a1929cea89?w=800&q=80',
    },
    {
      'title': 'Urban Scooter',
      'url': 'https://images.unsplash.com/photo-1558981806-ec527fa84c39?w=800&q=80',
    },
    {
      'title': 'Sports Convertible',
      'url': 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=800&q=80',
    },
  ];

  // Pick Multiple Local Images from Device Gallery
  Future<void> _pickMultiGalleryImages() async {
    final appState = Provider.of<AppState>(context, listen: false);
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFiles.isNotEmpty) {
        for (var file in pickedFiles) {
          final bytes = await file.readAsBytes();
          final ikUrl = await appState.imageKitService.uploadImage(
            bytes: bytes,
            fileName: 'vehicle_${DateTime.now().millisecondsSinceEpoch}.jpg',
            folder: '/vehicles',
          );
          final finalUrl = ikUrl ?? 'data:image/png;base64,${base64Encode(bytes)}';
          if (!_vehiclePhotos.contains(finalUrl)) {
            _vehiclePhotos.add(finalUrl);
          }
        }
        setState(() {});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added ${pickedFiles.length} photo(s) to vehicle gallery!'),
              backgroundColor: Colors.green.shade700,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final isMissingPlugin = e.toString().contains('MissingPluginException');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isMissingPlugin
                  ? '⚠️ Native plugin not bound yet! Please restart your "flutter run" session in the terminal to load the newly installed image_picker plugin.'
                  : 'Error selecting gallery photos: $e',
            ),
            duration: const Duration(seconds: 6),
            backgroundColor: isMissingPlugin ? Colors.orange.shade900 : Colors.red.shade800,
          ),
        );
      }
    }
  }

  // Take a Photo with Device Camera
  Future<void> _pickCameraPhoto() async {
    final appState = Provider.of<AppState>(context, listen: false);
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final ikUrl = await appState.imageKitService.uploadImage(
          bytes: bytes,
          fileName: 'camera_${DateTime.now().millisecondsSinceEpoch}.jpg',
          folder: '/vehicles',
        );
        final finalUrl = ikUrl ?? 'data:image/png;base64,${base64Encode(bytes)}';
        setState(() {
          _vehiclePhotos.add(finalUrl);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Added camera photo to vehicle gallery!'),
              backgroundColor: Colors.green.shade700,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final isMissingPlugin = e.toString().contains('MissingPluginException');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isMissingPlugin
                  ? '⚠️ Native plugin not bound yet! Please restart your "flutter run" session in the terminal to load the newly installed image_picker plugin.'
                  : 'Error taking photo: $e',
            ),
            duration: const Duration(seconds: 6),
            backgroundColor: isMissingPlugin ? Colors.orange.shade900 : Colors.red.shade800,
          ),
        );
      }
    }
  }

  // Add Custom Web URL to Photo Gallery
  void _addWebUrlPhoto() {
    final url = _urlInputController.text.trim();
    if (url.isNotEmpty) {
      if (!_vehiclePhotos.contains(url)) {
        setState(() {
          _vehiclePhotos.add(url);
          _urlInputController.clear();
        });
      }
    }
  }

  // Set selected photo as main cover photo (move to index 0)
  void _setAsCoverPhoto(int index) {
    if (index > 0 && index < _vehiclePhotos.length) {
      setState(() {
        final photo = _vehiclePhotos.removeAt(index);
        _vehiclePhotos.insert(0, photo);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Updated cover photo!')),
      );
    }
  }

  // Remove single photo from gallery
  void _removePhoto(int index) {
    setState(() {
      _vehiclePhotos.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => appState.setNavIndex(8),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HOST LISTING WIZARD',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: isDark ? AppColors.secondaryFixedDim : AppColors.secondary,
                    ),
                  ),
                  const Text('Register New Vehicle', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 1. Basic Vehicle Information
          const Text('1. Basic Vehicle Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),

          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Vehicle Title / Make & Model',
              prefixIcon: Icon(Icons.directions_car),
            ),
          ),
          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Vehicle Type',
              prefixIcon: Icon(Icons.category),
            ),
            items: ['Motorcycle', 'Car', 'Scooter', 'Electric EV']
                .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                .toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedCategory = val;
                  _seats = val == 'Car' ? 5 : 2;
                });
              }
            },
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _vinController,
            decoration: const InputDecoration(
              labelText: 'VIN / Registration Plate Number',
              prefixIcon: Icon(Icons.pin),
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _locationController,
            decoration: InputDecoration(
              labelText: 'Pickup Location / City',
              prefixIcon: const Icon(Icons.location_on),
              suffixIcon: TextButton.icon(
                onPressed: () async {
                  final result = await showLocationPickerModal(context);
                  if (result != null) {
                    setState(() {
                      _locationController.text = result.displayName;
                    });
                  }
                },
                icon: const Icon(Icons.my_location, size: 14),
                label: const Text('Pick (Live/Manual)', style: TextStyle(fontSize: 11)),
              ),
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _descriptionController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Vehicle Description & Features',
              prefixIcon: Icon(Icons.description),
            ),
          ),

          const SizedBox(height: 24),

          // 2. Multi-Photo Gallery Upload Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '2. Vehicle Photos Gallery (${_vehiclePhotos.length})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              if (_vehiclePhotos.isNotEmpty)
                TextButton.icon(
                  onPressed: () => setState(() => _vehiclePhotos.clear()),
                  icon: const Icon(Icons.delete_sweep, size: 16, color: Colors.redAccent),
                  label: const Text('Clear All', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Add multiple vehicle photos (exterior, interior, side view). The first photo will be used as the cover photo.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 14),

          // Multi-Photo Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _pickMultiGalleryImages,
                  icon: const Icon(Icons.photo_library, size: 18),
                  label: const Text('Add Multiple Photos', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickCameraPhoto,
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: const Text('Take Camera Photo', style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Add Web URL Input Field
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _urlInputController,
                  decoration: const InputDecoration(
                    labelText: 'Or Add Web Image Photo URL',
                    prefixIcon: Icon(Icons.link),
                    hintText: 'https://example.com/photo.jpg',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _addWebUrlPhoto,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Quick Select Sample Presets (Appends to Multi-Photo List)
          const Text('Quick Select Sample Photos (Tap to add to gallery):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SizedBox(
            height: 85,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _presetPhotos.length,
              itemBuilder: (context, idx) {
                final photo = _presetPhotos[idx];
                final isAlreadyAdded = _vehiclePhotos.contains(photo['url']);
                return GestureDetector(
                  onTap: () {
                    if (!isAlreadyAdded) {
                      setState(() {
                        _vehiclePhotos.add(photo['url']!);
                      });
                    }
                  },
                  child: Container(
                    width: 110,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isAlreadyAdded ? AppColors.primary : Colors.grey.shade400,
                        width: isAlreadyAdded ? 2.5 : 1,
                      ),
                      image: DecorationImage(
                        image: NetworkImage(photo['url']!),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                            color: Colors.black.withValues(alpha: 0.65),
                            child: Text(
                              photo['title']!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        if (isAlreadyAdded)
                          const Positioned(
                            top: 4,
                            right: 4,
                            child: CircleAvatar(
                              radius: 10,
                              backgroundColor: AppColors.primary,
                              child: Icon(Icons.check, size: 12, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Interactive Multi-Photo Gallery Horizontal Preview
          if (_vehiclePhotos.isNotEmpty) ...[
            const Text('Uploaded Vehicle Photo Gallery (Drag / Tap to manage):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _vehiclePhotos.length,
                itemBuilder: (context, index) {
                  final photoUrl = _vehiclePhotos[index];
                  final isCover = index == 0;

                  return Container(
                    width: 180,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isCover ? AppColors.primary : (isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight),
                        width: isCover ? 2.5 : 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (photoUrl.startsWith('data:image/'))
                          Image.memory(
                            base64Decode(photoUrl.split(',').last),
                            fit: BoxFit.cover,
                          )
                        else
                          Image.network(
                            photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => const Center(
                              child: Icon(Icons.broken_image, size: 36, color: Colors.grey),
                            ),
                          ),

                        // Cover Photo Badge
                        Positioned(
                          top: 8,
                          left: 8,
                          child: GestureDetector(
                            onTap: () => _setAsCoverPhoto(index),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isCover ? AppColors.primary : Colors.black.withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isCover ? Icons.star : Icons.photo,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isCover ? 'COVER PHOTO' : '#${index + 1} Set Cover',
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Delete Single Photo Button
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => _removePhoto(index),
                            child: const CircleAvatar(
                              radius: 13,
                              backgroundColor: Colors.black54,
                              child: Icon(Icons.close, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],

          // 3. Specifications & Seating
          const Text('3. Specifications & Seating', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedFuelType,
                  decoration: const InputDecoration(labelText: 'Fuel Type', prefixIcon: Icon(Icons.local_gas_station)),
                  items: ['Petrol', 'Diesel', 'Electric', 'Gasoline', 'Hybrid', 'CNG']
                      .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedFuelType = val!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedTransmission,
                  decoration: const InputDecoration(labelText: 'Transmission', prefixIcon: Icon(Icons.settings)),
                  items: ['Manual', 'Automatic']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedTransmission = val!),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 4. Pricing & Policies
          const Text('4. Rental Rates & Instant Booking', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),

          TextField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Daily Rental Rate (₹ INR)',
              prefixIcon: Icon(Icons.currency_rupee),
            ),
          ),
          const SizedBox(height: 12),

          SwitchListTile(
            title: const Text('Enable Instant Booking', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: const Text('Verified renters can book without waiting for host approval', style: TextStyle(fontSize: 12)),
            value: _instantBook,
            onChanged: (val) => setState(() => _instantBook = val),
            activeColor: AppColors.secondary,
          ),

          const SizedBox(height: 24),

          // 5. IoT Telematics Hardware Pair
          const Text('5. Pair IoT Telematics Hardware', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.secondary),
            ),
            child: Row(
              children: [
                const Icon(Icons.bluetooth_searching, color: AppColors.secondary, size: 28),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PassonRide OBD-II IoT Node', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('Device ID: #IOT-NODE-9941 (Connected)', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('IoT Telematics Node Test Signal Verified!')),
                    );
                  },
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                  child: const Text('Test Lock', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting
                  ? null
                  : () async {
                      if (_isSubmitting) return;

                      setState(() {
                        _isSubmitting = true;
                      });

                      try {
                        final title = _titleController.text.trim();
                        final price = double.tryParse(_priceController.text.trim()) ?? 500.0;
                        final isCar = _selectedCategory.contains('Car');
                        final isScooter = _selectedCategory.contains('Scooter');
                        final isElectric = _selectedCategory.contains('Electric') || _selectedFuelType == 'Electric';

                        String coverImageUrl = _vehiclePhotos.isNotEmpty
                            ? _vehiclePhotos.first
                            : (isCar
                                ? 'https://images.unsplash.com/photo-1560958089-b8a1929cea89?w=800&q=80'
                                : (isScooter
                                    ? 'https://images.unsplash.com/photo-1558981806-ec527fa84c39?w=800&q=80'
                                    : 'https://images.unsplash.com/photo-1558981403-c5f9899a28bc?w=800&q=80'));

                        final newVehicle = Vehicle(
                          id: 'v_${DateTime.now().millisecondsSinceEpoch}',
                          title: title.isEmpty ? 'Custom Vehicle Listing' : title,
                          type: isElectric
                              ? VehicleType.electric
                              : (isCar ? VehicleType.car : (isScooter ? VehicleType.scooter : VehicleType.bike)),
                          category: _selectedCategory,
                          pricePerDay: price,
                          rating: 5.0,
                          reviewCount: 1,
                          imageUrl: coverImageUrl,
                          images: _vehiclePhotos.isNotEmpty ? _vehiclePhotos : [coverImageUrl],
                          location: _locationController.text.trim().isNotEmpty
                              ? _locationController.text.trim()
                              : appState.selectedLocation,
                          latitude: 22.5726 + (DateTime.now().millisecondsSinceEpoch % 100) * 0.001,
                          longitude: 88.3639 + (DateTime.now().millisecondsSinceEpoch % 100) * 0.001,
                          status: 'Available',
                          hostName: appState.activeUserDisplayName,
                          hostAvatar: appState.activeUserPhotoUrl,
                          hostTrustScore: appState.activeUserTrustScore,
                          hostId: appState.userProfile?.uid ?? appState.supabaseUser?.id ?? '',
                          fuelType: _selectedFuelType,
                          transmission: _selectedTransmission,
                          seats: _seats,
                          description: _descriptionController.text.trim().isNotEmpty
                              ? _descriptionController.text.trim()
                              : 'Freshly registered rental listing. Maintained in prime condition with keyless IoT access.',
                          iotData: {
                            'locked': true,
                            'engineOn': false,
                            'batteryLevel': 98,
                            'odometer': 1200,
                            'tirePressureFront': 32.0,
                            'tirePressureRear': 35.0,
                            'lat': 22.5726,
                            'lng': 88.3639,
                          },
                        );

                        await appState.addVehicle(newVehicle);

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Vehicle "${newVehicle.title}" published live!'),
                              backgroundColor: Colors.green.shade700,
                            ),
                          );
                          appState.selectVehicle(newVehicle);
                          _titleController.clear();
                          _priceController.clear();
                          _locationController.clear();
                          _descriptionController.clear();
                          if (mounted) {
                            setState(() {
                              _vehiclePhotos.clear();
                              _isSubmitting = false;
                            });
                          }
                          appState.setNavIndex(8); // Redirect to Host Dashboard (Nav Index 8)
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error publishing vehicle: $e'), backgroundColor: Colors.red.shade800),
                          );
                        }
                      } finally {
                        if (mounted) {
                          setState(() {
                            _isSubmitting = false;
                          });
                        }
                      }
                    },
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Icon(Icons.publish),
              label: Text(
                _isSubmitting ? 'Publishing Vehicle...' : 'Publish Vehicle Listing',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
