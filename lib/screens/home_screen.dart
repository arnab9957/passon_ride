import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';
import '../widgets/tour_details_modal.dart';
import 'location_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Welcome & Search Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [AppColors.surfaceContainerHighDark, AppColors.surfaceContainerDark]
                    : [AppColors.primary, AppColors.primaryContainer],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt, size: 14, color: AppColors.onSecondaryContainer),
                          const SizedBox(width: 4),
                          Text(
                            'P2P KINETIC MARKETPLACE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSecondaryContainer,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => showLocationPickerModal(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              appState.isLiveLocationActive ? Icons.my_location : Icons.location_on,
                              size: 13,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              appState.selectedLocation.split(',').first,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_drop_down, size: 14, color: Colors.white70),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Rent Premium Bikes, Cars\n& Guided Local Tours',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Keyless IoT access • Fully insured • Direct from local owners',
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => appState.setNavIndex(1), // Go to Discovery
                  icon: const Icon(Icons.explore, size: 18),
                  label: const Text('Explore Vehicles & Tours'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondaryContainer,
                    foregroundColor: AppColors.onSecondaryContainer,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Quick Category Pills
          const Text(
            'Explore Categories',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryChip(context, appState, 'All', Icons.apps),
                _buildCategoryChip(context, appState, 'Motorcycles', Icons.two_wheeler),
                _buildCategoryChip(context, appState, 'Cars', Icons.directions_car),
                _buildCategoryChip(context, appState, 'Scooters', Icons.electric_scooter),
                _buildCategoryChip(context, appState, 'Guided Tours', Icons.tour),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Quick Access Banner for Driving License & Government ID Upload
          InkWell(
            onTap: () => appState.setNavIndex(14),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceContainerDark : AppColors.secondaryContainer.withOpacity(0.35),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.secondary.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.badge, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('🪪 Documents & Licenses Verification', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('Submit Driving License, Expiry Date & PDF/JPG scan (150KB - 500KB)', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.secondary),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Nearest Proximity Algorithm Indicator Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [AppColors.secondary.withOpacity(0.2), AppColors.surfaceContainerHighDark]
                    : [AppColors.secondaryContainer.withOpacity(0.45), AppColors.surfaceContainerLowest],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.secondary.withOpacity(0.35)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.explore, size: 16, color: AppColors.secondary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('NEAREST PROXIMITY ALGORITHM ACTIVE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5, color: AppColors.secondary)),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('ALL FLEET LISTED', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.green)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Origin: ${appState.selectedLocation.split(',').first} (${appState.isLiveLocationActive ? "Live GPS 📍" : "Default / Custom 🏙️"}) • Ranked by Haversine Distance',
                        style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Featured Rides / Guided Tours Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Builder(
                      builder: (context) {
                        final isTours = appState.selectedCategory == 'Guided Tours';
                        final count = isTours
                            ? appState.filteredTours.length
                            : appState.getAvailableVehiclesNearCustomer(radiusKm: 999999.0).length;
                        final catLabel = appState.selectedCategory == 'All' ? 'All Vehicles' : appState.selectedCategory;
                        return Text(
                          isTours ? 'Guided Tours ($count)' : '$catLabel by Proximity ($count)',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                    Text(
                      appState.selectedCategory == 'Guided Tours'
                          ? 'Verified local hosts & guided expeditions'
                          : 'Sorted strictly from closest to farthest host',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.secondaryFixedDim : AppColors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => appState.setNavIndex(1),
                icon: const Icon(Icons.tune, size: 14),
                label: const Text('Filters & Search'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Featured Horizontal Carousel List (Shows vehicles or direct guided tours based on category)
          SizedBox(
            height: 310,
            child: Builder(
              builder: (ctx) {
                if (appState.selectedCategory == 'Guided Tours') {
                  final tours = appState.filteredTours;
                  if (tours.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.tour, size: 36, color: Colors.grey),
                          const SizedBox(height: 8),
                          const Text('No guided tours currently listed.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () => appState.setCategory('All'),
                            icon: const Icon(Icons.refresh, size: 14),
                            label: const Text('View All Categories'),
                          ),
                        ],
                      ),
                    );
                  }
                  return AutoScrollingCarousel(
                    itemCount: tours.length,
                    itemExtent: 256.0,
                    itemBuilder: (context, index) {
                      final tour = tours[index];
                      return _buildHorizontalTourCard(context, appState, tour);
                    },
                  );
                }

                final allVehiclesSorted = appState.getAvailableVehiclesNearCustomer(radiusKm: 999999.0);
                if (allVehiclesSorted.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 36, color: Colors.grey),
                        const SizedBox(height: 8),
                        Text(
                          'No ${appState.selectedCategory} currently listed nearby.',
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => appState.setCategory('All'),
                          icon: const Icon(Icons.refresh, size: 14),
                          label: const Text('Clear Filter & View All'),
                        ),
                      ],
                    ),
                  );
                }
                return AutoScrollingCarousel(
                  itemCount: allVehiclesSorted.length,
                  itemExtent: 256.0,
                  itemBuilder: (context, index) {
                    final vehicle = allVehiclesSorted[index];
                    return _buildVehicleCard(context, appState, vehicle, distanceRank: index + 1);
                  },
                );
              },
            ),
          ),

          if (appState.selectedCategory != 'Guided Tours') ...[
            const SizedBox(height: 24),

            // Popular Guided Tours Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Popular Guided Tours',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => appState.setNavIndex(1),
                  child: const Text('All Tours'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Tours List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: appState.tours.length,
              itemBuilder: (context, index) {
                final tour = appState.tours[index];
                return _buildTourCard(context, appState, tour);
              },
            ),
          ],

          const SizedBox(height: 28),

          // About PassionRide Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.shield_outlined, color: AppColors.primary, size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      'Why PassionRide?',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildAboutFeature(
                  Icons.key,
                  'IoT Keyless Access',
                  'Unlock rides directly from your smartphone using encrypted hardware telematics.',
                ),
                const SizedBox(height: 12),
                _buildAboutFeature(
                  Icons.verified_user,
                  'Kinetic Trust Scoring',
                  'AI-driven safety verification and transparent peer ratings protect both riders and owners.',
                ),
                const SizedBox(height: 12),
                _buildAboutFeature(
                  Icons.eco,
                  'Eco-Conscious Fleet',
                  'Over 45% of our community vehicles are 100% zero-emission electric bikes and cars.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(BuildContext context, AppState appState, String label, IconData icon) {
    final isSelected = appState.selectedCategory == label;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        avatar: Icon(
          icon,
          size: 18,
          color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppColors.primary),
        ),
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) appState.setCategory(label);
        },
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : (isDark ? Colors.white : AppColors.onSurfaceLight),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        backgroundColor: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLow,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildVehicleCard(BuildContext context, AppState appState, Vehicle vehicle, {int distanceRank = 1}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 240,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: distanceRank == 1
              ? AppColors.secondary
              : (isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight),
          width: distanceRank == 1 ? 2.0 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            appState.selectVehicle(vehicle);
            appState.setNavIndex(2); // Detail screen
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    child: Image.network(
                      vehicle.imageUrl,
                      height: 130,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Container(
                        height: 130,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.directions_car, size: 40, color: Colors.grey),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: distanceRank == 1
                            ? Colors.green.shade700
                            : (distanceRank <= 3 ? Colors.blue.shade800 : Colors.black.withOpacity(0.75)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            distanceRank == 1
                                ? Icons.emoji_events
                                : (distanceRank <= 3 ? Icons.near_me : Icons.navigation),
                            size: 11,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            distanceRank == 1
                                ? '🥇 #1 NEAREST'
                                : (distanceRank == 2
                                    ? '🥈 #2 NEAREST'
                                    : (distanceRank == 3 ? '🥉 #3 NEAREST' : '#$distanceRank NEAREST')),
                            style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.black45,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          vehicle.isFavorite ? Icons.favorite : Icons.favorite_border,
                          size: 18,
                          color: vehicle.isFavorite ? Colors.redAccent : Colors.white,
                        ),
                        onPressed: () => appState.toggleFavoriteVehicle(vehicle.id),
                      ),
                    ),
                  ),
                  if (vehicle.isInstantBookable)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.flash_on, size: 12, color: Colors.white),
                            SizedBox(width: 2),
                            Text('Instant Book', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(
                          '${vehicle.rating}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        Text(
                          ' (${vehicle.reviewCount})',
                          style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryContainer.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '📍 ${appState.getFormattedDistanceToVehicle(vehicle)}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '₹${vehicle.pricePerDay.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : AppColors.primary,
                                ),
                              ),
                              TextSpan(
                                text: '/day',
                                style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            appState.selectVehicle(vehicle);
                            appState.setNavIndex(2); // Detail screen
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('View', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalTourCard(BuildContext context, AppState appState, Tour tour) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
        ),
      ),
      child: InkWell(
        onTap: () {
          appState.selectTour(tour);
          showTourDetailsModal(context, appState, tour);
        },
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Image.network(
                    tour.imageUrl,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => Container(
                      height: 140,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.tour, size: 40, color: Colors.grey),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 13),
                        const SizedBox(width: 3),
                        Text(
                          tour.rating.toStringAsFixed(1),
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                if (tour.isExpired)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade800,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('EXPIRED', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tour.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${tour.location} • ${tour.duration}',
                    style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        tour.isExpired ? Icons.event_busy : Icons.event_available,
                        size: 11,
                        color: tour.isExpired ? Colors.red : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        tour.isExpired ? 'Expired: ${tour.formattedExpiryDate}' : 'Expires: ${tour.formattedExpiryDate}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: tour.isExpired ? FontWeight.bold : FontWeight.w500,
                          color: tour.isExpired ? Colors.red : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${tour.price.toStringAsFixed(0)} / person',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.secondaryFixedDim : AppColors.secondary,
                          fontSize: 13,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          appState.selectTour(tour);
                          showTourDetailsModal(context, appState, tour);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: tour.isExpired ? Colors.grey : AppColors.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          tour.isExpired ? 'Expired' : 'Book Tour',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTourCard(BuildContext context, AppState appState, Tour tour) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        appState.selectTour(tour);
        showTourDetailsModal(context, appState, tour);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              child: Image.network(
                tour.imageUrl,
                height: 100,
                width: 110,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => Container(
                  height: 100,
                  width: 110,
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.tour, size: 30, color: Colors.grey),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tour.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${tour.location} • ${tour.duration}',
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          tour.isExpired ? Icons.event_busy : Icons.event_available,
                          size: 12,
                          color: tour.isExpired ? Colors.red : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          tour.isExpired ? 'Expired: ${tour.formattedExpiryDate}' : 'Expires: ${tour.formattedExpiryDate}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: tour.isExpired ? FontWeight.bold : FontWeight.w500,
                            color: tour.isExpired ? Colors.red : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹${tour.price.toStringAsFixed(0)} / person',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.secondaryFixedDim : AppColors.secondary,
                            fontSize: 13,
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () {
                            appState.selectTour(tour);
                            showTourDetailsModal(context, appState, tour);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            side: tour.isExpired ? const BorderSide(color: Colors.grey) : null,
                          ),
                          child: Text(
                            tour.isExpired ? 'Expired' : 'Book Tour',
                            style: TextStyle(
                              fontSize: 11,
                              color: tour.isExpired ? Colors.grey : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutFeature(IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 2),
              Text(desc, style: const TextStyle(fontSize: 12, height: 1.3)),
            ],
          ),
        ),
      ],
    );
  }
}

class AutoScrollingCarousel extends StatefulWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double itemExtent;

  const AutoScrollingCarousel({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.itemExtent = 256.0,
  });

  @override
  State<AutoScrollingCarousel> createState() => _AutoScrollingCarouselState();
}

class _AutoScrollingCarouselState extends State<AutoScrollingCarousel> {
  late ScrollController _scrollController;
  Timer? _timer;
  bool _userInteracting = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_userInteracting || !_scrollController.hasClients || widget.itemCount <= 1) {
        return;
      }
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;
      double targetScroll = currentScroll + widget.itemExtent;

      if (targetScroll >= maxScroll + 10) {
        targetScroll = 0.0;
      }

      _scrollController.animateTo(
        targetScroll,
        duration: const Duration(milliseconds: 850),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _onUserPointerDown() {
    _userInteracting = true;
  }

  void _onUserPointerUp() {
    _userInteracting = false;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _onUserPointerDown(),
      onPointerUp: (_) => _onUserPointerUp(),
      onPointerCancel: (_) => _onUserPointerUp(),
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: widget.itemCount,
        itemBuilder: widget.itemBuilder,
      ),
    );
  }
}
