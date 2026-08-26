// ignore_for_file: avoid_print
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:passon_ride/services/document_ocr_service.dart';

void main() {
  test('Test DL.pdf OCR extraction', () async {
    final file = File('public/DL.pdf');
    expect(file.existsSync(), isTrue, reason: 'public/DL.pdf must exist');

    final bytes = await file.readAsBytes();
    print('Read ${bytes.length} bytes from public/DL.pdf');

    final result = await DocumentOcrService.processDocument(
      fileName: 'DL.pdf',
      selectedDocType: 'Driving License',
      fileSizeKb: bytes.length / 1024.0,
      bytes: bytes,
    );

    print('\n==================================================');
    print('=== OCR EXTRACTION RESULT FOR public/DL.pdf ===');
    print('Doc Type:          ${result.docType}');
    print('Holder Name:       ${result.holderName}');
    print('Document Number:   ${result.documentNumber}');
    print('Date of Birth:     ${result.dob}');
    print('Calculated Age:    ${result.calculatedAge} (Eligible: ${result.isAgeEligible})');
    print('Blood Group:       ${result.bloodGroup}');
    print('Address:           ${result.address}');
    print('Expiry Date:       ${result.expiryDate}');
    print('Expiry Status:     ${result.expiryStatusText}');
    print('License Class:     ${result.licenseClass}');
    print('Issuing Authority: ${result.issuingAuthority}');
    print('Confidence Score:  ${result.confidenceScore}%');
    print('Raw Text (${result.rawText.length} chars):');
    print('"""\n${result.rawText}\n"""');
    print('==================================================\n');
  });
}
