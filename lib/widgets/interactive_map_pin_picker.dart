import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
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

class _InteractiveMapPinPickerState extends State<InteractiveMapPinPicker> {
  final LocationService _locationService = LocationService();

  late double _pinLat;
  late double _pinLng;
  double _zoomLevel = 14.0; // 10 to 18

  bool _isGeocoding = false;
  LocationResult? _pinLocationResult;
  Timer? _geocodeDebounce;

  // Search autocomplete
  final TextEditingController _searchController = TextEditingController();
  List<LocationResult> _searchResults = [];
  bool _isSearching = false;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _pinLat = widget.initialLat;
    _pinLng = widget.initialLng;
    _fetchAddressForPin(_pinLat, _pinLng);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _geocodeDebounce?.cancel();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _fetchAddressForPin(double lat, double lng) {
    _geocodeDebounce?.cancel();
    setState(() => _isGeocoding = true);

    _geocodeDebounce = Timer(const Duration(milliseconds: 350), () async {
      final result = await _locationService.reverseGeocode(lat, lng);
      if (!mounted) return;
      setState(() {
        _pinLocationResult = result;
        _isGeocoding = false;
      });
    });
  }

  void _onPanUpdate(DragUpdateDetails details, Size screenSize) {
    // Map pan scale factor based on zoom level
    final double latDegPerPx = 0.05 / pow(2, _zoomLevel - 10);
    final double lngDegPerPx = 0.05 / pow(2, _zoomLevel - 10);

    setState(() {
      _pinLat -= details.delta.dy * latDegPerPx;
      _pinLng -= details.delta.dx * lngDegPerPx;
    });

    _fetchAddressForPin(_pinLat, _pinLng);
  }

  void _onTapMap(TapUpDetails details, Size screenSize) {
    final double centerPxX = screenSize.width / 2;
    final double centerPxY = screenSize.height / 2;

    final double deltaX = details.localPosition.dx - centerPxX;
    final double deltaY = details.localPosition.dy - centerPxY;

    final double latDegPerPx = 0.05 / pow(2, _zoomLevel - 10);
    final double lngDegPerPx = 0.05 / pow(2, _zoomLevel - 10);

    setState(() {
      _pinLat -= deltaY * latDegPerPx;
      _pinLng += deltaX * lngDegPerPx;
    });

    _fetchAddressForPin(_pinLat, _pinLng);
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    _searchDebounce = Timer(const Duration(milliseconds: 400), () async {
      final results = await _locationService.searchLocations(query);
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    });
  }

