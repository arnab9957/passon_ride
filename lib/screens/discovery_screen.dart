import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';

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
      final matchesSearch = v.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          v.location.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          v.category.toLowerCase().contains(_searchQuery.toLowerCase());

      final isBooked = appState.isVehicleBookedDuring(v.id, appState.pickupDateTime, appState.dropoffDateTime);

      bool matchesAvailability = true;
      if (_selectedType == '🟢 Available Now') {
        matchesAvailability = !isBooked;
      } else if (_selectedType == '🔴 Currently Rented') {
        matchesAvailability = isBooked;
      } else if (_selectedType == 'Motorcycles') {
        matchesAvailability = v.type == VehicleType.bike;
      } else if (_selectedType == 'Cars') {
        matchesAvailability = v.type == VehicleType.car;
      } else if (_selectedType == 'Scooters') {
        matchesAvailability = v.type == VehicleType.scooter;
      }

      return matchesSearch && matchesAvailability;
    }).toList();

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
              hintText: 'Search bikes, cars, or scooters...',
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

          // Filter Chips (Including Availability status filters)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', '🟢 Available Now', '🔴 Currently Rented', 'Motorcycles', 'Cars', 'Scooters'].map((type) {
                final isSelected = _selectedType == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(type),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedType = type);
                    },
                    selectedColor: type.contains('🟢')
                        ? Colors.green.shade700
                        : (type.contains('🔴') ? Colors.red.shade700 : AppColors.primary),
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
                    'Real-time Availability Tracker • Showing bikes matching your exact schedule',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Results List
          Text(
            'Rides Matching Schedule (${filteredVehicles.length})',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

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
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Image.network(
                    vehicle.imageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => Container(
                      height: 180,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.directions_car, size: 50, color: Colors.grey),
                    ),
                  ),
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
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filter Rides', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Price Range per Day', style: TextStyle(fontWeight: FontWeight.w600)),
            Slider(value: 150, min: 30, max: 400, onChanged: (v) {}),
            const SizedBox(height: 16),
            const Text('Vehicle Transmission', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton(onPressed: () {}, child: const Text('Automatic')),
                const SizedBox(width: 8),
                OutlinedButton(onPressed: () {}, child: const Text('Manual')),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Apply Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
