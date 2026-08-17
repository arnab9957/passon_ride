import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/app_state.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';
import 'location_screen.dart';

class RegisterTourScreen extends StatefulWidget {
  const RegisterTourScreen({super.key});

  @override
  State<RegisterTourScreen> createState() => _RegisterTourScreenState();
}

class _RegisterTourScreenState extends State<RegisterTourScreen> {
  final _titleController = TextEditingController(text: 'Sierra Nevada Alpine Ridge Tour');
  final _priceController = TextEditingController(text: '179.00');
  final _locationController = TextEditingController(text: 'Lake Tahoe, CA');
  final _picker = ImagePicker();

  String? _selectedTourImageUrl;
  bool _isUploadingImage = false;
  final List<String> _tourPhotos = [];

  final List<String> _presetTourImages = [
    'https://ik.imagekit.io/hsqoovxu0/tours/tour_1786900455239_aQc5pXYg77.jpg',
    'https://ik.imagekit.io/hsqoovxu0/tours/tour_1786900457035_ejzTSFqJD.jpg',
    'https://ik.imagekit.io/hsqoovxu0/tours/tour_1786900458573_elHJZC1SJl.jpg',
    'https://ik.imagekit.io/hsqoovxu0/tours/tour_1786898499747_FbsCuXtW-.jpg',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      final draft = appState.draftTourFromAi;
      if (draft != null) {
        _titleController.text = draft.title;
        _priceController.text = draft.price.toStringAsFixed(0);
        _locationController.text = draft.location;
        if (draft.imageUrl.isNotEmpty) {
          setState(() {
            _selectedTourImageUrl = draft.imageUrl;
            if (draft.images.isNotEmpty) {
              _tourPhotos.addAll(draft.images);
            }
          });
        }
      }
    });
  }

  Future<void> _pickAndUploadTourImage() async {
    final appState = Provider.of<AppState>(context, listen: false);
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFiles.isNotEmpty) {
        setState(() => _isUploadingImage = true);
        for (var file in pickedFiles) {
          final bytes = await file.readAsBytes();
          final ikUrl = await appState.imageKitService.uploadImage(
            bytes: bytes,
            fileName: 'tour_${DateTime.now().millisecondsSinceEpoch}.jpg',
            folder: '/tours',
          );
          final finalUrl = ikUrl ?? 'data:image/jpeg;base64,${base64Encode(bytes)}';
          if (!_tourPhotos.contains(finalUrl)) {
            _tourPhotos.add(finalUrl);
          }
        }

        setState(() {
          if (_tourPhotos.isNotEmpty) {
            _selectedTourImageUrl = _tourPhotos.first;
          }
          _isUploadingImage = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${pickedFiles.length} Tour photos uploaded to ImageKit CDN!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isUploadingImage = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading tour image: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final draft = appState.draftTourFromAi;
    final currentCoverUrl = _selectedTourImageUrl ?? draft?.imageUrl ?? _presetTourImages.first;

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
                    'GUIDE WIZARD',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: isDark ? AppColors.secondaryFixedDim : AppColors.secondary,
                    ),
                  ),
                  const Text('Register Guided Tour', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Tour Image Cover Upload Section
          const Text('Tour Cover & Banner Image', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight),
              image: DecorationImage(
                image: NetworkImage(currentCoverUrl),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('PREVIEW', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isUploadingImage ? null : _pickAndUploadTourImage,
                    icon: _isUploadingImage
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.cloud_upload),
                    label: Text(_isUploadingImage ? 'Uploading Image...' : 'Upload Tour Cover Photo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Or Select Preset Route Style Image:', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 6),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _presetTourImages.length,
              itemBuilder: (context, idx) {
                final img = _presetTourImages[idx];
                final isSelected = currentCoverUrl == img;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTourImageUrl = img),
                  child: Container(
                    width: 70,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        width: isSelected ? 2.5 : 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(img, fit: BoxFit.cover),
                  ),
                );
              },
            ),
          ),

          const Text('Tour Details & Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),

          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Tour Experience Title',
              prefixIcon: Icon(Icons.tour),
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _locationController,
            decoration: InputDecoration(
              labelText: 'Starting Location / Region',
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
          const SizedBox(height: 20),

          // Dedicated Pricing & Financial Payout Card
          const Text('Tour Pricing & Financial Payout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  onChanged: (val) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Set Price Per Rider (₹ INR)',
                    prefixIcon: Icon(Icons.currency_rupee, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Quick Select Price Tiers:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: ['999', '1999', '3499', '4999'].map((p) {
                    return ChoiceChip(
                      label: Text('₹$p'),
                      selected: _priceController.text == p,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _priceController.text = p;
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
                const Divider(height: 24),
                Builder(
                  builder: (context) {
                    final priceVal = double.tryParse(_priceController.text.trim()) ?? 0.0;
                    final fee = priceVal * 0.05;
                    final hostNet = priceVal - fee;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('ESTIMATED NET EARNINGS', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(
                              '₹${hostNet.toStringAsFixed(0)} / rider',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          ],
                        ),
                        Text(
                          '(5% platform fee: ₹${fee.toStringAsFixed(0)})',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text('Waypoints & Stops', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),

          _buildWaypointTile('Stop 1', 'Emerald Bay Lookout Point'),
          _buildWaypointTile('Stop 2', 'Mount Rose Summit Peak'),
          _buildWaypointTile('Stop 3', 'High Alpine Cafe Lunch Break'),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () async {
                final title = _titleController.text.trim();
                final price = double.tryParse(_priceController.text.trim()) ?? 179.0;
                final location = _locationController.text.trim();

                final newTour = Tour(
                  id: 't_${DateTime.now().millisecondsSinceEpoch}',
                  title: title.isEmpty ? (draft?.title ?? 'Sierra Nevada Alpine Ridge Tour') : title,
                  location: location.isEmpty ? (draft?.location ?? 'Lake Tahoe, CA') : location,
                  price: price,
                  duration: draft?.duration ?? 'Full Day (6 hrs)',
                  rating: 5.0,
                  reviewCount: 1,
                  imageUrl: currentCoverUrl,
                  images: _tourPhotos.isNotEmpty ? _tourPhotos : [currentCoverUrl],
                  guideName: appState.activeUserDisplayName,
                  guideAvatar: appState.activeUserPhotoUrl,
                  hostId: appState.userProfile?.uid ?? appState.supabaseUser?.id ?? '',
                  waypoints: draft?.waypoints.isNotEmpty == true
                      ? draft!.waypoints
                      : ['Emerald Bay Lookout', 'Mount Rose Peak', 'High Alpine Cafe'],
                  includedGear: draft?.includedGear.isNotEmpty == true
                      ? draft!.includedGear
                      : ['Full Face Helmet', 'Bluetooth Intercom', 'Roadside Assist'],
                  description: draft?.description.isNotEmpty == true
                      ? draft!.description
                      : 'Experience guided mountain roads with an experienced local host.',
                );

                await appState.addTour(newTour);
                appState.clearDraftTourFromAi();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Guided Tour "$title" Published Live!'),
                      backgroundColor: Colors.green.shade700,
                    ),
                  );
                  appState.setNavIndex(8);
                }
              },
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Publish Guided Tour', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildWaypointTile(String stop, String desc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.place, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Text(stop, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(width: 12),
          Expanded(child: Text(desc, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}
