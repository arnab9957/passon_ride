// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';

void showNotificationCenterModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _NotificationCenterSheet(),
  );
}

class _NotificationCenterSheet extends StatefulWidget {
  const _NotificationCenterSheet();

  @override
  State<_NotificationCenterSheet> createState() => _NotificationCenterSheetState();
}

class _NotificationCenterSheetState extends State<_NotificationCenterSheet> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allNotifs = appState.notifications;

    // Filter notifications
    final filteredNotifs = allNotifs.where((notif) {
      if (_selectedFilter == 'Unread') return !notif.isRead;
      if (_selectedFilter == 'Bookings') {
        return notif.type == NotificationType.bookingConfirmation ||
            notif.type == NotificationType.bookingReceivedHost ||
            notif.type == NotificationType.tourBookingConfirmation ||
            notif.type == NotificationType.tourBookingReceivedHost;
      }
      if (_selectedFilter == 'Payments') {
        return notif.type == NotificationType.paymentSuccessUser ||
            notif.type == NotificationType.paymentReceivedHost;
      }
      if (_selectedFilter == 'Tours') {
        return notif.type == NotificationType.tourBookingConfirmation ||
            notif.type == NotificationType.tourBookingReceivedHost;
      }
      if (_selectedFilter == 'Host Alerts') {
        return notif.type == NotificationType.bookingReceivedHost ||
            notif.type == NotificationType.tourBookingReceivedHost ||
            notif.type == NotificationType.paymentReceivedHost;
      }
      return true;
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLowest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_active_outlined,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Notifications',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          if (appState.unreadNotificationCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${appState.unreadNotificationCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Live vehicle bookings, tour alerts & payments',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Close',
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // Action Toolbar right under the notification bar line
          if (allNotifs.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceContainerHighDark.withOpacity(0.5) : AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.outlineVariantDark.withOpacity(0.3) : AppColors.outlineVariantLight.withOpacity(0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      '${allNotifs.length} total • ${appState.unreadNotificationCount} unread',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                    const Spacer(),
                    if (appState.unreadNotificationCount > 0) ...[
                      InkWell(
                        onTap: () => appState.markAllNotificationsAsRead(),
                        borderRadius: BorderRadius.circular(8),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.done_all, size: 14, color: AppColors.primary),
                              SizedBox(width: 4),
                              Text(
                                'Mark Read',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(width: 1, height: 14, color: Colors.grey.shade400),
                      const SizedBox(width: 8),
                    ],
                    // Prominent Clear All Button right under notification bar line
                    InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (dCtx) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            title: const Row(
                              children: [
                                Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
                                SizedBox(width: 8),
                                Text('Clear Notifications', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            content: const Text('Are you sure you want to clear all your notifications? This cannot be undone.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dCtx),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(dCtx);
                                  appState.clearAllNotifications();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('All notifications cleared'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.delete_sweep, size: 16, color: Colors.white),
                                label: const Text('Clear All', style: TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.delete_sweep_outlined, size: 15, color: Colors.redAccent.shade400),
                            const SizedBox(width: 4),
                            Text(
                              'Clear All',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.redAccent.shade400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 8),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip('All', allNotifs.length),
                _buildFilterChip('Unread', appState.unreadNotificationCount),
                _buildFilterChip('Bookings', allNotifs.where((n) => n.type == NotificationType.bookingConfirmation || n.type == NotificationType.bookingReceivedHost || n.type == NotificationType.tourBookingConfirmation || n.type == NotificationType.tourBookingReceivedHost).length),
                _buildFilterChip('Payments', allNotifs.where((n) => n.type == NotificationType.paymentSuccessUser || n.type == NotificationType.paymentReceivedHost).length),
                _buildFilterChip('Tours', allNotifs.where((n) => n.type == NotificationType.tourBookingConfirmation || n.type == NotificationType.tourBookingReceivedHost).length),
                _buildFilterChip('Host Alerts', allNotifs.where((n) => n.type == NotificationType.bookingReceivedHost || n.type == NotificationType.tourBookingReceivedHost || n.type == NotificationType.paymentReceivedHost).length),
              ],
            ),
          ),

          const Divider(height: 16),

          // Notification List
          Expanded(
            child: filteredNotifs.isEmpty
                ? _buildEmptyState(isDark)
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filteredNotifs.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (ctx, index) {
                      final notif = filteredNotifs[index];
                      return _buildNotificationCard(context, appState, notif, isDark);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int count) {
    final isSelected = _selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text('$label ($count)'),
        selected: isSelected,
        onSelected: (_) => setState(() => _selectedFilter = label),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : null,
        ),
        selectedColor: AppColors.primary,
        checkmarkColor: Colors.white,
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected ? AppColors.primary : Colors.grey.shade400.withOpacity(0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none_outlined,
              size: 64,
              color: isDark ? Colors.white24 : Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _selectedFilter == 'All' ? 'No notifications yet' : 'No $_selectedFilter notifications',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Activity alerts for vehicle rentals, tour bookings and payment receipts will appear right here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    AppState appState,
    AppNotification notif,
    bool isDark,
  ) {
    final config = _getNotificationConfig(notif.type, isDark);

    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
      ),
      onDismissed: (_) {
        appState.deleteNotification(notif.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed "${notif.title}"'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: InkWell(
        onTap: () {
          appState.markNotificationAsRead(notif.id);
          if (notif.actionNavIndex != null) {
            Navigator.pop(context);
            appState.setNavIndex(notif.actionNavIndex!);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: notif.isRead
                ? (isDark ? AppColors.surfaceContainerHighDark.withOpacity(0.4) : AppColors.surfaceContainerLow)
                : (isDark ? AppColors.surfaceContainerHighDark : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: notif.isRead
                  ? Colors.transparent
                  : config.accentColor.withOpacity(0.35),
              width: notif.isRead ? 1 : 1.5,
            ),
            boxShadow: notif.isRead
                ? []
                : [
                    BoxShadow(
                      color: config.accentColor.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Badge
              Stack(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: config.accentColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      config.icon,
                      color: config.accentColor,
                      size: 22,
                    ),
                  ),
                  if (!notif.isRead)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),

              // Text details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Category Tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: config.accentColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            config.tag,
                            style: TextStyle(
                              color: config.accentColor,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatRelativeTime(notif.timestamp),
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.white54 : Colors.black45,
                            fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notif.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notif.message,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.black87,
                        height: 1.35,
                      ),
                    ),
                    if (notif.actionNavIndex != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            config.actionLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: config.accentColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward_ios, size: 10, color: config.accentColor),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Image Thumbnail (if available)
              if (notif.imageUrl != null && notif.imageUrl!.isNotEmpty) ...[
                const SizedBox(width: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    notif.imageUrl!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  _NotificationConfig _getNotificationConfig(NotificationType type, bool isDark) {
    switch (type) {
      case NotificationType.bookingConfirmation:
        return _NotificationConfig(
          icon: Icons.directions_car,
          accentColor: const Color(0xFF0077B6),
          tag: 'BOOKING CONFIRMED',
          actionLabel: 'View PIN & Vehicle Controls',
        );
      case NotificationType.bookingReceivedHost:
        return _NotificationConfig(
          icon: Icons.key_outlined,
          accentColor: const Color(0xFF028090),
          tag: 'HOST: VEHICLE BOOKED',
          actionLabel: 'Open Host Fleet Dashboard',
        );
      case NotificationType.paymentSuccessUser:
        return _NotificationConfig(
          icon: Icons.check_circle_outline,
          accentColor: const Color(0xFF10B981),
          tag: 'PAYMENT SUCCESSFUL',
          actionLabel: 'View Booking Receipt',
        );
      case NotificationType.paymentReceivedHost:
        return _NotificationConfig(
          icon: Icons.account_balance_wallet_outlined,
          accentColor: const Color(0xFF059669),
          tag: 'PAYMENT RECEIVED',
          actionLabel: 'Open Host Earnings',
        );
      case NotificationType.tourBookingConfirmation:
        return _NotificationConfig(
          icon: Icons.tour_outlined,
          accentColor: const Color(0xFFF59E0B),
          tag: 'GUIDED TOUR BOOKED',
          actionLabel: 'View Tour Itinerary',
        );
      case NotificationType.tourBookingReceivedHost:
        return _NotificationConfig(
          icon: Icons.backpack_outlined,
          accentColor: const Color(0xFF8B5CF6),
          tag: 'HOST: TOUR RESERVATION',
          actionLabel: 'Open Host Dashboard',
        );
      case NotificationType.telematicsAlert:
        return _NotificationConfig(
          icon: Icons.sensors,
          accentColor: const Color(0xFFF97316),
          tag: 'TELEMATICS IOT ALERT',
          actionLabel: 'View Live Telematics',
        );
      case NotificationType.documentVerified:
        return _NotificationConfig(
          icon: Icons.verified_user_outlined,
          accentColor: const Color(0xFF06B6D4),
          tag: 'COMPLIANCE VERIFIED',
          actionLabel: 'View Trust Score',
        );
      case NotificationType.general:
        return _NotificationConfig(
          icon: Icons.notifications_active_outlined,
          accentColor: AppColors.primary,
          tag: 'SYSTEM NOTICE',
          actionLabel: 'View Details',
        );
    }
  }

  String _formatRelativeTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}

class _NotificationConfig {
  final IconData icon;
  final Color accentColor;
  final String tag;
  final String actionLabel;

  _NotificationConfig({
    required this.icon,
    required this.accentColor,
    required this.tag,
    required this.actionLabel,
  });
}