  void _recenterOnGps() async {
    final appState = Provider.of<AppState>(context, listen: false);
    setState(() => _isGeocoding = true);
    final live = await _locationService.getCurrentLiveLocation();
    if (!mounted) return;
    setState(() {
      _pinLat = live.latitude;
      _pinLng = live.longitude;
      _pinLocationResult = live;
      _isGeocoding = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;

    return Stack(
      children: [
        // 1. Interactive Map Canvas with Pan & Tap Gestures
        GestureDetector(
          onPanUpdate: (details) => _onPanUpdate(details, screenSize),
          onTapUp: (details) => _onTapMap(details, screenSize),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: isDark ? const Color(0xFF0C192E) : const Color(0xFFE5E9F0),
            child: CustomPaint(
              painter: _MapCanvasPainter(
                centerLat: _pinLat,
                centerLng: _pinLng,
                zoom: _zoomLevel,
                isDark: isDark,
                vehicles: appState.vehicles,
              ),
            ),
          ),
        ),

        // 2. Fixed Center Pin Marker with Animation & Pulsing Ring
        Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 36), // Offset pin point to exact center
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Pulse Ring
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.secondary.withOpacity(0.2),
                    border: Border.all(color: AppColors.secondary.withOpacity(0.4), width: 1.5),
                  ),
                ),
                // Pin Icon
                const Icon(
                  Icons.location_on,
                  size: 48,
                  color: AppColors.error,
                ),
                // Center Dot
                Positioned(
                  bottom: 12,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 3. Top Floating Search Bar & Autocomplete
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search city or address to jump pin...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.primary),
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
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              if (_searchResults.isNotEmpty) ...[
                const SizedBox(height: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceContainerDark : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                    itemCount: _searchResults.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _searchResults[index];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.place, color: AppColors.primary, size: 18),
                        title: Text(item.displayName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        subtitle: Text('${item.latitude.toStringAsFixed(3)}, ${item.longitude.toStringAsFixed(3)}', style: const TextStyle(fontSize: 11)),
                        onTap: () {
                          setState(() {
                            _pinLat = item.latitude;
                            _pinLng = item.longitude;
                            _pinLocationResult = item;
                            _searchResults = [];
                            _searchController.clear();
                          });
                          _fetchAddressForPin(_pinLat, _pinLng);
                        },
                      );
                    },
                  ),
                ),
                ),
              ],
            ],
          ),
        ),

        // 4. Map Zoom & GPS Control Buttons (Right side)
        Positioned(
          right: 16,
          top: 90,
          child: Column(
            children: [
              FloatingActionButton.small(
                heroTag: 'map_zoom_in',
                backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
                foregroundColor: isDark ? Colors.white : Colors.black87,
                onPressed: () => setState(() => _zoomLevel = min(18.0, _zoomLevel + 1.0)),
                child: const Icon(Icons.add),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'map_zoom_out',
                backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
                foregroundColor: isDark ? Colors.white : Colors.black87,
                onPressed: () => setState(() => _zoomLevel = max(8.0, _zoomLevel - 1.0)),
                child: const Icon(Icons.remove),
              ),
              const SizedBox(height: 14),
              FloatingActionButton.small(
                heroTag: 'map_recenter_gps',
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                onPressed: _recenterOnGps,
                tooltip: 'Center on My GPS Location',
                child: const Icon(Icons.my_location),
              ),
            ],
          ),
        ),

        // 5. Bottom Address Card & Confirm CTA
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 16,
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                      Text(
                        'Zoom: ${_zoomLevel.round()}x',
                        style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _pinLocationResult?.displayName ?? 'Drag map or tap to move pin...',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.my_location, size: 12, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      '${_pinLat.toStringAsFixed(5)}° N, ${_pinLng.toStringAsFixed(5)}° W',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _pinLocationResult == null
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
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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

/// Custom Map Canvas Painter rendering simulated map grid, roads, and vehicle radar points
class _MapCanvasPainter extends CustomPainter {
  final double centerLat;
  final double centerLng;
  final double zoom;
  final bool isDark;
  final List<Vehicle> vehicles;

  _MapCanvasPainter({
    required this.centerLat,
    required this.centerLng,
    required this.zoom,
    required this.isDark,
    required this.vehicles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = isDark ? const Color(0xFF1B2A44) : const Color(0xFFD0D7E3)
      ..strokeWidth = 1.0;

    final roadPaint = Paint()
      ..color = isDark ? const Color(0xFF263959) : const Color(0xFFFFFFFF)
      ..strokeWidth = 4.0;

    final majorRoadPaint = Paint()
      ..color = isDark ? const Color(0xFF334B73) : const Color(0xFFF9D57C)
      ..strokeWidth = 7.0;

    final step = 40.0 * (zoom / 12.0);

    // Draw Grid Lines
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw Major Simulated Highways
    canvas.drawLine(Offset(0, size.height * 0.4), Offset(size.width, size.height * 0.4), majorRoadPaint);
    canvas.drawLine(Offset(size.width * 0.6, 0), Offset(size.width * 0.6, size.height), majorRoadPaint);
    canvas.drawLine(Offset(0, size.height * 0.75), Offset(size.width, size.height * 0.25), roadPaint);

    // Render Nearby Vehicle Pins on Map
    final vehiclePinPaint = Paint()
      ..color = AppColors.secondary
      ..style = PaintingStyle.fill;

    final double latDegPerPx = 0.05 / pow(2, zoom - 10);
    final double lngDegPerPx = 0.05 / pow(2, zoom - 10);

    for (final v in vehicles) {
      final double dx = (v.longitude - centerLng) / lngDegPerPx + (size.width / 2);
      final double dy = (centerLat - v.latitude) / latDegPerPx + (size.height / 2);

      if (dx >= 0 && dx <= size.width && dy >= 0 && dy <= size.height) {
        canvas.drawCircle(Offset(dx, dy), 6, vehiclePinPaint);
        canvas.drawCircle(
          Offset(dx, dy),
          10,
          Paint()
            ..color = AppColors.secondary.withOpacity(0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MapCanvasPainter oldDelegate) {
    return oldDelegate.centerLat != centerLat ||
        oldDelegate.centerLng != centerLng ||
        oldDelegate.zoom != zoom ||
        oldDelegate.isDark != isDark;
  }
}
