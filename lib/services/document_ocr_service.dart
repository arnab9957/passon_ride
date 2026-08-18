import 'dart:math';

class OcrExtractionResult {
  final String docType;
  final String holderName;
  final String documentNumber;
  final DateTime expiryDate;
  final String licenseClass;
  final String dob;
  final String issuingAuthority;
  final double confidenceScore;
  final String rawText;
  final String fileName;
  final double fileSizeKb;

  OcrExtractionResult({
    required this.docType,
    required this.holderName,
    required this.documentNumber,
    required this.expiryDate,
    required this.licenseClass,
    this.dob = '1996-05-14',
    required this.issuingAuthority,
    required this.confidenceScore,
    required this.rawText,
    required this.fileName,
    required this.fileSizeKb,
  });
}

class DocumentOcrService {
  /// Analyzes an uploaded document file name / content or image bytes and performs OCR text parsing
  static Future<OcrExtractionResult> processDocument({
    required String fileName,
    required String selectedDocType,
    double fileSizeKb = 285.0,
    List<int>? bytes,
  }) async {
    // Simulate smart AI OCR scanning delay
    await Future.delayed(const Duration(milliseconds: 750));

    final lowerName = fileName.toLowerCase();

    // 1. Check if user uploaded an Aadhar card file
    if (selectedDocType == 'Aadhar Card' || lowerName.contains('aadhar') || lowerName.contains('uidai')) {
      final docNum = _extractAadharNumber(fileName) ?? '5489 ${1000 + Random().nextInt(8999)} ${1000 + Random().nextInt(8999)}';
      final name = _extractNameFromFileName(fileName) ?? 'Aarav S. Varma';

      return OcrExtractionResult(
        docType: 'Aadhar Card',
        holderName: name,
        documentNumber: docNum,
        expiryDate: DateTime.now().add(const Duration(days: 3650)),
        licenseClass: 'Government Identity Card',
        dob: '1995-08-14',
        issuingAuthority: 'UIDAI - Government of India',
        confidenceScore: 98.8,
        rawText: 'GOVERNMENT OF INDIA\nUnique Identification Authority of India\nName: $name\nDOB: 14/08/1995\nVID / Aadhaar: $docNum\nAddress: H-12, Green Park, New Delhi',
        fileName: fileName,
        fileSizeKb: fileSizeKb,
      );
    }

    // 2. Check if user uploaded a Vehicle Registration (RC) file
    if (selectedDocType == 'Vehicle Registration (RC)' || lowerName.contains('rc') || lowerName.contains('registration')) {
      final rcNum = 'KA-01-MJ-${2020 + Random().nextInt(5)}';
      final name = _extractNameFromFileName(fileName) ?? 'Aarav S. Varma';

      return OcrExtractionResult(
        docType: 'Vehicle Registration (RC)',
        holderName: name,
        documentNumber: rcNum,
        expiryDate: DateTime.now().add(const Duration(days: 2500)),
        licenseClass: 'Motor Vehicle Registration',
        dob: 'N/A',
        issuingAuthority: 'Regional Transport Office (RTO KA-01)',
        confidenceScore: 97.6,
        rawText: 'FORM 23 - CERTIFICATE OF REGISTRATION\nReg No: $rcNum\nOwner Name: $name\nVehicle Class: Light Motor Vehicle (Private)\nChassis No: MA3EWD21S00${Random().nextInt(99999)}\nValid Till: 2038-04-12',
        fileName: fileName,
        fileSizeKb: fileSizeKb,
      );
    }

    // 3. Default: Driving License Extraction
    final dlNum = _extractDlNumber(fileName) ?? 'DL-142023${1000000 + Random().nextInt(8999999)}';
    final name = _extractNameFromFileName(fileName) ?? 'Aarav S. Varma';
    final licenseClass = _extractLicenseClass(fileName) ?? 'LMV & MCWG (Cars & Motorcycles)';
    final expDays = 2500 + Random().nextInt(1500);

    return OcrExtractionResult(
      docType: 'Driving License',
      holderName: name,
      documentNumber: dlNum,
      expiryDate: DateTime.now().add(Duration(days: expDays)),
      licenseClass: licenseClass,
      dob: '1996-05-14',
      issuingAuthority: 'Ministry of Road Transport & Highways (MoRTH)',
      confidenceScore: 99.2,
      rawText: 'UNION OF INDIA - DRIVING LICENSE\nLicence No: $dlNum\nName: $name\nS/D/W of: Rajesh Varma\nDOB: 14-05-1996\nAuthorised to Drive: LMV, MCWG\nValid Till: ${DateTime.now().year + 8}-09-24',
      fileName: fileName,
      fileSizeKb: fileSizeKb,
    );
  }

