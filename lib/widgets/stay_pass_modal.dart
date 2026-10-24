// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import 'stay_document_viewer_dialog.dart';

void showStayPassModal(BuildContext context, AppState appState, HotelBooking booking) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceContainerDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.verified_user, color: Colors.teal, size: 24),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Stay Pass QR / PIN',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
          const SizedBox(height: 8),
          const Text(
            'Present this digital pass or 6-digit PIN to your host at the front desk for instant check-in.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // QR Code Visual Placeholder Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Simulated QR graphic
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.teal.shade200),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(Icons.qr_code_2, size: 140, color: Colors.teal.shade900),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.teal),
                        ),
                        child: const Icon(Icons.home_work, color: Colors.teal, size: 20),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  booking.bookingRef,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 6-digit PIN Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.teal.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Check-In PIN Passcode',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    Text(
                      booking.bookingRef.replaceAll(RegExp(r'[^0-9]'), '').padRight(6, '9').substring(0, 6),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                        letterSpacing: 4,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.copy, color: Colors.teal),
                  onPressed: () {
                    final pin = booking.bookingRef.replaceAll(RegExp(r'[^0-9]'), '').padRight(6, '9').substring(0, 6);
                    Clipboard.setData(ClipboardData(text: pin));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('PIN copied: $pin'), backgroundColor: Colors.teal),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Stay details summary card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceContainerHighDark : AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.hotelName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  '${booking.roomType} • ${booking.nights} night(s) • ${booking.numGuests} guest(s)',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  'Dates: ${DateFormat('dd MMM yyyy').format(booking.checkInDate)} - ${DateFormat('dd MMM yyyy').format(booking.checkOutDate)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (booking.guests.isNotEmpty) ...[
                  const Divider(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.people_outline, size: 14, color: Colors.teal),
                      const SizedBox(width: 4),
                      Text(
                        'Registered Guests (${booking.guests.length}):',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...booking.guests.map((g) => Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceContainerHighDark : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                g.name,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Aadhaar: ${g.aadharNumber.isNotEmpty ? g.aadharNumber : "Provided"}${g.mobileNumber.isNotEmpty ? " • ${g.mobileNumber}" : ""}',
                                style: const TextStyle(fontSize: 10.5, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () => showStayGuestDocumentViewer(
                            context: context,
                            appState: appState,
                            booking: booking,
                            guest: g,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.teal.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.description_outlined, size: 12, color: Colors.teal),
                                SizedBox(width: 4),
                                Text(
                                  'Aadhaar Doc',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Status:', style: TextStyle(fontSize: 12)),
                    Text(
                      booking.status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: booking.status == 'Cancelled'
                            ? Colors.red
                            : booking.status == 'Active'
                                ? Colors.green
                                : Colors.blue,
                      ),
                    ),
                  ],
                ),
                if (booking.status == 'Cancelled') ...[
                  const SizedBox(height: 10),
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
                        const Icon(Icons.cancel, color: Colors.red, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Reservation Cancelled${booking.cancelledBy.isNotEmpty ? " by ${booking.cancelledBy == "host" ? "Host" : "Guest"}" : ""}${booking.cancellationReason.isNotEmpty ? ": ${booking.cancellationReason}" : ""}',
                            style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    appState.openChatWithHost(
                      hostName: booking.hostName.isNotEmpty ? booking.hostName : (booking.hotelName.isNotEmpty ? booking.hotelName : 'Hotel Host'),
                      vehicleTitle: 'Hotel: ${booking.hotelName}',
                    );
                  },
                  icon: const Icon(Icons.chat_outlined, size: 16),
                  label: const Text('Chat with Host'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
          if (booking.status != 'Cancelled' && booking.status != 'Completed') ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                icon: const Icon(Icons.cancel_outlined, size: 16),
                label: const Text('Cancel Stay Reservation', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                onPressed: () {
                  _showStayPassCancelDialog(context, appState, booking, () {
                    Navigator.pop(ctx);
                  });
                },
              ),
            ),
          ],
          const SizedBox(height: 12),
        ],
      ),
    ),
  ),
),
);
}

void _showStayPassCancelDialog(
  BuildContext context,
  AppState appState,
  HotelBooking booking,
  VoidCallback onCancelled,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  const reasonOptions = [
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
            const Expanded(
              child: Text(
                'Cancel Stay Reservation',
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
                'Are you sure you want to cancel your stay at "${booking.hotelName}"?',
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
                  hintText: 'Enter any notes for the host...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.all(10),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 10),
              Text(
                'ℹ️ Your reservation will be cancelled and room inventory will be released back to the host.',
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
                byHost: false,
                reason: finalReason,
              );

              onCancelled();

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Stay reservation cancelled successfully.'),
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
