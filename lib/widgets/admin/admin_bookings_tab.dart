import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../theme/app_colors.dart';

class AdminBookingsTab extends StatefulWidget {
  final List<Booking> bookings;
  final Function(Booking booking, String newStatus) onUpdateStatus;

  const AdminBookingsTab({
    super.key,
    required this.bookings,
    required this.onUpdateStatus,
  });

  @override
  State<AdminBookingsTab> createState() => _AdminBookingsTabState();
}

class _AdminBookingsTabState extends State<AdminBookingsTab> {
  String _searchQuery = '';
  String _selectedStatusFilter = 'All';

  List<Booking> get _filteredBookings {
    return widget.bookings.where((b) {
      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          b.id.toLowerCase().contains(q) ||
          b.vehicleTitle.toLowerCase().contains(q) ||
          b.hostName.toLowerCase().contains(q) ||
          b.riderId.toLowerCase().contains(q);

      final matchesStatus = _selectedStatusFilter == 'All' ||
          b.status.toLowerCase() == _selectedStatusFilter.toLowerCase();

      return matchesSearch && matchesStatus;
    }).toList();
  }

  void _showChangeStatusDialog(Booking booking) {
    String current = booking.status;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Booking #${booking.id.substring(0, 8)} Status'),
          content: RadioGroup<String>(
            groupValue: current,
            onChanged: (val) {
              if (val != null) setDialogState(() => current = val);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: ['Pending', 'Confirmed', 'Active', 'Completed', 'Cancelled', 'Disputed'].map((st) {
                return RadioListTile<String>(
                  title: Text(st),
                  subtitle: Text(_getStatusDescription(st), style: const TextStyle(fontSize: 11)),
                  value: st,
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                widget.onUpdateStatus(booking, current);
              },
              child: const Text('Update Booking Status'),
            ),
          ],
        ),
      ),
    );
  }

  void _showBookingDetailsDialog(Booking booking) {
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Booking #${booking.id.substring(0, 8)} Details', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRow('Booking ID', booking.id),
              _buildRow('Vehicle', booking.vehicleTitle),
              _buildRow('Vehicle ID', booking.vehicleId),
              _buildRow('Host Name', booking.hostName),
              _buildRow('Host ID', booking.hostId),
              _buildRow('Rider UID', booking.riderId),
              _buildRow('Status', booking.status.toUpperCase()),
              _buildRow('Total Price', currencyFormatter.format(booking.totalPrice)),
              _buildRow('Unlock Passcode', booking.unlockPasscode.isNotEmpty ? booking.unlockPasscode : 'None'),
              _buildRow('Start Date', DateFormat('dd MMM yyyy, HH:mm').format(booking.startDate)),
              _buildRow('End Date', DateFormat('dd MMM yyyy, HH:mm').format(booking.endDate)),
              _buildRow('Created At', DateFormat('dd MMM yyyy, HH:mm').format(booking.createdAt)),
              if (booking.paymentIntentId.isNotEmpty)
                _buildRow('Payment ID', booking.paymentIntentId),
              if (booking.riderLatitude != null && booking.riderLongitude != null)
                _buildRow('GPS Coordinates', '${booking.riderLatitude!.toStringAsFixed(4)}, ${booking.riderLongitude!.toStringAsFixed(4)}'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        ],
      ),
    );
  }

  String _getStatusDescription(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'Payment received, waiting for rider pickup.';
      case 'active':
        return 'Active rental currently on the road.';
      case 'completed':
        return 'Vehicle successfully inspected and returned.';
      case 'cancelled':
        return 'Reservation cancelled, deposit/fee refund triggered.';
      case 'disputed':
        return 'Dispute flagged by rider or host; requires admin arbitration.';
      default:
        return 'Awaiting host acceptance or checkout completion.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final filtered = _filteredBookings;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search and Filters
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by Booking ID, Rider ID, Vehicle, or Host...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    filled: true,
                    fillColor: isDark ? AppColors.surfaceContainerLowDark : Colors.white,
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              const SizedBox(width: 12),
              // Status Filter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceContainerLowDark : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppColors.outlineVariantDark : Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedStatusFilter,
                    items: ['All', 'Pending', 'Confirmed', 'Active', 'Completed', 'Cancelled', 'Disputed'].map((st) {
                      return DropdownMenuItem(value: st, child: Text('Status: $st'));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedStatusFilter = val);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Bookings List
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No bookings found matching current filters.'))
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final b = filtered[index];
                      final isDisputed = b.status.toLowerCase() == 'disputed';
                      final isActive = b.status.toLowerCase() == 'active';

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceContainerLowDark : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDisputed
                                ? Colors.red
                                : (isActive ? Colors.green.shade600 : (isDark ? AppColors.outlineVariantDark : Colors.grey.shade200)),
                            width: isDisputed || isActive ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Vehicle Photo / Icon
                            Container(
                              width: 70,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey.shade200,
                              ),
                              child: b.vehicleImageUrl.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        b.vehicleImageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.directions_car),
                                      ),
                                    )
                                  : const Icon(Icons.directions_car, color: Colors.grey),
                            ),
                            const SizedBox(width: 14),
                            // Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        b.vehicleTitle.isNotEmpty ? b.vehicleTitle : 'Booking #${b.id.substring(0, 8)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      const SizedBox(width: 8),
                                      _buildStatusBadge(b.status),
                                      if (b.unlockPasscode.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.indigo.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text('OTP: ${b.unlockPasscode}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.indigo)),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Host: ${b.hostName} • Rider: ${b.riderId.isNotEmpty ? b.riderId.substring(0, b.riderId.length > 8 ? 8 : b.riderId.length) : "Guest"}',
                                    style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${DateFormat('dd MMM yyyy').format(b.startDate)} - ${DateFormat('dd MMM yyyy').format(b.endDate)}',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                            // Price and Action buttons
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  currencyFormatter.format(b.totalPrice),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.info_outline, size: 20),
                                      tooltip: 'Booking Details',
                                      onPressed: () => _showBookingDetailsDialog(b),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      ),
                                      onPressed: () => _showChangeStatusDialog(b),
                                      child: const Text('Override', style: TextStyle(fontSize: 11)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    switch (status.toLowerCase()) {
      case 'confirmed':
        bg = Colors.blue.withValues(alpha: 0.15);
        fg = Colors.blue.shade700;
        break;
      case 'active':
        bg = Colors.green.withValues(alpha: 0.15);
        fg = Colors.green.shade700;
        break;
      case 'completed':
        bg = Colors.teal.withValues(alpha: 0.15);
        fg = Colors.teal.shade700;
        break;
      case 'cancelled':
        bg = Colors.red.withValues(alpha: 0.15);
        fg = Colors.red.shade700;
        break;
      case 'disputed':
        bg = Colors.orange.withValues(alpha: 0.15);
        fg = Colors.orange.shade800;
        break;
      default:
        bg = Colors.grey.withValues(alpha: 0.15);
        fg = Colors.grey.shade700;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg)),
    );
  }
}
