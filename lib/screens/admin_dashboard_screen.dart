import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import 'package:intl/intl.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;
  bool _isLoading = true;

  List<UserProfile> _users = [];
  List<HostProfile> _hosts = [];
  List<Vehicle> _vehicles = [];
  List<Booking> _bookings = [];

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    setState(() => _isLoading = true);
    final appState = Provider.of<AppState>(context, listen: false);
    
    // Run all fetches in parallel
    final results = await Future.wait([
      appState.supabaseService.fetchAllProfiles(),
      appState.supabaseService.fetchAllHostProfiles(),
      appState.supabaseService.getVehicles(), // Assuming getVehicles is admin-capable via RLS
      appState.supabaseService.fetchAllBookings(),
    ]);

    setState(() {
      _users = results[0] as List<UserProfile>;
      _hosts = results[1] as List<HostProfile>;
      _vehicles = results[2] as List<Vehicle>;
      _bookings = results[3] as List<Booking>;
      _isLoading = false;
    });
  }

  Future<void> _toggleUserBan(UserProfile user) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final newStatus = !user.isBanned;
    await appState.supabaseService.updateUserBannedStatus(user.uid, newStatus);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(newStatus ? 'User ${user.displayName} blocked.' : 'User unblocked.'),
      backgroundColor: newStatus ? Colors.red : Colors.green,
    ));
    _loadAdminData();
  }

  Future<void> _verifyHost(HostProfile host, bool verify) async {
    final appState = Provider.of<AppState>(context, listen: false);
    await appState.supabaseService.verifyHostProfile(host.id, verify);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(verify ? 'Host ${host.businessName} verified.' : 'Host rejected.'),
    ));
    _loadAdminData();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAdminData,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                NavigationRail(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (int index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  labelType: NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.group_outlined),
                      selectedIcon: Icon(Icons.group),
                      label: Text('Users'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.storefront_outlined),
                      selectedIcon: Icon(Icons.storefront),
                      label: Text('Verifications'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.directions_car_outlined),
                      selectedIcon: Icon(Icons.directions_car),
                      label: Text('Vehicles'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.receipt_long_outlined),
                      selectedIcon: Icon(Icons.receipt_long),
                      label: Text('Bookings'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(
                  child: _buildBody(isDark),
                ),
              ],
            ),
    );
  }

  Widget _buildBody(bool isDark) {
    switch (_currentIndex) {
      case 0:
        return _buildUsersTab();
      case 1:
        return _buildHostsTab();
      case 2:
        return _buildVehiclesTab();
      case 3:
        return _buildBookingsTab();
      default:
        return const Center(child: Text('Unknown Tab'));
    }
  }

  Widget _buildUsersTab() {
    return ListView.builder(
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
            child: user.photoUrl.isEmpty ? const Icon(Icons.person) : null,
          ),
          title: Text(user.displayName),
          subtitle: Text('${user.email} • Role: ${user.role}'),
          trailing: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: user.isBanned ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => _toggleUserBan(user),
            child: Text(user.isBanned ? 'Unblock' : 'Block'),
          ),
        );
      },
    );
  }

  Widget _buildHostsTab() {
    return ListView.builder(
      itemCount: _hosts.length,
      itemBuilder: (context, index) {
        final host = _hosts[index];
        final isVerified = host.isVerified;
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: isVerified ? Colors.green.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
            foregroundColor: isVerified ? Colors.green : Colors.orange,
            child: Icon(isVerified ? Icons.verified : Icons.pending),
          ),
          title: Text(host.businessName.isNotEmpty ? host.businessName : host.displayName),
          subtitle: Text('Status: ${host.verificationStatus.toUpperCase()} • ID: ${host.governmentIdType}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isVerified)
                TextButton(
                  onPressed: () => _verifyHost(host, true),
                  child: const Text('Approve', style: TextStyle(color: Colors.green)),
                ),
              if (isVerified)
                TextButton(
                  onPressed: () => _verifyHost(host, false),
                  child: const Text('Revoke', style: TextStyle(color: Colors.red)),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVehiclesTab() {
    return ListView.builder(
      itemCount: _vehicles.length,
      itemBuilder: (context, index) {
        final vehicle = _vehicles[index];
        return ListTile(
          leading: vehicle.imageUrl.isNotEmpty
              ? Image.network(vehicle.imageUrl, width: 60, height: 40, fit: BoxFit.cover)
              : const Icon(Icons.directions_car),
          title: Text(vehicle.title),
          subtitle: Text('${vehicle.category} • Hosted by: ${vehicle.hostName}'),
          trailing: Chip(label: Text(vehicle.status)),
        );
      },
    );
  }

  Widget _buildBookingsTab() {
    return ListView.builder(
      itemCount: _bookings.length,
      itemBuilder: (context, index) {
        final booking = _bookings[index];
        return ListTile(
          leading: const Icon(Icons.book_online),
          title: Text('Booking #${booking.id.substring(0, 8)}'),
          subtitle: Text('${booking.status} • Total: ₹${booking.totalPrice.toStringAsFixed(2)}'),
          trailing: Text(
            DateFormat('MMM dd, yyyy').format(booking.createdAt),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        );
      },
    );
  }
}
