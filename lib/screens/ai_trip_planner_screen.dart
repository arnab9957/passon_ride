import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/app_state.dart';
import '../services/trip_planner_service.dart';
import '../theme/app_colors.dart';
import '../widgets/hotel_details_modal.dart';
import '../widgets/supabase_auth_dialog.dart';
import '../widgets/tour_details_modal.dart';

/// Traveller-facing AI trip planner: destination + days + budget → day-by-day
/// plan with bookable PassionRide rides, stays and tours.
class AiTripPlannerScreen extends StatefulWidget {
  final String initialDestination;

  const AiTripPlannerScreen({super.key, this.initialDestination = ''});

  @override
  State<AiTripPlannerScreen> createState() => _AiTripPlannerScreenState();
}

class _AiTripPlannerScreenState extends State<AiTripPlannerScreen> {
  static const _budgets = ['Budget', 'Mid-range', 'Premium'];
  static const _allInterests = [
    'Beaches',
    'Mountains',
    'Temples & heritage',
    'Food',
    'Adventure',
    'Nightlife',
    'Nature & wildlife',
    'Photography',
  ];

  late final TextEditingController _destination = TextEditingController(text: widget.initialDestination);
  int _days = 3;
  int _travellers = 2;
  String _budget = 'Mid-range';
  final Set<String> _interests = {};
  bool _loading = false;
  TripPlan? _plan;

