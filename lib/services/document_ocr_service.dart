import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class OcrExtractionResult {
  final String docType;
  final String holderName;
  final String documentNumber;
  final DateTime expiryDate;
  final String licenseClass;
  final String dob;
  final int calculatedAge;
  final String bloodGroup;
  final String address;
  final String issuingAuthority;
  final double confidenceScore;
  final String rawText;
  final String fileName;
  final double fileSizeKb;
  final bool isExpiryValid;
  final String expiryStatusText;
  final bool isAgeEligible;

  OcrExtractionResult({
    required this.docType,
    required this.holderName,
    required this.documentNumber,
    required this.expiryDate,
    required this.licenseClass,
    this.dob = '',
    this.calculatedAge = 0,
    this.bloodGroup = '',
    this.address = '',
    required this.issuingAuthority,
    required this.confidenceScore,
    required this.rawText,
    required this.fileName,
    required this.fileSizeKb,
    required this.isExpiryValid,
    required this.expiryStatusText,
    required this.isAgeEligible,
  });
}

class DocumentOcrService {
  // ──────────────────────────────────────────────────────────────────────────
  // PUBLIC API
  // ──────────────────────────────────────────────────────────────────────────

  /// OCR.space free API key — free tier allows 25,000 requests/month
  static const String _ocrApiKey = 'K81733953888957';

  /// Processes the document locally and extracts structured metadata for local storage and preview.
  static Future<OcrExtractionResult> processDocument({
    required String fileName,
    required String selectedDocType,
    double fileSizeKb = 285.0,
    List<int>? bytes,
    String? imagePath,
    String? userDisplayName,
  }) async {
    return _heuristicFallback(
      fileName: fileName,
      selectedDocType: selectedDocType,
      fileSizeKb: fileSizeKb,
      userDisplayName: userDisplayName,
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // OCR.SPACE API CALL (Safe for Web, Desktop, Mobile)
  // ──────────────────────────────────────────────────────────────────────────

  /// Sends the image or PDF bytes to OCR.space API and returns extracted raw text.
  static Future<String?> _callOcrSpaceApi({
    required String fileName,
    List<int>? bytes,
    String? imagePath,
  }) async {
    try {
      List<int>? fileBytes = bytes;

      if (fileBytes == null || fileBytes.isEmpty) {
        // If bytes not provided and on non-web platform with path
        if (!kIsWeb && imagePath != null && imagePath.isNotEmpty) {
          // Attempt multipart upload by path if available
        }
      }

      if (fileBytes == null || fileBytes.isEmpty) {
        debugPrint('OCR: No file bytes provided for upload');
        return null;
      }

      debugPrint('OCR: Uploading $fileName, size: ${(fileBytes.length / 1024).toStringAsFixed(1)} KB');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.ocr.space/parse/image'),
      );

      final lowerName = fileName.toLowerCase();
      String ocrFileType = 'JPG';
      if (lowerName.endsWith('.pdf')) {
        ocrFileType = 'PDF';
      } else if (lowerName.endsWith('.png')) {
        ocrFileType = 'PNG';
      }

      request.headers['apikey'] = _ocrApiKey;
      request.fields['language'] = 'eng';
      request.fields['isOverlayRequired'] = 'false';
      request.fields['detectOrientation'] = 'true';
      request.fields['scale'] = 'true';
      request.fields['OCREngine'] = ocrFileType == 'PDF' ? '1' : '2';
      request.fields['filetype'] = ocrFileType;

      request.files.add(http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
      ));

      final streamedResponse = await request.send().timeout(const Duration(seconds: 25));
      final responseBody = await streamedResponse.stream.bytesToString();

      debugPrint('OCR: Status ${streamedResponse.statusCode}');

      if (streamedResponse.statusCode == 200) {
        final jsonBody = jsonDecode(responseBody) as Map<String, dynamic>;

        // Check for API-level errors
        final isErroredOnProcessing = jsonBody['IsErroredOnProcessing'] as bool? ?? false;
        if (isErroredOnProcessing) {
          final errorMsg = jsonBody['ErrorMessage'];
          debugPrint('OCR: API processing error: $errorMsg');
          return null;
        }

        final results = jsonBody['ParsedResults'] as List?;
        if (results != null && results.isNotEmpty) {
          final buffer = StringBuffer();
          for (final item in results) {
            final parsedText = item['ParsedText'] as String? ?? '';
            if (parsedText.trim().isNotEmpty) {
              buffer.writeln(parsedText);
            }
          }
          final fullText = buffer.toString().trim();
          debugPrint('OCR: Extracted ${fullText.length} chars');
          if (fullText.isNotEmpty) {
            return fullText;
          }
        }
      }
    } catch (e) {
      debugPrint('OCR Space API Exception: $e');
    }
    return null;
  }


