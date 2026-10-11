import 'dart:convert';
// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/side_by_side_reviews_widget.dart';
import '../widgets/edit_vehicle_dialog.dart';
import '../widgets/tr_text.dart';
import '../i18n/strings.g.dart';

class VehicleDetailScreen extends StatefulWidget {
  const VehicleDetailScreen({super.key});

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();
  bool _showVehicleMap = true;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildSingleImage(String url) {
    if (url.startsWith('data:image/')) {
      try {
        final base64Bytes = base64Decode(url.split(',').last);
        return Image.memory(base64Bytes, fit: BoxFit.cover);
      } catch (_) {}
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (ctx, err, stack) => Container(
        color: Colors.grey.shade300,
        child: const Icon(Icons.directions_car, size: 60, color: Colors.grey),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: _buildSingleImage(url),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(ctx),
              ),
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
    final vehicle = appState.selectedVehicle ?? (appState.vehicles.isNotEmpty ? appState.vehicles.first : null);

    if (vehicle == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.directions_car_outlined,
                size: 64,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              const SizedBox(height: 16),
              const Text(
                'No Vehicle Selected',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select a vehicle from the discovery list or home page to view full details.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => appState.setNavIndex(1),
                icon: const Icon(Icons.search),
                label: const Text('Browse Vehicles'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final List<String> allPhotos = vehicle.images.isNotEmpty
        ? vehicle.images
        : (vehicle.imageUrl.isNotEmpty ? [vehicle.imageUrl] : []);

    final activeUserPhoto = appState.activeUserPhotoUrl;
    final currentUid = appState.userProfile?.uid ?? appState.supabaseUser?.id ?? '';
    final currentDisplayName = appState.activeUserDisplayName;
    final isMyVehicle = (currentUid.isNotEmpty && vehicle.hostId == currentUid) ||
        (vehicle.hostName.isNotEmpty && currentDisplayName != 'Guest User' && vehicle.hostName == currentDisplayName) ||
        vehicle.hostId.isEmpty;
    String effectiveHostAvatar = vehicle.hostAvatar;
    if (activeUserPhoto.isNotEmpty && (isMyVehicle || effectiveHostAvatar.isEmpty || effectiveHostAvatar.contains('unsplash.com'))) {
      effectiveHostAvatar = activeUserPhoto;
    }
    if (effectiveHostAvatar.isEmpty) {
      effectiveHostAvatar = 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&q=80';
    }

    // final iotData = vehicle.iotData;
    // final bool isLocked = iotData['locked'] ?? true;
    // final int batteryLevel = iotData['batteryLevel'] ?? 90;
    // final int odometer = iotData['odometer'] ?? 12000;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Swipeable Multi-Photo Carousel & Top Controls
          Stack(
            children: [
              SizedBox(
                height: 280,
                width: double.infinity,
                child: allPhotos.isEmpty
                    ? Container(
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.directions_car, size: 60, color: Colors.grey),
                      )
                    : PageView.builder(
                        controller: _pageController,
                        itemCount: allPhotos.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentImageIndex = index;
                          });
                        },
                        itemBuilder: (context, idx) {
                          final photoUrl = allPhotos[idx];
                          return GestureDetector(
                            onTap: () => _showFullScreenImage(context, photoUrl),
                            child: _buildSingleImage(photoUrl),
                          );
                        },
                      ),
              ),

              // Image Counter & Tap Indicator Badge
              if (allPhotos.isNotEmpty)
                Positioned(
                  bottom: 12,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.photo_library, size: 14, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          '${_currentImageIndex + 1} / ${allPhotos.length} Photos',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),

              // Back Button
              Positioned(
                top: 16,
                left: 16,
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => appState.setNavIndex(1), // Back to discovery
                  ),
                ),
              ),

              // Top Right Actions (Host Delete & Favorite)
              Positioned(
                top: 16,
                right: 16,
                child: Row(
                  children: [
                    // Only the authorized host profile of this vehicle can edit & delete
                    if (appState.isHostOfVehicle(vehicle)) ...[
                      CircleAvatar(
                        backgroundColor: Colors.black54,
                        child: IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white),
                          tooltip: 'Edit Vehicle Details (Host Only)',
                          onPressed: () => showEditVehicleDialog(context, appState, vehicle),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: Colors.black54,
                        child: IconButton(
                          icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                          tooltip: 'Delete Vehicle Listing (Host Only)',
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                title: const Text('Delete Vehicle Listing?'),
                                content: Text('Are you sure you want to permanently delete "${vehicle.title}" as its host? This action cannot be undone.'),
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
                                              content: Text('Vehicle "${vehicle.title}" deleted.'),
                                              backgroundColor: Colors.red.shade800,
                                            ),
                                          );
                                          appState.setNavIndex(1); // Back to Discovery
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
                                    child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: Icon(
                          vehicle.isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: vehicle.isFavorite ? Colors.redAccent : Colors.white,
                        ),
                        onPressed: () => appState.toggleFavoriteVehicle(vehicle.id),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Multi-Photo Thumbnail Selector Strip
          if (allPhotos.length > 1) ...[
            Container(
              height: 70,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLow,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: allPhotos.length,
                itemBuilder: (context, idx) {
                  final isSelected = idx == _currentImageIndex;
                  return GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
                        idx,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      width: 75,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : Colors.transparent,
                          width: isSelected ? 2.5 : 1,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _buildSingleImage(allPhotos[idx]),
                    ),
                  );
                },
              ),
            ),
          ],

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title & Price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryContainer.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  vehicle.category.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? AppColors.onPrimaryContainer : AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: vehicle.status == 'Available'
                                      ? Colors.green.shade100
                                      : (vehicle.status == 'Maintenance' ? Colors.orange.shade100 : Colors.blue.shade100),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  vehicle.status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: vehicle.status == 'Available'
                                        ? Colors.green.shade800
                                        : (vehicle.status == 'Maintenance' ? Colors.orange.shade900 : Colors.blue.shade900),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          TrText(
                            vehicle.title,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 14, color: Colors.grey),
                              Expanded(
                                child: TrText(
                                  '${vehicle.location} (${vehicle.latitude.toStringAsFixed(3)}, ${vehicle.longitude.toStringAsFixed(3)})',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.star, size: 14, color: Colors.amber),
                              Builder(
                                builder: (context) {
                                  final reviews = appState.getVehicleReviews(vehicle.id);
                                  if (reviews.isEmpty) {
                                    return const TrText(
                                      'No reviews yet',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
                                    );
                                  }
                                  return Text(
                                    '${vehicle.rating.toStringAsFixed(1)} (${reviews.length})',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (vehicle.pricePerDay > 0) ...[
                          Text(
                            '₹${vehicle.pricePerDay.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.secondaryFixedDim : AppColors.primary,
                            ),
                          ),
                          Text(t.home.perDay, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                        if (vehicle.pricePerHour > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            '₹${vehicle.pricePerHour.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.secondaryFixedDim : AppColors.primary,
                            ),
                          ),
                          const Text('per hour', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                        if (vehicle.customTimeRangePrice > 0 && vehicle.customTimeRangeStart.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            '₹${vehicle.customTimeRangePrice.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.secondaryFixedDim : AppColors.primary,
                            ),
                          ),
                          Text('${vehicle.customTimeRangeStart}-${vehicle.customTimeRangeEnd}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),



                // Exact Pickup Location & Interactive Map Hub Card (after IoT Telematics)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with location icon and distance badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.location_on, color: Colors.redAccent, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'EXACT PICKUP LOCATION',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${appState.getFormattedDistanceToVehicle(vehicle)} (${appState.getEstimatedTravelTimeToVehicle(vehicle)})',
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  vehicle.location.isNotEmpty ? vehicle.location : 'Pickup Hub, City Center',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'GPS: ${vehicle.latitude != 0.0 ? vehicle.latitude.toStringAsFixed(4) : "22.5726"}° N, ${vehicle.longitude != 0.0 ? vehicle.longitude.toStringAsFixed(4) : "88.3639"}° E',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Map Control Actions
                      Row(
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() {
                                _showVehicleMap = !_showVehicleMap;
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.surfaceContainerHighDark : AppColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _showVehicleMap ? Icons.map : Icons.map_outlined,
                                    size: 14,
                                    color: AppColors.secondary,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    _showVehicleMap ? 'Hide Map' : 'Show Map Pin',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondary),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => _showFullLocationMapModal(context, appState, vehicle),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.surfaceContainerHighDark : AppColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.fullscreen, size: 15, color: Colors.deepPurple),
                                  SizedBox(width: 5),
                                  Text(
                                    'Full Hub View',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final lat = vehicle.latitude != 0.0 ? vehicle.latitude : 22.5726;
                              final lng = vehicle.longitude != 0.0 ? vehicle.longitude : 88.3639;
                              final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Unable to launch external map navigation.')),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.directions, size: 14),
                            label: const Text('Directions', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),

                      // Embedded Live OpenStreetMap Preview
                      if (_showVehicleMap) ...[
                        const SizedBox(height: 12),
                        Container(
                          height: 175,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            children: [
                              FlutterMap(
                                options: MapOptions(
                                  initialCenter: LatLng(
                                    vehicle.latitude != 0.0 ? vehicle.latitude : 22.5726,
                                    vehicle.longitude != 0.0 ? vehicle.longitude : 88.3639,
                                  ),
                                  initialZoom: 15.5,
                                  interactionOptions: const InteractionOptions(
                                    flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                                  ),
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName: 'com.passon.ride',
                                  ),
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: LatLng(
                                          vehicle.latitude != 0.0 ? vehicle.latitude : 22.5726,
                                          vehicle.longitude != 0.0 ? vehicle.longitude : 88.3639,
                                        ),
                                        width: 52,
                                        height: 52,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Container(
                                              width: 48,
                                              height: 48,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.red.withOpacity(0.25),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.red.shade700,
                                                border: Border.all(color: Colors.white, width: 2),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.25),
                                                    blurRadius: 6,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(
                                                Icons.directions_car,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.75),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Colors.greenAccent,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Text(
                                        'LIVE GPS PIN',
                                        style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Vehicle Specs Grid
                const Text('Vehicle Specifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildSpecChip(Icons.local_gas_station, 'Fuel', vehicle.fuelType, context)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildSpecChip(Icons.settings, 'Transmission', vehicle.transmission, context)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildSpecChip(Icons.airline_seat_recline_normal, 'Seating', '${vehicle.seats} Capacity', context)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildSpecChip(Icons.verified_user, 'Trust Score', '${vehicle.hostTrustScore}%', context)),
                  ],
                ),

                const SizedBox(height: 20),

                // Vehicle Owner & Host Details Section
                Row(
                  children: [
                    const Icon(Icons.person_pin, size: 20, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Text(
                      'Vehicle Owner & Host Details',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, size: 12, color: Colors.green),
                          SizedBox(width: 4),
                          Text(
                            'Verified Owner',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
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
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundImage: NetworkImage(effectiveHostAvatar),
                            onBackgroundImageError: (e, s) {},
                            child: effectiveHostAvatar.isEmpty ? const Icon(Icons.person, size: 28) : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        vehicle.hostName.isNotEmpty ? vehicle.hostName : 'Verified Host',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(Icons.verified, size: 16, color: Colors.blue.shade600),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '📍 Hub: ${vehicle.location}',
                                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Superhost • 98.5% Response Rate (< 15 mins)',
                                  style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      // Owner Attributes Grid
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.shield_outlined, size: 16, color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Trust Score', style: TextStyle(fontSize: 9, color: Colors.grey)),
                                        Text(
                                          '${vehicle.hostTrustScore.toStringAsFixed(0)}% Verified',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.two_wheeler, size: 16, color: Colors.purple),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Active Fleet', style: TextStyle(fontSize: 9, color: Colors.grey)),
                                        Builder(
                                          builder: (context) {
                                            final count = appState.vehicles.where((v) =>
                                              (v.hostId.isNotEmpty && v.hostId == vehicle.hostId) ||
                                              (v.hostName.isNotEmpty && v.hostName.toLowerCase() == vehicle.hostName.toLowerCase())
                                            ).length;
                                            return Text(
                                              '$count Vehicle${count > 1 ? 's' : ''}',
                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Phone number and Contact Info fetched from Supabase Profiles
                      FutureBuilder<dynamic>(
                        future: () async {
                          try {
                            final cleanId = vehicle.hostId.replaceAll('mth_', '').replaceAll('chd_', '');
                            if (cleanId.isEmpty) return null;
                            final res = await appState.supabaseService.client
                                ?.from('profiles')
                                .select('phone_number, full_name, email')
                                .eq('id', cleanId)
                                .maybeSingle();
                            return res;
                          } catch (_) {
                            return null;
                          }
                        }(),
                        builder: (context, snapshot) {
                          final data = snapshot.data as Map<String, dynamic>?;
                          final phone = data?['phone_number']?.toString() ?? '';
                          final email = data?['email']?.toString() ?? '';

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.phone_outlined, size: 15, color: Colors.teal),
                                        const SizedBox(width: 8),
                                        const Text('Phone: ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                        Text(
                                          phone.isNotEmpty ? phone : 'Verified with Host Support',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                    if (email.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.email_outlined, size: 15, color: Colors.teal),
                                          const SizedBox(width: 8),
                                          const Text('Email: ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                          Expanded(
                                            child: Text(
                                              email,
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Chat & Call Action Buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => appState.openChatWithHost(
                                        hostName: vehicle.hostName.isNotEmpty ? vehicle.hostName : 'Vehicle Host',
                                        hostAvatar: effectiveHostAvatar,
                                        vehicleTitle: vehicle.title,
                                      ),
                                      icon: const Icon(Icons.chat_bubble_outline, size: 16),
                                      label: const Text('Chat with Owner'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        side: const BorderSide(color: AppColors.primary),
                                      ),
                                    ),
                                  ),
                                  if (phone.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Owner Phone: $phone'),
                                            duration: const Duration(seconds: 4),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.call, size: 16, color: Colors.teal),
                                      label: const Text('Call', style: TextStyle(color: Colors.teal)),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        side: const BorderSide(color: Colors.teal),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Rental Date Selector Card
                const Text('Select Rental Dates', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('PICKUP & DROPOFF', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(
                                '${appState.rentalStartDate.day}/${appState.rentalStartDate.month} ➔ ${appState.rentalEndDate.day}/${appState.rentalEndDate.month} (${appState.rentalDaysCount} ${appState.rentalDaysCount == 1 ? 'Day' : 'Days'})',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final range = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 90)),
                                initialDateRange: DateTimeRange(start: appState.rentalStartDate, end: appState.rentalEndDate),
                              );
                              if (range != null) {
                                if (!context.mounted) return;
                                final startTime = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay(hour: appState.rentalStartDate.hour, minute: appState.rentalStartDate.minute),
                                  helpText: 'Select Pickup Time',
                                );
                                if (startTime != null) {
                                  if (!context.mounted) return;
                                  final endTime = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay(hour: startTime.hour + 1, minute: startTime.minute),
                                    helpText: 'Select Dropoff Time',
                                  );
                                  if (endTime != null) {
                                    appState.setRentalDates(
                                      DateTime(range.start.year, range.start.month, range.start.day, startTime.hour, startTime.minute),
                                      DateTime(range.end.year, range.end.month, range.end.day, endTime.hour, endTime.minute),
                                    );
                                  }
                                }
                              }
                            },
                            icon: const Icon(Icons.access_time, size: 16),
                            label: const Text('Change Dates'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ChoiceChip(
                              label: const Text('1 Day (Default)', style: TextStyle(fontSize: 12)),
                              selected: appState.rentalDaysCount == 1,
                              onSelected: (selected) {
                                if (selected) {
                                  appState.setRentalDurationDays(1);
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('2 Days', style: TextStyle(fontSize: 12)),
                              selected: appState.rentalDaysCount == 2,
                              onSelected: (selected) {
                                if (selected) {
                                  appState.setRentalDurationDays(2);
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('3 Days', style: TextStyle(fontSize: 12)),
                              selected: appState.rentalDaysCount == 3,
                              onSelected: (selected) {
                                if (selected) {
                                  appState.setRentalDurationDays(3);
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('7 Days', style: TextStyle(fontSize: 12)),
                              selected: appState.rentalDaysCount == 7,
                              onSelected: (selected) {
                                if (selected) {
                                  appState.setRentalDurationDays(7);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Rental Charge', style: TextStyle(fontSize: 13)),
                          Text(
                            '₹${vehicle.calculateRentalPrice(appState.rentalStartDate, appState.rentalEndDate).toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.secondaryFixedDim : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Description
                const Text('Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  vehicle.description,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),



                const SizedBox(height: 24),

                // Rider Feedback & Reviews Section (Public Aspect Ratings + Side-by-Side App Reviews)
                SideBySideReviewsWidget(vehicleId: vehicle.id),

                const SizedBox(height: 28),

                // Action Buttons
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => appState.setNavIndex(3), // Proceed to Booking Verification
                    child: Text(
                      'Proceed (₹${vehicle.calculateRentalPrice(appState.rentalStartDate, appState.rentalEndDate).toStringAsFixed(0)})',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildIoTMetric(IconData icon, String val, String label) {
  //   return Column(
  //     children: [
  //       Icon(icon, size: 22, color: AppColors.primary),
  //       const SizedBox(height: 4),
  //       Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
  //       Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
  //     ],
  //   );
  // }

  Widget _buildSpecChip(IconData icon, String label, String val, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }



  void _showFullLocationMapModal(BuildContext context, AppState appState, Vehicle vehicle) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lat = vehicle.latitude != 0.0 ? vehicle.latitude : 22.5726;
    final lng = vehicle.longitude != 0.0 ? vehicle.longitude : 88.3639;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceContainerDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Modal Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
              ),
              // Header Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.location_on, color: Colors.redAccent, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Vehicle Pickup Hub & Location',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            vehicle.title,
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
              const Divider(height: 1),

              // Interactive Full OpenStreetMap
              Expanded(
                child: Stack(
                  children: [
                    FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(lat, lng),
                        initialZoom: 16.0,
                        minZoom: 4.0,
                        maxZoom: 19.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.passon.ride',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(lat, lng),
                              width: 60,
                              height: 60,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.red.withOpacity(0.25),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.red.shade700,
                                      border: Border.all(color: Colors.white, width: 2.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(Icons.directions_car, color: Colors.white, size: 20),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${appState.getFormattedDistanceToVehicle(vehicle)} • ${appState.getEstimatedTravelTimeToVehicle(vehicle)}',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Pickup Address Card & Actions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceContainerHighDark : Colors.grey.shade50,
                  border: Border(
                    top: BorderSide(
                      color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.primary,
                          backgroundImage: vehicle.hostAvatar.isNotEmpty
                              ? NetworkImage(appState.imageKitService.buildImageUrl(vehicle.hostAvatar))
                              : null,
                          child: vehicle.hostAvatar.isEmpty
                              ? Text(
                                  vehicle.hostName.isNotEmpty ? vehicle.hostName[0].toUpperCase() : 'H',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Host: ${vehicle.hostName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text(vehicle.location.isNotEmpty ? vehicle.location : 'Pickup Hub Location', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${vehicle.hostTrustScore.toStringAsFixed(0)}% Trust',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              appState.openChatWithHost(
                                hostName: vehicle.hostName,
                                hostAvatar: vehicle.hostAvatar,
                                vehicleTitle: vehicle.title,
                              );
                            },
                            icon: const Icon(Icons.chat_bubble_outline, size: 16),
                            label: const Text('Chat Host'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              }
                            },
                            icon: const Icon(Icons.navigation, size: 16),
                            label: const Text('Open in Google Maps', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
