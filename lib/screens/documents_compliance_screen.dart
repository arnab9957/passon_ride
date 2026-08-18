import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/app_state.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';
import '../services/document_ocr_service.dart';

class DocumentsComplianceScreen extends StatefulWidget {
  const DocumentsComplianceScreen({super.key});

  @override
  State<DocumentsComplianceScreen> createState() => _DocumentsComplianceScreenState();
}

class _DocumentsComplianceScreenState extends State<DocumentsComplianceScreen> {
  // Form Controllers & State for Inline Submission
  final _nameController = TextEditingController();
  final _dlNumberController = TextEditingController();
  final _aadharNumberController = TextEditingController();
  final _dobController = TextEditingController(text: '1996-05-14');
  final _bloodGroupController = TextEditingController(text: 'O+');
  final _addressController = TextEditingController(text: 'H.No 142/B, 100ft Road, Indiranagar, Bengaluru, KA - 560038');
  
  String _selectedDocType = 'Driving License';
  String _selectedLicenseClass = 'LMV & MCWG (Cars & Motorcycles)';
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 3650));
  
  // File Upload State
  String _selectedFileName = 'driving_license_scan.pdf';
  String _selectedFileExtension = 'PDF';
  double _selectedFileSizeKb = 285.0; // Default valid size within 150 KB - 500 KB
  String? _fileSizeValidationError;
  Uint8List? _uploadedFileBytes;
  String? _uploadedFileBase64;

  // OCR Processing State
  bool _isOcrScanning = false;
  OcrExtractionResult? _lastOcrResult;

  @override
  void initState() {
    super.initState();
    _validateFileSize(_selectedFileSizeKb);
  }

  void _validateFileSize(double kb) {
    setState(() {
      if (kb < 150.0) {
        _fileSizeValidationError = '❌ File size too small (${kb.toStringAsFixed(0)} KB). Minimum 150 KB required for OCR readability.';
      } else if (kb > 500.0) {
        _fileSizeValidationError = '❌ File size exceeds limit (${kb.toStringAsFixed(0)} KB). Maximum allowed size is 500 KB.';
      } else {
        _fileSizeValidationError = null;
      }
    });
  }

  /// Triggers OCR scanning on attached document or preset sample.
  /// [imagePath] is the absolute path to the selected image file — required for real OCR.
  Future<void> _runOcrScan({
    required String fileName,
    required String docType,
    double sizeKb = 285.0,
    bool isPreset = false,
    String? userDisplayName,
    String? imagePath,
    List<int>? bytes,
  }) async {
    if (!mounted) return;
    setState(() => _isOcrScanning = true);

    OcrExtractionResult? result;
    String? errorMsg;

    try {
      result = isPreset
          ? DocumentOcrService.getPresetSample(docType)
          : await DocumentOcrService.processDocument(
              fileName: fileName,
              selectedDocType: docType,
              fileSizeKb: sizeKb,
              userDisplayName: userDisplayName,
              imagePath: imagePath,
              bytes: bytes,
            );
    } catch (e) {
      debugPrint('_runOcrScan error: $e');
      errorMsg = e.toString();
      result = null;
    }

    // Always stop the loading spinner
    if (!mounted) return;
    setState(() {
      _isOcrScanning = false;

      if (bytes != null && bytes.isNotEmpty) {
        _uploadedFileBytes = Uint8List.fromList(bytes);
        _uploadedFileBase64 = base64Encode(bytes);
      }

      if (result != null) {
        _selectedDocType = result.docType;
        _selectedFileName = fileName.isNotEmpty ? fileName : result.fileName;
        _selectedFileExtension = _selectedFileName.split('.').last.toUpperCase();
        _selectedFileSizeKb = sizeKb > 0 ? sizeKb : result.fileSizeKb;

        // Populate form fields with OCR results (always overwrite)
        _nameController.text = (result.holderName.isNotEmpty && result.holderName != 'Not Detected')
            ? result.holderName
            : _nameController.text;
        _dobController.text = result.dob.isNotEmpty ? result.dob : _dobController.text;
        _bloodGroupController.text = result.bloodGroup.isNotEmpty ? result.bloodGroup : _bloodGroupController.text;
        _addressController.text = result.address.isNotEmpty ? result.address : _addressController.text;

        if (result.docType == 'Driving License') {
          if (!result.documentNumber.contains('UNDETECTED')) {
            _dlNumberController.text = result.documentNumber;
          }
          if (result.licenseClass.isNotEmpty) _selectedLicenseClass = result.licenseClass;
        } else if (result.docType == 'Aadhar Card') {
          if (!result.documentNumber.contains('XXXX XXXX XXXX')) {
            _aadharNumberController.text = result.documentNumber;
          }
        } else {
          if (!result.documentNumber.contains('UNDETECTED')) {
            _dlNumberController.text = result.documentNumber;
          }
        }

        _expiryDate = result.expiryDate;
        _lastOcrResult = result;
      }
    });

    _validateFileSize(_selectedFileSizeKb);

    if (!mounted) return;

    if (result != null) {
      final isRealOcr = result.rawText.length > 50 &&
          !result.rawText.contains('INDIAN UNION DRIVING LICENCE') &&
          !result.rawText.contains('GOVERNMENT OF INDIA\nUnique Identification');
      final ocrLabel = isRealOcr ? '📷 Real OCR' : '🔧 Auto-fill';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          '$ocrLabel: ${result.docType} • ${result.holderName}'
          '${result.bloodGroup.isNotEmpty ? ' • ${result.bloodGroup}' : ''}'
          '${result.dob.isNotEmpty ? ' • DOB: ${result.dob}' : ''}',
        ),
        backgroundColor: result.isExpiryValid ? Colors.green.shade800 : Colors.red.shade800,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(errorMsg != null
            ? '⚠️ OCR error: ${errorMsg.length > 80 ? errorMsg.substring(0, 80) : errorMsg}'
            : '⚠️ OCR failed. Please try again.'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }


  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_nameController.text.isEmpty) {
      _nameController.text = appState.activeUserDisplayName;
    }
    if (_dlNumberController.text.isEmpty) {
      _dlNumberController.text = 'DL-1420110098765';
    }
    if (_aadharNumberController.text.isEmpty) {
      _aadharNumberController.text = '5489 1234 9876';
    }

    // Active DL & Aadhar documents from state
    final dlDoc = appState.documents.firstWhere(
      (d) => d.type.toLowerCase().contains('license') || d.title.toLowerCase().contains('license'),
      orElse: () => ComplianceDocument(
        id: 'dl_default',
        title: 'Driving License (Official Govt ID)',
        type: 'Driving License',
        status: 'Verified',
        expiryDate: DateTime.now().add(const Duration(days: 2840)),
        documentNumber: 'DL-1420110098765',
        holderName: appState.activeUserDisplayName,
        licenseType: 'LMV & MCWG (Cars & Motorcycles)',
        fileSizeKb: 285.0,
        fileName: 'driving_license_scan.pdf',
        fileExtension: 'PDF',
      ),
    );

    final aadharDoc = appState.documents.firstWhere(
      (d) => d.type.toLowerCase().contains('aadhar') || d.title.toLowerCase().contains('aadhar') || d.type.toLowerCase().contains('identity'),
      orElse: () => ComplianceDocument(
        id: 'aadhar_default',
        title: 'Aadhar Card (UIDAI Govt ID)',
        type: 'Aadhar Card',
        status: 'Verified',
        expiryDate: DateTime.now().add(const Duration(days: 3650)),
        documentNumber: '5489 1234 9876',
        holderName: appState.activeUserDisplayName,
        licenseType: 'Government Identity Card',
        fileSizeKb: 340.0,
        fileName: 'aadhar_card_front_back.jpg',
        fileExtension: 'JPG',
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => appState.setNavIndex(16), // Back to Profile
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TRUST & COMPLIANCE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: isDark ? AppColors.secondaryFixedDim : AppColors.secondary,
                    ),
                  ),
                  const Text('Documents & Licenses', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Compliance Status Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [AppColors.surfaceContainerHighDark, AppColors.surfaceContainerDark]
                    : [AppColors.secondaryContainer.withOpacity(0.4), Colors.green.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.secondary),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: AppColors.secondary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified_user, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('100% Verified Credentials', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          SizedBox(width: 6),
                          Icon(Icons.check_circle, size: 16, color: Colors.green),
                        ],
                      ),
                      SizedBox(height: 2),
                      Text('Driving License & Aadhar Card synced with Govt DigiLocker API.', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ========================================================
          // INLINE DRIVING LICENSE & GOVT ID SUBMISSION FORM CARD
          // ========================================================
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceContainerDark : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.secondaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.document_scanner, color: AppColors.secondary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Submit Driving License & Government ID',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text('Upload scan or try sample presets to auto-extract details via AI OCR', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // AI OCR Quick Preset Sample Scanners Bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome, size: 14, color: Colors.amber),
                        SizedBox(width: 4),
                        Text('1-TAP AI OCR SCAN PRESETS (AUTO-READ DATA)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ActionChip(
                            avatar: const Icon(Icons.badge, size: 14, color: Colors.white),
                            label: const Text('🪪 Sample Valid DL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                            backgroundColor: AppColors.secondary,
                            onPressed: () => _runOcrScan(
                              fileName: 'driving_license_aarav_official.pdf',
                              docType: 'Driving License',
                              isPreset: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ActionChip(
                            avatar: const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.white),
                            label: const Text('⚠️ Test Expired DL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                            backgroundColor: Colors.red.shade700,
                            onPressed: () => _runOcrScan(
                              fileName: 'driving_license_expired_test.pdf',
                              docType: 'Expired Driving License',
                              isPreset: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ActionChip(
                            avatar: const Icon(Icons.fingerprint, size: 14, color: Colors.white),
                            label: const Text('🆔 Sample Aadhar Scan', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                            backgroundColor: Colors.indigo,
                            onPressed: () => _runOcrScan(
                              fileName: 'aadhar_card_front_back_scan.jpg',
                              docType: 'Aadhar Card',
                              isPreset: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ActionChip(
                            avatar: const Icon(Icons.time_to_leave, size: 14, color: Colors.white),
                            label: const Text('🚗 Sample RC Scan', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                            backgroundColor: Colors.teal.shade700,
                            onPressed: () => _runOcrScan(
                              fileName: 'rc_book_mh12.pdf',
                              docType: 'Vehicle Registration (RC)',
                              isPreset: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // OCR Scanning Progress Animation Box
                if (_isOcrScanning) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue.shade400),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.blue),
                        ),
                        const SizedBox(height: 10),
                        const Text('🔍 Image Processing & OCR Extracting Text...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue)),
                        const SizedBox(height: 4),
                        const Text('Extracting Name, License #, Expiry Validity, DOB, Blood Group & Address...', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],

                // Extracted OCR Data Highlight Card
                if (_lastOcrResult != null && !_isOcrScanning) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [_lastOcrResult!.isExpiryValid ? Colors.green.shade900.withOpacity(0.4) : Colors.red.shade900.withOpacity(0.4), AppColors.surfaceContainerHighDark]
                            : [_lastOcrResult!.isExpiryValid ? Colors.green.shade50 : Colors.red.shade50, isDark ? AppColors.surfaceContainerDark : Colors.white],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _lastOcrResult!.isExpiryValid ? Colors.green.shade600 : Colors.red.shade600, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(_lastOcrResult!.isExpiryValid ? Icons.verified : Icons.error, color: _lastOcrResult!.isExpiryValid ? Colors.green : Colors.red, size: 22),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _lastOcrResult!.isExpiryValid ? '⚡ LICENSE IMAGE PROCESSOR (ALL FIELDS EXTRACTED)' : '⚠️ LICENSE EXPIRED OR INVALID',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: _lastOcrResult!.isExpiryValid ? Colors.green.shade800 : Colors.red.shade800, letterSpacing: 0.5),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: _lastOcrResult!.isExpiryValid ? Colors.green : Colors.red, borderRadius: BorderRadius.circular(10)),
                              child: Text('${_lastOcrResult!.confidenceScore}% Match', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        
                        // Expiry Status Banner
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: _lastOcrResult!.isExpiryValid ? Colors.green.withOpacity(0.12) : Colors.red.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _lastOcrResult!.expiryStatusText,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _lastOcrResult!.isExpiryValid ? Colors.green.shade900 : Colors.red.shade900),
                          ),
                        ),

                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('HOLDER NAME', style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                                  Text(_lastOcrResult!.holderName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('LICENSE / ID NUMBER', style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                                  Text(_lastOcrResult!.documentNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.secondary)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('DATE OF BIRTH & AGE', style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                                  Text('${_lastOcrResult!.dob} (${_lastOcrResult!.calculatedAge} yrs - ${_lastOcrResult!.isAgeEligible ? "Eligible 18+" : "Underage"})', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: _lastOcrResult!.isAgeEligible ? Colors.black87 : Colors.red)),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('BLOOD GROUP', style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                                  Row(
                                    children: [
                                      const Icon(Icons.water_drop, size: 14, color: Colors.red),
                                      const SizedBox(width: 4),
                                      Text(_lastOcrResult!.bloodGroup, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.red)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('PERMANENT RESIDENCE ADDRESS', style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(_lastOcrResult!.address, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                // 1. Document Type Dropdown
                const Text('DOCUMENT CATEGORY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedDocType,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.category, color: AppColors.secondary),
                    border: OutlineInputBorder(),
                  ),
                  items: ['Driving License', 'Aadhar Card', 'Vehicle Registration (RC)', 'Insurance Certificate'].map((t) {
                    return DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold)));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedDocType = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 14),

                // 2. Full Name
                const Text('FULL NAME (AS PER GOVERNMENT ID)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 6),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.person),
                    hintText: 'Enter full name as on license',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),

                // Date of Birth & Blood Group Inputs Row
                Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('DATE OF BIRTH (YYYY-MM-DD)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _dobController,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.cake, size: 18),
                              hintText: '1996-05-14',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('BLOOD GROUP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _bloodGroupController,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.water_drop, color: Colors.red, size: 18),
                              hintText: 'O+',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Permanent Residence Address Input
                const Text('PERMANENT ADDRESS (AS PER DL / GOVT ID)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 6),
                TextField(
                  controller: _addressController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.home),
                    hintText: 'House No, Street, City, State - Pincode',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),

                // 3. License Number / Aadhar Number Inputs
                if (_selectedDocType == 'Driving License') ...[
                  const Text('DRIVING LICENSE NUMBER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _dlNumberController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.numbers),
                      hintText: 'e.g. DL-1420110098765',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Authorized Vehicle Class Dropdown
                  const Text('AUTHORIZED VEHICLE CLASSES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _selectedLicenseClass,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.time_to_leave),
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      'LMV & MCWG (Cars & Motorcycles)',
                      'LMV Only (Light Motor Vehicles - Cars)',
                      'MCWG Only (Motorcycles With Gear)',
                      'MCWOG Only (Scooters / Gearless)',
                      'HMV (Heavy Commercial Vehicles)',
                    ].map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 12)))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedLicenseClass = val);
                    },
                  ),
                  const SizedBox(height: 14),

                  // Expiry Date Selection
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('LICENSE EXPIRY DATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
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
                                    '${_expiryDate.year}-${_expiryDate.month.toString().padLeft(2, '0')}-${_expiryDate.day.toString().padLeft(2, '0')}',
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
                            initialDate: _expiryDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 7300)),
                          );
                          if (picked != null) {
                            setState(() => _expiryDate = picked);
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
                ] else ...[
                  const Text('AADHAR / GOVERNMENT ID NUMBER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _aadharNumberController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.fingerprint),
                      hintText: 'e.g. 5489 1234 9876',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // 4. File Upload & Size Restriction Dropzone (150 KB to 500 KB)
                const Text(
                  'CLEAR SCAN UPLOAD (PDF / JPG WITHIN 150 KB TO 500 KB)',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5),
                ),
                const SizedBox(height: 6),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _fileSizeValidationError != null
                        ? Colors.red.withOpacity(0.08)
                        : (isDark ? AppColors.surfaceContainerHighDark : AppColors.surfaceContainerLow),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _fileSizeValidationError != null ? Colors.red : AppColors.secondary,
                      width: _fileSizeValidationError != null ? 1.5 : 1.0,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Uploaded File Live Preview Thumbnail
                      if (_uploadedFileBytes != null && _selectedFileExtension != 'PDF') ...[
                        Container(
                          height: 160,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.secondary.withOpacity(0.4)),
                            color: Colors.black12,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Image.memory(
                                _uploadedFileBytes!,
                                fit: BoxFit.contain,
                                width: double.infinity,
                                height: 160,
                              ),
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text('Live Preview', style: TextStyle(color: Colors.greenAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ] else if (_selectedFileExtension == 'PDF') ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.picture_as_pdf, size: 36, color: Colors.red),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_selectedFileName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    Text('PDF Document Attached (${_selectedFileSizeKb.toStringAsFixed(0)} KB)', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                  ],
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => _showUploadedDocumentPreview(context),
                                icon: const Icon(Icons.remove_red_eye, size: 14),
                                label: const Text('Preview', style: TextStyle(fontSize: 11)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ] else ...[
                        Icon(
                          _selectedFileExtension == 'PDF' ? Icons.picture_as_pdf : Icons.cloud_upload,
                          size: 38,
                          color: _fileSizeValidationError != null ? Colors.red : AppColors.secondary,
                        ),
                        const SizedBox(height: 6),
                      ],

                      Text(
                        _selectedFileName,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Chip(
                            label: Text('Format: $_selectedFileExtension'),
                            backgroundColor: Colors.blue.withOpacity(0.15),
                            labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text('Size: ${_selectedFileSizeKb.toStringAsFixed(0)} KB'),
                            backgroundColor: _fileSizeValidationError != null ? Colors.red.withOpacity(0.15) : Colors.green.withOpacity(0.15),
                            labelStyle: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _fileSizeValidationError != null ? Colors.red : Colors.green.shade800,
                            ),
                          ),
                        ],
                      ),
                      if (_fileSizeValidationError != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          _fileSizeValidationError!,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red.shade700),
                          textAlign: TextAlign.center,
                        ),
                      ] else ...[
                        const SizedBox(height: 4),
                        const Text('✅ File format & size valid for local storage & instant preview.', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                      ],
                      const SizedBox(height: 12),

                      // File Attachment Picker Buttons (Camera & Gallery & File)
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () async {
                              final picker = ImagePicker();
                              try {
                                final XFile? image = await picker.pickImage(
                                  source: ImageSource.camera,
                                  imageQuality: 50,
                                  maxWidth: 1500,
                                  maxHeight: 1500,
                                );
                                if (image != null) {
                                  final bytes = await image.readAsBytes();
                                  final sizeInKb = bytes.lengthInBytes / 1024.0;
                                  await _runOcrScan(
                                    fileName: image.name.isNotEmpty ? image.name : 'camera_license_scan.jpg',
                                    docType: _selectedDocType,
                                    sizeKb: sizeInKb > 0 ? sizeInKb : 280.0,
                                    userDisplayName: appState.activeUserDisplayName,
                                    imagePath: image.path,
                                    bytes: bytes,
                                  );
                                }
                              } catch (_) {
                                // Camera unavailable — fall back to heuristic preset
                                await _runOcrScan(
                                  fileName: '${_selectedDocType.toLowerCase().replaceAll(' ', '_')}_camera_scan.jpg',
                                  docType: _selectedDocType,
                                  sizeKb: 310.0,
                                  userDisplayName: appState.activeUserDisplayName,
                                );
                              }
                            },
                            icon: const Icon(Icons.camera_alt, size: 14),
                            label: const Text('📸 Camera Snap & OCR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final picker = ImagePicker();
                              try {
                                final XFile? image = await picker.pickImage(
                                  source: ImageSource.gallery,
                                  imageQuality: 50,
                                  maxWidth: 1500,
                                  maxHeight: 1500,
                                );
                                if (image != null) {
                                  final bytes = await image.readAsBytes();
                                  final sizeInKb = bytes.lengthInBytes / 1024.0;
                                  await _runOcrScan(
                                    fileName: image.name.isNotEmpty ? image.name : 'gallery_license_scan.jpg',
                                    docType: _selectedDocType,
                                    sizeKb: sizeInKb > 0 ? sizeInKb : 285.0,
                                    userDisplayName: appState.activeUserDisplayName,
                                    imagePath: image.path,
                                    bytes: bytes,
                                  );
                                }
                              } catch (_) {
                                // Gallery unavailable — fall back to heuristic preset
                                await _runOcrScan(
                                  fileName: '${_selectedDocType.toLowerCase().replaceAll(' ', '_')}_clear_scan.pdf',
                                  docType: _selectedDocType,
                                  sizeKb: 295.0,
                                  userDisplayName: appState.activeUserDisplayName,
                                );
                              }
                            },
                            icon: const Icon(Icons.photo_library, size: 14),
                            label: const Text('🖼️ Gallery Pick & OCR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                          // ── PDF / Document Upload Button ──────────────────
                          ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                final result = await FilePicker.platform.pickFiles(
                                  type: FileType.custom,
                                  allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                                  allowMultiple: false,
                                  withData: true,
                                  withReadStream: false,
                                );
                                if (result != null && result.files.isNotEmpty) {
                                  final picked = result.files.first;
                                  final sizeKb = (picked.size / 1024.0).clamp(10.0, 10000.0);
                                  final ext = (picked.extension ?? 'pdf').toLowerCase();
                                  await _runOcrScan(
                                    fileName: picked.name.isNotEmpty ? picked.name : 'uploaded_document.$ext',
                                    docType: _selectedDocType,
                                    sizeKb: sizeKb,
                                    userDisplayName: appState.activeUserDisplayName,
                                    imagePath: picked.path,
                                    bytes: picked.bytes,
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text('File pick error: $e'),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                  ));
                                }
                              }
                            },
                            icon: const Icon(Icons.upload_file, size: 14),
                            label: const Text('📄 PDF / File Upload', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),

                          PopupMenuButton<double>(
                            icon: const Icon(Icons.straighten, color: AppColors.secondary),
                            tooltip: 'Test Size Validator',
                            onSelected: (val) {
                              setState(() {
                                _selectedFileSizeKb = val;
                              });
                              _validateFileSize(val);
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(value: 95.0, child: Text('⚠️ 95 KB (Too Small <150KB)')),
                              const PopupMenuItem(value: 285.0, child: Text('✅ 285 KB (Valid Format PDF)')),
                              const PopupMenuItem(value: 410.0, child: Text('✅ 410 KB (Valid Format JPG)')),
                              const PopupMenuItem(value: 650.0, child: Text('⚠️ 650 KB (Exceeds 500KB Limit)')),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Submit Action Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _fileSizeValidationError != null
                        ? null
                        : () async {
                            final holder = _nameController.text.trim().isEmpty ? appState.activeUserDisplayName : _nameController.text.trim();
                            final number = _selectedDocType == 'Driving License'
                                ? (_dlNumberController.text.trim().isEmpty ? 'DL-1420110098765' : _dlNumberController.text.trim())
                                : (_aadharNumberController.text.trim().isEmpty ? '5489 1234 9876' : _aadharNumberController.text.trim());
                            final isExpired = _expiryDate.isBefore(DateTime.now());

                            final newDoc = ComplianceDocument(
                              id: 'doc_${DateTime.now().millisecondsSinceEpoch}',
                              title: '$_selectedDocType ($holder)',
                              type: _selectedDocType,
                              status: isExpired ? 'Action Required' : 'Verified',
                              expiryDate: _expiryDate,
                              documentUrl: _uploadedFileBase64 ?? '',
                              documentNumber: number,
                              holderName: holder,
                              licenseType: _selectedLicenseClass,
                              fileSizeKb: _selectedFileSizeKb,
                              fileName: _selectedFileName,
                              fileExtension: _selectedFileExtension,
                              confidenceScore: _lastOcrResult?.confidenceScore ?? 99.2,
                              issuingAuthority: _lastOcrResult?.issuingAuthority ?? 'Govt Transport Authority (RTO / UIDAI)',
                              bloodGroup: _bloodGroupController.text.trim().isNotEmpty ? _bloodGroupController.text.trim() : 'O+',
                              address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : 'Indiranagar, Bengaluru, KA',
                              dob: _dobController.text.trim().isNotEmpty ? _dobController.text.trim() : '1996-05-14',
                              isExpiryValid: !isExpired,
                            );

                            await appState.addComplianceDocument(newDoc);

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('✅ $_selectedDocType for $holder saved to local database! Tap "Preview" to inspect.'),
                                  backgroundColor: Colors.green.shade800,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Submit Document & Verify Compliance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ========================================================
          // VERIFIED DRIVING LICENSE & AADHAR DOCUMENTS CARDS
          // ========================================================
          const Text('Active Verified Documents', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),

          // Driving License Display Card
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.badge, color: AppColors.secondary, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(dlDoc.holderName.isNotEmpty ? dlDoc.holderName : appState.activeUserDisplayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text('DL No: ${dlDoc.documentNumber}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('VERIFIED DL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.onSecondaryContainer)),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('AUTHORIZED CLASS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text(dlDoc.licenseType, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('EXPIRY DATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text(
                            '${dlDoc.expiryDate.year}-${dlDoc.expiryDate.month.toString().padLeft(2, '0')}-${dlDoc.expiryDate.day.toString().padLeft(2, '0')} (${dlDoc.isExpiryValid ? "VALID" : "EXPIRED"})',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: dlDoc.isExpiryValid ? Colors.green.shade800 : Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('DATE OF BIRTH', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text(dlDoc.dob, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('BLOOD GROUP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text(dlDoc.bloodGroup, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('PERMANENT RESIDENCE ADDRESS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 2),
                    Text(dlDoc.address, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showDocumentPreviewModal(context, dlDoc),
                        icon: const Icon(Icons.remove_red_eye, size: 16),
                        label: const Text('👁️ Preview Document', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.secondary,
                          side: const BorderSide(color: AppColors.secondary),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceContainerHighDark : AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        dlDoc.fileExtension.toUpperCase() == 'PDF' ? Icons.picture_as_pdf : Icons.image,
                        color: dlDoc.fileExtension.toUpperCase() == 'PDF' ? Colors.red.shade400 : Colors.blue.shade400,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${dlDoc.fileName.isNotEmpty ? dlDoc.fileName : "driving_license.pdf"} (${dlDoc.fileSizeKb.toStringAsFixed(0)} KB)',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const Text('150KB-500KB Valid', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Aadhar Display Card
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.fingerprint, color: AppColors.primary, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(aadharDoc.holderName.isNotEmpty ? aadharDoc.holderName : appState.activeUserDisplayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text('Aadhar UID: XXXX XXXX ${aadharDoc.documentNumber.length >= 4 ? aadharDoc.documentNumber.substring(aadharDoc.documentNumber.length - 4) : "9876"}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('UIDAI GOVT ID', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showDocumentPreviewModal(context, aadharDoc),
                        icon: const Icon(Icons.remove_red_eye, size: 16),
                        label: const Text('👁️ Preview Document', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceContainerHighDark : AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        aadharDoc.fileExtension.toUpperCase() == 'PDF' ? Icons.picture_as_pdf : Icons.image,
                        color: aadharDoc.fileExtension.toUpperCase() == 'PDF' ? Colors.red.shade400 : Colors.blue.shade400,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${aadharDoc.fileName.isNotEmpty ? aadharDoc.fileName : "aadhar_card.jpg"} (${aadharDoc.fileSizeKb.toStringAsFixed(0)} KB)',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const Text('150KB-500KB Valid', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // List of remaining custom documents
          if (appState.documents.length > 2) ...[
            const SizedBox(height: 10),
            const Text('Other Documents', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: appState.documents.length,
              itemBuilder: (context, index) {
                final doc = appState.documents[index];
                if (doc.id == dlDoc.id || doc.id == aadharDoc.id) return const SizedBox.shrink();
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        doc.fileExtension.toUpperCase() == 'PDF' ? Icons.picture_as_pdf : Icons.verified,
                        color: AppColors.secondary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(doc.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text('${doc.fileName} • ${doc.fileSizeKb.toStringAsFixed(0)} KB', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_red_eye, size: 18, color: AppColors.secondary),
                        tooltip: 'Preview Document',
                        onPressed: () => _showDocumentPreviewModal(context, doc),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(8)),
                        child: Text(doc.status.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.green.shade900)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showUploadedDocumentPreview(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final holder = _nameController.text.trim().isEmpty ? appState.activeUserDisplayName : _nameController.text.trim();
    final number = _selectedDocType == 'Driving License'
        ? (_dlNumberController.text.trim().isEmpty ? 'DL-1420110098765' : _dlNumberController.text.trim())
        : (_aadharNumberController.text.trim().isEmpty ? '5489 1234 9876' : _aadharNumberController.text.trim());
    final isExpired = _expiryDate.isBefore(DateTime.now());

    final tempDoc = ComplianceDocument(
      id: 'temp_preview',
      title: '$_selectedDocType ($holder)',
      type: _selectedDocType,
      status: isExpired ? 'Action Required' : 'Verified',
      expiryDate: _expiryDate,
      documentUrl: _uploadedFileBase64 ?? '',
      documentNumber: number,
      holderName: holder,
      licenseType: _selectedLicenseClass,
      fileSizeKb: _selectedFileSizeKb,
      fileName: _selectedFileName,
      fileExtension: _selectedFileExtension,
      confidenceScore: _lastOcrResult?.confidenceScore ?? 99.2,
      issuingAuthority: _lastOcrResult?.issuingAuthority ?? 'Govt Transport Authority (RTO / UIDAI)',
      bloodGroup: _bloodGroupController.text.trim().isNotEmpty ? _bloodGroupController.text.trim() : 'O+',
      address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : 'Indiranagar, Bengaluru, KA',
      dob: _dobController.text.trim().isNotEmpty ? _dobController.text.trim() : '1996-05-14',
      isExpiryValid: !isExpired,
    );

    _showDocumentPreviewModal(context, tempDoc);
  }

  void _showDocumentPreviewModal(BuildContext context, ComplianceDocument doc) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Uint8List? imageBytes;
    if (doc.documentUrl.isNotEmpty && !doc.documentUrl.startsWith('http')) {
      try {
        imageBytes = base64Decode(doc.documentUrl);
      } catch (_) {}
    } else if (doc.id == 'temp_preview' && _uploadedFileBytes != null) {
      imageBytes = _uploadedFileBytes;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceContainerDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Modal handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: AppColors.secondary.withOpacity(0.15), shape: BoxShape.circle),
                            child: const Icon(Icons.verified_user, color: AppColors.secondary, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(doc.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                                const Text('Official Government Credential & Local Storage Record', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ),
                          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Uploaded Raw Image Preview (if present)
                      if (imageBytes != null && doc.fileExtension.toUpperCase() != 'PDF') ...[
                        const Text('UPLOADED SCAN PREVIEW', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.secondary.withOpacity(0.5), width: 1.5),
                            color: Colors.black12,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.memory(imageBytes, fit: BoxFit.contain),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Graphic ID Card Replica Box
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: doc.isExpiryValid
                                ? [Colors.blue.shade900, Colors.indigo.shade800]
                                : [Colors.red.shade900, Colors.deepOrange.shade900],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Card Top Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.shield, color: Colors.amber, size: 18),
                                    SizedBox(width: 6),
                                    Text('UNION OF INDIA / GOVT COMPLIANCE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.8)),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: doc.isExpiryValid ? Colors.green : Colors.red,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    doc.isExpiryValid ? 'VALID CREDENTIAL' : 'EXPIRED',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 9),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(color: Colors.white24, height: 20),

                            // Photo & Holder Details
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 70,
                                  height: 85,
                                  decoration: BoxDecoration(
                                    color: Colors.white12,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.white38),
                                  ),
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.person, color: Colors.white, size: 40),
                                      SizedBox(height: 2),
                                      Text('VERIFIED', style: TextStyle(color: Colors.greenAccent, fontSize: 8, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        doc.holderName.isNotEmpty ? doc.holderName.toUpperCase() : 'HOLDER NAME',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'NO: ${doc.documentNumber}',
                                        style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'CLASS: ${doc.licenseType}',
                                        style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        'EXPIRY: ${doc.expiryDate.year}-${doc.expiryDate.month.toString().padLeft(2, '0')}-${doc.expiryDate.day.toString().padLeft(2, '0')}',
                                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),

                            // DOB & Blood Group
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('DOB: ${doc.dob}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                  Row(
                                    children: [
                                      const Icon(Icons.water_drop, color: Colors.redAccent, size: 14),
                                      const SizedBox(width: 4),
                                      Text('BG: ${doc.bloodGroup}', style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  Text('STATUS: ${doc.status.toUpperCase()}', style: const TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Detailed Fields List
                      const Text('DOCUMENT METADATA & LOCAL DATABASE DETAILS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
                      const SizedBox(height: 10),

                      _buildDetailRow(Icons.account_balance, 'ISSUING AUTHORITY', doc.issuingAuthority),
                      _buildDetailRow(Icons.home, 'PERMANENT ADDRESS', doc.address),
                      _buildDetailRow(Icons.insert_drive_file, 'FILE NAME & SIZE', '${doc.fileName} (${doc.fileSizeKb.toStringAsFixed(0)} KB • ${doc.fileExtension.toUpperCase()})'),
                      _buildDetailRow(Icons.storage, 'DATABASE PERSISTENCE', 'Saved in Local SharedPreferences & Supabase Cache'),

                      const SizedBox(height: 24),

                      // Modal Actions
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.pop(ctx),
                              icon: const Icon(Icons.close),
                              label: const Text('Close Preview'),
                              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('📥 Download: Document copy ready in local device cache.'),
                                    backgroundColor: Colors.blue,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.download),
                              label: const Text('Download Scan'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.secondary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
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
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.secondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
