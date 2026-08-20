import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/app_state.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';
import 'location_screen.dart';

class RegisterTourScreen extends StatefulWidget {
  final Tour? existingTour;

  const RegisterTourScreen({super.key, this.existingTour});

  @override
  State<RegisterTourScreen> createState() => _RegisterTourScreenState();
}

class _RegisterTourScreenState extends State<RegisterTourScreen> {
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();
  final _guideNameController = TextEditingController();
  final _customGearController = TextEditingController();
  final _newWaypointController = TextEditingController();

  final _picker = ImagePicker();

  String? _selectedTourImageUrl;
  bool _isUploadingImage = false;
  final List<String> _tourPhotos = [];

  // Dynamic Waypoints list
  final List<String> _waypoints = [];

  // Dynamic Included Gear list
  final List<String> _includedGear = [];

  final List<String> _commonGearPresets = [
    'Action Cam / GoPro Helmet Mounts',
    'Fuel & Highway Toll Passes',
    'Rain Gear & Windbreaker Jackets',
    'Tire Inflator & Jump Starter',
    'High-Visibility Safety Vests',
    'Backup Vehicle & Sweep Rider',
  ];

  final List<String> _presetTourImages = [
    'https://ik.imagekit.io/hsqoovxu0/tours/tour_1786900455239_aQc5pXYg77.jpg',
    'https://ik.imagekit.io/hsqoovxu0/tours/tour_1786900457035_ejzTSFqJD.jpg',
    'https://ik.imagekit.io/hsqoovxu0/tours/tour_1786900458573_elHJZC1SJl.jpg',
    'https://ik.imagekit.io/hsqoovxu0/tours/tour_1786898499747_FbsCuXtW-.jpg',
  ];

  final List<String> _durationPresets = [
    'Half Day (3-4 hrs)',
    'Full Day (6-8 hrs)',
    'Sunset Ride (2-3 hrs)',
    'Weekend Expedition (2 Days)',
    'Multi-Day Cross Country (3-5 Days)',
  ];

  Tour? _currentEditingTour;

  DateTime _selectedExpiryDate = DateTime.now().add(const Duration(days: 90));

  @override
  void initState() {
    super.initState();
    _currentEditingTour = widget.existingTour;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);

