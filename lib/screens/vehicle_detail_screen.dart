import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';

class VehicleDetailScreen extends StatefulWidget {
  const VehicleDetailScreen({super.key});

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

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

    final iotData = vehicle.iotData;
    final bool isLocked = iotData['locked'] ?? true;
    final int batteryLevel = iotData['batteryLevel'] ?? 90;
    final int odometer = iotData['odometer'] ?? 12000;

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

              // Top Right Actions (Delete & Favorite)
              Positioned(
                top: 16,
                right: 16,
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                        tooltip: 'Delete Vehicle Listing',
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              title: const Text('Delete Vehicle Listing?'),
                              content: Text('Are you sure you want to delete "${vehicle.title}"?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
                                  onPressed: () async {
                                    Navigator.pop(ctx);
                                    await appState.deleteVehicle(vehicle.id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Vehicle "${vehicle.title}" deleted.'),
                                          backgroundColor: Colors.red.shade800,
                                        ),
                                      );
                                      appState.setNavIndex(1); // Back to Discovery
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
                          Text(
                            vehicle.title,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 14, color: Colors.grey),
                              Expanded(
                                child: Text(
                                  '${vehicle.location} (${vehicle.latitude.toStringAsFixed(3)}, ${vehicle.longitude.toStringAsFixed(3)})',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.star, size: 14, color: Colors.amber),
                              Text('${vehicle.rating} (${vehicle.reviewCount})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${vehicle.pricePerDay.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.secondaryFixedDim : AppColors.primary,
                          ),
                        ),
                        const Text('/day', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // IoT Telematics Status Card
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
                          const Row(
                            children: [
                              Icon(Icons.sensors, color: AppColors.secondary, size: 20),
                              SizedBox(width: 8),
                              Text('IoT Telematics Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'CONNECTED',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.onSecondaryContainer),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildIoTMetric(Icons.lock, isLocked ? 'Locked' : 'Unlocked', 'Smart Access'),
                          _buildIoTMetric(Icons.battery_charging_full, '$batteryLevel%', 'Fuel/Battery'),
                          _buildIoTMetric(Icons.speed, '$odometer mi', 'Odometer'),
                        ],
                      ),
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

                // Host Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: NetworkImage(vehicle.hostAvatar),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(vehicle.hostName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 2),
                            const Text('Superhost • 98.5% Response Rate', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => appState.setNavIndex(5), // Go to Chat
                        icon: const Icon(Icons.chat_bubble_outline, size: 16),
                        label: const Text('Chat'),
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
                                '${appState.rentalStartDate.day}/${appState.rentalStartDate.month} ➔ ${appState.rentalEndDate.day}/${appState.rentalEndDate.month} (${appState.rentalDaysCount} Days)',
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
                                appState.setRentalDates(range.start, range.end);
                              }
                            },
                            icon: const Icon(Icons.date_range, size: 16),
                            label: const Text('Change Dates'),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${appState.rentalDaysCount} Days x ₹${vehicle.pricePerDay.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13)),
                          Text(
                            '₹${(appState.rentalDaysCount * vehicle.pricePerDay).toStringAsFixed(2)}',
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

                // Rider Feedback & Reviews Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Rider Reviews & Feedback', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              '${vehicle.rating.toStringAsFixed(1)} (${vehicle.reviewCount} reviews)',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showAddReviewDialog(context, appState, vehicle.id),
                      icon: const Icon(Icons.rate_review_outlined, size: 16),
                      label: const Text('Write Review'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryContainer,
                        foregroundColor: AppColors.onPrimaryContainer,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Reviews List
                Builder(
                  builder: (context) {
                    final reviews = appState.getVehicleReviews(vehicle.id);
                    if (reviews.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: Text('No reviews yet. Be the first to share your feedback!', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        ),
                      );
                    }
                    return Column(
                      children: reviews.map((rev) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
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
                                  radius: 18,
                                  backgroundImage: NetworkImage(rev.userAvatar),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(rev.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      Text(
                                        '${rev.createdAt.day}/${rev.createdAt.month}/${rev.createdAt.year}',
                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.star, color: Colors.amber, size: 14),
                                      const SizedBox(width: 3),
                                      Text(
                                        rev.rating.toStringAsFixed(1),
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (rev.comment.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(rev.comment, style: const TextStyle(fontSize: 13, height: 1.3)),
                            ],
                          ],
                        ),
                      )).toList(),
                    );
                  },
                ),

                const SizedBox(height: 28),

                // Action Buttons
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => appState.setNavIndex(3), // Proceed to Booking Verification
                    child: Text(
                      'Proceed (₹${(appState.rentalDaysCount * vehicle.pricePerDay).toStringAsFixed(0)})',
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

  Widget _buildIoTMetric(IconData icon, String val, String label) {
    return Column(
      children: [
        Icon(icon, size: 22, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

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

  void _showAddReviewDialog(BuildContext context, AppState appState, String vehicleId) {
    if (!appState.isSignedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to write a review.')),
      );
      return;
    }

    double selectedRating = 5.0;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.rate_review, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Rate & Review Vehicle'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('How was your rental experience?', style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starVal = index + 1.0;
                  return IconButton(
                    icon: Icon(
                      starVal <= selectedRating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () {
                      setDialogState(() => selectedRating = starVal);
                    },
                  );
                }),
              ),
              Center(
                child: Text(
                  '${selectedRating.toStringAsFixed(1)} Stars',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Share feedback about vehicle performance, cleanliness, or host service...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
              onPressed: () async {
                final comment = commentController.text.trim();
                Navigator.pop(ctx);
                await appState.submitVehicleReview(
                  vehicleId: vehicleId,
                  rating: selectedRating,
                  comment: comment,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Thank you! Your feedback has been published.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Submit Review'),
            ),
          ],
        ),
      ),
    );
  }
}
