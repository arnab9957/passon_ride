// ignore_for_file: deprecated_member_use, unused_local_variable
import 'whatsapp_button.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import '../services/document_ocr_service.dart';
import '../services/imagekit_service.dart';
import 'auto_sliding_image_carousel.dart';
import 'stay_pass_modal.dart';
import 'stay_document_viewer_dialog.dart';
import 'supabase_auth_dialog.dart';

void showHotelDetailsModal(
  BuildContext context,
  AppState appState,
  Hotel hotel, {
  bool isHostView = false,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final galleryImages = hotel.images.isNotEmpty ? hotel.images : [hotel.imageUrl];
  final currentUid = appState.userProfile?.uid ?? appState.supabaseUser?.id ?? '';
  final isMyHotel = (currentUid.isNotEmpty && hotel.hostId == currentUid) ||
      (hotel.hostName.isNotEmpty &&
          appState.activeUserDisplayName != 'Guest User' &&
          hotel.hostName == appState.activeUserDisplayName) ||
      hotel.hostId.isEmpty;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Container(
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

            Expanded(
              child: Stack(
  children: [
    Positioned.fill(child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Carousel Header
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: AutoSlidingImageCarousel(
                            images: galleryImages,
                            height: 220,
                            fallbackIcon: Icons.holiday_village,
                          ),
                        ),
                        PositionmentBadge(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  '${formatRating(hotel.rating, hotel.reviewCount)} (${hotel.reviewCount} reviews)',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Title & Room Type
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hotel.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 15, color: Colors.redAccent),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      hotel.location,
                                      style: TextStyle(
                                        color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                                        fontSize: 13,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${hotel.pricePerNight.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const Text(
                                'per night',
                                style: TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Direct Community Stay Banner
                    // Container(
                    //   padding: const EdgeInsets.all(12),
                    //   decoration: BoxDecoration(
                    //     gradient: LinearGradient(
                    //       colors: isDark
                    //           ? [Colors.teal.shade900.withOpacity(0.4), Colors.blueGrey.shade900.withOpacity(0.4)]
                    //           : [Colors.teal.shade50, Colors.cyan.shade50],
                    //     ),
                    //     borderRadius: BorderRadius.circular(14),
                    //     border: Border.all(color: Colors.teal.withOpacity(0.3)),
                    //   ),
                    //   child: Row(
                    //     children: [
                    //       const Icon(Icons.verified_user_outlined, color: Colors.teal, size: 24),
                    //       const SizedBox(width: 10),
                    //       const Expanded(
                    //         child: Column(
                    //           crossAxisAlignment: CrossAxisAlignment.start,
                    //           children: [
                    //             Text(
                    //               'Direct Local Host • 0% Middleman Margin',
                    //               style: TextStyle(
                    //                 fontSize: 12,
                    //                 fontWeight: FontWeight.bold,
                    //                 color: Colors.teal,
                    //               ),
                    //             ),
                    //             SizedBox(height: 2),
                    //             Text(
                    //               '100% of your payment goes directly to empower this local resident and family.',
                    //               style: TextStyle(fontSize: 11, color: Colors.grey),
                    //             ),
                    //           ],
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ),

                    const SizedBox(height: 16),

                    // Quick Specs
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isNarrow = constraints.maxWidth < 420;
                        if (isNarrow) {
                          return Column(
                            children: [
                              Row(
                                children: [
                                  _buildSpecChip(
                                    icon: Icons.bedroom_parent_outlined,
                                    title: 'Room Type',
                                    value: hotel.roomType,
                                    isDark: isDark,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildSpecChip(
                                    icon: Icons.meeting_room_outlined,
                                    title: 'Available',
                                    value: '${hotel.availableRooms}/${hotel.totalRooms} Rms',
                                    isDark: isDark,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _buildSpecChip(
                                    icon: Icons.people_outline,
                                    title: 'Guests',
                                    value: 'Max ${hotel.maxGuests}',
                                    isDark: isDark,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildSpecChip(
                                    icon: Icons.access_time,
                                    title: 'Check-In',
                                    value: hotel.checkInTime,
                                    isDark: isDark,
                                  ),
                                ],
                              ),
                            ],
                          );
                        }
                        return Row(
                          children: [
                            _buildSpecChip(
                              icon: Icons.bedroom_parent_outlined,
                              title: 'Room Type',
                              value: hotel.roomType,
                              isDark: isDark,
                            ),
                            const SizedBox(width: 6),
                            _buildSpecChip(
                              icon: Icons.meeting_room_outlined,
                              title: 'Available',
                              value: '${hotel.availableRooms}/${hotel.totalRooms} Rms',
                              isDark: isDark,
                            ),
                            const SizedBox(width: 6),
                            _buildSpecChip(
                              icon: Icons.people_outline,
                              title: 'Guests',
                              value: 'Max ${hotel.maxGuests}',
                              isDark: isDark,
                            ),
                            const SizedBox(width: 6),
                            _buildSpecChip(
                              icon: Icons.access_time,
                              title: 'Check-In',
                              value: hotel.checkInTime,
                              isDark: isDark,
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 18),

                    // Description
                    const Text(
                      'About This Stay & Homestay',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      hotel.description.isNotEmpty
                          ? hotel.description
                          : 'Comfortable, clean, budget-friendly accommodation hosted by a welcoming local family.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: isDark ? Colors.grey.shade300 : Colors.black87,
                      ),
                    ),

                    if (hotel.address.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.pin_drop_outlined, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Address / Landmark: ${hotel.address}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (hotel.latitude != 0.0 && hotel.longitude != 0.0) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceContainerHighDark : Colors.teal.shade50.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.teal.withOpacity(0.25)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.explore_outlined, size: 16, color: Colors.teal),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'GPS: ${hotel.latitude.toStringAsFixed(5)}, ${hotel.longitude.toStringAsFixed(5)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.teal.shade200 : Colors.teal.shade800,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () async {
                                final uri = Uri.parse(
                                    'https://www.google.com/maps/search/?api=1&query=${hotel.latitude},${hotel.longitude}');
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.teal,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.directions, color: Colors.white, size: 13),
                                    SizedBox(width: 4),
                                    Text(
                                      'Open Map',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 18),

                    // Amenities
                    if (hotel.amenities.isNotEmpty) ...[
                      const Text(
                        'Available Amenities & Facilities',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: hotel.amenities.map((amenity) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.surfaceContainerHighDark
                                  : AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.outlineVariantDark
                                    : AppColors.outlineVariantLight,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getAmenityIcon(amenity),
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  amenity,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Room Categories Showcase (if available)
                    if (appState.getRoomsForHotel(hotel.id).isNotEmpty) ...[
                      const Text(
                        'Room Options & Availability',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...appState.getRoomsForHotel(hotel.id).map((room) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceContainerHighDark : Colors.teal.shade50.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.teal.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.meeting_room_outlined, color: Colors.teal, size: 24),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      room.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    Text(
                                      '${room.roomType} • Up to ${room.capacity} guests • ${room.quantity} room(s)',
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '₹${room.basePrice.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal,
                                    ),
                                  ),
                                  const Text('per night', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                    ],

                    // House Rules & Stay Info Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceContainerHighDark : AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.rule_outlined, size: 18, color: Colors.teal),
                              SizedBox(width: 8),
                              Text('House Rules & Stay Policy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.login, size: 14, color: Colors.grey),
                              const SizedBox(width: 6),
                              Text('Check-In: ${hotel.checkInTime}', style: const TextStyle(fontSize: 12)),
                              const SizedBox(width: 16),
                              const Icon(Icons.logout, size: 14, color: Colors.grey),
                              const SizedBox(width: 6),
                              Text('Check-Out: ${hotel.checkOutTime}', style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Row(
                            children: [
                              Icon(Icons.wifi, size: 14, color: Colors.teal),
                              SizedBox(width: 6),
                              Text('Complimentary Wi-Fi provided at Front Desk', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Row(
                            children: [
                              Icon(Icons.smoke_free, size: 14, color: Colors.grey),
                              SizedBox(width: 6),
                              Text('No smoking inside bedrooms • Quiet hours after 10 PM', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Host Profile Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceContainerHighDark : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppColors.outlineVariantDark : Colors.grey.shade200,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: AppColors.primary.withOpacity(0.15),
                                backgroundImage: (hotel.hostAvatar.isNotEmpty &&
                                        !hotel.hostAvatar.contains('unsplash.com'))
                                    ? NetworkImage(hotel.hostAvatar)
                                    : null,
                                child: (hotel.hostAvatar.isEmpty ||
                                        hotel.hostAvatar.contains('unsplash.com'))
                                    ? const Icon(Icons.person, color: AppColors.primary)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      hotel.hostName.isNotEmpty ? hotel.hostName : 'Local Host',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Text(
                                      'Verified Rural / Local Resident Host',
                                      style: TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (hotel.hostPhone.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      appState.openChatWithHost(
                                        hostName: hotel.hostName.isNotEmpty ? hotel.hostName : 'Stay Host',
                                        partnerUserId: hotel.hostId,
                                        hostAvatar: hotel.hostAvatar,
                                        vehicleTitle: 'Stay: ${hotel.name}',
                                        hostPhone: hotel.hostPhone,
                                      );
                                    },
                                    icon: const Icon(Icons.chat_bubble_outline, size: 15),
                                    label: const Text('Chat with Host', style: TextStyle(fontSize: 12)),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      side: const BorderSide(color: Colors.green),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    final uri = Uri.parse('tel:${hotel.hostPhone.replaceAll(' ', '')}');
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri);
                                    } else {
                                      Clipboard.setData(ClipboardData(text: hotel.hostPhone));
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Host Phone copied: ${hotel.hostPhone}'),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  icon: const Icon(Icons.phone, size: 15, color: Colors.green),
                                  label: const Text('Call', style: TextStyle(fontSize: 12, color: Colors.green)),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    side: const BorderSide(color: Colors.green),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                IconButton(
                                  tooltip: 'Copy Number',
                                  icon: const Icon(Icons.copy, size: 18),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: hotel.hostPhone));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Host Phone copied: ${hotel.hostPhone}'),
                                      ),
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
                  ],
                ),
              )),
    Positioned(
  right: 16,
  bottom: 16,
  child: WhatsAppFloatingButton(
    phone: hotel.hostPhone,
    hostId: hotel.hostId,
    message: 'Hello! I am interested in ${hotel.name} on PassionRide.',
  ),
),
  ],
),
            ),

            // Bottom Action Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceContainerDark : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '₹${hotel.pricePerNight.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const Text(
                          'total / night',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: hotel.availableRooms <= 0
                            ? () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('⚠️ Sorry, this stay currently has 0 rooms available to rent.'),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              }
                            : () {
                                if (!appState.isSignedIn) {
                                  showDialog(
                                    context: context,
                                    builder: (_) => const SupabaseAuthDialog(),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('🔒 Authentication Required: Please sign in or create an account to book this hotel stay.'),
                                      backgroundColor: Colors.teal,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  return;
                                }
                                Navigator.pop(ctx);
                                _showBookHotelDialog(context, appState, hotel);
                              },
                        icon: Icon(
                          hotel.availableRooms <= 0 ? Icons.do_not_disturb_on : Icons.calendar_month,
                          size: 18,
                        ),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            hotel.availableRooms <= 0
                                ? 'Sold Out • No Rooms'
                                : 'Reserve Local Stay (${hotel.availableRooms} left)',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hotel.availableRooms <= 0 ? Colors.grey : AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
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
),
);
}

class _GuestFormHolder {
  final TextEditingController nameCtrl;
  final TextEditingController aadharCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController dobCtrl;
  final TextEditingController addressCtrl;
  bool isScanning = false;
  bool hasScannedAadhaar = false;
  String idProofUrl = '';
  String documentFileName = '';
  Uint8List? documentBytes;
  bool isOcrDetected = false;
  int ocrFieldsCount = 0;

  _GuestFormHolder({
    String name = '',
    String aadhar = '',
    String phone = '',
    String dob = '',
    String address = '',
    this.hasScannedAadhaar = false,
    this.idProofUrl = '',
    this.documentFileName = '',
  })  : nameCtrl = TextEditingController(text: name),
        aadharCtrl = TextEditingController(text: aadhar),
        phoneCtrl = TextEditingController(text: phone),
        dobCtrl = TextEditingController(text: dob),
        addressCtrl = TextEditingController(text: address);

  void dispose() {
    nameCtrl.dispose();
    aadharCtrl.dispose();
    phoneCtrl.dispose();
    dobCtrl.dispose();
    addressCtrl.dispose();
  }
}

class _AadhaarInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 12) return oldValue;
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

void _showDocumentQuickPreview(
  BuildContext context, {
  required String guestName,
  required String urlOrDataUri,
  required String fileName,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: isDark ? AppColors.surfaceContainerDark : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Row(
        children: [
          const Icon(Icons.document_scanner, color: Colors.teal),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Aadhaar: ${guestName.isNotEmpty ? guestName : "Guest"}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attached Document: $fileName',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 260),
              color: Colors.black.withOpacity(0.04),
              child: InteractiveViewer(
                child: buildAadhaarDocumentPreview(urlOrDataUri, height: 240, fit: BoxFit.contain),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Icon(Icons.lock_outline, size: 12, color: Colors.teal),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Privacy Protected: Visible only to your account & property host after booking.',
                  style: TextStyle(fontSize: 10.5, color: Colors.teal, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

Widget _buildSourceOptionTile({
  required BuildContext context,
  required IconData icon,
  required Color color,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceContainerHigh : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
        ],
      ),
    ),
  );
}

Widget _buildUploadOptionButton({
  required BuildContext context,
  required IconData icon,
  required String label,
  required Color color,
  required VoidCallback onTap,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                maxLines: 1,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _PickedAadhaarFile {
  final String fileName;
  final String? filePath;
  final List<int> bytes;

  _PickedAadhaarFile({
    required this.fileName,
    this.filePath,
    required this.bytes,
  });
}

Future<_PickedAadhaarFile?> _pickViaFilePicker(
  BuildContext context, {
  bool allowAllFiles = true,
  FileType? customType,
  List<String>? allowedExtensions,
}) async {
  FilePickerResult? result;

  try {
    if (allowAllFiles) {
      // Allows exploring ANY folder, drive, or location across Linux (Zenity/GTK), Windows, macOS, Android, and iOS
      result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: kIsWeb,
      );
    } else if (customType != null && customType != FileType.custom) {
      result = await FilePicker.platform.pickFiles(
        type: customType,
        allowMultiple: false,
        withData: kIsWeb,
      );
    } else {
      // Case-insensitive extensions list for Linux, Windows, macOS
      final exts = allowedExtensions ?? [
        'pdf', 'PDF',
        'jpg', 'JPG',
        'jpeg', 'JPEG',
        'png', 'PNG',
        'webp', 'WEBP',
      ];
      try {
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: exts,
          allowMultiple: false,
          withData: kIsWeb,
        );
      } catch (customErr) {
        debugPrint('FileType.custom failed ($customErr), falling back to FileType.any');
        result = await FilePicker.platform.pickFiles(
          type: FileType.any,
          allowMultiple: false,
          withData: kIsWeb,
        );
      }
    }
  } catch (e) {
    debugPrint('FilePicker primary error ($e). Attempting fallback.');
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        if (bytes.isNotEmpty) {
          return _PickedAadhaarFile(
            fileName: picked.name,
            filePath: picked.path,
            bytes: bytes,
          );
        }
      }
    } catch (_) {}
  }

  if (result == null || result.files.isEmpty) {
    return null; // User cancelled
  }

  final f = result.files.first;
  final fileName = f.name;
  final filePath = f.path;
  List<int>? bytes = f.bytes;

  // On desktop (Linux, Windows, macOS) & mobile (Android, iOS), read from path
  if ((bytes == null || bytes.isEmpty) && filePath != null && !kIsWeb) {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        bytes = await file.readAsBytes();
      }
    } catch (e) {
      debugPrint('Error reading file bytes ($filePath): $e');
    }
  }

  if (bytes == null || bytes.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selected file could not be read. Please check file permissions or try another file.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return null;
  }

  // Validate format (support PDF and popular image formats)
  final ext = (fileName.contains('.') ? fileName.split('.').last : '').toLowerCase();
  const allowed = ['pdf', 'jpg', 'jpeg', 'png', 'webp', 'bmp', 'heic'];
  if (ext.isNotEmpty && !allowed.contains(ext)) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unsupported file format (.$ext). Please select an Aadhaar PDF document or image file (JPG, PNG, WebP).'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return null;
  }

  return _PickedAadhaarFile(
    fileName: fileName,
    filePath: filePath,
    bytes: bytes,
  );
}

Future<_PickedAadhaarFile?> _pickAadhaarFileCrossPlatform({
  required BuildContext context,
  required String source,
}) async {
  final isDesktop = !kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS);
  final isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  // 1. Camera Handling:
  if (source == 'camera') {
    if (isDesktop) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera capture is not supported on desktop. Opening file explorer to select your Aadhaar file...'),
            backgroundColor: Colors.teal,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return await _pickViaFilePicker(context, allowAllFiles: true);
    }

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1800,
        maxHeight: 1800,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        if (bytes.isNotEmpty) {
          return _PickedAadhaarFile(
            fileName: picked.name.isNotEmpty ? picked.name : 'aadhaar_camera.jpg',
            filePath: picked.path,
            bytes: bytes,
          );
        }
      }
      return null;
    } catch (e) {
      debugPrint('Mobile camera exception ($e). Falling back to file explorer.');
      if (!context.mounted) return null;
      return await _pickViaFilePicker(context, allowAllFiles: true);
    }
  }

  // 2. Photo Gallery Handling:
  if (source == 'gallery') {
    if (isMobile) {
      try {
        final picker = ImagePicker();
        final picked = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
          maxWidth: 1800,
          maxHeight: 1800,
        );
        if (picked != null) {
          final bytes = await picked.readAsBytes();
          if (bytes.isNotEmpty) {
            return _PickedAadhaarFile(
              fileName: picked.name.isNotEmpty ? picked.name : 'aadhaar_photo.jpg',
              filePath: picked.path,
              bytes: bytes,
            );
          }
        }
        return null;
      } catch (e) {
        debugPrint('Mobile gallery exception ($e). Falling back to file explorer.');
      }
    }
    if (!context.mounted) return null;
    return await _pickViaFilePicker(
      context,
      allowAllFiles: false,
      allowedExtensions: ['jpg', 'JPG', 'jpeg', 'JPEG', 'png', 'PNG', 'webp', 'WEBP'],
    );
  }

  // 3. PDF Document Specific Handling:
  if (source == 'pdf') {
    return await _pickViaFilePicker(
      context,
      allowAllFiles: false,
      allowedExtensions: ['pdf', 'PDF'],
    );
  }

  // 4. Default: "explore" or "file" (Browse all folders & drives across Linux, Windows, macOS, Android, iOS):
  return await _pickViaFilePicker(context, allowAllFiles: true);
}

Future<void> _scanAadhaarForGuest({
  required BuildContext context,
  required AppState appState,
  required _GuestFormHolder holder,
  required int guestIndex,
  required void Function(void Function()) setDlgState,
  String? directSource,
}) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final isDesktop = !kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS);
  String? source = directSource;
  source ??= await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceContainerDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.document_scanner, color: Colors.teal, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upload Aadhaar (Guest ${guestIndex + 1}) *',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'AI OCR will auto-detect Name, Aadhaar number & Address',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isDesktop) ...[
              _buildSourceOptionTile(
                context: context,
                icon: Icons.folder_open,
                color: Colors.teal,
                title: 'Explore Files on Computer (All Folders)',
                subtitle: 'Browse your folders, Downloads, and Documents for PDF or Image',
                onTap: () => Navigator.pop(sheetCtx, 'explore'),
              ),
              const SizedBox(height: 8),
              _buildSourceOptionTile(
                context: context,
                icon: Icons.picture_as_pdf,
                color: Colors.deepOrange,
                title: 'Upload e-Aadhaar PDF',
                subtitle: 'Browse official digital PDF file from storage',
                onTap: () => Navigator.pop(sheetCtx, 'pdf'),
              ),
              const SizedBox(height: 8),
              _buildSourceOptionTile(
                context: context,
                icon: Icons.image,
                color: Colors.indigo,
                title: 'Browse Scanned Image / Photo',
                subtitle: 'Select JPG, PNG, or WebP scan of Aadhaar',
                onTap: () => Navigator.pop(sheetCtx, 'gallery'),
              ),
            ] else ...[
              _buildSourceOptionTile(
                context: context,
                icon: Icons.camera_alt,
                color: Colors.teal,
                title: 'Take Photo with Camera',
                subtitle: 'Capture clear front or back of Aadhaar card',
                onTap: () => Navigator.pop(sheetCtx, 'camera'),
              ),
              const SizedBox(height: 8),
              _buildSourceOptionTile(
                context: context,
                icon: Icons.photo_library,
                color: Colors.indigo,
                title: 'Choose Photo from Gallery',
                subtitle: 'Select existing image from photo album',
                onTap: () => Navigator.pop(sheetCtx, 'gallery'),
              ),
              const SizedBox(height: 8),
              _buildSourceOptionTile(
                context: context,
                icon: Icons.folder_open,
                color: Colors.deepOrange,
                title: 'Explore Files / PDF Document',
                subtitle: 'Browse phone storage, Google Drive & downloads',
                onTap: () => Navigator.pop(sheetCtx, 'explore'),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceContainerLowest : Colors.grey.shade100,
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, size: 14, color: Colors.teal),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Your document is 256-bit encrypted and visible strictly to your account & host post-booking.',
                      style: TextStyle(fontSize: 10.5, color: Colors.black54),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

  if (source == null) return;
  if (!context.mounted) return;

  try {
    final pickedFile = await _pickAadhaarFileCrossPlatform(
      context: context,
      source: source,
    );

    if (pickedFile == null || pickedFile.bytes.isEmpty) {
      // User cancelled dialog or closed explorer
      return;
    }

    setDlgState(() {
      holder.isScanning = true;
      holder.documentFileName = pickedFile.fileName;
    });

    final fileName = pickedFile.fileName;
    final filePath = pickedFile.filePath;
    final bytes = pickedFile.bytes;
    final uBytes = Uint8List.fromList(bytes);
    holder.documentBytes = uBytes;

    // Resilient 3-stage upload pipeline:
    // 1. Try ImageKit CDN
    String? uploadedCdnUrl;
    final sanitizedFileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9_\.]'), '_');
    final cdnFileName = 'aadhaar_g${guestIndex + 1}_${DateTime.now().millisecondsSinceEpoch}_$sanitizedFileName';
    try {
      final ik = ImageKitService();
      uploadedCdnUrl = await ik.uploadImage(
        bytes: uBytes,
        fileName: cdnFileName,
        folder: '/hotel_guest_aadhaar',
      );
    } catch (e) {
      debugPrint('ImageKit upload exception: $e');
    }

    // 2. Fallback to Supabase Storage if ImageKit failed
    if (uploadedCdnUrl == null || uploadedCdnUrl.isEmpty) {
      try {
        uploadedCdnUrl = await appState.supabaseService.uploadImageToSupabaseStorage(
          bytes: uBytes,
          fileName: cdnFileName,
          bucket: 'vehicles',
        );
      } catch (e) {
        debugPrint('Supabase Storage fallback notice: $e');
      }
    }

    // 3. Fallback to base64 Data URI if network storage failed
    final isPdf = fileName.toLowerCase().endsWith('.pdf');
    final mime = isPdf ? 'application/pdf' : 'image/jpeg';
    final finalDocumentUrl = (uploadedCdnUrl != null && uploadedCdnUrl.isNotEmpty)
        ? uploadedCdnUrl
        : 'data:$mime;base64,${base64Encode(uBytes)}';

    holder.idProofUrl = finalDocumentUrl;
    holder.hasScannedAadhaar = true;

    // Run AI OCR to extract structured identity details
    final ocrResult = await DocumentOcrService.processDocument(
      fileName: fileName,
      selectedDocType: 'Aadhaar Card',
      fileSizeKb: bytes.length / 1024.0,
      bytes: bytes,
      imagePath: filePath,
      userDisplayName: holder.nameCtrl.text.isNotEmpty ? holder.nameCtrl.text : null,
    );

    int fieldsExtracted = 0;
    if (ocrResult.holderName.isNotEmpty && ocrResult.holderName != 'Not Detected') {
      holder.nameCtrl.text = ocrResult.holderName;
      fieldsExtracted++;
    }
    if (ocrResult.documentNumber.isNotEmpty &&
        !ocrResult.documentNumber.contains('UNDETECTED') &&
        !ocrResult.documentNumber.contains('XXXX')) {
      holder.aadharCtrl.text = ocrResult.documentNumber;
      fieldsExtracted++;
    }
    if (ocrResult.dob.isNotEmpty) {
      holder.dobCtrl.text = ocrResult.dob;
      fieldsExtracted++;
    }
    if (ocrResult.address.isNotEmpty) {
      holder.addressCtrl.text = ocrResult.address;
      fieldsExtracted++;
    }

    holder.isOcrDetected = fieldsExtracted > 0;
    holder.ocrFieldsCount = fieldsExtracted;
    setDlgState(() => holder.isScanning = false);

    if (context.mounted) {
      if (fieldsExtracted > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Aadhaar document uploaded & details auto-detected for Guest ${guestIndex + 1}'
              '${ocrResult.holderName.isNotEmpty && ocrResult.holderName != "Not Detected" ? " (${ocrResult.holderName})" : ""}!',
            ),
            backgroundColor: Colors.teal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Aadhaar document uploaded for Guest ${guestIndex + 1}! Please verify or enter any missing details.',
            ),
            backgroundColor: Colors.teal.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  } catch (e) {
    debugPrint('Aadhaar upload/OCR processing error: $e');
    setDlgState(() => holder.isScanning = false);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Aadhaar processing notice: $e'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

void _showBookHotelDialog(BuildContext context, AppState appState, Hotel hotel) {
  final rooms = appState.getRoomsForHotel(hotel.id);
  HotelRoom? selectedRoom = rooms.isNotEmpty ? rooms.first : null;
  DateTimeRange selectedRange = DateTimeRange(
    start: DateTime.now(),
    end: DateTime.now().add(const Duration(days: 1)),
  );
  int numGuests = 1;
  int roomCount = 1;
  final scrollController = ScrollController();

  // Look for any existing Aadhaar document in user's compliance docs
  String initialAadhar = '';
  String initialDocUrl = '';
  String initialFileName = '';
  bool initialScanned = false;
  for (final doc in appState.documents) {
    if (doc.type.toLowerCase().contains('aadhar') || doc.type.toLowerCase().contains('aadhaar')) {
      initialAadhar = doc.documentNumber;
      initialDocUrl = doc.documentUrl;
      initialFileName = doc.fileName;
      initialScanned = doc.status.toLowerCase() == 'verified' || doc.documentUrl.isNotEmpty || doc.documentNumber.isNotEmpty;
      break;
    }
  }

  // Initialize guest form holders list for multi-person details
  final List<_GuestFormHolder> guestHolders = [
    _GuestFormHolder(
      name: appState.activeUserDisplayName != 'Guest User' ? appState.activeUserDisplayName : '',
      phone: appState.userProfile?.phoneNumber ?? '',
      aadhar: initialAadhar,
      idProofUrl: initialDocUrl,
      documentFileName: initialFileName.isNotEmpty ? initialFileName : (initialDocUrl.isNotEmpty ? 'aadhaar_verified.jpg' : ''),
      hasScannedAadhaar: initialScanned && initialDocUrl.isNotEmpty,
    ),
  ];

  void syncGuests(int targetCount) {
    while (guestHolders.length < targetCount) {
      guestHolders.add(_GuestFormHolder());
    }
    while (guestHolders.length > targetCount) {
      final removed = guestHolders.removeLast();
      removed.dispose();
    }
  }

  showDialog(
    context: context,
    builder: (dlgCtx) => StatefulBuilder(
      builder: (dlgCtx, setDlgState) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final nights = selectedRange.duration.inDays > 0 ? selectedRange.duration.inDays : 1;
        final pricePerNight = selectedRoom?.basePrice ?? hotel.pricePerNight;
        final totalAmount = pricePerNight * nights * roomCount;

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.home_work_outlined, color: Colors.teal),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Book ${hotel.name}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width > 600 ? 550 : double.maxFinite,
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📍 ${hotel.location}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: hotel.availableRooms > 0
                          ? Colors.teal.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: hotel.availableRooms > 0
                            ? Colors.teal.withOpacity(0.3)
                            : Colors.red.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          hotel.availableRooms > 0 ? Icons.check_circle_outline : Icons.error_outline,
                          size: 16,
                          color: hotel.availableRooms > 0 ? Colors.teal : Colors.red,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            hotel.availableRooms > 0
                                ? '${hotel.availableRooms} of ${hotel.totalRooms} rooms available for booking'
                                : 'Property is currently sold out (0 rooms available)',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: hotel.availableRooms > 0 ? Colors.teal.shade900 : Colors.red.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Room Type Selector (if property has multiple room categories)
                  if (rooms.isNotEmpty) ...[
                    const Text('Select Room Category:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<HotelRoom>(
                          isExpanded: true,
                          value: selectedRoom,
                          items: rooms.map((r) {
                            return DropdownMenuItem(
                              value: r,
                              child: Text(
                                '${r.name} (₹${r.basePrice.toStringAsFixed(0)}/nt, max ${r.capacity}p)',
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setDlgState(() => selectedRoom = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Date Range Picker Button
                  const Text('Stay Dates:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        initialDateRange: selectedRange,
                      );
                      if (picked != null) {
                        setDlgState(() => selectedRange = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.teal.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16, color: Colors.teal),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${DateFormat('dd MMM').format(selectedRange.start)} - ${DateFormat('dd MMM').format(selectedRange.end)} ($nights night${nights == 1 ? '' : 's'})',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.teal),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.edit_calendar, size: 16, color: Colors.teal),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Number of guests & room count
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Guests:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            Row(
                              children: [
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  icon: const Icon(Icons.remove_circle_outline, size: 18),
                                  onPressed: numGuests > 1
                                      ? () {
                                          setDlgState(() {
                                            numGuests--;
                                            syncGuests(numGuests);
                                          });
                                        }
                                      : null,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Text('$numGuests', style: const TextStyle(fontWeight: FontWeight.bold)),
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  icon: const Icon(Icons.add_circle_outline, size: 18),
                                  onPressed: numGuests < 10
                                      ? () {
                                          setDlgState(() {
                                            numGuests++;
                                            syncGuests(numGuests);
                                          });
                                        }
                                      : null,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rooms (${hotel.availableRooms} max):',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Row(
                              children: [
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  icon: const Icon(Icons.remove_circle_outline, size: 18),
                                  onPressed: roomCount > 1 ? () => setDlgState(() => roomCount--) : null,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Text('$roomCount', style: const TextStyle(fontWeight: FontWeight.bold)),
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  icon: const Icon(Icons.add_circle_outline, size: 18),
                                  onPressed: (roomCount < hotel.availableRooms)
                                      ? () => setDlgState(() => roomCount++)
                                      : null,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 20),

                  // Multi-person Guest Details Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Guest Verification & Details *',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$numGuests ${numGuests == 1 ? "Guest" : "Guests"}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Upload Aadhaar for each guest. Our AI OCR auto-detects name, Aadhaar number & address.',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),

                  // Dynamic Guest Cards
                  ...List.generate(guestHolders.length, (idx) {
                    final holder = guestHolders[idx];
                    final hasDoc = holder.hasScannedAadhaar && holder.idProofUrl.isNotEmpty;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceContainerHigh : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: hasDoc
                              ? Colors.teal.shade300
                              : (idx == 0 ? Colors.teal.withOpacity(0.5) : Colors.amber.shade300),
                          width: hasDoc ? 1.4 : 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Guest Card Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: hasDoc
                                        ? Colors.teal
                                        : (idx == 0 ? Colors.teal.shade700 : Colors.grey.shade400),
                                    child: hasDoc
                                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                                        : Text(
                                            '${idx + 1}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    idx == 0 ? 'Guest 1 (Primary)' : 'Guest ${idx + 1}',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                      color: idx == 0 ? Colors.teal : null,
                                    ),
                                  ),
                                ],
                              ),
                              // Status Chip + Remove guest button
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (holder.isScanning)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.teal.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            width: 10,
                                            height: 10,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.teal),
                                          ),
                                          SizedBox(width: 5),
                                          Text(
                                            'Scanning OCR...',
                                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.teal),
                                          ),
                                        ],
                                      ),
                                    )
                                  else if (hasDoc)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.teal.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.teal.withOpacity(0.3)),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.verified, size: 12, color: Colors.teal),
                                          SizedBox(width: 4),
                                          Text(
                                            'Aadhaar Verified',
                                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.teal),
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.amber.shade300),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.warning_amber_rounded, size: 12, color: Colors.amber.shade800),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Aadhaar Required',
                                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (idx > 0) ...[
                                    const SizedBox(width: 8),
                                    Tooltip(
                                      message: 'Remove Guest ${idx + 1}',
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(16),
                                        onTap: () {
                                          setDlgState(() {
                                            final removed = guestHolders.removeAt(idx);
                                            removed.dispose();
                                            numGuests = guestHolders.length;
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.close, size: 14, color: Colors.red),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // 2. Aadhaar Upload Section
                          if (holder.isScanning)
                            // Scanning progress state
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade50.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.teal.shade300),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.teal),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Reading Aadhaar with AI OCR...',
                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal),
                                            ),
                                            Text(
                                              'Extracting Name, 12-digit number & Address from ${holder.documentFileName.isNotEmpty ? holder.documentFileName : "document"}',
                                              style: const TextStyle(fontSize: 10.5, color: Colors.black54),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: const LinearProgressIndicator(
                                      color: Colors.teal,
                                      backgroundColor: Color(0xFFB2DFDB),
                                      minHeight: 3,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (hasDoc)
                            // Uploaded & Verified Document Card
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.surfaceContainerLowest : Colors.teal.shade50.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.teal.shade300),
                              ),
                              child: Row(
                                children: [
                                  // Thumbnail preview (tappable)
                                  InkWell(
                                    onTap: () => _showDocumentQuickPreview(
                                      context,
                                      guestName: holder.nameCtrl.text.isNotEmpty ? holder.nameCtrl.text : 'Guest ${idx + 1}',
                                      urlOrDataUri: holder.idProofUrl,
                                      fileName: holder.documentFileName.isNotEmpty ? holder.documentFileName : 'aadhaar_card.jpg',
                                    ),
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Container(
                                            width: 60,
                                            height: 50,
                                            color: Colors.grey.shade200,
                                            child: buildAadhaarDocumentPreview(
                                              holder.idProofUrl,
                                              height: 50,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 2,
                                          right: 2,
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.65),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Icon(Icons.zoom_in, size: 11, color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  // Document information
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.check_circle, size: 14, color: Colors.teal),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                holder.documentFileName.isNotEmpty
                                                    ? holder.documentFileName
                                                    : 'Aadhaar Attached',
                                                style: const TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.teal,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          holder.isOcrDetected
                                              ? '✨ ${holder.ocrFieldsCount} details auto-filled via OCR'
                                              : 'Attached & verified for check-in',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            color: isDark ? Colors.grey.shade300 : Colors.black87,
                                            fontWeight: holder.isOcrDetected ? FontWeight.w600 : FontWeight.normal,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        const Row(
                                          children: [
                                            Icon(Icons.lock_outline, size: 10, color: Colors.grey),
                                            SizedBox(width: 3),
                                            Text(
                                              'Visible only to host after booking',
                                              style: TextStyle(fontSize: 9.5, color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Actions
                                  Column(
                                    children: [
                                      InkWell(
                                        onTap: () => _showDocumentQuickPreview(
                                          context,
                                          guestName: holder.nameCtrl.text.isNotEmpty ? holder.nameCtrl.text : 'Guest ${idx + 1}',
                                          urlOrDataUri: holder.idProofUrl,
                                          fileName: holder.documentFileName.isNotEmpty ? holder.documentFileName : 'aadhaar_card.jpg',
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.teal,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.visibility, size: 11, color: Colors.white),
                                              SizedBox(width: 3),
                                              Text('View', style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      InkWell(
                                        onTap: () => _scanAadhaarForGuest(
                                          context: context,
                                          appState: appState,
                                          holder: holder,
                                          guestIndex: idx,
                                          setDlgState: setDlgState,
                                        ),
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.refresh, size: 11, color: Colors.grey),
                                              SizedBox(width: 2),
                                              Text('Replace', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            )
                          else
                            // Not uploaded yet: Direct practical upload action card!
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.surfaceContainerLowest : const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.teal.shade300, width: 1.2),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.teal.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.document_scanner, color: Colors.teal, size: 20),
                                      ),
                                      const SizedBox(width: 8),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Upload & Scan Aadhaar Card *',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Colors.teal),
                                            ),
                                            Text(
                                              'AI OCR auto-fills all details in seconds',
                                              style: TextStyle(fontSize: 10.5, color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.shade100,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Compulsory',
                                          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  // Direct platform-adaptive upload actions
                                  Builder(
                                    builder: (context) {
                                      final isDesktop = !kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS);
                                      if (isDesktop) {
                                        return Row(
                                          children: [
                                            Expanded(
                                              flex: 5,
                                              child: _buildUploadOptionButton(
                                                context: context,
                                                icon: Icons.folder_open_outlined,
                                                label: 'Explore Files',
                                                color: Colors.teal,
                                                onTap: () => _scanAadhaarForGuest(
                                                  context: context,
                                                  appState: appState,
                                                  holder: holder,
                                                  guestIndex: idx,
                                                  setDlgState: setDlgState,
                                                  directSource: 'explore',
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              flex: 4,
                                              child: _buildUploadOptionButton(
                                                context: context,
                                                icon: Icons.picture_as_pdf_outlined,
                                                label: 'PDF Document',
                                                color: Colors.deepOrange,
                                                onTap: () => _scanAadhaarForGuest(
                                                  context: context,
                                                  appState: appState,
                                                  holder: holder,
                                                  guestIndex: idx,
                                                  setDlgState: setDlgState,
                                                  directSource: 'pdf',
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              flex: 4,
                                              child: _buildUploadOptionButton(
                                                context: context,
                                                icon: Icons.image_outlined,
                                                label: 'Browse Photo',
                                                color: Colors.indigo,
                                                onTap: () => _scanAadhaarForGuest(
                                                  context: context,
                                                  appState: appState,
                                                  holder: holder,
                                                  guestIndex: idx,
                                                  setDlgState: setDlgState,
                                                  directSource: 'gallery',
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      }

                                      // Mobile (Android / iOS):
                                      return Row(
                                        children: [
                                          Expanded(
                                            child: _buildUploadOptionButton(
                                              context: context,
                                              icon: Icons.camera_alt_outlined,
                                              label: 'Camera',
                                              color: Colors.teal,
                                              onTap: () => _scanAadhaarForGuest(
                                                context: context,
                                                appState: appState,
                                                holder: holder,
                                                guestIndex: idx,
                                                setDlgState: setDlgState,
                                                directSource: 'camera',
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: _buildUploadOptionButton(
                                              context: context,
                                              icon: Icons.photo_library_outlined,
                                              label: 'Gallery',
                                              color: Colors.indigo,
                                              onTap: () => _scanAadhaarForGuest(
                                                context: context,
                                                appState: appState,
                                                holder: holder,
                                                guestIndex: idx,
                                                setDlgState: setDlgState,
                                                directSource: 'gallery',
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: _buildUploadOptionButton(
                                              context: context,
                                              icon: Icons.folder_open_outlined,
                                              label: 'Explore Files',
                                              color: Colors.deepOrange,
                                              onTap: () => _scanAadhaarForGuest(
                                                context: context,
                                                appState: appState,
                                                holder: holder,
                                                guestIndex: idx,
                                                setDlgState: setDlgState,
                                                directSource: 'explore',
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 6),
                                  const Row(
                                    children: [
                                      Icon(Icons.lock_outline, size: 11, color: Colors.grey),
                                      SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          'Visible strictly to your account & host post-booking.',
                                          style: TextStyle(fontSize: 10, color: Colors.grey),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 12),

                          // 3. Section Header for Details
                          Row(
                            children: [
                              Text(
                                'Personal Details',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(width: 6),
                              if (holder.isOcrDetected)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    '✨ Auto-filled',
                                    style: TextStyle(fontSize: 9.5, color: Colors.teal, fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // Full Name (Mandatory)
                          TextField(
                            controller: holder.nameCtrl,
                            decoration: InputDecoration(
                              labelText: 'Full Name *',
                              hintText: 'As printed on Aadhaar card',
                              prefixIcon: const Icon(Icons.person_outline, size: 18),
                              suffixIcon: holder.nameCtrl.text.isNotEmpty
                                  ? const Icon(Icons.check_circle_outline, size: 16, color: Colors.teal)
                                  : null,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              isDense: true,
                            ),
                            onChanged: (_) => setDlgState(() {}),
                          ),
                          const SizedBox(height: 8),

                          // Aadhaar Card Number (Mandatory, 12 digits)
                          TextField(
                            controller: holder.aadharCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [_AadhaarInputFormatter()],
                            decoration: InputDecoration(
                              labelText: 'Aadhaar Card Number * (12 digits)',
                              hintText: 'XXXX XXXX XXXX',
                              prefixIcon: const Icon(Icons.credit_card, size: 18),
                              suffixIcon: holder.aadharCtrl.text.replaceAll(RegExp(r'\D'), '').length == 12
                                  ? const Icon(Icons.check_circle, size: 16, color: Colors.teal)
                                  : null,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              isDense: true,
                            ),
                            onChanged: (_) => setDlgState(() {}),
                          ),
                          const SizedBox(height: 8),

                          // Mobile Number (Mandatory, 10 digits)
                          TextField(
                            controller: holder.phoneCtrl,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            decoration: InputDecoration(
                              labelText: 'Mobile Number * (10 digits)',
                              hintText: '10-digit mobile number',
                              prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                              suffixIcon: holder.phoneCtrl.text.replaceAll(RegExp(r'\D'), '').length >= 10
                                  ? const Icon(Icons.check_circle, size: 16, color: Colors.teal)
                                  : null,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              isDense: true,
                            ),
                            onChanged: (_) => setDlgState(() {}),
                          ),
                          const SizedBox(height: 8),

                          // DOB & Address Row
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isCompact = constraints.maxWidth < 360;
                              final dobWidget = InkWell(
                                onTap: () async {
                                  final now = DateTime.now();
                                  DateTime initial = DateTime(now.year - 25, 1, 1);
                                  if (holder.dobCtrl.text.isNotEmpty) {
                                    final parts = holder.dobCtrl.text.split(RegExp(r'[-/.]'));
                                    if (parts.length == 3) {
                                      final d = int.tryParse(parts[0]);
                                      final m = int.tryParse(parts[1]);
                                      final y = int.tryParse(parts[2]);
                                      if (d != null && m != null && y != null && y > 1900 && y <= now.year) {
                                        initial = DateTime(y, m, d);
                                      }
                                    }
                                  }
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: initial,
                                    firstDate: DateTime(1920),
                                    lastDate: now,
                                  );
                                  if (picked != null) {
                                    setDlgState(() {
                                      holder.dobCtrl.text =
                                          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
                                    });
                                  }
                                },
                                child: AbsorbPointer(
                                  child: TextField(
                                    controller: holder.dobCtrl,
                                    decoration: InputDecoration(
                                      labelText: 'DOB',
                                      hintText: 'DD/MM/YYYY',
                                      prefixIcon: const Icon(Icons.cake_outlined, size: 16),
                                      suffixIcon: const Icon(Icons.calendar_today, size: 13, color: Colors.teal),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                              );

                              final addressWidget = TextField(
                                controller: holder.addressCtrl,
                                decoration: InputDecoration(
                                  labelText: 'Address',
                                  hintText: 'City, State, Pincode',
                                  prefixIcon: const Icon(Icons.location_on_outlined, size: 16),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  isDense: true,
                                ),
                                onChanged: (_) => setDlgState(() {}),
                              );

                              if (isCompact) {
                                return Column(
                                  children: [
                                    dobWidget,
                                    const SizedBox(height: 8),
                                    addressWidget,
                                  ],
                                );
                              }

                              return Row(
                                children: [
                                  Expanded(flex: 4, child: dobWidget),
                                  const SizedBox(width: 8),
                                  Expanded(flex: 6, child: addressWidget),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 2),

                  // "Add Guests" Section under Guest details
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceContainerHigh.withOpacity(0.4)
                          : Colors.teal.shade50.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.teal.withOpacity(0.3),
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.teal.withOpacity(0.14),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.group_add_outlined,
                                color: Colors.teal,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        'Add Guests',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.teal.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '${guestHolders.length} / 10 Max',
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.teal,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Traveling with more people? Add accompanying guests & upload their Aadhaar details.',
                                    style: TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                icon: const Icon(Icons.add, size: 18),
                                label: Text(
                                  numGuests < 10
                                      ? '+ Add Guest ${guestHolders.length + 1}'
                                      : 'Maximum Guests Added (10)',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                onPressed: numGuests < 10
                                    ? () {
                                        setDlgState(() {
                                          numGuests++;
                                          syncGuests(numGuests);
                                        });
                                        WidgetsBinding.instance.addPostFrameCallback((_) {
                                          if (scrollController.hasClients) {
                                            scrollController.animateTo(
                                              scrollController.position.maxScrollExtent,
                                              duration: const Duration(milliseconds: 320),
                                              curve: Curves.easeOut,
                                            );
                                          }
                                        });
                                      }
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Price Breakdown
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '₹${pricePerNight.toStringAsFixed(0)} × $nights nt × $roomCount rm',
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Text(
                                'Total (0% Commission):',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '₹${totalAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dlgCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (!appState.isSignedIn) {
                  showDialog(
                    context: context,
                    builder: (_) => const SupabaseAuthDialog(),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🔒 Authentication Required: Please sign in or create an account to confirm your hotel booking.'),
                      backgroundColor: Colors.teal,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                if (hotel.availableRooms <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('⚠️ This stay currently has 0 rooms available to rent.'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }
                if (roomCount > hotel.availableRooms) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('⚠️ Only ${hotel.availableRooms} room(s) available to rent at this stay.'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }

                // Validation: Ensure every guest has uploaded and scanned their Aadhaar card, with Full Name, 12-digit Aadhaar, and Mobile Number
                for (int i = 0; i < guestHolders.length; i++) {
                  final g = guestHolders[i];

                  // 1. Compulsory Aadhaar document upload & OCR scan check
                  if (!g.hasScannedAadhaar || g.idProofUrl.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '⚠️ Aadhaar upload & OCR scan is COMPULSORY for Guest ${i + 1}'
                          '${g.nameCtrl.text.isNotEmpty ? " (${g.nameCtrl.text})" : ""}. Please upload and scan their Aadhaar card to proceed.',
                        ),
                        backgroundColor: Colors.red.shade700,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                    return;
                  }

                  final name = g.nameCtrl.text.trim();
                  final aadharDigits = g.aadharCtrl.text.replaceAll(RegExp(r'\D'), '');
                  final phoneDigits = g.phoneCtrl.text.replaceAll(RegExp(r'\D'), '');

                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('⚠️ Please enter the Full Name for Guest ${i + 1}.'),
                        backgroundColor: Colors.red.shade700,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  if (aadharDigits.length != 12) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('⚠️ Please enter a valid 12-digit Aadhaar Card number for Guest ${i + 1}.'),
                        backgroundColor: Colors.red.shade700,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  if (phoneDigits.length < 10) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('⚠️ Please enter a valid 10-digit Mobile number for Guest ${i + 1}.'),
                        backgroundColor: Colors.red.shade700,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                }

                final guestDetails = guestHolders.map((g) {
                  return HotelGuestDetail(
                    name: g.nameCtrl.text.trim(),
                    aadharNumber: g.aadharCtrl.text.trim(),
                    mobileNumber: g.phoneCtrl.text.trim(),
                    dob: g.dobCtrl.text.trim(),
                    address: g.addressCtrl.text.trim(),
                    idProofUrl: g.idProofUrl,
                  );
                }).toList();

                final primaryGuest = guestDetails.first;
                final guestName = primaryGuest.name;
                final guestPhone = primaryGuest.mobileNumber;
                final guestAadhar = primaryGuest.aadharNumber;

                Navigator.pop(dlgCtx);

                final bookingRef = 'STAY-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                final hotelBooking = HotelBooking(
                  id: 'hb_${DateTime.now().millisecondsSinceEpoch}',
                  bookingRef: bookingRef,
                  hotelId: hotel.id,
                  hotelName: hotel.name,
                  hotelLocation: hotel.location,
                  hotelImageUrl: hotel.imageUrl,
                  roomType: selectedRoom?.name ?? hotel.roomType,
                  roomId: selectedRoom?.id ?? '',
                  roomCount: roomCount,
                  hostId: hotel.hostId,
                  hostName: hotel.hostName,
                  hostPhone: hotel.hostPhone,
                  hostAvatar: hotel.hostAvatar,
                  userId: appState.activeAccountId,
                  guestName: guestName,
                  guestPhone: guestPhone,
                  guestIdProofType: 'Aadhaar Card',
                  guestIdProofNumber: guestAadhar,
                  guests: guestDetails,
                  guestEmail: appState.userProfile?.email ?? '',
                  guestPhotoUrl: appState.activeUserPhotoUrl,
                  guestTrustScore: appState.userProfile?.trustScore ?? 100.0,
                  accountId: appState.activeAccountId,
                  accountName: appState.activeUserDisplayName,
                  accountType: appState.isChildAccount ? 'child' : 'mother',
                  isChildBooking: appState.isChildAccount,
                  childId: appState.activeChildProfile?.childId ?? '',
                  childName: appState.activeChildProfile?.name ?? '',
                  checkInDate: selectedRange.start,
                  checkOutDate: selectedRange.end,
                  nights: nights,
                  numGuests: numGuests,
                  pricePerNight: pricePerNight,
                  totalPrice: totalAmount,
                  status: 'Confirmed',
                );

                await appState.createHotelBooking(hotelBooking);

                // Send notification
                await appState.addNotification(
                  userId: appState.activeAccountId,
                  title: 'Homestay Reserved: ${hotel.name} 🏡',
                  message:
                      'Your stay for $nights night(s) at ${hotel.name} is reserved for $numGuests guest(s)! Booking Ref: $bookingRef.',
                  type: NotificationType.bookingConfirmation,
                  imageUrl: hotel.imageUrl,
                  actionNavIndex: 19,
                );

                if (context.mounted) {
                  showDialog(
                    context: context,
                    builder: (succCtx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 28),
                          SizedBox(width: 8),
                          Text('Stay Confirmed!'),
                        ],
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Reservation at "${hotel.name}" is confirmed!'),
                          const SizedBox(height: 8),
                          Text('Ref: $bookingRef', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('Dates: ${DateFormat('dd MMM').format(selectedRange.start)} - ${DateFormat('dd MMM').format(selectedRange.end)} ($nights night${nights == 1 ? "" : "s"})'),
                          Text('Guests: $numGuests person(s) • Rooms: $roomCount'),
                          if (hotel.hostPhone.isNotEmpty)
                            Text('Host: ${hotel.hostName} (${hotel.hostPhone})', style: const TextStyle(color: Colors.green)),
                          const Divider(height: 16),
                          const Text(
                            'Registered Guests (Aadhaar Verified):',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          ...guestDetails.map((g) {
                            final rawAadhar = g.aadharNumber.replaceAll(' ', '');
                            final maskedAadhar = rawAadhar.length >= 4
                                ? 'XXXX XXXX ${rawAadhar.substring(rawAadhar.length - 4)}'
                                : g.aadharNumber;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text(
                                '• ${g.name} ($maskedAadhar, Ph: ${g.mobileNumber})',
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            );
                          }),
                          const SizedBox(height: 10),
                          const Text(
                            'Pay directly at check-in. Show your digital Stay Pass QR code upon arrival.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 14),

                          // Cross-sell row: Nearby Rides & Tours
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.purple.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.two_wheeler, color: Colors.purple, size: 22),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Need a ride for this stay?',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.purple),
                                      ),
                                      Text(
                                        'Bikes and self-drive cars available nearby with keyless unlock.',
                                        style: TextStyle(fontSize: 10, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(succCtx);
                                    appState.setNavIndex(1); // Discovery catalog
                                  },
                                  child: const Text('Browse Rides', style: TextStyle(fontSize: 11, color: Colors.purple, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        OutlinedButton(
                          onPressed: () {
                            Navigator.pop(succCtx);
                            showStayPassModal(context, appState, hotelBooking);
                          },
                          child: const Text('View Stay Pass QR'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                          onPressed: () {
                            Navigator.pop(succCtx);
                            appState.setNavIndex(19); // My Bookings
                          },
                          child: const Text('My Bookings', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                }
              },
              child: const Text('Confirm Reservation'),
            ),
          ],
        );
      },
    ),
  ).then((_) {
    scrollController.dispose();
  });
}

Widget _buildSpecChip({
  required IconData icon,
  required String title,
  required String value,
  required bool isDark,
}) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceContainerHighDark : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ),
  );
}

IconData _getAmenityIcon(String amenity) {
  final l = amenity.toLowerCase();
  if (l.contains('wifi') || l.contains('wi-fi')) return Icons.wifi;
  if (l.contains('water') || l.contains('geyser')) return Icons.hot_tub;
  if (l.contains('food') || l.contains('meal') || l.contains('breakfast')) return Icons.restaurant;
  if (l.contains('park')) return Icons.local_parking;
  if (l.contains('view') || l.contains('mountain')) return Icons.landscape;
  if (l.contains('bath')) return Icons.bathtub_outlined;
  if (l.contains('bonfire')) return Icons.local_fire_department;
  if (l.contains('ac') || l.contains('cooler')) return Icons.ac_unit;
  return Icons.check_circle_outline;
}

class PositionmentBadge extends StatelessWidget {
  final Widget child;
  const PositionmentBadge({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 12,
      right: 12,
      child: child,
    );
  }
}
