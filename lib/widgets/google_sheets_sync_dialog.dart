// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_state.dart';
import '../services/google_sheets_service.dart';
import '../theme/app_colors.dart';

class GoogleSheetsSyncDialog extends StatefulWidget {
  final AppState appState;

  const GoogleSheetsSyncDialog({super.key, required this.appState});

  static Future<void> show(BuildContext context, AppState appState) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: GoogleSheetsSyncDialog(appState: appState),
        ),
      ),
    );
  }

  @override
  State<GoogleSheetsSyncDialog> createState() => _GoogleSheetsSyncDialogState();
}

class _GoogleSheetsSyncDialogState extends State<GoogleSheetsSyncDialog> {
  final _webhookController = TextEditingController();
  final _sheetsService = GoogleSheetsService();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isTesting = false;
  bool _isSyncingAll = false;
  String? _statusMessage;
  bool _statusSuccess = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentWebhook();
  }

  Future<void> _loadCurrentWebhook() async {
    final hostId = widget.appState.activeUserId;
    final savedUrl = await _sheetsService.getWebhookUrl(hostId);
    if (mounted) {
      setState(() {
        if (savedUrl != null) {
          _webhookController.text = savedUrl;
        }
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _webhookController.dispose();
    super.dispose();
  }

  Future<void> _saveWebhook() async {
    final hostId = widget.appState.activeUserId;
    final url = _webhookController.text.trim();
    setState(() => _isSaving = true);
    await _sheetsService.saveWebhookUrl(hostId, url);
    if (mounted) {
      setState(() {
        _isSaving = false;
        _statusMessage = url.isEmpty
            ? 'Google Sheet integration disabled.'
            : 'Google Sheet Webhook saved successfully! New bookings will be auto-updated.';
        _statusSuccess = true;
      });
    }
  }

  Future<void> _testSync() async {
    final url = _webhookController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter your Google Apps Script Webhook URL first.';
        _statusSuccess = false;
      });
      return;
    }

    setState(() {
      _isTesting = true;
      _statusMessage = null;
    });

    final testRow = {
      'bookingId': 'TEST-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      'category': 'System Test / Verification',
      'itemName': 'Sample PassOn Listing',
      'customerName': widget.appState.activeUserDisplayName,
      'customerPhone': '+91 9876543210',
      'customerEmail': widget.appState.userProfile?.email ?? 'host@passon.in',
      'startDate': DateTime.now().toIso8601String().split('T').first,
      'endDate': DateTime.now().add(const Duration(days: 2)).toIso8601String().split('T').first,
      'totalPrice': 1500,
      'status': 'Confirmed (Test)',
      'paymentMethod': 'PassOn Gateway',
      'timestamp': DateTime.now().toIso8601String(),
    };

    final ok = await _sheetsService.sendRowToSheet(
      webhookUrl: url,
      rowData: testRow,
    );

    if (mounted) {
      setState(() {
        _isTesting = false;
        _statusSuccess = ok;
        _statusMessage = ok
            ? '✅ Connection Verified! A test row has been appended to your Google Sheet.'
            : '❌ Connection Failed. Make sure you selected "Anyone" in Web App deployment.';
      });
    }
  }

  Future<void> _syncAllPastBookings() async {
    final url = _webhookController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter and save your Google Sheet Webhook URL first.';
        _statusSuccess = false;
      });
      return;
    }

    setState(() {
      _isSyncingAll = true;
      _statusMessage = null;
    });

    final hostId = widget.appState.activeUserId;
    int syncedCount = 0;

    // 1. Vehicle bookings
    for (final b in widget.appState.allBookings) {
      if (b.hostId == hostId || b.userId == hostId) {
        final ok = await _sheetsService.syncVehicleBooking(
          booking: b,
          hostId: hostId,
          vehicleName: b.vehicleTitle,
        );
        if (ok) syncedCount++;
      }
    }

    // 2. Hotel & Homestay bookings
    for (final hb in widget.appState.hotelBookings) {
      if (hb.hostId == hostId) {
        final ok = await _sheetsService.syncHotelBooking(
          booking: hb,
          hostId: hostId,
        );
        if (ok) syncedCount++;
      }
    }

    if (mounted) {
      setState(() {
        _isSyncingAll = false;
        _statusSuccess = true;
        _statusMessage = '🎉 Synced $syncedCount booking records directly to your Google Sheet!';
      });
    }
  }

  void _copyAppsScript() {
    final code = _sheetsService.getGoogleAppsScriptTemplate();
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📋 Google Apps Script code copied to clipboard!'),
        backgroundColor: Colors.teal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF181C24) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: _isLoading
          ? const Center(
              heightFactor: 6,
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF107C41).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.table_chart_rounded, color: Color(0xFF107C41), size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Google Sheets & Excel Live Sync',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Auto-sync bike, stay, & tour bookings to your personal spreadsheet',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Setup Steps Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? Colors.blueGrey.shade800 : Colors.blueGrey.shade200,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.flash_on_rounded, color: Colors.amber, size: 20),
                                SizedBox(width: 6),
                                Text(
                                  'Quick 1-Minute Setup Guide',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: _copyAppsScript,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                visualDensity: VisualDensity.compact,
                              ),
                              icon: const Icon(Icons.copy_rounded, size: 15),
                              label: const Text('Copy Script', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '1. Open your Google Sheet (linked with your Gmail).\n'
                          '2. Click "Extensions" > "Apps Script".\n'
                          '3. Paste our sync script (click "Copy Script" above).\n'
                          '4. Click "Deploy" > "New deployment" -> Type: "Web app".\n'
                          '5. Set "Who has access" to "Anyone", deploy, and copy the Web App URL below.',
                          style: TextStyle(
                            fontSize: 11.5,
                            height: 1.45,
                            color: isDark ? Colors.grey.shade300 : Colors.blueGrey.shade800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        InkWell(
                          onTap: () async {
                            final uri = Uri.parse('https://sheets.new');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.open_in_new_rounded, size: 13, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(
                                'Create a new Google Sheet now (sheets.new)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Webhook Input Field
                  const Text(
                    'Your Google Sheet Webhook / Web App URL',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _webhookController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'https://script.google.com/macros/s/.../exec',
                      hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF232B38) : Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                      prefixIcon: const Icon(Icons.link_rounded, color: Color(0xFF107C41)),
                    ),
                    style: const TextStyle(fontSize: 12),
                  ),

                  const SizedBox(height: 12),

                  // Status Message Banner
                  if (_statusMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: _statusSuccess
                            ? Colors.green.withValues(alpha: 0.12)
                            : Colors.red.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _statusSuccess ? Colors.green : Colors.red,
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        _statusMessage!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _statusSuccess ? Colors.green.shade700 : Colors.red.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isTesting ? null : _testSync,
                          icon: _isTesting
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.send_rounded, size: 16),
                          label: const Text('Test Sync', style: TextStyle(fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _saveWebhook,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.save_rounded, size: 16),
                          label: const Text('Save Link', style: TextStyle(fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF107C41),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Bulk Sync All Past Bookings
                  InkWell(
                    onTap: _isSyncingAll ? null : _syncAllPastBookings,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? Colors.blueGrey.shade700 : Colors.blueGrey.shade300,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isSyncingAll)
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            const Icon(Icons.sync_rounded, color: Color(0xFF107C41), size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            'Export All Past Bookings to Google Sheet',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
