import '../models/models.dart';

class ProviderPayout {
  final String id;
  final String hostId;
  final double amount;
  final String status;
  final String payoutDetails;
  final String reference;
  final String adminNote;
  final DateTime requestedAt;

  ProviderPayout.fromMap(Map<String, dynamic> map)
      : id = map['id'].toString(),
        hostId = map['host_id'].toString(),
        amount = (map['amount'] as num).toDouble(),
        status = map['status'].toString(),
        payoutDetails = (map['payout_details'] ?? '').toString(),
        reference = (map['reference'] ?? '').toString(),
        adminNote = (map['admin_note'] ?? '').toString(),
        requestedAt = DateTime.parse(map['requested_at'].toString());
}

class EarningItem {
  final String category;
  final String title;
  final String customer;
  final double amount;
  final DateTime date;
  final bool settled;
  final bool heldByPlatform;

  const EarningItem(this.category, this.title, this.customer, this.amount, this.date, this.settled, this.heldByPlatform);
}

/// Earnings for one provider. There is no platform commission. Only online payments
/// sit with the platform, so only those can be paid out; cash and direct UPI already
/// reached the provider.
class ProviderEarnings {
  final List<EarningItem> items;
  final List<ProviderPayout> payouts;

  ProviderEarnings(this.items, this.payouts);

  factory ProviderEarnings.calculate({
    required Set<String> hostIds,
    required List<Booking> bookings,
    required List<HotelBooking> hotelBookings,
    required List<ProviderPayout> payouts,
  }) {
    final now = DateTime.now();
    final items = <EarningItem>[];

    for (final b in bookings) {
      final status = b.status.toLowerCase();
      if (!hostIds.contains(b.hostId) || status == 'cancelled' || status == 'pending') continue;
      items.add(EarningItem(
        b.id.startsWith('tb_') ? 'Tours' : 'Bikes',
        b.vehicleTitle,
        b.customerName,
        b.totalPrice,
        b.endDate,
        status == 'completed' || b.endDate.isBefore(now),
        _isRazorpayPayment(b.paymentIntentId),
      ));
    }
    for (final b in hotelBookings) {
      final status = b.status.toLowerCase();
      if (!hostIds.contains(b.hostId) || status.contains('cancel')) continue;
      items.add(EarningItem(
        'Hotels',
        b.hotelName,
        b.guestName,
        b.totalPrice,
        b.checkOutDate,
        b.checkOutDate.isBefore(now),
        b.paymentMethod.toLowerCase().contains('razorpay'),
      ));
    }
    items.sort((a, b) => b.date.compareTo(a.date));
    return ProviderEarnings(items, payouts);
  }

  double _sum(bool Function(EarningItem) test) =>
      items.where(test).fold(0.0, (total, item) => total + item.amount);

  double _payouts(String status) =>
      payouts.where((p) => p.status == status).fold(0.0, (total, p) => total + p.amount);

  double earnedIn(String category) => _sum((i) => i.settled && i.category == category);

  double get totalEarned => _sum((i) => i.settled);
  double get upcoming => _sum((i) => !i.settled);
  double get paidOut => _payouts('paid');
  double get requested => _payouts('requested');
  double get collectedDirectly => _sum((i) => i.settled && !i.heldByPlatform);

  double get available {
    final balance = _sum((i) => i.settled && i.heldByPlatform) - paidOut - requested;
    return balance < 0 ? 0 : balance;
  }
}

// Razorpay ids look like pay_AbC123; site and UPI payments use their own prefixes.
bool _isRazorpayPayment(String id) =>
    id.startsWith('pay_') && !id.startsWith('pay_at_site') &&
    !id.startsWith('pay_upi') &&
    !id.startsWith('pay_vpa');
