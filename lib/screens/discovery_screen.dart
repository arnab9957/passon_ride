// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';
import '../widgets/auto_sliding_image_carousel.dart';
import '../widgets/tour_details_modal.dart';
import 'location_screen.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  String _searchQuery = '';
  String _selectedType = 'All';

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredVehicles = appState.vehicles.where((v) {
      // Hide maintenance or archived vehicles
      if (v.status == 'Maintenance' || v.status == 'Archived') return false;

      final matchesSearch = _searchQuery.isEmpty ||
          v.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          v.location.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          v.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          v.description.toLowerCase().contains(_searchQuery.toLowerCase());

      final isBooked = appState.isVehicleBookedDuring(v.id, appState.pickupDateTime, appState.dropoffDateTime);

      final activeCategory = _selectedType != 'All' ? _selectedType : appState.selectedCategory;

      bool matchesAvailability = true;
      if (activeCategory == '🟢 Available Now') {
        matchesAvailability = !isBooked && (v.status == 'Available' || v.status == 'Active' || v.status.isEmpty);
      } else if (activeCategory == '🔴 Currently Rented') {
        matchesAvailability = isBooked || v.status == 'Booked';
      } else if (activeCategory == 'Motorcycles') {
        matchesAvailability = v.type == VehicleType.bike ||
            v.category.toLowerCase().contains('bike') ||
            v.category.toLowerCase().contains('motorcycle');
      } else if (activeCategory == 'Cars') {
        matchesAvailability = v.type == VehicleType.car ||
            v.category.toLowerCase().contains('car');
      } else if (activeCategory == 'Scooters') {
        matchesAvailability = v.type == VehicleType.scooter ||
            v.category.toLowerCase().contains('scooter');
      } else if (activeCategory == 'Guided Tours') {
        matchesAvailability = false;
      }

      // Radius filter relative to client's selected location
      bool matchesRadius = true;
      if (appState.searchRadiusKm < 999.0) {
        final dist = appState.getDistanceToVehicle(v);
        matchesRadius = dist <= appState.searchRadiusKm;
      }

      return matchesSearch && matchesAvailability && matchesRadius;
    }).toList();

    // STRICT SORTING: Sort list strictly by client location distance ascending (nearest first) unless price/rating chosen
    if (appState.sortOption == 'price') {
      filteredVehicles.sort((a, b) => a.pricePerDay.compareTo(b.pricePerDay));
    } else if (appState.sortOption == 'rating') {
      filteredVehicles.sort((a, b) => b.rating.compareTo(a.rating));
    } else {
      filteredVehicles.sort((a, b) => appState.getDistanceToVehicle(a).compareTo(appState.getDistanceToVehicle(b)));
    }

    final filteredTours = appState.filteredTours;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DISCOVERY & TRACKING',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: isDark ? AppColors.secondaryFixedDim : AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Search & Availability Tracker',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.tune),
                onPressed: () => _showFilterBottomSheet(context),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // High-End Modern Search Input Bar
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceContainerDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black38 : AppColors.primary.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
              ),
            ),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search bikes, cars, scooters, or location...',
                hintStyle: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : Colors.grey.shade600),
                prefixIcon: const Icon(Icons.search, color: AppColors.secondary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Quick Filter Tag Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                {'label': '⚡ Near Me', 'query': ''},
                {'label': '🏍️ Superbikes', 'query': 'bike'},
                {'label': '🚗 Teslas & EVs', 'query': 'electric'},
                {'label': '🛵 E-Scooters', 'query': 'scooter'},
              ].map((tag) {
                final queryVal = tag['query']!;
                final isSelected = _searchQuery.toLowerCase() == queryVal.toLowerCase() && queryVal.isNotEmpty;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ActionChip(
                    label: Text(tag['label']!),
                    backgroundColor: isSelected
                        ? AppColors.secondary
                        : (isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLow),
                    labelStyle: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    onPressed: () {
                      setState(() {
                        _searchQuery = isSelected ? '' : queryVal;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 14),

          // Interactive Location, Pickup & Dropoff Date/Time Search Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [AppColors.surfaceContainerHighDark, AppColors.surfaceContainerDark]
                    : [Colors.white, AppColors.surfaceContainerLowest],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black45 : Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
              ),
            ),
            child: Column(
              children: [
                InkWell(
                  onTap: () => showLocationPickerModal(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: appState.isLiveLocationActive
                                ? AppColors.secondaryContainer
                                : AppColors.primaryContainer.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            appState.isLiveLocationActive ? Icons.my_location : Icons.location_on,
                            color: appState.isLiveLocationActive ? AppColors.onSecondaryContainer : AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 6,
                                runSpacing: 2,
                                children: [
                                  const Text(
                                    'ACTIVE CLIENT LOCATION',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: appState.isLiveLocationActive
                                          ? AppColors.secondaryContainer
                                          : AppColors.primaryContainer.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      appState.isLiveLocationActive ? '📡 Live GPS Locked' : '📍 Manual Address',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: appState.isLiveLocationActive
                                            ? AppColors.onSecondaryContainer
                                            : AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                appState.selectedLocation,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => showLocationPickerModal(context),
                          icon: const Icon(Icons.tune, size: 12),
                          label: const Text('Change', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: appState.isLiveLocationActive ? AppColors.secondary : AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.calendar_month, color: AppColors.secondary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PICKUP & DROPOFF SCHEDULE',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Pickup: ${_formatDateTime(appState.pickupDateTime)}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Dropoff: ${_formatDateTime(appState.dropoffDateTime)}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showPickupDropoffPicker(context, appState),
                      icon: const Icon(Icons.edit_calendar, size: 14),
                      label: const Text('Set Schedule', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Filter Chips (Vehicle Types & Availability)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', '🟢 Available Now', '🔴 Currently Rented', 'Motorcycles', 'Cars', 'Scooters', '🏍️ Guided Tours'].map((type) {
                final isSelected = _selectedType == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(type),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedType = type);
                    },
                    selectedColor: type.contains('🏍️')
                        ? AppColors.secondary
                        : (type.contains('🟢')
                            ? Colors.green.shade700
                            : (type.contains('🔴') ? Colors.red.shade700 : AppColors.primary)),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : (isDark ? Colors.white : AppColors.onSurfaceLight),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 12),

          // Proximity Radius Selector Chips (Customer Location to Host Vehicles)
          Row(
            children: [
              const Icon(Icons.radar, size: 16, color: AppColors.secondary),
              const SizedBox(width: 6),
              Text(
                'Host Search Radius:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.secondaryFixedDim : AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                {'label': '📍 5 km', 'value': 5.0},
                {'label': '15 km', 'value': 15.0},
                {'label': '30 km', 'value': 30.0},
                {'label': '50 km', 'value': 50.0},
                {'label': '100 km', 'value': 100.0},
                {'label': '🌐 Worldwide', 'value': 9999.0},
              ].map((radiusItem) {
                final val = radiusItem['value'] as double;
                final isSelected = (appState.searchRadiusKm - val).abs() < 0.1;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(radiusItem['label'] as String),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        appState.setSearchRadius(val);
                        appState.fetchAndSyncNearestVehiclesFromDatabase(radiusKm: val);
                      }
                    },
                    selectedColor: AppColors.secondary,
                    backgroundColor: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLow,
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Customer Location & Nearest Host Matching Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [AppColors.surfaceContainerHighDark, AppColors.surfaceContainerDark]
                    : [AppColors.primaryContainer.withOpacity(0.4), AppColors.secondaryContainer.withOpacity(0.3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.secondaryFixedDim.withOpacity(0.3) : AppColors.primary.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    appState.isLiveLocationActive ? Icons.my_location : Icons.near_me,
                    color: AppColors.secondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'CUSTOMER LOCATION MATCH',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Colors.grey),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${appState.getNearbyVehiclesCount()} Nearest Hosts',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppColors.onSecondaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Connected from ${appState.selectedLocation.split(',').first} (${appState.searchRadiusKm >= 999 ? "Worldwide" : "Within ${appState.searchRadiusKm.toInt()} km"})',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 1. SHORTLISTED VEHICLES SECTION (FIRST AS REQUESTED)
          if (_selectedType != '🏍️ Guided Tours') ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shortlisted Vehicles (${filteredVehicles.length})',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      appState.sortOption == 'nearest'
                          ? 'Ordered by proximity to client location (#1 Top)'
                          : 'Sorted by ${appState.sortOption.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.secondaryFixedDim : AppColors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
                    ),
                  ),
                  child: DropdownButton<String>(
                    value: appState.sortOption,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.sort, size: 18, color: AppColors.secondary),
                    items: const [
                      DropdownMenuItem(
                        value: 'nearest',
                        child: Text('📍 Nearest First (#1 Top)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                      DropdownMenuItem(
                        value: 'price',
                        child: Text('💲 Price: Low to High', style: TextStyle(fontSize: 11)),
                      ),
                      DropdownMenuItem(
                        value: 'rating',
                        child: Text('⭐ Highest Rated', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        appState.setSortOption(val);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (filteredVehicles.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.directions_car, size: 36, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('No vehicles found matching search criteria.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              )
            else ...[
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredVehicles.length,
                itemBuilder: (context, index) {
                  final vehicle = filteredVehicles[index];
                  return _buildDiscoveryCard(context, appState, vehicle, distanceRank: index + 1);
                },
              ),
              const SizedBox(height: 20),
            ],
          ],

          // 2. GUIDED GROUP TOURS SECTION (SECOND AS REQUESTED)
          if (_selectedType == 'All' || _selectedType == '🏍️ Guided Tours') ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Guided Group Tours (${filteredTours.length})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (_selectedType != '🏍️ Guided Tours')
                  TextButton(
                    onPressed: () => setState(() => _selectedType = '🏍️ Guided Tours'),
                    child: const Text('See All Tours', style: TextStyle(color: AppColors.secondary, fontSize: 12)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (filteredTours.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.tour, size: 36, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('No guided tours found matching query.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredTours.length,
                itemBuilder: (context, index) {
                  final tour = filteredTours[index];
                  return _buildDiscoveryTourCard(context, appState, tour);
                },
              ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  Widget _buildDiscoveryCard(BuildContext context, AppState appState, Vehicle vehicle, {int distanceRank = 1}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isBooked = appState.isVehicleBookedDuring(vehicle.id, appState.pickupDateTime, appState.dropoffDateTime);
    final freeUpTime = appState.getVehicleFreeUpTime(vehicle.id);
    final travelTime = appState.getEstimatedTravelTimeToVehicle(vehicle);

    return GestureDetector(
      onTap: () {
        appState.selectVehicle(vehicle);
        appState.setNavIndex(2);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: distanceRank == 1 && appState.sortOption == 'nearest'
                ? AppColors.secondary
                : (isBooked ? Colors.red.shade400 : (isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight)),
            width: (distanceRank == 1 && appState.sortOption == 'nearest') || isBooked ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AutoSlidingImageCarousel(
                  images: vehicle.images.isNotEmpty ? vehicle.images : [vehicle.imageUrl],
                  height: 260,
                  fallbackIcon: vehicle.type == VehicleType.bike ? Icons.two_wheeler : Icons.directions_car,
                ),

                // Distance Rank Proximity Badge (#1 Top Nearest Host)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: distanceRank == 1
                          ? AppColors.secondary
                          : (distanceRank <= 3 ? AppColors.primary : Colors.black.withOpacity(0.75)),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          distanceRank == 1 ? Icons.emoji_events : Icons.navigation,
                          size: 13,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          distanceRank == 1
                              ? '🏆 #1 TOP NEAREST HOST'
                              : '#$distanceRank PROXIMITY HOST',
                          style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),

                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isBooked ? Colors.red.shade700 : Colors.green.shade700,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isBooked ? Icons.lock_clock : Icons.check_circle,
                          size: 13,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isBooked
                              ? 'BOOKED • Free ${freeUpTime != null ? _formatDateTime(freeUpTime) : "Soon"}'
                              : 'AVAILABLE NOW',
                          style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.black45,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        vehicle.isFavorite ? Icons.favorite : Icons.favorite_border,
                        size: 20,
                        color: vehicle.isFavorite ? Colors.redAccent : Colors.white,
                      ),
                      onPressed: () => appState.toggleFavoriteVehicle(vehicle.id),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isBooked && freeUpTime != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 14, color: Colors.red.shade700),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Rented during window. Available for pickup: ${_formatDateTime(freeUpTime)}',
                              style: TextStyle(fontSize: 11, color: Colors.red.shade700, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          vehicle.title,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            '${vehicle.rating}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            ' (${vehicle.reviewCount})',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  
                  // Proximity & Travel Time Indicator Strip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.near_me, size: 14, color: AppColors.secondary),
                        const SizedBox(width: 6),
                        Text(
                          '${appState.getFormattedDistanceToVehicle(vehicle)} away',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '($travelTime)',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white70 : Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          appState.isLiveLocationActive ? Icons.my_location : Icons.location_on_outlined,
                          size: 13,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          vehicle.location.split(',').first,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '₹${vehicle.pricePerDay.toStringAsFixed(0)} / day',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.secondaryFixedDim : AppColors.primary,
                            ),
                          ),
                          const Text(
                            'Includes full insurance & IoT keyless',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {
                          appState.selectVehicle(vehicle);
                          appState.setNavIndex(2); // Go to Vehicle Detail
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isBooked ? Colors.amber.shade900 : AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        child: Text(isBooked ? 'Pre-Book Next Slot' : 'Rent Now'),
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

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return 'N/A';
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = months[dt.month - 1];
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '$month ${dt.day}, $hour:$min $period';
  }

  void _showPickupDropoffPicker(BuildContext context, AppState appState) async {
    final dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 120)),
      initialDateRange: DateTimeRange(start: appState.pickupDateTime, end: appState.dropoffDateTime),
      helpText: 'Select Pickup & Dropoff Dates',
    );

    if (dateRange != null && context.mounted) {
      final pickupTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(appState.pickupDateTime),
        helpText: 'Select Pickup Time',
      );

      if (pickupTime != null && context.mounted) {
        final dropoffTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(appState.dropoffDateTime),
          helpText: 'Select Dropoff Time',
        );

        if (dropoffTime != null) {
          final pickup = DateTime(dateRange.start.year, dateRange.start.month, dateRange.start.day, pickupTime.hour, pickupTime.minute);
          final dropoff = DateTime(dateRange.end.year, dateRange.end.month, dateRange.end.day, dropoffTime.hour, dropoffTime.minute);
          appState.setPickupAndDropoff(pickup, dropoff);
        }
      }
    }
  }

  void _showFilterBottomSheet(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    double currentMaxPrice = appState.maxPriceFilter;
    String selectedTransmission = appState.selectedTransmissionFilter;
    String selectedFuel = appState.selectedFuelFilter;
    bool instantOnly = appState.instantBookOnlyFilter;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Filter Vehicles & Fleet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {
                      appState.resetSearchFilters();
                      Navigator.pop(ctx);
                    },
                    child: const Text('Reset All'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Max Daily Rental Rate', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text('₹${currentMaxPrice.toStringAsFixed(0)} / day', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                ],
              ),
              Slider(
                value: currentMaxPrice,
                min: 100,
                max: 5000,
                divisions: 49,
                label: '₹${currentMaxPrice.toStringAsFixed(0)}',
                onChanged: (v) {
                  setState(() => currentMaxPrice = v);
                },
              ),
              const SizedBox(height: 16),
              const Text('Vehicle Transmission', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['All', 'Automatic', 'Manual'].map((t) {
                  final isSel = selectedTransmission == t;
                  return ChoiceChip(
                    label: Text(t),
                    selected: isSel,
                    onSelected: (val) {
                      if (val) setState(() => selectedTransmission = t);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text('Fuel / Power Type', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['All', 'Electric', 'Gasoline', 'Petrol', 'Diesel'].map((f) {
                  final isSel = selectedFuel == f;
                  return ChoiceChip(
                    label: Text(f),
                    selected: isSel,
                    onSelected: (val) {
                      if (val) setState(() => selectedFuel = f);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Instant Booking Only', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Book keyless rentals without host approval wait', style: TextStyle(fontSize: 11, color: Colors.grey)),
                value: instantOnly,
                onChanged: (v) {
                  setState(() => instantOnly = v);
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    appState.setMaxPriceFilter(currentMaxPrice);
                    appState.setTransmissionFilter(selectedTransmission);
                    appState.setFuelFilter(selectedFuel);
                    if (appState.instantBookOnlyFilter != instantOnly) {
                      appState.toggleInstantBookOnly();
                    }
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Apply Fleet Filters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiscoveryTourCard(BuildContext context, AppState appState, Tour tour) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => showTourDetailsModal(context, appState, tour),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AutoSlidingImageCarousel(
                  images: tour.images.isNotEmpty ? tour.images : [tour.imageUrl],
                  height: 260,
                  fallbackIcon: Icons.tour,
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.tour, color: Colors.white, size: 12),
                        SizedBox(width: 4),
                        Text('GUIDED TOUR', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: Icon(
                        tour.isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: tour.isFavorite ? Colors.red : Colors.white,
                        size: 20,
                      ),
                      onPressed: () => appState.toggleFavoriteTour(tour.id),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '₹${tour.price.toStringAsFixed(0)} / rider',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          tour.title,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 2),
                          Text(
                            tour.rating.toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${tour.location} • ${tour.duration}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundImage: NetworkImage(tour.guideAvatar.isNotEmpty
                                ? tour.guideAvatar
                                : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&q=80'),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            tour.guideName.isNotEmpty ? tour.guideName : 'Verified Local Host',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () => showTourDetailsModal(context, appState, tour),
                        icon: const Icon(Icons.info_outline, size: 14),
                        label: const Text('View Tour Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
}