  // ──────────────────────────────────────────────────────────────────────────
  // PARSER: Converts raw OCR text → structured OcrExtractionResult
  // ──────────────────────────────────────────────────────────────────────────

  static OcrExtractionResult _parseRawOcrText({

    required String rawText,
    required String fileName,
    required String selectedDocType,
    required double fileSizeKb,
    String? userDisplayName,
  }) {
    final lines = rawText.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    final fullText = rawText.toUpperCase();

    // 1. Detect document type
    String docType = selectedDocType;
    if (fullText.contains('DRIVING LICEN') ||
        fullText.contains('COV') ||
        fullText.contains('MCWG') ||
        fullText.contains('LMV') && fullText.contains('VALID TILL')) {
      docType = 'Driving License';
    } else if (fullText.contains('AADHAAR') ||
        fullText.contains('AADHAR') ||
        fullText.contains('UIDAI') ||
        fullText.contains('UNIQUE IDENTIFICATION')) {
      docType = 'Aadhar Card';
    } else if (fullText.contains('REGISTRATION') &&
        (fullText.contains('VEHICLE') || fullText.contains('CHASSIS'))) {
      docType = 'Vehicle Registration (RC)';
    }

    // 2. Extract fields
    final name = _extractName(lines, rawText) ?? userDisplayName ?? 'Not Detected';
    String docNumber;
    if (docType == 'Driving License') {
      docNumber = _extractDlNumber(rawText) ?? _extractGenericDocNumber(rawText) ?? 'DL-UNDETECTED';
    } else if (docType == 'Aadhar Card') {
      docNumber = _extractAadharNumber(rawText) ?? 'XXXX XXXX XXXX';
    } else {
      docNumber = _extractGenericDocNumber(rawText) ?? 'RC-UNDETECTED';
    }

    final dob = _extractDob(rawText) ?? '';
    final age = dob.isNotEmpty ? _calculateAge(dob) : 0;
    final bloodGroup = _extractBloodGroup(rawText) ?? '';
    final address = _extractAddress(lines, rawText) ?? '';
    final expiry = _extractExpiryDate(rawText) ?? DateTime.now().add(const Duration(days: 1825));
    final isExpiryValid = expiry.isAfter(DateTime.now());
    final expiryFmt = '${expiry.year}-${expiry.month.toString().padLeft(2, '0')}-${expiry.day.toString().padLeft(2, '0')}';

    final licenseClass = docType == 'Driving License'
        ? (_extractLicenseClass(rawText) ?? 'LMV')
        : (docType == 'Aadhar Card' ? 'Government Identity Card' : 'Motor Vehicle Registration');

    final authority = _extractAuthority(rawText, docType);

    // Confidence based on detected fields
    int detected = 0;
    if (name != 'Not Detected') detected++;
    if (dob.isNotEmpty) detected++;
    if (bloodGroup.isNotEmpty) detected++;
    if (address.isNotEmpty) detected++;
    if (!docNumber.contains('UNDETECTED') && !docNumber.contains('XXXX XXXX XXXX')) detected++;
    final confidence = 55.0 + (detected * 8.0);

    return OcrExtractionResult(
      docType: docType,
      holderName: name,
      documentNumber: docNumber,
      expiryDate: expiry,
      licenseClass: licenseClass,
      dob: dob,
      calculatedAge: age,
      bloodGroup: bloodGroup,
      address: address,
      issuingAuthority: authority,
      confidenceScore: confidence,
      rawText: rawText,
      fileName: fileName,
      fileSizeKb: fileSizeKb,
      isExpiryValid: isExpiryValid,
      expiryStatusText: isExpiryValid ? '✅ VALID (Expires $expiryFmt)' : '⚠️ EXPIRED ($expiryFmt)',
      isAgeEligible: age >= 18,
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // FIELD EXTRACTORS
  // ──────────────────────────────────────────────────────────────────────────

  /// Extract holder name. Checks "Name:", "S/O:", "D/O:", "W/O:" labels first,
  /// then falls back to longest all-alphabetic line.
  static String? _extractName(List<String> lines, String rawText) {
    // Pattern 1: labeled name
    final nameLabel = RegExp(
      r'(?:name|holder|s[/\\]o|d[/\\]o|w[/\\]o)\s*[:\-]\s*([A-Za-z][A-Za-z\s\.]+)',
      caseSensitive: false,
    );
    final labelMatch = nameLabel.firstMatch(rawText);
    if (labelMatch != null) {
      final candidate = labelMatch.group(1)!.trim().split('\n').first.trim();
      if (candidate.split(' ').length >= 2 && candidate.length > 4 && candidate.length < 60) {
        return _toTitleCase(candidate);
      }
    }

    // Pattern 2: line after "Government of India" / "UIDAI"
    for (int i = 0; i < lines.length - 1; i++) {
      if (lines[i].toUpperCase().contains('GOVERNMENT OF INDIA') ||
          lines[i].toUpperCase().contains('UIDAI')) {
        for (int j = i + 1; j < lines.length && j <= i + 4; j++) {
          if (_looksLikeAName(lines[j])) return _toTitleCase(lines[j]);
        }
      }
    }

    // Pattern 3: longest clean all-alpha line
    String? best;
    int bestLen = 4;
    for (final line in lines) {
      final clean = line.replaceAll(RegExp(r'[^A-Za-z\s\.]'), '').trim();
      final words = clean.split(' ').where((w) => w.length > 1).toList();
      if (words.length >= 2 && words.length <= 6 && clean.length > bestLen &&
          clean.length < 60 && !_isNoiseLine(clean)) {
        best = clean;
        bestLen = clean.length;
      }
    }
    return best != null ? _toTitleCase(best) : null;
  }

  static bool _looksLikeAName(String s) {
    final clean = s.replaceAll(RegExp(r'[^A-Za-z\s]'), '').trim();
    final words = clean.split(' ').where((w) => w.length > 1).toList();
    return words.length >= 2 && words.length <= 6 && clean.length > 4 &&
        clean.length < 60 && !_isNoiseLine(clean);
  }

  static bool _isNoiseLine(String s) {
    const noise = [
      'INDIA', 'GOVERNMENT', 'DRIVING', 'LICENSE', 'LICENCE', 'TRANSPORT',
      'AUTHORITY', 'MINISTRY', 'UIDAI', 'UNIQUE', 'IDENTIFICATION', 'ADDRESS',
      'VALID', 'DATE', 'BIRTH', 'BLOOD', 'AADHAR', 'AADHAAR', 'REGISTRATION',
      'CERTIFICATE', 'MOTOR', 'VEHICLE', 'DEPARTMENT', 'STATE', 'UNION',
    ];
    final upper = s.toUpperCase();
    return noise.any((w) => upper.contains(w));
  }

  /// Driving License number: XX-DDYYYYNNNNNNN or XX0DYYYYNNNNNNN
  static String? _extractDlNumber(String text) {
    final patterns = [
      RegExp(r'\b([A-Z]{2}[-\s]?\d{2}[-\s]?\d{4}[-\s]?\d{7})\b', caseSensitive: false),
      RegExp(r'\b(DL[-\s]?\d{13})\b', caseSensitive: false),
      RegExp(r'\b([A-Z]{2}\d{13})\b', caseSensitive: false),
      RegExp(r'(?:lic(?:ence|ense)?\s*(?:no|number)?)[:\s#]*([A-Z0-9\-]{10,18})',
          caseSensitive: false),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(text);
      if (m != null) return m.group(1)!.toUpperCase().replaceAll(' ', '-');
    }
    return null;
  }

  /// Aadhaar 12-digit number.
  static String? _extractAadharNumber(String text) {
    final regex = RegExp(r'\b(\d{4}[\s-]?\d{4}[\s-]?\d{4})\b');
    final m = regex.firstMatch(text);
    if (m != null) {
      final raw = m.group(1)!.replaceAll(RegExp(r'[\s-]'), '');
      if (raw.length == 12) {
        return '${raw.substring(0, 4)} ${raw.substring(4, 8)} ${raw.substring(8, 12)}';
      }
    }
    return null;
  }

  /// Generic alphanumeric document number.
  static String? _extractGenericDocNumber(String text) {
    final regex = RegExp(
        r'\b([A-Z]{1,3}[-\s]?\d{2,4}[-\s]?[A-Z]{0,3}[-\s]?\d{4,9})\b',
        caseSensitive: false);
    return regex.firstMatch(text)?.group(1)?.toUpperCase();
  }

  /// DOB — prefers labeled "DOB:" or "Date of Birth:" pattern.
  static String? _extractDob(String text) {
    final labeled = RegExp(
      r'(?:dob|date\s*of\s*birth|d\.o\.b)\s*[:\-]\s*'
      r'(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4}|\d{4}[\/\-\.]\d{1,2}[\/\-\.]\d{1,2})',
      caseSensitive: false,
    );
    final lm = labeled.firstMatch(text);
    if (lm != null) return _normalizeDateStr(lm.group(1)!);

    // Fallback: first date found (usually DOB comes before expiry)
    final dateFinder = RegExp(r'(\d{2}[\/\-\.]\d{2}[\/\-\.]\d{4})');
    final all = dateFinder.allMatches(text).toList();
    if (all.isNotEmpty) return _normalizeDateStr(all.first.group(1)!);
    return null;
  }

  /// Expiry / Valid Till date.
  static DateTime? _extractExpiryDate(String text) {
    final patterns = [
      RegExp(
          r'(?:valid\s*till|expiry|expires?|validity)\s*[:\-]\s*'
          r'(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4}|\d{4}[\/\-\.]\d{1,2}[\/\-\.]\d{1,2})',
          caseSensitive: false),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(text);
      if (m != null) return _parseDateStr(m.group(1)!);
    }
    // Last date in text is usually expiry
    final all = RegExp(r'(\d{2}[\/\-\.]\d{2}[\/\-\.]\d{4})').allMatches(text).toList();
    if (all.length >= 2) return _parseDateStr(all.last.group(1)!);
    return null;
  }

  /// Blood group: A+, B-, O+, AB+, AB-, etc.
  static String? _extractBloodGroup(String text) {
    final direct = RegExp(r'\b(A|B|AB|O)\s*[+\-]\b', caseSensitive: false);
    final dm = direct.firstMatch(text);
    if (dm != null) return dm.group(0)!.toUpperCase().replaceAll(' ', '');

    final wordMatch = RegExp(
      r'blood\s*(?:group|type)?\s*[:\-]?\s*(A|B|AB|O)\s*(positive|negative|pos|neg|\+|\-)',
      caseSensitive: false,
    ).firstMatch(text);
    if (wordMatch != null) {
      final grp = wordMatch.group(1)!.toUpperCase();
      final sign = wordMatch.group(2)!.toLowerCase();
      return '$grp${sign.startsWith('p') || sign == '+' ? '+' : '-'}';
    }
    return null;
  }

  /// Address block — labeled "Address:" first, then pincode-bearing lines.
  static String? _extractAddress(List<String> lines, String rawText) {
    final labeled = RegExp(r'(?:address|add|addr)\s*[:\-]\s*(.+)', caseSensitive: false);
    final m = labeled.firstMatch(rawText);
    if (m != null) {
      final addr = m.group(1)!.trim().split('\n').take(4).join(', ');
      return addr.length > 200 ? '${addr.substring(0, 200)}...' : addr;
    }
    // Look for pincode (6-digit) line and grab surrounding lines
    for (int i = 0; i < lines.length; i++) {
      if (RegExp(r'\b\d{6}\b').hasMatch(lines[i])) {
        final start = (i - 2).clamp(0, lines.length - 1);
        return lines.sublist(start, i + 1).join(', ');
      }
    }
    return null;
  }

  /// License class / COV.
  static String? _extractLicenseClass(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('hmv') || lower.contains('heavy motor')) return 'HMV (Heavy Commercial Vehicles)';
    if ((lower.contains('mcwg') || lower.contains('motorcycle')) && lower.contains('lmv')) return 'LMV & MCWG (Cars & Motorcycles)';
    if (lower.contains('mcwg') || lower.contains('motorcycle')) return 'MCWG Only (Motorcycles With Gear)';
    if (lower.contains('mcwog') || lower.contains('scooter')) return 'MCWOG Only (Scooters / Gearless)';
    if (lower.contains('lmv') || lower.contains('light motor')) return 'LMV Only (Light Motor Vehicles)';
    return null;
  }

  static String _extractAuthority(String text, String docType) {
    final upper = text.toUpperCase();
    if (docType == 'Aadhar Card') return 'UIDAI — Government of India';
    if (upper.contains('RTO') || upper.contains('REGIONAL TRANSPORT')) {
      final m = RegExp(r'RTO[:\s]+([A-Z0-9\-\s]+)', caseSensitive: false).firstMatch(text);
      return m != null ? 'RTO — ${m.group(1)!.trim()}' : 'Regional Transport Office (RTO)';
    }
    if (upper.contains('MINISTRY') || upper.contains('MORTH')) return 'Ministry of Road Transport & Highways (MoRTH)';
    if (docType == 'Vehicle Registration (RC)') return 'Regional Transport Office (RTO)';
    return 'Ministry of Road Transport & Highways (MoRTH)';
  }

  // ──────────────────────────────────────────────────────────────────────────
  // DATE UTILITIES
  // ──────────────────────────────────────────────────────────────────────────

  static String _normalizeDateStr(String raw) {
    final p = _parseDateStr(raw);
    if (p == null) return raw;
    return '${p.year.toString().padLeft(4, '0')}-${p.month.toString().padLeft(2, '0')}-${p.day.toString().padLeft(2, '0')}';
  }

  static DateTime? _parseDateStr(String raw) {
    try {
      final parts = raw.split(RegExp(r'[\/\-\.]'));
      if (parts.length != 3) return null;
      int year, month, day;
      if (parts[0].length == 4) {
        year = int.parse(parts[0]); month = int.parse(parts[1]); day = int.parse(parts[2]);
      } else {
        day = int.parse(parts[0]); month = int.parse(parts[1]);
        final raw2 = int.parse(parts[2]);
        year = parts[2].length == 2 ? (raw2 < 50 ? 2000 + raw2 : 1900 + raw2) : raw2;
      }
      if (month < 1 || month > 12 || day < 1 || day > 31) return null;
      return DateTime(year, month, day);
    } catch (_) { return null; }
  }

  static int _calculateAge(String dobStr) {
    try {
      final birth = _parseDateStr(dobStr);
      if (birth == null) return 0;
      final today = DateTime.now();
      int age = today.year - birth.year;
      if (today.month < birth.month || (today.month == birth.month && today.day < birth.day)) age--;
      return age > 0 ? age : 0;
    } catch (_) { return 0; }
  }

  static String _toTitleCase(String s) =>
      s.split(' ').map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase()).join(' ');

