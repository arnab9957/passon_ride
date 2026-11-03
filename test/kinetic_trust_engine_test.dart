import 'package:flutter_test/flutter_test.dart';
import 'package:passon_ride/models/models.dart';
import 'package:passon_ride/services/kinetic_trust_engine.dart';

final now = DateTime(2026, 11, 3, 12);

Booking booking(
  String id, {
  required String status,
  required DateTime start,
  Duration length = const Duration(hours: 8),
  DateTime? startedAt,
  DateTime? endedAt,
  String cancelledBy = '',
  DateTime? cancelledAt,
}) =>
    Booking(
      id: id,
      vehicleId: 'v',
      vehicleTitle: 'Bike',
      vehicleImageUrl: '',
      hostName: 'h',
      startDate: start,
      endDate: start.add(length),
      totalPrice: 500,
      status: status,
      unlockPasscode: '0000',
      createdAt: start.subtract(const Duration(days: 3)),
      rentalStartedAt: startedAt,
      rentalEndedAt: endedAt,
      cancelledBy: cancelledBy,
      cancelledAt: cancelledAt,
    );

ComplianceDocument doc(String type, String status) => ComplianceDocument(
      id: type,
      title: type,
      status: status,
      expiryDate: now.add(const Duration(days: 365)),
      type: type,
    );

void main() {
  final verifiedDocs = [doc('Driving License', 'Verified'), doc('Aadhar Card', 'Verified')];

  test('new user with no data sits at the neutral prior', () {
    final r = KineticTrustEngine.evaluate(bookings: [], documents: [], now: now);
    expect(r.reliability, closeTo(0.85, 1e-9));
    expect(r.punctuality, closeTo(0.85, 1e-9));
    expect(r.score, closeTo(100 * (0.40 * 0.85 + 0.25 * 0.85), 0.05)); // 55.3
  });

  test('verified documents add the full 20 points', () {
    final a = KineticTrustEngine.evaluate(bookings: [], documents: [], now: now);
    final b = KineticTrustEngine.evaluate(bookings: [], documents: verifiedDocs, now: now);
    expect(b.score - a.score, closeTo(20, 0.05));
  });

  test('cancellation cost decays with notice: c(h) = e^(-h/24)', () {
    expect(KineticTrustEngine.cancellationCost(0), 1);
    expect(KineticTrustEngine.cancellationCost(-3), 1);
    expect(KineticTrustEngine.cancellationCost(24), closeTo(0.3679, 1e-4));
    expect(KineticTrustEngine.cancellationCost(72), closeTo(0.0498, 1e-4));
  });

  test('last-minute cancel hurts far more than early cancel', () {
    final start = now.add(const Duration(days: 1));
    final lastMinute = booking('a',
        status: 'Cancelled', start: start, cancelledBy: 'customer', cancelledAt: start.subtract(const Duration(minutes: 30)));
    final early = booking('b',
        status: 'Cancelled', start: start, cancelledBy: 'customer', cancelledAt: start.subtract(const Duration(days: 4)));
    final s1 = KineticTrustEngine.evaluate(bookings: [lastMinute], documents: verifiedDocs, now: now).score;
    final s2 = KineticTrustEngine.evaluate(bookings: [early], documents: verifiedDocs, now: now).score;
    expect(s2, greaterThan(s1));
  });

  test('host cancellations never penalise the renter', () {
    final start = now.subtract(const Duration(days: 2));
    final host = booking('h', status: 'Cancelled', start: start, cancelledBy: 'host', cancelledAt: start);
    final base = KineticTrustEngine.evaluate(bookings: [], documents: verifiedDocs, now: now).score;
    final r = KineticTrustEngine.evaluate(bookings: [host], documents: verifiedDocs, now: now);
    expect(r.score, base);
    expect(r.hostCancellations, 1);
  });

  test('no-show is detected and weighs 1.5x', () {
    final start = now.subtract(const Duration(hours: 5));
    final r = KineticTrustEngine.evaluate(
        bookings: [booking('n', status: 'Confirmed', start: start)], documents: verifiedDocs, now: now);
    expect(r.noShows, 1);
    expect(r.reliability, closeTo((3 * 0.85) / (1.5 * r.events.first.recencyWeight + 3), 1e-9));
  });

  test('late return lowers punctuality: 2h late -> s = e^-1', () {
    final start = now.subtract(const Duration(days: 1));
    final b = booking('l',
        status: 'Completed',
        start: start,
        startedAt: start,
        endedAt: start.add(const Duration(hours: 10))); // 2h late
    final r = KineticTrustEngine.evaluate(bookings: [b], documents: verifiedDocs, now: now);
    expect(r.events.first.punctuality, closeTo(0.3679, 1e-3));
    expect(r.punctuality, lessThan(0.85));
    expect(r.avgLateReturnMinutes, 120);
  });

  test('a reliable rider with 15 on-time rides reaches Platinum', () {
    final rides = List.generate(15, (i) {
      final start = now.subtract(Duration(days: 10 + i * 7));
      return booking('r$i', status: 'Completed', start: start, startedAt: start, endedAt: start.add(const Duration(hours: 8)));
    });
    final r = KineticTrustEngine.evaluate(bookings: rides, documents: verifiedDocs, now: now);
    expect(r.score, greaterThanOrEqualTo(90));
    expect(r.tier, 'Platinum Rider');
    expect(r.badges, contains('Zero Cancellations'));
  });

  test('old cancellations count less than recent ones (180-day half-life)', () {
    expect(KineticTrustEngine.recencyWeight(now.subtract(const Duration(days: 180)), now), closeTo(0.5, 1e-3));
  });
}
