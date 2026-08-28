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
import 'technical_documentation_screen.dart';
import 'location_screen.dart';
import 'my_bookings_screen.dart';
import 'blog_screen.dart';

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
    const TechnicalDocumentationScreen(), // 20
    const BlogScreen(), // 21
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
              const PopupMenuItem(value: 21, child: Text('7. Blog & Social Hub')),
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
                _buildDesktopSidebar(context, appState, isDark),

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

  Widget _buildDesktopSidebar(BuildContext context, AppState appState, bool isDark) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceContainerLowDark : Colors.grey.shade50,
        border: Border(
          right: BorderSide(
            color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                _buildSidebarSectionHeader('Customer Space', isDark),
                _buildSidebarTile(
                  icon: Icons.home_outlined,
                  title: 'Home',
                  targetIndex: 0,
                  appState: appState,
                  isDark: isDark,
                ),
                _buildSidebarTile(
                  icon: Icons.search_outlined,
                  title: 'Search Vehicles',
                  targetIndex: 1,
                  appState: appState,
                  isDark: isDark,
                ),
                _buildSidebarTile(
                  icon: Icons.calendar_month_outlined,
                  title: 'My Bookings',
                  targetIndex: 19,
                  appState: appState,
                  isDark: isDark,
                ),
                _buildSidebarTile(
                  icon: Icons.favorite_border,
                  title: 'Saved Favorites',
                  targetIndex: 7,
                  appState: appState,
                  isDark: isDark,
                ),
                _buildSidebarTile(
                  icon: Icons.auto_awesome_outlined,
                  title: 'AI Tour Planner',
                  targetIndex: 12,
                  appState: appState,
                  isDark: isDark,
                ),
                
                _buildSidebarSectionHeader('Messenger', isDark),
                _buildSidebarTile(
                  icon: Icons.mail_outline,
                  title: 'Chat Inbox',
                  targetIndex: 6,
                  appState: appState,
                  isDark: isDark,
                ),

                _buildSidebarSectionHeader('Host Hub', isDark),
                _buildSidebarTile(
                  icon: Icons.dashboard_outlined,
                  title: 'Host Dashboard',
                  targetIndex: 8,
                  appState: appState,
                  isDark: isDark,
                ),
                _buildSidebarTile(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Earnings & Payouts',
                  targetIndex: 9,
                  appState: appState,
                  isDark: isDark,
                ),
                _buildSidebarTile(
                  icon: Icons.add_circle_outline,
                  title: 'Host a Vehicle',
                  targetIndex: 10,
                  appState: appState,
                  isDark: isDark,
                ),
                _buildSidebarTile(
                  icon: Icons.add_location_alt_outlined,
                  title: 'Host a Tour',
                  targetIndex: 11,
                  appState: appState,
                  isDark: isDark,
                ),
                _buildSidebarTile(
                  icon: Icons.sensors_outlined,
                  title: 'IoT Telematics Hub',
                  targetIndex: 13,
                  appState: appState,
                  isDark: isDark,
                ),

                _buildSidebarSectionHeader('Social Hub', isDark),
                _buildSidebarTile(
                  icon: Icons.rss_feed_outlined,
                  title: 'Blog & Social Feed',
                  targetIndex: 21,
                  appState: appState,
                  isDark: isDark,
                ),
                _buildSidebarSectionHeader('Settings & Docs', isDark),
                _buildSidebarTile(
                  icon: Icons.person_outline,
                  title: 'User Profile',
                  targetIndex: 16,
                  appState: appState,
                  isDark: isDark,
                ),
                _buildSidebarTile(
                  icon: Icons.badge_outlined,
                  title: 'Verify Docs & KYC',
                  targetIndex: 14,
                  appState: appState,
                  isDark: isDark,
                ),
                _buildSidebarTile(
                  icon: Icons.shield_outlined,
                  title: 'Trust & Safety Score',
                  targetIndex: 15,
                  appState: appState,
                  isDark: isDark,
                ),
                _buildSidebarTile(
                  icon: Icons.description_outlined,
                  title: 'Technical Docs',
                  targetIndex: 20,
                  appState: appState,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, top: 16, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white38 : Colors.black38,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSidebarTile({
    required IconData icon,
    required String title,
    required int targetIndex,
    required AppState appState,
    required bool isDark,
  }) {
    final isSelected = _isTileSelected(targetIndex, appState.currentNavIndex);
    final activeColor = AppColors.primary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? activeColor.withOpacity(0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => appState.setNavIndex(targetIndex),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? activeColor
                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? activeColor
                        : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                  ),
                ),
              ),
              if (isSelected)
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    color: activeColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isTileSelected(int targetIndex, int currentIndex) {
    if (currentIndex == targetIndex) return true;
    if (targetIndex == 1 && currentIndex == 2) return true; // Details maps to Search
    if (targetIndex == 6 && currentIndex == 5) return true; // Chat maps to Inbox
    if (targetIndex == 19 && (currentIndex == 3 || currentIndex == 4)) return true; // Verify / Pay maps to My Bookings
    return false;
  }
}
