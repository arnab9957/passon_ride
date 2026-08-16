import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';

class ProviderDashboardScreen extends StatelessWidget {
  const ProviderDashboardScreen({super.key});

  void _confirmDeleteVehicle(BuildContext context, AppState appState, Vehicle vehicle) {
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
              await appState.deleteVehicle(vehicle.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Vehicle "${vehicle.title}" deleted permanently.'),
                    backgroundColor: Colors.red.shade800,
                  ),
                );
              }
            },
            child: const Text('Delete Permanently', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditVehicleDialog(BuildContext context, AppState appState, Vehicle vehicle) {
    final titleController = TextEditingController(text: vehicle.title);
    final priceController = TextEditingController(text: vehicle.pricePerDay.toStringAsFixed(0));
    final locationController = TextEditingController(text: vehicle.location);
    final descriptionController = TextEditingController(text: vehicle.description);
    final imageUrlController = TextEditingController(text: vehicle.imageUrl);
    String selectedFuelType = vehicle.fuelType;
    String selectedTransmission = vehicle.transmission;

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
              children: [
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
                  controller: imageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Image Photo URL / Data URI',
                    prefixIcon: Icon(Icons.image),
                  ),
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
                  imageUrl: imageUrlController.text.trim().isNotEmpty ? imageUrlController.text.trim() : vehicle.imageUrl,
                );

                Navigator.pop(ctx);
                await appState.updateVehicle(updatedVehicle);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Vehicle "${updatedVehicle.title}" updated successfully!'),
                      backgroundColor: Colors.green.shade700,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.save),
              label: const Text('Save Details'),
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

    final currentUid = appState.userProfile?.uid ?? appState.firebaseUser?.uid ?? '';
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

          const SizedBox(height: 20),

          // Metrics 2x2 Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildMetricCard(context, '₹${appState.totalEarnings.toStringAsFixed(2)}', 'Total Earnings', '+18.4% this mo', Icons.currency_rupee, AppColors.secondary),
              _buildMetricCard(context, '${appState.vehicles.length} Vehicles', 'Fleet Count', '${appState.activeBookings.length} Active Rentals', Icons.directions_car, AppColors.primary),
              _buildMetricCard(context, '4.96 ★', 'Host Rating', '124 Total Reviews', Icons.star, Colors.amber),
              _buildMetricCard(context, '5 Hardware', 'IoT Telematics', 'All Systems Green', Icons.sensors, AppColors.tertiary),
            ],
          ),

          const SizedBox(height: 24),

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
                  const Text('Click "Add Listing" to host your bike or car on PassonRide.', style: TextStyle(fontSize: 12, color: Colors.grey)),
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

          // Upcoming Bookings Header
          const Text('Upcoming Rental Requests & Active Bookings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          if (appState.activeBookings.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('No active rental requests at the moment.', style: TextStyle(color: Colors.grey)),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: appState.activeBookings.length,
              itemBuilder: (ctx, i) {
                final booking = appState.activeBookings[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
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
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              booking.vehicleImageUrl,
                              height: 44,
                              width: 44,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => const Icon(Icons.directions_car),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(booking.vehicleTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                Text(
                                  'Renter: ${booking.hostName} • PIN: ${booking.unlockPasscode}',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                                if (booking.paymentIntentId.isNotEmpty)
                                  Text(
                                    'Stripe Intent: ${booking.paymentIntentId}',
                                    style: const TextStyle(fontSize: 10, color: Colors.blueGrey, fontWeight: FontWeight.w500),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: booking.status == 'Active'
                                  ? Colors.green.shade100
                                  : (booking.status == 'Completed'
                                      ? Colors.teal.shade100
                                      : (booking.status == 'Cancelled' ? Colors.red.shade100 : Colors.blue.shade100)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              booking.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: booking.status == 'Active'
                                    ? Colors.green.shade900
                                    : (booking.status == 'Completed'
                                        ? Colors.teal.shade900
                                        : (booking.status == 'Cancelled' ? Colors.red.shade900 : Colors.blue.shade900)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        children: [
                          Text(
                            'Payout: ₹${booking.totalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary, fontSize: 13),
                          ),
                          const Spacer(),
                          if (booking.status == 'Confirmed' || booking.status == 'Active') ...[
                            ElevatedButton.icon(
                              onPressed: () async {
                                await appState.completeBookingRental(booking.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Rental completed & Escrow payout released!'),
                                      backgroundColor: Colors.teal,
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.check_circle_outline, size: 14),
                              label: const Text('Complete & Release Escrow', style: TextStyle(fontSize: 11)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.secondary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          OutlinedButton.icon(
                            onPressed: () => appState.setNavIndex(5),
                            icon: const Icon(Icons.chat, size: 14),
                            label: const Text('Chat', style: TextStyle(fontSize: 11)),
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
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
}
