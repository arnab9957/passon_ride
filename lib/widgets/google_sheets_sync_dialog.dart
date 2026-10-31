import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_state.dart';
import '../services/bookings_excel_export.dart';
import '../services/google_sheets_service.dart';

class GoogleSheetsSyncDialog extends StatefulWidget {
  final AppState appState;

  const GoogleSheetsSyncDialog({super.key, required this.appState});

  static Future<void> show(BuildContext context, AppState appState) {
    return showDialog(
      context: context,
      builder: (_) => GoogleSheetsSyncDialog(appState: appState),
    );
  }

  @override
  State<GoogleSheetsSyncDialog> createState() => _GoogleSheetsSyncDialogState();
}

class _GoogleSheetsSyncDialogState extends State<GoogleSheetsSyncDialog> {
  final _sheets = GoogleSheetsService();
  Timer? _poll;
  String? _sheetUrl;
  bool _loading = true;
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    final url = await _sheets.getConnectedSheetUrl();
    if (!mounted) return;
    setState(() {
      _sheetUrl = url;
      _loading = false;
    });
    if (url != null) _poll?.cancel();
  }

  Future<void> _connect() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    final url = await _sheets.getConnectUrl();
    if (!mounted) return;
    setState(() => _busy = false);
    if (url == null) {
      setState(() => _message = 'Could not start Google sign-in. Please try again.');
      return;
    }
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (timer.tick > 100) timer.cancel();
      _refresh();
    });
  }

  Future<void> _syncPastBookings() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    final appState = widget.appState;
    final ids = appState.allActiveUserIds;
    var count = 0;
    for (final b in appState.allBookings.where((b) => ids.contains(b.hostId))) {
      if (await _sheets.syncVehicleBooking(booking: b)) count++;
    }
    for (final b in appState.hotelBookings.where((b) => ids.contains(b.hostId))) {
      if (await _sheets.syncHotelBooking(booking: b)) count++;
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = count == 0 ? 'Your sheet is already up to date.' : 'Added $count bookings to your sheet.';
    });
  }

  Future<void> _disconnect() async {
    setState(() => _busy = true);
    await _sheets.disconnect();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _sheetUrl = null;
      _message = 'Disconnected. Your existing sheet stays in your Google Drive.';
    });
  }

  Future<void> _download() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final count = await exportBookingsToExcel(widget.appState);
      if (mounted) setState(() => _message = 'Exported $count bookings to Excel.');
    } catch (e) {
      debugPrint('Excel export error: $e');
      if (mounted) setState(() => _message = 'Could not create the Excel file. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sheetUrl = _sheetUrl;
    return AlertDialog(
      title: const Text('Bookings Spreadsheet'),
      content: _loading
          ? const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()))
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (sheetUrl == null) ...[
                  const Text('Connect once and every new booking is added to a sheet in your Google Drive.'),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _busy ? null : _connect,
                    icon: const Icon(Icons.link),
                    label: const Text('Connect Google Sheets'),
                  ),
                ] else ...[
                  const Text('Connected. New bookings are added automatically.'),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => launchUrl(Uri.parse(sheetUrl), mode: LaunchMode.externalApplication),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open My Sheet'),
                  ),
                  OutlinedButton(
                    onPressed: _busy ? null : _syncPastBookings,
                    child: const Text('Add Past Bookings'),
                  ),
                  TextButton(
                    onPressed: _busy ? null : _disconnect,
                    child: const Text('Disconnect'),
                  ),
                ],
                const Divider(height: 24),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _download,
                  icon: const Icon(Icons.download),
                  label: const Text('Download Bookings (Excel)'),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 10),
                  Text(_message!, style: const TextStyle(fontSize: 12)),
                ],
              ],
            ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ],
    );
  }
}
