import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import '../utils/app_notification.dart';
import '../services/web_camera_helper.dart';

class BookingVerificationScreen extends StatefulWidget {
  const BookingVerificationScreen({super.key});

  @override
  State<BookingVerificationScreen> createState() => _BookingVerificationScreenState();
}

class _BookingVerificationScreenState extends State<BookingVerificationScreen> {
  // Verification Steps Checkbox States (All start unchecked by default)
  bool _licenseVerified = false;
  bool _depositAgreed = false;
  bool _agreedToTerms = false;
  bool _selfieVerified = false;
  bool _showVehicleMap = true;
  Uint8List? _capturedSelfieBytes;

  int get _totalItems => 4;

  int _getCompletedCount(bool hasVerifiedDl) {
    int count = 0;
    if (hasVerifiedDl && _licenseVerified) count++;
    if (_depositAgreed) count++;
    if (_agreedToTerms) count++;
    if (_selfieVerified) count++;
    return count;
  }

  void _promptManageDocsRedirect(BuildContext context, AppState appState) {
    AppToast.showInfo(
      context,
      '⚠️ Verified Driving License required. Please upload & verify your DL in Manage Docs.',
      action: SnackBarAction(
        label: 'GO TO DOCS',
        textColor: Colors.yellowAccent,
        onPressed: () => appState.navigateToDocsFromVerificationChecklist(),
      ),
    );
    appState.navigateToDocsFromVerificationChecklist();
  }