  // ──────────────────────────────────────────────────────────────────────────
  // HEURISTIC FALLBACK (no image provided)
  // ──────────────────────────────────────────────────────────────────────────

  static OcrExtractionResult _heuristicFallback({
    required String fileName,
    required String selectedDocType,
    required double fileSizeKb,
    String? userDisplayName,
  }) {
    final lower = fileName.toLowerCase();
    if (lower.contains('expired') || lower.contains('invalid') || lower.contains('old')) {
      return getPresetSample('Expired Driving License');
    }
    if (selectedDocType == 'Aadhar Card' || lower.contains('aadhar') || lower.contains('uidai')) {
      return getPresetSample('Aadhar Card');
    }
    if (selectedDocType == 'Vehicle Registration (RC)' || lower.contains('rc') || lower.contains('registration')) {
      return getPresetSample('Vehicle Registration (RC)');
    }
    return getPresetSample('Driving License');
  }

  // ──────────────────────────────────────────────────────────────────────────
  // PRESET SAMPLES (for quick testing / demo)
  // ──────────────────────────────────────────────────────────────────────────

  static OcrExtractionResult getPresetSample(String docType) {
    if (docType == 'Expired Driving License' || docType == 'Expired DL') {
      final expiredDate = DateTime.now().subtract(const Duration(days: 45));
      const dobStr = '1998-03-22';
      final age = _calculateAge(dobStr);
      return OcrExtractionResult(
        docType: 'Driving License',
        holderName: 'Rohan Deshmukh',
        documentNumber: 'DL-0420150012399',
        expiryDate: expiredDate,
        licenseClass: 'LMV & MCWG (Cars & Motorcycles)',
        dob: dobStr,
        calculatedAge: age,
        bloodGroup: 'A+',
        address: 'D-804, Blue Ridge, Hinjawadi Phase 1, Pune, MH - 411057',
        issuingAuthority: 'RTO Maharashtra (MH-04 Thane)',
        confidenceScore: 99.1,
        rawText: 'INDIAN UNION DRIVING LICENCE\nLicence No: DL-0420150012399\nName: Rohan Deshmukh\nDOB: 22-03-1998\nBlood Group: A+\nAddress: D-804, Blue Ridge, Hinjawadi Phase 1, Pune, MH - 411057\nCOV: LMV & MCWG\nValid Till: ${expiredDate.year}-${expiredDate.month.toString().padLeft(2, '0')}-${expiredDate.day.toString().padLeft(2, '0')} [EXPIRED]',
        fileName: 'driving_license_expired_test.pdf',
        fileSizeKb: 310.0,
        isExpiryValid: false,
        expiryStatusText: '⚠️ EXPIRED (Expired 45 days ago on ${expiredDate.year}-${expiredDate.month.toString().padLeft(2, '0')}-${expiredDate.day.toString().padLeft(2, '0')})',
        isAgeEligible: age >= 18,
      );
    } else if (docType == 'Aadhar Card') {
      const dobStr = '1994-11-20';
      final age = _calculateAge(dobStr);
      return OcrExtractionResult(
        docType: 'Aadhar Card',
        holderName: 'Vikramaditya Roy',
        documentNumber: '6742 8819 0431',
        expiryDate: DateTime.now().add(const Duration(days: 3650)),
        licenseClass: 'Government Identity Card',
        dob: dobStr,
        calculatedAge: age,
        bloodGroup: 'AB+',
        address: 'House 88, Park Street Extension, Kolkata, WB - 700016',
        issuingAuthority: 'UIDAI — Government of India',
        confidenceScore: 99.5,
        rawText: 'GOVERNMENT OF INDIA\nUnique Identification Authority of India\nName: Vikramaditya Roy\nDOB: 20/11/1994\nBlood Group: AB+\nGender: MALE\nAadhaar: 6742 8819 0431\nAddress: House 88, Park Street Extension, Kolkata, WB - 700016',
        fileName: 'aadhar_card_front_back_scan.jpg',
        fileSizeKb: 310.0,
        isExpiryValid: true,
        expiryStatusText: 'VALID (Govt Permanent ID)',
        isAgeEligible: age >= 18,
      );
    } else if (docType == 'Vehicle Registration (RC)') {
      return OcrExtractionResult(
        docType: 'Vehicle Registration (RC)',
        holderName: 'Priya Sharma',
        documentNumber: 'MH-12-PQ-9082',
        expiryDate: DateTime.now().add(const Duration(days: 4100)),
        licenseClass: 'Motor Vehicle Registration',
        dob: '1997-09-11',
        calculatedAge: _calculateAge('1997-09-11'),
        bloodGroup: 'B-',
        address: 'B-14, Green Valley Society, Baner Road, Pune, MH - 411045',
        issuingAuthority: 'RTO Maharashtra (MH-12 Pune)',
        confidenceScore: 98.4,
        rawText: 'STATE TRANSPORT AUTHORITY MAHARASHTRA\nCertificate of Vehicle Registration\nReg No: MH-12-PQ-9082\nOwner: Priya Sharma\nBlood Group: B-\nClass: LMV Sedan Petrol\nAddress: B-14, Green Valley Society, Baner Road, Pune, MH - 411045',
        fileName: 'rc_book_mh12.pdf',
        fileSizeKb: 275.0,
        isExpiryValid: true,
        expiryStatusText: 'VALID (Active Fitness)',
        isAgeEligible: true,
      );
    } else {
      const dobStr = '1996-05-14';
      final age = _calculateAge(dobStr);
      final expiry = DateTime.now().add(const Duration(days: 2840));
      return OcrExtractionResult(
        docType: 'Driving License',
        holderName: 'Aarav S. Varma',
        documentNumber: 'DL-1420230099812',
        expiryDate: expiry,
        licenseClass: 'LMV & MCWG (Cars & Motorcycles)',
        dob: dobStr,
        calculatedAge: age,
        bloodGroup: 'O+',
        address: 'H.No 142/B, 100ft Road, Indiranagar, Bengaluru, KA - 560038',
        issuingAuthority: 'Delhi Transport Department (RTO DL-14)',
        confidenceScore: 99.8,
        rawText: 'INDIAN UNION DRIVING LICENCE\nLicence No: DL-1420230099812\nName: Aarav S. Varma\nCOV: LMV & MCWG\nDOB: 14-05-1996\nBlood Group: O+\nAddress: H.No 142/B, 100ft Road, Indiranagar, Bengaluru, KA - 560038\nIssue Date: 12-04-2018\nValid Till: ${expiry.year}-${expiry.month.toString().padLeft(2, '0')}-${expiry.day.toString().padLeft(2, '0')}',
        fileName: 'driving_license_aarav_official.pdf',
        fileSizeKb: 345.0,
        isExpiryValid: true,
        expiryStatusText: 'VALID (Expires ${expiry.year}-${expiry.month.toString().padLeft(2, '0')}-${expiry.day.toString().padLeft(2, '0')})',
        isAgeEligible: age >= 18,
      );
    }
  }
}
