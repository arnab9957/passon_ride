import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import 'models.dart';

/// Booking lifecycle values as stored in `bookings.status`.
///
/// The database (`transition_booking`) is the authority on which change is
/// allowed; the helpers here only decide which buttons to show.
///
///   Pending → Confirmed → Active (shown as "Ongoing") → Completed
///   Pending → Rejected | Cancelled | Expired
///   Confirmed → Cancelled
class BookingStatus {
  BookingStatus._();

  static const pending = 'Pending';
  static const confirmed = 'Confirmed';
  static const active = 'Active';
  static const completed = 'Completed';
  static const rejected = 'Rejected';
  static const cancelled = 'Cancelled';
  static const expired = 'Expired';

  /// Normalises legacy spellings such as `confirmed` or `CONFIRMED`.
  static String normalize(String raw) {
    final s = raw.trim().toLowerCase();
    if (s.isEmpty) return pending;
    return s[0].toUpperCase() + s.substring(1);
  }

  static String label(String status) {
    final s = normalize(status);
    return s == active ? 'Ongoing' : s;
  }

  static Color color(String status) {
    switch (normalize(status)) {
      case pending:
        return AppColors.tertiary;
      case confirmed:
        return AppColors.primary;
      case active:
        return AppColors.secondary;
      case completed:
        return AppColors.outlineLight;
      default:
        return AppColors.error; // rejected, cancelled, expired
    }
  }

  static IconData icon(String status) {
    switch (normalize(status)) {
      case pending:
        return Icons.hourglass_top_rounded;
      case confirmed:
        return Icons.event_available_rounded;
      case active:
        return Icons.two_wheeler_rounded;
      case completed:
        return Icons.flag_rounded;
      case expired:
        return Icons.timer_off_rounded;
      default:
        return Icons.cancel_rounded;
    }
  }

  static bool isClosed(String status) =>
      const {completed, rejected, cancelled, expired}.contains(normalize(status));
}

/// The tabs both dashboards group bookings into.
enum BookingCategory { pending, confirmed, ongoing, completed, closed }

extension BookingCategoryX on BookingCategory {
  String get renterLabel => const {
        BookingCategory.pending: 'Pending',
        BookingCategory.confirmed: 'Confirmed',
        BookingCategory.ongoing: 'Ongoing',
        BookingCategory.completed: 'Completed',
        BookingCategory.closed: 'Cancelled / Rejected',
      }[this]!;

  String get ownerLabel => const {
        BookingCategory.pending: 'New Requests',
        BookingCategory.confirmed: 'Confirmed',
        BookingCategory.ongoing: 'Ongoing',
        BookingCategory.completed: 'Completed',
        BookingCategory.closed: 'Rejected / Cancelled',
      }[this]!;

  IconData get icon => const {
        BookingCategory.pending: Icons.hourglass_top_rounded,
        BookingCategory.confirmed: Icons.event_available_rounded,
        BookingCategory.ongoing: Icons.two_wheeler_rounded,
        BookingCategory.completed: Icons.flag_rounded,
        BookingCategory.closed: Icons.cancel_outlined,
      }[this]!;
}

extension BookingLifecycle on Booking {
  String get normalizedStatus => BookingStatus.normalize(status);

  BookingCategory get category {
    switch (normalizedStatus) {
      case BookingStatus.pending:
        return BookingCategory.pending;
      case BookingStatus.confirmed:
        return BookingCategory.confirmed;
      case BookingStatus.active:
        return BookingCategory.ongoing;
      case BookingStatus.completed:
        return BookingCategory.completed;
      default:
        return BookingCategory.closed;
    }
  }

  /// The ₹10 fee is still outstanding, so the owner cannot accept yet.
  bool get bookingFeeOutstanding =>
      const {'PENDING', 'SUBMITTED', 'FAILED'}.contains(feePaymentStatus.toUpperCase());

  bool get ownerCanDecide => normalizedStatus == BookingStatus.pending;
  bool get ownerCanAccept => ownerCanDecide && !bookingFeeOutstanding;
  bool get canMarkOngoing => normalizedStatus == BookingStatus.confirmed;
  bool get canMarkCompleted => normalizedStatus == BookingStatus.active;

  /// Renters may cancel a request, or a confirmed booking before pickup time.
  bool renterCanCancel(DateTime now) =>
      normalizedStatus == BookingStatus.pending ||
      (normalizedStatus == BookingStatus.confirmed && now.isBefore(startDate));

  bool get ownerCanCancel =>
      normalizedStatus == BookingStatus.pending || normalizedStatus == BookingStatus.confirmed;

  /// Sharing "confirmed" details only makes sense once the booking is confirmed or ongoing.
  bool get canShareConfirmation =>
      normalizedStatus == BookingStatus.confirmed || normalizedStatus == BookingStatus.active;
}
