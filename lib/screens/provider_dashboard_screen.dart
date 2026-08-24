import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../providers/app_state.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';
import '../widgets/tour_details_modal.dart';

class ProviderDashboardScreen extends StatelessWidget {
  const ProviderDashboardScreen({super.key});

  void _confirmDeleteVehicle(BuildContext context, AppState appState, Vehicle vehicle) {
    if (!appState.isHostOfVehicle(vehicle) && appState.activeUserRole.toLowerCase() != 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Unauthorized: Only the host of this vehicle can remove it from the server.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
            SizedBox(width: 8),
            Expanded(child: Text('Delete Vehicle Listing?')),
          ],
        ),
        content: Text('Are you sure you want to permanently delete "${vehicle.title}" from the marketplace? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await appState.deleteVehicle(vehicle.id);
              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Vehicle "${vehicle.title}" deleted permanently.'),
                      backgroundColor: Colors.red.shade800,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('⚠️ Unauthorized: Only the host profile can remove this vehicle.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete Permanently', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteTour(BuildContext context, AppState appState, Tour tour) {
    if (!appState.isHostOfTour(tour) && appState.activeUserRole.toLowerCase() != 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Unauthorized: Only the host/guide of this tour can remove it from the server.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
            SizedBox(width: 8),
            Expanded(child: Text('Delete Guided Tour?')),
          ],
        ),
        content: Text('Are you sure you want to permanently delete "${tour.title}" from the marketplace?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await appState.deleteTour(tour.id);
              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Guided Tour "${tour.title}" deleted.'),
                      backgroundColor: Colors.red.shade800,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('⚠️ Unauthorized: Only the host profile can remove this tour.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete Permanently', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditTourDialog(BuildContext context, AppState appState, Tour tour) {
    final titleController = TextEditingController(text: tour.title);
    final priceController = TextEditingController(text: tour.price.toStringAsFixed(0));
    final locationController = TextEditingController(text: tour.location);
    final descriptionController = TextEditingController(text: tour.description);
    final List<String> tourImages = List<String>.from(tour.images.isNotEmpty ? tour.images : [tour.imageUrl]);
    bool isUploadingImage = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.edit_location_alt, color: AppColors.secondary, size: 28),
              SizedBox(width: 8),
              Text('Edit Guided Tour'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tour Photo Gallery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),

                // Multi-Image Gallery Row
                if (tourImages.isNotEmpty)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(tourImages.length, (i) {
                        final img = tourImages[i];
                        return Stack(
                          children: [
                            Container(
                              width: 100,
                              height: 90,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade400),
                                image: DecorationImage(
                                  image: NetworkImage(appState.imageKitService.buildImageUrl(img)),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 12,
                              child: GestureDetector(
                                onTap: () => setState(() {
                                  tourImages.removeAt(i);
                                  if (tourImages.isEmpty) {
                                    tourImages.add('https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=800&q=80');
                                  }
                                }),
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, color: Colors.white, size: 12),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),

                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: isUploadingImage
                        ? null
                        : () async {
                            final ImagePicker picker = ImagePicker();
                            try {
                              final List<XFile> pickedFiles = await picker.pickMultiImage(
                                maxWidth: 1920,
                                maxHeight: 1080,
                                imageQuality: 85,
                              );
                              if (pickedFiles.isNotEmpty) {
                                setState(() => isUploadingImage = true);
                                for (var file in pickedFiles) {
                                  final bytes = await file.readAsBytes();
                                  final ikUrl = await appState.imageKitService.uploadImage(
                                    bytes: bytes,
                                    fileName: 'tour_${DateTime.now().millisecondsSinceEpoch}.jpg',
                                    folder: '/tours',
                                  );
                                  final finalUrl = ikUrl ?? 'data:image/jpeg;base64,${base64Encode(bytes)}';
                                  if (!tourImages.contains(finalUrl)) {
                                    tourImages.add(finalUrl);
                                  }
                                }
                                setState(() => isUploadingImage = false);
                              }
                            } catch (e) {
                              setState(() => isUploadingImage = false);
                            }
                          },
                    icon: isUploadingImage
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.add_photo_alternate, size: 16),
                    label: Text(isUploadingImage ? 'Uploading Photos...' : 'Add Multiple Photos to Gallery'),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Tour Experience Title',
                    prefixIcon: Icon(Icons.tour),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Starting Location',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Price Per Rider (₹ INR)',
                    prefixIcon: Icon(Icons.currency_rupee),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Tour Description',
                    prefixIcon: Icon(Icons.description),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
              onPressed: () async {
                Navigator.pop(ctx);
                final updated = tour.copyWith(
                  title: titleController.text.trim(),
                  location: locationController.text.trim(),
                  price: double.tryParse(priceController.text.trim()) ?? tour.price,
                  description: descriptionController.text.trim(),
                  imageUrl: tourImages.isNotEmpty ? tourImages.first : tour.imageUrl,
                  images: tourImages,
                );
                await appState.updateTour(updated);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Tour "${updated.title}" updated with ${tourImages.length} photo(s)!'),
                      backgroundColor: Colors.green.shade700,
                    ),
                  );
                }
              },
              child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditVehicleDialog(BuildContext context, AppState appState, Vehicle vehicle) {
    final titleController = TextEditingController(text: vehicle.title);
    final priceController = TextEditingController(text: vehicle.pricePerDay.toStringAsFixed(0));
    final locationController = TextEditingController(text: vehicle.location);
    final descriptionController = TextEditingController(text: vehicle.description);
    final List<String> vehicleImages = List<String>.from(vehicle.images.isNotEmpty ? vehicle.images : [vehicle.imageUrl]);
    String selectedFuelType = vehicle.fuelType;
    String selectedTransmission = vehicle.transmission;
    bool isUploadingImage = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.edit_note, color: AppColors.primary, size: 28),
              SizedBox(width: 8),
              Text('Edit Vehicle Details'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Vehicle Photo Gallery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),

                // Multi-Image Gallery Row
                if (vehicleImages.isNotEmpty)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(vehicleImages.length, (i) {
                        final img = vehicleImages[i];
                        return Stack(
                          children: [
                            Container(
                              width: 100,
                              height: 90,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade400),
                                image: DecorationImage(
                                  image: NetworkImage(appState.imageKitService.buildImageUrl(img)),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 12,
                              child: GestureDetector(
                                onTap: () => setState(() {
                                  vehicleImages.removeAt(i);
                                }),
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, color: Colors.white, size: 12),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),

                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: isUploadingImage
                        ? null
                        : () async {
                            final ImagePicker picker = ImagePicker();
                            try {
                              final List<XFile> pickedFiles = await picker.pickMultiImage(
                                maxWidth: 1920,
                                maxHeight: 1080,
                                imageQuality: 85,
                              );
                              if (pickedFiles.isNotEmpty) {
                                setState(() => isUploadingImage = true);
                                for (var file in pickedFiles) {
                                  final bytes = await file.readAsBytes();
                                  final ikUrl = await appState.imageKitService.uploadImage(
                                    bytes: bytes,
                                    fileName: 'vehicle_${DateTime.now().millisecondsSinceEpoch}.jpg',
                                    folder: '/vehicles',
                                  );
                                  final finalUrl = ikUrl ?? 'data:image/jpeg;base64,${base64Encode(bytes)}';
                                  if (!vehicleImages.contains(finalUrl)) {
                                    vehicleImages.add(finalUrl);
                                  }
                                }
                                setState(() => isUploadingImage = false);
                              }
                            } catch (e) {
                              setState(() => isUploadingImage = false);
                            }
                          },
                    icon: isUploadingImage
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.add_photo_alternate, size: 16),
                    label: Text(isUploadingImage ? 'Uploading Photos...' : 'Add Multiple Photos to Gallery'),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Vehicle Title / Model',
                    prefixIcon: Icon(Icons.directions_car),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Daily Rental Rate (₹ INR)',
                    prefixIcon: Icon(Icons.currency_rupee),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Pickup Location / City',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedFuelType,
                        decoration: const InputDecoration(labelText: 'Fuel Type'),
                        items: ['Petrol', 'Diesel', 'Electric', 'Gasoline', 'Hybrid', 'CNG']
                            .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => selectedFuelType = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedTransmission,
                        decoration: const InputDecoration(labelText: 'Transmission'),
                        items: ['Manual', 'Automatic']
                            .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => selectedTransmission = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Vehicle Description',
                    prefixIcon: Icon(Icons.description),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final newPrice = double.tryParse(priceController.text.trim()) ?? vehicle.pricePerDay;
                final updatedVehicle = vehicle.copyWith(
                  title: titleController.text.trim().isNotEmpty ? titleController.text.trim() : vehicle.title,
                  pricePerDay: newPrice,
                  location: locationController.text.trim().isNotEmpty ? locationController.text.trim() : vehicle.location,
                  fuelType: selectedFuelType,
                  transmission: selectedTransmission,
                  description: descriptionController.text.trim().isNotEmpty ? descriptionController.text.trim() : vehicle.description,
                  imageUrl: vehicleImages.isNotEmpty ? vehicleImages.first : vehicle.imageUrl,
                  images: vehicleImages,
                );

                Navigator.pop(ctx);
                await appState.updateVehicle(updatedVehicle);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Vehicle "${updatedVehicle.title}" updated with ${vehicleImages.length} photo(s)!'),
                      backgroundColor: Colors.green.shade700,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Save Changes', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final currentUid = appState.userProfile?.uid ?? appState.supabaseUser?.id ?? '';
    final currentDisplayName = appState.activeUserDisplayName;

    final myVehicles = appState.vehicles.where((v) {
      if (currentUid.isNotEmpty && v.hostId.isNotEmpty) {
        return v.hostId == currentUid;
      }
      if (v.hostName.isNotEmpty && currentDisplayName != 'Guest User' && v.hostName == currentDisplayName) {
        return true;
      }
      if (v.id.startsWith('v_')) {
        return true;
      }
      return v.hostId.isEmpty;
    }).toList();

    final myTours = appState.tours.where((t) {
      if (currentUid.isNotEmpty && t.hostId.isNotEmpty) {
        return t.hostId == currentUid;
      }
      if (t.guideName.isNotEmpty && currentDisplayName != 'Guest User' && t.guideName == currentDisplayName) {
        return true;
      }
      return true;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HOST PORTAL',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: isDark ? AppColors.secondaryFixedDim : AppColors.secondary,
                    ),
                  ),
                  const Text('Provider Dashboard', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified, size: 14, color: AppColors.onSecondaryContainer),
                    SizedBox(width: 4),
                    Text('SUPERHOST', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.onSecondaryContainer)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Quick Action Cards
          const Text('Management Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionTile(
                  context,
                  'Add Vehicle',
                  'Register new car or bike',
                  Icons.add_a_photo,
                  AppColors.primary,
                  () => appState.setNavIndex(10), // Register vehicle wizard
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionTile(
                  context,
                  'Add Tour',
                  'Create local guided tour',
                  Icons.add_location_alt,
                  AppColors.secondary,
                  () => appState.setNavIndex(11), // Register tour wizard
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // My Hosted Vehicle Listings Section (Edit & Delete Management)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Hosted Vehicle Listings (${myVehicles.length})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () => appState.setNavIndex(10),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Listing', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (myVehicles.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.directions_car_outlined, size: 48, color: Colors.grey),
                  const SizedBox(height: 8),
                  const Text('No vehicles registered yet.', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Click "Add Listing" to host your bike or car on PassionRide.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => appState.setNavIndex(10),
                    icon: const Icon(Icons.add_a_photo, size: 16),
                    label: const Text('Register Vehicle Now'),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: myVehicles.length,
              itemBuilder: (ctx, i) {
                final vehicle = myVehicles[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              vehicle.imageUrl,
                              height: 60,
                              width: 75,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => Container(
                                height: 60,
                                width: 75,
                                color: Colors.grey.shade300,
                                child: const Icon(Icons.directions_car),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        vehicle.title,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: vehicle.status == 'Available'
                                            ? Colors.green.shade100
                                            : (vehicle.status == 'Maintenance' ? Colors.orange.shade100 : Colors.blue.shade100),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        vehicle.status.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: vehicle.status == 'Available'
                                              ? Colors.green.shade800
                                              : (vehicle.status == 'Maintenance' ? Colors.orange.shade900 : Colors.blue.shade900),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '₹${vehicle.pricePerDay.toStringAsFixed(0)} / day • ${vehicle.fuelType} • ${vehicle.location}',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              final newStatus = vehicle.status == 'Maintenance' ? 'Available' : 'Maintenance';
                              appState.updateVehicleStatus(vehicle.id, newStatus);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Vehicle status changed to $newStatus')),
                              );
                            },
                            icon: Icon(
                              vehicle.status == 'Maintenance' ? Icons.build_circle : Icons.build_circle_outlined,
                              size: 14,
                              color: vehicle.status == 'Maintenance' ? Colors.orange.shade800 : Colors.grey,
                            ),
                            label: Text(
                              vehicle.status == 'Maintenance' ? 'Set Available' : 'Maintenance',
                              style: const TextStyle(fontSize: 11),
                            ),
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                          ),
                          const SizedBox(width: 6),
                          OutlinedButton.icon(
                            onPressed: () {
                              appState.selectVehicle(vehicle);
                              appState.setNavIndex(2); // View details
                            },
                            icon: const Icon(Icons.visibility, size: 14),
                            label: const Text('View', style: TextStyle(fontSize: 11)),
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                          ),
                          const SizedBox(width: 6),
                          ElevatedButton.icon(
                            onPressed: () => _showEditVehicleDialog(context, appState, vehicle),
                            icon: const Icon(Icons.edit, size: 14),
                            label: const Text('Edit Details', style: TextStyle(fontSize: 11)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            onPressed: () => _confirmDeleteVehicle(context, appState, vehicle),
                            icon: const Icon(Icons.delete_forever, color: Colors.redAccent, size: 20),
                            tooltip: 'Delete Vehicle Listing',
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

          const SizedBox(height: 24),

          // My Hosted Guided Tours Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Hosted Guided Tours (${myTours.length})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () => appState.setNavIndex(11), // Register tour wizard
                icon: const Icon(Icons.add_location_alt, size: 16),
                label: const Text('Add Tour', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (myTours.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.tour_outlined, size: 48, color: Colors.grey),
                  const SizedBox(height: 8),
                  const Text('No guided tours registered yet.', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Click "Add Tour" or use AI Tour Generator to publish your route.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => appState.setNavIndex(11),
                    icon: const Icon(Icons.add_location_alt, size: 16),
                    label: const Text('Register Guided Tour Now'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, foregroundColor: Colors.white),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: myTours.length,
              itemBuilder: (ctx, i) {
                final tour = myTours[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              tour.imageUrl,
                              height: 60,
                              width: 75,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => Container(
                                height: 60,
                                width: 75,
                                color: Colors.grey.shade300,
                                child: const Icon(Icons.tour),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        tour.title,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'LIVE',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '₹${tour.price.toStringAsFixed(0)} / rider • ${tour.duration} • ${tour.location}',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              appState.selectTour(tour);
                              showTourDetailsModal(context, appState, tour, isHostView: true);
                            },
                            icon: const Icon(Icons.visibility, size: 14),
                            label: const Text('View', style: TextStyle(fontSize: 11)),
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                          ),
                          const SizedBox(width: 6),
                          ElevatedButton.icon(
                            onPressed: () => _showEditTourDialog(context, appState, tour),
                            icon: const Icon(Icons.edit, size: 14),
                            label: const Text('Edit Details', style: TextStyle(fontSize: 11)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            onPressed: () => _confirmDeleteTour(context, appState, tour),
                            icon: const Icon(Icons.delete_forever, color: Colors.redAccent, size: 20),
                            tooltip: 'Delete Guided Tour',
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

          const SizedBox(height: 24),

          // Bookings & Rental Requests Shortcut Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month, color: AppColors.primary, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Upcoming Requests & Active Bookings',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        '${appState.activeBookings.length} active & confirmed bookings managed in dedicated My Bookings page.',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => appState.setNavIndex(19), // My Bookings Page
                  icon: const Icon(Icons.arrow_forward, size: 14),
                  label: const Text('View All', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildMetricCard(BuildContext context, String val, String title, String sub, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              Text(sub, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
            ],
          ),
          const Spacer(),
          Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, String title, String sub, IconData icon, Color color, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(sub, style: const TextStyle(fontSize: 10, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAnumodanApprovalDialog(BuildContext context, AppState appState, Booking booking) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Auto-detect vehicle registration plate from vehicle title or ID
    final detectedRegPlate = 'WB-02-AK-${(booking.vehicleId.hashCode % 9000 + 1000).abs()}';
    const anumodanUrl = 'https://anumodan.wb.gov.in';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          width: 850,
          constraints: const BoxConstraints(maxHeight: 700),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dialog Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.shade700,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WEST BENGAL TRANSPORT PERMIT VERIFICATION',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: Colors.green),
                          ),
                          Text(
                            'Host Approval & Anumodan Portal',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Auto-Detect Vehicle Banner Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceContainerLow : Colors.blue.shade50,
                    border: Border.all(color: Colors.blue.shade300),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.directions_bike, color: Colors.blue, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('AUTO-DETECTED VEHICLE: ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: Colors.amber.shade600, borderRadius: BorderRadius.circular(6)),
                                  child: Text(detectedRegPlate, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${booking.vehicleTitle} • Renter: ${booking.hostName}',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.blue.shade200 : Colors.blue.shade900),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: detectedRegPlate));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Copied vehicle plate $detectedRegPlate to clipboard!'), duration: const Duration(seconds: 2)),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 14),
                        label: const Text('Copy Reg Plate', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Portal Status & Direct Launch Dashboard View
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceContainerHigh : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppColors.outlineVariantDark : Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.language, color: Colors.green.shade700, size: 22),
                          const SizedBox(width: 8),
                          const Text(
                            'Government of West Bengal • Transport Department',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.circle, color: Colors.green.shade800, size: 8),
                                const SizedBox(width: 6),
                                Text(
                                  'Portal Active',
                                  style: TextStyle(color: Colors.green.shade900, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Official URL: $anumodanUrl',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const Divider(height: 24),
                      const Text(
                        'Automated Permit & Fitness Checks:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      _buildVerificationCheckItem('Commercial State Transport Permit', 'Verified on Anumodan System', true),
                      const SizedBox(height: 8),
                      _buildVerificationCheckItem('Vehicle Road Tax & Fitness Certificate', 'Active & Valid until 2027', true),
                      const SizedBox(height: 8),
                      _buildVerificationCheckItem('Pollution Under Control (PUC)', 'Passed Emission Standard', true),
                      const SizedBox(height: 8),
                      _buildVerificationCheckItem('Renter KYC & Driving License Match', 'Identity Matched', true),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final uri = Uri.parse(anumodanUrl);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          },
                          icon: const Icon(Icons.open_in_new, color: Colors.white, size: 18),
                          label: const Text('Open Official Anumodan Portal (anumodan.wb.gov.in)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Responsive Wrap Bottom Approval Action Bar (Prevents 18px Overflow)
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        final uri = Uri.parse(anumodanUrl);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      icon: const Icon(Icons.open_in_new, size: 14),
                      label: const Text('Open Portal in New Tab', style: TextStyle(fontSize: 12)),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await appState.completeBookingRental(booking.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Vehicle ${booking.vehicleTitle} verified on Anumodan Portal & Host Approval granted!'),
                                  backgroundColor: Colors.green.shade800,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.verified, color: Colors.white, size: 18),
                          label: const Text('Verify Anumodan Permit & Approve Rental', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmBikeReturnAndStopGps(BuildContext context, AppState appState, Booking booking, BuildContext? modalCtx) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.teal, size: 28),
            SizedBox(width: 8),
            Expanded(child: Text('Confirm Bike Return?')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Confirm that the renter has successfully returned "${booking.vehicleTitle}".'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.teal.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('⏱️ Final Rental Duration: ${appState.getFormattedRentalDuration(booking)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                  const SizedBox(height: 4),
                  const Text('📡 Live GPS location tracking will be stopped.', style: TextStyle(fontSize: 12, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text('💰 Escrow payout of ₹${booking.totalPrice.toStringAsFixed(2)} will be marked released.', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                ],
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700),
            onPressed: () async {
              Navigator.pop(ctx);
              if (modalCtx != null && modalCtx.mounted) {
                Navigator.pop(modalCtx);
              }
              await appState.completeBookingRental(booking.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Bike returned! GPS tracking stopped & rental completed.'),
                    backgroundColor: Colors.teal.shade800,
                  ),
                );
              }
            },
            child: const Text('Confirm Return & Release', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showRiderLiveGpsModal(BuildContext context, AppState appState, Booking initialBooking) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final vehicle = appState.vehicles.firstWhere(
      (v) => v.id == initialBooking.vehicleId,
      orElse: () => appState.vehicles.first,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            // Fetch latest live booking state
            final booking = appState.activeBookings.firstWhere(
              (b) => b.id == initialBooking.id,
              orElse: () => initialBooking,
            );

            final riderLat = booking.riderLatitude ?? vehicle.latitude;
            final riderLng = booking.riderLongitude ?? vehicle.longitude;
            final riderPos = LatLng(riderLat, riderLng);
            final hubPos = LatLng(vehicle.latitude, vehicle.longitude);

            final isActive = booking.status == 'Active';
            final durationStr = appState.getFormattedRentalDuration(booking);
            final distanceStr = appState.getDistanceToRider(booking);

            return Container(
              height: MediaQuery.of(context).size.height * 0.90,
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLowest,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Modal Drag Indicator
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Top Header Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isActive ? Colors.green.shade100 : Colors.blue.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isActive ? Icons.gps_fixed : Icons.access_time,
                            color: isActive ? Colors.green.shade800 : Colors.blue.shade800,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Live GPS Telematics',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isActive ? Colors.green.shade700 : Colors.blueGrey,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      isActive ? '🟢 ACTIVE_RENTAL' : (booking.status == 'Completed' ? '🏁 BIKE_RETURNED' : '⏳ WAITING_FOR_PICKUP'),
                                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${booking.vehicleTitle} • Renter: ${booking.hostName}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),

                  // Real-time Telematics HUD Row
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceContainerLowest : AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildHudStat(
                          icon: Icons.timer,
                          iconColor: Colors.orange,
                          label: 'Rental Duration',
                          value: durationStr,
                        ),
                        Container(width: 1, height: 28, color: Colors.grey.shade300),
                        _buildHudStat(
                          icon: Icons.speed,
                          iconColor: Colors.blue,
                          label: 'Live Speed',
                          value: '${booking.riderSpeed.toStringAsFixed(0)} km/h',
                        ),
                        Container(width: 1, height: 28, color: Colors.grey.shade300),
                        _buildHudStat(
                          icon: Icons.near_me,
                          iconColor: Colors.green,
                          label: 'Hub Distance',
                          value: distanceStr,
                        ),
                        Container(width: 1, height: 28, color: Colors.grey.shade300),
                        _buildHudStat(
                          icon: Icons.satellite_alt,
                          iconColor: Colors.purple,
                          label: 'GPS Sync',
                          value: '5-10s live',
                        ),
                      ],
                    ),
                  ),

                  // Interactive Map Area
                  Expanded(
                    child: Stack(
                      children: [
                        ClipRRect(
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: riderPos,
                              initialZoom: 14.5,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.passon.ride',
                              ),
                              // Polyline connecting Hub to Rider
                              PolylineLayer(
                                polylines: [
                                  Polyline(
                                    points: [hubPos, riderPos],
                                    color: AppColors.secondary.withOpacity(0.8),
                                    strokeWidth: 3.5,
                                  ),
                                ],
                              ),
                              MarkerLayer(
                                markers: [
                                  // Hub Origin Marker
                                  Marker(
                                    point: hubPos,
                                    width: 44,
                                    height: 44,
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.black87,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text('HUB', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                                        ),
                                        const Icon(Icons.location_on, color: Colors.blueAccent, size: 24),
                                      ],
                                    ),
                                  ),
                                  // Rider Live Moving Marker
                                  Marker(
                                    point: riderPos,
                                    width: 80,
                                    height: 80,
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade800,
                                            borderRadius: BorderRadius.circular(6),
                                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.person_pin_circle, color: Colors.white, size: 10),
                                              const SizedBox(width: 2),
                                              Text(
                                                '${booking.riderSpeed.toStringAsFixed(0)} km/h',
                                                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Container(
                                              width: 38,
                                              height: 38,
                                              decoration: BoxDecoration(
                                                color: Colors.green.withOpacity(0.3),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: const BoxDecoration(
                                                color: Colors.green,
                                                shape: BoxShape.circle,
                                                boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 6)],
                                              ),
                                              child: Transform.rotate(
                                                angle: (booking.riderHeading * (3.141592653589793 / 180)),
                                                child: const Icon(Icons.navigation, color: Colors.white, size: 18),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Coordinates Pill Badge Overlay
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.my_location, color: Colors.greenAccent, size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  'GPS: ${riderLat.toStringAsFixed(4)}, ${riderLng.toStringAsFixed(4)}',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Direct Navigation Button
                        Positioned(
                          top: 12,
                          right: 12,
                          child: FloatingActionButton.small(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blue.shade800,
                            tooltip: 'Open in Google Maps',
                            onPressed: () async {
                              final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$riderLat,$riderLng');
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url, mode: LaunchMode.externalApplication);
                              }
                            },
                            child: const Icon(Icons.directions),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom Action Deck
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLowest,
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              appState.setNavIndex(5); // Open Chat
                            },
                            icon: const Icon(Icons.chat, size: 16),
                            label: const Text('Chat Rider'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (isActive)
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                _confirmBikeReturnAndStopGps(context, appState, booking, ctx);
                              },
                              icon: const Icon(Icons.stop_circle, size: 18),
                              label: const Text('Bike Returned (Stop GPS)', style: TextStyle(fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          )
                        else
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await appState.updateBookingStatus(booking.id, 'Active');
                                setModalState(() {});
                              },
                              icon: const Icon(Icons.play_arrow, size: 18),
                              label: const Text('Start Active Rental (Start GPS)'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHudStat({required IconData icon, required Color iconColor, required String label, required String value}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 13),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _showRiderVerificationModal(BuildContext context, AppState appState, Booking booking) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceContainerDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: FutureBuilder<UserProfile?>(
            future: appState.getUserProfile(booking.userId),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final profile = userSnapshot.data;
              if (profile == null) {
                return const Center(child: Text('Error loading renter profile.'));
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Renter Verification Portal',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.surfaceContainerHighDark : AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: AppColors.primary,
                                  backgroundImage: profile.photoUrl.isNotEmpty
                                      ? NetworkImage(profile.photoUrl)
                                      : null,
                                  child: profile.photoUrl.isEmpty
                                      ? Text(
                                          profile.displayName.isNotEmpty ? profile.displayName[0].toUpperCase() : 'U',
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        profile.displayName.isNotEmpty ? profile.displayName : 'Guest Renter',
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Email: ${profile.email.isNotEmpty ? profile.email : "N/A"}',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                      if (profile.phoneNumber.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          'Phone: ${profile.phoneNumber}',
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: profile.trustScore >= 80
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.amber.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: profile.trustScore >= 80 ? Colors.green : Colors.amber,
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(Icons.shield, size: 16, color: Colors.green),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${profile.trustScore.toStringAsFixed(0)} Trust',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: profile.trustScore >= 80 ? Colors.green : Colors.amber,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (profile.bio.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                'Bio: "${profile.bio}"',
                                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          const Text(
                            'Compliance Documents',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          FutureBuilder<List<ComplianceDocument>>(
                            future: appState.getComplianceDocumentsForUser(booking.userId),
                            builder: (context, docsSnapshot) {
                              if (docsSnapshot.connectionState == ConnectionState.waiting) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(24.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              final docs = docsSnapshot.data ?? [];
                              if (docs.isEmpty) {
                                return Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.surfaceContainerHighDark : AppColors.surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Column(
                                    children: [
                                      Icon(Icons.description_outlined, size: 40, color: Colors.grey),
                                      SizedBox(height: 8),
                                      Text(
                                        'No documents uploaded by this renter yet.',
                                        style: TextStyle(fontSize: 13, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: docs.length,
                                itemBuilder: (context, idx) {
                                  final doc = docs[idx];
                                  final isVerified = doc.status == 'Verified';
                                  final isActionRequired = doc.status == 'Action Required';

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.surfaceContainerHighDark : AppColors.surfaceContainerLowest,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                doc.title,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: isVerified
                                                    ? Colors.green.withOpacity(0.15)
                                                    : (isActionRequired
                                                        ? Colors.red.withOpacity(0.15)
                                                        : Colors.amber.withOpacity(0.15)),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: isVerified
                                                      ? Colors.green
                                                      : (isActionRequired ? Colors.red : Colors.amber),
                                                  width: 0.8,
                                                ),
                                              ),
                                              child: Text(
                                                doc.status.toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  color: isVerified
                                                      ? Colors.green
                                                      : (isActionRequired ? Colors.red : Colors.amber.shade900),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Divider(height: 20),
                                        _buildDetailRow('Holder Name', doc.holderName),
                                        _buildDetailRow('Document Number', doc.documentNumber),
                                        if (doc.licenseType.isNotEmpty && doc.title.toLowerCase().contains('license'))
                                          _buildDetailRow('License Type', doc.licenseType),
                                        _buildDetailRow('DOB', doc.dob),
                                        _buildDetailRow('Address', doc.address),
                                        _buildDetailRow('Issuing Authority', doc.issuingAuthority),
                                        _buildDetailRow('OCR Confidence', '${doc.confidenceScore.toStringAsFixed(1)}%'),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            if (doc.documentUrl.isNotEmpty)
                                              Expanded(
                                                child: OutlinedButton.icon(
                                                  onPressed: () async {
                                                    final uri = Uri.parse(doc.documentUrl);
                                                    if (await canLaunchUrl(uri)) {
                                                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                                                    }
                                                  },
                                                  icon: const Icon(Icons.open_in_new, size: 14),
                                                  label: const Text('View Document', style: TextStyle(fontSize: 11)),
                                                  style: OutlinedButton.styleFrom(
                                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                                  ),
                                                ),
                                              ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              flex: 2,
                                              child: Row(
                                                children: [
                                                  if (!isVerified)
                                                    Expanded(
                                                      child: ElevatedButton.icon(
                                                        onPressed: () async {
                                                          await appState.updateComplianceDocumentStatus(doc, 'Verified');
                                                          setModalState(() {}); // Refresh modal state
                                                        },
                                                        icon: const Icon(Icons.check, size: 14),
                                                        label: const Text('Verify', style: TextStyle(fontSize: 11)),
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: Colors.green,
                                                          foregroundColor: Colors.white,
                                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                                        ),
                                                      ),
                                                    ),
                                                  if (!isVerified && !isActionRequired)
                                                    const SizedBox(width: 6),
                                                  if (!isActionRequired)
                                                    Expanded(
                                                      child: ElevatedButton.icon(
                                                        onPressed: () async {
                                                          await appState.updateComplianceDocumentStatus(doc, 'Action Required');
                                                          setModalState(() {}); // Refresh modal state
                                                        },
                                                        icon: const Icon(Icons.warning, size: 14),
                                                        label: const Text('Flag', style: TextStyle(fontSize: 11)),
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: Colors.deepOrange,
                                                          foregroundColor: Colors.white,
                                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'N/A',
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationCheckItem(String title, String statusText, bool isPassed) {
    return Row(
      children: [
        Icon(
          isPassed ? Icons.check_circle : Icons.error,
          color: isPassed ? Colors.green.shade700 : Colors.orange,
          size: 18,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
        Text(
          statusText,
          style: TextStyle(fontSize: 12, color: isPassed ? Colors.green.shade800 : Colors.orange.shade800, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
