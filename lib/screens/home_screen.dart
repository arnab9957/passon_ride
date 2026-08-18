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

          const SizedBox(height: 24),

          // Featured Rides Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nearest Available Rides (${appState.getAvailableVehiclesNearCustomer().length})',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Connected to ${appState.selectedLocation.split(',').first}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.secondaryFixedDim : AppColors.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => appState.setNavIndex(1),
                child: const Text('See All'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Featured Rides Horizontal List (Sorted by proximity to customer address)
          SizedBox(
            height: 310,
            child: Builder(
              builder: (ctx) {
                final nearbyVehicles = appState.getAvailableVehiclesNearCustomer();
                if (nearbyVehicles.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.near_me_disabled, size: 36, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('No available vehicles near your location.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: nearbyVehicles.length,
                  itemBuilder: (context, index) {
                    final vehicle = nearbyVehicles[index];
                    return _buildVehicleCard(context, appState, vehicle, distanceRank: index + 1);
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // Popular Guided Tours
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

          const SizedBox(height: 28),

          // About PassonRide Section
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
                      'Why PassonRide?',
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
                    color: distanceRank == 1 ? AppColors.secondary : Colors.black.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        distanceRank == 1 ? Icons.emoji_events : Icons.navigation,
                        size: 11,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        distanceRank == 1 ? '🏆 #1 TOP NEAREST' : '#$distanceRank',
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
                    const SizedBox(height: 8),
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
                          ),
                          child: const Text('Book Tour', style: TextStyle(fontSize: 11)),
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