  final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  void dispose() {
    _destination.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final appState = context.read<AppState>();
    if (_destination.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Where do you want to go? Enter a destination.')),
      );
      return;
    }
    if (!appState.isSignedIn) {
      showDialog(context: context, builder: (_) => const SupabaseAuthDialog());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to use the AI Trip Planner.')),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _plan = null;
    });
    final plan = await TripPlannerService.plan(
      destination: _destination.text,
      days: _days,
      budget: _budget,
      travellers: _travellers,
      interests: _interests.toList(),
      vehicles: appState.vehicles,
      hotels: appState.hotels,
      tours: appState.tours,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _plan = plan;
    });
  }

  void _openVehicle(Vehicle v) {
    final appState = context.read<AppState>();
    appState.selectVehicle(v);
    appState.setNavIndex(2);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.auto_awesome, color: AppColors.primary),
          SizedBox(width: 8),
          Text('AI Trip Planner', style: TextStyle(fontWeight: FontWeight.bold)),
        ]),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildForm(scheme),
            const SizedBox(height: 20),
            if (_loading) _buildLoading(scheme),
            if (_plan != null) ..._buildPlan(_plan!, scheme),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(ColorScheme scheme) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _destination,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _generate(),
              decoration: InputDecoration(
                labelText: 'Destination',
                hintText: 'e.g. Puri, Odisha',
                prefixIcon: const Icon(Icons.place_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _stepper('Days', _days, 1, 10, (v) => setState(() => _days = v))),
              const SizedBox(width: 12),
              Expanded(child: _stepper('Travellers', _travellers, 1, 12, (v) => setState(() => _travellers = v))),
            ]),
            const SizedBox(height: 16),
            Text('Budget', style: TextStyle(fontWeight: FontWeight.w600, color: scheme.onSurface)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: [for (final b in _budgets) ButtonSegment(value: b, label: Text(b))],
              selected: {_budget},
              onSelectionChanged: (s) => setState(() => _budget = s.first),
              showSelectedIcon: false,
            ),
            const SizedBox(height: 16),
            Text('Interests', style: TextStyle(fontWeight: FontWeight.w600, color: scheme.onSurface)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final i in _allInterests)
                  FilterChip(
                    label: Text(i),
                    selected: _interests.contains(i),
                    onSelected: (on) => setState(() => on ? _interests.add(i) : _interests.remove(i)),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: _loading ? null : _generate,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.auto_awesome),
                label: Text(_plan == null ? 'Plan my trip' : 'Re-plan',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepper(String label, int value, int min, int max, ValueChanged<int> onChanged) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.remove),
          onPressed: value > min ? () => onChanged(value - 1) : null,
        ),
        Expanded(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('$value', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: scheme.onSurface)),
            Text(label, style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
          ]),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.add),
          onPressed: value < max ? () => onChanged(value + 1) : null,
        ),
      ]),
    );
  }

  Widget _buildLoading(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text('Planning your trip to ${_destination.text.trim()}…',
            style: TextStyle(color: scheme.onSurfaceVariant)),
      ]),
    );
  }

  List<Widget> _buildPlan(TripPlan plan, ColorScheme scheme) {
    final muted = scheme.onSurfaceVariant;
    return [
      Text(plan.title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: scheme.onSurface)),
      const SizedBox(height: 6),
      if (plan.summary.isNotEmpty) Text(plan.summary, style: TextStyle(color: muted, height: 1.4)),
      if (plan.estimatedBudget.isNotEmpty) ...[
        const SizedBox(height: 10),
        Row(children: [
          const Icon(Icons.account_balance_wallet_outlined, size: 18, color: AppColors.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Text('Estimated budget: ${plan.estimatedBudget}',
                style: TextStyle(fontWeight: FontWeight.w600, color: scheme.onSurface)),
          ),
        ]),
      ],
      if (!plan.fromAi) ...[
        const SizedBox(height: 10),
        Text('AI is busy right now — showing a starter plan. Tap Re-plan to try again.',
            style: TextStyle(fontSize: 12, color: Colors.orange.shade800)),
      ],
      const SizedBox(height: 16),
      for (final day in plan.days)
        Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(day.title, style: TextStyle(fontWeight: FontWeight.bold, color: scheme.onSurface)),
              const SizedBox(height: 6),
              for (final a in day.activities)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6, right: 8),
                      child: Icon(Icons.circle, size: 6, color: muted),
                    ),
                    Expanded(child: Text(a, style: TextStyle(color: scheme.onSurface, height: 1.35))),
                  ]),
                ),
            ]),
          ),
        ),
      if (plan.vehicles.isNotEmpty) ...[
        _sectionTitle('Rides for this trip', Icons.two_wheeler),
        for (final v in plan.vehicles)
          _listingTile(
            imageUrl: v.imageUrl,
            title: v.title,
            subtitle: v.location,
            price: '${_currency.format(v.pricePerDay)}/day',
            onTap: () => _openVehicle(v),
          ),
      ],
      if (plan.hotels.isNotEmpty) ...[
        _sectionTitle('Where to stay', Icons.hotel_outlined),
        for (final h in plan.hotels)
          _listingTile(
            imageUrl: h.imageUrl,
            title: h.name,
            subtitle: h.location,
            price: '${_currency.format(h.pricePerNight)}/night',
            onTap: () => showHotelDetailsModal(context, context.read<AppState>(), h),
          ),
      ],
      if (plan.tours.isNotEmpty) ...[
        _sectionTitle('Guided tours', Icons.tour_outlined),
        for (final t in plan.tours)
          _listingTile(
            imageUrl: t.imageUrl,
            title: t.title,
            subtitle: '${t.location} • ${t.duration}',
            price: _currency.format(t.price),
            onTap: () => showTourDetailsModal(context, context.read<AppState>(), t),
          ),
      ],
      if (plan.tips.isNotEmpty) ...[
        _sectionTitle('Tips', Icons.lightbulb_outline),
        for (final tip in plan.tips)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text('• $tip', style: TextStyle(color: scheme.onSurface, height: 1.35)),
          ),
      ],
      const SizedBox(height: 24),
    ];
  }

  Widget _sectionTitle(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Row(children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _listingTile({
    required String imageUrl,
    required String title,
    required String subtitle,
    required String price,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        child: Row(children: [
          SizedBox(
            width: 88,
            height: 72,
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(color: Colors.grey.shade200, child: const Icon(Icons.image)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(subtitle,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
              const SizedBox(height: 2),
              Text(price, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                minimumSize: const Size(0, 34),
              ),
              child: const Text('Book'),
            ),
          ),
        ]),
      ),
    );
  }
}
