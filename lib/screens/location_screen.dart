import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../services/location_service.dart';
import '../theme/app_colors.dart';
import '../widgets/interactive_map_pin_picker.dart';

class LocationScreen extends StatefulWidget {
  final bool isModal;
  final Function(LocationResult)? onLocationSelected;

  const LocationScreen({
    super.key,
    this.isModal = false,
    this.onLocationSelected,
  });

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final LocationService _locationService = LocationService();

  // Live Location State
  bool _isDetectingLiveLocation = false;
  LocationResult? _detectedLiveLocation;
  double _radarRadiusKm = 50.0;
  String _liveStatusMessage = 'Ready to calibrate device GPS sensor';

  // Manual Location State
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _zipController = TextEditingController();

  List<LocationResult> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounceTimer;
  LocationResult? _selectedManualLocation;
  bool _showCustomAddressForm = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final appState = Provider.of<AppState>(context, listen: false);

    if (appState.currentLocationResult != null) {
      if (appState.isLiveLocationActive) {
        _detectedLiveLocation = appState.currentLocationResult;
      } else {
        _selectedManualLocation = appState.currentLocationResult;
        _cityController.text = appState.currentLocationResult!.city;
        _stateController.text = appState.currentLocationResult!.state;
        _zipController.text = appState.currentLocationResult!.postalCode;
      }
    } else {
      _selectedManualLocation = LocationResult(
        displayName: appState.selectedLocation,
        latitude: appState.userLatitude,
        longitude: appState.userLongitude,
        isLive: false,
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // Detect Live Location via GPS & Reverse Geocoding
  Future<void> _detectLiveLocation() async {
    setState(() {
      _isDetectingLiveLocation = true;
      _liveStatusMessage = 'Connecting to satellite GPS & cellular triangulator...';
    });

    try {
      final liveResult = await _locationService.getCurrentLiveLocation();
      if (!mounted) return;

      setState(() {
        _detectedLiveLocation = liveResult;
        _isDetectingLiveLocation = false;
        _liveStatusMessage = 'GPS signal locked with high precision';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📍 Live GPS Detected: ${liveResult.displayName}'),
          backgroundColor: AppColors.secondary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isDetectingLiveLocation = false;
        _liveStatusMessage = 'Failed to acquire live GPS. Please try again.';
      });
    }
  }

  // Handle Manual Place Search with Debounce
  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
      final results = await _locationService.searchLocations(query);
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    });
  }

  void _applyAndSaveLocation(LocationResult location, {required bool isLive}) {
    final appState = Provider.of<AppState>(context, listen: false);
    if (isLive) {
      appState.setLiveLocation(location);
    } else {
      appState.setManualLocation(location);
    }

    if (widget.onLocationSelected != null) {
      widget.onLocationSelected!(location);
    }

    Navigator.of(context).pop(location);
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final content = Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        elevation: 0,
        leading: widget.isModal
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Rental Location',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Active: ${appState.selectedLocation} (${appState.isLiveLocationActive ? "📡 Live GPS" : "📍 Manual"})',
              style: TextStyle(
                fontSize: 11,
                color: appState.isLiveLocationActive ? AppColors.secondary : Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryContainer],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: Colors.white,
              unselectedLabelColor: isDark ? Colors.white70 : Colors.black87,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: const [
                Tab(
                  icon: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.my_location, size: 14),
                      SizedBox(width: 4),
                      Text('Live'),
                    ],
                  ),
                ),
                Tab(
                  icon: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search, size: 14),
                      SizedBox(width: 4),
                      Text('Manual'),
                    ],
                  ),
                ),
                Tab(
                  icon: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.map, size: 14),
                      SizedBox(width: 4),
                      Text('Pick on Map'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLiveLocationTab(context, appState, isDark),
          _buildManualLocationTab(context, appState, isDark),
          InteractiveMapPinPicker(
            initialLat: appState.userLatitude,
            initialLng: appState.userLongitude,
            onLocationPicked: (result) => _applyAndSaveLocation(result, isLive: false),
          ),
        ],
      ),
    );

    if (widget.isModal) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.90,
          child: content,
        ),
      );
    }

    return content;
  }

  // ==========================================
  // TAB 1: LIVE LOCATION IMPLEMENTATION
  // ==========================================
  Widget _buildLiveLocationTab(BuildContext context, AppState appState, bool isDark) {
    final liveLoc = _detectedLiveLocation ??
        (appState.isLiveLocationActive ? appState.currentLocationResult : null);

    final nearbyCount = liveLoc != null
        ? _locationService.getPopularHubs().isNotEmpty
            ? appState.vehicles
                .where((v) =>
                    _locationService.calculateDistanceKm(
                        liveLoc.latitude, liveLoc.longitude, v.latitude, v.longitude) <=
                    _radarRadiusKm)
                .length
            : 0
        : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Radar & Pulse Graphic Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [AppColors.surfaceContainerHighDark, AppColors.surfaceContainerDark]
                    : [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.secondary.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondary.withOpacity(0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                // Sonar / Radar Visual Pulse
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.secondary.withOpacity(0.1),
                        border: Border.all(
                          color: AppColors.secondary.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                    ),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.secondary.withOpacity(0.2),
                      ),
                    ),
                    Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.secondary,
                      ),
                      child: _isDetectingLiveLocation
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.satellite_alt, color: Colors.white, size: 26),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  _isDetectingLiveLocation ? 'Detecting Live Position...' : 'Real-time GPS Tracking',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _liveStatusMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: _isDetectingLiveLocation ? null : _detectLiveLocation,
                  icon: const Icon(Icons.my_location, size: 18),
                  label: Text(
                    liveLoc != null ? 'Refresh Live GPS' : 'Detect My Current Location',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Detected Location Details & Proximity Card
          if (liveLoc != null) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceContainerDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle, color: AppColors.onSecondaryContainer, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'CALIBRATED & VERIFIED',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.onSecondaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        liveLoc.accuracy,
                        style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.place, color: AppColors.primary, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              liveLoc.displayName,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${liveLoc.city.isNotEmpty ? "${liveLoc.city}, " : ""}${liveLoc.state.isNotEmpty ? "${liveLoc.state}, " : ""}${liveLoc.country}',
                              style: const TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  // Coordinates Chip Row
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceContainerHighDark : AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('LATITUDE', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                              Text(
                                '${liveLoc.latitude.toStringAsFixed(5)}° N',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceContainerHighDark : AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('LONGITUDE', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                              Text(
                                '${liveLoc.longitude.toStringAsFixed(5)}° W',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Proximity Radius Slider & Count
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Search Radius: ${_radarRadiusKm.round()} km',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$nearbyCount rides found nearby',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _radarRadiusKm,
                    min: 5,
                    max: 100,
                    divisions: 19,
                    activeColor: AppColors.secondary,
                    onChanged: (val) => setState(() => _radarRadiusKm = val),
                  ),
                  const SizedBox(height: 12),
                  // Confirm Live Location CTA
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _applyAndSaveLocation(liveLoc, isLive: true),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text(
                        'Use This Live Location',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Explanatory placeholder when not detected yet
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary, size: 24),
                  SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Tap "Detect My Current Location" to calculate exact distance to every vehicle and tour in real time.',
                      style: TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: MANUAL LOCATION IMPLEMENTATION
  // ==========================================
  Widget _buildManualLocationTab(BuildContext context, AppState appState, bool isDark) {
    final popularHubs = _locationService.getPopularHubs();
    final recentLocations = appState.recentLocations;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Switch to Interactive Map Pin Picker Card
          InkWell(
            onTap: () => _tabController.animateTo(2), // Switch to Tab 3 (Map Pin Picker)
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [AppColors.surfaceContainerHighDark, AppColors.surfaceContainerDark]
                      : [AppColors.primaryContainer, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.map, color: Colors.white, size: 22),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pick Directly From Map Pin 🗺️',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Drag map or drop pin to fetch precise street address & coordinates',
                          style: TextStyle(fontSize: 11, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Search Input Bar
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search city, state, address, or landmark...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
              filled: true,
              fillColor: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Search Autocomplete Results List
          if (_searchResults.isNotEmpty) ...[
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceContainerDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
                ),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _searchResults.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = _searchResults[index];
                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.primaryFixed,
                      child: Icon(Icons.place, color: AppColors.primary, size: 20),
                    ),
                    title: Text(
                      item.displayName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: Text(
                      '${item.city.isNotEmpty ? "${item.city}, " : ""}${item.state} (${item.latitude.toStringAsFixed(2)}, ${item.longitude.toStringAsFixed(2)})',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                    onTap: () {
                      setState(() => _selectedManualLocation = item);
                      _applyAndSaveLocation(item, isLive: false);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Expandable Custom Address Form Button
          OutlinedButton.icon(
            onPressed: () => setState(() => _showCustomAddressForm = !_showCustomAddressForm),
            icon: Icon(_showCustomAddressForm ? Icons.keyboard_arrow_up : Icons.add_location_alt, size: 18),
            label: Text(_showCustomAddressForm ? 'Hide Custom Address Form' : 'Enter Specific Pickup Address Manually'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),

          // Custom Detailed Address Form
          if (_showCustomAddressForm) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Custom Pickup Coordinates', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _streetController,
                    decoration: const InputDecoration(
                      labelText: 'Street Address / Area',
                      prefixIcon: Icon(Icons.streetview),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _cityController,
                          decoration: const InputDecoration(
                            labelText: 'City / Metro',
                            prefixIcon: Icon(Icons.location_city),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _stateController,
                          decoration: const InputDecoration(
                            labelText: 'State / Province',
                            prefixIcon: Icon(Icons.map),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _zipController,
                    decoration: const InputDecoration(
                      labelText: 'Postal / ZIP Code',
                      prefixIcon: Icon(Icons.pin),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final city = _cityController.text.trim();
                        final state = _stateController.text.trim();
                        final street = _streetController.text.trim();
                        final zip = _zipController.text.trim();

                        if (city.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please specify at least a City name.')),
                          );
                          return;
                        }

                        final display = [
                          if (street.isNotEmpty) street,
                          city,
                          if (state.isNotEmpty) state,
                          if (zip.isNotEmpty) zip,
                        ].join(', ');

                        final customResult = LocationResult(
                          displayName: display,
                          city: city,
                          state: state,
                          postalCode: zip,
                          latitude: appState.userLatitude,
                          longitude: appState.userLongitude,
                          isLive: false,
                          accuracy: 'Manual Custom Entry',
                        );

                        _applyAndSaveLocation(customResult, isLive: false);
                      },
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Apply Custom Address'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Popular Cities & Hubs Quick Grid
          const Text(
            'Popular Fleet Hubs & Cities',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: popularHubs.map((hub) {
              final isSelected = appState.selectedLocation.toLowerCase().contains(hub.city.toLowerCase()) ||
                  hub.displayName.toLowerCase() == appState.selectedLocation.toLowerCase();

              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSelected ? Icons.check_circle : Icons.location_city,
                      size: 14,
                      color: isSelected ? Colors.white : AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${hub.city}, ${hub.state.isNotEmpty ? hub.state.substring(0, hub.state.length > 2 ? 2 : hub.state.length).toUpperCase() : hub.country}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : null,
                      ),
                    ),
                  ],
                ),
                selected: isSelected,
                selectedColor: AppColors.primary,
                backgroundColor: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLow,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedManualLocation = hub);
                    _applyAndSaveLocation(hub, isLive: false);
                  }
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Recent Searches & Saved Locations
          if (recentLocations.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Locations',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => appState.clearRecentLocations(),
                  child: const Text('Clear History', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceContainerDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
                ),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentLocations.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final recent = recentLocations[index];
                  return ListTile(
                    leading: Icon(
                      recent.isLive ? Icons.my_location : Icons.history,
                      color: recent.isLive ? AppColors.secondary : Colors.grey,
                      size: 20,
                    ),
                    title: Text(
                      recent.displayName,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      recent.isLive ? '📡 Live GPS Result' : '📍 Manual Entry',
                      style: TextStyle(
                        fontSize: 11,
                        color: recent.isLive ? AppColors.secondary : Colors.grey,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () => _applyAndSaveLocation(recent, isLive: recent.isLive),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Helper function to open Location selection as an interactive modal sheet
Future<LocationResult?> showLocationPickerModal(
  BuildContext context, {
  Function(LocationResult)? onLocationSelected,
}) {
  return showModalBottomSheet<LocationResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => LocationScreen(
      isModal: true,
      onLocationSelected: onLocationSelected,
    ),
  );
}
