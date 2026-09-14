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
  String _selectedProfileFilter = 'all'; // 'all', 'mother', or childId

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

    // Sanitize selected profile filter
    final validChildIds = appState.childProfiles.map((c) => c.childId).toSet();
    if (_selectedProfileFilter != 'all' &&
        _selectedProfileFilter != 'mother' &&
        !validChildIds.contains(_selectedProfileFilter)) {
      _selectedProfileFilter = 'all';
    }

    final baseBookings = appState.activeBookings;
    List<Booking> allBookings;

    if (appState.isMotherAccount && _selectedProfileFilter != 'all') {
      if (_selectedProfileFilter == 'mother') {
        // Only Mother's personal bookings (excluding all child bookings and child hosted bookings)
        allBookings = baseBookings.where((b) {
          final cp = appState.getChildProfileForBooking(b);
          return cp == null && !b.isChildBooking && !b.isChildHosting;
        }).toList();
      } else {
        // Specific child profile selected from dropdown
        allBookings = appState.getBookingsForChild(_selectedProfileFilter);
      }
    } else {
      allBookings = baseBookings;
    }

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


          // Dropdown menu to filter bookings from different profiles
          if (appState.isSignedIn && appState.isMotherAccount && appState.childProfiles.isNotEmpty)
            _buildProfileFilterDropdown(context, appState, isDark),

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
      final childMatch = b.childName.toLowerCase().contains(_filterQuery) ||
          b.accountName.toLowerCase().contains(_filterQuery);
      return titleMatch || hostMatch || statusMatch || childMatch;
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



  Widget _buildProfileFilterDropdown(BuildContext context, AppState appState, bool isDark) {
    final totalCount = appState.allBookings.length;
    final motherCount = appState.allBookings.where((b) {
      final cp = appState.getChildProfileForBooking(b);
      return cp == null && !b.isChildBooking && !b.isChildHosting;
    }).length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceContainerDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _selectedProfileFilter == 'all'
              ? (isDark ? AppColors.outlineVariantDark : Colors.blue.shade200)
              : (isDark ? AppColors.primary : AppColors.primary.withValues(alpha: 0.6)),
          width: _selectedProfileFilter == 'all' ? 1 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: (_selectedProfileFilter == 'all'
                      ? AppColors.primary
                      : (_selectedProfileFilter == 'mother' ? Colors.blue : Colors.purple))
                  .withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _selectedProfileFilter == 'all'
                  ? Icons.filter_alt_rounded
                  : (_selectedProfileFilter == 'mother' ? Icons.stars : Icons.child_care),
              size: 16,
              color: _selectedProfileFilter == 'all'
                  ? AppColors.primary
                  : (_selectedProfileFilter == 'mother' ? Colors.blue : Colors.purple),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Filter Profile:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedProfileFilter,
                isExpanded: true,
                dropdownColor: isDark ? AppColors.surfaceContainerDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                icon: const Icon(Icons.arrow_drop_down_rounded, size: 24, color: AppColors.primary),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                items: [
                  DropdownMenuItem(
                    value: 'all',
                    child: Row(
                      children: [
                        const Icon(Icons.family_restroom, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'All Profiles (Everyone) • $totalCount',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'mother',
                    child: Row(
                      children: [
                        const Icon(Icons.stars, size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Primary: ${appState.motherProfile?.name.isNotEmpty == true ? appState.motherProfile!.name : appState.activeUserDisplayName} • $motherCount',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...appState.childProfiles.map((child) {
                    final cCount = appState.getBookingsForChild(child.childId).length;
                    return DropdownMenuItem(
                      value: child.childId,
                      child: Row(
                        children: [
                          const Icon(Icons.child_care, size: 16, color: Colors.purple),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Child: ${child.name} • $cCount',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedProfileFilter = val;
                    });
                  }
                },
              ),
            ),
          ),
          if (_selectedProfileFilter != 'all')
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
              tooltip: 'Reset to All Profiles',
              splashRadius: 18,
              onPressed: () {
                setState(() {
                  _selectedProfileFilter = 'all';
                });
              },
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
                          appState.isMotherAccount
                              ? 'Child Fleet: ${booking.childName.isNotEmpty ? booking.childName : booking.hostName}'
                              : 'My Hosted Fleet',
                          style: const TextStyle(
                            color: Colors.teal,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (appState.isMotherAccount) ...[
                  if (booking.isChildBooking || appState.getChildProfileForBooking(booking) != null) ...[
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
                            'Child: ${booking.childName.isNotEmpty ? booking.childName : (appState.getChildProfileForBooking(booking)?.name.isNotEmpty == true ? appState.getChildProfileForBooking(booking)!.name : (booking.accountName.isNotEmpty ? booking.accountName : "Child Account"))}',
                            style: const TextStyle(
                              color: Colors.purple,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
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
                            'Primary Account (M)',
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
                ] else ...[
                  // In Child Profile: personal booking
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.purple.withOpacity(0.4)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_outline, size: 12, color: Colors.purple),
                        SizedBox(width: 4),
                        Text(
                          'Personal Booking',
                          style: TextStyle(
                            color: Colors.purple,
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

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
