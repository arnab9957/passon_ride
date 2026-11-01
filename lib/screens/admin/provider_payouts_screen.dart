import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../services/provider_earnings.dart';

/// Admin view of each provider's earnings, balance and payout requests.
class ProviderPayoutsScreen extends StatefulWidget {
  const ProviderPayoutsScreen({super.key});

  @override
  State<ProviderPayoutsScreen> createState() => _ProviderPayoutsScreenState();
}

class _ProviderPayoutsScreenState extends State<ProviderPayoutsScreen> {
  final _money = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  List<HostProfile> _hosts = [];
  List<Booking> _bookings = [];
  List<HotelBooking> _hotelBookings = [];
  List<ProviderPayout> _payouts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final service = Provider.of<AppState>(context, listen: false).supabaseService;
    final hosts = await service.fetchAllHostProfiles();
    final bookings = await service.getAllBookings();
    final hotelBookings = await service.getHotelBookings();
    final payouts = await service.getProviderPayouts();
    if (!mounted) return;
    setState(() {
      _hosts = hosts;
      _bookings = bookings;
      _hotelBookings = hotelBookings ?? [];
      _payouts = payouts;
      _loading = false;
    });
  }

  ProviderEarnings _earningsFor(HostProfile host) => ProviderEarnings.calculate(
        hostIds: {host.id, 'mth_${host.id}'},
        bookings: _bookings,
        hotelBookings: _hotelBookings,
        payouts: _payouts.where((p) => p.hostId == host.id).toList(),
      );

  Future<void> _settle(ProviderPayout payout, {required bool paid}) async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(paid ? 'Mark ${_money.format(payout.amount)} as Paid' : 'Reject Payout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pay to: ${payout.payoutDetails.isNotEmpty ? payout.payoutDetails : 'Not provided'}'),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: paid ? 'UPI / Bank Transaction Reference' : 'Reason',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.pop(ctx, value);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (text == null || !mounted) return;

    final appState = Provider.of<AppState>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await appState.supabaseService.settleProviderPayout(
      payout.id,
      status: paid ? 'paid' : 'rejected',
      reference: paid ? text : '',
      adminNote: paid ? '' : text,
    );
    if (!ok) {
      messenger.showSnackBar(const SnackBar(content: Text('Could not update this payout.')));
      return;
    }
    await appState.addNotification(
      userId: payout.hostId,
      title: paid ? 'Payout Sent' : 'Payout Rejected',
      message: paid
          ? '${_money.format(payout.amount)} has been paid. Reference: $text'
          : 'Your payout of ${_money.format(payout.amount)} was rejected: $text',
      type: NotificationType.general,
    );
    await _load();
  }

  Widget _providerCard(HostProfile host, ProviderEarnings e) {
    final pending = e.payouts.where((p) => p.status == 'requested').toList();
    final name = host.businessName.isNotEmpty ? host.businessName : host.displayName;
    return Card(
      child: ExpansionTile(
        initiallyExpanded: pending.isNotEmpty,
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          'Balance ${_money.format(e.available)}'
          '${pending.isNotEmpty ? ' • ${pending.length} payout request' : ''}',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total earned: ${_money.format(e.totalEarned)}'),
          Text('Bikes: ${_money.format(e.earnedIn('Bikes'))}'),
          Text('Guided tours: ${_money.format(e.earnedIn('Tours'))}'),
          Text('Hotels & stays: ${_money.format(e.earnedIn('Hotels'))}'),
          Text('Upcoming: ${_money.format(e.upcoming)}'),
          Text('Collected directly: ${_money.format(e.collectedDirectly)}'),
          Text('Paid out: ${_money.format(e.paidOut)}'),
          Text('Payout in progress: ${_money.format(e.requested)}'),
          const Divider(),
          if (e.payouts.isEmpty) const Text('No payouts yet.'),
          for (final p in e.payouts)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('${_money.format(p.amount)} • ${p.status.toUpperCase()}'),
                  if (p.reference.isNotEmpty) Text('Ref: ${p.reference}'),
                  if (p.status == 'requested') ...[
                    ElevatedButton(onPressed: () => _settle(p, paid: true), child: const Text('Mark Paid')),
                    TextButton(onPressed: () => _settle(p, paid: false), child: const Text('Reject')),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = [for (final host in _hosts) (host, _earningsFor(host))];
    rows.sort((a, b) => b.$2.requested.compareTo(a.$2.requested));

    return Scaffold(
      appBar: AppBar(title: const Text('Provider Earnings & Payouts')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  if (rows.isEmpty) const Text('No providers yet.'),
                  for (final row in rows) _providerCard(row.$1, row.$2),
                ],
              ),
            ),
    );
  }
}
