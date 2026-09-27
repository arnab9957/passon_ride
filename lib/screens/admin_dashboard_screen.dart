import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../models/feedback_model.dart';
import '../providers/app_state.dart';
import '../services/feedback_service.dart';
import '../theme/app_colors.dart';
import '../widgets/admin/admin_overview_tab.dart';
import '../widgets/admin/admin_users_tab.dart';
import '../widgets/admin/admin_hosts_tab.dart';
import '../widgets/admin/admin_vehicles_tab.dart';
import '../widgets/admin/admin_bookings_tab.dart';
import '../widgets/admin/admin_compliance_tab.dart';
import '../widgets/admin/admin_financials_tab.dart';
import '../widgets/admin/admin_telematics_tab.dart';
import '../widgets/admin/admin_feedback_tab.dart';
import '../widgets/admin/admin_tours_tab.dart';
import '../widgets/admin/admin_broadcast_dialog.dart';

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
  List<ComplianceDocument> _complianceDocs = [];
  List<PaymentTransaction> _transactions = [];
  List<AppFeedbackReview> _feedbacks = [];
  List<Tour> _tours = [];

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    setState(() => _isLoading = true);
    final appState = Provider.of<AppState>(context, listen: false);

    try {
      final results = await Future.wait([
        appState.supabaseService.fetchAllProfiles(),
        appState.supabaseService.fetchAllHostProfiles(),
        appState.supabaseService.getVehicles(),
        appState.supabaseService.fetchAllBookings(),
        appState.supabaseService.fetchAllComplianceDocuments(),
        appState.supabaseService.getPaymentTransactions(),
        FeedbackService().getPublicAppFeedbackReviews(),
        appState.supabaseService.getTours(),
      ]);

      if (!mounted) return;

      setState(() {
        _users = results[0] as List<UserProfile>;
        _hosts = results[1] as List<HostProfile>;
        _vehicles = results[2] as List<Vehicle>;
        _bookings = results[3] as List<Booking>;
        _complianceDocs = results[4] as List<ComplianceDocument>;
        _transactions = results[5] as List<PaymentTransaction>;
        _feedbacks = results[6] as List<AppFeedbackReview>;
        _tours = results[7] as List<Tour>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Data sync warning: $e'), backgroundColor: Colors.orange),
      );
    }
  }

  // ==========================================
  // USER ACTIONS
  // ==========================================

  Future<void> _toggleUserBan(UserProfile user) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final newStatus = !user.isBanned;
    await appState.supabaseService.updateUserBannedStatus(user.uid, newStatus);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(newStatus ? 'User "${user.displayName}" blocked.' : 'User unblocked.'),
      backgroundColor: newStatus ? Colors.red : Colors.green,
    ));
    _loadAdminData();
  }

  Future<void> _changeUserRole(UserProfile user, String newRole) async {
    final appState = Provider.of<AppState>(context, listen: false);
    await appState.supabaseService.updateUserRole(user.uid, newRole);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Updated "${user.displayName}" role to $newRole.'),
      backgroundColor: Colors.blue,
    ));
    _loadAdminData();
  }

  Future<void> _updateTrustScore(UserProfile user, double newScore) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final trustScoreObj = TrustScore(
      userId: user.uid,
      trustScore: newScore,
      trustBadges: ['Verified Identity', 'Admin Verified'],
      telematicsScore: newScore,
      cancellationRate: 0.0,
    );
    await appState.supabaseService.saveTrustScore(trustScoreObj);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Updated "${user.displayName}" Kinetic Trust Score to ${newScore.toStringAsFixed(1)}.'),
      backgroundColor: Colors.teal,
    ));
    _loadAdminData();
  }

  // ==========================================
  // HOST ACTIONS
  // ==========================================

  Future<void> _verifyHost(HostProfile host, bool verify) async {
    final appState = Provider.of<AppState>(context, listen: false);
    await appState.supabaseService.verifyHostProfile(host.id, verify);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(verify ? 'Host "${host.businessName.isNotEmpty ? host.businessName : host.displayName}" approved.' : 'Host status revoked.'),
      backgroundColor: verify ? Colors.green : Colors.red,
    ));
    _loadAdminData();
  }

  Future<void> _rejectHostWithReason(HostProfile host, String reason) async {
    final appState = Provider.of<AppState>(context, listen: false);
    await appState.supabaseService.updateProviderVerificationStatus(
      host.userId,
      status: 'rejected',
      isVerified: false,
      notes: reason,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Host rejected: $reason'),
      backgroundColor: Colors.red,
    ));
    _loadAdminData();
  }

  // ==========================================
  // VEHICLE & FLEET ACTIONS
  // ==========================================

  Future<void> _updateVehicleStatus(Vehicle vehicle, String newStatus) async {
    final appState = Provider.of<AppState>(context, listen: false);
    await appState.supabaseService.updateVehicleStatus(vehicle.id, newStatus);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Vehicle "${vehicle.title}" status updated to $newStatus.'),
      backgroundColor: Colors.indigo,
    ));
    _loadAdminData();
  }

  Future<void> _deleteVehicle(Vehicle vehicle) async {
    final appState = Provider.of<AppState>(context, listen: false);
    await appState.supabaseService.deleteVehicle(vehicle.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Vehicle "${vehicle.title}" removed from platform.'),
      backgroundColor: Colors.red,
    ));
    _loadAdminData();
  }

  Future<void> _toggleEngineLock(Vehicle vehicle, bool lock) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final updatedIot = Map<String, dynamic>.from(vehicle.iotData);
    updatedIot['locked'] = lock;
    updatedIot['engineOn'] = !lock;
    await appState.supabaseService.updateVehicleIoTData(vehicle.id, updatedIot);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(lock ? 'Remote Engine Cutoff engaged on "${vehicle.title}".' : 'Engine restored on "${vehicle.title}".'),
      backgroundColor: lock ? Colors.red : Colors.green,
    ));
    _loadAdminData();
  }

  // ==========================================
  // BOOKING ACTIONS
  // ==========================================

  Future<void> _updateBookingStatus(Booking booking, String newStatus) async {
    final appState = Provider.of<AppState>(context, listen: false);
    await appState.supabaseService.updateBookingStatus(booking.id, newStatus);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Booking #${booking.id.substring(0, 8)} marked as $newStatus.'),
      backgroundColor: Colors.blue,
    ));
    _loadAdminData();
  }

  // ==========================================
  // COMPLIANCE ACTIONS
  // ==========================================

  Future<void> _updateComplianceDocStatus(ComplianceDocument doc, String newStatus) async {
    final appState = Provider.of<AppState>(context, listen: false);
    await appState.supabaseService.updateComplianceDocumentStatus(doc.id, newStatus);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Document "${doc.title}" marked as $newStatus.'),
      backgroundColor: newStatus == 'Verified' ? Colors.green : Colors.orange,
    ));
    _loadAdminData();
  }

  // ==========================================
  // TOUR ACTIONS
  // ==========================================

  Future<void> _deleteTour(Tour tour) async {
    final appState = Provider.of<AppState>(context, listen: false);
    await appState.supabaseService.deleteTour(tour.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Tour "${tour.title}" deleted.'),
      backgroundColor: Colors.red,
    ));
    _loadAdminData();
  }

  // ==========================================
  // BROADCAST ANNOUNCEMENT
  // ==========================================

  Future<void> _broadcastNotification(String title, String message, String audience, String type) async {
    final appState = Provider.of<AppState>(context, listen: false);

    // Broadcast notification to active users
    final recipients = audience == 'Riders Only'
        ? _users.where((u) => u.role.toLowerCase() == 'rider')
        : (audience == 'Hosts Only'
            ? _users.where((u) => u.role.toLowerCase() == 'host')
            : _users);

    for (final user in recipients.take(100)) {
      final notif = AppNotification(
        id: 'notif_${DateTime.now().millisecondsSinceEpoch}_${user.uid.substring(0, user.uid.length > 5 ? 5 : user.uid.length)}',
        userId: user.uid,
        title: title,
        message: message,
        type: NotificationType.general,
      );
      await appState.supabaseService.saveNotification(notif);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Broadcast "$title" dispatched to $audience.'),
      backgroundColor: Colors.green,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 950;

    // Badges calculation
    final int pendingHosts = _hosts.where((h) => !h.isVerified && h.verificationStatus.toLowerCase() == 'pending').length;
    final int pendingDocs = _complianceDocs.where((d) => d.status.toLowerCase() == 'pending').length;
    final int activeTrips = _bookings.where((b) => b.status.toLowerCase() == 'active').length;
    final int bugReports = _feedbacks.where((f) => f.category == 'bug_report').length;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, size: 24),
            SizedBox(width: 8),
            Text('PassionRide Command Center', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.campaign),
            tooltip: 'Broadcast System Alert',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AdminBroadcastDialog(onBroadcast: _broadcastNotification),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Sync Realtime Operations',
            onPressed: _loadAdminData,
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: isWide ? null : _buildMobileDrawer(pendingHosts, pendingDocs, activeTrips, bugReports),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Synchronizing Platform Operations & Fleet Telemetry...', style: TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
            )
          : isWide
              ? Row(
                  children: [
                    _buildNavigationRail(pendingHosts, pendingDocs, activeTrips, bugReports),
                    const VerticalDivider(thickness: 1, width: 1),
                    Expanded(child: _buildBody(isDark)),
                  ],
                )
              : _buildBody(isDark),
    );
  }

  Widget _buildNavigationRail(int pendingHosts, int pendingDocs, int activeTrips, int bugReports) {
    return NavigationRail(
      selectedIndex: _currentIndex,
      onDestinationSelected: (int index) => setState(() => _currentIndex = index),
      labelType: NavigationRailLabelType.all,
      minWidth: 90,
      destinations: [
        const NavigationRailDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: Text('Overview'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.people_alt_outlined),
          selectedIcon: Icon(Icons.people_alt),
          label: Text('Users'),
        ),
        NavigationRailDestination(
          icon: _buildIconWithBadge(Icons.storefront_outlined, pendingHosts),
          selectedIcon: _buildIconWithBadge(Icons.storefront, pendingHosts),
          label: const Text('Partners'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.directions_car_outlined),
          selectedIcon: Icon(Icons.directions_car),
          label: Text('Fleet'),
        ),
        NavigationRailDestination(
          icon: _buildIconWithBadge(Icons.receipt_long_outlined, activeTrips, color: Colors.green),
          selectedIcon: _buildIconWithBadge(Icons.receipt_long, activeTrips, color: Colors.green),
          label: const Text('Bookings'),
        ),
        NavigationRailDestination(
          icon: _buildIconWithBadge(Icons.badge_outlined, pendingDocs, color: Colors.deepOrange),
          selectedIcon: _buildIconWithBadge(Icons.badge, pendingDocs, color: Colors.deepOrange),
          label: const Text('Compliance'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.account_balance_wallet_outlined),
          selectedIcon: Icon(Icons.account_balance_wallet),
          label: Text('Financials'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.sensors),
          selectedIcon: Icon(Icons.cell_tower),
          label: Text('Telematics'),
        ),
        NavigationRailDestination(
          icon: _buildIconWithBadge(Icons.rate_review_outlined, bugReports, color: Colors.red),
          selectedIcon: _buildIconWithBadge(Icons.rate_review, bugReports, color: Colors.red),
          label: const Text('Feedback'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.tour_outlined),
          selectedIcon: Icon(Icons.tour),
          label: Text('Tours'),
        ),
      ],
    );
  }

  Widget _buildIconWithBadge(IconData icon, int count, {Color color = Colors.orange}) {
    if (count <= 0) return Icon(icon);
    return Badge(
      label: Text('$count'),
      backgroundColor: color,
      child: Icon(icon),
    );
  }

  Widget _buildMobileDrawer(int pendingHosts, int pendingDocs, int activeTrips, int bugReports) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.admin_panel_settings, size: 36, color: Colors.white),
                const SizedBox(height: 8),
                const Text('Mission Control', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text('${_users.length} Users • ${_vehicles.length} Vehicles', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          _buildDrawerItem(0, 'Mission Overview', Icons.dashboard_outlined),
          _buildDrawerItem(1, 'User Accounts & Roles', Icons.people_alt_outlined),
          _buildDrawerItem(2, 'Partner Verifications', Icons.storefront_outlined, badgeCount: pendingHosts),
          _buildDrawerItem(3, 'Fleet & Inventory', Icons.directions_car_outlined),
          _buildDrawerItem(4, 'Bookings & Dispatch', Icons.receipt_long_outlined, badgeCount: activeTrips),
          _buildDrawerItem(5, 'Document Compliance', Icons.badge_outlined, badgeCount: pendingDocs),
          _buildDrawerItem(6, 'Financials & Escrow Ledger', Icons.account_balance_wallet_outlined),
          _buildDrawerItem(7, 'Telematics & Remote Lock', Icons.cell_tower),
          _buildDrawerItem(8, 'Feedback & AI Sentiment', Icons.rate_review_outlined, badgeCount: bugReports),
          _buildDrawerItem(9, 'Tours & Experiences', Icons.tour_outlined),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(int index, String title, IconData icon, {int badgeCount = 0}) {
    final isSelected = _currentIndex == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppColors.primary : null),
      title: Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      trailing: badgeCount > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
              child: Text('$badgeCount', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            )
          : null,
      selected: isSelected,
      onTap: () {
        Navigator.pop(context);
        setState(() => _currentIndex = index);
      },
    );
  }

  Widget _buildBody(bool isDark) {
    switch (_currentIndex) {
      case 0:
        return AdminOverviewTab(
          users: _users,
          hosts: _hosts,
          vehicles: _vehicles,
          bookings: _bookings,
          complianceDocs: _complianceDocs,
          transactions: _transactions,
          feedbacks: _feedbacks,
          tours: _tours,
          onNavigateTab: (target) => setState(() => _currentIndex = target),
          onRefresh: _loadAdminData,
        );
      case 1:
        return AdminUsersTab(
          users: _users,
          onToggleBan: _toggleUserBan,
          onChangeRole: _changeUserRole,
          onUpdateTrustScore: _updateTrustScore,
        );
      case 2:
        return AdminHostsTab(
          hosts: _hosts,
          onVerifyHost: _verifyHost,
          onRejectHostWithReason: _rejectHostWithReason,
        );
      case 3:
        return AdminVehiclesTab(
          vehicles: _vehicles,
          onUpdateStatus: _updateVehicleStatus,
          onDeleteVehicle: _deleteVehicle,
          onToggleEngineLock: _toggleEngineLock,
        );
      case 4:
        return AdminBookingsTab(
          bookings: _bookings,
          onUpdateStatus: _updateBookingStatus,
        );
      case 5:
        return AdminComplianceTab(
          documents: _complianceDocs,
          onUpdateDocumentStatus: _updateComplianceDocStatus,
        );
      case 6:
        return AdminFinancialsTab(
          transactions: _transactions,
        );
      case 7:
        return AdminTelematicsTab(
          vehicles: _vehicles,
          onToggleEngineLock: _toggleEngineLock,
        );
      case 8:
        return AdminFeedbackTab(
          feedbacks: _feedbacks,
        );
      case 9:
        return AdminToursTab(
          tours: _tours,
          onDeleteTour: _deleteTour,
        );
      default:
        return const Center(child: Text('Unknown Module'));
    }
  }
}
