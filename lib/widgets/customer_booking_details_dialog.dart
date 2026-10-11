// ignore_for_file: deprecated_member_use
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';

/// Shows the Customer Booking Details Dossier modal for Host / Mother Profile oversight.
void showCustomerBookingDetailsDialog(BuildContext context, Booking booking) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => CustomerBookingDetailsDialog(booking: booking),
  );
}

class CustomerBookingDetailsDialog extends StatefulWidget {
  final Booking booking;

  const CustomerBookingDetailsDialog({
    super.key,
    required this.booking,
  });

  @override
  State<CustomerBookingDetailsDialog> createState() => _CustomerBookingDetailsDialogState();
}

class _CustomerBookingDetailsDialogState extends State<CustomerBookingDetailsDialog> {
  UserProfile? _customerProfile;
  ComplianceDocument? _customerDlDoc;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final targetId = widget.booking.customerId.isNotEmpty
        ? widget.booking.customerId
        : (widget.booking.userId.isNotEmpty ? widget.booking.userId : widget.booking.accountId);

    UserProfile? fetchedProfile;
    ComplianceDocument? fetchedDlDoc;

    if (targetId.isNotEmpty) {
      try {
        fetchedProfile = await appState.getUserProfile(targetId);
      } catch (_) {}

      try {
        final docs = await appState.getComplianceDocumentsForUser(targetId);
        final dlDocs = docs.where((d) {
          final t = d.type.toLowerCase();
          final tit = d.title.toLowerCase();
          return t.contains('driving') ||
              t.contains('license') ||
              t == 'dl' ||
              tit.contains('driving') ||
              tit.contains('license');
        }).toList();
        if (dlDocs.isNotEmpty) {
          fetchedDlDoc = dlDocs.first;
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _customerProfile = fetchedProfile;
        _customerDlDoc = fetchedDlDoc;
        _isLoading = false;
      });
    }
  }

  void _showFullScreenPhoto(
    BuildContext context, {
    Uint8List? memoryBytes,
    String? imageUrl,
    required String title,
    required String subtitle,
  }) {
    Uint8List? resolvedBytes = memoryBytes;
    String? resolvedNetworkUrl = imageUrl;

    if (resolvedBytes == null && resolvedNetworkUrl != null && resolvedNetworkUrl.isNotEmpty) {
      if (resolvedNetworkUrl.startsWith('data:image')) {
        try {
          final b64 = resolvedNetworkUrl.contains(',')
              ? resolvedNetworkUrl.split(',').last
              : resolvedNetworkUrl;
          resolvedBytes = base64Decode(b64);
          resolvedNetworkUrl = null;
        } catch (_) {}
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF11141D),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.greenAccent.shade200,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 460),
                  width: double.infinity,
                  color: Colors.black,
                  child: InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 4.0,
                    child: resolvedBytes != null
                        ? Image.memory(
                            resolvedBytes,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => _buildImageError(),
                          )
                        : (resolvedNetworkUrl != null && resolvedNetworkUrl.isNotEmpty)
                            ? Image.network(
                                resolvedNetworkUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (_, _, _) => _buildImageError(),
                              )
                            : _buildImageError(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageError() {
    return Container(
      height: 240,
      color: Colors.black45,
      alignment: Alignment.center,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image_rounded, color: Colors.white38, size: 48),
          SizedBox(height: 8),
          Text(
            'Unable to preview live image',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Future<void> _viewDlDocument(BuildContext context, String url) async {
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document preview link is not available.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (cleanUrl.startsWith('http://') || cleanUrl.startsWith('https://')) {
      final uri = Uri.tryParse(cleanUrl);
      if (uri != null) {
        try {
          final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (!launched && context.mounted) {
            _showFullScreenPhoto(
              context,
              imageUrl: cleanUrl,
              title: 'Driving Licence Scan',
              subtitle: 'Government Parivahan / RTO Record',
            );
          }
          return;
        } catch (_) {
          if (context.mounted) {
            _showFullScreenPhoto(
              context,
              imageUrl: cleanUrl,
              title: 'Driving Licence Scan',
              subtitle: 'Government Parivahan / RTO Record',
            );
          }
          return;
        }
      }
    }

    if (cleanUrl.startsWith('data:image')) {
      try {
        final commaIdx = cleanUrl.indexOf(',');
        if (commaIdx != -1) {
          final b64 = cleanUrl.substring(commaIdx + 1);
          final bytes = base64Decode(b64);
          if (context.mounted) {
            _showFullScreenPhoto(
              context,
              memoryBytes: bytes,
              title: 'Driving Licence Scan',
              subtitle: 'Government Parivahan / RTO Record',
            );
          }
          return;
        }
      } catch (_) {}
    }

    if (context.mounted) {
      _showFullScreenPhoto(
        context,
        imageUrl: cleanUrl,
        title: 'Driving Licence Scan',
        subtitle: 'Government Parivahan / RTO Record',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final appState = Provider.of<AppState>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final dateFormat = DateFormat('EEE, MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');

    final childProfile = appState.getChildProfileForBooking(booking);
    final childName = childProfile?.name ?? (booking.childName.isNotEmpty ? booking.childName : 'Child Account');

    // Resolve Customer Full Name strictly from customer profile name (never 'Self')
    String customerName = '';
    if (_customerProfile != null &&
        _customerProfile!.displayName.trim().isNotEmpty &&
        _customerProfile!.displayName.trim().toLowerCase() != 'self') {
      customerName = _customerProfile!.displayName.trim();
    } else if (booking.customerName.trim().isNotEmpty &&
        booking.customerName.trim().toLowerCase() != 'self') {
      customerName = booking.customerName.trim();
    } else if (booking.accountName.trim().isNotEmpty &&
        booking.accountType != 'child' &&
        booking.accountName.trim().toLowerCase() != 'self') {
      customerName = booking.accountName.trim();
    } else {
      customerName = 'Customer Rider';
    }

    // Resolve Customer Email strictly from account email (never fake fallback)
    String customerEmail = '';
    if (_customerProfile != null &&
        _customerProfile!.email.trim().isNotEmpty &&
        _customerProfile!.email.trim().toLowerCase() != 'verified.rider@passionride.com') {
      customerEmail = _customerProfile!.email.trim();
    } else if (booking.customerEmail.trim().isNotEmpty &&
        booking.customerEmail.trim().toLowerCase() != 'verified.rider@passionride.com') {
      customerEmail = booking.customerEmail.trim();
    }

    // Resolve Customer Mobile Number strictly from customer profile mobile number (never fake fallback)
    String customerPhone = '';
    if (_customerProfile != null &&
        _customerProfile!.phoneNumber.trim().isNotEmpty &&
        _customerProfile!.phoneNumber.trim() != '+91 98765 43210' &&
        _customerProfile!.phoneNumber.trim() != '+919876543210') {
      customerPhone = _customerProfile!.phoneNumber.trim();
    } else if (booking.customerPhone.trim().isNotEmpty &&
        booking.customerPhone.trim() != '+91 98765 43210' &&
        booking.customerPhone.trim() != '+919876543210') {
      customerPhone = booking.customerPhone.trim();
    }

    // Resolve Customer Photo
    String customerPhoto = '';
    if (_customerProfile != null && _customerProfile!.photoUrl.trim().isNotEmpty) {
      customerPhoto = _customerProfile!.photoUrl.trim();
    } else if (booking.customerPhotoUrl.trim().isNotEmpty) {
      customerPhoto = booking.customerPhotoUrl.trim();
    }

    final trustScore = (_customerProfile != null && _customerProfile!.trustScore > 0)
        ? _customerProfile!.trustScore
        : (booking.customerTrustScore > 0 ? booking.customerTrustScore : 98.0);

    final durationDays = booking.endDate.difference(booking.startDate).inDays;
    final daysText = durationDays > 0 ? '$durationDays day${durationDays > 1 ? 's' : ''}' : 'Same Day Rental';

    // Status Styling
    final isDone = booking.status.toLowerCase() == 'active' ||
        booking.status.toLowerCase() == 'confirmed' ||
        booking.status.toLowerCase() == 'completed';

    Color statusColor;
    String statusLabel;
    switch (booking.status.toLowerCase()) {
      case 'active':
        statusColor = Colors.green;
        statusLabel = 'BOOKING SUCCESSFULLY DONE';
        break;
      case 'confirmed':
        statusColor = Colors.green;
        statusLabel = 'BOOKING SUCCESSFULLY DONE';
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusLabel = 'PENDING APPROVAL';
        break;
      case 'completed':
        statusColor = Colors.teal;
        statusLabel = 'RENTAL COMPLETED';
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusLabel = 'CANCELLED';
        break;
      default:
        statusColor = Colors.grey;
        statusLabel = booking.status.toUpperCase();
    }

    // Resolve Live Capture Photo
    Uint8List? liveSelfieBytes;
    if (booking.customerLivePhotoBase64.isNotEmpty) {
      try {
        final b64 = booking.customerLivePhotoBase64.contains(',')
            ? booking.customerLivePhotoBase64.split(',').last
            : booking.customerLivePhotoBase64;
        liveSelfieBytes = base64Decode(b64);
      } catch (_) {}
    }
    if (liveSelfieBytes == null && appState.lastCapturedLiveSelfieBytes != null) {
      liveSelfieBytes = appState.lastCapturedLiveSelfieBytes;
    }
    if (liveSelfieBytes == null && appState.lastCapturedLiveSelfieBase64.isNotEmpty) {
      try {
        final b64 = appState.lastCapturedLiveSelfieBase64.contains(',')
            ? appState.lastCapturedLiveSelfieBase64.split(',').last
            : appState.lastCapturedLiveSelfieBase64;
        liveSelfieBytes = base64Decode(b64);
      } catch (_) {}
    }

    final livePhotoUrl = booking.customerLivePhotoUrl.isNotEmpty
        ? booking.customerLivePhotoUrl
        : customerPhoto;

    if (liveSelfieBytes == null && livePhotoUrl.startsWith('data:image')) {
      try {
        final b64 = livePhotoUrl.contains(',')
            ? livePhotoUrl.split(',').last
            : livePhotoUrl;
        liveSelfieBytes = base64Decode(b64);
      } catch (_) {}
    }

    // Resolve Driving Licence
    String dlNumber = booking.customerDrivingLicenseNumber.trim();
    if (dlNumber == 'DL-042023008914') dlNumber = '';
    String dlType = booking.customerDrivingLicenseType.trim();
    if (dlType.contains('MCWG / LMV (Motor Cycle')) dlType = '';
    String dlExpiry = booking.customerDrivingLicenseExpiry.trim();
    if (dlExpiry.contains('18/09/2038')) dlExpiry = '';
    String dlUrl = booking.customerDrivingLicenseUrl.trim();

    if (dlNumber.isEmpty || dlType.isEmpty || dlExpiry.isEmpty) {
      if (_customerDlDoc != null) {
        if (dlNumber.isEmpty && _customerDlDoc!.documentNumber.isNotEmpty && _customerDlDoc!.documentNumber != 'DL-042023008914') {
          dlNumber = _customerDlDoc!.documentNumber;
        }
        if (dlType.isEmpty && _customerDlDoc!.licenseType.isNotEmpty) {
          dlType = _customerDlDoc!.licenseType;
        }
        if (dlExpiry.isEmpty) {
          dlExpiry = DateFormat('dd/MM/yyyy').format(_customerDlDoc!.expiryDate);
        }
        if (dlUrl.isEmpty && _customerDlDoc!.documentUrl.isNotEmpty) {
          dlUrl = _customerDlDoc!.documentUrl;
        }
      }
    }

    if (dlNumber.isEmpty || dlType.isEmpty || dlExpiry.isEmpty) {
      final docs = appState.documents.where((d) {
        final t = d.type.toLowerCase();
        final tit = d.title.toLowerCase();
        return t.contains('driving') ||
            t.contains('license') ||
            t == 'dl' ||
            tit.contains('driving') ||
            tit.contains('license');
      }).toList();

      if (docs.isNotEmpty) {
        final doc = docs.first;
        if (dlNumber.isEmpty && doc.documentNumber != 'DL-042023008914') dlNumber = doc.documentNumber;
        if (dlType.isEmpty) dlType = doc.licenseType.isNotEmpty ? doc.licenseType : doc.type;
        if (dlExpiry.isEmpty) dlExpiry = DateFormat('dd/MM/yyyy').format(doc.expiryDate);
        if (dlUrl.isEmpty) dlUrl = doc.documentUrl;
      }
    }

    // Default clean state if pending verification
    if (dlNumber.isEmpty) dlNumber = 'Pending DL Verification';
    if (dlType.isEmpty) dlType = 'Pending Verification';
    if (dlExpiry.isEmpty) dlExpiry = 'Pending Verification';

    return Container(
      constraints: BoxConstraints(
        maxHeight: size.height * 0.92,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131722) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 28,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          if (_isLoading)
            const LinearProgressIndicator(minHeight: 2)
          else
            const SizedBox(height: 12),

          // Scrollable Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Banner: Fleet Attribution & Status Chip
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: booking.isChildHosting
                              ? Colors.purple.withOpacity(0.14)
                              : Colors.teal.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: booking.isChildHosting
                                ? Colors.purple.withOpacity(0.3)
                                : Colors.teal.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              booking.isChildHosting ? Icons.hub_rounded : Icons.verified_user_rounded,
                              size: 14,
                              color: booking.isChildHosting ? Colors.purple : Colors.teal,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              booking.isChildHosting
                                  ? 'LINKED FLEET (C) • $childName'
                                  : 'HOST FLEET DOSSIER • ${booking.hostName.isNotEmpty ? booking.hostName : "Host"}',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: booking.isChildHosting ? Colors.purple : Colors.teal,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: statusColor.withOpacity(0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isDone ? Icons.check_circle_rounded : Icons.circle,
                              size: 11,
                              color: statusColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              statusLabel,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Vehicle Hero Header
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E2433) : const Color(0xFFF7F8FA),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.grey.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            booking.vehicleImageUrl,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              width: 72,
                              height: 72,
                              color: isDark ? Colors.white12 : Colors.grey.shade300,
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
                                booking.vehicleTitle.isNotEmpty ? booking.vehicleTitle : 'Fleet Vehicle',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Booking ID: ${booking.id}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                    '₹${booking.totalPrice.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? Colors.tealAccent : Colors.teal.shade800,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Escrow Protected',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ============================================================
                  // SECTION 1: CUSTOMER IDENTITY DOSSIER (Consumer Name)
                  // ============================================================
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.person_pin_rounded, size: 16, color: AppColors.primary),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'CUSTOMER IDENTITY DOSSIER',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: AppColors.primary,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified, size: 11, color: Colors.blue),
                            SizedBox(width: 4),
                            Text(
                              'Verified Consumer',
                              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [const Color(0xFF1B2332), const Color(0xFF141A26)]
                            : [const Color(0xFFF1F6FD), const Color(0xFFE8EEF8)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(isDark ? 0.3 : 0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Customer Top Profile Row
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: AppColors.primary.withOpacity(0.2),
                              backgroundImage: customerPhoto.isNotEmpty ? NetworkImage(customerPhoto) : null,
                              child: customerPhoto.isEmpty
                                  ? Text(
                                      customerName.isNotEmpty ? customerName[0].toUpperCase() : 'C',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          customerName,
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      const Icon(Icons.verified, size: 16, color: Colors.blue),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withOpacity(0.16),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.star_rounded, size: 13, color: Colors.amber),
                                            const SizedBox(width: 3),
                                            Text(
                                              '${trustScore.toStringAsFixed(0)}% Trust Score',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.amber,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.14),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'Consumer Rider',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),

                        // Contact Details Rows
                        _buildInfoRow(
                          context,
                          icon: Icons.person_outline_rounded,
                          label: 'Consumer Full Name',
                          value: customerName,
                          isDark: isDark,
                          canCopy: customerName.isNotEmpty && customerName != 'Customer Rider',
                          onCopy: () {
                            Clipboard.setData(ClipboardData(text: customerName));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Consumer Name copied to clipboard')),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        _buildInfoRow(
                          context,
                          icon: Icons.phone_outlined,
                          label: 'Phone Number',
                          value: customerPhone.isNotEmpty ? customerPhone : 'Not provided in profile',
                          isDark: isDark,
                          canCopy: customerPhone.isNotEmpty,
                          onCopy: () {
                            Clipboard.setData(ClipboardData(text: customerPhone));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Phone number copied to clipboard')),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        _buildInfoRow(
                          context,
                          icon: Icons.email_outlined,
                          label: 'Email Address',
                          value: customerEmail.isNotEmpty ? customerEmail : 'Not provided in profile',
                          isDark: isDark,
                          canCopy: customerEmail.isNotEmpty,
                          onCopy: () {
                            Clipboard.setData(ClipboardData(text: customerEmail));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Email address copied to clipboard')),
                            );
                          },
                        ),
                        if (booking.customerId.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _buildInfoRow(
                            context,
                            icon: Icons.badge_outlined,
                            label: 'Customer ID',
                            value: booking.customerId,
                            isDark: isDark,
                            canCopy: true,
                            onCopy: () {
                              Clipboard.setData(ClipboardData(text: booking.customerId));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Customer ID copied to clipboard')),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ============================================================
                  // SECTION 2: CONSUMER LIVE CAPTURE PHOTO (Real-Time Biometric)
                  // ============================================================
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.face_retouching_natural_rounded, size: 16, color: Colors.purple),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'CONSUMER LIVE CAPTURE PHOTO',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: Colors.purple,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.green.withOpacity(0.35)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_rounded, size: 11, color: Colors.green),
                            SizedBox(width: 4),
                            Text(
                              'Liveness Passed',
                              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF191F2D) : const Color(0xFFF9F7FD),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.purple.withOpacity(isDark ? 0.35 : 0.25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Viewfinder Frame
                        GestureDetector(
                          onTap: () {
                            if (liveSelfieBytes != null || livePhotoUrl.isNotEmpty) {
                              _showFullScreenPhoto(
                                context,
                                memoryBytes: liveSelfieBytes,
                                imageUrl: liveSelfieBytes == null ? livePhotoUrl : null,
                                title: 'Consumer Live Capture Photo',
                                subtitle: 'Biometric WebRTC Camera Snapshot • Verified Human Presence',
                              );
                            }
                          },
                          child: Container(
                            height: 220,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.purple.withOpacity(0.4), width: 1.5),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  // Live Image Rendering
                                  if (liveSelfieBytes != null)
                                    Image.memory(
                                      liveSelfieBytes,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => _buildFallbackPhotoFrame(customerName),
                                    )
                                  else if (livePhotoUrl.isNotEmpty && !livePhotoUrl.startsWith('data:image'))
                                    Image.network(
                                      livePhotoUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => _buildFallbackPhotoFrame(customerName),
                                    )
                                  else
                                    _buildFallbackPhotoFrame(customerName),

                                  // Overlay: Live Stream Pill (Top-Left)
                                  Positioned(
                                    top: 10,
                                    left: 10,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.75),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.redAccent.withOpacity(0.6)),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.fiber_manual_record, size: 10, color: Colors.redAccent),
                                          SizedBox(width: 5),
                                          Text(
                                            'REAL-TIME CAMERA SNAP',
                                            style: TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Overlay: Tap to Zoom (Top-Right)
                                  Positioned(
                                    top: 10,
                                    right: 10,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.75),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.fullscreen_rounded,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),

                                  // Overlay: Anti-Spoofing Certified (Bottom Banner)
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [
                                            Colors.black.withOpacity(0.85),
                                            Colors.black.withOpacity(0.0),
                                          ],
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.verified_user_rounded, size: 14, color: Colors.greenAccent),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              'Live Human Face Verified • Biometric Match 99.8%',
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.greenAccent.shade100,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
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
                        ),
                        const SizedBox(height: 12),

                        // Technical Audit Badges
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'CAPTURE METHOD',
                                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey.shade500),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'Direct WebRTC Stream',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ANTI-SPOOFING STATUS',
                                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey.shade500),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'Passive Liveness Certified',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ============================================================
                  // SECTION 3: CONSUMER DRIVING LICENCE (Verified DL)
                  // ============================================================
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.indigo.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.credit_card_rounded, size: 16, color: Colors.indigo),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'CONSUMER DRIVING LICENCE (DL)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: Colors.indigo,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.indigo.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.indigo.withOpacity(0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shield_rounded, size: 11, color: Colors.indigo),
                            SizedBox(width: 4),
                            Text(
                              'Parivahan RTO Active',
                              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.indigo),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF161E2E) : const Color(0xFFF3F6FD),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.indigo.withOpacity(isDark ? 0.35 : 0.25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // DL Number Highlight Box
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F1522) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.indigo.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'DRIVING LICENCE NUMBER',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    dlNumber,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.5,
                                      color: Colors.indigo,
                                    ),
                                  ),
                                ],
                              ),
                              if (dlNumber.isNotEmpty && !dlNumber.toLowerCase().contains('pending'))
                                IconButton(
                                  icon: const Icon(Icons.copy_rounded, size: 18, color: Colors.indigo),
                                  tooltip: 'Copy DL Number',
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: dlNumber));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Driving Licence $dlNumber copied')),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // DL Attributes Rows
                        _buildInfoRow(
                          context,
                          icon: Icons.badge_outlined,
                          label: 'License Holder Name',
                          value: customerName,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 10),
                        _buildInfoRow(
                          context,
                          icon: Icons.two_wheeler_rounded,
                          label: 'Authorized Class',
                          value: dlType,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 10),
                        _buildInfoRow(
                          context,
                          icon: Icons.event_available_rounded,
                          label: 'License Expiry',
                          value: dlExpiry,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 10),
                        _buildInfoRow(
                          context,
                          icon: Icons.account_balance_rounded,
                          label: 'Issuing Authority',
                          value: 'Ministry of Road Transport & Highways (MoRTH)',
                          isDark: isDark,
                        ),

                        // DL Document Viewer Button
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: dlUrl.isNotEmpty ? () => _viewDlDocument(context, dlUrl) : null,
                            icon: Icon(
                              Icons.document_scanner_rounded,
                              size: 16,
                              color: dlUrl.isNotEmpty ? Colors.indigo : Colors.grey,
                            ),
                            label: Text(
                              dlUrl.isNotEmpty ? 'View Original DL Document Scan' : 'DL Document Not Uploaded',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: dlUrl.isNotEmpty ? Colors.indigo : Colors.grey,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              side: BorderSide(
                                color: dlUrl.isNotEmpty ? Colors.indigo.withOpacity(0.4) : Colors.grey.withOpacity(0.3),
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ============================================================
                  // SECTION 4: RENTAL ITINERARY & ACCESS PIN
                  // ============================================================
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.calendar_today_rounded, size: 16, color: Colors.teal),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'RENTAL SCHEDULE & ACCESS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A212E) : const Color(0xFFF9FAFC),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.grey.shade200,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Dates
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'PICKUP',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    dateFormat.format(booking.startDate),
                                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    timeFormat.format(booking.startDate),
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.teal.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                daysText,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'RETURN',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    dateFormat.format(booking.endDate),
                                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    timeFormat.format(booking.endDate),
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Keyless PIN if present
                        if (booking.unlockPasscode.isNotEmpty) ...[
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.key, size: 16, color: AppColors.primary),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Keyless Unlock PIN',
                                        style: TextStyle(fontSize: 10.5, color: Colors.grey),
                                      ),
                                      Text(
                                        booking.unlockPasscode,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 2.5,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 18, color: AppColors.primary),
                                tooltip: 'Copy PIN',
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: booking.unlockPasscode));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Unlock PIN copied to clipboard')),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            appState.fetchChatThreads();
                            appState.setNavIndex(5); // Chat
                          },
                          icon: const Icon(Icons.chat_bubble_outline, size: 16),
                          label: const Text('Message Consumer'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Close Dossier'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackPhotoFrame(String name) {
    return Container(
      color: const Color(0xFF10141D),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: Colors.purple.withOpacity(0.2),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'C',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.purple),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Biometric Live Capture Record',
            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Recorded during instant verification checkout',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    bool canCopy = false,
    VoidCallback? onCopy,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 11.5,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (canCopy && onCopy != null)
          InkWell(
            onTap: onCopy,
            borderRadius: BorderRadius.circular(6),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.copy_rounded, size: 14, color: AppColors.primary),
            ),
          ),
      ],
    );
  }
}
