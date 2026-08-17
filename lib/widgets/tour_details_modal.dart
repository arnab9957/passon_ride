import 'package:flutter/material.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import 'auto_sliding_image_carousel.dart';

void showTourDetailsModal(BuildContext context, AppState appState, Tour tour, {bool isHostView = false}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final galleryImages = tour.images.isNotEmpty ? tour.images : [tour.imageUrl];
  int activeImageIndex = 0;

  final activeUserPhoto = appState.activeUserPhotoUrl;
  final currentUid = appState.userProfile?.uid ?? appState.supabaseUser?.id ?? '';
  final currentDisplayName = appState.activeUserDisplayName;

  final isMyTour = (currentUid.isNotEmpty && tour.hostId == currentUid) ||
      (tour.guideName.isNotEmpty && currentDisplayName != 'Guest User' && tour.guideName == currentDisplayName) ||
      tour.hostId.isEmpty;

  String effectiveGuideAvatar = tour.guideAvatar;
  if (activeUserPhoto.isNotEmpty && (isMyTour || effectiveGuideAvatar.isEmpty || effectiveGuideAvatar.contains('unsplash.com'))) {
    effectiveGuideAvatar = activeUserPhoto;
  }
  if (effectiveGuideAvatar.isEmpty) {
    effectiveGuideAvatar = 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&q=80';
  }

  String effectiveGuideName = tour.guideName;
  if (isMyTour && currentDisplayName != 'Guest User') {
    effectiveGuideName = currentDisplayName;
  } else if (effectiveGuideName.isEmpty) {
    effectiveGuideName = 'Verified Local Host';
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLowest,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
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
                    Stack(
                      children: [
                        AutoSlidingImageCarousel(
                          images: galleryImages,
                          height: 300,
                          borderRadius: BorderRadius.circular(20),
                          fallbackIcon: Icons.tour,
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: CircleAvatar(
                            backgroundColor: Colors.black54,
                            child: IconButton(
                              icon: Icon(
                                tour.isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: tour.isFavorite ? Colors.red : Colors.white,
                              ),
                              onPressed: () {
                                appState.toggleFavoriteTour(tour.id);
                                setState(() {});
                              },
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Multi-Image Thumbnails
                    if (galleryImages.length > 1) ...[
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(galleryImages.length, (i) {
                            final isSel = i == activeImageIndex;
                            return GestureDetector(
                              onTap: () => setState(() => activeImageIndex = i),
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                width: 60,
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSel ? AppColors.secondary : Colors.transparent,
                                    width: 2,
                                  ),
                                  image: DecorationImage(
                                    image: NetworkImage(galleryImages[i]),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade700,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star, color: Colors.white, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '${tour.rating.toStringAsFixed(1)} (${tour.reviewCount} reviews)',
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tour.duration,
                            style: TextStyle(
                              color: isDark ? Colors.white : AppColors.secondary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Text(tour.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: AppColors.secondary, size: 16),
                        const SizedBox(width: 4),
                        Text(tour.location, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),

                    const Divider(height: 24),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceContainerHighDark : AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundImage: NetworkImage(effectiveGuideAvatar),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('TOUR GUIDE & HOST', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                                Text(
                                  effectiveGuideName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade700,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('VERIFIED', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    if (tour.description.isNotEmpty) ...[
                      const Text('About This Tour', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 6),
                      Text(
                        tour.description,
                        style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87, height: 1.4),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (tour.includedGear.isNotEmpty) ...[
                      const Text('Included Gear & Amenities', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: tour.includedGear.map((g) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle, color: AppColors.secondary, size: 14),
                              const SizedBox(width: 6),
                              Text(g, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        )).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (tour.waypoints.isNotEmpty) ...[
                      const Text('Route Highlights & Stops', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 8),
                      Column(
                        children: tour.waypoints.asMap().entries.map((entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 10,
                                backgroundColor: AppColors.secondary,
                                child: Text(
                                  '${entry.key + 1}',
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(entry.value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        )).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceContainerDark : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('TOUR PRICE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                      Text(
                        '₹${tour.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.secondaryFixedDim : AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        appState.selectTour(tour);
                        if (isHostView) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Viewing host tour listing: "${tour.title}"'),
                              backgroundColor: AppColors.secondary,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Selected tour: "${tour.title}". Proceeding to checkout.'),
                              backgroundColor: Colors.green.shade700,
                            ),
                          );
                          appState.setNavIndex(4);
                        }
                      },
                      icon: Icon(isHostView ? Icons.check_circle : Icons.confirmation_number, color: Colors.white, size: 18),
                      label: Text(
                        isHostView ? 'Host Preview Active' : 'Book Guided Tour',
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
