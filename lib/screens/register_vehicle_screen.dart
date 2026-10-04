// ignore_for_file: deprecated_member_use, use_build_context_synchronously
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/models.dart';
import '../services/location_service.dart';
import '../services/imagekit_service.dart';
import '../services/document_ocr_service.dart';
import '../theme/app_colors.dart';
import '../widgets/interactive_map_pin_picker.dart';
import '../widgets/exempt_hosts_dialog.dart';

class RegisterVehicleScreen extends StatefulWidget {
  final Vehicle? vehicleToEdit;

  const RegisterVehicleScreen({super.key, this.vehicleToEdit});

  @override
  State<RegisterVehicleScreen> createState() => _RegisterVehicleScreenState();
}

class _RegisterVehicleScreenState extends State<RegisterVehicleScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _priceController;
  late final TextEditingController _pricePerHourController;
  late final TextEditingController _customRangePriceController;
  TimeOfDay _customStartTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _customEndTime = const TimeOfDay(hour: 22, minute: 0);
  late final TextEditingController _vinController;
  late final TextEditingController _locationController;
  late final TextEditingController _descriptionController;
  final _urlInputController = TextEditingController();

  String _selectedCategory = 'Motorcycle';
  String _selectedFuelType = 'Petrol';
  String _selectedTransmission = 'Manual';
  String _selectedStatus = 'Available';
  int _seats = 2;
  int _quantity = 1;
  bool _instantBook = true;
  bool _isSubmitting = false;

  bool get isEditMode => widget.vehicleToEdit != null;

  // Host Location Map & GPS State
  double _hostLatitude = 22.5726;
  double _hostLongitude = 88.3639;
  bool _isGeocodingHostAddress = false;

  // Vehicle Registration Document (RC) state
  final _rcNumberController = TextEditingController();
  DateTime _rcExpiryDate = DateTime.now().add(const Duration(days: 365 * 5));
  String _rcFileName = '';
  Uint8List? _rcFileBytes;
  String? _rcFileExtension;

  // Insurance Document state
  final _insurancePolicyController = TextEditingController();
  final _insuranceProviderController = TextEditingController();
  DateTime _insuranceExpiryDate = DateTime.now().add(const Duration(days: 365));
  String _insuranceFileName = '';
  Uint8List? _insuranceFileBytes;
  String? _insuranceFileExtension;

  // Challan Clearance Document state
  final _challanNumberController = TextEditingController();
  DateTime _challanDate = DateTime.now();
  String _challanFileName = '';
  Uint8List? _challanFileBytes;
  String? _challanFileExtension;

  bool _isRcScanning = false;
  bool _isChallanScanning = false;

  // Multiple Vehicle Photos Gallery State
  final List<String> _vehiclePhotos = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final v = widget.vehicleToEdit;
    if (v != null) {
      _titleController = TextEditingController(text: v.title);
      _priceController = TextEditingController(text: v.pricePerDay.toStringAsFixed(0));
      _pricePerHourController = TextEditingController(
        text: v.pricePerHour > 0 ? v.pricePerHour.toStringAsFixed(0) : '99.00',
      );
      _customRangePriceController = TextEditingController(
        text: v.customTimeRangePrice > 0 ? v.customTimeRangePrice.toStringAsFixed(0) : '499.00',
      );
      if (v.customTimeRangeStart.isNotEmpty && v.customTimeRangeStart.contains(':')) {
        final parts = v.customTimeRangeStart.split(':');
        _customStartTime = TimeOfDay(hour: int.tryParse(parts[0]) ?? 7, minute: int.tryParse(parts[1]) ?? 0);
      }
      if (v.customTimeRangeEnd.isNotEmpty && v.customTimeRangeEnd.contains(':')) {
        final parts = v.customTimeRangeEnd.split(':');
        _customEndTime = TimeOfDay(hour: int.tryParse(parts[0]) ?? 22, minute: int.tryParse(parts[1]) ?? 0);
      }
      _vinController = TextEditingController(text: v.iotData['plateNumber']?.toString() ?? 'WB11442A');
      _locationController = TextEditingController(text: v.location);
      _descriptionController = TextEditingController(text: v.description);

      final cat = v.category.isNotEmpty ? v.category : '';
      if (['Motorcycle', 'Car', 'Scooter', 'Electric EV'].contains(cat)) {
        _selectedCategory = cat;
      } else if (cat.toLowerCase().contains('car')) {
        _selectedCategory = 'Car';
      } else if (cat.toLowerCase().contains('scooter')) {
        _selectedCategory = 'Scooter';
      } else if (cat.toLowerCase().contains('ev') || cat.toLowerCase().contains('electric')) {
        _selectedCategory = 'Electric EV';
      } else {
        _selectedCategory = v.type == VehicleType.car
            ? 'Car'
            : (v.type == VehicleType.scooter
                ? 'Scooter'
                : (v.type == VehicleType.electric ? 'Electric EV' : 'Motorcycle'));
      }

      final fuel = v.fuelType.isNotEmpty ? v.fuelType : 'Petrol';
      _selectedFuelType = ['Petrol', 'Diesel', 'Electric', 'Gasoline', 'Hybrid', 'CNG'].contains(fuel)
          ? fuel
          : 'Petrol';

      final trans = v.transmission.isNotEmpty ? v.transmission : 'Manual';
      _selectedTransmission = ['Manual', 'Automatic'].contains(trans) ? trans : 'Manual';

      _seats = v.seats > 0 ? v.seats : 2;
      _quantity = v.quantity > 0 ? v.quantity : 1;
      _instantBook = v.isInstantBookable;
      _hostLatitude = v.latitude != 0 ? v.latitude : 22.5726;
      _hostLongitude = v.longitude != 0 ? v.longitude : 88.3639;
      _selectedStatus = ['Available', 'Maintenance', 'Booked'].contains(v.status) ? v.status : 'Available';

      _vehiclePhotos.clear();
      if (v.images.isNotEmpty) {
        _vehiclePhotos.addAll(v.images);
      } else if (v.imageUrl.isNotEmpty) {
        _vehiclePhotos.add(v.imageUrl);
      }
    } else {
      _titleController = TextEditingController(text: 'Bajaj Pulsar N250');
      _priceController = TextEditingController(text: '599.00');
      _pricePerHourController = TextEditingController(text: '99.00');
      _customRangePriceController = TextEditingController(text: '499.00');
      _vinController = TextEditingController(text: 'WB11442A');
      _locationController = TextEditingController(text: 'Kolkata, West Bengal');
      _descriptionController = TextEditingController(
        text: 'Well-maintained street motorcycle available for daily or weekly rentals. Equipped with dual-channel ABS and helmet.',
      );
      _vehiclePhotos.clear();
      _vehiclePhotos.add('https://images.unsplash.com/photo-1558981403-c5f9899a28bc?w=800&q=80');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final appState = Provider.of<AppState>(context, listen: false);
        if (appState.userLatitude != 0) {
          setState(() {
            _hostLatitude = appState.userLatitude;
            _hostLongitude = appState.userLongitude;
            _locationController.text = appState.selectedLocation;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _pricePerHourController.dispose();
    _customRangePriceController.dispose();
    _vinController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _urlInputController.dispose();
    _rcNumberController.dispose();
    _insurancePolicyController.dispose();
    _insuranceProviderController.dispose();
    _challanNumberController.dispose();
    super.dispose();
  }

  // Preset sample vehicle photo choices
  final List<Map<String, String>> _presetPhotos = [
    {
      'title': 'Adventure Bike',
      'url': 'https://images.unsplash.com/photo-1558981403-c5f9899a28bc?w=800&q=80',
    },
    {
      'title': 'Sedan / SUV',
      'url': 'https://images.unsplash.com/photo-1560958089-b8a1929cea89?w=800&q=80',
    },
    {
      'title': 'Urban Scooter',
      'url': 'https://images.unsplash.com/photo-1558981806-ec527fa84c39?w=800&q=80',
    },
    {
      'title': 'Sports Convertible',
      'url': 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=800&q=80',
    },
  ];

  // Pick Multiple Local Images from Device Gallery
  Future<void> _pickMultiGalleryImages() async {
    final appState = Provider.of<AppState>(context, listen: false);
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFiles.isNotEmpty) {
        for (var file in pickedFiles) {
          final bytes = await file.readAsBytes();
          final ikUrl = await appState.imageKitService.uploadImage(
            bytes: bytes,
            fileName: 'vehicle_${DateTime.now().millisecondsSinceEpoch}.jpg',
            folder: '/vehicles',
          );
          final finalUrl = ikUrl ?? 'data:image/png;base64,${base64Encode(bytes)}';
          if (!_vehiclePhotos.contains(finalUrl)) {
            _vehiclePhotos.add(finalUrl);
          }
        }
        setState(() {});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added ${pickedFiles.length} photo(s) to vehicle gallery!'),
              backgroundColor: Colors.green.shade700,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final isMissingPlugin = e.toString().contains('MissingPluginException');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isMissingPlugin
                  ? '⚠️ Native plugin not bound yet! Please restart your "flutter run" session in the terminal to load the newly installed image_picker plugin.'
                  : 'Error selecting gallery photos: $e',
            ),
            duration: const Duration(seconds: 6),
            backgroundColor: isMissingPlugin ? Colors.orange.shade900 : Colors.red.shade800,
          ),
        );
      }
    }
  }

  // Take a Photo with Device Camera
  Future<void> _pickCameraPhoto() async {
    final appState = Provider.of<AppState>(context, listen: false);
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final ikUrl = await appState.imageKitService.uploadImage(
          bytes: bytes,
          fileName: 'camera_${DateTime.now().millisecondsSinceEpoch}.jpg',
          folder: '/vehicles',
        );
        final finalUrl = ikUrl ?? 'data:image/png;base64,${base64Encode(bytes)}';
        setState(() {
          _vehiclePhotos.add(finalUrl);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Added camera photo to vehicle gallery!'),
              backgroundColor: Colors.green.shade700,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final isMissingPlugin = e.toString().contains('MissingPluginException');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isMissingPlugin
                  ? '⚠️ Native plugin not bound yet! Please restart your "flutter run" session in the terminal to load the newly installed image_picker plugin.'
                  : 'Error taking photo: $e',
            ),
            duration: const Duration(seconds: 6),
            backgroundColor: isMissingPlugin ? Colors.orange.shade900 : Colors.red.shade800,
          ),
        );
      }
    }
  }

  // Add Custom Web URL to Photo Gallery
  void _addWebUrlPhoto() {
    final url = _urlInputController.text.trim();
    if (url.isNotEmpty) {
      if (!_vehiclePhotos.contains(url)) {
        setState(() {
          _vehiclePhotos.add(url);
          _urlInputController.clear();
        });
      }
    }
  }

  // Set selected photo as main cover photo (move to index 0)
  void _setAsCoverPhoto(int index) {
    if (index > 0 && index < _vehiclePhotos.length) {
      setState(() {
        final photo = _vehiclePhotos.removeAt(index);
        _vehiclePhotos.insert(0, photo);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Updated cover photo!')),
      );
    }
  }

  // Remove single photo from gallery
  void _removePhoto(int index) {
    setState(() {
      _vehiclePhotos.removeAt(index);
    });
  }

  Future<void> _pickRcDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final appState = Provider.of<AppState>(context, listen: false);
        final sizeKb = file.size / 1024.0;
        String? filePath;
        if (!kIsWeb) {
          try {
            filePath = file.path;
          } catch (_) {}
        }
        setState(() {
          _rcFileName = file.name;
          _rcFileBytes = file.bytes;
          _rcFileExtension = file.extension ?? 'pdf';
          _isRcScanning = true;
        });

        try {
          final ocrResult = await DocumentOcrService.processDocument(
            fileName: file.name,
            selectedDocType: 'Vehicle Registration (RC)',
            fileSizeKb: sizeKb,
            bytes: file.bytes,
            imagePath: filePath,
            userDisplayName: appState.activeUserDisplayName,
          );
          if (ocrResult.documentNumber.isNotEmpty && !ocrResult.documentNumber.contains('UNDETECTED')) {
            setState(() {
              _rcNumberController.text = ocrResult.documentNumber;
            });
          }
          if (ocrResult.expiryDate.isAfter(DateTime.now())) {
            setState(() {
              _rcExpiryDate = ocrResult.expiryDate;
            });
          }
        } catch (e) {
          debugPrint('RC OCR Scan error: $e');
        } finally {
          setState(() {
            _isRcScanning = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking RC document: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _pickInsuranceDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          _insuranceFileName = file.name;
          _insuranceFileBytes = file.bytes;
          _insuranceFileExtension = file.extension ?? 'pdf';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking Insurance document: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _pickChallanDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final appState = Provider.of<AppState>(context, listen: false);
        final sizeKb = file.size / 1024.0;
        String? filePath;
        if (!kIsWeb) {
          try {
            filePath = file.path;
          } catch (_) {}
        }
        setState(() {
          _challanFileName = file.name;
          _challanFileBytes = file.bytes;
          _challanFileExtension = file.extension ?? 'pdf';
          _isChallanScanning = true;
        });

        try {
          final ocrResult = await DocumentOcrService.processDocument(
            fileName: file.name,
            selectedDocType: 'Challan Clearance',
            fileSizeKb: sizeKb,
            bytes: file.bytes,
            imagePath: filePath,
            userDisplayName: appState.activeUserDisplayName,
          );
          if (ocrResult.documentNumber.isNotEmpty && !ocrResult.documentNumber.contains('UNDETECTED')) {
            setState(() {
              _challanNumberController.text = ocrResult.documentNumber;
            });
          }
          if (ocrResult.expiryDate.isAfter(DateTime.now().subtract(const Duration(days: 3650)))) {
            setState(() {
              _challanDate = ocrResult.expiryDate;
            });
          }
        } catch (e) {
          debugPrint('Challan OCR Scan error: $e');
        } finally {
          setState(() {
            _isChallanScanning = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking Challan document: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isExemptHost = appState.isDocumentExemptHost();

    final content = SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    appState.setNavIndex(8);
                  }
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEditMode ? 'HOST VEHICLE EDITOR' : 'HOST LISTING WIZARD',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: isDark ? AppColors.secondaryFixedDim : AppColors.secondary,
                      ),
                    ),
                    Text(
                      isEditMode ? 'Edit Vehicle Details' : 'Register New Vehicle',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    if (isEditMode) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Updating "${widget.vehicleToEdit!.title}"',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Initial Host Exemption Banner or Host Edit Banner
          if (isEditMode)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.secondaryFixedDim : AppColors.secondary).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (isDark ? AppColors.secondaryFixedDim : AppColors.secondary).withOpacity(0.35),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit_note, color: AppColors.secondary, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Host Editing Mode: ${widget.vehicleToEdit!.title}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Update specs, pricing, pickup location, photo gallery, and fleet availability status below.',
                          style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            _buildInitialExemptionBanner(context, appState, isDark, isExemptHost),

          const SizedBox(height: 20),

          // 1. Basic Vehicle Information
          const Text('1. Basic Vehicle Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),

          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Vehicle Title / Make & Model',
              prefixIcon: Icon(Icons.directions_car),
            ),
          ),
          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Vehicle Type',
              prefixIcon: Icon(Icons.category),
            ),
            items: ['Motorcycle', 'Car', 'Scooter', 'Electric EV']
                .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                .toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedCategory = val;
                  _seats = val == 'Car' ? 5 : 2;
                });
              }
            },
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _vinController,
            decoration: const InputDecoration(
              labelText: 'VIN / Registration Plate Number',
              prefixIcon: Icon(Icons.pin),
            ),
          ),
          const SizedBox(height: 12),

          if (isEditMode) ...[
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Fleet Availability Status',
                prefixIcon: Icon(Icons.traffic_outlined),
              ),
              items: const [
                DropdownMenuItem(value: 'Available', child: Text('🟢 Available for Rent')),
                DropdownMenuItem(value: 'Maintenance', child: Text('🟠 Maintenance / Workshop')),
                DropdownMenuItem(value: 'Booked', child: Text('🔵 Booked / On Trip')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedStatus = val);
              },
            ),
            const SizedBox(height: 12),
          ],

          // Quantity Selection
          Row(
            children: [
              const Icon(Icons.inventory, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Available Quantity',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 18),
                      onPressed: () {
                        if (_quantity > 1) {
                          setState(() => _quantity--);
                        }
                      },
                    ),
                    Text('$_quantity', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    IconButton(
                      icon: const Icon(Icons.add, size: 18),
                      onPressed: () {
                        setState(() => _quantity++);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Host Vehicle Location & Address Picker Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.secondary.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, color: AppColors.secondary, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Host Vehicle Pickup Address Line',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const Spacer(),
                    if (_isGeocodingHostAddress)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. 12 Park Street, Kolkata, West Bengal',
                    labelText: 'Exact Street Address Line',
                    prefixIcon: Icon(Icons.map_outlined),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (ctx) => Container(
                              height: MediaQuery.of(context).size.height * 0.85,
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.surfaceDark : Colors.white,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    color: AppColors.primary,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          '📍 Set Vehicle Host Pickup Pin',
                                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.close, color: Colors.white),
                                          onPressed: () => Navigator.pop(ctx),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: InteractiveMapPinPicker(
                                      initialLat: _hostLatitude,
                                      initialLng: _hostLongitude,
                                      onLocationPicked: (LocationResult result) {
                                        setState(() {
                                          _locationController.text = result.displayName;
                                          _hostLatitude = result.latitude;
                                          _hostLongitude = result.longitude;
                                        });
                                        Navigator.pop(ctx);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Host location pinned: ${result.displayName}'),
                                            backgroundColor: Colors.green.shade700,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.pin_drop, size: 16),
                        label: const Text('Pick Pin on Map', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          setState(() => _isGeocodingHostAddress = true);
                          try {
                            final liveRes = await LocationService().getCurrentLiveLocation();
                            setState(() {
                              _locationController.text = liveRes.displayName;
                              _hostLatitude = liveRes.latitude;
                              _hostLongitude = liveRes.longitude;
                              _isGeocodingHostAddress = false;
                            });
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Host Live GPS set: ${liveRes.displayName}'),
                                  backgroundColor: Colors.green.shade700,
                                ),
                              );
                            }
                          } catch (e) {
                            setState(() => _isGeocodingHostAddress = false);
                          }
                        },
                        icon: const Icon(Icons.my_location, size: 16),
                        label: const Text('Use Live GPS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryContainer.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, size: 12, color: AppColors.secondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Coordinates Locked: (${_hostLatitude.toStringAsFixed(4)}, ${_hostLongitude.toStringAsFixed(4)})',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSecondaryContainer,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _descriptionController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Vehicle Description & Features',
              prefixIcon: Icon(Icons.description),
            ),
          ),

          const SizedBox(height: 24),

          // 2. Multi-Photo Gallery Upload Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '2. Vehicle Photos Gallery (${_vehiclePhotos.length})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              if (_vehiclePhotos.isNotEmpty)
                TextButton.icon(
                  onPressed: () => setState(() => _vehiclePhotos.clear()),
                  icon: const Icon(Icons.delete_sweep, size: 16, color: Colors.redAccent),
                  label: const Text('Clear All', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Add multiple vehicle photos (exterior, interior, side view). The first photo will be used as the cover photo.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 14),

          // Multi-Photo Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _pickMultiGalleryImages,
                  icon: const Icon(Icons.photo_library, size: 18),
                  label: const Text('Add Multiple Photos', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickCameraPhoto,
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: const Text('Take Camera Photo', style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Add Web URL Input Field
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _urlInputController,
                  decoration: const InputDecoration(
                    labelText: 'Or Add Web Image Photo URL',
                    prefixIcon: Icon(Icons.link),
                    hintText: 'https://example.com/photo.jpg',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _addWebUrlPhoto,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Quick Select Sample Presets (Appends to Multi-Photo List)
          const Text('Quick Select Sample Photos (Tap to add to gallery):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SizedBox(
            height: 85,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _presetPhotos.length,
              itemBuilder: (context, idx) {
                final photo = _presetPhotos[idx];
                final isAlreadyAdded = _vehiclePhotos.contains(photo['url']);
                return GestureDetector(
                  onTap: () {
                    if (!isAlreadyAdded) {
                      setState(() {
                        _vehiclePhotos.add(photo['url']!);
                      });
                    }
                  },
                  child: Container(
                    width: 110,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isAlreadyAdded ? AppColors.primary : Colors.grey.shade400,
                        width: isAlreadyAdded ? 2.5 : 1,
                      ),
                      image: DecorationImage(
                        image: NetworkImage(photo['url']!),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                            color: Colors.black.withValues(alpha: 0.65),
                            child: Text(
                              photo['title']!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        if (isAlreadyAdded)
                          const Positioned(
                            top: 4,
                            right: 4,
                            child: CircleAvatar(
                              radius: 10,
                              backgroundColor: AppColors.primary,
                              child: Icon(Icons.check, size: 12, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Interactive Multi-Photo Gallery Horizontal Preview
          if (_vehiclePhotos.isNotEmpty) ...[
            const Text('Uploaded Vehicle Photo Gallery (Drag / Tap to manage):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _vehiclePhotos.length,
                itemBuilder: (context, index) {
                  final photoUrl = _vehiclePhotos[index];
                  final isCover = index == 0;

                  return Container(
                    width: 180,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isCover ? AppColors.primary : (isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight),
                        width: isCover ? 2.5 : 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (photoUrl.startsWith('data:image/'))
                          Image.memory(
                            base64Decode(photoUrl.split(',').last),
                            fit: BoxFit.cover,
                          )
                        else
                          Image.network(
                            photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => const Center(
                              child: Icon(Icons.broken_image, size: 36, color: Colors.grey),
                            ),
                          ),

                        // Cover Photo Badge
                        Positioned(
                          top: 8,
                          left: 8,
                          child: GestureDetector(
                            onTap: () => _setAsCoverPhoto(index),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isCover ? AppColors.primary : Colors.black.withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isCover ? Icons.star : Icons.photo,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isCover ? 'COVER PHOTO' : '#${index + 1} Set Cover',
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Delete Single Photo Button
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => _removePhoto(index),
                            child: const CircleAvatar(
                              radius: 13,
                              backgroundColor: Colors.black54,
                              child: Icon(Icons.close, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],

          // 3. Specifications & Seating
          const Text('3. Specifications & Seating', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedFuelType,
                  decoration: const InputDecoration(labelText: 'Fuel Type', prefixIcon: Icon(Icons.local_gas_station)),
                  items: ['Petrol', 'Diesel', 'Electric', 'Gasoline', 'Hybrid', 'CNG']
                      .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedFuelType = val!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedTransmission,
                  decoration: const InputDecoration(labelText: 'Transmission', prefixIcon: Icon(Icons.settings)),
                  items: ['Manual', 'Automatic']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedTransmission = val!),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 4. Pricing & Policies
          const Text('4. Rental Rates & Instant Booking', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),

          TextField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '24 Hours Rental Rate (₹ INR)',
              prefixIcon: Icon(Icons.currency_rupee),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pricePerHourController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Per Hour Rental Rate (₹ INR)',
              prefixIcon: Icon(Icons.timer),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Custom Time Range Pricing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _customStartTime,
                    );
                    if (time != null) {
                      setState(() => _customStartTime = time);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Start Time', prefixIcon: Icon(Icons.access_time), border: OutlineInputBorder()),
                    child: Text(_customStartTime.format(context)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _customEndTime,
                    );
                    if (time != null) {
                      setState(() => _customEndTime = time);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'End Time', prefixIcon: Icon(Icons.access_time), border: OutlineInputBorder()),
                    child: Text(_customEndTime.format(context)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _customRangePriceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Custom Range Rental Rate (₹ INR)',
              prefixIcon: Icon(Icons.currency_rupee),
            ),
          ),
          const SizedBox(height: 12),

          SwitchListTile(
            title: const Text('Enable Instant Booking', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: const Text('Verified renters can book without waiting for host approval', style: TextStyle(fontSize: 12)),
            value: _instantBook,
            onChanged: (val) => setState(() => _instantBook = val),
            activeColor: AppColors.secondary,
          ),

          const SizedBox(height: 24),

          // 5. Verify Vehicle Documents (Mandatory or Optional)
          Row(
            children: [
              Text(
                isExemptHost
                    ? '5. Verify Vehicle Documents (Optional)'
                    : '5. Verify Vehicle Documents (Mandatory)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(width: 8),
              if (isExemptHost)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade700,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'INITIAL EXEMPTION ACTIVE',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // RC Upload Sub-card (Mandatory or Optional for Exempt Hosts)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceContainerDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isExemptHost ? Icons.verified_outlined : Icons.description,
                      color: isExemptHost ? Colors.teal : AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isExemptHost
                            ? 'Vehicle Registration (RC) - Optional (Initial Launch Exemption)'
                            : 'Vehicle Registration (RC) - Mandatory',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16),
                const Text('VEHICLE REGISTRATION / RC NUMBER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 6),
                TextField(
                  controller: _rcNumberController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.numbers),
                    hintText: isExemptHost
                        ? 'e.g. WB11442A (Optional for initial launch)'
                        : 'e.g. WB11442A or KA01AB1234',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),

                // Registration Expiry Date Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('REGISTRATION EXPIRY DATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.surfaceContainerHighDark : AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_month, size: 18, color: AppColors.secondary),
                                const SizedBox(width: 8),
                                Text(
                                  '${_rcExpiryDate.year}-${_rcExpiryDate.month.toString().padLeft(2, '0')}-${_rcExpiryDate.day.toString().padLeft(2, '0')}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _rcExpiryDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 7300)),
                        );
                        if (picked != null) {
                          setState(() => _rcExpiryDate = picked);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                      child: const Text('Pick Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // File Attachment Dropzone
                const Text('UPLOAD RC DOCUMENT SCAN (PDF/JPG)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceContainerHighDark : AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.secondary, style: BorderStyle.solid),
                  ),
                  child: Column(
                    children: [
                      if (_isRcScanning) ...[
                        const SizedBox(
                          height: 60,
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.secondary),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'AI OCR Scanning RC Document...',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.secondary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ] else if (_rcFileBytes == null) ...[
                        Icon(
                          isExemptHost ? Icons.verified_outlined : Icons.cloud_upload_outlined,
                          size: 32,
                          color: isExemptHost ? Colors.teal : AppColors.secondary,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isExemptHost
                              ? 'No Document Selected (Optional for Initial Host)'
                              : 'No Document Selected',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        if (isExemptHost) ...[
                          const SizedBox(height: 4),
                          const Text(
                            'Initial host account is authorized to skip document upload.',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _pickRcDocument,
                          icon: const Icon(Icons.upload_file, size: 14),
                          label: Text(
                            isExemptHost ? 'Select File (Optional)' : 'Select File',
                            style: const TextStyle(fontSize: 11),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isExemptHost ? Colors.teal.shade700 : AppColors.secondary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Icon(
                              _rcFileExtension?.toUpperCase() == 'PDF' ? Icons.picture_as_pdf : Icons.image,
                              color: _rcFileExtension?.toUpperCase() == 'PDF' ? Colors.red : Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _rcFileName,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${(_rcFileBytes!.lengthInBytes / 1024.0).toStringAsFixed(0)} KB',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red, size: 18),
                              onPressed: () => setState(() {
                                _rcFileBytes = null;
                                _rcFileName = '';
                                _rcFileExtension = null;
                              }),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Challan Clearance Upload Sub-card (Optional)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceContainerDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.receipt_long, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Challan Clearance Certificate - Optional', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                const Divider(height: 16),
                const Text('CHALLAN REFERENCE / NUMBER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 6),
                TextField(
                  controller: _challanNumberController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.numbers),
                    hintText: 'e.g. CHN99887722',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),

                // Challan Date Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('CHALLAN DATE / CLEARANCE DATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.surfaceContainerHighDark : AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_month, size: 18, color: AppColors.secondary),
                                const SizedBox(width: 8),
                                Text(
                                  '${_challanDate.year}-${_challanDate.month.toString().padLeft(2, '0')}-${_challanDate.day.toString().padLeft(2, '0')}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _challanDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() => _challanDate = picked);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                      child: const Text('Pick Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // File Attachment Dropzone
                const Text('UPLOAD CHALLAN CLEARANCE DOCUMENT (PDF/JPG)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceContainerHighDark : AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.secondary, style: BorderStyle.solid),
                  ),
                  child: Column(
                    children: [
                      if (_isChallanScanning) ...[
                        const SizedBox(
                          height: 60,
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.secondary),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'AI OCR Scanning Challan clearance...',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.secondary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ] else if (_challanFileBytes == null) ...[
                        const Icon(Icons.cloud_upload_outlined, size: 32, color: AppColors.secondary),
                        const SizedBox(height: 6),
                        const Text('No Document Selected', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _pickChallanDocument,
                          icon: const Icon(Icons.upload_file, size: 14),
                          label: const Text('Select File', style: TextStyle(fontSize: 11)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Icon(
                              _challanFileExtension?.toUpperCase() == 'PDF' ? Icons.picture_as_pdf : Icons.image,
                              color: _challanFileExtension?.toUpperCase() == 'PDF' ? Colors.red : Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _challanFileName,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${(_challanFileBytes!.lengthInBytes / 1024.0).toStringAsFixed(0)} KB',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red, size: 18),
                              onPressed: () => setState(() {
                                _challanFileBytes = null;
                                _challanFileName = '';
                                _challanFileExtension = null;
                              }),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Insurance Upload Sub-card (Optional)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceContainerDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.shield_outlined, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Insurance Certificate (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                const Divider(height: 16),
                const Text('INSURANCE POLICY NUMBER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 6),
                TextField(
                  controller: _insurancePolicyController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.numbers),
                    hintText: 'e.g. POL123456789',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),

                const Text('INSURANCE PROVIDER / COMPANY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 6),
                TextField(
                  controller: _insuranceProviderController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.business),
                    hintText: 'e.g. HDFC Ergo, ICICI Lombard',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),

                // Policy Expiry Date Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('POLICY EXPIRY DATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.surfaceContainerHighDark : AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_month, size: 18, color: AppColors.secondary),
                                const SizedBox(width: 8),
                                Text(
                                  '${_insuranceExpiryDate.year}-${_insuranceExpiryDate.month.toString().padLeft(2, '0')}-${_insuranceExpiryDate.day.toString().padLeft(2, '0')}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _insuranceExpiryDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 7300)),
                        );
                        if (picked != null) {
                          setState(() => _insuranceExpiryDate = picked);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                      child: const Text('Pick Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // File Attachment Dropzone
                const Text('UPLOAD INSURANCE POLICY SCAN (PDF/JPG)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceContainerHighDark : AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.secondary, style: BorderStyle.solid),
                  ),
                  child: Column(
                    children: [
                      if (_insuranceFileBytes == null) ...[
                        const Icon(Icons.cloud_upload_outlined, size: 32, color: AppColors.secondary),
                        const SizedBox(height: 6),
                        const Text('No Document Selected', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _pickInsuranceDocument,
                          icon: const Icon(Icons.upload_file, size: 14),
                          label: const Text('Select File', style: TextStyle(fontSize: 11)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Icon(
                              _insuranceFileExtension?.toUpperCase() == 'PDF' ? Icons.picture_as_pdf : Icons.image,
                              color: _insuranceFileExtension?.toUpperCase() == 'PDF' ? Colors.red : Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _insuranceFileName,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${(_insuranceFileBytes!.lengthInBytes / 1024.0).toStringAsFixed(0)} KB',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red, size: 18),
                              onPressed: () => setState(() {
                                _insuranceFileBytes = null;
                                _insuranceFileName = '';
                                _insuranceFileExtension = null;
                              }),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting
                  ? null
                  : () async {
                      if (_isSubmitting) return;

                      // Document validation before submitting
                      final isExempt = appState.isDocumentExemptHost();
                      final rcNum = _rcNumberController.text.trim();
                      final challanNum = _challanNumberController.text.trim();
                      final insurancePolicy = _insurancePolicyController.text.trim();
                      final insuranceProvider = _insuranceProviderController.text.trim();

                      if (!isEditMode && !isExempt && (rcNum.isEmpty || _rcFileBytes == null)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('⚠️ Please enter the Vehicle Registration (RC) number and upload the RC document scan.'),
                            backgroundColor: Colors.orange,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }

                      // Challan Clearance is optional, no validation check needed.

                      setState(() {
                        _isSubmitting = true;
                      });

                      try {
                        final title = _titleController.text.trim();
                        final price = double.tryParse(_priceController.text.trim()) ?? 500.0;
                        final isCar = _selectedCategory.contains('Car');
                        final isScooter = _selectedCategory.contains('Scooter');
                        final isElectric = _selectedCategory.contains('Electric') || _selectedFuelType == 'Electric';

                        String coverImageUrl = _vehiclePhotos.isNotEmpty
                            ? _vehiclePhotos.first
                            : (isCar
                                ? 'https://images.unsplash.com/photo-1560958089-b8a1929cea89?w=800&q=80'
                                : (isScooter
                                    ? 'https://images.unsplash.com/photo-1558981806-ec527fa84c39?w=800&q=80'
                                    : 'https://images.unsplash.com/photo-1558981403-c5f9899a28bc?w=800&q=80'));

                        final pricePerHour = double.tryParse(_pricePerHourController.text.trim()) ?? 99.0;
                        final customRangePrice = double.tryParse(_customRangePriceController.text.trim()) ?? 499.0;
                        final customStartTimeStr = '${_customStartTime.hour.toString().padLeft(2, '0')}:${_customStartTime.minute.toString().padLeft(2, '0')}';
                        final customEndTimeStr = '${_customEndTime.hour.toString().padLeft(2, '0')}:${_customEndTime.minute.toString().padLeft(2, '0')}';

                        final ikService = ImageKitService();

                        if (isEditMode) {
                          final currentV = widget.vehicleToEdit!;
                          final updatedVehicle = currentV.copyWith(
                            title: title.isEmpty ? currentV.title : title,
                            type: isElectric
                                ? VehicleType.electric
                                : (isCar ? VehicleType.car : (isScooter ? VehicleType.scooter : VehicleType.bike)),
                            category: _selectedCategory,
                            pricePerDay: price,
                            pricePerHour: pricePerHour,
                            customTimeRangeStart: customStartTimeStr,
                            customTimeRangeEnd: customEndTimeStr,
                            customTimeRangePrice: customRangePrice,
                            imageUrl: coverImageUrl,
                            images: _vehiclePhotos.isNotEmpty ? _vehiclePhotos : [coverImageUrl],
                            location: _locationController.text.trim().isNotEmpty
                                ? _locationController.text.trim()
                                : currentV.location,
                            latitude: _hostLatitude,
                            longitude: _hostLongitude,
                            status: _selectedStatus,
                            fuelType: _selectedFuelType,
                            transmission: _selectedTransmission,
                            seats: _seats,
                            quantity: _quantity,
                            description: _descriptionController.text.trim().isNotEmpty
                                ? _descriptionController.text.trim()
                                : currentV.description,
                            isInstantBookable: _instantBook,
                            iotData: {
                              ...currentV.iotData,
                              'plateNumber': _vinController.text.trim(),
                            },
                          );

                          // Upload RC Scan to CDN if provided during edit
                          String rcUrl = '';
                          if (_rcFileBytes != null) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('☁️ Uploading RC document scan to CDN...'),
                                  backgroundColor: Colors.blue,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                            rcUrl = await ikService.uploadImage(
                              bytes: _rcFileBytes!,
                              fileName: 'rc_${updatedVehicle.id}_${DateTime.now().millisecondsSinceEpoch}.${_rcFileExtension ?? "pdf"}',
                              folder: '/compliance_documents',
                            ) ?? '';
                          }

                          // Upload Challan Scan to CDN if provided during edit
                          String challanUrl = '';
                          if (_challanFileBytes != null) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('☁️ Uploading Challan Clearance scan to CDN...'),
                                  backgroundColor: Colors.blue,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                            challanUrl = await ikService.uploadImage(
                              bytes: _challanFileBytes!,
                              fileName: 'challan_${updatedVehicle.id}_${DateTime.now().millisecondsSinceEpoch}.${_challanFileExtension ?? "pdf"}',
                              folder: '/compliance_documents',
                            ) ?? '';
                          }

                          // Upload Insurance Scan to CDN if provided during edit
                          String insuranceUrl = '';
                          if (_insuranceFileBytes != null) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('☁️ Uploading Insurance document scan to CDN...'),
                                  backgroundColor: Colors.blue,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                            insuranceUrl = await ikService.uploadImage(
                              bytes: _insuranceFileBytes!,
                              fileName: 'insurance_${updatedVehicle.id}_${DateTime.now().millisecondsSinceEpoch}.${_insuranceFileExtension ?? "pdf"}',
                              folder: '/compliance_documents',
                            ) ?? '';
                          }

                          // Save updated compliance documents if any were uploaded
                          if (_rcFileBytes != null || rcNum.isNotEmpty) {
                            final rcDoc = ComplianceDocument(
                              id: 'doc_rc_${DateTime.now().millisecondsSinceEpoch}',
                              title: 'Vehicle Registration (${appState.activeUserDisplayName})',
                              type: 'Vehicle Registration (RC)',
                              status: _rcExpiryDate.isBefore(DateTime.now()) ? 'Action Required' : 'Verified',
                              expiryDate: _rcExpiryDate,
                              documentUrl: rcUrl,
                              documentNumber: rcNum.isNotEmpty
                                  ? rcNum
                                  : (_vinController.text.trim().isNotEmpty
                                      ? _vinController.text.trim()
                                      : 'RC-UPDATED'),
                              holderName: appState.activeUserDisplayName,
                              licenseType: 'Vehicle: ${updatedVehicle.title} (${updatedVehicle.id})',
                              fileSizeKb: _rcFileBytes != null ? _rcFileBytes!.lengthInBytes / 1024.0 : 0.0,
                              fileName: _rcFileName.isNotEmpty ? _rcFileName : 'rc_document.pdf',
                              fileExtension: (_rcFileExtension ?? 'PDF').toUpperCase(),
                              confidenceScore: 100.0,
                              issuingAuthority: 'Govt Transport Department (RTO)',
                              address: '',
                              dob: '',
                              isExpiryValid: _rcExpiryDate.isAfter(DateTime.now()),
                            );
                            await appState.addComplianceDocument(rcDoc);
                          }

                          if (_challanFileBytes != null || challanNum.isNotEmpty) {
                            final challanDoc = ComplianceDocument(
                              id: 'doc_challan_${DateTime.now().millisecondsSinceEpoch}',
                              title: 'Challan Clearance Certificate (${appState.activeUserDisplayName})',
                              type: 'Challan Clearance',
                              status: 'Verified',
                              expiryDate: _challanDate,
                              documentUrl: challanUrl,
                              documentNumber: challanNum,
                              holderName: appState.activeUserDisplayName,
                              licenseType: 'Vehicle: ${updatedVehicle.title} (${updatedVehicle.id})',
                              fileSizeKb: _challanFileBytes != null ? _challanFileBytes!.lengthInBytes / 1024.0 : 0.0,
                              fileName: _challanFileName,
                              fileExtension: (_challanFileExtension ?? 'PDF').toUpperCase(),
                              confidenceScore: 100.0,
                              issuingAuthority: 'Traffic Police Department',
                              address: '',
                              dob: '',
                              isExpiryValid: true,
                            );
                            await appState.addComplianceDocument(challanDoc);
                          }

                          if (_insuranceFileBytes != null || insurancePolicy.isNotEmpty) {
                            final insuranceDoc = ComplianceDocument(
                              id: 'doc_ins_${DateTime.now().millisecondsSinceEpoch}',
                              title: 'Insurance Certificate (${appState.activeUserDisplayName})',
                              type: 'Insurance Certificate',
                              status: 'Verified',
                              expiryDate: _insuranceExpiryDate,
                              documentUrl: insuranceUrl,
                              documentNumber: insurancePolicy.isNotEmpty ? insurancePolicy : 'General-Policy',
                              holderName: appState.activeUserDisplayName,
                              licenseType: 'Vehicle: ${updatedVehicle.title} (${updatedVehicle.id})',
                              fileSizeKb: _insuranceFileBytes != null ? _insuranceFileBytes!.lengthInBytes / 1024.0 : 0.0,
                              fileName: _insuranceFileName.isNotEmpty ? _insuranceFileName : 'insurance_doc.pdf',
                              fileExtension: (_insuranceFileExtension ?? 'PDF').toUpperCase(),
                              confidenceScore: 100.0,
                              issuingAuthority: insuranceProvider.isNotEmpty ? insuranceProvider : 'Private Insurance Provider',
                              address: '',
                              dob: '',
                              isExpiryValid: _insuranceExpiryDate.isAfter(DateTime.now()),
                            );
                            await appState.addComplianceDocument(insuranceDoc);
                          }

                          await appState.updateVehicle(updatedVehicle);

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('✅ Vehicle "${updatedVehicle.title}" updated successfully!'),
                                backgroundColor: Colors.green.shade700,
                              ),
                            );
                            appState.selectVehicle(updatedVehicle);
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop(updatedVehicle);
                            } else {
                              appState.setNavIndex(8);
                            }
                          }
                          return;
                        }

                        final newVehicle = Vehicle(
                          id: 'v_${DateTime.now().millisecondsSinceEpoch}',
                          title: title.isEmpty ? 'Custom Vehicle Listing' : title,
                          type: isElectric
                              ? VehicleType.electric
                              : (isCar ? VehicleType.car : (isScooter ? VehicleType.scooter : VehicleType.bike)),
                          category: _selectedCategory,
                          pricePerDay: price,
                          pricePerHour: pricePerHour,
                          customTimeRangeStart: customStartTimeStr,
                          customTimeRangeEnd: customEndTimeStr,
                          customTimeRangePrice: customRangePrice,
                          rating: 5.0,
                          reviewCount: 1,
                          imageUrl: coverImageUrl,
                          images: _vehiclePhotos.isNotEmpty ? _vehiclePhotos : [coverImageUrl],
                          location: _locationController.text.trim().isNotEmpty
                              ? _locationController.text.trim()
                              : appState.selectedLocation,
                          latitude: _hostLatitude,
                          longitude: _hostLongitude,
                          status: 'Available',
                          hostName: appState.activeUserDisplayName,
                          hostAvatar: appState.activeUserPhotoUrl,
                          hostTrustScore: appState.activeUserTrustScore,
                          hostId: appState.userProfile?.uid ?? appState.supabaseUser?.id ?? '',
                          fuelType: _selectedFuelType,
                          transmission: _selectedTransmission,
                          seats: _seats,
                          quantity: _quantity,
                          description: _descriptionController.text.trim().isNotEmpty
                              ? _descriptionController.text.trim()
                              : 'Freshly registered rental listing. Maintained in prime condition with keyless IoT access.',
                          iotData: {
                            'locked': true,
                            'engineOn': false,
                            'batteryLevel': 98,
                            'odometer': 1200,
                            'tirePressureFront': 32.0,
                            'tirePressureRear': 35.0,
                            'lat': _hostLatitude,
                            'lng': _hostLongitude,
                            'plateNumber': _vinController.text.trim(),
                            'initialExemptionApplied': isExempt,
                            'documentStatus': _rcFileBytes != null ? 'Verified' : 'InitialExemption',
                          },
                        );

                        // 1. Upload RC Scan to CDN (If provided)
                        String rcUrl = '';
                        if (_rcFileBytes != null) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('☁️ Uploading RC document scan to CDN...'),
                                backgroundColor: Colors.blue,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                          rcUrl = await ikService.uploadImage(
                            bytes: _rcFileBytes!,
                            fileName: 'rc_${newVehicle.id}_${DateTime.now().millisecondsSinceEpoch}.${_rcFileExtension ?? "pdf"}',
                            folder: '/compliance_documents',
                          ) ?? '';
                        }

                        // 2. Upload Challan Scan to CDN (If provided)
                        String challanUrl = '';
                        if (_challanFileBytes != null) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('☁️ Uploading Challan Clearance scan to CDN...'),
                                backgroundColor: Colors.blue,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                          challanUrl = await ikService.uploadImage(
                            bytes: _challanFileBytes!,
                            fileName: 'challan_${newVehicle.id}_${DateTime.now().millisecondsSinceEpoch}.${_challanFileExtension ?? "pdf"}',
                            folder: '/compliance_documents',
                          ) ?? '';
                        }

                        // 3. Upload Insurance Scan to CDN (If provided)
                        String insuranceUrl = '';
                        if (_insuranceFileBytes != null) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('☁️ Uploading Insurance document scan to CDN...'),
                                backgroundColor: Colors.blue,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                          insuranceUrl = await ikService.uploadImage(
                            bytes: _insuranceFileBytes!,
                            fileName: 'insurance_${newVehicle.id}_${DateTime.now().millisecondsSinceEpoch}.${_insuranceFileExtension ?? "pdf"}',
                            folder: '/compliance_documents',
                          ) ?? '';
                        }

                        // 4. Save RC ComplianceDocument
                        if (_rcFileBytes != null || rcNum.isNotEmpty) {
                          final rcDoc = ComplianceDocument(
                            id: 'doc_rc_${DateTime.now().millisecondsSinceEpoch}',
                            title: 'Vehicle Registration (${appState.activeUserDisplayName})',
                            type: 'Vehicle Registration (RC)',
                            status: _rcExpiryDate.isBefore(DateTime.now()) ? 'Action Required' : 'Verified',
                            expiryDate: _rcExpiryDate,
                            documentUrl: rcUrl,
                            documentNumber: rcNum.isNotEmpty ? rcNum : 'INITIAL-EXEMPT',
                            holderName: appState.activeUserDisplayName,
                            licenseType: 'Vehicle: ${newVehicle.title} (${newVehicle.id})',
                            fileSizeKb: _rcFileBytes != null ? _rcFileBytes!.lengthInBytes / 1024.0 : 0.0,
                            fileName: _rcFileName.isNotEmpty ? _rcFileName : 'rc_initial_exemption.pdf',
                            fileExtension: (_rcFileExtension ?? 'PDF').toUpperCase(),
                            confidenceScore: 100.0,
                            issuingAuthority: 'Govt Transport Department (RTO)',
                            address: '',
                            dob: '',
                            isExpiryValid: _rcExpiryDate.isAfter(DateTime.now()),
                          );
                          await appState.addComplianceDocument(rcDoc);
                        } else if (isExempt) {
                          final exemptDoc = ComplianceDocument(
                            id: 'doc_rc_exempt_${DateTime.now().millisecondsSinceEpoch}',
                            title: 'Vehicle Registration Exemption (${appState.activeUserDisplayName})',
                            type: 'Vehicle Registration (RC)',
                            status: 'Initial Exemption (Active)',
                            expiryDate: DateTime.now().add(const Duration(days: 180)),
                            documentUrl: '',
                            documentNumber: 'INIT-EXEMPT-${newVehicle.id.substring(newVehicle.id.length > 8 ? newVehicle.id.length - 8 : 0)}',
                            holderName: appState.activeUserDisplayName,
                            licenseType: 'Vehicle: ${newVehicle.title} (${newVehicle.id})',
                            fileSizeKb: 0.0,
                            fileName: 'initial_exemption_record.pdf',
                            fileExtension: 'PDF',
                            confidenceScore: 100.0,
                            issuingAuthority: 'PassionRide Fast-Track Host Whitelist',
                            address: '',
                            dob: '',
                            isExpiryValid: true,
                          );
                          await appState.addComplianceDocument(exemptDoc);
                        }

                        // 5. Save Challan ComplianceDocument (If provided)
                        if (_challanFileBytes != null || challanNum.isNotEmpty) {
                          final challanDoc = ComplianceDocument(
                            id: 'doc_challan_${DateTime.now().millisecondsSinceEpoch}',
                            title: 'Challan Clearance Certificate (${appState.activeUserDisplayName})',
                            type: 'Challan Clearance',
                            status: _challanDate.isBefore(DateTime.now().subtract(const Duration(days: 30))) ? 'Action Required' : 'Verified',
                            expiryDate: _challanDate,
                            documentUrl: challanUrl,
                            documentNumber: challanNum,
                            holderName: appState.activeUserDisplayName,
                            licenseType: 'Vehicle: ${newVehicle.title} (${newVehicle.id})',
                            fileSizeKb: _challanFileBytes != null ? _challanFileBytes!.lengthInBytes / 1024.0 : 0.0,
                            fileName: _challanFileName,
                            fileExtension: (_challanFileExtension ?? 'PDF').toUpperCase(),
                            confidenceScore: 100.0,
                            issuingAuthority: 'Traffic Police Department',
                            address: '',
                            dob: '',
                            isExpiryValid: true,
                          );
                          await appState.addComplianceDocument(challanDoc);
                        }

                        // 6. Save Insurance ComplianceDocument (If provided)
                        if (_insuranceFileBytes != null || insurancePolicy.isNotEmpty) {
                          final insuranceDoc = ComplianceDocument(
                            id: 'doc_ins_${DateTime.now().millisecondsSinceEpoch}',
                            title: 'Insurance Certificate (${appState.activeUserDisplayName})',
                            type: 'Insurance Certificate',
                            status: _insuranceExpiryDate.isBefore(DateTime.now()) ? 'Action Required' : 'Verified',
                            expiryDate: _insuranceExpiryDate,
                            documentUrl: insuranceUrl,
                            documentNumber: insurancePolicy.isNotEmpty ? insurancePolicy : 'General-Policy',
                            holderName: appState.activeUserDisplayName,
                            licenseType: 'Vehicle: ${newVehicle.title} (${newVehicle.id})',
                            fileSizeKb: _insuranceFileBytes != null ? _insuranceFileBytes!.lengthInBytes / 1024.0 : 0.0,
                            fileName: _insuranceFileName.isNotEmpty ? _insuranceFileName : 'insurance_doc.pdf',
                            fileExtension: (_insuranceFileExtension ?? 'PDF').toUpperCase(),
                            confidenceScore: 100.0,
                            issuingAuthority: insuranceProvider.isNotEmpty ? insuranceProvider : 'Private Insurance Provider',
                            address: '',
                            dob: '',
                            isExpiryValid: _insuranceExpiryDate.isAfter(DateTime.now()),
                          );
                          await appState.addComplianceDocument(insuranceDoc);
                        }

                        // 7. Add Listing
                        await appState.addVehicle(newVehicle);

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isExempt && _rcFileBytes == null
                                    ? '🚀 Vehicle "${newVehicle.title}" published live under Initial Host Exemption!'
                                    : 'Vehicle "${newVehicle.title}" and its documents published live!',
                              ),
                              backgroundColor: Colors.green.shade700,
                            ),
                          );
                          appState.selectVehicle(newVehicle);
                          _titleController.clear();
                          _priceController.clear();
                          _locationController.clear();
                          _descriptionController.clear();
                          _rcNumberController.clear();
                          _challanNumberController.clear();
                          _insurancePolicyController.clear();
                          _insuranceProviderController.clear();
                          if (mounted) {
                            setState(() {
                              _vehiclePhotos.clear();
                              _rcFileBytes = null;
                              _rcFileName = '';
                              _rcFileExtension = null;
                              _challanFileBytes = null;
                              _challanFileName = '';
                              _challanFileExtension = null;
                              _insuranceFileBytes = null;
                              _insuranceFileName = '';
                              _insuranceFileExtension = null;
                              _isSubmitting = false;
                            });
                          }
                          appState.setNavIndex(8); // Redirect to Host Dashboard (Nav Index 8)
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error publishing vehicle: $e'), backgroundColor: Colors.red.shade800),
                          );
                        }
                      } finally {
                        if (mounted) {
                          setState(() {
                            _isSubmitting = false;
                          });
                        }
                      }
                    },
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : Icon(isEditMode ? Icons.save_outlined : Icons.publish),
              label: Text(
                _isSubmitting
                    ? (isEditMode ? 'Updating Vehicle...' : 'Publishing Vehicle...')
                    : (isEditMode ? 'Save & Update Vehicle Details' : 'Publish Vehicle Listing'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );

    if (isEditMode || Navigator.of(context).canPop()) {
      return Scaffold(
        appBar: AppBar(
          title: Text(isEditMode ? 'Edit Vehicle Details' : 'Register New Vehicle'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                appState.setNavIndex(8);
              }
            },
          ),
        ),
        body: SafeArea(child: content),
      );
    }

    return content;
  }

  Widget _buildInitialExemptionBanner(
    BuildContext context,
    AppState appState,
    bool isDark,
    bool isExempt,
  ) {
    final activeEmail = appState.activeUserEmail;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 460;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isExempt
                  ? [
                      Colors.teal.withOpacity(0.16),
                      AppColors.secondary.withOpacity(0.09),
                    ]
                  : [
                      Colors.orange.withOpacity(0.12),
                      Colors.amber.withOpacity(0.06),
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isExempt ? Colors.teal.shade400 : Colors.orange.shade300,
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: isExempt ? Colors.teal.shade700 : Colors.orange.shade800,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isExempt ? Icons.bolt_rounded : Icons.info_outline,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Text(
                          isExempt
                              ? 'FAST-TRACK INITIAL EXEMPTION'
                              : 'STANDARD COMPLIANCE MODE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.6,
                            color: isExempt
                                ? (isDark ? Colors.tealAccent : Colors.teal.shade800)
                                : (isDark ? Colors.orangeAccent : Colors.orange.shade900),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isExempt ? Colors.teal.shade700 : Colors.orange.shade800,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isExempt ? 'ACTIVE' : 'RC REQUIRED',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isCompact) ...[
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => ExemptHostsDialog.show(context),
                      icon: const Icon(Icons.tune, size: 14),
                      label: const Text('Whitelist', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isExempt ? Colors.teal.shade700 : Colors.orange.shade900,
                        side: BorderSide(
                          color: isExempt ? Colors.teal.shade400 : Colors.orange.shade400,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Text(
                isExempt
                    ? 'Account "$activeEmail" is authorized for initial vehicle hosting without uploading RC book scans or insurance documents.'
                    : 'Vehicle Registration (RC) document is mandatory. Testing or bootstrap hosting? Check whitelist settings.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              if (isCompact) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: () => ExemptHostsDialog.show(context),
                    icon: const Icon(Icons.tune, size: 14),
                    label: const Text('Manage Whitelist', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isExempt ? Colors.teal.shade700 : Colors.orange.shade900,
                      side: BorderSide(
                        color: isExempt ? Colors.teal.shade400 : Colors.orange.shade400,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}


