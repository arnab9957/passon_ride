import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/provider_earnings.dart';
import '../theme/app_colors.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  List<ProviderPayout> _payouts = [];
  String _payoutDetails = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final uid = appState.supabaseUser?.id;
    if (uid == null) return;
    final service = appState.supabaseService;
    final payouts = await service.getProviderPayouts(hostId: uid);
    final verification = await service.getProviderVerification(uid);
    if (!mounted) return;
    setState(() {
      _payouts = payouts;
      _payoutDetails = (verification?['payout_details'] ?? '').toString();
      _loading = false;
    });
  }

  Future<void> _requestPayout(double available) async {
    final messenger = ScaffoldMessenger.of(context);
    final appState = Provider.of<AppState>(context, listen: false);
    final controller = TextEditingController(text: available.toStringAsFixed(2));

    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request Payout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Amount (₹)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            Text(
              _payoutDetails.isNotEmpty ? 'Pay to: $_payoutDetails' : 'Add payout details in your verification form.',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, double.tryParse(controller.text.trim())),
            child: const Text('Request'),
          ),
        ],
      ),
    );
    if (amount == null) return;
    if (amount <= 0 || amount > available) {
      messenger.showSnackBar(const SnackBar(content: Text('Enter an amount up to your available balance.')));
      return;
    }

    final ok = await appState.supabaseService.requestProviderPayout(
      hostId: appState.supabaseUser!.id,
      amount: amount,
      payoutDetails: _payoutDetails,
    );
    messenger.showSnackBar(SnackBar(
      content: Text(ok ? 'Payout requested. Our team will process it soon.' : 'Could not request payout. Please try again.'),
    ));
    await _load();
  }

  Widget _metric(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final money = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final dates = DateFormat('dd MMM yyyy');
    final earnings = ProviderEarnings.calculate(
      hostIds: appState.allActiveUserIds,
      bookings: appState.allBookings,
      hotelBookings: appState.hotelBookings,
      payouts: _payouts,
    );
    final available = earnings.available;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => appState.setNavIndex(8),
              ),
              const SizedBox(width: 8),
              const Text('Earnings & Payouts', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Available for Payout', style: TextStyle(fontSize: 12, color: Colors.white70)),
                const SizedBox(height: 6),
                Text(
                  money.format(available),
                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _loading || available <= 0 ? null : () => _requestPayout(available),
                  icon: const Icon(Icons.account_balance),
                  label: const Text('Request Payout'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.2,
            children: [
              _metric(money.format(earnings.totalEarned), 'Total Earned'),
              _metric(money.format(earnings.earnedIn('Bikes')), 'Bikes'),
              _metric(money.format(earnings.earnedIn('Tours')), 'Guided Tours'),
              _metric(money.format(earnings.earnedIn('Hotels')), 'Hotels & Stays'),
              _metric(money.format(earnings.upcoming), 'Upcoming Bookings'),
              _metric(money.format(earnings.paidOut), 'Paid Out'),
              _metric(money.format(earnings.requested), 'Payout In Progress'),
              _metric(money.format(earnings.collectedDirectly), 'Collected Directly'),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Payout History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          if (_payouts.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text('No payouts yet.')),
          for (final p in _payouts)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(money.format(p.amount)),
              subtitle: Text(
                '${dates.format(p.requestedAt)}'
                '${p.reference.isNotEmpty ? ' • Ref: ${p.reference}' : ''}'
                '${p.adminNote.isNotEmpty ? ' • ${p.adminNote}' : ''}',
              ),
              trailing: Text(p.status.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          const SizedBox(height: 16),
          const Text('Booking Earnings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          if (earnings.items.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text('No earnings yet.')),
          for (final item in earnings.items)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(item.title),
              subtitle: Text('${item.category} • ${item.customer} • ${dates.format(item.date)}'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(money.format(item.amount), style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    !item.settled ? 'Upcoming' : (item.heldByPlatform ? 'Online' : 'Direct'),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
