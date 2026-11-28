import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/booking_status.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../services/booking_service.dart';
import '../theme/app_colors.dart';
import '../utils/app_notification.dart';
import '../widgets/booking_workflow_actions.dart';

/// Owner's booking manager: confirmation-mode setting plus bookings grouped
/// into New Requests / Confirmed / Ongoing / Completed / Rejected-Cancelled.
class OwnerBookingsScreen extends StatefulWidget {
  const OwnerBookingsScreen({super.key, this.initialCategory = BookingCategory.pending});

  final BookingCategory initialCategory;

  @override
  State<OwnerBookingsScreen> createState() => _OwnerBookingsScreenState();
}

class _OwnerBookingsScreenState extends State<OwnerBookingsScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    final appState = context.read<AppState>();
    setState(() => _loading = true);
    await Future.wait([
      appState.refreshBookingsForActiveAccount(),
      appState.loadBookingPreferences(),
    ]);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final bookings = appState.ownerVehicleBookings;
    final byCategory = {
      for (final c in BookingCategory.values) c: bookings.where((b) => b.category == c).toList(),
    };
    // Requests are handled soonest-pickup first.
    byCategory[BookingCategory.pending]!.sort((a, b) => a.startDate.compareTo(b.startDate));

    return DefaultTabController(
      length: BookingCategory.values.length,
      initialIndex: widget.initialCategory.index,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Bookings', style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(onPressed: _loading ? null : _refresh, icon: const Icon(Icons.refresh_rounded), tooltip: 'Refresh'),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              for (final c in BookingCategory.values)
                Tab(
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(c.icon, size: 16),
                    const SizedBox(width: 6),
                    Text('${c.ownerLabel} (${byCategory[c]!.length})'),
                  ]),
                ),
            ],
          ),
        ),
        body: Column(
          children: [
            if (_loading) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: TabBarView(
                children: [
                  for (final c in BookingCategory.values)
                    RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (c == BookingCategory.pending) const BookingConfirmationModeCard(),
                          if (byCategory[c]!.isEmpty)
                            _EmptyState(category: c)
                          else
                            for (final b in byCategory[c]!) OwnerBookingCard(booking: b),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.category});
  final BookingCategory category;

  static const _text = {
    BookingCategory.pending: 'No booking requests are waiting for you.',
    BookingCategory.confirmed: 'Confirmed bookings appear here until pickup.',
    BookingCategory.ongoing: 'Vehicles currently out with renters appear here.',
    BookingCategory.completed: 'Finished rentals appear here.',
    BookingCategory.closed: 'Rejected, cancelled and expired bookings appear here.',
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(category.icon, size: 44, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(_text[category]!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

/// "Booking Confirmation Mode" setting. Automatic confirmation is only
/// offered to verified owners; the database enforces the same rule.
class BookingConfirmationModeCard extends StatefulWidget {
  const BookingConfirmationModeCard({super.key});

  @override
  State<BookingConfirmationModeCard> createState() => _BookingConfirmationModeCardState();
}

class _BookingConfirmationModeCardState extends State<BookingConfirmationModeCard> {
  bool _saving = false;

  Future<void> _save(AppState appState, {bool? autoConfirm, bool? accepting}) async {
    setState(() => _saving = true);
    try {
      final p = await appState.setBookingPreferences(autoConfirm: autoConfirm, acceptingBookings: accepting);
      if (!mounted) return;
      AppToast.showSuccess(
        context,
        accepting != null
            ? (p.acceptingBookings ? 'You are accepting new bookings.' : 'New bookings are paused.')
            : (p.autoConfirm
                ? 'Automatic confirmation is on for future bookings.'
                : 'Manual confirmation is on for future bookings.'),
      );
    } on BookingException catch (e) {
      if (mounted) AppToast.showError(context, e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final p = appState.bookingPreferences;
    final mode = p.autoConfirm ? 'auto' : 'manual';
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: AppColors.primary.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [
              Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text('Booking Confirmation Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ]),
            const SizedBox(height: 10),
            RadioGroup<String>(
              groupValue: mode,
              onChanged: (v) {
                if (_saving || v == null || v == mode) return;
                _save(appState, autoConfirm: v == 'auto');
              },
              child: Column(
                children: [
                  RadioListTile<String>(
                    value: 'auto',
                    enabled: p.isVerified && !_saving,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Automatic Confirmation'),
                    subtitle: Text(p.isVerified
                        ? 'Bookings for free time slots are confirmed instantly.'
                        : 'Available once your provider profile is verified.'),
                  ),
                  RadioListTile<String>(
                    value: 'manual',
                    enabled: !_saving,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Manual Confirmation'),
                    subtitle: const Text('Every request waits for you to accept or reject it.'),
                  ),
                ],
              ),
            ),
            const Divider(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: p.acceptingBookings,
              onChanged: _saving ? null : (v) => _save(appState, accepting: v),
              title: const Text('Accepting new bookings'),
              subtitle: const Text('Turn off to pause new requests for all your vehicles.'),
            ),
            const Text('Changes apply to future bookings only. Existing bookings keep their status.',
                style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

/// Entry tile for the provider dashboard.
class OwnerBookingsTile extends StatelessWidget {
  const OwnerBookingsTile({super.key});

  @override
  Widget build(BuildContext context) {
    final bookings = context.watch<AppState>().ownerVehicleBookings;
    final pending = bookings.where((Booking b) => b.category == BookingCategory.pending).length;
    final confirmed = bookings.where((Booking b) => b.category == BookingCategory.confirmed).length;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: pending > 0 ? AppColors.tertiary : AppColors.outlineVariantLight),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: (pending > 0 ? AppColors.tertiary : AppColors.primary).withValues(alpha: 0.12),
          child: Icon(Icons.event_note_rounded, color: pending > 0 ? AppColors.tertiary : AppColors.primary),
        ),
        title: const Text('Manage Bookings', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(pending > 0
            ? '$pending new request${pending == 1 ? '' : 's'} waiting · $confirmed confirmed'
            : '$confirmed confirmed · set automatic or manual confirmation'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OwnerBookingsScreen())),
      ),
    );
  }
}
