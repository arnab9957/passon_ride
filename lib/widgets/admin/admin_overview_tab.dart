import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../models/feedback_model.dart';
import '../../theme/app_colors.dart';
import 'admin_metric_card.dart';

class AdminOverviewTab extends StatelessWidget {
  final List<UserProfile> users;
  final List<HostProfile> hosts;
  final List<Vehicle> vehicles;
  final List<Booking> bookings;
  final List<ComplianceDocument> complianceDocs;
  final List<PaymentTransaction> transactions;
  final List<AppFeedbackReview> feedbacks;
  final List<Tour> tours;
  final Function(int targetTab) onNavigateTab;
  final VoidCallback onRefresh;

  const AdminOverviewTab({
    super.key,
    required this.users,
    required this.hosts,
    required this.vehicles,
    required this.bookings,
    required this.complianceDocs,
    required this.transactions,
    required this.feedbacks,
    required this.tours,
    required this.onNavigateTab,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    // Calculate aggregated metrics
    final double totalGmv = bookings.fold(0.0, (sum, b) => sum + b.totalPrice);
    final double platformRevenue = totalGmv * 0.15; // 15% platform take-rate
    final int activeBookingsCount = bookings.where((b) {
      final s = b.status.toLowerCase();
      return s == 'active' || s == 'confirmed';
    }).length;

    final int pendingHostsCount = hosts.where((h) => !h.isVerified && h.verificationStatus.toLowerCase() == 'pending').length;
    final int pendingDocsCount = complianceDocs.where((d) => d.status.toLowerCase() == 'pending').length;
    final int availableVehiclesCount = vehicles.where((v) => v.status.toLowerCase() == 'available').length;
    final int maintenanceVehiclesCount = vehicles.where((v) => v.status.toLowerCase() == 'maintenance').length;
    final int urgentFeedbackCount = feedbacks.where((f) => f.category == 'bug_report' || f.aiSentiment == 'negative').length;

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome & Live Status Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mission Control Center',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                        color: isDark ? Colors.white : AppColors.onBackgroundLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Real-time overview of PassionRide operations, revenue, and fleet health.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.onSurfaceVariantDark : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Sync Realtime Data'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Urgent Attention Alert Banner
            if (pendingHostsCount > 0 || pendingDocsCount > 0 || urgentFeedbackCount > 0)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.amber.shade500.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.amber.shade600.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Action Required: Items Awaiting Verification',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isDark ? Colors.amber.shade200 : Colors.amber.shade900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$pendingHostsCount Host(s), $pendingDocsCount KYC Document(s), and $urgentFeedbackCount Issue(s) are pending review.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        if (pendingHostsCount > 0)
                          OutlinedButton(
                            onPressed: () => onNavigateTab(2), // Host Verification tab
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.amber.shade900,
                              side: BorderSide(color: Colors.amber.shade700),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            child: const Text('Review Hosts', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        if (pendingDocsCount > 0)
                          ElevatedButton(
                            onPressed: () => onNavigateTab(5), // Compliance tab
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            child: const Text('Verify KYC', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

            // Top Primary Metrics Grid
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 900;
                final isMedium = constraints.maxWidth > 600;
                final crossAxisCount = isWide ? 4 : (isMedium ? 2 : 1);

                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: isWide ? 1.6 : (isMedium ? 1.8 : 2.2),
                  children: [
                    AdminMetricCard(
                      title: 'Gross Booking Volume (GMV)',
                      value: currencyFormatter.format(totalGmv),
                      subtitle: 'Total value of all reservations',
                      icon: Icons.currency_rupee,
                      accentColor: Colors.blue.shade700,
                      onTap: () => onNavigateTab(4), // Bookings
                    ),
                    AdminMetricCard(
                      title: 'Est. Platform Revenue (15%)',
                      value: currencyFormatter.format(platformRevenue),
                      subtitle: 'Net platform commission',
                      icon: Icons.account_balance_wallet,
                      accentColor: Colors.teal.shade700,
                      onTap: () => onNavigateTab(6), // Financials
                    ),
                    AdminMetricCard(
                      title: 'Active Trips In Progress',
                      value: '$activeBookingsCount Rides',
                      subtitle: 'Confirmed or active rentals right now',
                      icon: Icons.electric_scooter,
                      accentColor: Colors.orange.shade700,
                      badgeText: activeBookingsCount > 0 ? 'LIVE' : null,
                      badgeColor: Colors.green,
                      onTap: () => onNavigateTab(4), // Bookings
                    ),
                    AdminMetricCard(
                      title: 'Fleet Availability',
                      value: '$availableVehiclesCount / ${vehicles.length}',
                      subtitle: '$maintenanceVehiclesCount vehicles in maintenance',
                      icon: Icons.directions_car_filled,
                      accentColor: Colors.indigo.shade700,
                      onTap: () => onNavigateTab(3), // Vehicles
                    ),
                    AdminMetricCard(
                      title: 'Registered Users',
                      value: '${users.length}',
                      subtitle: '${users.where((u) => u.role.toLowerCase() == 'host').length} Hosts • ${users.where((u) => u.isBanned).length} Banned',
                      icon: Icons.people_alt,
                      accentColor: Colors.purple.shade700,
                      onTap: () => onNavigateTab(1), // Users
                    ),
                    AdminMetricCard(
                      title: 'Verified Partners & Hosts',
                      value: '${hosts.where((h) => h.isVerified).length} / ${hosts.length}',
                      subtitle: '$pendingHostsCount pending verification',
                      icon: Icons.verified_user,
                      accentColor: Colors.green.shade700,
                      badgeText: pendingHostsCount > 0 ? '$pendingHostsCount PENDING' : 'HEALTHY',
                      badgeColor: pendingHostsCount > 0 ? Colors.orange : Colors.green,
                      onTap: () => onNavigateTab(2), // Hosts
                    ),
                    AdminMetricCard(
                      title: 'KYC Document Compliance',
                      value: '${complianceDocs.where((d) => d.status.toLowerCase() == 'verified').length} / ${complianceDocs.length}',
                      subtitle: '$pendingDocsCount pending verification',
                      icon: Icons.badge,
                      accentColor: Colors.deepOrange.shade700,
                      badgeText: pendingDocsCount > 0 ? '$pendingDocsCount PENDING' : null,
                      badgeColor: Colors.red,
                      onTap: () => onNavigateTab(5), // Compliance
                    ),
                    AdminMetricCard(
                      title: 'Feedback & Bug Reports',
                      value: '${feedbacks.length}',
                      subtitle: '$urgentFeedbackCount bugs or negative reports',
                      icon: Icons.bug_report,
                      accentColor: const Color(0xFFE11D48),
                      badgeText: urgentFeedbackCount > 0 ? 'ATTN' : null,
                      badgeColor: Colors.red,
                      onTap: () => onNavigateTab(8), // Feedback
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),

            // Quick Operations & Recent Bookings Preview
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Recent Bookings Summary
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceContainerLowDark : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.outlineVariantDark : Colors.grey.shade200,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Recent Bookings',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppColors.onBackgroundLight,
                              ),
                            ),
                            TextButton(
                              onPressed: () => onNavigateTab(4),
                              child: const Text('View All Bookings'),
                            ),
                          ],
                        ),
                        const Divider(),
                        if (bookings.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 30),
                            child: Center(child: Text('No bookings recorded yet.')),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: bookings.take(5).length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final b = bookings[index];
                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: b.vehicleImageUrl.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(b.vehicleImageUrl, fit: BoxFit.cover, errorBuilder: (ctx, err, stack) => const Icon(Icons.directions_car)),
                                        )
                                      : const Icon(Icons.directions_car, color: AppColors.primary),
                                ),
                                title: Text(
                                  b.vehicleTitle.isNotEmpty ? b.vehicleTitle : 'Booking #${b.id.substring(0, 8)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                subtitle: Text(
                                  'Host: ${b.hostName} • ${DateFormat('dd MMM yyyy').format(b.startDate)}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      currencyFormatter.format(b.totalPrice),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    const SizedBox(height: 2),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(b.status).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        b.status.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: _getStatusColor(b.status),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),

                // Quick Navigation & Platform Health
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceContainerLowDark : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.outlineVariantDark : Colors.grey.shade200,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick Actions & Tools',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.onBackgroundLight,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildQuickActionTile(
                          icon: Icons.shield_outlined,
                          title: 'Review KYC Documents',
                          subtitle: '$pendingDocsCount pending verification',
                          color: Colors.blue,
                          onTap: () => onNavigateTab(5),
                        ),
                        _buildQuickActionTile(
                          icon: Icons.store_outlined,
                          title: 'Partner Onboarding',
                          subtitle: '$pendingHostsCount partner profiles awaiting sign-off',
                          color: Colors.teal,
                          onTap: () => onNavigateTab(2),
                        ),
                        _buildQuickActionTile(
                          icon: Icons.sensors,
                          title: 'Telematics Fleet Health',
                          subtitle: '${vehicles.length} connected IoT nodes',
                          color: Colors.indigo,
                          onTap: () => onNavigateTab(7),
                        ),
                        _buildQuickActionTile(
                          icon: Icons.tour_outlined,
                          title: 'Guided Tour Packages',
                          subtitle: '${tours.length} active experiences registered',
                          color: Colors.orange,
                          onTap: () => onNavigateTab(9),
                        ),
                        const Divider(height: 24),
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Supabase PostgreSQL Connected',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: onTap,
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.blue;
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.teal;
      case 'cancelled':
        return Colors.red;
      case 'disputed':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
