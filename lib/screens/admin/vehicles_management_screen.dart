import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../models/models.dart';

class VehiclesManagementScreen extends StatefulWidget {
  const VehiclesManagementScreen({super.key});

  @override
  State<VehiclesManagementScreen> createState() => _VehiclesManagementScreenState();
}

class _VehiclesManagementScreenState extends State<VehiclesManagementScreen> {
  final int _limit = 20;
  int _currentPage = 1;
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedStatus = 'All';

  List<Vehicle> _vehicles = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVehicles() async {
    setState(() => _isLoading = true);
    final appState = Provider.of<AppState>(context, listen: false);
    final vehicles = await appState.supabaseService.getVehiclesPaginated(
      _currentPage,
      _limit,
      searchQuery: _searchQuery,
      status: _selectedStatus,
    );
    if (!mounted) return;
    setState(() {
      _vehicles = vehicles;
      _isLoading = false;
    });
  }

  void _onSearchChanged(String query) {
    _searchQuery = query;
    _currentPage = 1;
    _loadVehicles();
  }

  void _onStatusChanged(String? status) {
    if (status != null) {
      _selectedStatus = status;
      _currentPage = 1;
      _loadVehicles();
    }
  }

  Future<void> _updateVehicleStatus(Vehicle vehicle, String newStatus) async {
    final appState = Provider.of<AppState>(context, listen: false);
    await appState.supabaseService.updateVehicleStatus(vehicle.id, newStatus);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Vehicle updated to $newStatus.'),
    ));
    _loadVehicles();
  }

  void _showVehicleDetails(Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(vehicle.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (vehicle.imageUrl.isNotEmpty)
                Image.network(vehicle.imageUrl, height: 120, width: double.infinity, fit: BoxFit.cover),
              const SizedBox(height: 16),
              Text('Host: ${vehicle.hostName}'),
              Text('Category: ${vehicle.category}'),
              Text('Price/Day: ₹${vehicle.pricePerDay}'),
              Text('Status: ${vehicle.status}'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _updateVehicleStatus(vehicle, 'Active');
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    child: const Text('Approve'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _updateVehicleStatus(vehicle, 'Suspended');
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                    child: const Text('Suspend'),
                  ),
                ],
              )
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search vehicles by title or host',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onSubmitted: _onSearchChanged,
                ),
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: _selectedStatus,
                items: ['All', 'Active', 'Pending', 'Suspended', 'Maintenance'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: _onStatusChanged,
              ),
            ],
          ),
        ),

        // List View
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _vehicles.isEmpty
                  ? const Center(child: Text('No vehicles found.'))
                  : ListView.builder(
                      itemCount: _vehicles.length,
                      itemBuilder: (context, index) {
                        final vehicle = _vehicles[index];
                        return ListTile(
                          leading: vehicle.imageUrl.isNotEmpty
                              ? Image.network(vehicle.imageUrl, width: 60, height: 40, fit: BoxFit.cover)
                              : const Icon(Icons.directions_car),
                          title: Text(vehicle.title),
                          subtitle: Text('${vehicle.category} • Hosted by: ${vehicle.hostName}'),
                          trailing: Chip(
                            label: Text(vehicle.status, style: const TextStyle(fontSize: 12)),
                            backgroundColor: vehicle.status == 'Active' ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                          ),
                          onTap: () => _showVehicleDetails(vehicle),
                        );
                      },
                    ),
        ),

        // Pagination Controls
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _currentPage > 1
                    ? () {
                        _currentPage--;
                        _loadVehicles();
                      }
                    : null,
              ),
              Text('Page $_currentPage'),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _vehicles.length == _limit
                    ? () {
                        _currentPage++;
                        _loadVehicles();
                      }
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
