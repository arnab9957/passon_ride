import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

import '../services/booking_fee_service.dart';

/// Admin: match submitted UTRs against the merchant bank statement and
/// approve (confirms booking + notifies provider) or reject.
class AdminBookingFeeReviewScreen extends StatefulWidget {
  const AdminBookingFeeReviewScreen({super.key});

  @override
  State<AdminBookingFeeReviewScreen> createState() => _AdminBookingFeeReviewScreenState();
}

class _AdminBookingFeeReviewScreenState extends State<AdminBookingFeeReviewScreen> {
  final _svc = BookingFeeService.instance;
  List<BookingFeePayment> _items = [];
  bool _loading = true;
  String? _error;
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _items = await _svc.pendingForReview();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _act(BookingFeePayment p, Future<void> Function() fn, String done) async {
    setState(() => _busy.add(p.id));
    try {
      await fn();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(done)));
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red));
      }
    }
    if (mounted) setState(() => _busy.remove(p.id));
  }

  Future<String?> _ask(String title, String label, {String initial = ''}) {
    final c = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(controller: c, decoration: InputDecoration(labelText: label), autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM, hh:mm a');
    final submitted = _items.where((p) => p.status == 'SUBMITTED').toList();
    final other = _items.where((p) => p.status != 'SUBMITTED').toList();

    Widget tile(BookingFeePayment p) {
      final busy = _busy.contains(p.id);
      final color = switch (p.status) {
        'SUBMITTED' => Colors.orange,
        'REFUND_PENDING' => Colors.blueGrey,
        _ => Colors.grey,
      };
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(p.utr.isEmpty ? 'No UTR yet' : 'UTR ${p.utr}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              Chip(
                label: Text(p.status, style: const TextStyle(fontSize: 11, color: Colors.white)),
                backgroundColor: color,
                visualDensity: VisualDensity.compact,
              ),
            ]),
            Text('₹${p.amount.toStringAsFixed(0)} • ${p.bookingKind} • booking ${p.bookingId}'),
            Text('Ref ${p.paymentRef} • ${fmt.format(p.createdAt.toLocal())}',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            if (p.checks.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(spacing: 6, runSpacing: 4, children: [
                for (final c in p.checks)
                  Tooltip(
                    message: c.detail,
                    child: Chip(
                      avatar: Icon(c.ok ? Icons.check_circle : Icons.cancel,
                          size: 16, color: c.ok ? Colors.green : Colors.red),
                      label: Text(c.label, style: const TextStyle(fontSize: 11)),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ]),
            ],
            if (p.screenshotUrl.isNotEmpty)
              TextButton.icon(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => Dialog(
                    child: InteractiveViewer(child: Image.network(p.screenshotUrl)),
                  ),
                ),
                icon: const Icon(Icons.image),
                label: const Text('View payment screenshot'),
              ),
            const SizedBox(height: 8),
            if (busy)
              const LinearProgressIndicator()
            else if (p.status == 'SUBMITTED')
              Row(children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () => _act(p, () => _svc.review(p.id, approve: true), 'Approved — booking confirmed'),
                    icon: const Icon(Icons.check),
                    label: const Text('Received — approve'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    onPressed: () async {
                      final reason = await _ask('Reject payment', 'Reason',
                          initial: 'UTR not found in bank statement');
                      if (reason == null) return;
                      await _act(p, () => _svc.review(p.id, approve: false, reason: reason), 'Rejected');
                    },
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                  ),
                ),
              ])
            else if (p.status == 'REFUND_PENDING')
              FilledButton.icon(
                onPressed: () async {
                  final ref = await _ask('Mark refund completed', 'Refund UTR / reference');
                  if (ref == null || ref.isEmpty) return;
                  await _act(p, () => _svc.refund(p.id, reason: 'Provider rejected the booking', reference: ref),
                      'Refund recorded');
                },
                icon: const Icon(Icons.currency_exchange),
                label: const Text('Mark refund completed'),
              ),
          ]),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking fee verification'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(padding: const EdgeInsets.all(12), children: [
                    const Text(
                      'Approve only after the UTR and ₹10 appear in the merchant bank account statement.',
                      style: TextStyle(fontSize: 12.5, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text('Awaiting verification (${submitted.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    if (submitted.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Text('All caught up 🎉')),
                    ...submitted.map(tile),
                    if (other.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text('Other open payments (${other.length})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ...other.map(tile),
                    ],
                  ]),
                ),
    );
  }
}
