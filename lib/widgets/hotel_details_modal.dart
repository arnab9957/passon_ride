// ignore_for_file: deprecated_member_use, unused_local_variable
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
import 'auto_sliding_image_carousel.dart';
import 'stay_pass_modal.dart';

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
      builder: (ctx, setState) => Container(
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
              child: SingleChildScrollView(
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
                                  '${hotel.rating.toStringAsFixed(1)} (${hotel.reviewCount} reviews)',
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
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [Colors.teal.shade900.withOpacity(0.4), Colors.blueGrey.shade900.withOpacity(0.4)]
                              : [Colors.teal.shade50, Colors.cyan.shade50],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.teal.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_user_outlined, color: Colors.teal, size: 24),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Direct Local Host • 0% Middleman Margin',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '100% of your payment goes directly to empower this local resident and family.',
                                  style: TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Quick Specs
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
                          icon: Icons.people_outline,
                          title: 'Guests',
                          value: 'Up to ${hotel.maxGuests}',
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
                                    label: Text(
                                      'Call: ${hotel.hostPhone}',
                                      style: const TextStyle(fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
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
                        Text(
                          '₹${hotel.pricePerNight.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
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
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showBookHotelDialog(context, appState, hotel);
                        },
                        icon: const Icon(Icons.calendar_month, size: 18),
                        label: const Text(
                          'Reserve Local Stay',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
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
  );
}

class _GuestFormHolder {
  final TextEditingController nameCtrl;
  final TextEditingController aadharCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController dobCtrl;
  final TextEditingController addressCtrl;
  bool isScanning = false;

  _GuestFormHolder({
    String name = '',
    String aadhar = '',
    String phone = '',
    String dob = '',
    String address = '',
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

Future<void> _scanAadhaarForGuest({
  required BuildContext context,
  required _GuestFormHolder holder,
  required int guestIndex,
  required void Function(void Function()) setDlgState,
}) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final source = await showModalBottomSheet<String>(
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
          Row(
            children: [
              const Icon(Icons.document_scanner, color: Colors.teal, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Scan Aadhaar Card (Guest ${guestIndex + 1})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Automatically detects and extracts Full Name, 12-digit Aadhaar Number, DOB, and Address using AI OCR.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const Divider(height: 24),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFE0F2F1),
              child: Icon(Icons.camera_alt, color: Colors.teal),
            ),
            title: const Text('Take Photo with Camera', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: const Text('Capture front or back of Aadhaar card', style: TextStyle(fontSize: 12)),
            onTap: () => Navigator.pop(sheetCtx, 'camera'),
          ),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFE0F2F1),
              child: Icon(Icons.photo_library, color: Colors.teal),
            ),
            title: const Text('Choose Photo from Gallery', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: const Text('Pick an existing photo or scan from storage', style: TextStyle(fontSize: 12)),
            onTap: () => Navigator.pop(sheetCtx, 'gallery'),
          ),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFE0F2F1),
              child: Icon(Icons.picture_as_pdf, color: Colors.teal),
            ),
            title: const Text('Upload PDF / Document File', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: const Text('Browse e-Aadhaar PDF or scanned file', style: TextStyle(fontSize: 12)),
            onTap: () => Navigator.pop(sheetCtx, 'file'),
          ),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFFFF3E0),
              child: Icon(Icons.auto_awesome, color: Colors.orange),
            ),
            title: const Text('Use Sample Aadhaar Card (Demo / Instant)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: const Text('Instant OCR verification test with mock UIDAI scan', style: TextStyle(fontSize: 12)),
            onTap: () => Navigator.pop(sheetCtx, 'preset'),
          ),
        ],
      ),
    ),
  );

  if (source == null) return;

  setDlgState(() => holder.isScanning = true);

  try {
    List<int>? bytes;
    String fileName = 'aadhaar_card.jpg';
    String? filePath;

    if (source == 'camera' || source == 'gallery') {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked != null) {
        fileName = picked.name;
        bytes = await picked.readAsBytes();
        filePath = picked.path;
      }
    } else if (source == 'file') {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final f = result.files.first;
        fileName = f.name;
        bytes = f.bytes;
        filePath = f.path;
      }
    } else if (source == 'preset') {
      final preset = DocumentOcrService.getPresetSample('Aadhaar Card');
      if (preset.holderName.isNotEmpty) holder.nameCtrl.text = preset.holderName;
      if (preset.documentNumber.isNotEmpty) holder.aadharCtrl.text = preset.documentNumber;
      if (preset.dob.isNotEmpty) holder.dobCtrl.text = preset.dob;
      if (preset.address.isNotEmpty) holder.addressCtrl.text = preset.address;

      setDlgState(() => holder.isScanning = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Sample Aadhaar detected for Guest ${guestIndex + 1}! (${preset.holderName})'),
            backgroundColor: Colors.teal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (bytes == null || bytes.isEmpty) {
      setDlgState(() => holder.isScanning = false);
      return;
    }

    final ocrResult = await DocumentOcrService.processDocument(
      fileName: fileName,
      selectedDocType: 'Aadhaar Card',
      fileSizeKb: bytes.length / 1024.0,
      bytes: bytes,
      imagePath: filePath,
      userDisplayName: holder.nameCtrl.text.isNotEmpty ? holder.nameCtrl.text : null,
    );

    if (ocrResult.holderName.isNotEmpty && ocrResult.holderName != 'Not Detected') {
      holder.nameCtrl.text = ocrResult.holderName;
    }
    if (ocrResult.documentNumber.isNotEmpty &&
        !ocrResult.documentNumber.contains('UNDETECTED') &&
        !ocrResult.documentNumber.contains('XXXX')) {
      holder.aadharCtrl.text = ocrResult.documentNumber;
    }
    if (ocrResult.dob.isNotEmpty) {
      holder.dobCtrl.text = ocrResult.dob;
    }
    if (ocrResult.address.isNotEmpty) {
      holder.addressCtrl.text = ocrResult.address;
    }

    setDlgState(() => holder.isScanning = false);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Aadhaar OCR Success! Details filled for Guest ${guestIndex + 1}'
            '${ocrResult.holderName.isNotEmpty && ocrResult.holderName != "Not Detected" ? " (${ocrResult.holderName})" : ""}',
          ),
          backgroundColor: Colors.teal,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  } catch (e) {
    debugPrint('Aadhaar OCR processing error: $e');
    setDlgState(() => holder.isScanning = false);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Aadhaar OCR notice: $e'),
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

  // Look for any existing Aadhaar document in user's compliance docs
  String initialAadhar = '';
  for (final doc in appState.documents) {
    if (doc.type.toLowerCase().contains('aadhar') || doc.type.toLowerCase().contains('aadhaar')) {
      initialAadhar = doc.documentNumber;
      break;
    }
  }

  // Initialize guest form holders list for multi-person details
  final List<_GuestFormHolder> guestHolders = [
    _GuestFormHolder(
      name: appState.activeUserDisplayName != 'Guest User' ? appState.activeUserDisplayName : '',
      phone: appState.userProfile?.phoneNumber ?? '',
      aadhar: initialAadhar,
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📍 ${hotel.location}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16, color: Colors.teal),
                              const SizedBox(width: 8),
                              Text(
                                '${DateFormat('dd MMM').format(selectedRange.start)} - ${DateFormat('dd MMM').format(selectedRange.end)} ($nights night${nights == 1 ? '' : 's'})',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.teal),
                              ),
                            ],
                          ),
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
                                Text('$numGuests', style: const TextStyle(fontWeight: FontWeight.bold)),
                                IconButton(
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
                            const Text('Rooms:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, size: 18),
                                  onPressed: roomCount > 1 ? () => setDlgState(() => roomCount--) : null,
                                ),
                                Text('$roomCount', style: const TextStyle(fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline, size: 18),
                                  onPressed: roomCount < 5 ? () => setDlgState(() => roomCount++) : null,
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
                          'Guest Details (Required for All Guests):',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$numGuests ${numGuests == 1 ? "Person" : "Persons"}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Full Name, 12-digit Aadhaar number, and Mobile number must be provided for every person booking.',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),

                  // Dynamic Guest Cards
                  ...List.generate(guestHolders.length, (idx) {
                    final holder = guestHolders[idx];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceContainerHigh : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: idx == 0 ? Colors.teal.withOpacity(0.4) : Colors.grey.shade300,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: idx == 0 ? Colors.teal : Colors.grey.shade400,
                                    child: Text(
                                      '${idx + 1}',
                                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    idx == 0 ? 'Guest 1 (Primary Guest)' : 'Guest ${idx + 1}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: idx == 0 ? Colors.teal : null,
                                    ),
                                  ),
                                ],
                              ),
                              if (holder.isScanning)
                                const Row(
                                  children: [
                                    SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.teal),
                                    ),
                                    SizedBox(width: 6),
                                    Text('Scanning...', style: TextStyle(fontSize: 11, color: Colors.teal)),
                                  ],
                                )
                              else
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    minimumSize: const Size(0, 30),
                                    side: BorderSide(color: Colors.teal.shade400),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  icon: const Icon(Icons.document_scanner, size: 14, color: Colors.teal),
                                  label: const Text(
                                    'Scan Aadhaar (OCR)',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal),
                                  ),
                                  onPressed: () => _scanAadhaarForGuest(
                                    context: context,
                                    holder: holder,
                                    guestIndex: idx,
                                    setDlgState: setDlgState,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Full Name (Mandatory)
                          TextField(
                            controller: holder.nameCtrl,
                            decoration: InputDecoration(
                              labelText: 'Full Name *',
                              hintText: 'Enter name as on Aadhaar',
                              prefixIcon: const Icon(Icons.person_outline, size: 18),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              isDense: true,
                            ),
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
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              isDense: true,
                            ),
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
                              hintText: '10-digit phone number',
                              prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // DOB & Address Row (Auto-populated by OCR or manual)
                          Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: TextField(
                                  controller: holder.dobCtrl,
                                  decoration: InputDecoration(
                                    labelText: 'DOB',
                                    hintText: 'DD/MM/YYYY',
                                    prefixIcon: const Icon(Icons.cake_outlined, size: 16),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 6,
                                child: TextField(
                                  controller: holder.addressCtrl,
                                  decoration: InputDecoration(
                                    labelText: 'Address',
                                    hintText: 'City, State, Pincode',
                                    prefixIcon: const Icon(Icons.location_on_outlined, size: 16),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 4),

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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '₹${pricePerNight.toStringAsFixed(0)} × $nights nt × $roomCount rm',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                            const Text('Total (0% Commission):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
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
                // Validation: Ensure every guest has Full Name, valid 12-digit Aadhaar, and Mobile Number
                for (int i = 0; i < guestHolders.length; i++) {
                  final g = guestHolders[i];
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
  );
}

Widget _buildSpecChip({
  required IconData icon,
  required String title,
  required String value,
  required bool isDark,
}) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceContainerHighDark : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
