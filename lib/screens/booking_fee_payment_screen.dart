import 'package:image_picker/image_picker.dart';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/booking_fee_service.dart';

/// Pay the ₹10 booking fee by UPI, then submit the UTR for verification.
class BookingFeePaymentScreen extends StatefulWidget {
  final String bookingKind; // vehicle | tour | stay
  final String bookingId;
  final String serviceLabel; // "Bike Rental", "Guided Tour"
  final String itemTitle;
  final double totalAmount;
  final String durationLabel;

  const BookingFeePaymentScreen({
    super.key,
    required this.bookingKind,
    required this.bookingId,
    required this.serviceLabel,
    required this.itemTitle,
    required this.totalAmount,
    this.durationLabel = '',
  });

  @override
  State<BookingFeePaymentScreen> createState() => _BookingFeePaymentScreenState();
}

class _BookingFeePaymentScreenState extends State<BookingFeePaymentScreen> {
  final _svc = BookingFeeService.instance;
  final _utr = TextEditingController();
  BookingFeePayment? _payment;
  String _upiUri = '';
  String? _error;
  bool _loading = true;
  bool _busy = false;
  List<ScreenshotCheck> _checks = const [];
  StreamSubscription<BookingFeePayment>? _sub;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final (p, uri) = await _svc.create(bookingKind: widget.bookingKind, bookingId: widget.bookingId);
      _setPayment(p);
      _upiUri = uri;
      _sub?.cancel();
      _sub = _svc.watch(p.id).listen(_setPayment, onError: (_) {});
      // Fallback in case realtime drops.
      _poll?.cancel();
      _poll = Timer.periodic(const Duration(seconds: 15), (_) async {
        final cur = _payment;
        if (cur == null || cur.isFinal) return;
        try {
          _setPayment(await _svc.status(cur.id));
        } catch (_) {}
      });
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    if (mounted) setState(() => _loading = false);
  }

  void _setPayment(BookingFeePayment p) {
    if (!mounted) return;
    setState(() => _payment = p);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _poll?.cancel();
    _utr.dispose();
    super.dispose();
  }

  /// UPI apps with their own deep-link schemes; they take the same query as upi://pay.
  static const _upiApps = <(String, String, Color)>[
    ('Google Pay', 'tez://upi/pay', Color(0xFF1A73E8)),
    ('PhonePe', 'phonepe://pay', Color(0xFF5F259F)),
    ('Paytm', 'paytmmp://pay', Color(0xFF00BAF2)),
    ('FamPay', 'upi://pay', Color(0xFFFF7A00)), // FamPay has no public scheme: opens the UPI app chooser
    ('BHIM', 'bhim://upi/pay', Color(0xFF0B6E4F)),
    ('Amazon Pay', 'upi://pay', Color(0xFF232F3E)),
  ];

  bool get _isPhone =>
      defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;

  Future<void> _openUpi([String base = 'upi://pay', String appName = '']) async {
    final query = Uri.parse(_upiUri).query;
    var ok = await launchUrl(Uri.parse('$base?$query'), mode: LaunchMode.externalApplication).catchError((_) => false);
    if (!ok && base != 'upi://pay') {
      if (mounted && appName.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$appName not found — choose another UPI app')));
      }
      ok = await launchUrl(Uri.parse(_upiUri), mode: LaunchMode.externalApplication).catchError((_) => false);
    }
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No UPI app found. Scan the QR code from another phone or pay to the UPI ID shown.'),
      ));
    }
  }

  Future<void> _submitUtr() async {
    final p = _payment;
    final utr = _utr.text.replaceAll(' ', '');
    if (p == null) return;
    if (!RegExp(r'^\d{12}$').hasMatch(utr)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter the 12-digit UPI reference (UTR) from your payment app')));
      return;
    }
    setState(() => _busy = true);
    try {
      _setPayment(await _svc.submitUtr(p.id, utr));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ));
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _uploadScreenshot() async {
    final p = _payment;
    if (p == null) return;
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1400,
      imageQuality: 80, // keeps it under the 1 MB OCR limit
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final name = picked.name.toLowerCase();
    final mime = name.endsWith('.png') ? 'image/png' : name.endsWith('.webp') ? 'image/webp' : 'image/jpeg';
    setState(() => _busy = true);
    try {
      final (updated, checks) = await _svc.submitScreenshot(p.id, bytes, mime);
      _checks = checks;
      _setPayment(updated);
      if (mounted && updated.status != 'SUCCESS') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Some checks did not pass — sent to our team for manual review.'),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ));
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  Widget _screenshotButton({String label = 'Upload payment screenshot'}) => SizedBox(
        height: 48,
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _busy ? null : _uploadScreenshot,
          icon: _busy
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.document_scanner),
          label: Text(_busy ? 'Checking screenshot…' : label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      );

  Widget _checkList() {
    if (_checks.isEmpty) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Screenshot check', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          for (final c in _checks)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(c.ok ? Icons.check_circle : Icons.cancel, size: 18, color: c.ok ? Colors.green : Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text.rich(TextSpan(children: [
                    TextSpan(text: c.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                    TextSpan(text: '  ${c.detail}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ])),
                ),
              ]),
            ),
        ]),
      ),
    );
  }

  String _rs(double v) => '₹${v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2)}';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final p = _payment;
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm booking')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _init)
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: ListView(padding: const EdgeInsets.all(16), children: [
                      _summary(scheme, p!),
                      const SizedBox(height: 16),
                      switch (p.status) {
                        'SUCCESS' => _StatusCard(
                            icon: Icons.verified,
                            color: Colors.green,
                            title: 'Booking confirmed!',
                            body: 'Your ₹10 fee is verified and the provider has been notified. '
                                'Pay ${_rs(widget.totalAmount)} directly to the provider at pickup / check-in.',
                            action: FilledButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Done'),
                            ),
                          ),
                        'SUBMITTED' => _StatusCard(
                            icon: Icons.hourglass_top,
                            color: Colors.orange,
                            title: 'Verifying your payment…',
                            body: 'UTR ${p.utr} received. We match it with our bank statement, usually within a few '
                                'minutes. You will get a notification once confirmed — you can close this screen.',
                            action: Column(children: [
                              if (p.verificationMethod.isEmpty) ...[
                                const Text('Upload your payment screenshot to confirm instantly:',
                                    style: TextStyle(fontSize: 12.5)),
                                const SizedBox(height: 8),
                                _screenshotButton(),
                                _checkList(),
                                const SizedBox(height: 8),
                              ],
                              OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('Close'),
                              ),
                            ]),
                          ),
                        'REFUNDED' || 'REFUND_PENDING' => _StatusCard(
                            icon: Icons.currency_exchange,
                            color: Colors.blueGrey,
                            title: p.status == 'REFUNDED' ? 'Fee refunded' : 'Refund in progress',
                            body: 'The provider could not accept this booking, so your ₹10 fee is being returned.',
                          ),
                        _ => _payStep(scheme, p),
                      },
                    ]),
                  ),
                ),
    );
  }

  Widget _summary(ColorScheme scheme, BookingFeePayment p) {
    Widget line(String a, String b, {bool bold = false, Color? color}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            Expanded(child: Text(a, style: TextStyle(fontWeight: bold ? FontWeight.bold : null))),
            Text(b, style: TextStyle(fontWeight: bold ? FontWeight.w900 : FontWeight.w600, color: color)),
          ]),
        );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('BOOKING SUMMARY', style: TextStyle(fontSize: 11, letterSpacing: 1, color: scheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          line('Service', widget.serviceLabel),
          line(widget.bookingKind == 'stay' ? 'Stay' : widget.bookingKind == 'tour' ? 'Tour' : 'Vehicle', widget.itemTitle),
          if (widget.durationLabel.isNotEmpty) line('Duration', widget.durationLabel),
          line('Booking amount', _rs(widget.totalAmount)),
          const Divider(),
          line('Booking confirmation fee (now)', _rs(p.amount), bold: true, color: scheme.primary),
          line('Pay provider directly', _rs(widget.totalAmount)),
          const SizedBox(height: 8),
          Text(
            'The ₹10 fee is a non-refundable PassionRide booking fee, refunded only if the provider rejects '
            'your booking. The full booking amount is paid directly to the provider.',
            style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
          ),
        ]),
      ),
    );
  }

  Widget _payStep(ColorScheme scheme, BookingFeePayment p) {
    final failed = p.status == 'FAILED';
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (failed)
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
          child: Text('Payment not verified: ${p.failureReason}. Check the UTR and submit again.',
              style: const TextStyle(color: Colors.red)),
        ),
      Text('Step 1 — Pay ₹10 by UPI', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      const SizedBox(height: 8),
      if (_isPhone) ...[
        Text('Tap your UPI app to pay ${_rs(p.amount)}:', style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.6,
          children: [
            for (final (name, base, color) in _upiApps)
              Material(
                color: color.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: color.withValues(alpha: 0.35)),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _openUpi(base, name),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    CircleAvatar(
                      radius: 13,
                      backgroundColor: color,
                      child: Text(name[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    const SizedBox(height: 4),
                    Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _openUpi,
            icon: const Icon(Icons.apps),
            label: const Text('Other UPI app', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
      const SizedBox(height: 10),
      Center(
        child: Column(children: [
          Text(_isPhone ? 'Or scan from another phone' : 'Scan with any UPI app',
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
          const SizedBox(height: 6),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(8),
            child: QrImageView(data: _upiUri, size: 180, padding: EdgeInsets.zero),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: p.payeeVpa));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('UPI ID copied')));
            },
            child: Text('UPI ID: ${p.payeeVpa}  ⧉', style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Text('Note / ref: ${p.paymentRef}', style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
        ]),
      ),
      const SizedBox(height: 20),
      const Text('Step 2 — Upload the payment screenshot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      const SizedBox(height: 4),
      Text('Take a screenshot of the "Payment successful" screen showing the amount, UTR, date/time and '
          'who you paid. Your booking is confirmed instantly if everything matches.',
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
      const SizedBox(height: 8),
      _screenshotButton(),
      _checkList(),
      const SizedBox(height: 20),
      const Text('Or enter the UPI reference (UTR) manually', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      const SizedBox(height: 4),
      Text('Find the 12-digit "UPI Ref No." / "UTR" in your payment app after paying.',
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
      const SizedBox(height: 8),
      TextField(
        controller: _utr,
        keyboardType: TextInputType.number,
        maxLength: 12,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          labelText: 'UTR / UPI reference number',
          prefixIcon: Icon(Icons.receipt_long),
          border: OutlineInputBorder(),
        ),
      ),
      SizedBox(
        height: 48,
        child: FilledButton(
          onPressed: _busy ? null : _submitUtr,
          child: _busy
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Submit for verification', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
      const SizedBox(height: 8),
      const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.lock, size: 14, color: Colors.green),
        SizedBox(width: 4),
        Text('Secure UPI payment • we never see your UPI PIN', style: TextStyle(fontSize: 11.5)),
      ]),
    ]);
  }
}

class _StatusCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final Widget? action;
  const _StatusCard({required this.icon, required this.color, required this.title, required this.body, this.action});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            Icon(icon, size: 56, color: color),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(body, textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ]),
        ),
      );
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ]),
        ),
      );
}
