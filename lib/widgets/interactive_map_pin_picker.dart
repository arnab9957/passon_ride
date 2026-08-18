import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:free_map/free_map.dart';
import '../models/models.dart';
import '../services/location_service.dart';
import '../theme/app_colors.dart';

class InteractiveMapPinPicker extends StatefulWidget {
  final double initialLat;
  final double initialLng;
  final Function(LocationResult) onLocationPicked;

  const InteractiveMapPinPicker({
    super.key,
    required this.initialLat,
    required this.initialLng,
    required this.onLocationPicked,
  });

  @override
  State<InteractiveMapPinPicker> createState() => _InteractiveMapPinPickerState();
}

class _InteractiveMapPinPickerState extends State<InteractiveMapPinPicker>
    with SingleTickerProviderStateMixin {
  final LocationService _locationService = LocationService();
  final MapController _mapController = MapController();

  late double _pinLat;
  late double _pinLng;

  bool _isGeocoding = false;
  bool _isLocating = false;
  LocationResult? _pinLocationResult;
  Timer? _geocodeDebounce;

  // free_map search
  FmData? _selectedFmAddress;

  // Live user location marker
  LatLng? _userLivePosition;
  StreamSubscription<Position>? _positionStream;

  // Pin bounce animation
  late AnimationController _pinBounceController;
  late Animation<double> _pinOffsetAnim;
  bool _isMapMoving = false;

  @override
  void initState() {
    super.initState();
    _pinLat = widget.initialLat != 0.0 ? widget.initialLat : 22.5726;
    _pinLng = widget.initialLng != 0.0 ? widget.initialLng : 88.3639;

    _pinBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _pinOffsetAnim = Tween<double>(begin: 0, end: -14).animate(
      CurvedAnimation(parent: _pinBounceController, curve: Curves.easeOut),
    );

    _fetchAddressForPin(_pinLat, _pinLng);
    _startLiveLocationStream();
  }

  @override
  void dispose() {
    _geocodeDebounce?.cancel();
    _positionStream?.cancel();
    _pinBounceController.dispose();
    super.dispose();
  }

  Future<void> _startLiveLocationStream() async {
    final hasPermission = await _locationService.requestLocationPermission();
    if (!hasPermission) return;

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position pos) {
      if (!mounted) return;
      setState(() {
        _userLivePosition = LatLng(pos.latitude, pos.longitude);
      });
    });
  }

  void _fetchAddressForPin(double lat, double lng) {
    _geocodeDebounce?.cancel();
    setState(() => _isGeocoding = true);

    _geocodeDebounce = Timer(const Duration(milliseconds: 500), () async {
      final result = await _locationService.reverseGeocode(lat, lng);
      if (!mounted) return;
      setState(() {
        _pinLocationResult = result;
        _isGeocoding = false;
      });
    });
  }

  /// Called when the user selects a result from FmSearchField autocomplete
  void _onFmAddressSelected(FmData? data) {
    if (data == null) return;
    final lat = data.lat ?? _pinLat;
    final lng = data.lng ?? _pinLng;
    final ll = LatLng(lat, lng);
    _mapController.move(ll, 14.0);
    setState(() {
      _pinLat = lat;
      _pinLng = lng;
      _selectedFmAddress = data;
      _pinLocationResult = LocationResult(
        displayName: data.address ?? '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
        city: '',
        state: '',
        country: '',
        postalCode: '',
        latitude: lat,
        longitude: lng,
        isLive: false,
      );
    });
  }

  Future<void> _recenterOnGps() async {
    if (_isLocating) return;
    setState(() => _isLocating = true);

    try {
      final live = await _locationService.getCurrentLiveLocation();
      if (!mounted) return;
      final ll = LatLng(live.latitude, live.longitude);
      _mapController.move(ll, 15.0);
      setState(() {
        _pinLat = live.latitude;
        _pinLng = live.longitude;
        _pinLocationResult = live;
        _userLivePosition = ll;
      });
    } catch (_) {}

    if (mounted) setState(() => _isLocating = false);
  }

  void _onMapMoveStart(MapCamera camera, bool hasGesture) {
    if (!_isMapMoving) {
      _isMapMoving = true;
      _pinBounceController.forward();
    }
  }

  void _onMapMoveEnd(MapCamera camera) {
    if (_isMapMoving) {
      _isMapMoving = false;
      _pinBounceController.reverse();
    }
    final newCenter = camera.center;
    setState(() {
      _pinLat = newCenter.latitude;
      _pinLng = newCenter.longitude;
    });
    _fetchAddressForPin(_pinLat, _pinLng);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // 1. FmMap — free_map widget (OpenStreetMap tiles)
        FmMap(
          mapController: _mapController,
          mapOptions: MapOptions(
            initialCenter: LatLng(_pinLat, _pinLng),
            initialZoom: 14.0,
            minZoom: 5.0,
            maxZoom: 19.0,
            onMapEvent: (event) {
              if (event is MapEventMoveStart) {
                _onMapMoveStart(event.camera, true);
              } else if (event is MapEventMoveEnd) {
                _onMapMoveEnd(event.camera);
              } else if (event is MapEventScrollWheelZoom) {
                _onMapMoveEnd(event.camera);
              }
            },
          ),
          markers: [
            // Live user GPS blue dot
            if (_userLivePosition != null)
              Marker(
                point: _userLivePosition!,
                width: 30,
                height: 30,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.shade600,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.35),
                        blurRadius: 12,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),

        // 2. Animated center pin
        Center(
          child: AnimatedBuilder(
            animation: _pinOffsetAnim,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _pinOffsetAnim.value - 24),
                child: child,
              );
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.error.withOpacity(0.15),
                    border: Border.all(color: AppColors.error.withOpacity(0.4), width: 1.5),
                  ),
                ),
                Positioned(
                  bottom: -4,
                  child: Container(
                    width: 10,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const Icon(Icons.location_on, size: 48, color: AppColors.error),
              ],
            ),
          ),
        ),

        // 3. Top floating FmSearchField (free_map autocomplete)
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: FmSearchField(
              selectedValue: _selectedFmAddress,
              searchParams: const FmSearchParams(),
              onSelected: _onFmAddressSelected,
              textFieldBuilder: (focus, controller, onChanged) {
                return TextFormField(
                  focusNode: focus,
                  controller: controller,
                  onChanged: onChanged,
                  decoration: InputDecoration(
                    hintText: 'Search city, landmark or address...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                    suffixIcon: controller.text.trim().isEmpty || !focus.hasFocus
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: controller.clear,
                            visualDensity: VisualDensity.compact,
                          ),
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                );
              },
            ),
          ),
        ),

        // 4. Right-side map controls
        Positioned(
          right: 12,
          bottom: 190,
          child: Column(
            children: [
              _MapControlButton(
                heroTag: 'map_zoom_in_fm',
                icon: Icons.add,
                isDark: isDark,
                onPressed: () {
                  final currentZoom = _mapController.camera.zoom;
                  _mapController.move(_mapController.camera.center, currentZoom + 1);
                },
              ),
              const SizedBox(height: 8),
              _MapControlButton(
                heroTag: 'map_zoom_out_fm',
                icon: Icons.remove,
                isDark: isDark,
                onPressed: () {
                  final currentZoom = _mapController.camera.zoom;
                  _mapController.move(_mapController.camera.center, currentZoom - 1);
                },
              ),
              const SizedBox(height: 14),
              _MapControlButton(
                heroTag: 'map_gps_fm',
                icon: Icons.my_location,
                isDark: isDark,
                isPrimary: true,
                isLoading: _isLocating,
                onPressed: _recenterOnGps,
                tooltip: 'Jump to my GPS location',
              ),
            ],
          ),
        ),

        // 5. Bottom address card & confirm button
        Positioned(
          bottom: 12,
          left: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.pin_drop, size: 12, color: AppColors.onSecondaryContainer),
                          const SizedBox(width: 4),
                          Text(
                            'MAP PIN LOCATION',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSecondaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isGeocoding)
                      const Row(
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 6),
                          Text('Geocoding...', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Icon(Icons.map_outlined, size: 13, color: AppColors.secondary),
                          const SizedBox(width: 4),
                          Text(
                            'OpenStreetMap · free_map',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),

                const SizedBox(height: 10),

                Text(
                  _pinLocationResult?.displayName ?? 'Drag map to move pin...',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(Icons.my_location, size: 12, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      '${_pinLat.toStringAsFixed(5)}\u00b0, ${_pinLng.toStringAsFixed(5)}\u00b0',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _pinLocationResult == null || _isGeocoding
                        ? null
                        : () => widget.onLocationPicked(_pinLocationResult!),
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text(
                      'Confirm Pin Location',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.primary.withOpacity(0.4),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Reusable FAB-style map control button
class _MapControlButton extends StatelessWidget {
  final String heroTag;
  final IconData icon;
  final bool isDark;
  final bool isPrimary;
  final bool isLoading;
  final VoidCallback onPressed;
  final String? tooltip;

  const _MapControlButton({
    required this.heroTag,
    required this.icon,
    required this.isDark,
    required this.onPressed,
    this.isPrimary = false,
    this.isLoading = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: FloatingActionButton.small(
        heroTag: heroTag,
        backgroundColor: isPrimary
            ? AppColors.secondary
            : (isDark ? AppColors.surfaceDark : Colors.white),
        foregroundColor: isPrimary
            ? Colors.white
            : (isDark ? Colors.white : Colors.black87),
        elevation: 4,
        onPressed: onPressed,
        child: isLoading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isPrimary ? Colors.white : AppColors.primary,
                ),
              )
            : Icon(icon),
      ),
    );
  }
}
