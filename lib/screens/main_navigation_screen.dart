import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/firebase_auth_dialog.dart';

import 'home_screen.dart';
import 'discovery_screen.dart';
import 'vehicle_detail_screen.dart';
import 'booking_verification_screen.dart';
import 'payment_checkout_screen.dart';
import 'chat_screen.dart';
import 'message_list_screen.dart';
import 'favorites_screen.dart';
import 'provider_dashboard_screen.dart';
import 'earnings_screen.dart';
import 'register_vehicle_screen.dart';
import 'register_tour_screen.dart';
import 'ai_tour_generator_screen.dart';
import 'telematics_hub_screen.dart';
import 'documents_compliance_screen.dart';
import 'kinetic_trust_screen.dart';
import 'profile_screen.dart';

import '../widgets/auth_guard_widget.dart';

class MainNavigationScreen extends StatelessWidget {
  const MainNavigationScreen({super.key});

  static final List<Widget> _screens = [
    const HomeScreen(), // 0
    const DiscoveryScreen(), // 1
    const VehicleDetailScreen(), // 2
    const AuthGuardWidget(
      taskName: 'verify vehicle reservations & keyless unlock PINs',
      icon: Icons.verified_outlined,
      child: BookingVerificationScreen(),
    ), // 3
    const AuthGuardWidget(
      taskName: 'complete rental booking checkout & payments',
      icon: Icons.payment_outlined,
      child: PaymentCheckoutScreen(),
    ), // 4
    const AuthGuardWidget(
      taskName: 'chat live with hosts & riders',
      icon: Icons.chat_bubble_outline,
      child: ChatScreen(),
    ), // 5
    const AuthGuardWidget(
      taskName: 'access your message inbox',
      icon: Icons.mail_outline,
      child: MessageListScreen(),
    ), // 6
    const AuthGuardWidget(
      taskName: 'save and view favorite listings',
      icon: Icons.favorite_outline,
      child: FavoritesScreen(),
    ), // 7
    const AuthGuardWidget(
      taskName: 'access host fleet dashboard',
      icon: Icons.dashboard_outlined,
      child: ProviderDashboardScreen(),
    ), // 8
    const AuthGuardWidget(
      taskName: 'view provider financial earnings & payouts',
      icon: Icons.account_balance_wallet_outlined,
      child: EarningsScreen(),
    ), // 9
    const AuthGuardWidget(
      taskName: 'register and host vehicles for rental',
      icon: Icons.directions_car_outlined,
      child: RegisterVehicleScreen(),
    ), // 10
    const AuthGuardWidget(
      taskName: 'register and publish guided group tours',
      icon: Icons.tour_outlined,
      child: RegisterTourScreen(),
    ), // 11
    const AuthGuardWidget(
      taskName: 'generate AI guided itineraries',
      icon: Icons.auto_awesome_outlined,
      child: AiTourGeneratorScreen(),
    ), // 12
    const AuthGuardWidget(
      taskName: 'use IoT remote controls & vehicle telematics hub',
      icon: Icons.sensors_outlined,
      child: TelematicsHubScreen(),
    ), // 13
    const AuthGuardWidget(
      taskName: 'upload identity & compliance documents',
      icon: Icons.description_outlined,
      child: DocumentsComplianceScreen(),
    ), // 14
    const AuthGuardWidget(
      taskName: 'view kinetic trust reputation & badges',
      icon: Icons.shield_outlined,
      child: KineticTrustScreen(),
    ), // 15
    const ProfileScreen(), // 16
  ];

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 800;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.directions_bike, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Passon',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.primary,
                        ),
                      ),
                      TextSpan(
                        text: 'Ride',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.secondaryFixedDim : AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          // Quick Module Switcher Popup Menu
          PopupMenuButton<int>(
            icon: const Icon(Icons.grid_view_rounded),
            tooltip: 'All 17 Feature Modules',
            onSelected: (idx) => appState.setNavIndex(idx),
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 0, child: Text('1. Nexus Home Page')),
              const PopupMenuItem(value: 1, child: Text('2. Vehicle Discovery')),
              const PopupMenuItem(value: 2, child: Text('3. Vehicle Details')),
              const PopupMenuItem(value: 3, child: Text('4. Booking Verification')),
              const PopupMenuItem(value: 4, child: Text('5. Payment Checkout')),
              const PopupMenuItem(value: 5, child: Text('6. Chat with Provider')),
              const PopupMenuItem(value: 6, child: Text('7. Message Inbox')),
              const PopupMenuItem(value: 7, child: Text('8. My Favorites')),
              const PopupMenuItem(value: 8, child: Text('9. Host Dashboard')),
              const PopupMenuItem(value: 9, child: Text('10. Earnings & Financials')),
              const PopupMenuItem(value: 10, child: Text('11. Register Vehicle')),
              const PopupMenuItem(value: 11, child: Text('12. Register Tour')),
              const PopupMenuItem(value: 12, child: Text('13. AI Tour Generator')),
              const PopupMenuItem(value: 13, child: Text('14. IoT Telematics Hub')),
              const PopupMenuItem(value: 14, child: Text('15. Documents & Compliance')),
              const PopupMenuItem(value: 15, child: Text('16. Kinetic Trust Score')),
              const PopupMenuItem(value: 16, child: Text('17. User Profile')),
            ],
          ),
          // Firebase Auth Controls
          if (!appState.isSignedIn) ...[
            ElevatedButton.icon(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const FirebaseAuthDialog(),
              ),
              icon: const Icon(Icons.local_fire_department, size: 16, color: Colors.white),
              label: Text(isDesktop ? 'Sign In / Register' : 'Sign In', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(width: 8),
          ] else ...[
            PopupMenuButton<String>(
              onSelected: (val) async {
                if (val == 'signout') {
                  await appState.signOut();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Firebase Auth Logged Out')),
                    );
                  }
                } else if (val == 'profile') {
                  appState.setNavIndex(16);
                }
              },
              icon: const CircleAvatar(
                radius: 16,
                backgroundColor: Colors.deepOrange,
                child: Icon(Icons.local_fire_department, color: Colors.white, size: 18),
              ),
              tooltip: 'Firebase User (${appState.activeUserEmail})',
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  enabled: false,
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.deepOrange,
                        child: Icon(Icons.local_fire_department, color: Colors.white, size: 14),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(appState.activeUserDisplayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(appState.activeUserEmail, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person_outline, size: 18),
                      SizedBox(width: 8),
                      Text('Firebase Profile'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'signout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.redAccent, size: 18),
                      SizedBox(width: 8),
                      Text('Sign Out', style: TextStyle(color: Colors.redAccent)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
          ],
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => appState.toggleTheme(),
            tooltip: 'Toggle Theme',
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          // Desktop Navigation Sidebar
          if (isDesktop)
            SingleChildScrollView(
              child: IntrinsicHeight(
                child: NavigationRail(
                  selectedIndex: appState.currentNavIndex > 16 ? 0 : appState.currentNavIndex,
                  onDestinationSelected: (idx) => appState.setNavIndex(idx),
                  labelType: NavigationRailLabelType.selected,
                  backgroundColor: isDark ? AppColors.surfaceContainerLowDark : AppColors.surfaceContainerLow,
                  selectedIconTheme: const IconThemeData(color: AppColors.primary),
                  unselectedIconTheme: const IconThemeData(color: Colors.grey),
                  destinations: const [
                    NavigationRailDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: Text('Home')),
                    NavigationRailDestination(icon: Icon(Icons.search_outlined), selectedIcon: Icon(Icons.search), label: Text('Search')),
                    NavigationRailDestination(icon: Icon(Icons.directions_car_outlined), selectedIcon: Icon(Icons.directions_car), label: Text('Details')),
                    NavigationRailDestination(icon: Icon(Icons.verified_outlined), selectedIcon: Icon(Icons.verified), label: Text('Verify')),
                    NavigationRailDestination(icon: Icon(Icons.payment_outlined), selectedIcon: Icon(Icons.payment), label: Text('Pay')),
                    NavigationRailDestination(icon: Icon(Icons.chat_outlined), selectedIcon: Icon(Icons.chat), label: Text('Chat')),
                    NavigationRailDestination(icon: Icon(Icons.inbox_outlined), selectedIcon: Icon(Icons.inbox), label: Text('Inbox')),
                    NavigationRailDestination(icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite), label: Text('Saved')),
                    NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Host')),
                    NavigationRailDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: Text('Earnings')),
                    NavigationRailDestination(icon: Icon(Icons.add_circle_outline), selectedIcon: Icon(Icons.add_circle), label: Text('+Vehicle')),
                    NavigationRailDestination(icon: Icon(Icons.add_location_alt_outlined), selectedIcon: Icon(Icons.add_location_alt), label: Text('+Tour')),
                    NavigationRailDestination(icon: Icon(Icons.auto_awesome_outlined), selectedIcon: Icon(Icons.auto_awesome), label: Text('AI Tour')),
                    NavigationRailDestination(icon: Icon(Icons.sensors), selectedIcon: Icon(Icons.sensors), label: Text('IoT Hub')),
                    NavigationRailDestination(icon: Icon(Icons.badge_outlined), selectedIcon: Icon(Icons.badge), label: Text('Docs')),
                    NavigationRailDestination(icon: Icon(Icons.shield_outlined), selectedIcon: Icon(Icons.shield), label: Text('Trust')),
                    NavigationRailDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: Text('Profile')),
                  ],
                ),
              ),
            ),

          // Main Active Screen Canvas
          Expanded(
            child: _screens[appState.currentNavIndex < _screens.length ? appState.currentNavIndex : 0],
          ),
        ],
      ),

      // Mobile Bottom Navigation Bar
      bottomNavigationBar: !isDesktop
          ? BottomNavigationBar(
              currentIndex: _getMobileBottomIndex(appState.currentNavIndex),
              onTap: (idx) {
                if (idx == 0) appState.setNavIndex(0); // Home
                if (idx == 1) appState.setNavIndex(1); // Discovery
                if (idx == 2) appState.setNavIndex(13); // IoT Telematics Hub
                if (idx == 3) appState.setNavIndex(8); // Host Dashboard
                if (idx == 4) appState.setNavIndex(16); // Profile
              },
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: Colors.grey,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(icon: Icon(Icons.search_outlined), activeIcon: Icon(Icons.search), label: 'Search'),
                BottomNavigationBarItem(icon: Icon(Icons.sensors), activeIcon: Icon(Icons.sensors), label: 'IoT Hub'),
                BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Host'),
                BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
              ],
            )
          : null,
    );
  }

  int _getMobileBottomIndex(int navIndex) {
    if (navIndex == 0) return 0;
    if (navIndex == 1 || navIndex == 2 || navIndex == 3 || navIndex == 4) return 1;
    if (navIndex == 13) return 2;
    if (navIndex == 8 || navIndex == 9 || navIndex == 10 || navIndex == 11) return 3;
    if (navIndex == 16 || navIndex == 14 || navIndex == 15) return 4;
    return 0;
  }
}
