import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../theme/app_colors.dart';

class AdminVehiclesTab extends StatefulWidget {
  final List<Vehicle> vehicles;
  final Function(Vehicle vehicle, String newStatus) onUpdateStatus;
  final Function(Vehicle vehicle) onDeleteVehicle;
  final Function(Vehicle vehicle, bool lockEngine) onToggleEngineLock;

  const AdminVehiclesTab({
    super.key,
    required this.vehicles,
    required this.onUpdateStatus,
    required this.onDeleteVehicle,
    required this.onToggleEngineLock,
  });

  @override
  State<AdminVehiclesTab> createState() => _AdminVehiclesTabState();
}

class _AdminVehiclesTabState extends State<AdminVehiclesTab> {
  String _searchQuery = '';
  String _selectedStatus = 'All';
  String _selectedCategory = 'All';

  List<Vehicle> get _filteredVehicles {
    return widget.vehicles.where((vehicle) {
      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          vehicle.title.toLowerCase().contains(q) ||
          vehicle.location.toLowerCase().contains(q) ||
          vehicle.hostName.toLowerCase().contains(q) ||
          vehicle.category.toLowerCase().contains(q);

      final matchesStatus = _selectedStatus == 'All' ||
          vehicle.status.toLowerCase() == _selectedStatus.toLowerCase();

      final matchesCategory = _selectedCategory == 'All' ||
          vehicle.category.toLowerCase() == _selectedCategory.toLowerCase();

      return matchesSearch && matchesStatus && matchesCategory;
    }).toList();
  }

  void _showStatusDialog(Vehicle vehicle) {
    String current = vehicle.status;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Change Status: ${vehicle.title}'),
          content: RadioGroup<String>(
            groupValue: current,
            onChanged: (val) {
              if (val != null) setDialogState(() => current = val);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: ['Available', 'Booked', 'Maintenance', 'Archived'].map((status) {
                return RadioListTile<String>(
                  title: Text(status),
                  value: status,
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                widget.onUpdateStatus(vehicle, current);
              },
              child: const Text('Update Status'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Vehicle?'),
        content: Text('Are you sure you want to remove "${vehicle.title}" from the platform catalog? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              widget.onDeleteVehicle(vehicle);
            },
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  void _showVehicleDetailsDialog(Vehicle vehicle) {
    final isLocked = vehicle.iotData['locked'] ?? false;
    final engineOn = vehicle.iotData['engineOn'] ?? false;
    final battery = vehicle.iotData['batteryLevel'] ?? 85;
    final odo = vehicle.iotData['odometer'] ?? 10500;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(vehicle.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (vehicle.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    vehicle.imageUrl,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const SizedBox(),
                  ),
                ),
              const SizedBox(height: 12),
              _buildRow('Vehicle ID', vehicle.id),
              _buildRow('Category', vehicle.category),
              _buildRow('Status', vehicle.status),
              _buildRow('Daily Rate', '₹${vehicle.pricePerDay.toStringAsFixed(0)} / day'),
              _buildRow('Location', vehicle.location),
              _buildRow('Host Name', vehicle.hostName),
              _buildRow('Fuel & Trans.', '${vehicle.fuelType} • ${vehicle.transmission}'),
              _buildRow('Seats', '${vehicle.seats} Seater'),
              _buildRow('Rating', '★ ${vehicle.rating.toStringAsFixed(1)} (${vehicle.reviewCount} reviews)'),
              const Divider(height: 16),
              const Text('Telematics & IoT Node:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 6),
              _buildRow('Odometer', '$odo km'),
              _buildRow('Battery / Fuel', '$battery%'),
              _buildRow('Engine State', engineOn ? 'ON' : 'OFF'),
              _buildRow('Security Lock', isLocked ? 'LOCKED' : 'UNLOCKED'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _filteredVehicles;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search and Filters
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by vehicle title, location, host, or model...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    filled: true,
                    fillColor: isDark ? AppColors.surfaceContainerLowDark : Colors.white,
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              const SizedBox(width: 12),
              // Status Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceContainerLowDark : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppColors.outlineVariantDark : Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedStatus,
                    items: ['All', 'Available', 'Booked', 'Maintenance', 'Archived'].map((status) {
                      return DropdownMenuItem(value: status, child: Text('Status: $status'));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedStatus = val);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Category Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Car', 'Bike', 'Scooter', 'EV', 'Luxury'].map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedCategory = cat);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Vehicles List
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No vehicles found matching criteria.'))
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final vehicle = filtered[index];
                      final isLocked = vehicle.iotData['locked'] ?? false;
                      final battery = vehicle.iotData['batteryLevel'] ?? 85;

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceContainerLowDark : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? AppColors.outlineVariantDark : Colors.grey.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Thumbnail
                            Container(
                              width: 80,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey.shade200,
                              ),
                              child: vehicle.imageUrl.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        vehicle.imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.directions_car),
                                      ),
                                    )
                                  : const Icon(Icons.directions_car, color: Colors.grey),
                            ),
                            const SizedBox(width: 14),
                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        vehicle.title,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      const SizedBox(width: 8),
                                      _buildStatusChip(vehicle.status),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(vehicle.category, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Hosted by: ${vehicle.hostName} • ₹${vehicle.pricePerDay.toStringAsFixed(0)}/day • ${vehicle.location}',
                                    style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.battery_charging_full, size: 14, color: battery < 20 ? Colors.red : Colors.green),
                                      const SizedBox(width: 2),
                                      Text('$battery%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 10),
                                      Text(
                                        '${vehicle.transmission} • ${vehicle.fuelType} • ${vehicle.seats} seats',
                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Actions
                            Wrap(
                              spacing: 6,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.info_outline, size: 20),
                                  tooltip: 'Vehicle Details',
                                  onPressed: () => _showVehicleDetailsDialog(vehicle),
                                ),
                                IconButton(
                                  icon: Icon(
                                    isLocked ? Icons.lock : Icons.lock_open,
                                    size: 20,
                                    color: isLocked ? Colors.red : Colors.green,
                                  ),
                                  tooltip: isLocked ? 'Unlock Remote Immobilizer' : 'Trigger Remote Immobilizer (Lock)',
                                  onPressed: () => widget.onToggleEngineLock(vehicle, !isLocked),
                                ),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.edit, size: 14),
                                  label: const Text('Status', style: TextStyle(fontSize: 11)),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  ),
                                  onPressed: () => _showStatusDialog(vehicle),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                  tooltip: 'Delete Vehicle',
                                  onPressed: () => _showDeleteConfirmDialog(vehicle),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bg;
    Color fg;
    switch (status.toLowerCase()) {
      case 'available':
        bg = Colors.green.withValues(alpha: 0.15);
        fg = Colors.green.shade700;
        break;
      case 'booked':
        bg = Colors.blue.withValues(alpha: 0.15);
        fg = Colors.blue.shade700;
        break;
      case 'maintenance':
        bg = Colors.orange.withValues(alpha: 0.15);
        fg = Colors.orange.shade800;
        break;
      default:
        bg = Colors.grey.withValues(alpha: 0.15);
        fg = Colors.grey.shade700;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg)),
    );
  }
}
