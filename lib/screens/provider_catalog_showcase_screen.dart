import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/user_avatar.dart';
import '../widgets/share_provider_catalog_dialog.dart';
import '../widgets/hotel_details_modal.dart';
import '../widgets/tour_details_modal.dart';
import 'main_navigation_screen.dart';

class ProviderCatalogShowcaseScreen extends StatefulWidget {
  final String hostId;
  final String hostName;

  /// Vehicle to open straight away (from a shared product link).
  final String? initialItemId;

  const ProviderCatalogShowcaseScreen({
    super.key,
    required this.hostId,
    required this.hostName,
    this.initialItemId,
  });

  @override
  State<ProviderCatalogShowcaseScreen> createState() =>
      _ProviderCatalogShowcaseScreenState();
}

class _ProviderCatalogShowcaseScreenState
    extends State<ProviderCatalogShowcaseScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'All';
  AppState? _appState;
  int _initialNavIndex = 0;
  bool _redirected = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _appState = Provider.of<AppState>(context, listen: false);
    _initialNavIndex = _appState!.currentNavIndex;
    _appState!.addListener(_onAppStateChanged);
    _pendingItemId = widget.initialItemId;
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryOpenSharedItem());
  }

  String? _pendingItemId;

  /// Opens the vehicle from a shared link once the catalogue has loaded.
  void _tryOpenSharedItem() {
    final id = _pendingItemId;
    final appState = _appState;
    if (id == null || id.isEmpty || appState == null || !mounted || _redirected) return;
    final match = appState.vehicles.where((v) => v.id == id);
    if (match.isEmpty) return;
    _pendingItemId = null;
    _openVehicle(match.first);
  }

  /// Booking flows (verification, checkout, My Bookings…) switch pages via
  /// `setNavIndex`, which only renders inside [MainNavigationScreen]. When the
  /// storefront was opened from a shared link it is the app's root, so we hand
  /// off to the main shell as soon as the nav index changes.
  void _onAppStateChanged() {
    final appState = _appState;
    if (_redirected || !mounted || appState == null) return;
    if (_pendingItemId != null) {
      _tryOpenSharedItem();
      return;
    }
    if (appState.currentNavIndex == _initialNavIndex) return;
    _openMainShell();
  }

  /// Push the main shell on top of the storefront so that backing out of the
  /// page it was entered on (vehicle details, My Bookings…) returns here.
  Future<void> _openMainShell() async {
    final appState = _appState!;
    _redirected = true;
    appState.markStorefrontEntry();
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const MainNavigationScreen()));
    appState.clearStorefrontEntry();
    if (!mounted) return;
    // Restore the nav index the storefront was opened with, then resume listening.
    appState.setNavIndex(_initialNavIndex);
    _redirected = false;
  }

  void _goToMainApp({bool home = false}) {
    if (home) {
      _appState?.setNavIndex(0);
    }
    _appState?.clearStorefrontEntry();
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      (_) => false,
    );
  }

  /// Vehicle details and the booking flow live inside [MainNavigationScreen]
  /// (page 2 → verification 3 → checkout), so open them there rather than as
  /// a bare route, which has no Scaffold/theme text styles.
  void _openVehicle(Vehicle vehicle) {
    final appState = _appState!;
    _redirected = true;
    appState.selectVehicle(vehicle);
    appState.setNavIndex(2);
    _openMainShell();
  }

  @override
  void dispose() {
    _appState?.removeListener(_onAppStateChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    // Fetch this host's vehicles, tours & stays. Listings may be saved under the raw
    // login id or a 'mth_' / 'chd_' account id, so compare ids without that prefix.
    String bare(String id) => id.trim().replaceFirst(RegExp(r'^(mth_|chd_)'), '');
    final hostKey = bare(widget.hostId);
    final nameKey = widget.hostName.trim().toLowerCase();
    // Viewing your own store: use exactly what your dashboard shows.
    final isOwnStore = hostKey.isNotEmpty &&
        appState.allActiveUserIds.any((id) => bare(id) == hostKey);
    bool sameHost(String id, String name) {
      if (hostKey.isNotEmpty && id.trim().isNotEmpty && bare(id) == hostKey) return true;
      return nameKey.isNotEmpty && name.trim().toLowerCase() == nameKey;
    }

    final allHostedVehicles = appState.vehicles.where((v) {
      if (isOwnStore && appState.hostedVehiclesForActiveAccount.any((m) => m.id == v.id)) return true;
      return sameHost(v.hostId, v.hostName) || (v.ownerAccountId.isNotEmpty && sameHost(v.ownerAccountId, ''));
    }).toList();

    final bikesAndScooters = allHostedVehicles.where((v) {
      final t = v.type.toString().toLowerCase();
      final cat = v.category.toLowerCase();
      return t.contains('bike') ||
          t.contains('scooter') ||
          cat.contains('bike') ||
          cat.contains('scooter') ||
          cat.contains('two');
    }).toList();

    final carsAndSuvs = allHostedVehicles.where((v) {
      final t = v.type.toString().toLowerCase();
      final cat = v.category.toLowerCase();
      return t.contains('car') ||
          cat.contains('car') ||
          cat.contains('suv') ||
          cat.contains('four');
    }).toList();

    final hostedTours = appState.tours.where((t) {
      if (isOwnStore && appState.isHostOfTour(t)) return true;
      return sameHost(t.hostId, t.guideName);
    }).toList();

    final hostedHotels = appState.hotels.where((h) => sameHost(h.hostId, h.hostName)).toList();

    // Host profile summary fallback
    final activeHost = appState.hostProfile;
    final bool matchesActiveHost =
        activeHost != null &&
        (activeHost.userId == widget.hostId ||
            activeHost.id == widget.hostId ||
            (activeHost.displayName.isNotEmpty &&
                widget.hostName.isNotEmpty &&
                activeHost.displayName.toLowerCase() ==
                    widget.hostName.toLowerCase()));

    final hostProfile = matchesActiveHost
        ? activeHost
        : HostProfile(
            id: widget.hostId,
            userId: widget.hostId,
            displayName: widget.hostName.isNotEmpty
                ? widget.hostName
                : 'Verified Partner',
            email: '',
            phoneNumber: '',
            photoUrl: allHostedVehicles.isNotEmpty
                ? allHostedVehicles.first.hostAvatar
                : '',
            bio:
                'Official PassionRide verified host and fleet owner offering top-tier bikes, cars, and experiences.',
            isVerified: true,
            verificationStatus: 'verified',
            trustScore: allHostedVehicles.isNotEmpty
                ? allHostedVehicles.first.hostTrustScore
                : 95.0,
          );

    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      appBar: AppBar(
        leading: canPop
            ? null
            : IconButton(
                tooltip: 'Go to PassionRide',
                icon: const Icon(Icons.home_outlined),
                onPressed: () {
                  _redirected = true;
                  _goToMainApp(home: true);
                },
              ),
        title: Text(
          widget.hostName.isNotEmpty
              ? '${widget.hostName}\'s Store'
              : 'Host Showcase',
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
                hostName: widget.hostName.isNotEmpty
                    ? widget.hostName
                    : hostProfile.displayName,
                vehicles: allHostedVehicles,
                tours: hostedTours,
                hotels: hostedHotels,
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
            _buildHostHeaderCard(
              context,
              hostProfile,
              allHostedVehicles.length,
              hostedTours.length,
              hostedHotels.length,
              isDark,
            ),
            const SizedBox(height: 12),

            // Category Filter Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCategoryChip(
                      'All',
                      allHostedVehicles.length +
                          hostedTours.length +
                          hostedHotels.length,
                    ),
                    const SizedBox(width: 8),
                    _buildCategoryChip('Vehicles', allHostedVehicles.length),
                    const SizedBox(width: 8),
                    _buildCategoryChip('Tours', hostedTours.length),
                    const SizedBox(width: 8),
                    _buildCategoryChip('Hotels', hostedHotels.length),
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
                hotels: hostedHotels,
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
    int hotelCount,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceContainerDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.outlineVariantDark : Colors.grey.shade200,
        ),
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
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (host.isVerified) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.verified,
                            color: Colors.blue,
                            size: 18,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.shield,
                                color: Colors.green,
                                size: 13,
                              ),
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
                          '$vehicleCount Vehicles • $tourCount Tours • $hotelCount Stays',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
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
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected
            ? Colors.white
            : Theme.of(context).colorScheme.onSurface,
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
    required List<Hotel> hotels,
    required NumberFormat currencyFormatter,
    required bool isDark,
  }) {
    List<Vehicle> displayedVehicles = [];
    List<Tour> displayedTours = [];
    final displayedHotels =
        _selectedCategory == 'All' || _selectedCategory == 'Hotels'
        ? hotels
        : <Hotel>[];

    if (_selectedCategory == 'All') {
      displayedVehicles = allVehicles;
      displayedTours = tours;
    } else if (_selectedCategory == 'Vehicles') {
      displayedVehicles = allVehicles;
    } else if (_selectedCategory == 'Tours') {
      displayedTours = tours;
    }

    if (displayedVehicles.isEmpty &&
        displayedTours.isEmpty &&
        displayedHotels.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 54,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'No items found in "$_selectedCategory"',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'This provider hasn\'t published any listings in this category yet.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;
        final crossAxisCount = isWide
            ? 3
            : (constraints.maxWidth > 500 ? 2 : 1);
        // Card height = 4:3 photo at the column width + fixed details area.
        final itemWidth =
            (constraints.maxWidth - 16 * (crossAxisCount - 1)) / crossAxisCount;
        final cardExtent = itemWidth / _imageAspect + _cardBodyHeight;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (displayedVehicles.isNotEmpty) ...[
              Text(
                'Hosted Vehicles (${displayedVehicles.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  mainAxisExtent: cardExtent,
                ),
                itemCount: displayedVehicles.length,
                itemBuilder: (context, i) {
                  return _buildVehicleCard(
                    context,
                    displayedVehicles[i],
                    currencyFormatter,
                    isDark,
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
            if (displayedTours.isNotEmpty) ...[
              Text(
                'Hosted Guided Tours (${displayedTours.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  mainAxisExtent: cardExtent,
                ),
                itemCount: displayedTours.length,
                itemBuilder: (context, i) {
                  return _buildTourCard(
                    context,
                    displayedTours[i],
                    currencyFormatter,
                    isDark,
                  );
                },
              ),
              const SizedBox(height: 24),
            ],

            if (displayedHotels.isNotEmpty) ...[
              Text(
                'Hotels & Stays (${displayedHotels.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  mainAxisExtent: cardExtent,
                ),
                itemCount: displayedHotels.length,
                itemBuilder: (context, i) {
                  return _buildHotelCard(
                    context,
                    displayedHotels[i],
                    currencyFormatter,
                  );
                },
              ),
            ],
          ],
        );
      },
    );
  }

  // ---------- Card building blocks ----------

  /// Every listing photo uses the same 4:3 frame; the text area below is fixed.
  static const double _imageAspect = 4 / 3;
  static const double _cardBodyHeight = 182;

  static String? _joinOrNull(List<String> parts, [String sep = ' • ']) =>
      parts.isEmpty ? null : parts.join(sep);

  Widget _cardImage(
    String url,
    IconData fallback, {
    String? badge,
    Color? badgeColor,
    Widget? trailing,
  }) {
    Widget fallbackBox(BuildContext context, Object error, StackTrace? stack) =>
        Container(
          color: Colors.grey.shade200,
          child: Icon(fallback, size: 44, color: Colors.grey),
        );
    return AspectRatio(
      aspectRatio: _imageAspect,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Blurred fill behind so the whole photo (contain) never looks letterboxed.
          ClipRect(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: fallbackBox,
              ),
            ),
          ),
          Image.network(url, fit: BoxFit.contain, errorBuilder: fallbackBox),
          if (badge != null)
            Positioned(
              top: 8,
              left: 8,
              child: _pill(
                badge,
                badgeColor ?? Colors.black.withValues(alpha: 0.65),
                Colors.white,
              ),
            ),
          if (trailing != null) Positioned(top: 8, right: 8, child: trailing),
        ],
      ),
    );
  }

  Widget _pill(String text, Color bg, Color fg, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: fg),
            const SizedBox(width: 3),
          ],
          Text(
            text,
            style: TextStyle(
              color: fg,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _ratingPill(double rating, int reviews) {
    return _pill(
      reviews == 0 ? 'New' : '${rating.toStringAsFixed(1)} ($reviews)',
      Colors.white.withValues(alpha: 0.92),
      Colors.black87,
      icon: Icons.star_rounded,
    );
  }

  Widget _infoRow(BuildContext context, IconData icon, String text) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Icon(icon, size: 13, color: muted),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.5, color: muted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceAndButton({
    required String price,
    required String unit,
    required VoidCallback onPressed,
    String? extra,
  }) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: price,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    TextSpan(
                      text: ' $unit',
                      style: TextStyle(fontSize: 11, color: muted),
                    ),
                  ],
                ),
              ),
              if (extra != null)
                Text(
                  extra,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10.5, color: muted),
                ),
            ],
          ),
        ),
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            minimumSize: Size.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            'Book',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _cardShell({
    required VoidCallback onTap,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _cardBody({
    required String title,
    required List<Widget> details,
    required Widget footer,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            ...details,
            const Spacer(),
            footer,
          ],
        ),
      ),
    );
  }

  // ---------- Cards ----------

  Widget _buildVehicleCard(
    BuildContext context,
    Vehicle vehicle,
    NumberFormat currencyFormatter,
    bool isDark,
  ) {
    final available =
        vehicle.status.isEmpty || vehicle.status.toLowerCase() == 'available';
    final specs = _joinOrNull([
      if (vehicle.transmission.isNotEmpty) vehicle.transmission,
      if (vehicle.fuelType.isNotEmpty) vehicle.fuelType,
      if (vehicle.seats > 0) '${vehicle.seats} Seats',
    ]);
    final hasCustom =
        vehicle.customTimeRangePrice > 0 &&
        vehicle.customTimeRangeStart.isNotEmpty &&
        vehicle.customTimeRangeEnd.isNotEmpty;
    return _cardShell(
      onTap: () => _openVehicle(vehicle),
      children: [
        _cardImage(
          vehicle.imageUrl,
          Icons.two_wheeler,
          badge: vehicle.category.toUpperCase(),
          trailing: _ratingPill(vehicle.rating, vehicle.reviewCount),
        ),
        _cardBody(
          title: vehicle.title,
          details: [
            if (specs != null)
              _infoRow(context, Icons.settings_outlined, specs),
            if (vehicle.location.isNotEmpty)
              _infoRow(context, Icons.location_on_outlined, vehicle.location),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                available
                    ? _pill(
                        'Available',
                        Colors.green.shade50,
                        Colors.green.shade800,
                        icon: Icons.check_circle,
                      )
                    : _pill(
                        vehicle.status,
                        Colors.orange.shade50,
                        Colors.orange.shade900,
                        icon: Icons.schedule,
                      ),
                if (vehicle.isInstantBookable)
                  _pill(
                    'Instant Book',
                    Colors.blue.shade50,
                    Colors.blue.shade800,
                    icon: Icons.bolt,
                  ),
                if (vehicle.quantity > 1)
                  _pill(
                    '${vehicle.quantity} units',
                    Colors.grey.shade200,
                    Colors.black87,
                  ),
              ],
            ),
          ],
          footer: _priceAndButton(
            price: currencyFormatter.format(vehicle.pricePerDay),
            unit: '/day',
            onPressed: () => _openVehicle(vehicle),
            extra: _joinOrNull([
              if (vehicle.pricePerHour > 0)
                '${currencyFormatter.format(vehicle.pricePerHour)}/hr',
              if (hasCustom)
                '${currencyFormatter.format(vehicle.customTimeRangePrice)} (${vehicle.customTimeRangeStart}-${vehicle.customTimeRangeEnd})',
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildHotelCard(
    BuildContext context,
    Hotel hotel,
    NumberFormat currencyFormatter,
  ) {
    void open() => showHotelDetailsModal(
      context,
      Provider.of<AppState>(context, listen: false),
      hotel,
    );
    final guests = _joinOrNull([
      if (hotel.maxGuests > 0) 'Up to ${hotel.maxGuests} guests',
      if (hotel.checkInTime.isNotEmpty) 'Check-in ${hotel.checkInTime}',
    ]);
    return _cardShell(
      onTap: open,
      children: [
        _cardImage(
          hotel.imageUrl,
          Icons.hotel,
          badge: hotel.roomType.isNotEmpty
              ? hotel.roomType.toUpperCase()
              : 'STAY',
          badgeColor: Colors.teal.shade800.withValues(alpha: 0.85),
          trailing: _ratingPill(hotel.rating, hotel.reviewCount),
        ),
        _cardBody(
          title: hotel.name,
          details: [
            if (hotel.location.isNotEmpty)
              _infoRow(context, Icons.location_on_outlined, hotel.location),
            if (guests != null) _infoRow(context, Icons.people_outline, guests),
            if (hotel.amenities.isNotEmpty)
              _infoRow(
                context,
                Icons.room_service_outlined,
                hotel.amenities.take(3).join(' • '),
              ),
            const SizedBox(height: 6),
            hotel.isAvailable
                ? _pill(
                    'Available',
                    Colors.green.shade50,
                    Colors.green.shade800,
                    icon: Icons.check_circle,
                  )
                : _pill(
                    'Fully booked',
                    Colors.red.shade50,
                    Colors.red.shade800,
                    icon: Icons.block,
                  ),
          ],
          footer: _priceAndButton(
            price: currencyFormatter.format(hotel.pricePerNight),
            unit: '/night',
            onPressed: open,
            extra: hotel.totalRooms > 0
                ? '${hotel.availableRooms}/${hotel.totalRooms} rooms free'
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildTourCard(
    BuildContext context,
    Tour tour,
    NumberFormat currencyFormatter,
    bool isDark,
  ) {
    void open() => showTourDetailsModal(
      context,
      Provider.of<AppState>(context, listen: false),
      tour,
    );
    return _cardShell(
      onTap: open,
      children: [
        _cardImage(
          tour.imageUrl,
          Icons.tour,
          badge: 'GUIDED TOUR',
          badgeColor: Colors.purple.shade900.withValues(alpha: 0.8),
          trailing: _ratingPill(tour.rating, tour.reviewCount),
        ),
        _cardBody(
          title: tour.title,
          details: [
            if (tour.location.isNotEmpty)
              _infoRow(context, Icons.location_on_outlined, tour.location),
            if (tour.duration.isNotEmpty)
              _infoRow(context, Icons.schedule, tour.duration),
            if (tour.waypoints.isNotEmpty)
              _infoRow(
                context,
                Icons.route_outlined,
                tour.waypoints.take(3).join(' → '),
              ),
            if (tour.includedGear.isNotEmpty)
              _infoRow(
                context,
                Icons.backpack_outlined,
                'Includes: ${tour.includedGear.take(3).join(', ')}',
              ),
          ],
          footer: _priceAndButton(
            price: currencyFormatter.format(tour.price),
            unit: '/person',
            onPressed: open,
          ),
        ),
      ],
    );
  }
}
