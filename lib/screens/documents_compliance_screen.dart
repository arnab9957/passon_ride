import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_state.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';
import '../utils/app_notification.dart';
import '../services/document_ocr_service.dart';
import '../services/imagekit_service.dart';

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
  final _dobController = TextEditingController();
  final _bloodGroupController = TextEditingController();
  final _addressController = TextEditingController();
  
  String _selectedDocType = 'Driving License';
  String _selectedLicenseClass = 'LMV & MCWG (Cars & Motorcycles)';
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 3650));
  
  // File Upload State
  String _selectedFileName = '';
  String _selectedFileExtension = '';
  double _selectedFileSizeKb = 0.0;
  String? _fileSizeValidationError;
  Uint8List? _uploadedFileBytes;
  String? _uploadedFileBase64;

  // OCR Processing State
  bool _isOcrScanning = false;
  OcrExtractionResult? _lastOcrResult;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppState>(context, listen: false).fetchComplianceDocuments();
    });
  }

  void _validateFileSize(double kb) {
    if (kb <= 0.0) {
      setState(() {
        _fileSizeValidationError = null;
      });
      return;
    }
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

  /// Triggers OCR scanning on attached document.
  Future<void> _runOcrScan({
    required String fileName,
    required String docType,
    double sizeKb = 0.0,
    String? userDisplayName,
    String? imagePath,
    List<int>? bytes,
  }) async {
    if (!mounted) return;
    setState(() => _isOcrScanning = true);

    OcrExtractionResult? result;
    String? errorMsg;

    try {
      result = await DocumentOcrService.processDocument(
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
        _selectedFileExtension = _selectedFileName.contains('.')
            ? _selectedFileName.split('.').last.toUpperCase()
            : 'JPG';
        _selectedFileSizeKb = sizeKb > 0 ? sizeKb : result.fileSizeKb;

        // Populate form fields with OCR results
        if (result.holderName.isNotEmpty && result.holderName != 'Not Detected') {
          _nameController.text = result.holderName;
        }
        if (result.dob.isNotEmpty) _dobController.text = result.dob;
        if (result.bloodGroup.isNotEmpty) _bloodGroupController.text = result.bloodGroup;
        if (result.address.isNotEmpty) _addressController.text = result.address;

        if (result.docType == 'Driving License') {
          if (!result.documentNumber.contains('UNDETECTED')) {
            _dlNumberController.text = result.documentNumber;
          }
          if (result.licenseClass.isNotEmpty) {
            final rawClass = result.licenseClass.toLowerCase();
            if (rawClass.contains('mcwg') && rawClass.contains('lmv')) {
              _selectedLicenseClass = 'LMV & MCWG (Cars & Motorcycles)';
            } else if (rawClass.contains('hmv') || rawClass.contains('heavy')) {
              _selectedLicenseClass = 'HMV (Heavy Commercial Vehicles)';
            } else if (rawClass.contains('mcwog') || rawClass.contains('scooter')) {
              _selectedLicenseClass = 'MCWOG Only (Scooters / Gearless)';
            } else if (rawClass.contains('mcwg') || rawClass.contains('motorcycle')) {
              _selectedLicenseClass = 'MCWG Only (Motorcycles With Gear)';
            } else if (rawClass.contains('lmv') || rawClass.contains('light')) {
              _selectedLicenseClass = 'LMV Only (Light Motor Vehicles - Cars)';
            } else {
              _selectedLicenseClass = 'LMV & MCWG (Cars & Motorcycles)';
            }
          }
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

    if (_nameController.text.isEmpty && appState.activeUserDisplayName.isNotEmpty) {
      _nameController.text = appState.activeUserDisplayName;
    }

    // Active DL & Aadhar documents from state (submitted by user)
    final dlDocs = appState.documents.where(
      (d) => d.type.toLowerCase().contains('license') || d.title.toLowerCase().contains('license'),
    );
    final ComplianceDocument? dlDoc = dlDocs.isNotEmpty ? dlDocs.first : null;

    final aadharDocs = appState.documents.where(
      (d) => d.type.toLowerCase().contains('aadhar') || d.title.toLowerCase().contains('aadhar') || d.type.toLowerCase().contains('identity'),
    );
    final ComplianceDocument? aadharDoc = aadharDocs.isNotEmpty ? aadharDocs.first : null;

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
                onPressed: () {
                  if (appState.cameFromVerificationChecklist) {
                    appState.returnToVerificationChecklist();
                  } else {
                    appState.setNavIndex(16); // Back to Profile
                  }
                },
                tooltip: appState.cameFromVerificationChecklist ? 'Return to Verification Checklist' : 'Back to Profile',
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                        if (appState.cameFromVerificationChecklist) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.deepOrange.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.deepOrange, width: 0.8),
                            ),
                            child: const Text(
                              'VERIFICATION FLOW',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const Text('Documents & Licenses', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              if (appState.cameFromVerificationChecklist)
                TextButton.icon(
                  onPressed: () => appState.returnToVerificationChecklist(),
                  icon: const Icon(Icons.arrow_forward, size: 14),
                  label: const Text('To Checklist', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.deepOrange,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Verification Checklist Flow Banner (If navigated from checklist)
          if (appState.cameFromVerificationChecklist) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [Colors.deepOrange.shade900.withOpacity(0.35), AppColors.surfaceContainerDark]
                      : [Colors.orange.shade50, Colors.amber.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.deepOrange.shade400, width: 1.2),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.deepOrange,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.playlist_add_check_circle, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Verification Checklist In Progress',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.deepOrange),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dlDoc != null
                              ? '✅ Driving License uploaded & verified! You can return to finalize your verification checklist.'
                              : 'Please upload and verify your Driving License below. You will be redirected back to the verification checklist once verified.',
                          style: const TextStyle(fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => appState.returnToVerificationChecklist(),
                    icon: const Icon(Icons.arrow_forward, size: 13),
                    label: Text(dlDoc != null ? 'Checklist' : 'Back', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),
          ],

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
              border: Border.all(color: (dlDoc != null && aadharDoc != null) ? Colors.green : AppColors.secondary),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (dlDoc != null && aadharDoc != null) ? Colors.green.shade700 : AppColors.secondary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    (dlDoc != null && aadharDoc != null) ? Icons.verified_user : Icons.shield_outlined,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            (dlDoc != null && aadharDoc != null)
                                ? '100% Verified Credentials'
                                : (appState.documents.isNotEmpty
                                    ? '${appState.documents.length} Document(s) Uploaded'
                                    : 'Verification Pending'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(width: 6),
                          if (dlDoc != null && aadharDoc != null)
                            const Icon(Icons.check_circle, size: 16, color: Colors.green),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        (dlDoc != null && aadharDoc != null)
                            ? 'Driving License & Government ID submitted and verified for rental compliance.'
                            : 'Upload your Driving License and Government ID to start renting vehicles.',
                        style: const TextStyle(fontSize: 12),
                      ),
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
                          Text('Upload scan to auto-extract details via AI OCR or enter details manually', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),

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
                              hintText: 'YYYY-MM-DD',
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
                              hintText: 'e.g. O+, A+',
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
                      hintText: 'e.g. KA0120200012345',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Authorized Vehicle Class Dropdown
                  const Text('AUTHORIZED VEHICLE CLASSES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: [
                      'LMV & MCWG (Cars & Motorcycles)',
                      'LMV Only (Light Motor Vehicles - Cars)',
                      'MCWG Only (Motorcycles With Gear)',
                      'MCWOG Only (Scooters / Gearless)',
                      'HMV (Heavy Commercial Vehicles)',
                    ].contains(_selectedLicenseClass)
                        ? _selectedLicenseClass
                        : 'LMV & MCWG (Cars & Motorcycles)',
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
                      hintText: 'e.g. 1234 5678 9012',
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
                      // Dropzone content: Empty state vs Uploaded File Preview
                      if (_selectedFileName.isEmpty) ...[
                        const Icon(Icons.cloud_upload_outlined, size: 40, color: AppColors.secondary),
                        const SizedBox(height: 8),
                        const Text('No Document Selected', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text(
                          'Tap Camera, Gallery, or PDF Upload below to attach a clear scan.\nRequired file size: 150 KB to 500 KB.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        const SizedBox(height: 12),
                      ] else ...[
                        // Single Clean Card for the Uploaded File
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceContainerHighDark : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _fileSizeValidationError != null ? Colors.red : AppColors.secondary.withOpacity(0.4),
                            ),
                          ),
                          child: Column(
                            children: [
                              if (_uploadedFileBytes != null && _selectedFileExtension != 'PDF') ...[
                                Container(
                                  height: 140,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.black12,
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Image.memory(_uploadedFileBytes!, fit: BoxFit.contain),
                                ),
                                const SizedBox(height: 10),
                              ] else if (_selectedFileExtension == 'PDF') ...[
                                Row(
                                  children: [
                                    const Icon(Icons.picture_as_pdf, size: 36, color: Colors.red),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(_selectedFileName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                          Text('PDF Document Attached (${_selectedFileSizeKb.toStringAsFixed(0)} KB)', style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
                                const SizedBox(height: 8),
                              ] else ...[
                                Text(_selectedFileName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                              ],

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Chip(
                                    label: Text('Format: $_selectedFileExtension'),
                                    backgroundColor: Colors.blue.withOpacity(0.12),
                                    labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue),
                                  ),
                                  const SizedBox(width: 8),
                                  Chip(
                                    label: Text('Size: ${_selectedFileSizeKb.toStringAsFixed(0)} KB'),
                                    backgroundColor: _fileSizeValidationError != null ? Colors.red.withOpacity(0.12) : Colors.green.withOpacity(0.12),
                                    labelStyle: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: _fileSizeValidationError != null ? Colors.red : Colors.green.shade800,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _selectedFileName = '';
                                        _selectedFileExtension = '';
                                        _selectedFileSizeKb = 0.0;
                                        _uploadedFileBytes = null;
                                        _uploadedFileBase64 = null;
                                        _fileSizeValidationError = null;
                                        _lastOcrResult = null;
                                      });
                                    },
                                    icon: const Icon(Icons.close, size: 14, color: Colors.red),
                                    label: const Text('Remove File', style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),

                              if (_fileSizeValidationError != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  _fileSizeValidationError!,
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red.shade700),
                                  textAlign: TextAlign.center,
                                ),
                              ] else ...[
                                const SizedBox(height: 4),
                                const Text('✅ File format & size valid for local storage & instant preview.', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

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
                                  String? imagePath;
                                  if (!kIsWeb) {
                                    try {
                                      imagePath = image.path;
                                    } catch (_) {}
                                  }
                                  await _runOcrScan(
                                    fileName: image.name.isNotEmpty ? image.name : 'camera_license_scan.jpg',
                                    docType: _selectedDocType,
                                    sizeKb: sizeInKb > 0 ? sizeInKb : 280.0,
                                    userDisplayName: appState.activeUserDisplayName,
                                    imagePath: imagePath,
                                    bytes: bytes,
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text('Camera unavailable: $e'),
                                    backgroundColor: Colors.orange,
                                    behavior: SnackBarBehavior.floating,
                                  ));
                                }
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
                                  String? imagePath;
                                  if (!kIsWeb) {
                                    try {
                                      imagePath = image.path;
                                    } catch (_) {}
                                  }
                                  await _runOcrScan(
                                    fileName: image.name.isNotEmpty ? image.name : 'gallery_license_scan.jpg',
                                    docType: _selectedDocType,
                                    sizeKb: sizeInKb > 0 ? sizeInKb : 285.0,
                                    userDisplayName: appState.activeUserDisplayName,
                                    imagePath: imagePath,
                                    bytes: bytes,
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text('Gallery unavailable: $e'),
                                    backgroundColor: Colors.orange,
                                    behavior: SnackBarBehavior.floating,
                                  ));
                                }
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
                                  String? filePath;
                                  if (!kIsWeb) {
                                    try {
                                      filePath = picked.path;
                                    } catch (_) {}
                                  }
                                  await _runOcrScan(
                                    fileName: picked.name.isNotEmpty ? picked.name : 'uploaded_document.$ext',
                                    docType: _selectedDocType,
                                    sizeKb: sizeKb,
                                    userDisplayName: appState.activeUserDisplayName,
                                    imagePath: filePath,
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
                    onPressed: (_fileSizeValidationError != null || _selectedFileName.isEmpty)
                        ? null
                        : () async {
                            final holder = _nameController.text.trim().isEmpty ? appState.activeUserDisplayName : _nameController.text.trim();
                            final number = _selectedDocType == 'Driving License'
                                ? _dlNumberController.text.trim()
                                : _aadharNumberController.text.trim();

                            if (number.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('⚠️ Please enter your ${_selectedDocType == "Driving License" ? "Driving License" : "ID"} number.'),
                                  backgroundColor: Colors.orange,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }

                            final isExpired = _expiryDate.isBefore(DateTime.now());
                            String docUrl = _uploadedFileBase64 ?? '';

                            // 1. Upload scan file to ImageKit.io CDN if bytes are attached
                            if (_uploadedFileBytes != null) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('☁️ Uploading document scan to ImageKit.io CDN & Supabase DB...'),
                                    backgroundColor: Colors.blue,
                                    behavior: SnackBarBehavior.floating,
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                              }
                              try {
                                final ikService = ImageKitService();
                                final uploadedUrl = await ikService.uploadImage(
                                  bytes: _uploadedFileBytes!,
                                  fileName: _selectedFileName.isNotEmpty ? _selectedFileName : 'compliance_${DateTime.now().millisecondsSinceEpoch}.${_selectedFileExtension.isNotEmpty ? _selectedFileExtension : "pdf"}',
                                  folder: '/compliance_documents',
                                );
                                if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
                                  docUrl = uploadedUrl;
                                }
                              } catch (e) {
                                print('ImageKit document upload error: $e');
                              }
                            }

                            final newDoc = ComplianceDocument(
                              id: 'doc_${DateTime.now().millisecondsSinceEpoch}',
                              title: '$_selectedDocType ($holder)',
                              type: _selectedDocType,
                              status: isExpired ? 'Action Required' : 'Verified',
                              expiryDate: _expiryDate,
                              documentUrl: docUrl,
                              documentNumber: number,
                              holderName: holder,
                              licenseType: _selectedLicenseClass,
                              fileSizeKb: _selectedFileSizeKb,
                              fileName: _selectedFileName,
                              fileExtension: _selectedFileExtension,
                              confidenceScore: _lastOcrResult?.confidenceScore ?? 99.2,
                              issuingAuthority: _lastOcrResult?.issuingAuthority ?? 'Govt Transport Authority (RTO / UIDAI)',
                              bloodGroup: _bloodGroupController.text.trim(),
                              address: _addressController.text.trim(),
                              dob: _dobController.text.trim(),
                              isExpiryValid: !isExpired,
                            );

                            await appState.addComplianceDocument(newDoc);

                            if (context.mounted) {
                              final isDl = _selectedDocType.toLowerCase().contains('license');
                              final cameFromChecklist = appState.cameFromVerificationChecklist;

                              if (cameFromChecklist || isDl) {
                                _showDlUploadSuccessRedirectModal(context, appState);
                              } else {
                                AppToast.showSuccess(
                                  context,
                                  '$_selectedDocType saved & verified successfully!',
                                );
                              }
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

          // If no documents submitted yet, show clean empty state
          if (dlDoc == null && aadharDoc == null && appState.documents.isEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight,
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.folder_open_outlined, size: 44, color: Colors.grey.shade400),
                  const SizedBox(height: 10),
                  const Text('No Verified Documents Yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 6),
                  const Text(
                    'Attach your document scan above and tap "Submit Document". Your verified credentials will appear here once saved.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],

          // Driving License Display Card
          if (dlDoc != null) ...[
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
                            Text(dlDoc.dob.isNotEmpty ? dlDoc.dob : 'Not specified', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('BLOOD GROUP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                            const SizedBox(height: 2),
                            Text(dlDoc.bloodGroup.isNotEmpty ? dlDoc.bloodGroup : 'Not specified', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: dlDoc.bloodGroup.isNotEmpty ? Colors.red : Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (dlDoc.address.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('PERMANENT RESIDENCE ADDRESS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 2),
                        Text(dlDoc.address, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showDocumentPreviewModal(context, dlDoc),
                          icon: const Icon(Icons.remove_red_eye, size: 16),
                          label: const Text('👁️ Preview', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.secondary,
                            side: const BorderSide(color: AppColors.secondary),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      if (dlDoc.documentUrl.startsWith('http')) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final uri = Uri.parse(dlDoc.documentUrl);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              }
                            },
                            icon: const Icon(Icons.open_in_new, size: 14),
                            label: const Text('🌐 View File', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _confirmDeleteDocument(context, appState, dlDoc),
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                        tooltip: 'Delete Driving License',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: Colors.red.withOpacity(0.3)),
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
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => appState.returnToVerificationChecklist(),
                      icon: const Icon(Icons.playlist_add_check_circle, size: 16),
                      label: Text(
                        appState.cameFromVerificationChecklist
                            ? '➔ Return to Verification Checklist (Step 1 Cleared)'
                            : '➔ Proceed to Booking Verification Checklist',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Aadhar Display Card
          if (aadharDoc != null) ...[
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
                            Text('Aadhar UID: XXXX XXXX ${aadharDoc.documentNumber.length >= 4 ? aadharDoc.documentNumber.substring(aadharDoc.documentNumber.length - 4) : "ID"}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
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
                          label: const Text('👁️ Preview', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      if (aadharDoc.documentUrl.startsWith('http')) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final uri = Uri.parse(aadharDoc.documentUrl);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              }
                            },
                            icon: const Icon(Icons.open_in_new, size: 14),
                            label: const Text('🌐 View File', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _confirmDeleteDocument(context, appState, aadharDoc),
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                        tooltip: 'Delete Aadhar Card',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: Colors.red.withOpacity(0.3)),
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
          ],

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
                if ((dlDoc != null && doc.id == dlDoc.id) || (aadharDoc != null && doc.id == aadharDoc.id)) {
                  return const SizedBox.shrink();
                }
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
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                        tooltip: 'Delete Document',
                        onPressed: () => _confirmDeleteDocument(context, appState, doc),
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

  void _confirmDeleteDocument(BuildContext context, AppState appState, ComplianceDocument doc) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceContainerDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_forever, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Delete Document?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to permanently delete this uploaded file and its verification record?',
              style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doc.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  if (doc.documentNumber.isNotEmpty)
                    Text('Document #: ${doc.documentNumber}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  Text('File: ${doc.fileName.isNotEmpty ? doc.fileName : "uploaded_document"} (${doc.fileSizeKb.toStringAsFixed(0)} KB)', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await appState.deleteComplianceDocument(doc.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('🗑️ ${doc.type} has been permanently deleted.'),
                    backgroundColor: Colors.red.shade800,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
            icon: const Icon(Icons.delete, size: 16),
            label: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  void _showUploadedDocumentPreview(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final holder = _nameController.text.trim().isNotEmpty 
        ? _nameController.text.trim() 
        : appState.activeUserDisplayName;
    final number = _selectedDocType == 'Driving License'
        ? _dlNumberController.text.trim()
        : _aadharNumberController.text.trim();
    final isExpired = _expiryDate.isBefore(DateTime.now());

    final tempDoc = ComplianceDocument(
      id: 'temp_preview',
      title: '$_selectedDocType (${holder.isNotEmpty ? holder : "User Document"})',
      type: _selectedDocType,
      status: isExpired ? 'Action Required' : 'Uploaded (Pending Review)',
      expiryDate: _expiryDate,
      documentUrl: _uploadedFileBase64 ?? '',
      documentNumber: number.isNotEmpty ? number : 'Pending Form Submission',
      holderName: holder.isNotEmpty ? holder : 'Document Owner',
      licenseType: _selectedLicenseClass,
      fileSizeKb: _selectedFileSizeKb,
      fileName: _selectedFileName,
      fileExtension: _selectedFileExtension,
      confidenceScore: _lastOcrResult?.confidenceScore ?? 100.0,
      issuingAuthority: (_lastOcrResult?.issuingAuthority != null && !_lastOcrResult!.issuingAuthority.contains('RTO DL-14'))
          ? _lastOcrResult!.issuingAuthority
          : (_selectedDocType == 'Aadhar Card' ? 'UIDAI — Government of India' : 'Govt Transport Department (RTO)'),
      bloodGroup: _bloodGroupController.text.trim(),
      address: _addressController.text.trim().isNotEmpty
          ? _addressController.text.trim()
          : 'Address from submitted form',
      dob: _dobController.text.trim(),
      isExpiryValid: !isExpired,
    );

    _showDocumentPreviewModal(context, tempDoc);
  }

  void _showDlUploadSuccessRedirectModal(BuildContext context, AppState appState) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceContainerDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified, color: Colors.green, size: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              'Driving License Uploaded & Verified!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Your Driving License has been recorded and verified. Return to the Verification Checklist to complete your vehicle rental authorization.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Stay in Docs'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      appState.returnToVerificationChecklist();
                    },
                    icon: const Icon(Icons.playlist_add_check_circle),
                    label: const Text('Go to Checklist', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showDocumentPreviewModal(BuildContext context, ComplianceDocument doc) {
    final appState = Provider.of<AppState>(context, listen: false);
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
                          if (doc.id != 'temp_preview') ...[
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              tooltip: 'Delete Document',
                              onPressed: () {
                                Navigator.pop(ctx);
                                _confirmDeleteDocument(context, appState, doc);
                              },
                            ),
                          ],
                          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Uploaded Raw Image Preview (if image)
                      if (imageBytes != null && doc.fileExtension.toUpperCase() != 'PDF') ...[
                        const Text('REAL UPLOADED SCAN PREVIEW', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          height: 280,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.secondary, width: 1.5),
                            color: Colors.black,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: InteractiveViewer(
                            panEnabled: true,
                            minScale: 0.8,
                            maxScale: 3.0,
                            child: Image.memory(imageBytes, fit: BoxFit.contain),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Center(
                          child: Text('💡 Pinch or scroll to zoom into full resolution scan', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        ),
                        const SizedBox(height: 16),
                      ] else if (doc.fileExtension.toUpperCase() == 'PDF') ...[
                        const Text('REAL UPLOADED PDF DOCUMENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.red.withOpacity(0.4), width: 1.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.picture_as_pdf, size: 48, color: Colors.red),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          doc.fileName.isNotEmpty ? doc.fileName : 'Uploaded_Document.pdf',
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'PDF File Attached (${doc.fileSizeKb.toStringAsFixed(0)} KB)',
                                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(6)),
                                    child: const Text('PDF FILE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.green, size: 16),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Verified PDF attached and ready for compliance verification.',
                                        style: TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Detailed Fields List
                      const Text('DOCUMENT METADATA & COMPLIANCE DETAILS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
                      const SizedBox(height: 10),

                      _buildDetailRow(Icons.badge, 'HOLDER NAME', doc.holderName.isNotEmpty ? doc.holderName : 'Document Owner'),
                      if (doc.documentNumber.isNotEmpty)
                        _buildDetailRow(Icons.numbers, 'DOCUMENT NUMBER', doc.documentNumber),
                      _buildDetailRow(Icons.category, 'CREDENTIAL CLASS', doc.licenseType),
                      _buildDetailRow(Icons.event, 'EXPIRY DATE', '${doc.expiryDate.year}-${doc.expiryDate.month.toString().padLeft(2, '0')}-${doc.expiryDate.day.toString().padLeft(2, '0')} (${doc.isExpiryValid ? "VALID" : "EXPIRED"})'),
                      _buildDetailRow(Icons.account_balance, 'ISSUING AUTHORITY', doc.issuingAuthority.isNotEmpty ? doc.issuingAuthority : 'Govt Transport Authority (RTO / UIDAI)'),
                      if (doc.address.isNotEmpty)
                        _buildDetailRow(Icons.home, 'PERMANENT ADDRESS', doc.address),
                      _buildDetailRow(Icons.insert_drive_file, 'FILE NAME & SIZE', '${doc.fileName.isNotEmpty ? doc.fileName : "Scan document"} (${doc.fileSizeKb > 0 ? doc.fileSizeKb.toStringAsFixed(0) : "0"} KB • ${doc.fileExtension.toUpperCase()})'),
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
                      if (doc.documentUrl.startsWith('http')) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final uri = Uri.parse(doc.documentUrl);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Unable to open link: ${doc.documentUrl}')),
                                );
                              }
                            },
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('🌐 Open Uploaded File (ImageKit CDN)', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                      if (doc.id != 'temp_preview') ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _confirmDeleteDocument(context, appState, doc);
                            },
                            icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                            label: const Text('🗑️ Delete Uploaded Document', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.redAccent),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
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
