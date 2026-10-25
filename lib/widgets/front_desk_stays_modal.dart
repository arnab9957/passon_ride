// ignore_for_file: deprecated_member_use, use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import 'stay_document_viewer_dialog.dart';
import 'hotel_details_modal.dart';
import 'record_offline_booking_dialog.dart';

void showFrontDeskStaysModal(BuildContext context, AppState appState, Hotel hotel) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: _FrontDeskStaysSheet(hotel: hotel, appState: appState),
      ),
    ),
  );
}

class _FrontDeskStaysSheet extends StatefulWidget {
  final Hotel hotel;
  final AppState appState;

  const _FrontDeskStaysSheet({
    required this.hotel,
    required this.appState,
  });

  @override
  State<_FrontDeskStaysSheet> createState() => _FrontDeskStaysSheetState();
}

class _FrontDeskStaysSheetState extends State<_FrontDeskStaysSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await widget.appState.fetchHotelRooms(widget.hotel.id);
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        final appState = widget.appState;
        final hotel = appState.hotels.firstWhere((h) => h.id == widget.hotel.id, orElse: () => widget.hotel);
        final now = DateTime.now();

        // All bookings for this hotel
        final allBookings = appState.hotelBookings.where((b) => b.hotelId == hotel.id).toList();

        // 1. Arrivals Today
        final arrivals = allBookings.where((b) {
          return _isSameDay(b.checkInDate, now) && b.status != 'Cancelled' && b.status != 'Completed';
        }).toList();

        // 2. Departures Today
        final departures = allBookings.where((b) {
          return _isSameDay(b.checkOutDate, now) && b.status != 'Cancelled';
        }).toList();

        // 3. In-House (Active or Checked-In stays)
        final inHouse = allBookings.where((b) {
          final isBetween = (b.checkInDate.isBefore(now) || _isSameDay(b.checkInDate, now)) &&
              (b.checkOutDate.isAfter(now) || _isSameDay(b.checkOutDate, now));
          return (b.status == 'Active' || isBetween) && b.status != 'Cancelled' && b.status != 'Completed';
        }).toList();

        final rooms = appState.getRoomsForHotel(hotel.id);

        return Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLowest,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.teal.withOpacity(0.15),
                      child: const Icon(Icons.desk, color: Colors.teal),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Front Desk: ${hotel.name}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Today: ${DateFormat('EEE, dd MMM yyyy').format(now)}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Onboard Offline / Walk-in Guest',
                      icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.teal),
                      onPressed: () {
                        RecordOfflineBookingDialog.show(
                          context,
                          appState,
                          hotels: [hotel],
                        );
                      },
                    ),
                    IconButton(
                      tooltip: 'Live Customer View',
                      icon: const Icon(Icons.remove_red_eye_outlined, color: Colors.teal),
                      onPressed: () {
                        showHotelDetailsModal(context, appState, hotel, isHostView: false);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Tab Bar: Arrivals, In-House, Departures, All Stays, Rooms
              TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: Colors.teal,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.teal,
                tabs: [
                  Tab(text: 'Arrivals (${arrivals.length})'),
                  Tab(text: 'In-House (${inHouse.length})'),
                  Tab(text: 'Departures (${departures.length})'),
                  Tab(text: 'All Stays (${allBookings.length})'),
                  Tab(text: 'Rooms (${rooms.length})'),
                ],
              ),

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.teal))
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildBookingsList(context, arrivals, 'No arrivals scheduled for today.', 'Check-In'),
                          _buildBookingsList(context, inHouse, 'No in-house guests at the moment.', 'Manage'),
                          _buildBookingsList(context, departures, 'No departures scheduled for today.', 'Check-Out'),
                          _buildBookingsList(context, allBookings, 'No bookings found for this property.', 'All'),
                          _buildRoomsManagementList(context, hotel, rooms),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBookingsList(
    BuildContext context,
    List<HotelBooking> bookings,
    String emptyMessage,
    String actionLabel,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appState = widget.appState;

    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_available, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            Text(emptyMessage, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (ctx, idx) {
        final b = bookings[idx];
        final isCheckedIn = b.checkedInAt != null;
        final isCheckedOut = b.checkedOutAt != null;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.teal),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: b.status == 'Cancelled'
                            ? Colors.red.withOpacity(0.15)
                            : b.status == 'Active'
                                ? Colors.green.withOpacity(0.15)
                                : Colors.blue.withOpacity(0.15),
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
                                  : Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '👤 ${b.guestName} (${b.guestPhone.isNotEmpty ? b.guestPhone : "No Phone"})',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '🛏️ ${b.roomType} • ${b.nights} night(s) • Total: ₹${b.totalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  '📅 ${DateFormat('dd MMM').format(b.checkInDate)} - ${DateFormat('dd MMM').format(b.checkOutDate)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (b.status == 'Cancelled') ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.25)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.cancel_outlined, size: 14, color: Colors.red),
                            const SizedBox(width: 6),
                            Text(
                              'Reservation Cancelled ${b.cancelledBy.isNotEmpty ? "by ${b.cancelledBy.toUpperCase()}" : ""}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red),
                            ),
                            if (b.cancelledAt != null) ...[
                              const Spacer(),
                              Text(
                                DateFormat('dd MMM, hh:mm a').format(b.cancelledAt!),
                                style: TextStyle(fontSize: 10, color: Colors.red.shade700),
                              ),
                            ],
                          ],
                        ),
                        if (b.cancellationReason.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Reason: ${b.cancellationReason}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.red.shade200 : Colors.red.shade900,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                if (b.guests.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '👥 Verified Guests (${b.guests.length}):',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal),
                        ),
                        const SizedBox(height: 4),
                        ...b.guests.map((g) => Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceContainerHighDark : Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.teal.withOpacity(0.2)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '• ${g.name} • Aadhaar: ${g.aadharNumber.isNotEmpty ? g.aadharNumber : "Provided"} • Ph: ${g.mobileNumber}',
                                  style: const TextStyle(fontSize: 11),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: () => showStayGuestDocumentViewer(
                                  context: context,
                                  appState: appState,
                                  booking: b,
                                  guest: g,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.visibility_outlined, size: 11, color: Colors.teal),
                                      SizedBox(width: 3),
                                      Text(
                                        'Inspect ID',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.teal),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                ],
                if (b.status != 'Cancelled' && b.status != 'Completed') ...[
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (!isCheckedOut) ...[
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Colors.redAccent),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          icon: const Icon(Icons.cancel_outlined, size: 16),
                          label: const Text('Cancel Stay', style: TextStyle(fontSize: 12)),
                          onPressed: () => _showHostCancelStayDialog(context, b),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (!isCheckedIn)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          icon: const Icon(Icons.login, size: 16),
                          label: const Text('Check-In Guest', style: TextStyle(fontSize: 12)),
                          onPressed: () async {
                            await appState.checkInHotelGuest(b.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Guest ${b.guestName} checked in!'),
                                  backgroundColor: Colors.teal,
                                ),
                              );
                              setState(() {});
                            }
                          },
                        ),
                      if (isCheckedIn && !isCheckedOut) ...[
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange,
                            side: const BorderSide(color: Colors.orange),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          icon: const Icon(Icons.logout, size: 16),
                          label: const Text('Check-Out', style: TextStyle(fontSize: 12)),
                          onPressed: () async {
                            await appState.checkOutHotelGuest(b.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Guest ${b.guestName} checked out!'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              setState(() {});
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showHostCancelStayDialog(BuildContext context, HotelBooking booking) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reasonOptions = [
      'Room Maintenance / Repair',
      'Overbooked / Inventory issue',
      'Host Personal Emergency',
      'Guest Requested Cancellation',
      'Property Temporarily Unavailable',
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
              const Expanded(
                child: Text(
                  'Cancel Guest Reservation',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
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
                  'Are you sure you want to cancel the reservation for guest "${booking.guestName}"?',
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
                      Text('Booking Ref: ${booking.bookingRef}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.teal)),
                      Text('Room(s): ${booking.roomCount} • Type: ${booking.roomType}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      Text(
                        'Dates: ${DateFormat('dd MMM').format(booking.checkInDate)} - ${DateFormat('dd MMM yyyy').format(booking.checkOutDate)} (${booking.nights} night${booking.nights > 1 ? "s" : ""})',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      Text('Total: ₹${booking.totalPrice.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Host Cancellation Reason:',
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
                    labelText: 'Additional Notes for Guest (Optional)',
                    hintText: 'Enter specific details about the cancellation...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.all(10),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 10),
                Text(
                  '⚠️ ${booking.roomCount} room(s) will be immediately restored to your available inventory and the guest will be notified.',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Keep Reservation'),
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

                await widget.appState.cancelHotelBooking(
                  booking.id,
                  byHost: true,
                  reason: finalReason,
                );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Reservation cancelled. ${booking.roomCount} room(s) restored to available inventory.',
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

  Widget _buildRoomsManagementList(BuildContext context, Hotel hotel, List<HotelRoom> rooms) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appState = widget.appState;
    final currentHotel = appState.hotels.firstWhere((h) => h.id == hotel.id, orElse: () => hotel);

    return Column(
      children: [
        // Property Room Capacity & Available to Rent Overview Banner
        Container(
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: currentHotel.availableRooms > 0
                ? Colors.teal.withOpacity(0.08)
                : Colors.red.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: currentHotel.availableRooms > 0
                  ? Colors.teal.withOpacity(0.3)
                  : Colors.red.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.meeting_room,
                color: currentHotel.availableRooms > 0 ? Colors.teal : Colors.red,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${currentHotel.availableRooms} of ${currentHotel.totalRooms} Rooms Available to Rent',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: currentHotel.availableRooms > 0 ? Colors.teal.shade900 : Colors.red.shade900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currentHotel.availableRooms > 0
                          ? 'Guests can book up to ${currentHotel.availableRooms} rooms at this stay.'
                          : 'Sold out • No rooms currently available to rent.',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  foregroundColor: Colors.teal,
                  side: BorderSide(color: Colors.teal.shade300),
                ),
                icon: const Icon(Icons.edit, size: 14),
                label: const Text('Update', style: TextStyle(fontSize: 11)),
                onPressed: () => _showQuickInventoryDialog(context, currentHotel),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Individual Room Categories (${rooms.length})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Room Type', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                onPressed: () => _showAddRoomDialog(context, currentHotel),
              ),
            ],
          ),
        ),
        Expanded(
          child: rooms.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.bed_outlined, size: 48, color: Colors.grey),
                      const SizedBox(height: 8),
                      const Text('No individual room categories added yet.'),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => _showAddRoomDialog(context, hotel),
                        child: const Text('Create First Room Category'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  itemCount: rooms.length,
                  itemBuilder: (ctx, idx) {
                    final room = rooms[idx];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      color: isDark ? AppColors.surfaceContainerHigh : Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  room.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                _buildStatusChip(context, hotel.id, room),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹${room.basePrice.toStringAsFixed(0)}/night • ${room.roomType} • Capacity: ${room.capacity} guests • Total: ${room.quantity} rooms',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.block, size: 14, color: Colors.redAccent),
                                  label: const Text('Block Dates', style: TextStyle(fontSize: 11, color: Colors.redAccent)),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.redAccent),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  ),
                                  onPressed: () => _showBlockDatesDialog(context, room),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                                  onPressed: () async {
                                    await appState.deleteHotelRoom(hotel.id, room.id);
                                    setState(() {});
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(BuildContext context, String hotelId, HotelRoom room) {
    final appState = widget.appState;

    Color color;
    switch (room.status) {
      case RoomCleanStatus.clean:
        color = Colors.green;
        break;
      case RoomCleanStatus.dirty:
        color = Colors.amber.shade800;
        break;
      case RoomCleanStatus.occupied:
        color = Colors.blue;
        break;
      case RoomCleanStatus.maintenance:
        color = Colors.red;
        break;
    }

    return PopupMenuButton<RoomCleanStatus>(
      initialValue: room.status,
      onSelected: (val) async {
        await appState.updateRoomStatus(hotelId, room.id, val);
        setState(() {});
      },
      itemBuilder: (ctx) => [
        const PopupMenuItem(value: RoomCleanStatus.clean, child: Text('🟢 Clean')),
        const PopupMenuItem(value: RoomCleanStatus.dirty, child: Text('🟡 Needs Cleaning')),
        const PopupMenuItem(value: RoomCleanStatus.occupied, child: Text('🔵 Occupied')),
        const PopupMenuItem(value: RoomCleanStatus.maintenance, child: Text('🔴 Maintenance')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              room.status.name.toUpperCase(),
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 14, color: color),
          ],
        ),
      ),
    );
  }

  void _showAddRoomDialog(BuildContext context, Hotel hotel) {
    final nameCtrl = TextEditingController(text: 'Standard Double Room');
    final priceCtrl = TextEditingController(text: hotel.pricePerNight.toStringAsFixed(0));
    final qtyCtrl = TextEditingController(text: '2');
    final capacityCtrl = TextEditingController(text: '2');
    String selectedType = 'Private Room';

    showDialog(
      context: context,
      builder: (dCtx) => StatefulBuilder(
        builder: (dCtx, setDState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add Room Type', style: TextStyle(fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Room Category Name *'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: ['Private Room', 'Double Bed Room', 'Family Room', 'Entire Homestay', 'Shared Dorm Bed']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDState(() => selectedType = v);
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Base Price / Night (₹) *'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: capacityCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Max Guests'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: qtyCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Quantity (Rooms)'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              onPressed: () async {
                final appState = widget.appState;
                final newRoom = HotelRoom(
                  id: 'room_${DateTime.now().millisecondsSinceEpoch}',
                  hotelId: hotel.id,
                  name: nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : 'Standard Room',
                  roomType: selectedType,
                  basePrice: double.tryParse(priceCtrl.text.trim()) ?? 500.0,
                  capacity: int.tryParse(capacityCtrl.text.trim()) ?? 2,
                  quantity: int.tryParse(qtyCtrl.text.trim()) ?? 1,
                );
                await appState.saveHotelRoom(newRoom);
                Navigator.pop(dCtx);
                setState(() {});
              },
              child: const Text('Save Room', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showBlockDatesDialog(BuildContext context, HotelRoom room) {
    DateTimeRange? selectedRange;
    final reasonCtrl = TextEditingController(text: 'Room Maintenance');

    showDialog(
      context: context,
      builder: (dCtx) => StatefulBuilder(
        builder: (dCtx, setDState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Block Dates: ${room.name}', style: const TextStyle(fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.date_range, color: Colors.teal),
                label: Text(
                  selectedRange == null
                      ? 'Pick Blocked Date Range'
                      : '${DateFormat('dd MMM').format(selectedRange!.start)} - ${DateFormat('dd MMM').format(selectedRange!.end)}',
                ),
                onPressed: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setDState(() => selectedRange = picked);
                  }
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: reasonCtrl,
                decoration: const InputDecoration(labelText: 'Reason for Hold'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: selectedRange == null
                  ? null
                  : () async {
                      final appState = widget.appState;
                      final block = BlockedRange(
                        id: 'block_${DateTime.now().millisecondsSinceEpoch}',
                        roomId: room.id,
                        startDate: selectedRange!.start,
                        endDate: selectedRange!.end,
                        reason: reasonCtrl.text.trim(),
                      );
                      await appState.addBlockedRange(block);
                      Navigator.pop(dCtx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Dates blocked successfully!'),
                            backgroundColor: Colors.teal,
                          ),
                        );
                      }
                    },
              child: const Text('Block Dates', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickInventoryDialog(BuildContext context, Hotel hotel) {
    int totalRooms = hotel.totalRooms;
    int availableRooms = hotel.availableRooms;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.meeting_room, color: Colors.teal),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Available Rooms: ${hotel.name}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Specify the number of rooms currently open for rent vs. your total property capacity.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.teal.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Rooms Available to Rent',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Guests and customers can book up to this number.',
                          style: TextStyle(fontSize: 11, color: Colors.black54),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton.filledTonal(
                              onPressed: availableRooms > 0
                                  ? () {
                                      setDialogState(() {
                                        availableRooms--;
                                      });
                                    }
                                  : null,
                              icon: const Icon(Icons.remove),
                            ),
                            Text(
                              '$availableRooms',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton.filledTonal(
                              onPressed: availableRooms < totalRooms
                                  ? () {
                                      setDialogState(() {
                                        availableRooms++;
                                      });
                                    }
                                  : () {
                                      setDialogState(() {
                                        availableRooms++;
                                        totalRooms = availableRooms;
                                      });
                                    },
                              icon: const Icon(Icons.add),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Property Capacity',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Total physical rooms at your stay / property.',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton.filledTonal(
                              onPressed: totalRooms > 1 && totalRooms > availableRooms
                                  ? () {
                                      setDialogState(() {
                                        totalRooms--;
                                      });
                                    }
                                  : null,
                              icon: const Icon(Icons.remove),
                            ),
                            Text(
                              '$totalRooms',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton.filledTonal(
                              onPressed: () {
                                setDialogState(() {
                                  totalRooms++;
                                });
                              },
                              icon: const Icon(Icons.add),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(dCtx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
                onPressed: isSaving
                    ? null
                    : () async {
                        setDialogState(() => isSaving = true);
                        final appState = widget.appState;
                        await appState.updateHotelRoomsInventory(
                          hotel.id,
                          totalRooms: totalRooms,
                          availableRooms: availableRooms,
                        );
                        if (context.mounted) {
                          Navigator.pop(dCtx);
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Updated inventory for ${hotel.name}: $availableRooms / $totalRooms rooms available',
                              ),
                              backgroundColor: Colors.teal,
                            ),
                          );
                        }
                      },
                child: isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save Inventory'),
              ),
            ],
          );
        },
      ),
    );
  }
}
