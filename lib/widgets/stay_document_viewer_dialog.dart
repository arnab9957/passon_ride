// ignore_for_file: deprecated_member_use
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';

/// Access control helper to ensure only the booking customer and the
/// verified hotel host (after booking) can view uploaded identity documents.
bool canViewStayGuestDocuments({
  required AppState appState,
  required HotelBooking booking,
}) {
  final currentUid = appState.userProfile?.uid ?? appState.supabaseUser?.id ?? '';
  final activeAccountId = appState.activeAccountId;
  final allActiveIds = appState.allActiveUserIds;

  // 1. Customer Verification (Booking creator or mother/child profile of the booking)
  final isCustomer = (activeAccountId.isNotEmpty &&
          (booking.userId == activeAccountId ||
              booking.accountId == activeAccountId ||
              allActiveIds.contains(booking.userId) ||
              allActiveIds.contains(booking.accountId))) ||
      (currentUid.isNotEmpty && (booking.userId == currentUid || booking.accountId == currentUid));

  // 2. Hotel Owner / Host Verification (Only allowed post-booking)
  final isBookingCreated = booking.id.isNotEmpty && booking.bookingRef.isNotEmpty;
  final isHost = isBookingCreated &&
      ((activeAccountId.isNotEmpty &&
              (booking.hostId == activeAccountId || allActiveIds.contains(booking.hostId))) ||
          (currentUid.isNotEmpty && booking.hostId == currentUid) ||
          (booking.hostName.isNotEmpty &&
              appState.activeUserDisplayName != 'Guest User' &&
              booking.hostName.trim().toLowerCase() == appState.activeUserDisplayName.trim().toLowerCase()));

  return isCustomer || isHost;
}

/// Helper widget to render document scans from data URI or web CDN URLs
Widget buildAadhaarDocumentPreview(
  String urlOrDataUri, {
  double? height,
  BoxFit fit = BoxFit.contain,
}) {
  if (urlOrDataUri.isEmpty) {
    return Container(
      height: height ?? 180,
      color: Colors.grey.shade100,
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.credit_card_off, size: 40, color: Colors.grey),
          SizedBox(height: 8),
          Text('No Aadhaar document scan available', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  if (urlOrDataUri.startsWith('data:image')) {
    try {
      final commaIndex = urlOrDataUri.indexOf(',');
      final base64Data = commaIndex != -1 ? urlOrDataUri.substring(commaIndex + 1) : urlOrDataUri;
      final bytes = base64Decode(base64Data);
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          bytes,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => _buildFallbackTile(),
        ),
      );
    } catch (e) {
      debugPrint('Error decoding base64 Aadhaar document: $e');
      return _buildFallbackTile();
    }
  }

  return ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: Image.network(
      urlOrDataUri,
      height: height,
      fit: fit,
      loadingBuilder: (ctx, child, progress) {
        if (progress == null) return child;
        return Container(
          height: height ?? 200,
          color: Colors.grey.shade100,
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.teal),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => _buildFallbackTile(),
    ),
  );
}

Widget _buildFallbackTile() {
  return Container(
    height: 180,
    decoration: BoxDecoration(
      color: Colors.teal.shade50,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.teal.shade200),
    ),
    padding: const EdgeInsets.all(16),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.verified_user, size: 44, color: Colors.teal.shade700),
        const SizedBox(height: 8),
        const Text(
          'UIDAI Aadhaar Card Verified',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.teal),
        ),
        const SizedBox(height: 4),
        const Text(
          'Secure Government Digital Identity Document Record',
          style: TextStyle(fontSize: 11, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

/// Displays the secure Aadhaar inspection dialog with strict privacy access controls
void showStayGuestDocumentViewer({
  required BuildContext context,
  required AppState appState,
  required HotelBooking booking,
  required HotelGuestDetail guest,
}) {
  final isAuthorized = canViewStayGuestDocuments(appState: appState, booking: booking);
  final isDark = Theme.of(context).brightness == Brightness.dark;

  if (!isAuthorized) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.lock_person, color: Colors.redAccent, size: 28),
            SizedBox(width: 8),
            Text('Access Restricted', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: const Text(
          'Privacy & Identity Protection Policy:\n\n'
          'Uploaded Aadhaar identity documents are strictly confidential. '
          'They can only be viewed by the customer who made the reservation, '
          'and the verified hotel owner after the booking is completed.',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
    return;
  }

  // Determine role for UI clarity
  final activeAccountId = appState.activeAccountId;
  final isHostViewing = (activeAccountId.isNotEmpty &&
          (booking.hostId == activeAccountId || appState.allActiveUserIds.contains(booking.hostId))) ||
      (appState.activeUserDisplayName != 'Guest User' &&
          booking.hostName.trim().toLowerCase() == appState.activeUserDisplayName.trim().toLowerCase());

  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: isDark ? AppColors.surfaceContainerDark : Colors.white,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 550,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 18,
                        backgroundColor: Color(0xFFE0F2F1),
                        child: Icon(Icons.document_scanner, color: Colors.teal, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Aadhaar Document Proof',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              isHostViewing
                                  ? '🏨 Hotel Host Inspection • Stay Ref: ${booking.bookingRef}'
                                  : '👤 Customer Account View • Stay Ref: ${booking.bookingRef}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isHostViewing ? Colors.teal : Colors.blueGrey,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
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

            const SizedBox(height: 12),

            // Privacy badge banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.teal.withOpacity(0.25)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, size: 14, color: Colors.teal),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Strict UIDAI Confidentiality: Accessible solely to booking party & front desk.',
                      style: TextStyle(fontSize: 10.5, color: Colors.teal, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Scrollable Content: Details + Document Scan
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Guest Metadata Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceContainerHigh : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                guest.name.isNotEmpty ? guest.name : 'Guest',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.verified, size: 12, color: Colors.green),
                                    SizedBox(width: 4),
                                    Text('AI OCR Verified', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.credit_card, size: 14, color: Colors.teal),
                              const SizedBox(width: 6),
                              Text(
                                'Aadhaar: ${guest.aadharNumber.isNotEmpty ? guest.aadharNumber : "Not Specified"}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          if (guest.mobileNumber.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.phone, size: 14, color: Colors.grey),
                                const SizedBox(width: 6),
                                Text('Phone: ${guest.mobileNumber}', style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                          ],
                          if (guest.dob.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.cake, size: 14, color: Colors.grey),
                                const SizedBox(width: 6),
                                Text('DOB: ${guest.dob}', style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                          ],
                          if (guest.address.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Address: ${guest.address}',
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Document image preview section
                    const Text(
                      'Scanned Aadhaar Document / Proof:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: InteractiveViewer(
                          panEnabled: true,
                          scaleEnabled: true,
                          minScale: 0.8,
                          maxScale: 3.5,
                          child: buildAadhaarDocumentPreview(
                            guest.idProofUrl,
                            height: 240,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Center(
                      child: Text(
                        'Pinch or scroll to zoom document scan',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Actions
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Close Verification View'),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
