import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/booking_status.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../services/whatsapp_service.dart';
import '../theme/app_colors.dart';
import '../utils/app_notification.dart';
import 'booking_actions.dart';

/// Phone number of the vehicle owner, from the listing (never a platform fallback).
String ownerPhoneFor(AppState appState, Booking booking) =>
    appState.vehicles.where((v) => v.id == booking.vehicleId).firstOrNull?.hostPhone.trim() ?? '';

/// Status-driven actions for one booking. Owners: accept / reject, mark
/// ongoing / completed, notify the renter. Renters: share with the owner,
/// contact the owner. Both: booking history. Which button appears follows
/// the booking lifecycle; the database still validates every change.
class BookingWorkflowActions extends StatefulWidget {
  const BookingWorkflowActions({super.key, required this.booking, required this.isOwner});

  final Booking booking;
  final bool isOwner;

  @override
  State<BookingWorkflowActions> createState() => _BookingWorkflowActionsState();
}

class _BookingWorkflowActionsState extends State<BookingWorkflowActions> {
  bool _busy = false;

  Booking get b => widget.booking;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return; // guards double taps
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) AppToast.showError(context, '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _accept(AppState appState) async {
    final note = await confirmBookingAction(
      context,
      title: 'Accept booking?',
      message:
          '${b.customerName.isNotEmpty ? b.customerName : 'The renter'} will get a confirmed booking for ${b.vehicleTitle}. '
          'Other requests for an overlapping time will be declined automatically.',
      confirmLabel: 'Accept booking',
      noteLabel: 'Note for the renter (optional)',
    );
    if (note == null) return;
    await _run(() async {
      final saved = await appState.acceptBooking(b.id, note: note);
      if (!mounted) return;
      AppToast.showSuccess(context, 'Booking ${saved.displayReference} confirmed.');
      await _offerNotifyRenter(saved, appState);
    });
  }

  Future<void> _reject(AppState appState) async {
    final reason = await confirmBookingAction(
      context,
      title: 'Reject booking?',
      message: 'The renter will be told the request could not be confirmed. This cannot be undone.',
      confirmLabel: 'Reject booking',
      destructive: true,
      noteLabel: 'Reason (optional, shown to the renter)',
    );
    if (reason == null) return;
    await _run(() async {
      final saved = await appState.rejectBooking(b.id, reason: reason);
      if (!mounted) return;
      AppToast.showInfo(context, 'Booking ${saved.displayReference} rejected.');
      await _offerNotifyRenter(saved, appState);
    });
  }

  Future<void> _offerNotifyRenter(Booking saved, AppState appState) async {
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Notify the renter on WhatsApp?'),
        content: const Text('WhatsApp opens with the booking details filled in. You still press Send yourself.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Not now')),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 16),
            label: const Text('Open WhatsApp'),
            style: ElevatedButton.styleFrom(backgroundColor: whatsAppGreen, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
    if (go == true && mounted) await _notifyRenter(saved, appState);
  }

  Future<void> _notifyRenter(Booking booking, AppState appState) async {
    final message = WhatsAppService.messageForRenter(booking, ownerPhone: ownerPhoneFor(appState, booking));
    if (message == null) return;
    await shareBookingOnWhatsApp(context, phone: booking.customerPhone, message: message, recipient: 'the renter');
  }

  Future<void> _shareWithOwner(AppState appState) async {
    final message = WhatsAppService.messageForOwner(b);
    if (message == null) return;
    await shareBookingOnWhatsApp(context, phone: ownerPhoneFor(appState, b), message: message, recipient: 'the owner');
  }

  Future<void> _call(String phone, String who) async {
    final digits = WhatsAppService.normalizePhone(phone);
    if (digits == null) {
      AppToast.showError(context, 'No phone number is saved for $who.');
      return;
    }
    if (!await launchUrl(Uri.parse('tel:+$digits'))) {
      if (mounted) AppToast.showError(context, 'Calling is not available on this device.');
    }
  }

  Future<void> _lifecycle(AppState appState, String to, String title, String message) async {
    final ok = await confirmBookingAction(context, title: title, message: message, confirmLabel: 'Confirm');
    if (ok == null) return;
    await _run(() async {
      await appState.updateBookingStatus(b.id, to);
      if (mounted) AppToast.showSuccess(context, 'Booking ${b.displayReference} is now ${BookingStatus.label(to)}.');
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    final status = b.normalizedStatus;
    final children = <Widget>[];

    if (widget.isOwner) {
      if (b.ownerCanDecide) {
        children.addAll([
          ElevatedButton.icon(
            onPressed: _busy || !b.ownerCanAccept ? null : () => _accept(appState),
            icon: const Icon(Icons.check_circle_rounded, size: 18),
            label: const Text('ACCEPT BOOKING'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, foregroundColor: Colors.white),
          ),
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _reject(appState),
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('REJECT BOOKING'),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
          ),
        ]);
      }
      if (b.canMarkOngoing) {
        children.add(OutlinedButton.icon(
          onPressed: _busy
              ? null
              : () => _lifecycle(appState, BookingStatus.active, 'Mark as ongoing?',
                  'Confirm the renter has picked up ${b.vehicleTitle}. GPS tracking starts.'),
          icon: const Icon(Icons.two_wheeler_rounded, size: 18),
          label: const Text('Mark as Ongoing'),
        ));
      }
      if (b.canMarkCompleted) {
        children.add(OutlinedButton.icon(
          onPressed: _busy
              ? null
              : () => _lifecycle(appState, BookingStatus.completed, 'Mark as completed?',
                  'Confirm ${b.vehicleTitle} has been returned. It becomes available for new bookings.'),
          icon: const Icon(Icons.flag_rounded, size: 18),
          label: const Text('Mark as Completed'),
        ));
      }
      if (WhatsAppService.messageForRenter(b, ownerPhone: '') != null) {
        children.add(WhatsAppButton(
          label: 'Notify Renter on WhatsApp',
          onPressed: _busy ? null : () => _notifyRenter(b, appState),
        ));
      }
      if (!BookingStatus.isClosed(status)) {
        children.add(TextButton.icon(
          onPressed: () => _call(b.customerPhone, 'the renter'),
          icon: const Icon(Icons.call_outlined, size: 16),
          label: const Text('Contact Renter'),
        ));
      }
    } else {
      if (WhatsAppService.messageForOwner(b) != null && status != BookingStatus.cancelled) {
        children.add(WhatsAppButton(
          label: 'Share with Owner on WhatsApp',
          onPressed: _busy ? null : () => _shareWithOwner(appState),
        ));
      }
      if (!BookingStatus.isClosed(status)) {
        children.add(TextButton.icon(
          onPressed: () => _call(ownerPhoneFor(appState, b), 'the owner'),
          icon: const Icon(Icons.call_outlined, size: 16),
          label: const Text('Contact Owner'),
        ));
      }
    }

    children.add(TextButton.icon(
      onPressed: () => showBookingHistorySheet(context, b, appState.bookingService),
      icon: const Icon(Icons.history_rounded, size: 16),
      label: const Text('Booking History'),
    ));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (status == BookingStatus.pending) _PendingNote(booking: b, isOwner: widget.isOwner),
        if (status == BookingStatus.rejected && b.rejectionReason.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('Reason: ${b.rejectionReason}', style: const TextStyle(fontSize: 12, color: AppColors.error)),
          ),
        if (_busy) const LinearProgressIndicator(minHeight: 2),
        Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: children),
      ],
    );
  }
}