      if (_currentEditingTour != null) {
        _populateFromTour(_currentEditingTour!);
      } else {
        final draft = appState.draftTourFromAi;
        if (draft != null) {
          _populateFromTour(draft);
        } else {
          _guideNameController.text = appState.activeUserDisplayName;
        }
      }
    });
  }

  void _populateFromTour(Tour tour) {
    setState(() {
      _titleController.text = tour.title;
      _priceController.text = tour.price.toStringAsFixed(0);
      _locationController.text = tour.location;
      _descriptionController.text = tour.description;
      _durationController.text = tour.duration.isNotEmpty ? tour.duration : 'Full Day (6-8 hrs)';
      _guideNameController.text = tour.guideName.isNotEmpty ? tour.guideName : 'Lead Host Guide';
      if (tour.expiryDate != null) {
        _selectedExpiryDate = tour.expiryDate!;
      }

      if (tour.imageUrl.isNotEmpty) {
        _selectedTourImageUrl = tour.imageUrl;
      }
      if (tour.images.isNotEmpty) {
        _tourPhotos.clear();
        _tourPhotos.addAll(tour.images);
      }
      if (tour.waypoints.isNotEmpty) {
        _waypoints.clear();
        _waypoints.addAll(tour.waypoints);
      }
      if (tour.includedGear.isNotEmpty) {
        _includedGear.clear();
        _includedGear.addAll(tour.includedGear);
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _guideNameController.dispose();
    _customGearController.dispose();
    _newWaypointController.dispose();
    super.dispose();
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
              content: Text('${pickedFiles.length} Tour photos uploaded to CDN!'),
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

  void _showAddWaypointDialog() {
    _newWaypointController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.add_location_alt, color: AppColors.secondary),
            SizedBox(width: 8),
            Text('Add Route Stop / Waypoint'),
          ],
        ),
        content: TextField(
          controller: _newWaypointController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Waypoint Name & Landmark',
            hintText: 'e.g. Pinecrest Lake Vista Overlook',
            prefixIcon: Icon(Icons.pin_drop),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = _newWaypointController.text.trim();
              if (text.isNotEmpty) {
                setState(() => _waypoints.add(text));
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, foregroundColor: Colors.white),
            child: const Text('Add Stop'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final draft = appState.draftTourFromAi;
    final currentCoverUrl = _selectedTourImageUrl ?? draft?.imageUrl ?? _presetTourImages.first;
    final isEditing = _currentEditingTour != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        isEditing ? 'TOUR MANAGEMENT' : 'GUIDE WIZARD',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: isDark ? AppColors.secondaryFixedDim : AppColors.secondary,
                        ),
                      ),
                      Text(
                        isEditing ? 'Update Tour Details' : 'Register Guided Tour',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              if (appState.tours.isNotEmpty)
                PopupMenuButton<Tour>(
                  tooltip: 'Load Existing Tour to Edit',
                  icon: const Icon(Icons.tune, color: AppColors.secondary),
                  onSelected: (tour) {
                    _currentEditingTour = tour;
                    _populateFromTour(tour);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Loaded tour "${tour.title}" for editing!'),
                        backgroundColor: AppColors.secondary,
                      ),
                    );
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem<Tour>(
                      enabled: false,
                      child: Text('LOAD TOUR TO UPDATE:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                    ...appState.tours.map(
                      (t) => PopupMenuItem<Tour>(
                        value: t,
                        child: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Banner / Cover Photo Section
          const Text('Tour Cover & Banner Photos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Container(
            height: 190,
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
                  colors: [Colors.black.withOpacity(0.6), Colors.transparent, Colors.black.withOpacity(0.75)],
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
                      child: Text(
                        isEditing ? 'EDITING ACTIVE LISTING' : 'PREVIEW',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isUploadingImage ? null : _pickAndUploadTourImage,
                    icon: _isUploadingImage
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.cloud_upload),
                    label: Text(_isUploadingImage ? 'Uploading Photos...' : 'Upload HD Tour Photos'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Preset Photo Thumbnails
          const Text('Or Select Route Photo Preset:', style: TextStyle(fontSize: 12, color: Colors.grey)),
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

          const SizedBox(height: 24),

          // ==========================================
          // SECTION 1: CORE TOUR DETAILS & LOCATION
          // ==========================================
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: AppColors.secondary.withOpacity(0.15), shape: BoxShape.circle),
                      child: const Icon(Icons.info_outline, size: 18, color: AppColors.secondary),
                    ),
                    const SizedBox(width: 10),
                    const Text('Tour Overview & Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Tour Experience Title',
                    hintText: 'e.g. Sierra Nevada Alpine Ridge Tour',
                    prefixIcon: Icon(Icons.tour),
                  ),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: 'Starting Location / Region',
                    hintText: 'e.g. Lake Tahoe, CA or Manali, HP',
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
                      label: const Text('Pick Location', style: TextStyle(fontSize: 11)),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Comprehensive Description Field
                TextField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Detailed Tour Description & Highlights',
                    hintText: 'e.g. Experience sweeping mountain hairpins, panoramic lake vistas, and scenic alpine summits with an experienced local guide. Suitable for cruiser and adventure riders looking for scenic routes...',
                    alignLabelWithHint: true,
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 50),
                      child: Icon(Icons.description),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Tour Duration Selector
                const Text('Tour Duration & Riding Time:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _durationPresets.map((dur) {
                    final isSelected = _durationController.text == dur;
                    return ChoiceChip(
                      label: Text(dur, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                      selected: isSelected,
                      selectedColor: AppColors.secondary.withOpacity(0.2),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _durationController.text = dur);
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _durationController,
                  decoration: const InputDecoration(
                    labelText: 'Custom Duration Label',
                    hintText: 'e.g. Full Day (6-8 hrs) or 2 Days Expedition',
                    prefixIcon: Icon(Icons.schedule),
                  ),
                ),
                const SizedBox(height: 16),

                // Tour Expiry Date Picker
                const Text('Tour Expiry Date (Valid Until):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedExpiryDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 1095)),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedExpiryDate = picked;
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceContainerHighDark : AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.event_available, color: AppColors.secondary, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              'Valid Until: ${_selectedExpiryDate.day.toString().padLeft(2, '0')}/${_selectedExpiryDate.month.toString().padLeft(2, '0')}/${_selectedExpiryDate.year}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                        const Icon(Icons.edit_calendar, color: AppColors.secondary, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ==========================================
          // SECTION 2: DYNAMIC ROUTE WAYPOINTS BUILDER
          // ==========================================
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: Colors.blue.withOpacity(0.15), shape: BoxShape.circle),
                          child: const Icon(Icons.alt_route, size: 18, color: Colors.blue),
                        ),
                        const SizedBox(width: 10),
                        const Text('Route Itinerary & Waypoints', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: _showAddWaypointDialog,
                      icon: const Icon(Icons.add, size: 14),
                      label: const Text('Add Stop', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Define key scenic lookout points, rest breaks, and landmarks along your guided route (${_waypoints.length} stops configured):',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 12),

                if (_waypoints.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('No waypoints added yet. Tap "+ Add Stop" to configure itinerary.', style: TextStyle(color: Colors.grey)),
                  )
                else
                  ..._waypoints.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final stop = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceContainerHighDark : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Stop ${idx + 1}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              stop,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                            onPressed: () {
                              setState(() => _waypoints.removeAt(idx));
                            },
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ==========================================
          // SECTION 3: INCLUDED SAFETY GEAR & PERKS
          // ==========================================
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.teal.withOpacity(0.15), shape: BoxShape.circle),
                      child: const Icon(Icons.verified_user, size: 18, color: Colors.teal),
                    ),
                    const SizedBox(width: 10),
                    const Text('Included Safety Gear & Rider Perks', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Select all safety equipment, connectivity tools, and amenities provided to riders on this tour:',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 12),

                // Active Included Items Chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _includedGear.map((gear) {
                    return Chip(
                      avatar: const Icon(Icons.check_circle, size: 16, color: Colors.teal),
                      label: Text(gear, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      backgroundColor: Colors.teal.withOpacity(0.12),
                      deleteIcon: const Icon(Icons.cancel, size: 16),
                      onDeleted: () {
                        setState(() => _includedGear.remove(gear));
                      },
                    );
                  }).toList(),
                ),

                const Divider(height: 24),

                const Text('Quick Add Preset Perks:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _commonGearPresets.map((preset) {
                    final alreadyAdded = _includedGear.contains(preset);
                    return ActionChip(
                      label: Text(preset, style: TextStyle(fontSize: 11, color: alreadyAdded ? Colors.grey : null)),
                      avatar: Icon(alreadyAdded ? Icons.check : Icons.add, size: 14),
                      onPressed: alreadyAdded
                          ? null
                          : () {
                              setState(() => _includedGear.add(preset));
                            },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 14),

                // Custom Gear Input
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customGearController,
                        decoration: const InputDecoration(
                          hintText: 'Add custom perk (e.g. Drone Video Footage)',
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        final text = _customGearController.text.trim();
                        if (text.isNotEmpty && !_includedGear.contains(text)) {
                          setState(() {
                            _includedGear.add(text);
                            _customGearController.clear();
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                      child: const Text('Add'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ==========================================
          // SECTION 4: GUIDE DETAILS & PRICING
          // ==========================================
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.amber.withOpacity(0.15), shape: BoxShape.circle),
                      child: const Icon(Icons.badge, size: 18, color: Colors.amber),
                    ),
                    const SizedBox(width: 10),
                    const Text('Guide Host & Pricing Tiers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _guideNameController,
                  decoration: const InputDecoration(
                    labelText: 'Lead Guide / Host Name',
                    hintText: 'e.g. Rahul Sharma (Certified Moto Lead)',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  onChanged: (val) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Set Price Per Rider (₹ INR)',
                    hintText: 'e.g. 1999',
                    prefixIcon: Icon(Icons.currency_rupee, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 12),

                const Text('Quick Select Price Tiers:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: ['999', '1999', '3499', '4999', '7999'].map((p) {
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

          const SizedBox(height: 28),

          // ==========================================
          // ACTION: SUBMIT / UPDATE TOUR BUTTON
          // ==========================================
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () async {
                final title = _titleController.text.trim();
                final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
                final location = _locationController.text.trim();
                final description = _descriptionController.text.trim();
                final duration = _durationController.text.trim();
                final guideName = _guideNameController.text.trim();

                if (title.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a tour experience title.'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }

                if (location.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter the starting location / region.'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }

                if (price <= 0.0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid price per rider.'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }

                final tourId = isEditing ? _currentEditingTour!.id : 't_${DateTime.now().millisecondsSinceEpoch}';

                final tourData = Tour(
                  id: tourId,
                  title: title,
                  location: location,
                  price: price,
                  duration: duration.isNotEmpty ? duration : 'Full Day (6-8 hrs)',
                  rating: isEditing ? _currentEditingTour!.rating : 5.0,
                  reviewCount: isEditing ? _currentEditingTour!.reviewCount : 1,
                  imageUrl: currentCoverUrl,
                  images: _tourPhotos.isNotEmpty ? _tourPhotos : [currentCoverUrl],
                  guideName: guideName.isNotEmpty ? guideName : appState.activeUserDisplayName,
                  guideAvatar: appState.activeUserPhotoUrl,
                  hostId: appState.userProfile?.uid ?? appState.supabaseUser?.id ?? '',
                  waypoints: _waypoints,
                  includedGear: _includedGear,
                  description: description.isNotEmpty
                      ? description
                      : 'Experience guided scenic routes with an experienced local host.',
                  expiryDate: _selectedExpiryDate,
                );

                if (isEditing) {
                  await appState.updateTour(tourData);
                } else {
                  await appState.addTour(tourData);
                }

                appState.clearDraftTourFromAi();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEditing
                          ? '✅ Tour "$title" details updated successfully!'
                          : '🚀 Guided Tour "$title" published live!'),
                      backgroundColor: Colors.green.shade700,
                    ),
                  );
                  appState.setNavIndex(8); // Navigate back to Dashboard
                }
              },
              icon: Icon(isEditing ? Icons.save : Icons.check_circle_outline),
              label: Text(
                isEditing ? 'Save & Update Tour Details' : 'Publish Guided Tour',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
