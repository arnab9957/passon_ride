// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';
import '../widgets/rental_review_modal.dart';
import '../widgets/supabase_auth_dialog.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _filterQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final allBookings = appState.activeBookings;
    final activeAndUpcoming = allBookings.where((b) {
      final s = b.status.toLowerCase();
      return s == 'active' || s == 'confirmed' || s == 'pending';
    }).toList();

    final rentalRequests = allBookings.where((b) {
      final s = b.status.toLowerCase();
      return s == 'pending' || s == 'requested' || s == 'in_review';
    }).toList();

    final completedBookings = allBookings.where((b) {
      final s = b.status.toLowerCase();
      return s == 'completed' || s == 'finished' || s == 'cancelled';
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Bookings & Rental Requests',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: isDark ? Colors.white : AppColors.primary,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.directions_car, size: 16),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Active & Upcoming (${activeAndUpcoming.length})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.inbox_outlined, size: 16),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Requests (${rentalRequests.length})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.history, size: 16),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Completed (${completedBookings.length})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filter Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _filterQuery = val.trim().toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search bookings by vehicle or host...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _filterQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _filterQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLow,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBookingList(
                  context,
                  appState,
                  _filterBookings(activeAndUpcoming),
                  emptyTitle: 'No Active or Upcoming Bookings',
                  emptySubtitle: 'Your confirmed rentals and keyless reservations will appear here.',
                  isUpcoming: true,
                ),
                _buildBookingList(
                  context,
                  appState,
                  _filterBookings(rentalRequests),
                  emptyTitle: 'No Pending Rental Requests',
                  emptySubtitle: 'Incoming or outgoing P2P booking requests awaiting approval will show up here.',
                  isUpcoming: false,
                ),
                _buildBookingList(
                  context,
                  appState,
                  _filterBookings(completedBookings),
                  emptyTitle: 'No Past Trip History',
                  emptySubtitle: 'Your finished rental history and receipts will be stored here.',
                  isUpcoming: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Booking> _filterBookings(List<Booking> list) {
    if (_filterQuery.isEmpty) return list;
    return list.where((b) {
      final titleMatch = b.vehicleTitle.toLowerCase().contains(_filterQuery);
      final hostMatch = b.hostName.toLowerCase().contains(_filterQuery);
      final statusMatch = b.status.toLowerCase().contains(_filterQuery);
      return titleMatch || hostMatch || statusMatch;
    }).toList();
  }

  Widget _buildBookingList(
    BuildContext context,
    AppState appState,
    List<Booking> bookings, {
    required String emptyTitle,
    required String emptySubtitle,
    required bool isUpcoming,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (bookings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLow,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.calendar_today_outlined,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                emptyTitle,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                emptySubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => appState.setNavIndex(1), // Go to discovery
                icon: const Icon(Icons.search),
                label: const Text('Browse Available Vehicles'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return _buildBookingCard(context, appState, booking, isUpcoming);
      },
    );
  }

  Widget _buildBookingCard(BuildContext context, AppState appState, Booking booking, bool isUpcoming) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('MMM dd, yyyy');
    final startStr = dateFormat.format(booking.startDate);
    final endStr = dateFormat.format(booking.endDate);

    final statusColor = booking.status.toLowerCase() == 'active'
        ? Colors.green
        : (booking.status.toLowerCase() == 'confirmed'
            ? Colors.blue
            : (booking.status.toLowerCase() == 'pending' ? Colors.orange : Colors.grey));

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Status & Price Bar
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.circle, size: 8, color: statusColor),
                      const SizedBox(width: 6),
                      Text(
                        booking.status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  '₹${booking.totalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Vehicle Info Row
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    booking.vehicleImageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.directions_car, size: 36, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.vehicleTitle,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            'Host: ${booking.hostName}',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.date_range, size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            '$startStr - $endStr',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Keyless Unlock Code Banner (if active/confirmed)
            if (booking.unlockPasscode.isNotEmpty &&
                (booking.status.toLowerCase() == 'confirmed' || booking.status.toLowerCase() == 'active')) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.key, color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Keyless Bluetooth Unlock PIN', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        Text(
                          booking.unlockPasscode,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: () {
                        appState.setNavIndex(3); // Booking Verification Screen
                      },
                      icon: const Icon(Icons.bluetooth_searching, size: 14),
                      label: const Text('Unlock'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Bottom Action Buttons
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () {
                      appState.fetchChatThreads();
                      appState.setNavIndex(5); // Chat
                    },
                    icon: const Icon(Icons.chat_bubble_outline, size: 16),
                    label: const Text('Message Host'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (!appState.isSignedIn) {
                        showDialog(
                          context: context,
                          builder: (_) => const SupabaseAuthDialog(),
                        );
                        return;
                      }
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => RentalReviewModal(
                          vehicleId: booking.vehicleId,
                          bookingId: booking.id,
                        ),
                      );
                    },
                    icon: const Icon(Icons.star_rate_rounded, size: 16),
                    label: const Text('Rate Rental'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryContainer,
                      foregroundColor: AppColors.onPrimaryContainer,
                      elevation: 0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      appState.setNavIndex(13); // IoT Telematics Hub
                    },
                    icon: const Icon(Icons.sensors, size: 16),
                    label: const Text('IoT Telematics'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? AppColors.surfaceContainerHighDark : AppColors.surfaceContainerHigh,
                      foregroundColor: isDark ? Colors.white : Colors.black87,
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