class _PendingNote extends StatelessWidget {
  const _PendingNote({required this.booking, required this.isOwner});
  final Booking booking;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    final String text;
    if (booking.bookingFeeOutstanding) {
      text = isOwner
          ? 'You can accept once the renter\'s ₹10 booking fee is verified.'
          : 'Your ₹10 booking fee is being verified.';
    } else {
      text = isOwner
          ? 'This renter is waiting for your decision.'
          : 'Waiting for the owner to accept. This is not a confirmed booking yet.';
    }
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.tertiary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.tertiary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.hourglass_top_rounded, size: 16, color: AppColors.tertiary),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}

/// Compact booking card for the owner's booking manager.
class OwnerBookingCard extends StatelessWidget {
  const OwnerBookingCard({super.key, required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final b = booking;
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: isDark ? AppColors.outlineVariantDark : AppColors.outlineVariantLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: SelectableText(b.displayReference,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace', fontSize: 13)),
                ),
                BookingStatusBadge(b.status),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    b.vehicleImageUrl,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 64,
                      height: 64,
                      color: AppColors.surfaceContainer,
                      child: const Icon(Icons.two_wheeler_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(b.vehicleTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text('${b.customerName.isNotEmpty ? b.customerName : 'Renter'} · '
                          '${b.customerPhone.isNotEmpty ? b.customerPhone : 'no phone'}',
                          style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('₹${WhatsAppService.formatAmount(b.totalPrice)}'
                          '${b.confirmationType.isNotEmpty ? ' · ${b.confirmationType.toLowerCase()} confirmation' : ''}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _line(Icons.login_rounded, 'Pickup', WhatsAppService.formatDateTime(b.startDate)),
            const SizedBox(height: 4),
            _line(Icons.logout_rounded, 'Return', WhatsAppService.formatDateTime(b.endDate)),
            const Divider(height: 22),
            BookingWorkflowActions(booking: b, isOwner: true),
          ],
        ),
      ),
    );
  }

  Widget _line(IconData icon, String label, String value) => Row(
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text('$label: ', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
        ],
      );
}