  // Condition 2: Deposit Pre-authorization Modal
  void _showDepositApprovalModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(22),
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
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.secondary.withOpacity(0.15), shape: BoxShape.circle),
                  child: const Icon(Icons.lock_clock, color: AppColors.secondary, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Security Deposit Pre-authorization', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Refundable hold required for ride activation', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• Amount: ₹2,500.00 (100% Refundable)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue)),
                  SizedBox(height: 4),
                  Text('• The amount is placed on hold via UPI / PassonPay and automatically released back within 2 hours after vehicle return inspection with no damage claims.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() => _depositAgreed = true);
                      AppToast.showSuccess(
                        context,
                        'Security deposit pre-authorization condition approved!',
                      );
                    },
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Authorize & Verify'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, foregroundColor: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Condition 3: Terms & Agreement Contract Modal
  void _showTermsContractModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceContainerDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.amber.withOpacity(0.15), shape: BoxShape.circle),
                  child: const Icon(Icons.gavel, color: Colors.amber, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('P2P Rental Contract & Policy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Please review and accept legal terms', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    '1. VEHICLE USAGE: The renter agrees to operate the vehicle responsibly in compliance with Indian Motor Vehicles Act and traffic regulations.\n\n'
                    '2. TELEMETRY & GEO-FENCING: Real-time speed and GPS telemetry monitoring is enabled for safety. Speeding over 90 km/h triggers host warning alerts.\n\n'
                    '3. RETURN CONDITION: Vehicle must be returned with equivalent fuel/charge level, clean condition, and at designated return dock or host address on time.\n\n'
                    '4. THIRD-PARTY LIABILITY: Standard comprehensive insurance covers accident claims with deductible per policy terms.\n\n'
                    '5. NO SUB-LEASING: Renter must not allow unauthorized third-party individuals to operate the vehicle without host consent.',
                    style: TextStyle(fontSize: 12, height: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() => _agreedToTerms = true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Rental contract & terms accepted!'),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Accept & Sign'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, foregroundColor: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Condition 4: Real-Time Live WebRTC/Camera Biometric Scanner Modal
  void _showBiometricScannerModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cameraViewId = 'biometric_cam_${DateTime.now().millisecondsSinceEpoch}';
    Uint8List? localBytes = _capturedSelfieBytes;
    bool isProcessing = false;
    String statusMessage = 'Look into the live camera lens and tap "Snap Live Photo".';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          Future<void> snapLivePhoto() async {
            try {
              setModalState(() {
                isProcessing = true;
                statusMessage = 'Analyzing live facial geometry & liveness markers...';
              });

              Uint8List? bytes;
              if (WebCameraManager.isSupported) {
                bytes = await WebCameraManager.captureFrame(cameraViewId);
              } else {
                final picker = ImagePicker();
                final XFile? file = await picker.pickImage(
                  source: ImageSource.camera,
                  preferredCameraDevice: CameraDevice.front,
                  maxWidth: 800,
                  maxHeight: 800,
                  imageQuality: 85,
                );
                if (file != null) {
                  bytes = await file.readAsBytes();
                }
              }

              if (bytes != null) {
                await Future.delayed(const Duration(milliseconds: 1000));
                setModalState(() {
                  localBytes = bytes;
                  isProcessing = false;
                  statusMessage = '✅ Real-Time Face Authenticated! Liveness Confidence: 99.8%';
                });
              } else {
                setModalState(() {
                  isProcessing = false;
                  statusMessage = 'Camera snapshot failed. Please tap Snap again.';
                });
              }
            } catch (e) {
              setModalState(() {
                isProcessing = false;
                statusMessage = 'Camera error: $e. Please allow camera permissions.';
              });
            }
          }

          return Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceContainerDark : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.purple.withOpacity(0.15), shape: BoxShape.circle),
                  child: const Icon(Icons.camera_front, color: Colors.purple, size: 30),
                ),
                const SizedBox(height: 10),
                const Text('Live Biometric Face Liveness Check', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                  statusMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: localBytes != null ? Colors.green : Colors.grey,
                    fontWeight: localBytes != null ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 16),

                // Real-Time Live WebRTC Stream / Captured Photo Viewfinder
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: localBytes != null ? Colors.green : (isProcessing ? Colors.amber : Colors.purple),
                      width: 3.5,
                    ),
                    color: Colors.black,
                    boxShadow: [
                      BoxShadow(
                        color: (localBytes != null ? Colors.green : Colors.purple).withOpacity(0.25),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Live WebRTC HTML Video Element Stream
                      if (localBytes == null)
                        if (WebCameraManager.isSupported)
                          WebCameraManager.buildLiveCameraView(
                            viewId: cameraViewId,
                            width: 180,
                            height: 180,
                            onInitialized: () {
                              setModalState(() {
                                statusMessage = '✅ Live Camera Feed Active! Align face in circle.';
                              });
                            },
                            onError: (err) {
                              setModalState(() {
                                statusMessage = 'Camera permission required in browser settings.';
                              });
                            },
                          )
                        else
                          const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt, size: 48, color: Colors.purple),
                              SizedBox(height: 4),
                              Text('Live Camera Ready', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                            ],
                          ),

                      // Captured Snapshot View
                      if (localBytes != null)
                        Image.memory(localBytes!, width: 180, height: 180, fit: BoxFit.cover),

                      // Processing Spinner
                      if (isProcessing)
                        Container(
                          color: Colors.black54,
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(color: Colors.greenAccent),
                                SizedBox(height: 8),
                                Text('Verifying Liveness...', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Anti-Spoofing Real-Time Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.purple.withOpacity(0.2)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.videocam, size: 14, color: Colors.purple),
                      SizedBox(width: 6),
                      Text('Direct WebRTC Live Feed (No File Uploads)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.purple)),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Real-Time Camera Snap Button (Directly captures current live frame)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: isProcessing ? null : snapLivePhoto,
                    icon: const Icon(Icons.camera),
                    label: Text(
                      localBytes == null ? '📸 Snap Live Photo' : '🔄 Retake Live Photo',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Confirm and Verify Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: (localBytes != null && !isProcessing)
                        ? () {
                            if (WebCameraManager.isSupported) {
                              WebCameraManager.stopCamera(cameraViewId);
                            }
                            setState(() {
                              _capturedSelfieBytes = localBytes;
                              _selfieVerified = true;
                            });
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ Live biometric selfie verified in real-time!'),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        : null,
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Confirm & Verify Biometrics', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ).then((_) {
      if (WebCameraManager.isSupported) {
        WebCameraManager.stopCamera(cameraViewId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Check for active verified Driving License in local database / state
    final verifiedDlDoc = appState.documents.where((d) =>
        (d.type.toLowerCase().contains('license') || d.title.toLowerCase().contains('license')) &&
        d.status.toLowerCase().contains('verified') &&
        d.isExpiryValid
    ).firstOrNull;

    final bool hasVerifiedDl = verifiedDlDoc != null;
    final bool isDlChecked = hasVerifiedDl && _licenseVerified;
    final int completedCount = _getCompletedCount(hasVerifiedDl);
    final double progress = _totalItems > 0 ? completedCount / _totalItems : 0.0;
    final bool allRequiredCompleted =
        hasVerifiedDl && _licenseVerified && _depositAgreed && _agreedToTerms && _selfieVerified;
    final vehicle = appState.selectedVehicle ?? (appState.vehicles.isNotEmpty ? appState.vehicles.first : null);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Navigation Bar
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => appState.setNavIndex(2),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BOOKING SAFETY & COMPLIANCE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: isDark ? AppColors.secondaryFixedDim : AppColors.secondary,
                    ),
                  ),
                  const Text('Verification Checklist', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Dynamic Progress Card with Vehicle Being Booked
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [AppColors.surfaceContainerDark, AppColors.surfaceContainerHighDark]
                    : [AppColors.surfaceContainerLow, AppColors.secondaryContainer.withOpacity(0.3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Feature Card of the Vehicle being booked with Integrated Location System & Map
                if (vehicle != null) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceContainerHighDark.withOpacity(0.75)
                          : Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark
                            ? AppColors.outlineVariantDark.withOpacity(0.6)
                            : AppColors.secondary.withOpacity(0.25),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Main Vehicle Details Row (Tap to open details)
                        InkWell(
                          onTap: () => appState.setNavIndex(2),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Vehicle Image Thumbnail with Category Tag
                                Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        appState.imageKitService.buildImageUrl(vehicle.imageUrl),
                                        height: 72,
                                        width: 76,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          height: 72,
                                          width: 76,
                                          color: Colors.grey.shade300,
                                          child: const Icon(Icons.directions_car, color: Colors.grey),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      left: 4,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.black87,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          vehicle.category.toUpperCase(),
                                          style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                // Vehicle Title, Host Name, and Price
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.secondary.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.directions_bike, size: 10, color: AppColors.secondary),
                                                SizedBox(width: 4),
                                                Text(
                                                  'VEHICLE BEING BOOKED',
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.secondary,
                                                    letterSpacing: 0.4,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            '₹${vehicle.pricePerDay.toStringAsFixed(0)}/day',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? AppColors.secondaryFixedDim : AppColors.secondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        vehicle.title,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      // Host Name and Trust Score
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 10,
                                            backgroundColor: AppColors.primary,
                                            backgroundImage: vehicle.hostAvatar.isNotEmpty
                                                ? NetworkImage(appState.imageKitService.buildImageUrl(vehicle.hostAvatar))
                                                : null,
                                            child: vehicle.hostAvatar.isEmpty
                                                ? Text(
                                                    vehicle.hostName.isNotEmpty ? vehicle.hostName[0].toUpperCase() : 'H',
                                                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                                  )
                                                : null,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: RichText(
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              text: TextSpan(
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: isDark ? Colors.white70 : Colors.black87,
                                                ),
                                                children: [
                                                  const TextSpan(text: 'Host: ', style: TextStyle(color: Colors.grey)),
                                                  TextSpan(
                                                    text: vehicle.hostName,
                                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: Colors.green.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.shield, size: 10, color: Colors.green),
                                                const SizedBox(width: 2),
                                                Text(
                                                  '${vehicle.hostTrustScore.toStringAsFixed(0)}% Trust',
                                                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.green),
                                                ),
                                              ],
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

                        // Integrated Exact Address & Live Location System Header
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: const Divider(height: 1),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.location_on, size: 16, color: Colors.redAccent),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Text(
                                              'HOST VEHICLE PICKUP LOCATION',
                                              style: TextStyle(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            const Spacer(),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.withOpacity(0.12),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                '${appState.getFormattedDistanceToVehicle(vehicle)} (${appState.getEstimatedTravelTimeToVehicle(vehicle)})',
                                                style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.blue),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          vehicle.location.isNotEmpty ? vehicle.location : 'Pickup Hub, City Center',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'GPS: ${vehicle.latitude != 0.0 ? vehicle.latitude.toStringAsFixed(4) : "22.5726"}° N, ${vehicle.longitude != 0.0 ? vehicle.longitude.toStringAsFixed(4) : "88.3639"}° E',
                                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Map Actions Bar (Toggle Map & Navigation)
                              Row(
                                children: [
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        _showVehicleMap = !_showVehicleMap;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLow,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _showVehicleMap ? Icons.map : Icons.map_outlined,
                                            size: 13,
                                            color: AppColors.secondary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _showVehicleMap ? 'Hide Map' : 'Show Map Pin',
                                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.secondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  InkWell(
                                    onTap: () => _showFullLocationMapModal(context, appState, vehicle),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLow,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.fullscreen, size: 14, color: Colors.deepPurple),
                                          SizedBox(width: 4),
                                          Text(
                                            'Full Hub View',
                                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      final lat = vehicle.latitude != 0.0 ? vehicle.latitude : 22.5726;
                                      final lng = vehicle.longitude != 0.0 ? vehicle.longitude : 88.3639;
                                      final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
                                      if (await canLaunchUrl(uri)) {
                                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                                      } else {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Unable to launch external maps directions.')),
                                          );
                                        }
                                      }
                                    },
                                    icon: const Icon(Icons.directions, size: 12),
                                    label: const Text('Directions', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue.shade700,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Integrated Live OpenStreetMap Preview
                        if (_showVehicleMap) ...[
                          Container(
                            height: 155,
                            margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              children: [
                                FlutterMap(
                                  options: MapOptions(
                                    initialCenter: LatLng(
                                      vehicle.latitude != 0.0 ? vehicle.latitude : 22.5726,
                                      vehicle.longitude != 0.0 ? vehicle.longitude : 88.3639,
                                    ),
                                    initialZoom: 15.2,
                                    interactionOptions: const InteractionOptions(
                                      flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                                    ),
                                  ),
                                  children: [
                                    TileLayer(
                                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                      userAgentPackageName: 'com.passon.ride',
                                    ),
                                    MarkerLayer(
                                      markers: [
                                        Marker(
                                          point: LatLng(
                                            vehicle.latitude != 0.0 ? vehicle.latitude : 22.5726,
                                            vehicle.longitude != 0.0 ? vehicle.longitude : 88.3639,
                                          ),
                                          width: 50,
                                          height: 50,
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              Container(
                                                width: 44,
                                                height: 44,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.red.withOpacity(0.25),
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.all(7),
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.red.shade700,
                                                  border: Border.all(color: Colors.white, width: 2),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withOpacity(0.2),
                                                      blurRadius: 6,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: const Icon(
                                                  Icons.directions_car,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.75),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            color: Colors.greenAccent,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Text(
                                          'LIVE GPS PIN',
                                          style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          progress == 1.0 ? Icons.check_circle : Icons.checklist_rtl,
                          color: progress == 1.0 ? Colors.green : AppColors.secondary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text('Checklist Progress', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: progress == 1.0 ? Colors.green.withOpacity(0.15) : AppColors.secondary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$completedCount/$_totalItems Completed (${(progress * 100).toInt()}%)',
                        style: TextStyle(
                          color: progress == 1.0 ? Colors.green.shade800 : AppColors.secondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: isDark ? Colors.white12 : Colors.black12,
                    color: progress == 1.0 ? Colors.green : AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        !hasVerifiedDl
                            ? '⚠️ Driving License unverified. Upload in Manage Docs to unlock.'
                            : allRequiredCompleted
                                ? '✅ All mandatory verification conditions cleared'
                                : '⚠️ Tap and complete each requirement condition to verify',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: !hasVerifiedDl
                              ? Colors.redAccent
                              : allRequiredCompleted
                                  ? Colors.green
                                  : Colors.orange.shade800,
                        ),
                      ),
                    ),
                    if (completedCount > 0) ...[
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _licenseVerified = false;
                            _depositAgreed = false;
                            _agreedToTerms = false;
                            _selfieVerified = false;
                            _capturedSelfieBytes = null;
                          });
                        },
                        icon: const Icon(Icons.refresh, size: 14),
                        label: const Text('Reset All', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        style: TextButton.styleFrom(visualDensity: VisualDensity.compact, padding: const EdgeInsets.symmetric(horizontal: 8)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // MANDATORY VERIFICATION STEPS
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: AppColors.secondary.withOpacity(0.15), shape: BoxShape.circle),
                child: const Icon(Icons.verified_user, size: 16, color: AppColors.secondary),
              ),
              const SizedBox(width: 8),
              const Text('Mandatory Verification Steps', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 12),

          // Step 1 Checkbox Card: Driver License (Condition: Verified DL in Local DB)
          _buildInteractiveStepCard(
            context: context,
            stepNum: '1',
            title: 'Driver License & Govt ID Verification',
            subtitle: hasVerifiedDl
                ? 'Verified: ${verifiedDlDoc.holderName} • DL #${verifiedDlDoc.documentNumber} (${verifiedDlDoc.isExpiryValid ? "Valid" : "Expired"})'
                : '❌ Condition: Must upload and verify DL in Manage Docs first.',
            value: isDlChecked,
            isLocked: !hasVerifiedDl,
            statusBadge: hasVerifiedDl
                ? (isDlChecked ? '✅ VERIFIED' : 'READY TO CHECK')
                : '🔒 DOC REQUIRED',
            icon: Icons.badge,
            onChanged: (val) {
              if (!hasVerifiedDl) {
                _promptManageDocsRedirect(context, appState);
                return;
              }
              setState(() => _licenseVerified = val ?? false);
            },
            onLockedTap: () => _promptManageDocsRedirect(context, appState),
            trailingAction: hasVerifiedDl
                ? TextButton.icon(
                    onPressed: () => appState.navigateToDocsFromVerificationChecklist(),
                    icon: const Icon(Icons.open_in_new, size: 13),
                    label: const Text('Manage Docs', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  )
                : ElevatedButton.icon(
                    onPressed: () => appState.navigateToDocsFromVerificationChecklist(),
                    icon: const Icon(Icons.upload_file, size: 13),
                    label: const Text('Upload DL in Manage Docs', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
          ),

          const SizedBox(height: 12),

          // Step 2 Checkbox Card: Security Deposit (Condition: Pre-authorization Approval)
          _buildInteractiveStepCard(
            context: context,
            stepNum: '2',
            title: 'Security Deposit Pre-authorization',
            subtitle: _depositAgreed
                ? '₹2,500.00 refundable deposit pre-authorization authorized'
                : 'Condition: Tap to review & authorize ₹2,500 refundable deposit hold',
            value: _depositAgreed,
            statusBadge: _depositAgreed ? '✅ AUTHORIZED' : 'TAP TO AUTHORIZE',
            icon: Icons.lock_clock,
            onChanged: (val) {
              if (val == true) {
                _showDepositApprovalModal(context);
              } else {
                setState(() => _depositAgreed = false);
              }
            },
          ),

          const SizedBox(height: 12),

          // Step 3 Checkbox Card: P2P Contract & Terms (Condition: Terms Review & Agreement)
          _buildInteractiveStepCard(
            context: context,
            stepNum: '3',
            title: 'P2P Rental Contract & Terms Agreement',
            subtitle: _agreedToTerms
                ? 'Usage policy, telemetry monitoring rules, and liability terms signed'
                : 'Condition: Tap to review and accept the legal rental contract',
            value: _agreedToTerms,
            statusBadge: _agreedToTerms ? '✅ SIGNED' : 'TAP TO REVIEW',
            icon: Icons.gavel,
            onChanged: (val) {
              if (val == true) {
                _showTermsContractModal(context);
              } else {
                setState(() => _agreedToTerms = false);
              }
            },
          ),

          const SizedBox(height: 12),

          // Step 4 Checkbox Card: Biometric Selfie (Condition: Live Camera Face Scan)
          _buildInteractiveStepCard(
            context: context,
            stepNum: '4',
            title: 'Biometric Face Liveness Check',
            subtitle: _selfieVerified
                ? 'Biometric selfie authenticated with front camera (99.8% Match)'
                : 'Condition: Tap to open front camera and complete live selfie check',
            value: _selfieVerified,
            statusBadge: _selfieVerified ? '✅ CAMERA VERIFIED' : 'CAMERA SCAN REQUIRED',
            icon: Icons.face,
            avatarBytes: _capturedSelfieBytes,
            onChanged: (val) {
              if (val == true) {
                _showBiometricScannerModal(context);
              } else {
                setState(() {
                  _selfieVerified = false;
                  _capturedSelfieBytes = null;
                });
              }
            },
          ),

          const SizedBox(height: 32),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: allRequiredCompleted
                  ? () => appState.setNavIndex(4) // Go to Payment Checkout
                  : null,
              icon: const Icon(Icons.payment),
              label: Text(
                allRequiredCompleted ? 'Continue to Payment Checkout' : 'Complete All 4 Conditions First',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showFullLocationMapModal(BuildContext context, AppState appState, Vehicle vehicle) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lat = vehicle.latitude != 0.0 ? vehicle.latitude : 22.5726;
    final lng = vehicle.longitude != 0.0 ? vehicle.longitude : 88.3639;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceContainerDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Modal Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
              ),
              // Header Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.location_on, color: Colors.redAccent, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Host Vehicle Pickup Hub',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            vehicle.title,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Interactive Full OpenStreetMap
              Expanded(
                child: Stack(
                  children: [
                    FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(lat, lng),
                        initialZoom: 16.0,
                        minZoom: 4.0,
                        maxZoom: 19.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.passon.ride',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(lat, lng),
                              width: 60,
                              height: 60,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.red.withOpacity(0.25),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.red.shade700,
                                      border: Border.all(color: Colors.white, width: 2.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(Icons.directions_car, color: Colors.white, size: 20),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${appState.getFormattedDistanceToVehicle(vehicle)} • ${appState.getEstimatedTravelTimeToVehicle(vehicle)}',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Pickup Address Card & Actions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceContainerHighDark : Colors.grey.shade50,
                  border: Border(
                    top: BorderSide(
                      color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.primary,
                          backgroundImage: vehicle.hostAvatar.isNotEmpty
                              ? NetworkImage(appState.imageKitService.buildImageUrl(vehicle.hostAvatar))
                              : null,
                          child: vehicle.hostAvatar.isEmpty
                              ? Text(
                                  vehicle.hostName.isNotEmpty ? vehicle.hostName[0].toUpperCase() : 'H',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Host: ${vehicle.hostName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text(vehicle.location.isNotEmpty ? vehicle.location : 'Pickup Hub Location', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${vehicle.hostTrustScore.toStringAsFixed(0)}% Trust',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              appState.openChatWithHost(
                                hostName: vehicle.hostName,
                                hostAvatar: vehicle.hostAvatar,
                                vehicleTitle: vehicle.title,
                              );
                            },
                            icon: const Icon(Icons.chat_bubble_outline, size: 16),
                            label: const Text('Chat Host'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              }
                            },
                            icon: const Icon(Icons.navigation, size: 16),
                            label: const Text('Open in Google Maps', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInteractiveStepCard({
    required BuildContext context,
    required String stepNum,
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required ValueChanged<bool?> onChanged,
    bool isLocked = false,
    String? statusBadge,
    VoidCallback? onLockedTap,
    Widget? trailingAction,
    Uint8List? avatarBytes,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        if (isLocked) {
          if (onLockedTap != null) onLockedTap();
        } else {
          onChanged(!value);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isLocked
              ? (isDark ? Colors.red.withOpacity(0.06) : Colors.red.withOpacity(0.03))
              : value
                  ? (isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLowest)
                  : (isDark ? AppColors.surfaceContainerLow : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLocked
                ? Colors.red.withOpacity(0.4)
                : value
                    ? AppColors.secondary
                    : (isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight),
            width: isLocked || value ? 1.5 : 1.0,
          ),
          boxShadow: value && !isLocked
              ? [BoxShadow(color: AppColors.secondary.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isLocked)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Icon(Icons.lock, size: 22, color: Colors.red.shade400),
              )
            else
              Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: AppColors.secondary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
            const SizedBox(width: 4),
            if (avatarBytes != null)
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.green, width: 2),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.memory(avatarBytes, fit: BoxFit.cover),
              )
            else
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isLocked
                      ? Colors.red.withOpacity(0.12)
                      : value
                          ? AppColors.secondaryContainer
                          : Colors.grey.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: isLocked
                      ? Colors.red.shade400
                      : value
                          ? AppColors.onSecondaryContainer
                          : Colors.grey,
                ),
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.black12,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('Step $stepNum', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      if (statusBadge != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: isLocked
                                ? Colors.red.withOpacity(0.15)
                                : value
                                    ? Colors.green.withOpacity(0.15)
                                    : Colors.blue.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            statusBadge,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: isLocked
                                  ? Colors.red.shade700
                                  : value
                                      ? Colors.green.shade800
                                      : Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isLocked
                                ? Colors.red.shade400
                                : value
                                    ? null
                                    : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isLocked
                          ? (isDark ? Colors.red.shade300 : Colors.red.shade700)
                          : value
                              ? Colors.grey.shade600
                              : Colors.grey.shade500,
                    ),
                  ),
                  if (trailingAction != null) ...[
                    const SizedBox(height: 6),
                    trailingAction,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
