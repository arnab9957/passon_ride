// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'dashboard_overview_screen.dart';
import 'users_management_screen.dart';
import 'vehicles_management_screen.dart';
import 'bookings_management_screen.dart';
import 'financials_screen.dart';
import '../../widgets/exempt_hosts_dialog.dart';

class AdminLayoutScreen extends StatefulWidget {
  const AdminLayoutScreen({super.key});

  @override
  State<AdminLayoutScreen> createState() => _AdminLayoutScreenState();
}

class _AdminLayoutScreenState extends State<AdminLayoutScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardOverviewScreen(),
    const UsersManagementScreen(),
    const VehiclesManagementScreen(),
    const BookingsManagementScreen(),
    const FinancialsScreen(),
  ];

  static const List<NavigationRailDestination> _railDestinations = [
    NavigationRailDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: Text('Overview'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.group_outlined),
      selectedIcon: Icon(Icons.group),
      label: Text('Users'),
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
    NavigationRailDestination(
      icon: Icon(Icons.account_balance_wallet_outlined),
      selectedIcon: Icon(Icons.account_balance_wallet),
      label: Text('Financials'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1100;
    final isTabletOrDesktop = screenWidth >= 720;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.admin_panel_settings, size: 22, color: Colors.white),
            const SizedBox(width: 8),
            const Text(
              'Admin Portal',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red.shade900,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'LIVE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Initial Host Exemption Whitelist',
            icon: const Icon(Icons.verified_user_outlined),
            onPressed: () => ExemptHostsDialog.show(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isTabletOrDesktop
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (int index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  extended: isDesktop,
                  backgroundColor: isDark
                      ? AppColors.surfaceContainerDark
                      : AppColors.surfaceLight,
                  selectedIconTheme: const IconThemeData(color: AppColors.secondary),
                  selectedLabelTextStyle: const TextStyle(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  labelType: isDesktop
                      ? NavigationRailLabelType.none
                      : NavigationRailLabelType.all,
                  destinations: _railDestinations,
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(
                  child: _pages[_currentIndex],
                ),
              ],
            )
          : _pages[_currentIndex],
      bottomNavigationBar: isTabletOrDesktop
          ? null
          : NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (int index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              backgroundColor: isDark
                  ? AppColors.surfaceContainerDark
                  : AppColors.surfaceLight,
              indicatorColor: AppColors.secondary.withOpacity(0.2),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard, color: AppColors.secondary),
                  label: 'Overview',
                ),
                NavigationDestination(
                  icon: Icon(Icons.group_outlined),
                  selectedIcon: Icon(Icons.group, color: AppColors.secondary),
                  label: 'Users',
                ),
                NavigationDestination(
                  icon: Icon(Icons.directions_car_outlined),
                  selectedIcon: Icon(Icons.directions_car, color: AppColors.secondary),
                  label: 'Vehicles',
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long, color: AppColors.secondary),
                  label: 'Bookings',
                ),
                NavigationDestination(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  selectedIcon: Icon(Icons.account_balance_wallet, color: AppColors.secondary),
                  label: 'Financials',
                ),
              ],
            ),
    );
  }
}
