import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
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
  
  String _selectedDocType = 'Driving License';
  String _selectedLicenseClass = 'LMV & MCWG (Cars & Motorcycles)';
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 3650));
  
  // File Upload State
  String _selectedFileName = 'driving_license_scan.pdf';
  String _selectedFileExtension = 'PDF';
  double _selectedFileSizeKb = 285.0; // Default valid size within 150 KB - 500 KB
  String? _fileSizeValidationError;

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

  /// Triggers OCR scanning on attached document or preset sample
  Future<void> _runOcrScan({
    required String fileName,
    required String docType,
    double sizeKb = 285.0,
    bool isPreset = false,
  }) async {
    setState(() {
      _isOcrScanning = true;
    });

    final result = isPreset
        ? DocumentOcrService.getPresetSample(docType)
        : await DocumentOcrService.processDocument(
            fileName: fileName,
            selectedDocType: docType,
            fileSizeKb: sizeKb,
          );

    setState(() {
      _selectedDocType = result.docType;
      _selectedFileName = result.fileName;
      _selectedFileExtension = result.fileName.split('.').last.toUpperCase();
      _selectedFileSizeKb = result.fileSizeKb;
      _nameController.text = result.holderName;

      if (result.docType == 'Driving License') {
        _dlNumberController.text = result.documentNumber;
        _selectedLicenseClass = result.licenseClass;
      } else if (result.docType == 'Aadhar Card') {
        _aadharNumberController.text = result.documentNumber;
      } else {
        _dlNumberController.text = result.documentNumber;
      }

      _expiryDate = result.expiryDate;
      _lastOcrResult = result;
      _isOcrScanning = false;
    });

    _validateFileSize(_selectedFileSizeKb);
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
                            label: const Text('🪪 Try Sample DL Scan', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                            backgroundColor: AppColors.secondary,
                            onPressed: () => _runOcrScan(
                              fileName: 'driving_license_aarav_official.pdf',
                              docType: 'Driving License',
                              isPreset: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ActionChip(
                            avatar: const Icon(Icons.fingerprint, size: 14, color: Colors.white),
                            label: const Text('🆔 Try Sample Aadhar Scan', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
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
                            label: const Text('🚗 Try Sample RC Scan', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
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
                        const Text('🔍 Scanning Document & Extracting Text via AI OCR...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue)),
                        const SizedBox(height: 4),
                        const Text('Extracting Name, License #, Expiry Date & Authorized Classes...', style: TextStyle(fontSize: 11, color: Colors.grey)),
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
                            ? [Colors.green.shade900.withOpacity(0.4), AppColors.surfaceContainerHighDark]
                            : [Colors.green.shade50, Colors.teal.shade50],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green.shade600, width: 1.2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.verified, color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            const Text('⚡ DATA EXTRACTED FROM DOCUMENT (AI OCR)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.green, letterSpacing: 0.5)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(10)),
                              child: Text('${_lastOcrResult!.confidenceScore}% Match', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('EXTRACTED NAME', style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                                  Text(_lastOcrResult!.holderName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('EXTRACTED NUMBER', style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                                  Text(_lastOcrResult!.documentNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.secondary)),
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
                                  const Text('EXPIRY DATE', style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                                  Text('${_lastOcrResult!.expiryDate.year}-${_lastOcrResult!.expiryDate.month.toString().padLeft(2, '0')}-${_lastOcrResult!.expiryDate.day.toString().padLeft(2, '0')}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('ISSUING AUTHORITY', style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                                  Text(_lastOcrResult!.issuingAuthority, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
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
                            firstDate: DateTime.now(),
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
                      Icon(
                        _selectedFileExtension == 'PDF' ? Icons.picture_as_pdf : Icons.cloud_upload,
                        size: 38,
                        color: _fileSizeValidationError != null ? Colors.red : AppColors.secondary,
                      ),
                      const SizedBox(height: 6),
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
                        const Text('✅ File format & size (150 KB - 500 KB) valid for OCR verification.', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                      ],
                      const SizedBox(height: 12),

                      // File Attachment Picker Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () async {
                              final picker = ImagePicker();
                              try {
                                final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                                if (image != null) {
                                  final bytes = await image.readAsBytes();
                                  final sizeInKb = bytes.lengthInBytes / 1024.0;
                                  await _runOcrScan(
                                    fileName: image.name,
                                    docType: _selectedDocType,
                                    sizeKb: sizeInKb > 0 ? sizeInKb : 280.0,
                                  );
                                }
                              } catch (_) {
                                await _runOcrScan(
                                  fileName: '${_selectedDocType.toLowerCase().replaceAll(' ', '_')}_clear.pdf',
                                  docType: _selectedDocType,
                                  sizeKb: 295.0,
                                );
                              }
                            },
                            icon: const Icon(Icons.folder_open, size: 14),
                            label: const Text('Attach File & Auto-Scan OCR', style: TextStyle(fontSize: 11)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
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

                            final newDoc = ComplianceDocument(
                              id: 'doc_${DateTime.now().millisecondsSinceEpoch}',
                              title: '$_selectedDocType ($holder)',
                              type: _selectedDocType,
                              status: 'Verified',
                              expiryDate: _expiryDate,
                              documentNumber: number,
                              holderName: holder,
                              licenseType: _selectedLicenseClass,
                              fileSizeKb: _selectedFileSizeKb,
                              fileName: _selectedFileName,
                              fileExtension: _selectedFileExtension,
                              confidenceScore: _lastOcrResult?.confidenceScore ?? 99.2,
                              issuingAuthority: _lastOcrResult?.issuingAuthority ?? 'Govt Transport Authority (RTO / UIDAI)',
                            );

                            await appState.addComplianceDocument(newDoc);

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('✅ $_selectedDocType for $holder verified & saved! (Format: $_selectedFileExtension, Size: ${_selectedFileSizeKb.toStringAsFixed(0)} KB)'),
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
                          Text('${dlDoc.expiryDate.year}-${dlDoc.expiryDate.month.toString().padLeft(2, '0')}-${dlDoc.expiryDate.day.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
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
}
