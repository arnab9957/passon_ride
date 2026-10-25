// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';
import '../widgets/rental_review_modal.dart';
import '../widgets/supabase_auth_dialog.dart';
// import '../widgets/account_switcher_dialog.dart';
import '../widgets/customer_booking_details_dialog.dart';
import '../widgets/stay_pass_modal.dart';
import '../widgets/record_offline_booking_dialog.dart';
import '../widgets/tour_details_modal.dart';
import '../widgets/google_sheets_sync_dialog.dart';
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
  // 0: Bikes & Vehicles, 1: Guided Tours, 2: Hotels & Homestays
  int _selectedCategoryIndex = 0;

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

    final tourBookings = appState.paymentTransactions
        .where((tx) => tx.notes.containsKey('tour_id') || tx.bookingId.startsWith('tb_'))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Bookings & Rental Requests',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Link Google Sheet / Excel',
            icon: const Icon(Icons.table_chart_rounded, color: Color(0xFF107C41)),
            onPressed: () => GoogleSheetsSyncDialog.show(context, appState),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8, right: 12),
            child: ElevatedButton.icon(
              onPressed: () => RecordOfflineBookingDialog.show(context, appState),
              icon: const Icon(Icons.person_add_alt_1, size: 15, color: Colors.white),
              label: const Text('+ Offline Booking', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
        bottom: _selectedCategoryIndex == 0
            ? TabBar(
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
              )
            : null,
      ),
      body: Column(
        children: [


          // Dropdown menu to filter bookings from different profiles (Mother/Child architecture)
          // if (appState.isSignedIn && appState.isMotherAccount && appState.childProfiles.isNotEmpty)
          //   _buildProfileFilterDropdown(context, appState, isDark),

          // Host Management Tools: Onboard Offline & Google Sheet Sync
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(
              children: [
                // 1. Onboard Offline / Walk-in Customer
                InkWell(
                  onTap: () => RecordOfflineBookingDialog.show(
                    context,
                    appState,
                    vehicles: appState.hostedVehiclesForActiveAccount,
                    hotels: appState.hotels.where((h) => h.hostId == appState.activeUserId).toList(),
                    tours: appState.tours.where((t) => t.hostId == appState.activeUserId || appState.isHostOfTour(t)).toList(),
                  ),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF065F46), const Color(0xFF042F2E)]
                            : [const Color(0xFFD1FAE5), const Color(0xFFA7F3D0)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? const Color(0xFF059669) : const Color(0xFF34D399),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669).withOpacity(0.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF059669), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 6,
                                runSpacing: 2,
                                children: [
                                  const Text(
                                    'Onboard Offline / Walk-in Customer',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF059669),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'MANUAL ENTRY',
                                      style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Directly record walk-in bike, homestay or tour bookings with guest ID & contact details.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.grey.shade300 : Colors.teal.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF059669)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // 2. Google Sheets / Excel Live Sync Tile
                InkWell(
                  onTap: () => GoogleSheetsSyncDialog.show(context, appState),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF1E3A8A).withOpacity(0.4), const Color(0xFF064E3B).withOpacity(0.35)]
                            : [const Color(0xFFEFF6FF), const Color(0xFFECFDF5)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? const Color(0xFF107C41) : const Color(0xFF86EFAC),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF107C41).withOpacity(0.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.table_chart_rounded, color: Color(0xFF107C41), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 6,
                                runSpacing: 2,
                                children: [
                                  const Text(
                                    'Link Google Sheet / Excel',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF107C41),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'AUTO SYNC',
                                      style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Automatically log all bike, stay, and tour bookings into your personal Gmail spreadsheet in real-time.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.grey.shade300 : const Color(0xFF14532D),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF107C41)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ==========================================
          // SERVICE CATEGORY SELECTION TABS
          // ==========================================
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedCategoryIndex = 0),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                      decoration: BoxDecoration(
                        color: _selectedCategoryIndex == 0
                            ? AppColors.primary
                            : (isDark ? AppColors.surfaceContainerDark : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedCategoryIndex == 0
                              ? AppColors.primary
                              : (isDark ? AppColors.outlineVariantDark : Colors.grey.shade300),
                          width: _selectedCategoryIndex == 0 ? 2 : 1,
                        ),
                        boxShadow: _selectedCategoryIndex == 0
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.two_wheeler,
                            size: 20,
                            color: _selectedCategoryIndex == 0
                                ? Colors.white
                                : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Bikes & Cars',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _selectedCategoryIndex == 0
                                  ? Colors.white
                                  : (isDark ? Colors.white : Colors.black87),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${allBookings.length} Bookings',
                            style: TextStyle(
                              fontSize: 9.5,
                              color: _selectedCategoryIndex == 0
                                  ? Colors.white70
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedCategoryIndex = 1),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                      decoration: BoxDecoration(
                        color: _selectedCategoryIndex == 1
                            ? AppColors.secondary
                            : (isDark ? AppColors.surfaceContainerDark : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedCategoryIndex == 1
                              ? AppColors.secondary
                              : (isDark ? AppColors.outlineVariantDark : Colors.grey.shade300),
                          width: _selectedCategoryIndex == 1 ? 2 : 1,
                        ),
                        boxShadow: _selectedCategoryIndex == 1
                            ? [
                                BoxShadow(
                                  color: AppColors.secondary.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.explore_rounded,
                            size: 20,
                            color: _selectedCategoryIndex == 1
                                ? Colors.white
                                : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Guided Tours',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _selectedCategoryIndex == 1
                                  ? Colors.white
                                  : (isDark ? Colors.white : Colors.black87),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${tourBookings.length} Tours',
                            style: TextStyle(
                              fontSize: 9.5,
                              color: _selectedCategoryIndex == 1
                                  ? Colors.white70
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedCategoryIndex = 2),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                      decoration: BoxDecoration(
                        color: _selectedCategoryIndex == 2
                            ? Colors.teal
                            : (isDark ? AppColors.surfaceContainerDark : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedCategoryIndex == 2
                              ? Colors.teal
                              : (isDark ? AppColors.outlineVariantDark : Colors.grey.shade300),
                          width: _selectedCategoryIndex == 2 ? 2 : 1,
                        ),
                        boxShadow: _selectedCategoryIndex == 2
                            ? [
                                BoxShadow(
                                  color: Colors.teal.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.holiday_village_rounded,
                            size: 20,
                            color: _selectedCategoryIndex == 2
                                ? Colors.white
                                : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Hotels & Stays',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _selectedCategoryIndex == 2
                                  ? Colors.white
                                  : (isDark ? Colors.white : Colors.black87),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${appState.hotelBookings.length} Stays',
                            style: TextStyle(
                              fontSize: 9.5,
                              color: _selectedCategoryIndex == 2
                                  ? Colors.white70
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

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
                hintText: _selectedCategoryIndex == 0
                    ? 'Search bookings by vehicle or host...'
                    : (_selectedCategoryIndex == 1
                        ? 'Search guided tours...'
                        : 'Search hotel/homestay stays...'),
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

          // Category Body Content
          Expanded(
            child: _selectedCategoryIndex == 0
                ? TabBarView(
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
                  )
                : (_selectedCategoryIndex == 1
                    ? _buildTourBookingsList(context, appState, tourBookings)
                    : _buildHotelBookingsList(context, appState)),
          ),
        ],
      ),
    );
  }

  Widget _buildTourBookingsList(
    BuildContext context,
    AppState appState,
    List<PaymentTransaction> tourTxs,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredTxs = tourTxs.where((tx) {
      if (_filterQuery.isEmpty) return true;
      final tourTitle = (tx.notes['tour_title'] ?? '').toString().toLowerCase();
      final guideName = (tx.notes['guide_name'] ?? '').toString().toLowerCase();
      final id = tx.bookingId.toLowerCase();
      return tourTitle.contains(_filterQuery) ||
          guideName.contains(_filterQuery) ||
          id.contains(_filterQuery);
    }).toList();

    if (filteredTxs.isEmpty) {
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
                child: const Icon(
                  Icons.explore_off_outlined,
                  size: 48,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Guided Tour Bookings',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'Book curated bike tours and scenic expeditions led by expert marshals.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => appState.setNavIndex(1), // Discovery / Tours
                icon: const Icon(Icons.explore),
                label: const Text('Discover Guided Tours'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
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
      itemCount: filteredTxs.length,
      itemBuilder: (ctx, idx) {
        final tx = filteredTxs[idx];
        final tourTitle = tx.notes['tour_title']?.toString() ?? 'Guided Tour Expedition';
        final guideName = tx.notes['guide_name']?.toString() ?? 'Tour Marshal';
        final participants = tx.notes['participants']?.toString() ?? '1';
        final tourId = tx.notes['tour_id']?.toString() ?? '';

        Tour? matchingTour;
        if (tourId.isNotEmpty) {
          try {
            matchingTour = appState.tours.firstWhere((t) => t.id == tourId);
          } catch (_) {}
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: isDark ? AppColors.surfaceContainerHigh : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        tx.bookingId,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.secondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'CONFIRMED',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: matchingTour != null && matchingTour.imageUrl.isNotEmpty
                          ? Image.network(
                              appState.imageKitService.buildImageUrl(matchingTour.imageUrl),
                              width: 70,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => Container(
                                width: 70,
                                height: 60,
                                color: Colors.grey.shade300,
                                child: const Icon(Icons.explore, color: Colors.grey),
                              ),
                            )
                          : Container(
                              width: 70,
                              height: 60,
                              color: AppColors.secondary.withValues(alpha: 0.15),
                              child: const Icon(Icons.explore, color: AppColors.secondary),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tourTitle,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Guide: $guideName • $participants Participant(s)',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Payment: ₹${tx.amount.toStringAsFixed(0)} • Method: ${tx.paymentMethod.toUpperCase()}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.teal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ref: ${tx.receipt}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    if (matchingTour != null)
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.secondary,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                        onPressed: () => showTourDetailsModal(context, appState, matchingTour!),
                        icon: const Icon(Icons.visibility, size: 14),
                        label: const Text('Tour Itinerary', style: TextStyle(fontSize: 11)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHotelBookingsList(BuildContext context, AppState appState) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stays = appState.hotelBookings;

    if (stays.isEmpty) {
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
                child: const Icon(
                  Icons.holiday_village_outlined,
                  size: 48,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Stays Booked Yet',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'Explore budget homestays and rural lodges with 0% platform commission.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => appState.setNavIndex(0), // Discovery / Home
                icon: const Icon(Icons.explore),
                label: const Text('Discover Local Stays'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
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
      itemCount: stays.length,
      itemBuilder: (ctx, idx) {
        final b = stays[idx];
        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: isDark ? AppColors.surfaceContainerHigh : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      b.bookingRef,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.teal),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: b.status == 'Cancelled'
                            ? Colors.red.withOpacity(0.15)
                            : b.status == 'Active'
                                ? Colors.green.withOpacity(0.15)
                                : Colors.teal.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        b.status,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: b.status == 'Cancelled'
                              ? Colors.red
                              : b.status == 'Active'
                                  ? Colors.green
                                  : Colors.teal,
                        ),
                      ),
                    ),
                  ],
                ),
                if (b.status == 'Cancelled') ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cancel, color: Colors.red, size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Reservation Cancelled${b.cancelledBy.isNotEmpty ? " by ${b.cancelledBy == "host" ? "Host" : "Guest"}" : ""}${b.cancellationReason.isNotEmpty ? ": ${b.cancellationReason}" : ""}',
                            style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        b.hotelImageUrl,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 70,
                          height: 70,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.hotel, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            b.hotelName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${b.roomType} • ${b.nights} night(s)',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '📅 ${DateFormat('dd MMM').format(b.checkInDate)} - ${DateFormat('dd MMM yyyy').format(b.checkOutDate)}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Total: ₹${b.totalPrice.toStringAsFixed(0)} (Pay at Check-in)',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                // Wi-Fi & Check-in Info Chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.wifi, size: 14, color: Colors.teal),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'Wi-Fi at Front Desk • Check-in: 12:00 PM',
                          style: TextStyle(fontSize: 11, color: Colors.teal),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.chat_outlined, size: 15, color: Colors.teal),
                      label: const Text('Chat Host', style: TextStyle(fontSize: 12, color: Colors.teal)),
                      onPressed: () => appState.openChatWithHost(
                        hostName: b.hostName.isNotEmpty ? b.hostName : (b.hotelName.isNotEmpty ? b.hotelName : 'Hotel Host'),
                        vehicleTitle: 'Hotel: ${b.hotelName}',
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        if (b.status != 'Cancelled' && b.status != 'Completed')
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: BorderSide(color: Colors.red.shade300),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.cancel_outlined, size: 14),
                            label: const Text('Cancel Stay', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            onPressed: () => _showCancelStayDialog(context, appState, b, isHost: false),
                          ),
                        if (b.status != 'Cancelled')
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.qr_code, size: 14),
                            label: const Text('Stay Pass QR', style: TextStyle(fontSize: 11)),
                            onPressed: () => showStayPassModal(context, appState, b),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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



  // ignore: unused_element
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
            : (booking.status.toLowerCase() == 'pending'
                ? Colors.orange
                : (booking.status.toLowerCase() == 'cancelled' ? Colors.red : Colors.grey)));

    final currentUid = appState.activeAccountId.isNotEmpty
        ? appState.activeAccountId
        : (appState.userProfile?.uid ?? appState.supabaseUser?.id ?? '');
    final isHost = booking.isChildHosting ||
        (currentUid.isNotEmpty && booking.hostId == currentUid) ||
        appState.vehicles.any((v) => v.id == booking.vehicleId && (v.hostId == currentUid || v.ownerAccountId == currentUid));
    final canCancel = booking.status.toLowerCase() != 'cancelled' && booking.status.toLowerCase() != 'completed';

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
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () {
                            showCustomerBookingDetailsDialog(context, booking);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: statusColor.withOpacity(0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  (booking.status.toLowerCase() == 'confirmed' || booking.status.toLowerCase() == 'active')
                                      ? Icons.check_circle_rounded
                                      : Icons.circle,
                                  size: (booking.status.toLowerCase() == 'confirmed' || booking.status.toLowerCase() == 'active')
                                      ? 12
                                      : 8,
                                  color: statusColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  (booking.status.toLowerCase() == 'confirmed' || booking.status.toLowerCase() == 'active')
                                      ? 'BOOKING SUCCESSFULLY DONE'
                                      : booking.status.toUpperCase(),
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.touch_app_rounded, size: 11, color: statusColor),
                              ],
                            ),
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
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '₹${booking.totalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _showDeleteBookingDialog(context, appState, booking),
                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                  tooltip: 'Delete Booking',
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
                      if (isHost && (booking.customerName.isNotEmpty || booking.customerDrivingLicenseNumber.isNotEmpty)) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark ? Colors.white12 : Colors.grey.shade200,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.person_rounded, size: 13, color: AppColors.primary),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      'Consumer: ${booking.customerName.isNotEmpty ? booking.customerName : "Customer Rider"}',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Icon(Icons.verified, size: 12, color: Colors.blue),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  const Icon(Icons.credit_card_rounded, size: 13, color: Colors.indigo),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      'DL: ${(booking.customerDrivingLicenseNumber.isNotEmpty && booking.customerDrivingLicenseNumber != 'DL-042023008914') ? booking.customerDrivingLicenseNumber : 'Pending Verification'}',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: isDark ? Colors.indigo.shade200 : Colors.indigo.shade800,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'LIVE MATCH',
                                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.green),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),



            // Cancellation Notification Banner for Renter & Host
            if (booking.status.toLowerCase() == 'cancelled') ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.cancel_outlined, color: Colors.red.shade800, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.cancelledBy == 'host'
                                ? '⚠️ Ride Cancelled by Seller / Host'
                                : (booking.cancelledBy == 'customer'
                                    ? '🚫 Ride Cancelled by You (Renter)'
                                    : '🚫 Ride Cancelled'),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.red.shade900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            booking.cancelledBy == 'host'
                                ? 'The owner of this vehicle cancelled the booking.${booking.cancellationReason.isNotEmpty ? " Reason: \"${booking.cancellationReason}\"" : ""} Any escrowed payments are automatically refunded.'
                                : (booking.cancellationReason.isNotEmpty
                                    ? 'Reason: "${booking.cancellationReason}". Vehicle has been freed up.'
                                    : 'This reservation is cancelled and inventory released.'),
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.red.shade800,
                              height: 1.3,
                            ),
                          ),
                        ],
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (canCancel) ...[
                  ElevatedButton.icon(
                    onPressed: () => _showCancelBookingDialog(context, appState, booking, isHost),
                    icon: const Icon(Icons.cancel_outlined, size: 16),
                    label: Text(
                      isHost ? 'Cancel Booking (Host)' : 'Cancel Ride',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ],
                if (booking.isChildHosting ||
                    appState.isHost ||
                    (booking.hostId.isNotEmpty &&
                        booking.hostId == (appState.userProfile?.uid ?? appState.supabaseUser?.id ?? '')) ||
                    (booking.hostName.isNotEmpty &&
                        appState.activeUserDisplayName != 'Guest User' &&
                        booking.hostName.toLowerCase() == appState.activeUserDisplayName.toLowerCase())) ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      showCustomerBookingDetailsDialog(context, booking);
                    },
                    icon: const Icon(Icons.badge_outlined, size: 15),
                    label: const Text('Consumer Details (DL & Photo)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: booking.isChildHosting ? Colors.purple : AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      appState.openChatWithHost(
                        hostName: booking.customerName.isNotEmpty ? booking.customerName : 'Customer',
                        vehicleTitle: booking.vehicleTitle,
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_outline, size: 16),
                    label: const Text('Message Consumer'),
                  ),
                ] else ...[
                  TextButton.icon(
                    onPressed: () {
                      appState.openChatWithHost(
                        hostName: booking.hostName.isNotEmpty ? booking.hostName : 'Host',
                        vehicleTitle: booking.vehicleTitle,
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_outline, size: 16),
                    label: const Text('Message Host'),
                  ),
                ],
                if (booking.status.toLowerCase() == 'completed') ...[
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
                if (booking.status.toLowerCase() == 'cancelled') ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.block, size: 14, color: Colors.red),
                        const SizedBox(width: 4),
                        Text(
                          booking.cancelledBy == 'host'
                              ? 'Cancelled by Host • Refund Processed'
                              : 'Ride Cancelled • Bike Freed Up',
                          style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelBookingDialog(
    BuildContext context,
    AppState appState,
    Booking booking,
    bool isHost,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cancel_outlined, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isHost ? 'Cancel Booking (Host)' : 'Cancel Ride',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isHost
                  ? 'Are you sure you want to cancel this booking for ${booking.vehicleTitle} as host?'
                  : 'Are you sure you want to cancel your ride for ${booking.vehicleTitle}?',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.green.shade800, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'The bike will immediately be freed up in state & database for other consumers to book.',
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Ride'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await appState.cancelBooking(booking.id, byHost: isHost);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isHost
                          ? 'Booking cancelled by host. The vehicle is now available for other consumers.'
                          : 'Ride cancelled successfully. The bike is now free for other consumers.',
                    ),
                    backgroundColor: Colors.red.shade800,
                  ),
                );
              }
            },
            child: const Text('Yes, Cancel Ride'),
          ),
        ],
      ),
    );
  }

  void _showDeleteBookingDialog(
    BuildContext context,
    AppState appState,
    Booking booking,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Booking'),
        content: const Text(
          'Are you sure you want to delete this booking from your list? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await appState.deleteBooking(booking.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Booking deleted successfully')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showCancelStayDialog(
    BuildContext context,
    AppState appState,
    HotelBooking booking, {
    required bool isHost,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final List<String> reasonOptions = isHost
        ? [
            'Room Maintenance / Repair',
            'Overbooked / Inventory issue',
            'Host Personal Emergency',
            'Guest Requested Cancellation',
            'Property Temporarily Unavailable',
            'Other Reason',
          ]
        : [
            'Change in Travel Plans',
            'Booked by Mistake',
            'Found Alternative Accommodation',
            'Trip Postponed / Rescheduled',
            'Personal Emergency',
            'Other Reason',
          ];

    String selectedReason = reasonOptions.first;
    final reasonDetailsCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cancel_outlined, color: Colors.red, size: 24),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isHost ? 'Cancel Guest Stay' : 'Cancel Stay Reservation',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHost
                      ? 'Are you sure you want to cancel the reservation for guest "${booking.guestName}" at ${booking.hotelName}?'
                      : 'Are you sure you want to cancel your stay at "${booking.hotelName}"?',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceContainerHighDark : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Stay: ${booking.hotelName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      Text('Ref: ${booking.bookingRef} • ${booking.roomCount} room(s)', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      Text(
                        'Dates: ${DateFormat('dd MMM').format(booking.checkInDate)} - ${DateFormat('dd MMM yyyy').format(booking.checkOutDate)} (${booking.nights} night${booking.nights > 1 ? "s" : ""})',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      Text('Amount: ₹${booking.totalPrice.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.teal)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Cancellation Reason:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: selectedReason,
                  isExpanded: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    isDense: true,
                  ),
                  items: reasonOptions
                      .map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 12))))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDlgState(() => selectedReason = val);
                    }
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: reasonDetailsCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Additional Details (Optional)',
                    hintText: 'Enter any notes for the ${isHost ? "guest" : "host"}...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.all(10),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 10),
                Text(
                  isHost
                      ? '⚠️ ${booking.roomCount} room(s) will be immediately restored to your available inventory.'
                      : 'ℹ️ Your booking will be cancelled and room inventory will be released back to the host.',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Keep Stay'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                final finalReason = reasonDetailsCtrl.text.trim().isNotEmpty
                    ? '$selectedReason - ${reasonDetailsCtrl.text.trim()}'
                    : selectedReason;

                await appState.cancelHotelBooking(
                  booking.id,
                  byHost: isHost,
                  reason: finalReason,
                );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isHost
                            ? 'Stay reservation cancelled. ${booking.roomCount} room(s) released back to inventory.'
                            : 'Stay reservation cancelled successfully.',
                      ),
                      backgroundColor: Colors.red.shade800,
                    ),
                  );
                }
              },
              child: const Text('Confirm Cancellation'),
            ),
          ],
        ),
      ),
    );
  }
}
