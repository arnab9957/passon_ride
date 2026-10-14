// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';

void showStayPassModal(BuildContext context, AppState appState, HotelBooking booking) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
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
              Row(
                children: [
                  const Icon(Icons.verified_user, color: Colors.teal, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Stay Pass QR / PIN',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
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
                  ...booking.guests.map((g) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• ${g.name}${g.aadharNumber.isNotEmpty ? ' (Aadhaar: ${g.aadharNumber})' : ''}${g.mobileNumber.isNotEmpty ? ' • ${g.mobileNumber}' : ''}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
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
                        color: booking.status == 'Active' ? Colors.green : Colors.blue,
                      ),
                    ),
                  ],
                ),
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
                    appState.setNavIndex(5); // Chat with Host
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
          const SizedBox(height: 12),
        ],
      ),
    ),
  );
}