  /// Preset sample documents for quick 1-tap test scans
  static OcrExtractionResult getPresetSample(String docType) {
    if (docType == 'Aadhar Card') {
      return OcrExtractionResult(
        docType: 'Aadhar Card',
        holderName: 'Vikramaditya Roy',
        documentNumber: '6742 8819 0431',
        expiryDate: DateTime.now().add(const Duration(days: 3650)),
        licenseClass: 'Government Identity Card',
        dob: '1994-11-20',
        issuingAuthority: 'UIDAI - Government of India',
        confidenceScore: 99.5,
        rawText: 'GOVERNMENT OF INDIA\nUnique Identification Authority of India\nName: Vikramaditya Roy\nDOB: 20/11/1994\nGender: MALE\nAadhaar: 6742 8819 0431',
        fileName: 'aadhar_card_front_back_scan.jpg',
        fileSizeKb: 310.0,
      );
    } else if (docType == 'Vehicle Registration (RC)') {
      return OcrExtractionResult(
        docType: 'Vehicle Registration (RC)',
        holderName: 'Priya Sharma',
        documentNumber: 'MH-12-PQ-9082',
        expiryDate: DateTime.now().add(const Duration(days: 4100)),
        licenseClass: 'Motor Vehicle Registration',
        dob: 'N/A',
        issuingAuthority: 'RTO Maharashtra (MH-12 Pune)',
        confidenceScore: 98.4,
        rawText: 'STATE TRANSPORT AUTHORITY MAHARASHTRA\nCertificate of Vehicle Registration\nReg No: MH-12-PQ-9082\nOwner: Priya Sharma\nClass: LMV Sedan Petrol',
        fileName: 'rc_book_mh12.pdf',
        fileSizeKb: 275.0,
      );
    } else {
      return OcrExtractionResult(
        docType: 'Driving License',
        holderName: 'Aarav S. Varma',
        documentNumber: 'DL-1420230099812',
        expiryDate: DateTime.now().add(const Duration(days: 2840)),
        licenseClass: 'LMV & MCWG (Cars & Motorcycles)',
        dob: '1996-05-14',
        issuingAuthority: 'Delhi Transport Department (RTO DL-14)',
        confidenceScore: 99.8,
        rawText: 'INDIAN UNION DRIVING LICENCE\nLicence No: DL-1420230099812\nName: Aarav S. Varma\nCOV: LMV & MCWG\nIssue Date: 12-04-2018\nValid Till: 11-04-2038',
        fileName: 'driving_license_aarav_official.pdf',
        fileSizeKb: 345.0,
      );
    }
  }

  static String? _extractDlNumber(String text) {
    final dlRegex = RegExp(r'(DL-?\d{13}|[A-Z]{2}-?\d{2}-?\d{11}|[A-Z]{2}\d{13})', caseSensitive: false);
    final match = dlRegex.firstMatch(text);
    return match?.group(0)?.toUpperCase();
  }

  static String? _extractAadharNumber(String text) {
    final aadharRegex = RegExp(r'\d{4}\s?\d{4}\s?\d{4}');
    final match = aadharRegex.firstMatch(text);
    if (match != null) {
      final raw = match.group(0)!.replaceAll(' ', '');
      if (raw.length == 12) {
        return '${raw.substring(0, 4)} ${raw.substring(4, 8)} ${raw.substring(8, 12)}';
      }
    }
    return null;
  }

  static String? _extractNameFromFileName(String fileName) {
    final clean = fileName.replaceAll(RegExp(r'\.(pdf|jpg|jpeg|png)$', caseSensitive: false), '');
    final parts = clean.split(RegExp(r'[_ -]'));
    final validWords = parts.where((p) => p.length > 2 && !['scan', 'doc', 'dl', 'aadhar', 'license', 'card', 'front', 'back', 'pdf', 'jpg'].contains(p.toLowerCase())).toList();

    if (validWords.isNotEmpty) {
      return validWords.map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase()).join(' ');
    }
    return null;
  }

  static String? _extractLicenseClass(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('hmv') || lower.contains('heavy')) {
      return 'HMV (Heavy Commercial Vehicles)';
    } else if (lower.contains('mcwg') && lower.contains('lmv')) {
      return 'LMV & MCWG (Cars & Motorcycles)';
    } else if (lower.contains('mcwg') || lower.contains('bike') || lower.contains('motorcycle')) {
      return 'MCWG Only (Motorcycles With Gear)';
    } else if (lower.contains('scooter') || lower.contains('mcwog')) {
      return 'MCWOG Only (Scooters / Gearless)';
    } else if (lower.contains('lmv') || lower.contains('car')) {
      return 'LMV Only (Light Motor Vehicles - Cars)';
    }
    return null;
  }
}
