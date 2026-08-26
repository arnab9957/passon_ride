// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../services/location_service.dart';
import '../theme/app_colors.dart';
import '../screens/location_screen.dart';

class LocationPromptDialog extends StatefulWidget {
  const LocationPromptDialog({super.key});

  static Future<void> show(BuildContext context) async {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.setHasPromptedLocationOnLogin(true);

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const LocationPromptDialog(),
    );
  }

  @override
  State<LocationPromptDialog> createState() => _LocationPromptDialogState();
}

class _LocationPromptDialogState extends State<LocationPromptDialog> {
  bool _isDetectingGps = false;
  String? _gpsStatus;
  final LocationService _locationService = LocationService();

  Future<void> _handleGpsLocation() async {
    setState(() {
      _isDetectingGps = true;
      _gpsStatus = 'Calibrating device GPS sensors & satellite locks...';
    });

    try {
      final loc = await _locationService.getCurrentLiveLocation();
      if (!mounted) return;

      final appState = Provider.of<AppState>(context, listen: false);
      appState.setLiveLocation(loc);

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.gps_fixed, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text('📍 Live GPS active: ${loc.displayName} (${loc.latitude.toStringAsFixed(3)}, ${loc.longitude.toStringAsFixed(3)})'),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDetectingGps = false;
          _gpsStatus = 'Could not access GPS. Please choose address manually or check browser permissions.';
        });
      }
    }
  }

  void _handleManualAddress() {
    Navigator.pop(context);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LocationScreen(
          isModal: true,
          onLocationSelected: (loc) {
            final appState = Provider.of<AppState>(context, listen: false);
            appState.setManualLocation(loc);
          },
        ),
      ),
    );
  }

  void _handleKeepKolkataDefault() {
    final appState = Provider.of<AppState>(context, listen: false);
    final kolkata = LocationResult(
      displayName: 'Kolkata, West Bengal, India',
      city: 'Kolkata',
      state: 'West Bengal',
      country: 'India',
      postalCode: '700001',
      latitude: 22.5726,
      longitude: 88.3639,
      accuracy: 'Default Metro Hub',
    );
    appState.setManualLocation(kolkata);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📍 Location set to default: Kolkata, West Bengal, India'),
        backgroundColor: AppColors.secondary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceContainerDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),

          // Header Icon
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_on, color: AppColors.secondary, size: 36),
          ),
          const SizedBox(height: 14),

          // Title & Subtitle
          const Text(
            'Set Your Location',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const SizedBox(height: 6),
          Text(
            'To show available vehicles, hosts, and tours closest to you, please choose your location preference:',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
          ),
          const SizedBox(height: 20),

          // GPS Status message if scanning
          if (_isDetectingGps) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _gpsStatus ?? 'Detecting GPS...',
                      style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ] else if (_gpsStatus != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Text(
                _gpsStatus!,
                style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Option 1: Live GPS
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isDetectingGps ? null : _handleGpsLocation,
              icon: const Icon(Icons.my_location),
              label: const Text(
                '📍 Enable Live GPS Location',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Option 2: Search / Enter Custom Address
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _isDetectingGps ? null : _handleManualAddress,
              icon: const Icon(Icons.search),
              label: const Text(
                '🏙️ Search Address or City',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.secondary, width: 1.5),
                foregroundColor: AppColors.secondary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Option 3: Keep Default (Kolkata)
          TextButton.icon(
            onPressed: _isDetectingGps ? null : _handleKeepKolkataDefault,
            icon: const Icon(Icons.check, size: 16),
            label: const Text(
              'Use Default Address (Kolkata, WB)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            style: TextButton.styleFrom(foregroundColor: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
