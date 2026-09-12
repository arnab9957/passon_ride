// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';
import '../widgets/rental_review_modal.dart';
import '../widgets/supabase_auth_dialog.dart';
import '../widgets/account_switcher_dialog.dart';
import '../widgets/customer_booking_details_dialog.dart';
import '../widgets/tr_text.dart';
import '../i18n/strings.g.dart';

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
        actions: [
          if (appState.isSignedIn)
            IconButton(
              icon: const Icon(Icons.swap_horiz_rounded),
              tooltip: 'Switch Account',
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const AccountSwitcherDialog(),
                );
              },
            ),
        ],
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
                    child: TrText(
                      '${t.booking.active} & Upcoming (${activeAndUpcoming.length})',
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
                    child: TrText(
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
                    child: TrText(
                      '${t.booking.completed} (${completedBookings.length})',
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
          // Account Architecture Context Banner
          if (appState.isSignedIn)
            _buildAccountContextBanner(context, appState, isDark),

          // Filter Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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

  Widget _buildAccountContextBanner(BuildContext context, AppState appState, bool isDark) {
    final isMother = appState.isMotherAccount;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMother
            ? (isDark ? Colors.blueGrey.shade900 : Colors.blue.shade50)
            : (isDark ? Colors.purple.shade900.withOpacity(0.4) : Colors.purple.shade50),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMother
              ? Colors.blue.withOpacity(0.3)
              : Colors.purple.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: isMother
                ? AppColors.primary.withOpacity(0.2)
                : Colors.purple.withOpacity(0.2),
            child: Icon(
              isMother ? Icons.family_restroom : Icons.child_care,
              size: 18,
              color: isMother ? AppColors.primary : Colors.purple,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isMother ? 'Mother Account View' : 'Child Account View',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isMother
                            ? (isDark ? Colors.lightBlueAccent : Colors.blue.shade900)
                            : (isDark ? Colors.purpleAccent : Colors.purple.shade900),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isMother ? Colors.blue : Colors.purple).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        appState.activeUserDisplayName,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isMother ? Colors.blue : Colors.purple,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  isMother
                      ? 'Aggregated family bookings: Showing your trips and bookings made by your linked child accounts.'
                      : 'Strict isolation active: Showing strictly your personal bookings. Other family trips remain hidden.',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const AccountSwitcherDialog(),
              );
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Switch',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isMother ? AppColors.primary : Colors.purple,
              ),
            ),
          ),
        ],
      ),
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
                if (booking.isChildHosting) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.teal.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.car_rental_rounded, size: 12, color: Colors.teal),
                        const SizedBox(width: 4),
                        Text(
                          'Child Fleet: ${booking.childName.isNotEmpty ? booking.childName : booking.hostName}',
                          style: const TextStyle(
                            color: Colors.teal,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (booking.isChildBooking) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.purple.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.child_care, size: 12, color: Colors.purple),
                        const SizedBox(width: 4),
                        Text(
                          'Child: ${booking.accountName.isNotEmpty ? booking.accountName : "Child Account"}',
                          style: const TextStyle(
                            color: Colors.purple,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (appState.isMotherAccount && appState.childCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.stars, size: 12, color: AppColors.primary),
                        SizedBox(width: 4),
                        Text(
                          'Mother Account',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                      if (booking.isChildHosting) ...[
                        Row(
                          children: [
                            const Icon(Icons.person_pin_circle_rounded, size: 14, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Customer: ${booking.customerName.isNotEmpty ? booking.customerName : "Rider"}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.hub_outlined, size: 14, color: Colors.purple),
                            const SizedBox(width: 4),
                            Text(
                              'Child Host: ${booking.childName.isNotEmpty ? booking.childName : booking.hostName}',
                              style: const TextStyle(color: Colors.purple, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ] else ...[
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
                      ],
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
                  if (booking.isChildHosting) ...[
                    ElevatedButton.icon(
                      onPressed: () {
                        showCustomerBookingDetailsDialog(context, booking);
                      },
                      icon: const Icon(Icons.badge_outlined, size: 15),
                      label: const Text('Customer Dossier'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () {
                        appState.fetchChatThreads();
                        appState.setNavIndex(5); // Chat
                      },
                      icon: const Icon(Icons.chat_bubble_outline, size: 16),
                      label: const Text('Message Customer'),
                    ),
                  ] else ...[
                    TextButton.icon(
                      onPressed: () {
                        appState.fetchChatThreads();
                        appState.setNavIndex(5); // Chat
                      },
                      icon: const Icon(Icons.chat_bubble_outline, size: 16),
                      label: const Text('Message Host'),
                    ),
                  ],
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
