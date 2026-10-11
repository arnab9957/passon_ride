// ignore_for_file: deprecated_member_use, unused_local_variable
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import 'auto_sliding_image_carousel.dart';

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

void _showBookHotelDialog(BuildContext context, AppState appState, Hotel hotel) {
  int nights = 1;
  final TextEditingController nameCtrl = TextEditingController(
    text: appState.activeUserDisplayName != 'Guest User' ? appState.activeUserDisplayName : '',
  );
  final TextEditingController phoneCtrl = TextEditingController(
    text: appState.userProfile?.phoneNumber ?? '',
  );

  showDialog(
    context: context,
    builder: (dlgCtx) => StatefulBuilder(
      builder: (dlgCtx, setDlgState) {
        final totalAmount = hotel.pricePerNight * nights;

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.home_work_outlined, color: AppColors.primary),
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
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Location: ${hotel.location}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Number of Nights:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: nights > 1 ? () => setDlgState(() => nights--) : null,
                        ),
                        Text(
                          '$nights ${nights == 1 ? "Night" : "Nights"}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: nights < 30 ? () => setDlgState(() => nights++) : null,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Guest Full Name',
                    prefixIcon: Icon(Icons.person_outline, size: 18),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Contact Phone / WhatsApp',
                    prefixIcon: Icon(Icons.phone_outlined, size: 18),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Estimated Price:'),
                      Text(
                        '₹${totalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dlgCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final guestName = nameCtrl.text.trim().isNotEmpty
                    ? nameCtrl.text.trim()
                    : appState.activeUserDisplayName;
                final guestPhone = phoneCtrl.text.trim();

                Navigator.pop(dlgCtx);

                // Add in-app notification to host and guest
                final bookingRef = 'STAY-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                await appState.addNotification(
                  userId: appState.activeAccountId,
                  title: 'Homestay Reserved: ${hotel.name} 🏡',
                  message:
                      'Your stay for $nights night(s) at ${hotel.name} is reserved for $guestName (Contact: $guestPhone). Booking Ref: $bookingRef. Host: ${hotel.hostName} (${hotel.hostPhone}).',
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
                          Text('Homestay Reserved!'),
                        ],
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Your reservation at "${hotel.name}" has been recorded!'),
                          const SizedBox(height: 10),
                          Text('Booking Ref: $bookingRef', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('Host: ${hotel.hostName}'),
                          if (hotel.hostPhone.isNotEmpty)
                            Text('Host Phone: ${hotel.hostPhone}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                          const SizedBox(height: 12),
                          const Text(
                            'Pay directly to host at check-in or via UPI. 0% Commission charged.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      actions: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(succCtx);
                            appState.setNavIndex(19); // Go to My Bookings / Rides
                          },
                          child: const Text('View My Bookings'),
                        ),
                      ],
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
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
