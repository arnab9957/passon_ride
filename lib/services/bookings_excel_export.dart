import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/app_state.dart';

const _headers = [
  'Booking ID', 'Category', 'Item / Service', 'Customer Name', 'Customer Phone', 'Customer Email',
  'Start / Check-In', 'End / Check-Out', 'Total (INR)', 'Status',
];

const _contentTypes = '<?xml version="1.0" encoding="UTF-8"?>'
    '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
    '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
    '<Default Extension="xml" ContentType="application/xml"/>'
    '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
    '<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
    '</Types>';
const _rootRels = '<?xml version="1.0" encoding="UTF-8"?>'
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
    '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
    '</Relationships>';
const _workbook = '<?xml version="1.0" encoding="UTF-8"?>'
    '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
    'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
    '<sheets><sheet name="Bookings" sheetId="1" r:id="rId1"/></sheets></workbook>';
const _workbookRels = '<?xml version="1.0" encoding="UTF-8"?>'
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
    '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>'
    '</Relationships>';

String _day(DateTime date) => date.toIso8601String().split('T').first;

String _escape(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

String _cell(Object value) => value is num
    ? '<c><v>$value</v></c>'
    : '<c t="inlineStr"><is><t>${_escape(value.toString())}</t></is></c>';

Uint8List _buildWorkbook(List<List<Object>> rows) {
  final sheetRows = [_headers, ...rows].map((r) => '<row>${r.map(_cell).join()}</row>').join();
  final sheet = '<?xml version="1.0" encoding="UTF-8"?>'
      '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
      '<sheetData>$sheetRows</sheetData></worksheet>';

  final archive = Archive();
  void add(String name, String content) {
    final bytes = utf8.encode(content);
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  }

  add('[Content_Types].xml', _contentTypes);
  add('_rels/.rels', _rootRels);
  add('xl/workbook.xml', _workbook);
  add('xl/_rels/workbook.xml.rels', _workbookRels);
  add('xl/worksheets/sheet1.xml', sheet);
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

/// Builds and saves an Excel file of the active host's bookings. Returns the row count.
Future<int> exportBookingsToExcel(AppState appState) async {
  final ids = appState.allActiveUserIds;
  final rows = <List<Object>>[
    for (final b in appState.allBookings)
      if (ids.contains(b.hostId))
        [
          b.id, 'Bike / Vehicle Ride', b.vehicleTitle, b.customerName, b.customerPhone, b.customerEmail,
          _day(b.startDate), _day(b.endDate), b.totalPrice, b.status,
        ],
    for (final b in appState.hotelBookings)
      if (ids.contains(b.hostId))
        [
          b.bookingRef.isNotEmpty ? b.bookingRef : b.id, 'Hotel / Homestay', b.hotelName, b.guestName,
          b.guestPhone, b.guestEmail, _day(b.checkInDate), _day(b.checkOutDate), b.totalPrice, b.status,
        ],
  ];

  await FilePicker.platform.saveFile(
    fileName: 'PassionRide_Bookings_${_day(DateTime.now())}.xlsx',
    bytes: _buildWorkbook(rows),
  );
  return rows.length;
}
