// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/supabase_auth_dialog.dart';

import 'home_screen.dart';
import '../i18n/strings.g.dart';
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
import 'in_app_web_view_screen.dart';
import 'location_screen.dart';
import 'my_bookings_screen.dart';

import '../widgets/auth_guard_widget.dart';
import '../widgets/location_prompt_dialog.dart';
import '../widgets/notification_center_modal.dart';
import '../widgets/movable_chatbot_button.dart';
import '../widgets/global_feedback_fab.dart';
import '../irsargo/irsargo_api.dart';
import '../irsargo/chatbot.dart';
import '../irsargo/context_collector.dart';

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
    const InAppWebViewScreen(), // 17
    const LocationScreen(), // 18
    const AuthGuardWidget(
      taskName: 'view active bookings and upcoming rental requests',
      icon: Icons.calendar_month_outlined,
      child: MyBookingsScreen(),
    ), // 19
    InAppWebViewScreen(
      initialUrl: kIsWeb ? '${Uri.base.origin}/technical_documentation.html' : 'https://PassionRide.com',
      title: 'Technical Documentation',
    ), // 20
  ];

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 800;

    // When a user is logged in, automatically ask their address or GPS location access if not prompted yet
    if (appState.isLoggedIn && !appState.hasPromptedLocationOnLogin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted && !appState.hasPromptedLocationOnLogin) {
          LocationPromptDialog.show(context);
        }
      });
    }

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
          // Message Inbox Header Icon Button
          IconButton(
            tooltip: 'Message Inbox',
            icon: const Icon(Icons.mail_outline, size: 21),
            onPressed: () => appState.setNavIndex(6),
          ),
          // Quick Location Selector Button
          IconButton(
            tooltip: 'Rental Location (${appState.isLiveLocationActive ? "Live GPS" : "Manual"})',
            icon: Icon(
              appState.isLiveLocationActive ? Icons.my_location : Icons.location_on,
              color: appState.isLiveLocationActive ? AppColors.secondary : AppColors.primary,
              size: 20,
            ),
            onPressed: () => showLocationPickerModal(context),
          ),
          // Quick Module Switcher Popup Menu
          PopupMenuButton<int>(
            icon: const Icon(Icons.grid_view_rounded),
            tooltip: 'Feature Modules',
            onSelected: (idx) => appState.setNavIndex(idx),
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 7, child: Text('1. My Favorites')),
              const PopupMenuItem(value: 9, child: Text('2. Earnings & Financials')),
              const PopupMenuItem(value: 12, child: Text('3. AI Tour Generator')),
              const PopupMenuItem(value: 14, child: Text('4. Documents & Compliance')),
              const PopupMenuItem(value: 15, child: Text('5. Kinetic Trust Score')),
              const PopupMenuItem(value: 20, child: Text('6. Technical Documentation')),
            ],
          ),
          // Supabase Auth Controls
          if (!appState.isSignedIn) ...[
            if (screenWidth >= 360)
              ElevatedButton.icon(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => const SupabaseAuthDialog(),
                ),
                icon: const Icon(Icons.lock_outline, size: 16, color: Colors.white),
                label: Text(isDesktop ? 'Sign In / Register' : 'Sign In', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              )
            else
              IconButton(
                tooltip: 'Sign In',
                icon: const Icon(Icons.lock_outline, color: AppColors.primary),
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => const SupabaseAuthDialog(),
                ),
              ),
            const SizedBox(width: 4),
          ] else ...[
            PopupMenuButton<String>(
              onSelected: (val) async {
                if (val == 'signout') {
                  await appState.signOut();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Supabase Auth Signed Out')),
                    );
                  }
                } else if (val == 'profile') {
                  appState.setNavIndex(16);
                }
              },
              icon: CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary,
                backgroundImage: appState.activeUserPhotoUrl.isNotEmpty
                    ? NetworkImage(appState.imageKitService.buildImageUrl(appState.activeUserPhotoUrl))
                    : null,
                onBackgroundImageError: appState.activeUserPhotoUrl.isNotEmpty
                    ? (exception, stackTrace) {
                        debugPrint('Nav avatar image load notice: $exception');
                      }
                    : null,
                child: appState.activeUserPhotoUrl.isEmpty
                    ? Text(
                        appState.activeUserDisplayName.isNotEmpty ? appState.activeUserDisplayName[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              tooltip: 'Supabase User (${appState.activeUserEmail})',
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  enabled: false,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.primary,
                        backgroundImage: appState.activeUserPhotoUrl.isNotEmpty
                            ? NetworkImage(appState.imageKitService.buildImageUrl(appState.activeUserPhotoUrl))
                            : null,
                        onBackgroundImageError: appState.activeUserPhotoUrl.isNotEmpty
                            ? (exception, stackTrace) {
                                debugPrint('Nav popup avatar image load notice: $exception');
                              }
                            : null,
                        child: appState.activeUserPhotoUrl.isEmpty
                            ? Text(
                                appState.activeUserDisplayName.isNotEmpty ? appState.activeUserDisplayName[0].toUpperCase() : '?',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              )
                            : null,
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
                      Text('User Profile'),
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
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => showNotificationCenterModal(context),
                tooltip: 'Notifications',
              ),
              if (appState.unreadNotificationCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.redAccent.withOpacity(0.5),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        appState.unreadNotificationCount > 99 ? '99+' : '${appState.unreadNotificationCount}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Row(
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
                        NavigationRailDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: Text('Bookings')),
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

          // Movable / Draggable Custom Chatbot Button
          MovableChatbotButton(
            onTap: () {
              final liveUiContext = IrsargoContextCollector.collectPublicAppContext(appState);

              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (ctx) => IrsargoChatbotWidget(
                  api: IrsargoApi(),
                  uiContext: liveUiContext,
                ),
              );
            },
          ),

          // Global App-Wide Movable Feedback Trigger Button
          const GlobalFeedbackFab(),
        ],
      ),

      // Mobile Bottom Navigation Bar
      bottomNavigationBar: !isDesktop
          ? BottomNavigationBar(
              currentIndex: _getMobileBottomIndex(appState.currentNavIndex),
              onTap: (idx) {
                if (idx == 0) appState.setNavIndex(0); // Home
                if (idx == 1) appState.setNavIndex(1); // Discovery / Search
                if (idx == 2) appState.setNavIndex(8); // Host Section (Bright Blue Circle Plus)
                if (idx == 3) appState.setNavIndex(19); // My Bookings & Requests
                if (idx == 4) appState.setNavIndex(16); // Profile
              },
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: Colors.grey,
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.home_outlined),
                  activeIcon: const Icon(Icons.home),
                  label: t.nav.home,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.search_outlined),
                  activeIcon: const Icon(Icons.search),
                  label: t.common.search,
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0284C7), // Bright Blue Circle
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x550284C7),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 20),
                  ),
                  activeIcon: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0284C7), // Bright Blue Circle
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xAA0284C7),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 20),
                  ),
                  label: t.nav.provider,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.calendar_month_outlined),
                  activeIcon: const Icon(Icons.calendar_month),
                  label: t.nav.rides,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.person_outline),
                  activeIcon: const Icon(Icons.person),
                  label: t.nav.profile,
                ),
              ],
            )
          : null,
    );
  }

  int _getMobileBottomIndex(int navIndex) {
    if (navIndex == 0) return 0;
    if (navIndex == 1 || navIndex == 2 || navIndex == 3 || navIndex == 4) return 1;
    if (navIndex == 8 || navIndex == 9 || navIndex == 10 || navIndex == 11) return 2;
    if (navIndex == 19) return 3;
    if (navIndex == 16 || navIndex == 14 || navIndex == 15) return 4;
    return 0;
  }
}
