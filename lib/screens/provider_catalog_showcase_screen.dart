import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/user_avatar.dart';
import '../widgets/share_provider_catalog_dialog.dart';
import 'vehicle_detail_screen.dart';

class ProviderCatalogShowcaseScreen extends StatefulWidget {
  final String hostId;
  final String hostName;

  const ProviderCatalogShowcaseScreen({
    super.key,
    required this.hostId,
    required this.hostName,
  });

  @override
  State<ProviderCatalogShowcaseScreen> createState() => _ProviderCatalogShowcaseScreenState();
}

class _ProviderCatalogShowcaseScreenState extends State<ProviderCatalogShowcaseScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    // Fetch this host's vehicles & tours
    final allHostedVehicles = appState.vehicles.where((v) {
      if (v.hostId.isNotEmpty && widget.hostId.isNotEmpty) {
        if (v.hostId == widget.hostId) return true;
      }
      if (v.hostName.isNotEmpty && widget.hostName.isNotEmpty) {
        return v.hostName.toLowerCase() == widget.hostName.toLowerCase();
      }
      return false;
    }).toList();

    final bikesAndScooters = allHostedVehicles.where((v) {
      final t = v.type.toString().toLowerCase();
      final cat = v.category.toLowerCase();
      return t.contains('bike') || t.contains('scooter') || cat.contains('bike') || cat.contains('scooter') || cat.contains('two');
    }).toList();

    final carsAndSuvs = allHostedVehicles.where((v) {
      final t = v.type.toString().toLowerCase();
      final cat = v.category.toLowerCase();
      return t.contains('car') || cat.contains('car') || cat.contains('suv') || cat.contains('four');
    }).toList();

    final hostedTours = appState.tours.where((t) {
      if (t.hostId.isNotEmpty && widget.hostId.isNotEmpty) {
        if (t.hostId == widget.hostId) return true;
      }
      if (t.guideName.isNotEmpty && widget.hostName.isNotEmpty) {
        return t.guideName.toLowerCase() == widget.hostName.toLowerCase();
      }
      return false;
    }).toList();

    // Host profile summary fallback
    final activeHost = appState.hostProfile;
    final bool matchesActiveHost = activeHost != null &&
        (activeHost.userId == widget.hostId ||
            activeHost.id == widget.hostId ||
            (activeHost.displayName.isNotEmpty &&
                widget.hostName.isNotEmpty &&
                activeHost.displayName.toLowerCase() == widget.hostName.toLowerCase()));

    final hostProfile = matchesActiveHost
        ? activeHost
        : HostProfile(
            id: widget.hostId,
            userId: widget.hostId,
            displayName: widget.hostName.isNotEmpty ? widget.hostName : 'Verified Partner',
            email: '',
            phoneNumber: '',
            photoUrl: allHostedVehicles.isNotEmpty ? allHostedVehicles.first.hostAvatar : '',
            bio: 'Official PassionRide verified host and fleet owner offering top-tier bikes, cars, and experiences.',
            isVerified: true,
            verificationStatus: 'verified',
            trustScore: allHostedVehicles.isNotEmpty ? allHostedVehicles.first.hostTrustScore : 95.0,
          );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.hostName.isNotEmpty ? '${widget.hostName}\'s Store' : 'Host Showcase',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: 'Share Storefront',
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ShareProviderCatalogDialog.show(
                context,
                hostId: widget.hostId,
                hostName: widget.hostName.isNotEmpty ? widget.hostName : hostProfile.displayName,
                vehicles: allHostedVehicles,
                tours: hostedTours,
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Storefront Banner & Host Profile Card
            _buildHostHeaderCard(context, hostProfile, allHostedVehicles.length, hostedTours.length, isDark),
            const SizedBox(height: 12),

            // Category Filter Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCategoryChip('All', allHostedVehicles.length + hostedTours.length),
                    const SizedBox(width: 8),
                    _buildCategoryChip('Bikes & Scooters', bikesAndScooters.length),
                    const SizedBox(width: 8),
                    _buildCategoryChip('Cars & Four-Wheelers', carsAndSuvs.length),
                    const SizedBox(width: 8),
                    _buildCategoryChip('Tours & Experiences', hostedTours.length),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Content Based on Selected Filter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildCatalogList(
                context,
                allVehicles: allHostedVehicles,
                bikes: bikesAndScooters,
                cars: carsAndSuvs,
                tours: hostedTours,
                currencyFormatter: currencyFormatter,
                isDark: isDark,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHostHeaderCard(
    BuildContext context,
    HostProfile host,
    int vehicleCount,
    int tourCount,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceContainerDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.outlineVariantDark : Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(
                photoUrl: host.photoUrl,
                displayName: host.displayName,
                radius: 32,
                backgroundColor: AppColors.primary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            host.displayName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (host.isVerified) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.verified, color: Colors.blue, size: 18),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.shield, color: Colors.green, size: 13),
                              const SizedBox(width: 4),
                              Text(
                                'Trust: ${host.trustScore.toStringAsFixed(1)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$vehicleCount Vehicles • $tourCount Tours',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (host.bio.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              host.bio,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String title, int count) {
    final isSelected = _selectedCategory == title;
    return ChoiceChip(
      label: Text('$title ($count)'),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedCategory = title),
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : null,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildCatalogList(
    BuildContext context, {
    required List<Vehicle> allVehicles,
    required List<Vehicle> bikes,
    required List<Vehicle> cars,
    required List<Tour> tours,
    required NumberFormat currencyFormatter,
    required bool isDark,
  }) {
    List<Vehicle> displayedVehicles = [];
    List<Tour> displayedTours = [];

    if (_selectedCategory == 'All') {
      displayedVehicles = allVehicles;
      displayedTours = tours;
    } else if (_selectedCategory == 'Bikes & Scooters') {
      displayedVehicles = bikes;
    } else if (_selectedCategory == 'Cars & Four-Wheelers') {
      displayedVehicles = cars;
    } else if (_selectedCategory == 'Tours & Experiences') {
      displayedTours = tours;
    }

    if (displayedVehicles.isEmpty && displayedTours.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(Icons.inventory_2_outlined, size: 54, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No items found in "$_selectedCategory"',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'This provider hasn\'t published any listings in this category yet.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;
        final crossAxisCount = isWide ? 3 : (constraints.maxWidth > 500 ? 2 : 1);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (displayedVehicles.isNotEmpty) ...[
              Text(
                'Hosted Vehicles (${displayedVehicles.length})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: displayedVehicles.length,
                itemBuilder: (context, i) {
                  return _buildVehicleCard(context, displayedVehicles[i], currencyFormatter, isDark);
                },
              ),
              const SizedBox(height: 24),
            ],
            if (displayedTours.isNotEmpty) ...[
              Text(
                'Hosted Guided Tours (${displayedTours.length})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.9,
                ),
                itemCount: displayedTours.length,
                itemBuilder: (context, i) {
                  return _buildTourCard(context, displayedTours[i], currencyFormatter, isDark);
                },
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildVehicleCard(
    BuildContext context,
    Vehicle vehicle,
    NumberFormat currencyFormatter,
    bool isDark,
  ) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          final appState = Provider.of<AppState>(context, listen: false);
          appState.selectVehicle(vehicle);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const VehicleDetailScreen()),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    vehicle.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.directions_car, size: 48, color: Colors.grey),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        vehicle.category.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
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
                          vehicle.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${vehicle.transmission} • ${vehicle.fuelType} • ${vehicle.seats} Seats',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currencyFormatter.format(vehicle.pricePerDay),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const Text('/day', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: () {
                            final appState = Provider.of<AppState>(context, listen: false);
                            appState.selectVehicle(vehicle);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const VehicleDetailScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Book', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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

  Widget _buildTourCard(
    BuildContext context,
    Tour tour,
    NumberFormat currencyFormatter,
    bool isDark,
  ) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  tour.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.tour, size: 48, color: Colors.grey),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade900.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'GUIDED TOUR',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '📍 ${tour.location} • ⏳ ${tour.duration}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        currencyFormatter.format(tour.price),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              tour.rating.toStringAsFixed(1),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ],
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
}
