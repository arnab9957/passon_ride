import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:material_ui/material_ui.dart';

import '../models/booking_status.dart';
import '../models/models.dart';
import '../services/booking_service.dart';
import '../services/whatsapp_service.dart';
import '../theme/app_colors.dart';
import '../utils/app_notification.dart';

const whatsAppGreen = Color(0xFF25D366);

/// Coloured pill showing a booking's status ("Ongoing" for Active).
class BookingStatusBadge extends StatelessWidget {
  const BookingStatusBadge(this.status, {super.key});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = BookingStatus.color(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(BookingStatus.icon(status), size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            BookingStatus.label(status).toUpperCase(),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.4),
          ),
        ],
      ),
    );
  }
}

/// Green button with the WhatsApp logo.
class WhatsAppButton extends StatelessWidget {
  const WhatsAppButton({super.key, required this.label, required this.onPressed});
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: whatsAppGreen,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

/// Opens WhatsApp with [message] for [phone]. If the number is missing or
/// WhatsApp cannot be opened, offers the message to copy instead.
Future<void> shareBookingOnWhatsApp(
  BuildContext context, {
  required String? phone,
  required String message,
  required String recipient, // e.g. 'the owner', 'the renter'
  WhatsAppService? service,
}) async {
  final result = await (service ?? WhatsAppService()).open(phone: phone, message: message);
  if (!context.mounted) return;
  switch (result) {
    case WhatsAppOpenResult.opened:
      AppToast.showInfo(context, 'WhatsApp opened. Press Send to share the details with $recipient.');
    case WhatsAppOpenResult.invalidPhone:
      await showCopyMessageFallback(context,
          reason: 'No valid WhatsApp number is saved for $recipient.', message: message);
    case WhatsAppOpenResult.unavailable:
      await showCopyMessageFallback(context,
          reason: 'WhatsApp could not be opened on this device.', message: message);
  }
}

Future<void> showCopyMessageFallback(BuildContext context, {required String reason, required String message}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Copy booking details', style: TextStyle(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$reason Copy the message and send it any way you like.', style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 12),
            Container(
              width: double.maxFinite,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(message, style: const TextStyle(fontSize: 12, height: 1.4)),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ElevatedButton.icon(
          icon: const Icon(Icons.copy_rounded, size: 18),
          label: const Text('Copy message'),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: message));
            if (!ctx.mounted) return;
            Navigator.pop(ctx);
            AppToast.showSuccess(context, 'Booking details copied.');
          },
        ),
      ],
    ),
  );
}

/// Asks before an irreversible booking action. Returns the note (possibly
/// empty) when confirmed, or null when dismissed.
Future<String?> confirmBookingAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
  String? noteLabel,
}) {
  final note = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: const TextStyle(fontSize: 13)),
          if (noteLabel != null) ...[
            const SizedBox(height: 12),
            TextField(
              controller: note,
              maxLength: 200,
              decoration: InputDecoration(labelText: noteLabel, border: const OutlineInputBorder()),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Back')),
        ElevatedButton(
          style: destructive ? ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white) : null,
          onPressed: () => Navigator.pop(ctx, note.text.trim()),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
}

/// Bottom sheet listing every status change of a booking.
Future<void> showBookingHistorySheet(BuildContext context, Booking booking, BookingService service) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Booking history · ${booking.displayReference}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            FutureBuilder<List<BookingHistoryEntry>>(
              future: service.fetchHistory(booking.id),
              builder: (ctx, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snap.hasError) {
                  return Text('${snap.error}', style: const TextStyle(color: AppColors.error));
                }
                final entries = snap.data ?? const [];
                if (entries.isEmpty) {
                  return const Text('No status changes recorded yet.', style: TextStyle(color: Colors.grey));
                }
                return Column(
                  children: [
                    for (final e in entries)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(BookingStatus.icon(e.toStatus), color: BookingStatus.color(e.toStatus)),
                        title: Text(
                          e.fromStatus == null
                              ? 'Created as ${BookingStatus.label(e.toStatus)}'
                              : '${BookingStatus.label(e.fromStatus!)} → ${BookingStatus.label(e.toStatus)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text([
                          WhatsAppService.formatDateTime(e.at),
                          if (e.note.isNotEmpty) e.note,
                        ].join(' · ')),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}
