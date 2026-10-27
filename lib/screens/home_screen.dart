import 'dart:async';
// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';
import '../widgets/tour_details_modal.dart';
import '../widgets/hotel_details_modal.dart';
import '../widgets/side_by_side_reviews_widget.dart';
import '../widgets/edit_vehicle_dialog.dart';
import 'blog_editor_screen.dart';
import '../widgets/supabase_auth_dialog.dart';
import '../widgets/home_hero_carousel.dart';
import '../widgets/home/home_greeting.dart';
import '../widgets/home/quick_actions_grid.dart';
import '../widgets/home/how_it_works_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isHotelsSelected = appState.selectedCategory == 'Hotels and Stays' ||
        appState.selectedCategory == 'Hotels & Stays' ||
        appState.selectedCategory == '🏡 Budget Stays & Hotels';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting & Search
          const HomeGreeting(),
          const SizedBox(height: 16),

          // Hero Carousel
          HomeHeroCarousel(onPostBlog: () => _handleCreateBlogPost(context, appState)),
          const SizedBox(height: 24),

          // Main actions
          const QuickActionsGrid(),

          // First-time onboarding (dismissible)
          const HowItWorksCard(),

          const SizedBox(height: 24),

          // Category filter for the listings below
          const Text(
            'Browse Listings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryChip(context, appState, 'All', Icons.apps),
                _buildCategoryChip(context, appState, 'Hotels and Stays', Icons.holiday_village_rounded),
                _buildCategoryChip(context, appState, 'Motorcycles', Icons.two_wheeler),
                _buildCategoryChip(context, appState, 'Guided Tours', Icons.tour),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Quick Access Banner for Driving License & Government ID Upload
          InkWell(
            onTap: () => appState.setNavIndex(14),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceContainerDark : AppColors.secondaryContainer.withOpacity(0.35),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.secondary.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.badge, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('🪪 Documents & Licenses Verification', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('Submit Driving License, Expiry Date & PDF/JPG scan (150KB - 500KB)', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.secondary),
                ],
              ),
            ),
          ),



          // Featured Rides / Guided Tours Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Builder(
                      builder: (context) {
                        final isTours = appState.selectedCategory == 'Guided Tours';
                        final count = isHotelsSelected
                            ? appState.getAvailableHotelsNearCustomer(radiusKm: 999999.0).length
                            : (isTours
                                ? appState.filteredTours.length
                                : appState.getAvailableVehiclesNearCustomer(radiusKm: 999999.0).length);
                        final catLabel = appState.selectedCategory == 'All' ? 'All Vehicles' : appState.selectedCategory;
                        return Text(
                          isHotelsSelected
                              ? 'Hotels and Stays ($count)'
                              : (isTours ? 'Guided Tours ($count)' : '$catLabel by Proximity ($count)'),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                    Text(
                      isHotelsSelected
                          ? 'Verified homestays & local rooms sorted by proximity'
                          : (appState.selectedCategory == 'Guided Tours'
                              ? 'Verified local hosts & guided expeditions'
                              : 'Sorted strictly from closest to farthest host'),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.secondaryFixedDim : AppColors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      if (isHotelsSelected) {
                        appState.setCategory('🏡 Budget Stays & Hotels');
                      } else if (appState.selectedCategory == 'Guided Tours') {
                        appState.setCategory('🏍️ Guided Tours');
                      } else {
                        appState.setCategory('All');
                      }
                      appState.setNavIndex(1);
                    },
                    icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                    label: const Text('Explore All'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Filters & Search',
                    onPressed: () => appState.setNavIndex(1),
                    icon: const Icon(Icons.tune, size: 18),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Featured Vehicles & Tours Grid / Carousel
          Builder(
            builder: (ctx) {
              final isDesktop = MediaQuery.of(ctx).size.width >= 800;

              if (isHotelsSelected) {
                final hotels = appState.getAvailableHotelsNearCustomer(radiusKm: 999999.0);
                if (hotels.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.holiday_village_outlined, size: 36, color: Colors.grey),
                        const SizedBox(height: 8),
                        const Text('No homestays currently listed nearby.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => appState.setCategory('All'),
                          icon: const Icon(Icons.refresh, size: 14),
                          label: const Text('View All Categories'),
                        ),
                      ],
                    ),
                  );
                }

                if (isDesktop) {
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 460,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      mainAxisExtent: 176,
                    ),
                    itemCount: hotels.length,
                    itemBuilder: (context, index) {
                      return _buildHomeHotelCard(context, appState, hotels[index], distanceRank: index + 1, isGrid: true);
                    },
                  );
                } else {
                  return SizedBox(
                    height: 335,
                    child: AutoScrollingCarousel(
                      itemCount: hotels.length,
                      itemExtent: 260.0,
                      itemBuilder: (context, index) {
                        return _buildHomeHotelCard(context, appState, hotels[index], distanceRank: index + 1);
                      },
                    ),
                  );
                }
              }

              if (appState.selectedCategory == 'Guided Tours') {
                final tours = appState.filteredTours;
                if (tours.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.tour, size: 36, color: Colors.grey),
                        const SizedBox(height: 8),
                        const Text('No guided tours currently listed.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => appState.setCategory('All'),
                          icon: const Icon(Icons.refresh, size: 14),
                          label: const Text('View All Categories'),
                        ),
                      ],
                    ),
                  );
                }

                if (isDesktop) {
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 460,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      mainAxisExtent: 156,
                    ),
                    itemCount: tours.length,
                    itemBuilder: (context, index) {
                      return _buildHorizontalTourCard(context, appState, tours[index], isGrid: true);
                    },
                  );
                } else {
                  return SizedBox(
                    height: 310,
                    child: AutoScrollingCarousel(
                      itemCount: tours.length,
                      itemExtent: 256.0,
                      itemBuilder: (context, index) {
                        return _buildHorizontalTourCard(context, appState, tours[index]);
                      },
                    ),
                  );
                }
              }

              final allVehiclesSorted = appState.getAvailableVehiclesNearCustomer(radiusKm: 999999.0);
              if (allVehiclesSorted.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.search_off, size: 36, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text(
                        'No ${appState.selectedCategory} currently listed nearby.',
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => appState.setCategory('All'),
                        icon: const Icon(Icons.refresh, size: 14),
                        label: const Text('Clear Filter & View All'),
                      ),
                    ],
                  ),
                );
              }

              if (isDesktop) {
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 460,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    mainAxisExtent: 176,
                  ),
                  itemCount: allVehiclesSorted.length,
                  itemBuilder: (context, index) {
                    return _buildVehicleCard(context, appState, allVehiclesSorted[index], distanceRank: index + 1, isGrid: true);
                  },
                );
              } else {
                return SizedBox(
                  height: 335,
                  child: AutoScrollingCarousel(
                    itemCount: allVehiclesSorted.length,
                    itemExtent: 256.0,
                    itemBuilder: (context, index) {
                      return _buildVehicleCard(context, appState, allVehiclesSorted[index], distanceRank: index + 1);
                    },
                  ),
                );
              }
            },
          ),

          // Dedicated "Hotels and Stays" Section for Customers
          if (!isHotelsSelected) ...[
            const SizedBox(height: 24),
            _buildHotelsAndStaysSection(context, appState, isDark),
          ],

          if (appState.selectedCategory != 'Guided Tours' && !isHotelsSelected) ...[
            const SizedBox(height: 24),

            // Popular Guided Tours Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Popular Guided Tours',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    appState.setCategory('🏍️ Guided Tours');
                    appState.setNavIndex(1);
                  },
                  icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                  label: const Text('Explore All'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.secondary,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Tours List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: appState.tours.length,
              itemBuilder: (context, index) {
                final tour = appState.tours[index];
                return _buildTourCard(context, appState, tour);
              },
            ),
          ],

          const SizedBox(height: 20),

          // Direct Community Blog Posting Banner (Moved down after Guided Tours)
          InkWell(
            onTap: () => _handleCreateBlogPost(context, appState),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E1B4B), const Color(0xFF312E81)]
                      : [const Color(0xFFEEF2FF), const Color(0xFFE0E7FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.35)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.rate_review_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                '✍️ Share a Road Story',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4F46E5),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'NEW',
                                style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Share trip tips, post photos, or link reels to the community feed.',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton(
                    onPressed: () => _handleCreateBlogPost(context, appState),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: const Text('Post', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Community Ratings & Side-by-Side Reviews Section
          const SideBySideReviewsWidget(
            title: 'Community Reviews & Platform Feedback',
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHotelsAndStaysSection(BuildContext context, AppState appState, bool isDark) {
    final hotels = appState.getAvailableHotelsNearCustomer(radiusKm: 999999.0);
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.holiday_village_rounded, size: 20, color: Colors.teal),
                      ),
                      const SizedBox(width: 8),
                      const Flexible(
                        child: Text(
                          'Hotels and Stays',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Budget homestays & verified local rooms near your destination',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.secondaryFixedDim : AppColors.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: () {
                appState.setCategory('🏡 Budget Stays & Hotels');
                appState.setNavIndex(1);
              },
              icon: const Icon(Icons.arrow_forward_rounded, size: 14),
              label: const Text('Explore All'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Content
        if (hotels.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.holiday_village_outlined, size: 36, color: Colors.grey),
                SizedBox(height: 8),
                Text(
                  'No local stays or homestays currently available nearby.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          )
        else if (isDesktop)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 460,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              mainAxisExtent: 176,
            ),
            itemCount: hotels.length,
            itemBuilder: (context, index) {
              return _buildHomeHotelCard(context, appState, hotels[index], distanceRank: index + 1, isGrid: true);
            },
          )
        else
          SizedBox(
            height: 335,
            child: AutoScrollingCarousel(
              itemCount: hotels.length,
              itemExtent: 260.0,
              itemBuilder: (context, index) {
                return _buildHomeHotelCard(context, appState, hotels[index], distanceRank: index + 1);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildHomeHotelCard(
    BuildContext context,
    AppState appState,
    Hotel hotel, {
    int distanceRank = 1,
    bool isGrid = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final distStr = appState.getFormattedDistanceToHotel(hotel);

    if (isGrid) {
      return Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: distanceRank == 1
                ? Colors.teal
                : (isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight),
            width: distanceRank == 1 ? 2.0 : 1.0,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => showHotelDetailsModal(context, appState, hotel),
            child: Row(
              children: [
                // Left Image Stack
                SizedBox(
                  width: 140,
                  height: double.infinity,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(18),
                            bottomLeft: Radius.circular(18),
                          ),
                          child: Image.network(
                            hotel.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => Container(
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.holiday_village_rounded, size: 40, color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: distanceRank == 1
                                ? Colors.teal.shade700
                                : (distanceRank <= 3 ? Colors.teal.shade800 : Colors.black.withOpacity(0.75)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                distanceRank == 1 ? Icons.emoji_events : Icons.near_me,
                                size: 10,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                distanceRank == 1
                                    ? '1st'
                                    : (distanceRank == 2 ? '2nd' : (distanceRank == 3 ? '3rd' : '#$distanceRank')),
                                style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 10),
                              const SizedBox(width: 2),
                              Text(
                                hotel.rating.toStringAsFixed(1),
                                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade700,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '0% FEE',
                            style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Right Details Column
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hotel.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 11, color: Colors.redAccent),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: Text(
                                    hotel.location,
                                    style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${hotel.roomType} • Max ${hotel.maxGuests} guests',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: isDark ? Colors.teal.shade200 : Colors.teal.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (distStr.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                '📍 $distStr away',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark ? AppColors.secondaryFixedDim : AppColors.secondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      '₹${hotel.pricePerNight.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? AppColors.secondaryFixedDim : AppColors.primary,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const Text(
                                      ' / nt',
                                      style: TextStyle(fontSize: 9, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            ElevatedButton(
                              onPressed: () => showHotelDetailsModal(context, appState, hotel),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text(
                                'View Stay',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
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
          ),
        ),
      );
    }

    // Mobile / Horizontal Carousel Card
    return Container(
      width: 250,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: distanceRank == 1
              ? Colors.teal
              : (isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight),
          width: distanceRank == 1 ? 2.0 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => showHotelDetailsModal(context, appState, hotel),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    child: Image.network(
                      hotel.imageUrl,
                      height: 130,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Container(
                        height: 130,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.holiday_village_rounded, size: 40, color: Colors.grey),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: distanceRank == 1
                            ? Colors.teal.shade700
                            : (distanceRank <= 3 ? Colors.teal.shade800 : Colors.black.withOpacity(0.75)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            distanceRank == 1 ? Icons.emoji_events : Icons.near_me,
                            size: 11,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            distanceRank == 1
                                ? '🥇 #1 NEAREST'
                                : (distanceRank == 2 ? '🥈 #2 NEAREST' : (distanceRank == 3 ? '🥉 #3 NEAREST' : '#$distanceRank NEAREST')),
                            style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 11),
                          const SizedBox(width: 2),
                          Text(
                            hotel.rating.toStringAsFixed(1),
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade700,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, color: Colors.white, size: 10),
                          SizedBox(width: 3),
                          Text('0% FEE', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        hotel.roomType,
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hotel.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 12, color: Colors.redAccent),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            hotel.location,
                            style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (distStr.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.teal.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              distStr,
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.teal),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.people_outline, size: 12, color: Colors.grey),
                        const SizedBox(width: 3),
                        Text(
                          'Max ${hotel.maxGuests} guests',
                          style: const TextStyle(fontSize: 10.5, color: Colors.grey),
                        ),
                        const SizedBox(width: 8),
                        if (hotel.amenities.isNotEmpty) ...[
                          const Icon(Icons.wifi, size: 12, color: Colors.teal),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              hotel.amenities.first,
                              style: const TextStyle(fontSize: 10.5, color: Colors.teal),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '₹${hotel.pricePerNight.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? AppColors.secondaryFixedDim : AppColors.primary,
                                    fontSize: 16,
                                  ),
                                ),
                                const Text(
                                  ' / night',
                                  style: TextStyle(fontSize: 10, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => showHotelDetailsModal(context, appState, hotel),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text(
                            'View Stay',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
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
      ),
    );
  }

  Widget _buildCategoryChip(BuildContext context, AppState appState, String label, IconData icon) {
    final isSelected = appState.selectedCategory == label;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        avatar: Icon(
          icon,
          size: 18,
          color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppColors.primary),
        ),
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) appState.setCategory(label);
        },
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : (isDark ? Colors.white : AppColors.onSurfaceLight),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        backgroundColor: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLow,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildVehicleCard(BuildContext context, AppState appState, Vehicle vehicle, {int distanceRank = 1, bool isGrid = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isHost = appState.isHostOfVehicle(vehicle);

    if (isGrid) {
      return Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: distanceRank == 1
                ? AppColors.secondary
                : (isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight),
            width: distanceRank == 1 ? 2.0 : 1.0,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              appState.selectVehicle(vehicle);
              appState.setNavIndex(2); // Detail screen
            },
            child: Row(
              children: [
                // Left Image Stack
                SizedBox(
                  width: 140,
                  height: double.infinity,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(18),
                            bottomLeft: Radius.circular(18),
                          ),
                          child: Image.network(
                            vehicle.imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (ctx, err, stack) => Container(
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.directions_car, size: 40, color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: distanceRank == 1
                                ? Colors.green.shade700
                                : (distanceRank <= 3 ? Colors.blue.shade800 : Colors.black.withOpacity(0.75)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                distanceRank == 1
                                    ? Icons.emoji_events
                                    : (distanceRank <= 3 ? Icons.near_me : Icons.navigation),
                                size: 10,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                distanceRank == 1
                                    ? '1st'
                                    : (distanceRank == 2
                                        ? '2nd'
                                        : (distanceRank == 3 ? '3rd' : '#$distanceRank')),
                                style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (vehicle.isInstantBookable)
                        Positioned(
                          bottom: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.flash_on, size: 10, color: Colors.white),
                          ),
                        ),
                      if (isHost)
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => showEditVehicleDialog(context, appState, vehicle),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black26, blurRadius: 4),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.edit, size: 10, color: Colors.white),
                                  SizedBox(width: 2),
                                  Text(
                                    'Edit',
                                    style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Right Details Column
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    vehicle.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: Colors.transparent,
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: Icon(
                                      vehicle.isFavorite ? Icons.favorite : Icons.favorite_border,
                                      size: 16,
                                      color: vehicle.isFavorite ? Colors.redAccent : (isDark ? Colors.white60 : Colors.black45),
                                    ),
                                    onPressed: () => appState.toggleFavoriteVehicle(vehicle.id),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.star, size: 12, color: Colors.amber),
                                const SizedBox(width: 2),
                                Text(
                                  '${vehicle.rating}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                                Text(
                                  ' (${vehicle.reviewCount})',
                                  style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Owner & Features Chips
                        Wrap(
                          spacing: 4,
                          runSpacing: 2,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.person, size: 10, color: AppColors.primary),
                                  const SizedBox(width: 3),
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 110),
                                    child: Text(
                                      'Owner: ${vehicle.hostName.isNotEmpty ? vehicle.hostName : "Host"}',
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white10 : Colors.blueGrey.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${vehicle.category} • ${vehicle.fuelType} • ${vehicle.seats}S',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryContainer.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '📍 ${appState.getFormattedDistanceToVehicle(vehicle)}',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSecondaryContainer,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: RichText(
                                overflow: TextOverflow.ellipsis,
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '₹${vehicle.pricePerDay.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : AppColors.primary,
                                      ),
                                    ),
                                    TextSpan(
                                      text: '/d',
                                      style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : Colors.black54),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isHost) ...[
                                  OutlinedButton.icon(
                                    onPressed: () => showEditVehicleDialog(context, appState, vehicle),
                                    icon: const Icon(Icons.edit, size: 11),
                                    label: const Text('Edit', style: TextStyle(fontSize: 10)),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      side: const BorderSide(color: AppColors.primary),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                ElevatedButton(
                                  onPressed: () {
                                    appState.selectVehicle(vehicle);
                                    appState.setNavIndex(2); // Detail screen
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text('View', style: TextStyle(fontSize: 11)),
                                ),
                              ],
                            ),
                          ],
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

    return Container(
      width: 240,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: distanceRank == 1
              ? AppColors.secondary
              : (isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight),
          width: distanceRank == 1 ? 2.0 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            appState.selectVehicle(vehicle);
            appState.setNavIndex(2); // Detail screen
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    child: Image.network(
                      vehicle.imageUrl,
                      height: 130,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      errorBuilder: (ctx, err, stack) => Container(
                        height: 130,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.directions_car, size: 40, color: Colors.grey),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: distanceRank == 1
                            ? Colors.green.shade700
                            : (distanceRank <= 3 ? Colors.blue.shade800 : Colors.black.withOpacity(0.75)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            distanceRank == 1
                                ? Icons.emoji_events
                                : (distanceRank <= 3 ? Icons.near_me : Icons.navigation),
                            size: 11,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              distanceRank == 1
                                  ? '🥇 #1 NEAREST'
                                  : (distanceRank == 2
                                      ? '🥈 #2 NEAREST'
                                      : (distanceRank == 3 ? '🥉 #3 NEAREST' : '#$distanceRank NEAREST')),
                              style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.black45,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          vehicle.isFavorite ? Icons.favorite : Icons.favorite_border,
                          size: 18,
                          color: vehicle.isFavorite ? Colors.redAccent : Colors.white,
                        ),
                        onPressed: () => appState.toggleFavoriteVehicle(vehicle.id),
                      ),
                    ),
                  ),
                  if (vehicle.isInstantBookable)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.flash_on, size: 12, color: Colors.white),
                            SizedBox(width: 2),
                            Text('Instant Book', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  if (isHost)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => showEditVehicleDialog(context, appState, vehicle),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 4),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit, size: 11, color: Colors.white),
                              SizedBox(width: 3),
                              Text('Edit Details', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(
                          '${vehicle.rating}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        Text(
                          ' (${vehicle.reviewCount})',
                          style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                        ),
                        const Spacer(),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryContainer.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '📍 ${appState.getFormattedDistanceToVehicle(vehicle)}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.onSecondaryContainer,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Features & Owner
                    Wrap(
                      spacing: 4,
                      runSpacing: 3,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.person, size: 11, color: AppColors.primary),
                              const SizedBox(width: 3),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 120),
                                child: Text(
                                  'Owner: ${vehicle.hostName.isNotEmpty ? vehicle.hostName : "Host"}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : Colors.blueGrey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            '${vehicle.category} • ${vehicle.fuelType} • ${vehicle.seats}S',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: RichText(
                            overflow: TextOverflow.ellipsis,
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '₹${vehicle.pricePerDay.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : AppColors.primary,
                                  ),
                                ),
                                TextSpan(
                                  text: '/day',
                                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isHost) ...[
                              OutlinedButton.icon(
                                onPressed: () => showEditVehicleDialog(context, appState, vehicle),
                                icon: const Icon(Icons.edit, size: 12),
                                label: const Text('Edit', style: TextStyle(fontSize: 11)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  side: const BorderSide(color: AppColors.primary),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            ElevatedButton(
                              onPressed: () {
                                appState.selectVehicle(vehicle);
                                appState.setNavIndex(2); // Detail screen
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text('View', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildHorizontalTourCard(BuildContext context, AppState appState, Tour tour, {bool isGrid = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isGrid) {
      return Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: () {
              appState.selectTour(tour);
              showTourDetailsModal(context, appState, tour);
            },
            borderRadius: BorderRadius.circular(20),
            child: Row(
              children: [
                // Left Image Stack
                SizedBox(
                  width: 140,
                  height: double.infinity,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            bottomLeft: Radius.circular(20),
                          ),
                          child: Image.network(
                            tour.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => Container(
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.tour, size: 40, color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 11),
                              const SizedBox(width: 2),
                              Text(
                                tour.rating.toStringAsFixed(1),
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (tour.isExpired)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.red.shade800,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('EXPIRED', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                          ),
                        ),
                    ],
                  ),
                ),
                // Right Details Column
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tour.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${tour.location} • ${tour.duration}',
                              style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  tour.isExpired ? Icons.event_busy : Icons.event_available,
                                  size: 11,
                                  color: tour.isExpired ? Colors.red : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                ),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    tour.isExpired ? 'Expired: ${tour.formattedExpiryDate}' : 'Expires: ${tour.formattedExpiryDate}',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: tour.isExpired ? FontWeight.bold : FontWeight.w500,
                                      color: tour.isExpired ? Colors.red : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                '₹${tour.price.toStringAsFixed(0)} / person',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.secondaryFixedDim : AppColors.secondary,
                                  fontSize: 11.5,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            ElevatedButton(
                              onPressed: () {
                                appState.selectTour(tour);
                                showTourDetailsModal(context, appState, tour);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: tour.isExpired ? Colors.grey : AppColors.secondary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: Text(
                                tour.isExpired ? 'Expired' : 'Book Tour',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
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
          ),
        ),
      );
    }

    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
        ),
      ),
      child: InkWell(
        onTap: () {
          appState.selectTour(tour);
          showTourDetailsModal(context, appState, tour);
        },
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Image.network(
                    tour.imageUrl,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => Container(
                      height: 140,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.tour, size: 40, color: Colors.grey),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 13),
                        const SizedBox(width: 3),
                        Text(
                          tour.rating.toStringAsFixed(1),
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                if (tour.isExpired)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade800,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('EXPIRED', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tour.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${tour.location} • ${tour.duration}',
                    style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        tour.isExpired ? Icons.event_busy : Icons.event_available,
                        size: 11,
                        color: tour.isExpired ? Colors.red : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          tour.isExpired ? 'Expired: ${tour.formattedExpiryDate}' : 'Expires: ${tour.formattedExpiryDate}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: tour.isExpired ? FontWeight.bold : FontWeight.w500,
                            color: tour.isExpired ? Colors.red : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          '₹${tour.price.toStringAsFixed(0)} / person',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.secondaryFixedDim : AppColors.secondary,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      ElevatedButton(
                        onPressed: () {
                          appState.selectTour(tour);
                          showTourDetailsModal(context, appState, tour);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: tour.isExpired ? Colors.grey : AppColors.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          tour.isExpired ? 'Expired' : 'Book Tour',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
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
    );
  }

  Widget _buildTourCard(BuildContext context, AppState appState, Tour tour) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        appState.selectTour(tour);
        showTourDetailsModal(context, appState, tour);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              child: Image.network(
                tour.imageUrl,
                height: 100,
                width: 110,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => Container(
                  height: 100,
                  width: 110,
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.tour, size: 30, color: Colors.grey),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tour.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${tour.location} • ${tour.duration}',
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          tour.isExpired ? Icons.event_busy : Icons.event_available,
                          size: 12,
                          color: tour.isExpired ? Colors.red : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            tour.isExpired ? 'Expired: ${tour.formattedExpiryDate}' : 'Expires: ${tour.formattedExpiryDate}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: tour.isExpired ? FontWeight.bold : FontWeight.w500,
                              color: tour.isExpired ? Colors.red : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '₹${tour.price.toStringAsFixed(0)} / person',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.secondaryFixedDim : AppColors.secondary,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        OutlinedButton(
                          onPressed: () {
                            appState.selectTour(tour);
                            showTourDetailsModal(context, appState, tour);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            side: tour.isExpired ? const BorderSide(color: Colors.grey) : null,
                          ),
                          child: Text(
                            tour.isExpired ? 'Expired' : 'Book Tour',
                            style: TextStyle(
                              fontSize: 11,
                              color: tour.isExpired ? Colors.grey : null,
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
      ),
    );
  }

  void _handleCreateBlogPost(BuildContext context, AppState appState) {
    if (!appState.isSignedIn) {
      showDialog(
        context: context,
        builder: (_) => const SupabaseAuthDialog(),
      );
      return;
    }
    Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const BlogEditorScreen()),
    ).then((updated) {
      if (updated == true) {
        appState.loadBlogPosts();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('🎉 Blog post shared to Community Feed!'),
                ],
              ),
              backgroundColor: const Color(0xFF4F46E5),
              action: SnackBarAction(
                label: 'View Feed',
                textColor: Colors.white,
                onPressed: () => appState.setNavIndex(21), // Go to Blog & Social Hub
              ),
            ),
          );
        }
      }
    });
  }
}

class AutoScrollingCarousel extends StatefulWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double itemExtent;

  const AutoScrollingCarousel({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.itemExtent = 256.0,
  });

  @override
  State<AutoScrollingCarousel> createState() => _AutoScrollingCarouselState();
}

class _AutoScrollingCarouselState extends State<AutoScrollingCarousel> {
  late ScrollController _scrollController;
  Timer? _timer;
  bool _userInteracting = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_userInteracting || !_scrollController.hasClients || widget.itemCount <= 1) {
        return;
      }
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;
      double targetScroll = currentScroll + widget.itemExtent;

      if (targetScroll >= maxScroll + 10) {
        targetScroll = 0.0;
      }

      _scrollController.animateTo(
        targetScroll,
        duration: const Duration(milliseconds: 850),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _onUserPointerDown() {
    _userInteracting = true;
  }

  void _onUserPointerUp() {
    _userInteracting = false;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _onUserPointerDown(),
      onPointerUp: (_) => _onUserPointerUp(),
      onPointerCancel: (_) => _onUserPointerUp(),
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: widget.itemCount,
        itemBuilder: widget.itemBuilder,
      ),
    );
  }
}
