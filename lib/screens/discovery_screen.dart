import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';
import '../widgets/auto_sliding_image_carousel.dart';

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

    final filteredVehicles = appState.filteredVehicles.where((v) {
      final matchesSearch = _searchQuery.isEmpty ||
          v.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          v.location.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          v.category.toLowerCase().contains(_searchQuery.toLowerCase());

      final isBooked = appState.isVehicleBookedDuring(v.id, appState.pickupDateTime, appState.dropoffDateTime);

      bool matchesAvailability = true;
      if (_selectedType == '🟢 Available Now') {
        matchesAvailability = !isBooked && v.status == 'Available';
      } else if (_selectedType == '🔴 Currently Rented') {
        matchesAvailability = isBooked || v.status == 'Booked';
      } else if (_selectedType == 'Motorcycles') {
        matchesAvailability = v.type == VehicleType.bike;
      } else if (_selectedType == 'Cars') {
        matchesAvailability = v.type == VehicleType.car;
      } else if (_selectedType == 'Scooters') {
        matchesAvailability = v.type == VehicleType.scooter;
      }

      return matchesSearch && matchesAvailability;
    }).toList();

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

          // Search Bar
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Search bikes, cars, scooters, or guided tours...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
            ),
          ),

          const SizedBox(height: 16),

          // Interactive Location, Pickup & Dropoff Date/Time Search Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, color: AppColors.primary, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SEARCH LOCATION',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                          Text(
                            appState.selectedLocation,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4)),
                      child: const Text('Change Location', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  children: [
                    const Icon(Icons.calendar_month, color: AppColors.secondary, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PICKUP & DROPOFF SCHEDULE',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
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

          // Filter Chips (Including Guided Tours filter)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', '🏍️ Guided Tours', '🟢 Available Now', '🔴 Currently Rented', 'Motorcycles', 'Cars', 'Scooters'].map((type) {
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

          const SizedBox(height: 20),

          // AI Smart Recommendation Badge Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.tertiaryContainer.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.tertiaryContainer),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_awesome, color: AppColors.tertiary, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Real-time Availability Tracker • Search vehicles and guided group tours',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 1. GUIDED TOURS SECTION
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

          // 2. VEHICLES SECTION
          if (_selectedType != '🏍️ Guided Tours') ...[
            Text(
              'Rides Matching Schedule (${filteredVehicles.length})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (filteredVehicles.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
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
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredVehicles.length,
                itemBuilder: (context, index) {
                  final vehicle = filteredVehicles[index];
                  return _buildDiscoveryCard(context, appState, vehicle);
                },
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildDiscoveryCard(BuildContext context, AppState appState, Vehicle vehicle) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isBooked = appState.isVehicleBookedDuring(vehicle.id, appState.pickupDateTime, appState.dropoffDateTime);
    final freeUpTime = appState.getVehicleFreeUpTime(vehicle.id);

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
            color: isBooked
                ? Colors.red.shade400
                : (isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight),
            width: isBooked ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AutoSlidingImageCarousel(
                  images: vehicle.images.isNotEmpty ? vehicle.images : [vehicle.imageUrl],
                  height: 180,
                  fallbackIcon: vehicle.type == VehicleType.bike ? Icons.two_wheeler : Icons.directions_car,
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shield, size: 12, color: AppColors.secondaryFixedDim),
                        const SizedBox(width: 4),
                        Text(
                          'Trust Score ${vehicle.hostTrustScore}%',
                          style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
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
                  Row(
                    children: [
                      const Icon(Icons.directions_bus_filled_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('${vehicle.category} • ${vehicle.transmission}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const Spacer(),
                      const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 2),
                      Text(vehicle.location, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
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
      onTap: () => _showTourDetailsModal(context, appState, tour),
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
                  height: 180,
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
                        onPressed: () => _showTourDetailsModal(context, appState, tour),
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

  void _showTourDetailsModal(BuildContext context, AppState appState, Tour tour) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final galleryImages = tour.images.isNotEmpty ? tour.images : [tour.imageUrl];
    int activeImageIndex = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLowest,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 12),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          AutoSlidingImageCarousel(
                            images: galleryImages,
                            height: 220,
                            borderRadius: BorderRadius.circular(20),
                            fallbackIcon: Icons.tour,
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
                                ),
                                onPressed: () {
                                  appState.toggleFavoriteTour(tour.id);
                                  setState(() {});
                                },
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Multi-Image Thumbnails
                      if (galleryImages.length > 1) ...[
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: List.generate(galleryImages.length, (i) {
                              final isSel = i == activeImageIndex;
                              return GestureDetector(
                                onTap: () => setState(() => activeImageIndex = i),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  width: 60,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSel ? AppColors.secondary : Colors.transparent,
                                      width: 2,
                                    ),
                                    image: DecorationImage(
                                      image: NetworkImage(galleryImages[i]),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.amber.shade700, borderRadius: BorderRadius.circular(6)),
                            child: Row(
                              children: [
                                const Icon(Icons.star, color: Colors.white, size: 14),
                                const SizedBox(width: 4),
                                Text('${tour.rating.toStringAsFixed(1)} (${tour.reviewCount} reviews)', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.secondaryContainer, borderRadius: BorderRadius.circular(6)),
                            child: Text(tour.duration, style: TextStyle(color: isDark ? Colors.white : AppColors.secondary, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Text(tour.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: AppColors.secondary, size: 16),
                          const SizedBox(width: 4),
                          Text(tour.location, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
                        ],
                      ),

                      const Divider(height: 24),

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceContainerHighDark : AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundImage: NetworkImage(tour.guideAvatar.isNotEmpty ? tour.guideAvatar : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&q=80'),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('TOUR GUIDE & HOST', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                                  Text(tour.guideName.isNotEmpty ? tour.guideName : 'Verified Local Host', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: Colors.green.shade700, borderRadius: BorderRadius.circular(20)),
                              child: const Text('VERIFIED', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      if (tour.description.isNotEmpty) ...[
                        const Text('About This Tour', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 6),
                        Text(tour.description, style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87, height: 1.4)),
                        const SizedBox(height: 16),
                      ],

                      if (tour.includedGear.isNotEmpty) ...[
                        const Text('Included Gear & Amenities', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: tour.includedGear.map((g) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle, color: AppColors.secondary, size: 14),
                                const SizedBox(width: 6),
                                Text(g, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          )).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (tour.waypoints.isNotEmpty) ...[
                        const Text('Route Highlights & Stops', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 8),
                        Column(
                          children: tour.waypoints.asMap().entries.map((entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 10,
                                  backgroundColor: AppColors.secondary,
                                  child: Text('${entry.key + 1}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 10),
                                Text(entry.value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          )).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceContainerDark : Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, -4))],
                ),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('TOUR PRICE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                        Text('₹${tour.price.toStringAsFixed(0)}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? AppColors.secondaryFixedDim : AppColors.secondary)),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          appState.selectTour(tour);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Selected tour: "${tour.title}". Proceeding to checkout.'),
                              backgroundColor: Colors.green.shade700,
                            ),
                          );
                          appState.setNavIndex(4);
                        },
                        icon: const Icon(Icons.confirmation_number, color: Colors.white, size: 18),
                        label: const Text('Book Guided Tour', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
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
}
