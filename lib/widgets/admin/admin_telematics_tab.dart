import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../theme/app_colors.dart';
import 'admin_metric_card.dart';

class AdminTelematicsTab extends StatefulWidget {
  final List<Vehicle> vehicles;
  final Function(Vehicle vehicle, bool lockEngine) onToggleEngineLock;

  const AdminTelematicsTab({
    super.key,
    required this.vehicles,
    required this.onToggleEngineLock,
  });

  @override
  State<AdminTelematicsTab> createState() => _AdminTelematicsTabState();
}

class _AdminTelematicsTabState extends State<AdminTelematicsTab> {
  String _searchQuery = '';
  String _selectedStateFilter = 'All';

  List<Vehicle> get _filteredVehicles {
    return widget.vehicles.where((v) {
      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          v.title.toLowerCase().contains(q) ||
          v.location.toLowerCase().contains(q) ||
          v.hostName.toLowerCase().contains(q);

      final isLocked = v.iotData['locked'] ?? false;
      final engineOn = v.iotData['engineOn'] ?? false;

      bool matchesState = true;
      if (_selectedStateFilter == 'Engine On') {
        matchesState = engineOn;
      } else if (_selectedStateFilter == 'Immobilized') {
        matchesState = isLocked;
      } else if (_selectedStateFilter == 'Low Battery') {
        final battery = (v.iotData['batteryLevel'] as num?)?.toInt() ?? 100;
        matchesState = battery < 25;
      }

      return matchesSearch && matchesState;
    }).toList();
  }

  void _confirmToggleImmobilizer(Vehicle vehicle, bool lock) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(lock ? Icons.lock : Icons.lock_open, color: lock ? Colors.red : Colors.green),
            const SizedBox(width: 8),
            Text(lock ? 'Trigger Engine Cutoff?' : 'Restore Vehicle Engine?'),
          ],
        ),
        content: Text(
          lock
              ? 'Warning: Sending the remote immobilizer command will instantly cut ignition power and engage electronic anti-theft locks on "${vehicle.title}". Use in cases of geo-fence breaches, theft, or critical compliance violations.'
              : 'Restoring vehicle engine will disengage electronic immobilizer locks and allow regular ignition start for "${vehicle.title}".',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: lock ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              widget.onToggleEngineLock(vehicle, lock);
            },
            child: Text(lock ? 'Confirm Emergency Lock' : 'Confirm Engine Unlock'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalVehicles = widget.vehicles.length;
    final runningEngines = widget.vehicles.where((v) => v.iotData['engineOn'] == true).length;
    final immobilizedVehicles = widget.vehicles.where((v) => v.iotData['locked'] == true).length;
    final lowBatteryVehicles = widget.vehicles.where((v) {
      final b = (v.iotData['batteryLevel'] as num?)?.toInt() ?? 80;
      return b < 25;
    }).length;

    final filtered = _filteredVehicles;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Telematics Hub Overview Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;
              return GridView.count(
                crossAxisCount: isWide ? 4 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: isWide ? 1.8 : 1.6,
                children: [
                  AdminMetricCard(
                    title: 'Active IoT Telemetry Nodes',
                    value: '$totalVehicles Devices',
                    subtitle: 'GPS & OBD-II transceivers connected',
                    icon: Icons.cell_tower,
                    accentColor: Colors.blue.shade700,
                  ),
                  AdminMetricCard(
                    title: 'Engines In Motion',
                    value: '$runningEngines Vehicles',
                    subtitle: 'Active ignition on the road',
                    icon: Icons.electric_bike,
                    accentColor: Colors.green.shade700,
                    badgeText: runningEngines > 0 ? 'ACTIVE' : null,
                    badgeColor: Colors.green,
                  ),
                  AdminMetricCard(
                    title: 'Remote Immobilizer Active',
                    value: '$immobilizedVehicles Locked',
                    subtitle: 'Anti-theft locks engaged',
                    icon: Icons.lock_outline,
                    accentColor: Colors.red.shade700,
                  ),
                  AdminMetricCard(
                    title: 'Battery / Fuel Critical',
                    value: '$lowBatteryVehicles Nodes',
                    subtitle: 'Vehicles below 25% charge/fuel',
                    icon: Icons.battery_alert,
                    accentColor: Colors.orange.shade700,
                    badgeText: lowBatteryVehicles > 0 ? 'ATTN' : null,
                    badgeColor: Colors.orange,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // Search & Filter
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search fleet nodes by title, location, or host...',
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceContainerLowDark : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppColors.outlineVariantDark : Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedStateFilter,
                    items: ['All', 'Engine On', 'Immobilized', 'Low Battery'].map((st) {
                      return DropdownMenuItem(value: st, child: Text('Filter: $st'));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedStateFilter = val);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Fleet IoT Grid
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No vehicle telemetry nodes match your filter.'))
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 420,
                      mainAxisExtent: 220,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final v = filtered[index];
                      final isLocked = v.iotData['locked'] ?? false;
                      final engineOn = v.iotData['engineOn'] ?? false;
                      final battery = (v.iotData['batteryLevel'] as num?)?.toInt() ?? 82;
                      final odo = (v.iotData['odometer'] as num?)?.toInt() ?? 12400;
                      final frontPsi = (v.iotData['tirePressureFront'] as num?)?.toDouble() ?? 36.0;
                      final rearPsi = (v.iotData['tirePressureRear'] as num?)?.toDouble() ?? 40.0;

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceContainerLowDark : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isLocked
                                ? Colors.red.shade400
                                : (engineOn ? Colors.green.shade600 : (isDark ? AppColors.outlineVariantDark : Colors.grey.shade200)),
                            width: isLocked || engineOn ? 1.5 : 1.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.grey.shade200,
                                  ),
                                  child: v.imageUrl.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            v.imageUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.directions_car),
                                          ),
                                        )
                                      : const Icon(Icons.directions_car, color: Colors.grey),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        v.title,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${v.category} • ${v.location}',
                                        style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (engineOn ? Colors.green : Colors.grey).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    engineOn ? 'IGNITION ON' : 'STOPPED',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: engineOn ? Colors.green : Colors.grey,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 14),
                            // Telemetry Stats Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildTelemPill('Battery', '$battery%', Icons.battery_charging_full, battery < 25 ? Colors.red : Colors.green),
                                _buildTelemPill('Odometer', '$odo km', Icons.speed, Colors.blue),
                                _buildTelemPill('Tire PSI', '${frontPsi.toStringAsFixed(0)}/${rearPsi.toStringAsFixed(0)}', Icons.album_outlined, Colors.indigo),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Controls & Live coordinates
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'GPS: ${v.latitude.toStringAsFixed(3)}, ${v.longitude.toStringAsFixed(3)}',
                                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                                ),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isLocked ? Colors.green : Colors.red.shade700,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  ),
                                  icon: Icon(isLocked ? Icons.lock_open : Icons.lock, size: 14),
                                  label: Text(
                                    isLocked ? 'Unlock Engine' : 'Immobilize',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                  onPressed: () => _confirmToggleImmobilizer(v, !isLocked),
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

  Widget _buildTelemPill(String label, String val, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
            Text(val, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ],
    );
  }
}
